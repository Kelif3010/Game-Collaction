# Apple On-Device AI Analysis Progress

## 2026-04-15

- Started Apple/on-device AI analysis for the Games Collection app.
- Read relevant skills: `apple-intelligence`, `apple-on-device-ai`, and `planning-with-files`.
- Enumerated project files and identified game modules plus existing AI-related areas.
- Looked up current Apple primary documentation for Foundation Models, App Intents, Visual Intelligence, Core ML, Natural Language, Vision, Speech, and HIG Generative AI.
- Inspected existing AI code in Imposter and TimesUp.
- Inspected core gameplay hooks for Bet Buddy, Falsche Faehrte, Questions, Sound Cinema, TimesUp, Party Hub, and global stats.
- Cross-checked Apple framework capabilities against official Apple documentation.
- Ranked feature ideas by fun impact, implementation effort, privacy, and product risk.
- Drafted `APPLE_ON_DEVICE_AI_GAME_IDEAS.md`.
- Verified the report file exists, has no placeholder markers, and updated planning status.

## Spy / Imposter AI Review - 2026-04-15

- Started deep review of Spy/Imposter AI.
- Read relevant skills: `apple-intelligence`, `foundation-models`, `swiftui-patterns`, `swift-concurrency`, `coding-best-practices`, and `planning-with-files`.
- Searched all Imposter AI references and identified service, hint, voice, settings, category-hint, and game-logic integration points.
- Inspected AI service, hint generation/validation, HintService, CategoryHints, HintsManager, GameLogic integration, settings UI, voice service, and ModeratorLog.
- Wrote `SPY_AI_REVIEW.md` with findings, score, risks, and prioritized recommendations.
- Verified `SPY_AI_REVIEW.md` exists, has no TODO/placeholder markers, and contains the expected review sections.

## Spy Runtime Events / Chaos Planning - 2026-04-16

- Started planning for the current `Hinweise aktivieren` system after the user reported it feels like beta.
- Read and applied relevant skills for this planning pass:
  - `planning-with-files`
  - `debugging`
  - `product-agent`
  - `apple-intelligence`
  - `speech-recognition`
- Re-checked the existing runtime hint code path:
  - `HintService`
  - `HintOverlay`
  - `GameLogic`
  - `VoiceService`
  - `AIService+Hints`
- Re-read `SPY_EXPLANATION.md` and compared the current public hint concept with the actual game loop.
- Confirmed that public live hints do not cleanly fit the social deduction loop as currently designed.
- Agreed target direction with the user:
  - keep normal Chaos mode
  - also test Chaos+ with AI questions
  - add an optional microphone-assisted local mode for simple signals only
- Added a persistent phased execution plan to `task_plan.md`.
- Added design findings and product/technical constraints to `findings.md`.
- Current status:
  - planning complete
  - no implementation work started
  - waiting for user `Go` for Phase 1
- Last step completed:
  - saved the phased plan and recovery state into the repo planning files
