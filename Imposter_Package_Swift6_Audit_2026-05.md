# Imposter / Spy — Schlachtplan: Package-Einsatz & Swift 6 / iOS 26 Modernisierung

Stand: 2026-05-02 (Live-Code-Scan aller 61 Swift-Dateien)  
Scope: `Games Collection/Games/Imposter` — ~41.000 Zeilen

---

## Kurzfazit

Der Spy-Teil ist funktional vollständig und läuft auf iOS 26. Er nutzt die Plattform aber noch nicht konsequent nach heutigem Stand aus. Die größten Hebel sind nicht neue Features, sondern:

- Migration von `ObservableObject`/`@Published` auf `@Observable` (14 Dateien betroffen)
- Ersetzen von `Timer`/`DispatchQueue.main.asyncAfter` durch Swift Concurrency (12 Stellen)
- Foundation Models auf strukturierte Ausgaben statt manuellem JSON-Parsing umstellen
- Danach: `Pow` für UI-Polish, `swift-collections` für Multiplayer-State, `swift-async-algorithms` für Timer-Logik

Von den installierten Packages ist für Spy aktuell nur `Lottie` real im Einsatz. Die übrigen fünf sind entweder gar nicht genutzt oder könnten gezielt eingesetzt werden.

---

## Verifizierter Ist-Zustand (Code-Scan 2026-05)

### Package-Status

| Package | Version | Im Imposter-Spiel aktiv? |
|---|---|---|
| `Lottie` | 4.6.0 | Ja — über `SharedLottieView` |
| `Pow` | 1.0.6 | Nein |
| `SFSafeSymbols` | 7.0.0 | Nein |
| `swift-algorithms` | 1.2.1 | Nein |
| `swift-async-algorithms` | 1.1.3 | Nein |
| `swift-collections` | 1.4.1 | Nein |

### Combine-Nutzung — 14 Dateien

Alle als `@MainActor class ... ObservableObject` mit `@Published`:

```
GameLogic.swift       GameSettings.swift    HintService.swift
HintsManager.swift    StatsService.swift    VoteResult.swift
WordGuessing.swift    AIService.swift       AITuner.swift
ModeratorLog.swift    SettingsService.swift SavedPlayers.swift
VoiceService.swift
```

### Swift-6-Warnzeichen

```
ImposterHapticsManager.swift:9   @preconcurrency import UIKit
ImposterHapticsManager.swift:16  nonisolated(unsafe) private var engine: CHHapticEngine?
ImposterHapticsManager.swift:17  nonisolated(unsafe) private var lifecycleObservers: [NSObjectProtocol]
GameLogic.swift:15               nonisolated(unsafe) private var gameTimer: Timer?
```

### Timer / DispatchQueue — 12 veraltete Stellen

```
HintService.swift:82         Timer.scheduledTimer(withTimeInterval: hintInterval, ...)
HintService.swift:253        DispatchQueue.main.asyncAfter(deadline: .now() + 45)
GameLogic.swift:580          Timer.scheduledTimer(withTimeInterval: timerTickInterval, ...)
SpyCardExtension.swift:95    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35)
SpyCardExtension.swift:243   Timer.scheduledTimer(withTimeInterval: interval, ...)
SpyCardExtension.swift:293   DispatchQueue.main.asyncAfter(deadline: .now() + 0.4)
FloatingStartButton.swift:62 DispatchQueue.main.asyncAfter(deadline: .now() + 3)
GameSetupView.swift:121      DispatchQueue.main.async
GameSetupView.swift:139      DispatchQueue.main.async
WordGuessingView.swift:61    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1)
WordGuessingView.swift:353   DispatchQueue.main.asyncAfter(deadline: .now() + 1.5)
VotingView.swift:200         DispatchQueue.main.asyncAfter(deadline: .now() + 1.5)
```

### SF Symbols als rohe Strings — 60+ Stellen, 19 Dateien

Betroffen: `GameModeCard`, `ImposterStyle`, `CompactPlayersList`, `FloatingStartButton`, `HintOverlay`, `RoleActionView`, `ModernUIComponents`, `VoiceSettingsView`, `GameModeSheet`, `ExpandableSpyOptionsSection`, `CategorySelectionSheet`, `SpyShootoutView`, `RolesTutorialView`, `PlayerManagementSheet`, `CategoriesView`, `SpyOptionsView`, `ImposterInfoSheet`, `VotingView`, `GamePlayView`.

### Duplikat-Implementierung (swift-algorithms)

