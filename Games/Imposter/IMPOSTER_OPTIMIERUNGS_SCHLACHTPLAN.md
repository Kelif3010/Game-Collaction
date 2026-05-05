# Imposter Optimierungs-Schlachtplan

Stand: 2026-05-04  
Scope: `Games/Imposter`  
Hinweis: Vorhandene Markdown-Dateien wurden fuer diese Analyse nicht gelesen.

## Zielbild

Der Imposter-Bereich soll Swift-6-strikter, iOS-26-faehiger und leichter wartbar werden. Die wichtigsten Ziele sind:

- klare Trennung von UI, Spielregeln, Persistenz, Multiplayer-Protokoll und Plattformdiensten
- kurze SwiftUI-Views mit stabiler View-Struktur und wenig Logik im `body`
- testbare Game- und Voting-Regeln ohne direkte Abhaengigkeit von `MultipeerManager.shared`
- konsistente Namen fuer Spielzustand, Netzwerkpayloads, Rollen, Kategorien und Stores
- moderne Swift-6-Concurrency mit sauberen Actor-Grenzen, `Sendable`-Modellen und weniger `try?`/`print`
- gezielter Einsatz vorhandener Pakete: Lottie, Pow, SFSafeSymbols, swift-algorithms, swift-async-algorithms, swift-collections, swift-numerics

## Aktueller Befund

Der Ordner umfasst ca. 16.221 Swift-Zeilen. Die groessten Komplexitaetstreiber sind:

- `Views/SpyCardExtension.swift` ca. 746 Zeilen
- `Views/VotingView.swift` ca. 688 Zeilen
- `Views/GameSetupView.swift` ca. 613 Zeilen
- `Views/VotingResultsView.swift` ca. 553 Zeilen
- `Services/AIService+Hints.swift` ca. 561 Zeilen
- `Models/GameSettings.swift` ca. 476 Zeilen
- `Views/GamePlayView.swift` ca. 466 Zeilen
- `Views/ImposterGameTimerView.swift` ca. 442 Zeilen
- `Multiplayer/ImposterMultiplayerSheet.swift` ca. 452 Zeilen

Schon gut ist: `@Observable` wird bereits genutzt, `AsyncTimerSequence` ist vorhanden, `SFSafeSymbols` steckt in Rollen/Karten, `OrderedCollections` ist im Voting/Stats-Pfad eingebaut, Lottie ist ueber einen gemeinsamen Wrapper angebunden und iOS-26-FoundationModels sind mit Availability-Checks gekapselt.

Die groessten Baustellen sind: UI-Views enthalten noch Netzwerk- und Spiellogik, `GameSettings` ist gleichzeitig Preferences, Runtime-State, Multiplayer-State und Kategorie-Store-Fassade, `GameLogic` mischt Startlogik, Timer, Rematch, MPC-Rollenverteilung und Rejoin, und `ImposterMPCHandler` hat einen sehr grossen Event-Switch mit vielen stillen Decode-Fehlern.

## Phase 0: Sicherheitsnetz und Baseline

Ziel: Vor dem Umbau eine messbare Ausgangslage schaffen.

Arbeit:

- Build mit Swift-6-Konfiguration pruefen und Warnungen sammeln.
- Kleine Characterization-Tests fuer reine Spiellogik anlegen: Rollenverteilung, Imposter-Cap, Kategorieauswahl, Voting-Auswertung, Word-Guessing.
- Multiplayer-Payload-Codierung testen: `ImposterGameConfig`, Role Assignment, Timer Sync, Rejoin State, Voting Payloads.
- Einen kurzen manuellen Smoke-Test definieren: lokal starten, Multiplayer-Host/Peer, Karten-Reveal, Timer, Voting, Rematch.

Ergebnis:

- Keine Architekturveraenderung, nur Tests und eine klare Fehlerliste.
- Danach koennen Phasen einzeln umgesetzt werden, ohne Verhalten versehentlich zu verlieren.

## Phase 1: Struktur und Namen aufraeumen

