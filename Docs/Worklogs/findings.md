# Apple On-Device AI Analysis Findings

## Initial Findings

- The project is a Swift/iOS games collection with multiple party games: Imposter, Bet Buddy, Falsche Faehrte, Questions, TimesUp, Sound Cinema, and Party Hub.
- Existing AI-related files are present in Imposter and TimesUp, so the final report should account for current AI direction rather than proposing AI from scratch.
- Foundation Models is best suited for text generation, structured output, short game dialog, summarization, classification, and tool calling on Apple Intelligence-capable iOS 26+ devices.
- Core ML, Natural Language, Vision, and Speech can cover broader on-device AI features that do not require Apple Intelligence.

## Project-Specific Findings

- `Imposter` already has `AIService`, `AIService+Hints`, `AITuner`, AI-generated spy hints, mission flavor, moderator logs, role generation, JSON validation, caching, request limiting, and deterministic fallback content.
- `TimesUp` already has `AICategoryGenerator` using `FoundationModels` when available, with mock/fallback terms and category persistence through `CategoryManager`.
- `Bet Buddy` has a large static challenge and hint corpus, timer/risk mechanics, category stats, all-time scores, and strong candidate hooks for personalized challenge generation, adaptive difficulty, recap narration, and smarter hint lists.
- `Falsche Faehrte` has player-written lies, true answers, voting, scores, packs, timers, and multiplayer. Strong hooks: AI lie coach, duplicate/too-obvious lie detection, reveal commentary, and custom question pack generation.
- `Questions` has paired citizen/liar prompts, answer timing, voting, and TV board support. Strong hooks: prompt-pair generation, similarity checking, suspicious-answer summaries, and adaptive discussion prompts.
- `Sound Cinema` is sound-acting based with packs, timers, voting, lives, and card deck JSON. Strong hooks: dynamic sound cards, post-round awards, speech/audio-based judging as an optional assist, not automatic truth.
- Global stats exist through `GlobalStatsManager`, which enables party-level AI recommendations and recap generation without network data collection.
- Privacy manifest currently declares UserDefaults only and no collected data/tracking. On-device AI should preserve this stance; cloud AI would change privacy posture.
- Project deployment target has iOS 17.6 in main target configs, with some iOS 26.2 references likely package/tooling. Apple Intelligence features need availability gates and non-AI fallbacks.

## Source Notes

- Apple Foundation Models supports on-device language understanding/generation, structured output, and tool calling.
- Apple App Intents can expose app actions/entities to Siri, Spotlight, Shortcuts, and Apple Intelligence.
- Apple Natural Language supports language identification, tokenization, tags, named entities, embeddings, and custom text models.
- Apple Vision text recognition runs on-device and can OCR images.
- Apple Speech supports live/prerecorded speech transcription.
- Apple HIG for Generative AI stresses transparency, user control, clear expectations, fallbacks, testing, and feedback.

## Recommendation Summary

- Avoid a generic app chatbot. Use small AI moments inside existing game loops.
- First MVP should be the AI Party Director in the existing game recommender, the Falsche Faehrte Lie Coach before bluff submission, and the Time's Up Generator 2.0 with structured output and review.
- Build a shared `GameAIService`/availability/validator layer instead of each game creating separate Foundation Models logic.
- Keep every core game playable without Apple Intelligence.
- Treat AI output as untrusted: decode, validate, filter, fallback, let the user accept/retry.
- Avoid automatic AI judging for winners, especially in Sound Cinema or social party games.

## Spy / Imposter AI Review Findings

- The strongest current AI feature is private spy-card hints via `HintsManager.createSpyCardTextWithAI`, `CategoryHints.getHintsWithAI`, and `AIService.generateSpyHints`.
- Foundation Models gating and fallbacks are present, but the UI currently treats spy hints as unavailable without Apple Intelligence even though manual/fallback hints exist.
- `HintService.startHints` is not called anywhere in the current Imposter flow; the runtime hint overlay appears wired visually but not functionally started.
- `AIService.generateMissionFlavor`, `AIService.generateModeratorLog`, `generateRole`, and `generateRoles` are present but mostly or completely unused in the searched Imposter flow.
- `AITuner` is deterministic fairness logic, not Foundation Models AI; naming and log text make it sound more AI-driven than it is.
- The AI hint pipeline has good spoiler validation, cache, and request limiting, but still relies on raw JSON extraction instead of Foundation Models structured output.
- Runtime public hints, if enabled later, must not use strong true hints such as first letter or word length because all players would see them.
- Debug logs may store secret words and generated hint content; this is local but can become a spoiler/export privacy issue.

## Spy Runtime Events / Chaos Findings - 2026-04-16

- `SPY_EXPLANATION.md` makes the core game loop clear:
  - players look at cards
  - the app picks a starting player
  - players go around and each say exactly one fitting word
  - the social deduction is supposed to come from the players, not from app help
- Because of that, a live public hint system that helps with the secret word is a weak fit.
- A private pre-round spy hint still fits very well because it helps only the spy and does not interrupt the speaking round.
- The current runtime hint system is better reframed as a round-event engine than as a true hint engine.
- The user wants three runtime directions:
  - normal `Chaos` mode with pressure / moderation / event prompts
  - `Chaos+` with AI-generated questions for idea testing
  - optional microphone-assisted local detection for simple signals only
- Product judgement:
  - `Moderation` and `Chaos` fit the game if they affect pace and pressure rather than secret-word discovery.
  - `Chaos+` can be tested, but category-aware or word-aware AI questions must be treated as experimental because they can easily distort the social deduction loop.
  - microphone support is viable only for simple local detection; full semantic live round analysis is too risky and intrusive for the core game.
- Technical judgement:
  - runtime event start/stop must be wired into the actual round lifecycle before any expansion work
  - public fallback hints in the current system are partly inconsistent with the stricter anti-leak rules in the AI pipeline
  - voice should likely become optional per mode because forced spoken interruptions can harm pacing