```swift
// Array+Chunked.swift:14–18 — identisch mit chunks(ofCount:) aus swift-algorithms:
func chunked(into size: Int) -> [[Element]] {
    return stride(from: 0, to: count, by: size).map {
        Array(self[$0..<Swift.min($0 + size, count)])
    }
}
```

### Foundation Models — bereits genutzt, aber erste Generation

```
AIService.swift:11       import FoundationModels
AIService+Hints.swift:3  import FoundationModels
VoiceService.swift:11    import FoundationModels
```

Aktuell: String-Prompt → JSON als Text → manuelles Extrahieren via `{...}` / `[...]`  
(AIService+Hints.swift:175, AIService+Hints.swift:279)

---

## Package-Analyse

---

### 1. Lottie 4.6.0

**Empfehlung:** Behalten. Das am klarsten gerechtfertigte Paket im Spy-Spiel.

**Aktuelle Nutzung:**
- Fingerprint/Biometric Scanner auf der Karten-Rückseite — `SpyCardExtension.swift:168`
- Radar-Animation im Multiplayer-Waiting-State — `GamePlayView.swift:571`

**Nächste sinnvolle Kandidaten:**

| View | Animation | Zweck |
|---|---|---|
| `SpyShootoutView.swift:64` | kurzer "target locked" One-shot | dramatischer Moment |
| `VotingResultsView.swift` | "mission accomplished" / "infiltrated" | Spielende-Emotion |
| `TimeOutResultView.swift` | Timeout-Effekt | Countdown-Ende |
| `RolesTutorialView.swift:170` | Role-Reveal | Tutorial-Klarheit |

**Was ich nicht tun würde:** Lottie für normale UI-Zustände. Nur echte Hero-Moments rechtfertigen die Ladezeit einer .lottie-Datei.

**Priorität:** Mittel — optischer Gewinn, aber kein Modernisierungsgewinn.

---

### 2. Pow 1.0.6

**Empfehlung:** Im Spy-Spiel sehr sinnvoll, aktuell komplett ungenutzt.

**Was Pow bringt:** Deklarative SwiftUI-Transitions (flip, pop, vanish, iris, glare) — ersetzt manuelle Kombinationen aus `.scaleEffect` + `.opacity` + `.offset`.

**Konkrete Einbaustellen:**

- **Karten-Flip** — `SpyCardExtension.swift:35`  
  Aktuell: manuelles `.scaleEffect` + `.opacity`  
  Ziel: `.transition(.movingParts.flip)`

- **Vote-Lock-Bestätigung** — `VotingView.swift` (Locking-Animation)  
  Ziel: `.transition(.movingParts.pop)`

- **Target-Auswahl** — `SpyShootoutView.swift:64`  
  Ziel: `.transition(.movingParts.vanish)` für die getroffene Karte

- **Result-Reveal** — `VotingResultsView.swift`  
  Ziel: `.transition(.movingParts.iris(origin:, blurRadius:))` beim Aufdecken des Spions

- **Timer-Critical** — `GamePlayView.swift` bei ≤ 5 Sekunden  
  Ziel: `.transition(.movingParts.glare)` für das Timer-Label

**Warum besser als aktuell:** 79 manuelle Animations-Stellen im Spy-Code — Pow macht die wichtigsten davon deklarativer und konsistenter.

**Priorität:** Hoch für UI-Polish.

---

### 3. SFSafeSymbols 7.0.0

**Empfehlung:** Optional. Für Spy kein Muss auf iOS 26, aber sauberer.

**Warum:** 60+ rohe Symbol-Strings in 19 Dateien. Ein Tippfehler crasht nicht, fällt aber erst zur Laufzeit auf. SFSafeSymbols macht das compile-zeitlich sicher.

**Wo zuerst:**  
Nur zentrale Enum-Properties — dann werden alle abhängigen Views automatisch sicher:

```swift
// RoleType.swift — var icon: String → var icon: SFSymbol
// ImposterStyle.swift:193 — let systemName: String → let systemName: SFSymbol
```

**Wo ich es nicht zuerst anfassen würde:** Einzelne rohe Strings in Views. Das ist mühsam und bringt keinen strukturellen Gewinn.

**Priorität:** Niedrig bis mittel — erst wenn man Enums ohnehin anfasst.

---

### 4. swift-algorithms 1.2.1

**Empfehlung:** Punktuell sinnvoll. Ein Quick Win wartet sofort.

**Sofortiger Quick Win:**  
`Array+Chunked.swift` komplett löschen. Die Funktion `chunks(ofCount:)` aus swift-algorithms ist identisch. Ein Commit, eine Datei weniger, kein eigener Code zu warten.