Ziel: Dateien und Typen sollen ihre Verantwortung zeigen.

Vorschlag fuer neue Struktur:

```text
Games/Imposter/
  Domain/
    Models/
    Rules/
    Selection/
    Voting/
  State/
    ImposterGameSession.swift
    ImposterSetupState.swift
    ImposterMultiplayerState.swift
  Services/
    AI/
    Audio/
    Haptics/
    Persistence/
    Stats/
  Multiplayer/
    Payloads/
    Routing/
    Lobby/
  Views/
    Setup/
    Gameplay/
    Cards/
    Voting/
    Results/
    Components/
```

Konkrete Umbenennungen:

- `GameSettings` -> aufteilen statt nur umbenennen:
  - `ImposterSetupState`: Spieler, Kategorie, Modus, Rollenoptionen, Timerlimit
  - `ImposterRoundState`: Phase, aktueller Spieler, Timer, Kartenstatus, Ergebnisstatus
  - `ImposterPreferencesStore`: UserDefaults-Settings
  - `ImposterCategoryStore`: Custom Categories
- `GameLogic` -> aufteilen:
  - `ImposterGameCoordinator`: Start/Restart/Navigation-Orchestrierung
  - `ImposterRoundEngine`: reine Round-Regeln
  - `ImposterTimerController`: Timer, Pause, Sync-Zeit
  - `ImposterRematchCoordinator`: Rematch-Angebote und Antworten
- `VoteResult.swift` -> `ImposterVotingManager.swift` und `ImposterVotingResult.swift`
- `SpyCardExtension.swift` -> `SpyCardView.swift`, `CardBackView.swift`, `SpyCardFrontView.swift`, `RoleCardContent.swift`, `WrapHStack.swift`
- `PlayerProfilesStore.swift` aus `Views` nach `Services/Persistence`
- `FairnessState.swift`, `FairnessPolicy.swift`, `ImposterPicker.swift` aus `Views` nach `Domain/Selection`

## Phase 2: Swift 6 und Concurrency

Ziel: striktere Isolation, weniger globale Zugriffe, weniger stille Fehler.

Arbeit:

- Domain-Modelle auf `Sendable`, `Hashable`, `Codable` pruefen: `Player`, `Category`, Payloads, `GameCard`, Voting-Ergebnisse.
- UI-nahe Observable-Klassen explizit `@MainActor @Observable` machen, wenn sie SwiftUI-State besitzen.
- Nicht-UI-Dienste als `actor` oder reine `struct`-Services modellieren:
  - Hint Cache ist schon `actor`, gut.
  - `AIRequestLimiter` sollte eher Actor/Semaphore statt `@MainActor final class` sein.
  - Persistenz-Stores sollten keine UI-Isolation benoetigen.
- `try?` an Netzwerk-/Persistenz-Grenzen durch typed Result oder zentralen Logger ersetzen.
- `print(...)` durch `Logger` aus `OSLog` ersetzen, mit Kategorien: `imposter.ai`, `imposter.mpc`, `imposter.timer`, `imposter.persistence`.
- `Task { @MainActor in ... }` in Views reduzieren: wo moeglich `.task(id:)`, explizite private async Methoden oder Coordinator-Methoden.
- `NotificationCenter.addObserver` in `GameSettings` durch async Notifications oder einen App-Reset-Service ersetzen, damit Lifecycle sauber abgebaut wird.

Swift-6-Risiken:

- `MultipeerManager.shared` ist vermutlich noch `ObservableObject`; Views nutzen `@ObservedObject`. Das ist ok fuer bestehende Infrastruktur, sollte aber ueber eine kleine Adapter-Fassade aus den Imposter-Views herausgezogen werden.
- `GameLogic` haelt `Task`-State und ist `@Observable`; bei `deinit`/Actor-Isolation sauber pruefen.
- Payloads muessen `Sendable` werden, wenn sie ueber async Tasks und Actor-Grenzen gehen.

## Phase 3: GameSettings entflechten

