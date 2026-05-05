# Imposter – Optimierungs-Schlachtplan

> **Stand:** Mai 2026 | **Scope:** 69 Swift-Dateien, ~10.000 LOC  
> **Ziel:** Swift 6, iOS 26, modernste APIs, maximale Performance, saubere Architektur

---

## Übersicht der Phasen

| Phase | Titel | Priorität | Risiko |
|-------|-------|-----------|--------|
| 1 | Swift 6 Strict Concurrency | Kritisch | Mittel |
| 2 | Architektur-Refaktor (God Object aufbrechen) | Hoch | Hoch |
| 3 | iOS 26 & FoundationModels Upgrade | Hoch | Niedrig |
| 4 | Paket-Integration (SFSafeSymbols, swift-algorithms, Pow) | Mittel | Niedrig |
| 5 | Performance & Laufzeit-Optimierungen | Mittel | Niedrig |
| 6 | View-Schicht & UI/UX Modernisierung | Niedrig | Niedrig |

---

## Phase 1 — Swift 6 Strict Concurrency

### 1.1 `@ObservedObject` → `@Observable` + `@Environment`

**Datei:** `Views/GamePlayView.swift:16`

```swift
// VORHER (Legacy ObservableObject)
@ObservedObject private var mpc = MultipeerManager.shared

// NACHHER (Swift 6 @Observable)
@Environment(MultipeerManager.self) var mpc
```

`MultipeerManager` muss dafür von `ObservableObject` auf `@Observable` migriert werden. Alle `@Published`-Properties fallen weg, `objectWillChange.send()` entfällt.

---

### 1.2 Polling-ACK-Loop → `AsyncStream` / Continuation

**Datei:** `Models/GameLogic.swift:203–211`

```swift
// VORHER: Busy-Wait, blockiert MainActor alle 150ms
while !pendingRoleAcks.isEmpty && Date().timeIntervalSinceReferenceDate < deadline {
    try? await Task.sleep(for: .milliseconds(150))
}

// NACHHER: AsyncStream mit Timeout via swift-async-algorithms
let ackStream = AsyncStream<Void> { continuation in
    self.ackContinuation = continuation
}
try await ackStream
    .first { _ in pendingRoleAcks.isEmpty }
    .timeout(.seconds(2.5), clock: .continuous)
```

Alternativ: `withCheckedContinuation` + Resume in `handleRoleAck()`.

---

### 1.3 `NotificationCenter.addObserver` → Async Stream

**Datei:** `Models/GameSettings.swift:148–152`

```swift
// VORHER: Callback-basiert, potenzielle Retain-Cycles
NotificationCenter.default.addObserver(forName: ..., queue: .main) { [weak self] _ in ... }

// NACHHER: Swift Concurrency Notification Stream
Task { @MainActor [weak self] in
    for await _ in NotificationCenter.default.notifications(named: .init("AppDidReset")) {
        self?.resetSettingsToDefaults()
    }
}
```

---

### 1.4 `Task { @MainActor in }` innerhalb bereits isolierter Klassen entfernen

**Dateien:** `Models/ImposterGameState.swift:99`, `Models/ImposterGameState.swift:287`

Wenn die umgebende Funktion bereits `@MainActor` ist, ist ein innerer `Task { @MainActor in }` redundant und erzeugt unnötigen Task-Overhead:

```swift
// VORHER
Task { @MainActor in
    HintService.shared.stopHints()
}

// NACHHER (direkt aufrufen, da bereits @MainActor-Kontext)
HintService.shared.stopHints()
```

---

### 1.5 Tote Berechnung entfernen

**Datei:** `Models/ImposterWordAssigner.swift:165`

```swift
// VORHER: Ergebnis wird sofort verworfen
_ = playerIds.shuffled()

// NACHHER: Zeile komplett löschen
```

---

### 1.6 `Player.init(from:)` / `encode(to:)` Manual Codable entfernen

**Datei:** `Models/Player.swift:41–65`