**Weitere sinnvolle Stellen:**

| API | Wo | Datei |
|---|---|---|
| `uniqued()` | Spieler-Deduplizierung | `PlayerManagementSheet.swift` |
| `combinations(ofCount:)` | Twins / Team-Paarbildung | `GameLogic.swift:289` |
| `chunked(by:)` | Voting-Ergebnis-Gruppen | `VotingResultsView.swift` |

**Priorität:** Mittel. Nur einsetzen, wo die Logik spürbar klarer wird.

---

### 5. swift-async-algorithms 1.1.3

**Empfehlung:** Das interessanteste noch ungenutzte Paket für echte Modernisierung.

**Was es bringt:** Async-Sequenzen für zeitgesteuerte Abläufe — ersetzt `Timer` und `DispatchQueue.main.asyncAfter` mit strukturierter Concurrency und sauberer Cancellation.

**Konkrete Ersetzungen:**

**HintService — Hint-Timer (HintService.swift:82)**
```swift
// Vorher:
hintTimer = Timer.scheduledTimer(withTimeInterval: hintInterval, repeats: true) { [weak self] _ in
    Task { await self?.generateHint() }
}

// Nachher:
hintTask = Task {
    for await _ in AsyncTimerSequence(interval: .seconds(hintInterval), clock: .continuous) {
        guard !Task.isCancelled else { break }
        await generateHint()
    }
}
```

**GameLogic — Game-Timer (GameLogic.swift:580)**
```swift
// Vorher:
gameTimer = Timer.scheduledTimer(withTimeInterval: timerTickInterval, repeats: true) { [weak self] _ in
    Task { @MainActor in await self?.timerTick() }
}

// Nachher:
timerTask = Task { @MainActor in
    for await _ in AsyncTimerSequence(interval: .seconds(timerTickInterval), clock: .continuous) {
        guard !Task.isCancelled else { break }
        timerTick()
    }
}
// → nonisolated(unsafe) private var gameTimer: Timer? (GameLogic.swift:15) verschwindet
```

**Alle UI-Delays (9 Stellen mit DispatchQueue.main.asyncAfter)**
```swift
// Vorher:
DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { ... }

// Nachher:
Task { @MainActor in
    try? await Task.sleep(for: .seconds(1.5))
    // ...
}
```

**Warum das für Swift 6 wichtig ist:**
- Cancellation ist strukturiert statt manuell `timer?.invalidate()`
- Keine Race-Conditions zwischen Timer-Callbacks und `@MainActor`
- `nonisolated(unsafe)` für `gameTimer` verschwindet automatisch

> **Hinweis:** Die genaue `AsyncTimerSequence`-API vor dem Einbau gegen die aktuelle swift-async-algorithms Dokumentation verifizieren — die Initialisierungs-Signatur kann sich je nach Version leicht unterscheiden.

**Priorität:** Sehr hoch für echte Modernisierung.

---

### 6. swift-collections 1.4.1

**Empfehlung:** Sinnvoll für Spy, aber gezielt. Nicht überall.

**Was es bringt:** `OrderedDictionary`, `OrderedSet`, `Deque` — dort wo Reihenfolge und Effizienz zusammen wichtig sind.

**Konkrete Einbaustellen:**

**GameLogic — Multiplayer-State (GameLogic.swift:21–26)**
```swift
// Vorher:
private var multiplayerVotePreview: [String: String] = [:]
private var rematchResponses: [String: Bool] = [:]
private var pendingRoleAcks: Set<String> = []

// Nachher:
private var multiplayerVotePreview: OrderedDictionary<String, String> = [:]
private var rematchResponses: OrderedDictionary<String, Bool> = [:]
private var pendingRoleAcks: OrderedSet<String> = []
// → stabile Reihenfolge für UI-Darstellung ohne explizites sort()
```

**HintService — Hint-Historien (HintService.swift:16–17)**
```swift
// Vorher:
@Published var activeHints: [GameHint] = []
@Published var hintHistory: [GameHint] = []

// Nachher:
var activeHints: Deque<GameHint> = []
var hintHistory: Deque<GameHint> = []
// → O(1) prepend statt O(n) insert(at: 0)
```

**StatsService — Leaderboard (StatsService.swift:61)**
```swift
// Vorher:
@Published private(set) var stats: [String: PlayerStats] = [:]
// Problem: Reihenfolge bei Leaderboard-Darstellung nicht deterministisch

// Nachher:
var stats: OrderedDictionary<String, PlayerStats> = [:]
// → konsistente Reihenfolge ohne sort() bei jedem Render
```

