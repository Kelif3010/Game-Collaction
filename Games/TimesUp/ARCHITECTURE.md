# TimesUp Architecture

TimesUp follows MVVM with a small service layer. Keep all TimesUp-specific code inside
`Games/TimesUp` so refactors in other games stay isolated.

## Folder Map

- `Entry/`: feature entry points, currently `TimesUpWrapper`.
- `Models/`: plain game data and rules data.
  - `Core/`: game state, teams, terms, language, rounds, settings.
  - `Categories/`: category domain models.
  - `Perks/`: perk domain models.
- `ViewModels/`: observable state and user-intent handling for SwiftUI views.
  - `TimesUpGameViewModel`: game flow, teams, turns, rounds, timer orchestration.
  - `TimesUpCategoryViewModel`: category library, persistence, AI generation state.
- `Services/`: platform or external-capability wrappers.
  - AI category generation, word translation, haptics.
- `Resources/`: bundled/static TimesUp data.
- `Features/Drawing/`: drawing-specific MVVM slice.
  - `ViewModels/DrawingViewModel`: canvas state and drawing actions.
  - `Views/`: drawing UI.
- `Views/`: SwiftUI presentation grouped by feature.
  - `Settings/`, `Game/`, `Categories/`, `Perks/`, `Shared/`, `Style/`.

## Rules

- Views should render state and forward user actions to a ViewModel.
- ViewModels own observable state, validation, and game workflow decisions.
- Services should not import SwiftUI unless they specifically wrap UI-facing platform APIs.
- Models should stay independent of SwiftUI view lifecycle and should avoid persistence or UI side effects.
- New TimesUp files should go into the narrowest folder above, not a generic `Managers` folder.