Ziel: Ein Typ soll nicht Setup, Runtime, Multiplayer, Persistenz und Kategorien gleichzeitig tragen.

Aktuelle Problemstellen:

- UserDefaults-DidSets in `GameSettings`
- Multiplayer-Voting-State im gleichen Objekt wie Setup-Optionen
- Kategorienpersistenz im gleichen Typ
- Reset-Logik veraendert Spieler, Multiplayer, Timer und Fairness gleichzeitig

Umbau:

- `ImposterPreferences` als Codable-Werttyp fuer persistente Optionen.
- `ImposterPreferencesStore` fuer UserDefaults read/write.
- `ImposterSetupState` als beobachtbarer UI-State.
- `ImposterRoundState` fuer laufende Runde.
- `ImposterMultiplayerState` fuer Reveal/Voting/Rejoin/Rematch-Zustand.
- `GameSettings` zunaechst als Kompatibilitaets-Fassade behalten, dann schrittweise ersetzen.

Wichtig: Diese Phase inkrementell machen, damit nicht alle Views gleichzeitig geaendert werden muessen.

## Phase 4: Spiellogik und Regeln testbar machen

Ziel: Regeln funktionieren ohne SwiftUI und ohne Multiplayer.

Auslagerungen:

- `ImposterWordAssigner` bleibt Domain, bekommt aber injizierbaren RNG.
- `ImposterPicker` aus `Views` nach `Domain/Selection`.
- `VotingManager.executeVote()` in einen reinen `ImposterVotingEngine` verschieben.
- Stats-Aufzeichnung aus Voting-Regel herausziehen: Engine liefert Ergebnis, Coordinator zeichnet Stats auf.
- `HintsManager` in `SpyHintTextFactory` und `HintAvailabilityService` trennen.
- `WordGuessingManager` in `WordGuessingEngine` und UI-Coordinator trennen.

Paketnutzung:

- `swift-algorithms`: fuer Kombinationen/Permutationen bei Fairness- und Auswahltests.
- `swift-collections`: `OrderedSet`/`OrderedDictionary` weiter nutzen; ggf. `Deque` fuer Logs, Toasts oder Event-Historie.
- `swift-numerics`: nur einsetzen, wenn Fairness-Gewichte/Statistik wirklich numerisch komplexer werden. Nicht kuenstlich einbauen.

## Phase 5: Multiplayer sauber kapseln

Ziel: Imposter-Views kennen nicht mehr `MultipeerManager.shared` direkt.

Aktuelle direkte Zugriffe sitzen u.a. in:

- `GameSetupView`
- `GamePlayView`
- `VotingView`
- `VotingResultsView`
- `TimeOutResultView`
- `WordGuessingView`
- `ImposterGameTimerView`
- `ImposterMPCHandler`
- `ImposterVotingLogic`
- `ImposterGameState`

Umbau:

- `ImposterMultiplayerClient` als Protokoll einfuehren: role, myName, peers, events, send APIs.
- Adapter `MultipeerImposterClient` kapselt `MultipeerManager.shared`.
- `ImposterMPCHandler` in Router + einzelne Event Handler aufteilen:
  - `SetupConfigEventHandler`
  - `RoleAssignmentEventHandler`
  - `TimerSyncEventHandler`
  - `VotingEventHandler`
  - `RejoinEventHandler`
  - `RematchEventHandler`
- Decode-Helfer bauen:

```swift
func decodePayload<T: Decodable>(_ type: T.Type, from event: MPCEvent) throws -> T
```

- Eventtypen nicht als freie Strings in Views senden, sondern zentrale typed API verwenden.
- Host-only und Peer-only Actions als Methoden modellieren, nicht als verstreute `guard role == ...` in Views.

## Phase 6: SwiftUI-Views verkleinern

Ziel: Views lesen wie UI, nicht wie Controller.

Prioritaet:

1. `GameSetupView.swift`
2. `GamePlayView.swift`
3. `VotingView.swift`
4. `VotingResultsView.swift`
5. `SpyCardExtension.swift`
6. `ImposterGameTimerView.swift`
7. `ImposterMultiplayerSheet.swift`

Regeln:

- Keine grossen `private var ...: some View`-Sammlungen als Ersatz fuer echte Subviews.
- Pro sinnvoller Sektion ein kleiner `View`-Typ.
- Button-Actions und `.onChange`-Logik in private Methoden oder Coordinator.
- Keine `AnyView`-Ketten wie in `GameSetupView.applySetupBindings`; besser eigene Modifier oder direkte Modifier-Kette.
- Top-Level-Branching stabilisieren: Root-ZStack/VStack behalten, Phasen als kleine Subviews/Overlays austauschen.

Konkrete Extraktionen:

- `GameSetupView`:
  - `ImposterSetupToolbar`
  - `ImposterSetupOptionsCard`
  - `ImposterSetupSheets`
  - `ImposterSetupBindingsModifier`
  - `ImposterSetupCoordinator`
- `GamePlayView`:
  - `GameplayPhaseRouter`
  - `MultiplayerConnectionToast`
  - `RejoinCoordinator`
  - `CardRevealCoordinator`
- `VotingView`:
  - `VotingPhaseRouter`
  - `VoteLockAnimationView`
  - `MultiplayerVotingCoordinator`
  - `ShootoutResultHandler`
- `SpyCardExtension`:
  - separate Dateien fuer Rueckseite, Vorderseite, Scan-Animation, Rolleninhalt, Layout.

## Phase 7: iOS 26 und neue APIs

Ziel: moderne APIs nutzen, aber mit klaren Availability-Grenzen.

Bereits vorhanden:

- `#if canImport(FoundationModels)` und `#available(iOS 26.0, *)`
- `@Observable`
- `sensoryFeedback`
- `contentTransition(.numericText())`
- `symbolEffect`
- `presentationDetents`
- Lottie 4.x ueber Shared Wrapper

Empfehlungen:

- FoundationModels in `ImposterAIContentService` kapseln. Views und Domain sollten nicht wissen, ob FoundationModels verfuegbar ist.
- `@Generable`/structured output nur in AI DTOs halten, nicht in Domain-Models.
- Availability-Fallbacks zentralisieren: `AIContentProvider.live` und `AIContentProvider.fallback`.
- Wo UI-Animationen rein SwiftUI sind, `PhaseAnimator`/`KeyframeAnimator` pruefen. Lottie bleibt fuer Fingerprint/Lock/Radar-Assets sinnvoll.
- `SFSafeSymbols` konsequent in UI-Komponenten nutzen. Aktuell gibt es viele `Image(systemName:)`; fuer typo-sichere Symbole auf `Image(systemSymbol:)` migrieren, soweit die lokale SFSafeSymbols-Version das unterstuetzt.
- `sensoryFeedback` zentral in Interaktionskomponenten verwenden statt eigene Haptic-Calls und View-Haptics zu mischen.
- Falls Deployment wirklich iOS 26-only wird: alte Availability-Helfer fuer iOS 18 Navigation-Bar-Hiding entfernen. Falls nicht, Fallbacks behalten.

## Phase 8: UI-System und Paketnutzung konsolidieren

Ziel: weniger Wiederholung bei Buttons, Sheets, Karten, Symbolen, Animationen.

Arbeit:

- `ImposterStyle`, `ModernUIComponents`, `SetupComponents` zu einem kleinen Design-System ordnen:
  - `Buttons`
  - `Rows`
  - `Cards`
  - `Sheets`
  - `Badges`
  - `Effects`
- Wiederholte Sheet-Konfigurationen als Modifier:

```swift
.imposterSheetStyle(detents: [.large])
```

- Wiederholte Toasts vereinheitlichen.
- Lottie-Dateinamen als enum:

```swift
enum ImposterLottieAsset: String {
    case fingerprint = "Fingerprint biometric scan"
    case androidFingerprint = "Android Fingerprint"
    case lockUnlock = "Lock Unlock Icon"
    case radar = "Radar animation"
}
```