**Priorität:** Mittel — korrektere Semantik, spürbar bei Multiplayer-State.

---

## Swift 6 / iOS 26 Modernisierung (unabhängig von Packages)

---

### A. @Observable statt ObservableObject

**Priorität: Sehr hoch.** Apple empfiehlt für iOS 17+ Observation. Auf iOS 26 gibt es keinen Grund, neue Arbeit noch auf `@Published` aufzubauen.

**Zielbild:**
```swift
// Vorher:
@MainActor class GameSettings: ObservableObject {
    @Published var players: [Player] = []
}
// In Views:
@ObservedObject var gameSettings: GameSettings
@EnvironmentObject var gameLogic: GameLogic

// Nachher:
@MainActor @Observable class GameSettings {
    var players: [Player] = []
}
// In Views:
@Environment(GameSettings.self) var gameSettings
@Bindable var gameSettings: GameSettings  // wenn Binding nötig
```

**Empfohlene Reihenfolge:**
1. `StatsService.swift` — einfachste Migration, wenige @Published
2. `HintService.swift` — Singleton, danach alle abhängigen Views einfacher
3. `GameSettings.swift` — zentrales Modell
4. `GameLogic.swift` — **Achtung: 1052 Zeilen, starke View-Kopplung** — größte Migration, sorgfältig testen
5. Rest der Services

> **Wichtiger Fallstrick:** `GameLogic` mit 1052 Zeilen ist der schwierigste Schritt. Die Migration lohnt sich, aber das ist kein Nachmittag. Sinnvoll wäre, `GameLogic` dabei auch thematisch aufzuteilen (Timer-Logic, Vote-Logic, MPC-Logic als separate Typen).

**Betroffene Views danach:**
- `@ObservedObject` → direkte Property
- `@EnvironmentObject` → `@Environment(...)`
- `SpyOptionsView.swift:5`, `ExpandableSpyOptionsSection.swift:11` u.v.m.

---

### B. ImposterHapticsManager — nonisolated(unsafe) beheben

**Problem (ImposterHapticsManager.swift:16–17):**
```swift
nonisolated(unsafe) private var engine: CHHapticEngine?
nonisolated(unsafe) private var lifecycleObservers: [NSObjectProtocol] = []
```

`nonisolated(unsafe)` ist ein Swift-6-Workaround, kein sauberes Design.

**Empfehlung:** Den Manager zu einem `actor` machen wäre der sauberste Schritt — **aber mit Vorsicht:**  
`CHHapticEngine` muss auf dem Main Thread bedient werden. Ein `actor` erzeugt eine eigene Isolation, die das nicht automatisch garantiert. Vor der Migration sicherstellen, dass alle `engine`-Aufrufe via `@MainActor` laufen oder der Actor explizit auf `@MainActor` isoliert wird:

```swift
@MainActor
final class ImposterHapticsManager {
    private var engine: CHHapticEngine?
    // → @MainActor-Isolation statt nonisolated(unsafe)
    // → CHHapticEngine läuft garantiert auf Main Thread
}
```

Das wäre der sichere Mittelweg: kein `nonisolated(unsafe)`, kein Threading-Risiko.

---

### C. sensoryFeedback in SwiftUI-Views

**Priorität: Mittel.** In reinen SwiftUI-Views gibt es seit iOS 17 die native API:

```swift
// Vorher (direkt in Views):
UIImpactFeedbackGenerator(style: .heavy).impactOccurred()

// Nachher:
.sensoryFeedback(.impact(weight: .heavy), trigger: someState)
```

`ImposterHapticsManager` bleibt für komplexe CoreHaptics-Pattern erhalten. Nur die einfachen Impact-Calls in Views werden ersetzt.

**Betroffene Views:** `SpyCardExtension.swift` (Card-Flip), `VotingView.swift` (Vote-Lock), `SpyShootoutView.swift` (Target-Auswahl).

---

### D. NotificationCenter → Async-Sequenzen

**Priorität: Mittel.** Gilt direkt im Kontext der Haptics-Modernisierung.

```swift
// Vorher (ImposterHapticsManager.swift:62–76):
let didEnter = center.addObserver(
    forName: UIApplication.didEnterBackgroundNotification,
    object: nil, queue: .main
) { [weak self] _ in self?.engine?.stop() }
lifecycleObservers = [didEnter, willEnter]
// + manuelles removeObserver in deinit

// Nachher:
Task { @MainActor in
    for await _ in NotificationCenter.default.notifications(
        named: UIApplication.didEnterBackgroundNotification
    ) {
        engine?.stop()
    }
}
// → kein [NSObjectProtocol]-Array, kein manuelles removeObserver, saubere Cancellation
```