Alle Properties sind bereits `Codable`. Die manuelle Implementierung bringt null Mehrwert und ist Fehlerquelle bei künftigen Property-Ergänzungen.

```swift
// VORHER: ~25 Zeilen manuelle Codable-Implementierung

// NACHHER: Komplett löschen, Swift synthesiert alles automatisch
struct Player: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var isImposter: Bool
    var word: String
    var hasSeenCard: Bool
    var isEliminated: Bool
    var role: String?
    var roleType: RoleType?
    var isProtected: Bool
    
    init(name: String) { ... }  // bleibt
}
```

---

### 1.7 `Sendable`-Konformanz für Value Types sicherstellen

Alle `struct`-Modelle, die über Aktorgrenzen gesendet werden (`ImposterRolePayload`, `ImposterGameStateSync`, etc.) in `Models/MPCImposterModels.swift` explizit `Sendable` machen:

```swift
struct ImposterRolePayload: Codable, Sendable { ... }
struct ImposterGameStateSync: Codable, Sendable { ... }
```

---

## Phase 2 — Architektur: God Object `GameSettings` aufbrechen

### 2.1 Problem

`GameSettings` (~477 Zeilen) vereint aktuell:
- Persistierte Einstellungen (numberOfImposters, timeLimit, gameMode…)
- Laufender Spielzustand (gamePhase, currentPlayerIndex, timeRemaining…)
- Multiplayer-Zustand (multiplayerVotes, revealProgress, votingProgress…)
- Kategorie-Management (categories, selectedCategoryIds…)
- Spieler-Management (players, savePlayers, fairnessState…)

Das macht Tests unmöglich und Änderungen riskant.

---

### 2.2 Zielarchitektur

```
ImposterSettingsStore          @Observable – nur UserDefaults-backed Settings
ImposterGameState              @Observable – reiner Spielzustand
ImposterMultiplayerState       @Observable – nur MP-spezifischer Zustand
CategoryStore                  @Observable – Kategorien + Persistenz
```

**`ImposterSettingsStore`** (übernimmt ~120 Zeilen aus GameSettings):
```swift
@Observable final class ImposterSettingsStore {
    @AppStorage("imposter.numberOfImposters") var numberOfImposters = 1
    @AppStorage("imposter.timeLimit")         var timeLimit = 300
    @AppStorage("imposter.spyCanSeeCategory") var spyCanSeeCategory = false
    // usw.
    var gameMode: ImposterGameMode  // bleibt JSON-codiert
    var activeRoles: Set<RoleType>
}
```

> `@AppStorage` funktioniert direkt in `@Observable`-Klassen (iOS 17+).

**`ImposterGameState`** (übernimmt ~80 Zeilen):
```swift
@Observable final class ImposterGameState {
    var gamePhase: ImposterGamePhase = .setup
    var currentPlayerIndex: Int = 0
    var timeRemaining: Int = 300
    var isTimerPaused: Bool = false
    var players: [Player] = []
    var roundCategory: Category?
    var fairnessState: FairnessState = .init()
    // Signals für Navigation
    var requestExitToMain = false
    var requestExitToSetup = false
}
```

**`ImposterMultiplayerState`** (übernimmt ~100 Zeilen):
```swift
@Observable final class ImposterMultiplayerState {
    var revealProgress: RevealProgress? = nil
    var isWaitingForOtherPlayers = false
    var shouldPresentVoting = false
    var votingProgress: ImposterVotingStatusPayload? = nil
    var votingSelection: [String]? = nil
    var votes: [String: [String]] = [:]
    var voteTally: [String: Int] = [:]
    // usw.
}

struct RevealProgress {   // statt (ready: Int, total: Int) Tupel
    let ready: Int
    let total: Int
}
```

---

### 2.3 `MultipeerManager` via `@Environment` injizieren

Aktuell: `MultipeerManager.shared` wird in >15 Dateien direkt aufgerufen (GameLogic, ImposterMPCHandler, ImposterGameState, VotingView, etc.).

