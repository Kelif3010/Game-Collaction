# Apple On-Device AI Analysis Plan

## Goal
Create a practical Markdown report for `Games Collection` that evaluates how on-device AI and Apple Intelligence can increase the fun factor of the existing party games.

## Phases

- [x] Phase 1: Read relevant Apple/on-device AI skills and project file map.
- [x] Phase 2: Inspect existing games, AI-related code, data models, and UX surfaces.
- [x] Phase 3: Cross-check current Apple framework capabilities from primary Apple sources.
- [x] Phase 4: Rank concrete feature ideas by fun impact, feasibility, privacy, and App Store risk.
- [x] Phase 5: Write the final report Markdown file in the repository.
- [x] Phase 6: Verify report content and summarize outcome.

## Decisions

- Keep the output strategic and implementation-oriented, not a generic AI feature list.
- Prefer on-device/private approaches first.
- Separate iOS 17-compatible options from iOS 26+/Apple Intelligence options.

## Errors Encountered

| Error | Attempt | Resolution |
|---|---|---|

## New Task: Spy / Imposter AI Deep Review

### Goal
Review and evaluate the AI implementation of the Spy/Imposter game with relevant Apple Intelligence, Foundation Models, SwiftUI, concurrency, and code-quality criteria.

### Phases

- [x] Phase 1: Read relevant skills.
- [x] Phase 2: Inspect AI service, hint generation, role logic, settings UI, and gameplay integration.
- [x] Phase 3: Evaluate strengths, risks, bugs, architecture, privacy, and game-design impact.
- [x] Phase 4: Write a focused Markdown review.
- [x] Phase 5: Verify review and summarize outcome.

## New Task: Spy Runtime Hints / Chaos / Chaos+ / Micro Support

### Goal
Turn the current `Hinweise aktivieren` feature into a clear, game-fitting round-event system for Spy/Imposter with four staged deliverables:
1. renamed and clarified mode model,
2. stable `Moderation` and `Chaos` runtime events,
3. experimental `Chaos+` category-aware AI questions,
4. optional microphone-assisted detection for simple live signals.

### Current State
- Planning complete
- Implementation not started
- Waiting for user `Go` for Phase 1

### Phase Rules
- Execute exactly one phase at a time
- After each phase:
  - update `task_plan.md`
  - update `findings.md`
  - update `progress.md`
  - summarize outcome in chat
  - stop and wait for user `Go`

### Phases

- [ ] Phase 1: Product and settings refactor
  - Define the new feature model for runtime hints:
    - `Aus`
    - `Moderation`
    - `Chaos`
    - reserve `Chaos+` and `Mikro-Unterstützung` as experimental follow-up modes/flags
  - Replace the vague `Hinweise aktivieren` wording with clear in-game naming
  - Update settings UI and persisted settings model
  - Keep existing `Spion-Hinweise anzeigen` separate from runtime events
  - Skills to use:
    - `product-agent`
    - `swiftui-expert-skill`
    - `context-management`

- [ ] Phase 2: Runtime event engine for `Moderation` and `Chaos`
  - Wire runtime start/stop into the actual round flow
  - Make the current `HintService` behave like a round-event engine
  - Remove or avoid public word-revealing hints during live rounds
  - Add curated event pools:
    - neutral moderation prompts
    - pressure/tempo/chaos prompts
  - Tune timing, frequency, overlay behavior, and optional voice behavior
  - Skills to use:
    - `debugging`
    - `swiftui-expert-skill`
    - `apple-intelligence`

- [ ] Phase 3: Experimental `Chaos+` AI questions
  - Add an experimental AI-assisted event type for category-aware questions
  - Start with safe category-aware questions first
  - Only then evaluate stronger word-aware questions behind an explicit experimental flag
  - Build guardrails so AI prompts do not directly leak the secret word
  - Skills to use:
    - `apple-intelligence`
    - `foundation-models`
    - `product-agent`

- [ ] Phase 4: Optional microphone-assisted Chaos support
  - Add clear optional microphone mode
  - Limit live recognition to simple signals:
    - whether someone spoke
    - whether silence was too long
    - whether more than one word was spoken
    - whether obvious duplicate words were repeated
  - Do not build full semantic live round analysis in this phase
  - Add permission flow, visible state, graceful fallback, and basic validation
  - Skills to use:
    - `speech-recognition`
    - `debugging`
    - `apple-intelligence`

### Files Likely In Scope
- `Games/Imposter/Services/SettingsService.swift`
- `Games/Imposter/Views/ImposterSettingsView.swift`
- `Games/Imposter/Services/HintService.swift`
- `Games/Imposter/Views/Components/HintOverlay.swift`
- `Games/Imposter/Models/GameLogic.swift`
- `Games/Imposter/Services/AIService+Hints.swift`
- `Games-Collection-Info.plist`
- possibly new focused files for runtime event definitions / microphone support

### Explicit Constraints
- The core Spy round must still be driven by players, not by the app
- `Spion-Hinweise anzeigen` remains a separate private assist feature
- Public runtime events must not give away:
  - the secret word
  - first letters
  - word length
  - overly direct category narrowing
- `Chaos+` AI questions are treated as experimental and can be cut back if they harm game quality

### Done So Far
- Reviewed current Spy/Imposter AI and hint architecture
- Compared current hint system against `SPY_EXPLANATION.md`
- Identified the main current issue: runtime hint UI exists, but event flow is not cleanly started in the round lifecycle
- Agreed target direction with user:
  - normal `Chaos`
  - `Chaos+` with AI questions for testing
  - optional microphone-assisted support

### Last Step
- Wrote this phased execution plan and persistence strategy to project planning files

### Next Step
- Wait for user `Go` to begin Phase 1 only