- Sound-Dateinamen ebenfalls typisieren.
- Pow nur fuer echte besondere Transitions nutzen, nicht fuer Standardbewegung.
- `swift-async-algorithms` weiter fuer Timer-Sequenzen nutzen; Timer-Zyklen zentralisieren.

## Phase 9: Persistenz und Fehlerbehandlung

Ziel: UserDefaults-Zugriffe sind nicht ueberall verteilt.

Aktuell:

- `GameSettings` schreibt viele Optionen direkt in `UserDefaults`.
- `StatsService`, `SettingsService`, `SavedPlayersManager`, `UserDefaultsPlayerProfilesStore`, `CustomCategoryStore`, `VoiceService`, `ImposterHapticsManager` greifen direkt auf `UserDefaults` zu.

Umbau:

- `ImposterDefaultsKeys` zentralisieren.
- Pro Feature ein Store-Protokoll plus UserDefaults-Implementierung.
- JSONEncoder/JSONDecoder als gemeinsame Dependency mit klarer Date-Strategie, wenn noetig.
- Fehler loggen statt still `try?`.
- Store-Tests fuer Kategorien, Spielerprofile, Stats und Preferences.

## Phase 10: Abschlussqualitaet

Ziel: Umbau abschliessen, ohne versteckte Regressions.

Checkliste:

- Build unter Swift 6 ohne neue Warnungen.
- Tests fuer Domain-Regeln und Payloads gruen.
- Manuelle Smoke-Tests lokal und Multiplayer.
- Keine grossen SwiftUI-Dateien mehr ueber ca. 300 Zeilen, ausser begruendete reine Datenlisten.
- Keine direkten `MultipeerManager.shared`-Zugriffe in Views ausser in einem temporaeren Adapter.
- Keine neuen globalen Singletons fuer neue Imposter-Services.
- Keine vorhandenen Animationen, Sounds oder Haptics versehentlich entfernt.

## Empfohlene Reihenfolge nach Go

1. Phase 0: Baseline und Tests.
2. Phase 1: Dateien/Typen verschieben und klare Namen schaffen, ohne Verhalten zu aendern.
3. Phase 6 Teil A: `GameSetupView` entlasten, weil dort Setup, Sheets und MPC stark vermischt sind.
4. Phase 5: Multiplayer-Fassade einfuehren.
5. Phase 3: `GameSettings` inkrementell zerlegen.
6. Phase 4: Voting/Game-Regeln aus UI und Services loesen.
7. Phase 6 Teil B: `GamePlayView`, `VotingView`, `SpyCardExtension`, Results/Timer.
8. Phase 7 bis 9: iOS-26-/API-Modernisierung, Design-System, Persistenz/Logging.
9. Phase 10: Abschlussbuild, Tests, Smoke-Test.

## Quick Wins

- `.DS_Store` aus `Games/Imposter` entfernen und sicherstellen, dass es ignoriert wird.
- `GameSetupView.applySetupBindings` ohne `AnyView` neu schreiben.
- Lottie- und Sound-Dateinamen typisieren.
- `Image(systemName:)` schrittweise zu SFSafeSymbols migrieren.
- `print(...)` in Imposter-Services auf `Logger` umstellen.
- `PlayerProfilesStore.swift` aus `Views` verschieben.
- `VoteResult.swift` passend aufteilen und benennen.
- `AIService+Hints.swift` in Request, Validation, Fallback und Role-Generation trennen.

## Nicht sofort anfassen

- Keine komplette FoundationModels-Neuentwicklung vor dem Architekturumbau.
- Keine SwiftData-Migration, solange Imposter nur UserDefaults/JSON nutzt.
- Kein erzwungener Einsatz von swift-numerics ohne echten mathematischen Bedarf.
- Kein Big-Bang-Rewrite von `GameSettings`; die Kompatibilitaets-Fassade reduziert Risiko.