**Ziel:** Eine einzige `@Environment`-Injection im Root-View, danach kein direkter Singleton-Zugriff mehr in Views.

```swift
// ImposterGameWrapper.swift
.environment(MultipeerManager.shared)

// Views: statt MultipeerManager.shared.role
@Environment(MultipeerManager.self) var mpc
```

---

### 2.4 Navigation-Flags → SwiftUI Navigation

`requestExitToMain`, `requestExitToSetup`, `shouldDismissSheets` sind State-Flags die als Signale missbraucht werden. Besser:

```swift
// NavigationPath oder @Binding<Bool> dismiss direkt
@Environment(\.dismiss) private var dismiss
```

---

## Phase 3 — iOS 26 & FoundationModels

### 3.1 Structured Generation mit `@Generable`

**Datei:** `Services/AIService.swift`

Aktuell wird `session.respond(to: prompt)` verwendet und ein Freitext zurückgegeben. iOS 26 / FoundationModels bietet strukturierte Generierung mit dem `@Generable`-Makro:

```swift
import FoundationModels

@Generable
struct MissionFlavor {
    @Guide(description: "Ein spannender Satz für die Mission, max. 80 Zeichen")
    var headline: String
    
    @Guide(description: "Optionaler zweiter Satz als dramatischer Abschluss")
    var subline: String?
}

@Generable
struct SpyHint {
    @Guide(description: "Ein Hinweis, der die Kategorie umschreibt ohne sie zu nennen")
    var hint: String
    
    @Guide(description: "Schwierigkeitsgrad: leicht / mittel / schwer")
    var difficulty: String
}
```

```swift
// Aufruf
let flavor = try await session.respond(
    to: "Generiere Mission-Flavor für Kategorie '\(category.name)'",
    generating: MissionFlavor.self
)
// flavor.headline ist typsicher, kein String-Parsing mehr
```

---

### 3.2 `LanguageModelSession` Session-Recycling

**Datei:** `Services/AIService.swift:26–68`

Aktuell wird bei jedem Aufruf die bestehende Session gecheckt. Eine Session sollte langlebig sein und nur neu erstellt werden wenn nötig:

```swift
@available(iOS 26.0, *)
private lazy var aiSession: LanguageModelSession = {
    LanguageModelSession(instructions: systemInstructions)
}()
```

Außerdem sollte `isResponding` durch eine Task-basierte Semaphore ersetzt werden, damit parallele Aufrufe nicht kollidieren.

---

### 3.3 AVSpeechSynthesizer → neue iOS 26 TTS API prüfen

**Datei:** `Services/AIService.swift:122–163` und `Services/VoiceService.swift`

iOS 26 bringt verbesserte AVSpeechSynthesis-APIs. Prüfen ob:
- `AVSpeechSynthesisVoice` neue `.premium`-Quality vorhanden
- Neue `AVSpeechSynthesizer.write(_:toBufferCallback:)` für Buffer-basiertes Streaming genutzt werden kann
- Personal Voice Unterstützung (`AVSpeechSynthesisPersonalVoiceAuthorizationStatus`)

---

### 3.4 `#if canImport(FoundationModels)` Guards bereinigen

Da das Build-Target iOS 26 ist, kann der `#if canImport` Guard durch ein saubereres `@available(iOS 26.0, *)` ersetzt werden:

```swift
// VORHER: Überall verstreute #if canImport(FoundationModels) Guards

// NACHHER: Einmal im AIService, sauber isoliert
@available(iOS 26.0, *)
private func buildSession() -> LanguageModelSession { ... }
```

---

## Phase 4 — Paket-Integration

### 4.1 `SFSafeSymbols` 7.0.0 — alle String-Literals ersetzen

**Betroffene Dateien:** Alle View-Dateien (~30+ Vorkommen)

Suche nach: `Image(systemName: "...")`