---

### E. Foundation Models — Structured Generation

**Priorität: Sehr hoch.** Apple hat Foundation Models für iOS 26 vollständig auf `@Generable` ausgebaut.

**Aktueller Stand (AIService+Hints.swift:175 und :279):**  
String-Prompt → JSON-String → manuelles Parsen mit `{...}` / `[...]` — fehleranfällig und unnötig aufwändig.

**Ziel:**
```swift
@Generable
struct SpyHintOutput {
    let hints: [String]
    let difficulty: String
}

let result = try await session.respond(
    to: prompt,
    generating: SpyHintOutput.self
)
// result.hints ist direkt [String] — kein JSON-Parsing
```

Apple hat Foundation Models im Februar 2026 aktualisiert. Prompts vor der Migration gegen die aktuelle Modellversion testen, besonders bei Format-sensitiven Ausgaben.

---

## Was ich nicht tun würde

- Mehr Lottie-Animationen einbauen, nur weil das Paket vorhanden ist
- Alle 60+ SF-Symbol-Strings in Views auf einmal ersetzen — zu viel Aufwand für wenig strukturellen Gewinn
- Alle Arrays/Sets blind durch Collection-Typen ersetzen — nur wo Reihenfolge wirklich relevant ist
- `GameLogic` als ersten Schritt der @Observable-Migration nehmen — zu groß, zu viele Abhängigkeiten

---

## Priorisierter Schlachtplan

### Phase 1 — Fundament (höchster Langzeitwert)

| Aufgabe | Dateien | Aufwand | Warum zuerst |
|---|---|---|---|
| `@Observable`-Migration | 13 Services/Modelle | Hoch | Alles andere baut darauf auf |
| `DispatchQueue.asyncAfter` → `Task.sleep` | 9 Stellen | Klein | Sofort sauberer, null Risiko |
| Foundation Models structured generation | `AIService+Hints.swift` | Mittel | Robustheit, iOS-26-Konformität |
| `ImposterHapticsManager` → `@MainActor class` | 1 Datei | Mittel | `nonisolated(unsafe)` entfernen |

### Phase 2 — Package-Integration (nach Phase 1)

| Aufgabe | Dateien | Aufwand |
|---|---|---|
| `Array+Chunked.swift` löschen + `swift-algorithms` | 1 Datei löschen | Minimal |
| Timer → Async-Sequences (`swift-async-algorithms`) | 3 Timer-Stellen | Mittel |
| `swift-collections` für Multiplayer-State + Stats | 3 Dateien | Klein |
| `sensoryFeedback` in Views | 3 Views | Klein |
| `NotificationCenter` → Async in HapticsManager | 1 Datei | Klein |

### Phase 3 — UI-Polish & Typsicherheit

| Aufgabe | Dateien | Aufwand |
|---|---|---|
| `Pow` für Card-Flip, Vote-Lock, Result-Reveal | 3–5 Views | Mittel |
| Weitere Lottie-Animations für Hero-Moments | 3 Views | Klein |
| `SFSafeSymbols` für zentrale Enums | `RoleType`, `ImposterStyle` | Klein |

---

## Gesamtbewertung

| Dimension | Status | Detail |
|---|---|---|
| Funktionalität | Vollständig | Produktionsreif |
| Swift-6-Konformität | Ausbaufähig | `nonisolated(unsafe)` ×4, Combine in 14 Dateien |
| iOS-26-Nutzung | Teilweise | FoundationModels da, aber erste Generation |
| Package-Nutzung | Untergenutzt | 5 von 6 Packages im Imposter-Spiel ungenutzt |
| Timer-Pattern | Veraltet | 12 Stellen mit Timer + DispatchQueue |

**Empfehlung in einem Satz:** Zuerst `@Observable`-Migration und Timer-Modernisierung als strukturelles Fundament — dann sind alle weiteren Package-Integrationen deutlich einfacher und sauberer.

---

## Apple-Dokumentations-Referenzen

- SwiftUI: *Migrating from the Observable Object protocol to the Observable macro*
- SwiftUI: *Managing model data in your app*
- SwiftUI: *Adding accessibility to your app* (sensoryFeedback)
- Foundation Models: *Generating content and performing tasks with Foundation Models*
- Foundation Models: *Generating Swift data structures with guided generation*
- Foundation Models Updates: *February 2026*
- Swift Concurrency: *Migrating to Swift 6*
- Swift Collections: *swift-collections package documentation*
- Swift Async Algorithms: *swift-async-algorithms package documentation*