```swift
// VORHER
Image(systemName: "wifi.slash")
Image(systemName: "star.fill")
Image(systemName: "theatermasks.fill")
Image(systemName: "doc.on.doc.fill")
Image(systemName: "questionmark.circle.fill")

// NACHHER
Image(.wifiSlash)
Image(.starFill)
Image(.theatermasksFill)
Image(.docOnDocFill)
Image(.questionmarkCircleFill)
```

Auch `Label("...", systemImage: "...")` Aufrufe ersetzen.

---

### 4.2 `swift-algorithms` 1.2.1 — Algorithmen-Stellen optimieren

**`selectCandidates` in `Models/ImposterVotingLogic.swift:137`:**

```swift
// VORHER: Manuelles grouping + sorting
let grouped = Dictionary(grouping: voteCounts.keys) { voteCounts[$0, default: 0] }
let sortedCounts = grouped.keys.sorted(by: >)

// NACHHER: Mit Algorithms.sorted(by:) und uniqued()
import Algorithms
let sorted = voteCounts.sorted(using: KeyPathComparator(\.value, order: .reverse))
let selected = Array(sorted.prefix(requiredCount).map(\.key))
```

**`distributeRoles` in `Models/ImposterWordAssigner.swift`:**

```swift
// VORHER: Manuelles shuffled() + Set-Tracking
var availableIds = Set(playerIds)

// NACHHER: randomSample(count:) aus swift-algorithms
import Algorithms
let imposterIds = playerIds.randomSample(count: imposterCount)
```

**Kategorie-Auswahl in `chooseRoundCategory()`:**

```swift
// VORHER: pool.randomElement()

// NACHHER: Mit gewichteter Auswahl wenn Fairness-Pool vorhanden
// Algorithms.weightedRandomElement falls swift-numerics Gewichte bereitstellt
```

---

### 4.3 `swift-async-algorithms` 1.1.3 — Timer & Streams

**Timer-Merge für Multiplayer-Sync:**

```swift
import AsyncAlgorithms

// VORHER: Zwei getrennte Timer-Logiken (tick + sync)
// NACHHER: merge() für gleichzeitige Streams
let timerAndSync = merge(
    AsyncTimerSequence(interval: .milliseconds(250), clock: .continuous),
    syncRequestStream
)
for await event in timerAndSync { ... }
```

**`debounce` für Voting-Tally-Updates:**

```swift
// VORHER: Jedes Preview-Update sendet sofort per MPC
// NACHHER: Debounce verhindert Spam
for await _ in previewStream.debounce(for: .milliseconds(100), clock: .continuous) {
    broadcastTallyUpdate()
}
```

---

### 4.4 `swift-collections` 1.4.1 — `Deque` für Hint-Rotation

**Datei:** `Models/HintsManager.swift` / `Services/HintService.swift`

Die zyklische Hint-Rotation nutzt aktuell einen Index-Zähler. Mit `Deque` aus swift-collections:

```swift
import Collections
var hintQueue: Deque<String> = Deque(category.hints)

func nextHint() -> String {
    guard let hint = hintQueue.popFirst() else { return "" }
    hintQueue.append(hint)  // rotiert ans Ende
    return hint
}
```

---

### 4.5 `Pow` — Transitions in Ergebnis-Views

**Dateien:** `Views/VotingResultsView.swift`, `Views/TimeOutResultView.swift`

```swift
import Pow

// VORHER
.transition(.move(edge: .top).combined(with: .opacity))

// NACHHER: Pow-Effekte
.transition(.movingParts.swoosh)          // für Karten
.transition(.movingParts.pop)             // für Treffer-Reveals
.transition(.movingParts.blur)            // für Phase-Wechsel
.changeEffect(.impact(.heavy), value: voteCount)  // Haptic-begleitend
```

---

### 4.6 `swift-numerics` 1.1.1 — FairnessPolicy Berechnungen

**Datei:** `Views/ImposterPicker.swift`, `Views/FairnessPolicy.swift`

Die Gewichtungsformel `alphaFrequencyPenalty * 0.6 + betaDistanceBonus * 0.2` kann mit `swift-numerics` präziser und overflow-sicher berechnet werden:

```swift
import Numerics

// Gewichte als Double.Logarithm für präzisere Verteilung bei großen Spielermengen
let weight = Double.exp(-alpha * Double(timesImposter)) * (1.0 + beta * Double(roundsSince))
```

---

## Phase 5 — Performance & Laufzeit

### 5.1 Timer-Tick von `@MainActor` entlasten

**Datei:** `Models/ImposterGameState.swift:57–115`

`handleTimerTick()` läuft alle 250ms auf dem MainActor und macht:
- `ProcessInfo.systemUptime` Aufruf
- Mathematik
- Optional MPC-Broadcast
- Haptic-Trigger

**Optimierung:** Zeitberechnung in einen Background-Actor auslagern, nur UI-Updates auf MainActor:

```swift
actor TimerActor {
    private var precise: TimeInterval
    func tick(delta: TimeInterval) -> (display: Int, didChange: Bool) { ... }
}

// MainActor empfängt nur fertige Displaywerte
let result = await timerActor.tick(delta: delta)
if result.didChange {
    gameSettings.timeRemaining = result.display
}
```

---

### 5.2 `StatsService.persist()` — Batched Writes

**Datei:** `Services/StatsService.swift:162`

Aktuell schreibt jede `save(stat:)`-Operation sofort in UserDefaults via `Task.detached`. Bei schnellen Spielenden (timeout → stats für 8 Spieler) entstehen 8 parallele Writes.

```swift
private var pendingPersist = false

private func schedulePersist() {
    guard !pendingPersist else { return }
    pendingPersist = true
    Task.detached(priority: .utility) { [weak self] in
        try? await Task.sleep(for: .milliseconds(500))
        await self?.flushToDisk()
    }
}
```

---

### 5.3 Duplizierte `players.filter { ... }.count` cachen

**Datei:** `Models/ImposterGameState.swift:100–112`

```swift
// VORHER: Zwei filter-Passes über das gleiche Array
let spies = gameSettings.players.filter { $0.isImposter || ... }
let citizens = gameSettings.players.filter { !$0.isImposter && ... }

// NACHHER: Ein Pass mit partitioned(by:) aus swift-algorithms
let (spies, citizens) = gameSettings.players.partitioned(by: { $0.isImposter || $0.roleType?.team == .imposter })
```

---

### 5.4 `MissionTemplateCatalog.load()` asynchron machen

**Datei:** `Services/AIService.swift:213–224`

```swift
// VORHER: Synchrones Data(contentsOf:) auf dem MainActor
static func load() -> MissionTemplateCatalog? {
    let data = try Data(contentsOf: url)  // blockiert!
    ...
}

// NACHHER: Async laden, einmalig gecacht
static func load() async throws -> MissionTemplateCatalog {
    let (data, _) = try await URLSession.shared.data(from: url)
    return try JSONDecoder().decode(MissionTemplateCatalog.self, from: data)
}
```

---

### 5.5 `rebuildCategories()` lazy machen

**Datei:** `Models/GameSettings.swift:342`

`rebuildCategories()` wird bei jeder `persistCustomCategories()`-Änderung aufgerufen. Für große Category-Listen kann das lazy gecacht werden:

```swift
private var _cachedCategories: [Category]?

var categories: [Category] {
    if let cached = _cachedCategories { return cached }
    let rebuilt = buildCategories()
    _cachedCategories = rebuilt
    return rebuilt
}

private func invalidateCategoriesCache() {
    _cachedCategories = nil
}
```

---

## Phase 6 — View-Schicht & UI Modernisierung

### 6.1 Liquid Glass Material für Hauptcontainer

**Datei:** `Views/Components/ImposterStyle.swift`, `Views/GamePlayView.swift`

iOS 26 / Liquid Glass für Karten und Container:

```swift
// VORHER: Custom-Gradient-Hintergrund
ImposterStyle.backgroundGradient.ignoresSafeArea()

// NACHHER: Liquid Glass Material
.glassEffect(.regular.tinted(.green.opacity(0.1)))
```

Karten-Container in Voting, CardReveal und Timer-Views können `GlassEffectContainer` nutzen.

---

### 6.2 Toast-Views in `GamePlayView` auslagern

**Datei:** `Views/GamePlayView.swift:61–95`

Die zwei Toasts (disconnect / reconnect) sind Copy-Paste mit unterschiedlichen Farben. Extraktion:

```swift
struct ConnectionToast: View {
    let name: String
    let isDisconnect: Bool
    
    var body: some View { ... }
}
```

---

### 6.3 `LottieView` auf Lottie 4.6.0 API aktualisieren

**Datei:** `Views/Components/LottieView.swift`

Lottie 4.6.0 bringt Swift Concurrency-basiertes Laden. Prüfen ob:
- `LottieAnimation.named(_:)` durch async Variant ersetzt werden kann
- `DotLottieFile` für `.lottie`-Format korrekt genutzt wird (statt `.json`)

---

### 6.4 `ImposterGameMode.description` → `LocalizedStringResource`

**Datei:** `Models/GameSettings.swift:427–451`

Hardkodierte deutsche Strings für zukünftige Lokalisierbarkeit vorbereiten:

```swift
var description: LocalizedStringResource {
    switch self {
    case .classic:  return "game.mode.classic.description"
    // usw.
    }
}
```

---

## Datei-Checkliste

| Datei | Phase | Maßnahmen |
|-------|-------|-----------|
| `Models/Player.swift` | 1 | Manual Codable entfernen |
| `Models/GameLogic.swift` | 1, 2 | ACK-Loop, @Environment MPC |
| `Models/GameSettings.swift` | 1, 2 | NotificationCenter, @AppStorage, aufbrechen |
| `Models/ImposterGameState.swift` | 1, 5 | Task-Redundanz, Timer-Actor |
| `Models/ImposterVotingLogic.swift` | 4 | swift-algorithms selectCandidates |
| `Models/ImposterWordAssigner.swift` | 1, 4 | Tote Berechnung, randomSample |
| `Models/VoteResult.swift` | 6 | – |
| `Models/MPCImposterModels.swift` | 1 | Sendable-Konformanz |
| `Services/AIService.swift` | 3 | @Generable, Session-Recycling, #if Guards |
| `Services/StatsService.swift` | 5 | Batched Writes, partitioned |
| `Services/HintService.swift` | 4 | Deque Rotation |
| `Multiplayer/ImposterMPCHandler.swift` | 1, 2 | @Observable MPC |
| `Views/GamePlayView.swift` | 1, 6 | @ObservedObject→@Observable, Toast |
| `Views/**/*.swift` (alle) | 4 | SFSafeSymbols, Pow-Transitions |
| `Views/Components/LottieView.swift` | 6 | Lottie 4.6 API |
| `Views/ImposterPicker.swift` | 4 | swift-numerics Gewichte |
| `Views/FairnessPolicy.swift` | 4 | swift-numerics |

---

## Abhängigkeiten zwischen Phasen

```
Phase 1 (Swift 6) ──→ Phase 2 (Architektur) ──→ Phase 3 (iOS 26)
                                │
                                ↓
                    Phase 4 (Pakete) ──→ Phase 5 (Performance)
                                              │
                                              ↓
                                    Phase 6 (Views)
```

Phase 1 und 4 (SFSafeSymbols) können parallel laufen, da sie unabhängig sind.

---

## Quick Wins (sofort, kein Risiko)

1. `_ = playerIds.shuffled()` in `ImposterWordAssigner.swift:165` löschen
2. Manual `Codable` in `Player.swift` entfernen
3. Alle `Image(systemName: "...")` → SFSafeSymbols
4. `Sendable` zu allen MPC-Payload-Structs hinzufügen
5. `Task { @MainActor in HintService.shared.stopHints() }` vereinfachen (bereits @MainActor)
6. `partitioned(by:)` statt doppeltem `filter` in `ImposterGameState`
