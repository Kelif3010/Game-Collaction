# AUDIT: Performance & Stabilität
## Phase 2 — Erstellungsdatum: 2026-04-12

> **Legende:**
> 🔴 KRITISCH — Direkter spürbarer Lag / Crash-Risiko
> 🟠 HOCH — Messbarer Einfluss auf Framerate / Batterie
> 🟡 MITTEL — Unnötige Arbeit, aber keine sichtbaren Lags
> 🟢 NIEDRIG — Technische Schulden, kein messbarer Impact

---

## ABSCHNITT 1: SWIFTUI RE-RENDERS & VIEW-PERFORMANCE

---

### 🔴 P-01: `GameManager.gameState didSet` schreibt bei JEDER Änderung auf Disk

**Datei:** `Games/TimesUp/Managers/GameManager.swift:26-33`

```swift
@Published var gameState = GameState() {
    didSet {
        if let data = try? JSONEncoder().encode(gameState.settings) {
            UserDefaults.standard.set(data, forKey: "timesup.settings")
        }
    }
}
```

**Problem:** `gameState` ist das zentrale State-Objekt für TimesUp. Es ändert sich **mehrfach pro Sekunde** (Timer-Ticks, Perk-Animationen, Score-Updates etc.). Jede Änderung triggert:
1. `JSONEncoder().encode()` — CPU-intensive Serialisierung
2. `UserDefaults.standard.set()` — Synchroner Disk-Write

Bei 60 FPS und mehreren State-Updates pro Frame bedeutet das Dutzende Disk-Writes pro Sekunde.

**Fix:** Nur `settings` (nicht den gesamten gameState) persistieren, und nur wenn sich `settings` tatsächlich geändert hat:
```swift
@Published var gameState = GameState()
private var lastPersistedSettings: TimesUpGameSettings?

private func persistSettingsIfChanged() {
    guard gameState.settings != lastPersistedSettings else { return }
    lastPersistedSettings = gameState.settings
    if let data = try? JSONEncoder().encode(gameState.settings) {
        UserDefaults.standard.set(data, forKey: "timesup.settings")
    }
}
```
Aufrufen nur in expliziten Settings-Änderungs-Methoden.

---

### 🔴 P-02: `BetBuddyHintService.allHints` — 247KB Dictionary bei jedem Aufruf neu zusammengebaut

**Datei:** `Games/Bet Buddy/Services/BetBuddyHintService.swift:7-23`

```swift
private static var allHints: [String: String] {   // var = computed, KEIN Cache!
    var combined = ClassicHints.data               // 48KB Dict
    combined.merge(PartyHints.data) { ... }        // +65KB Dict
    combined.merge(SpicyHints.data) { ... }        // +48KB Dict
    combined.merge(AlphabetHints.data) { ... }     // +83KB Dict
    return combined                                 // 247KB Ergebnis
}
```

`static var` mit Closure ist ein **computed property** — kein Cache. Jedes Mal wenn `hintItems(for:)` aufgerufen wird (z.B. beim Laden jedes Challenges), werden 4 Dictionaries mit 247KB Gesamtgröße zusammengebaut.

**Fix:**
```swift
// Einmalig initialisiert (Swift lazy static initialization):
private static let allHints: [String: String] = {
    var combined = ClassicHints.data
    combined.merge(PartyHints.data) { _, new in new }
    combined.merge(SpicyHints.data) { _, new in new }
    combined.merge(AlphabetHints.data) { _, new in new }
    return combined
}()
```
`static let` mit Closure wird **lazy** und **thread-safe** nur einmal ausgeführt.

---

### 🔴 P-03: Timer mit 10 Hz in `SlotRewardFullView` aktualisiert Array und triggert 10x/Sek Re-Render

**Datei:** `Games/TimesUp/Views/TimesUpGameView.swift:428-440`

```swift
timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
    for i in 0..<3 {
        reelSymbols[i] = symbolPool.randomElement()!  // @State Update → Re-Render
    }
}
```

Jeder Timer-Tick ändert ein `@State`-Array → 3 Array-Schreibzugriffe → SwiftUI-View-Diff → Re-Render des SlotReels, **10 Mal pro Sekunde**.

Zusätzlich: `symbolPool.randomElement()!` — **force unwrap** auf `randomElement()`. Falls `symbolPool` leer wäre, gibt es einen Crash.

**Fix:** `TimelineView(.animation)` + `Canvas` für die Slot-Animation verwenden (wie SnowView), keine State-Updates im Timer.

---

### 🟠 P-04: `@ObservedObject var gameManager` in 7+ Child-Views — Thundering-Herd Re-Renders

**Betroffene Dateien:**
```
TimesUpGameView.swift
SettingsView.swift
TimerView.swift
PerkWordText.swift
DrawingPhaseViews.swift
DrawingView.swift
DrawingGameControlsView.swift
```

Alle 7 Views beobachten das **gesamte** `GameManager`-Objekt über `@ObservedObject`. Wenn auch nur eine `@Published`-Property im GameManager sich ändert (und GameManager hat ~25 `@Published` Properties), werden **alle 7 Views neu gerendert**.

**Konkret:** Ein Timer-Tick für `gameState.turnTimeRemaining` triggert Re-Renders in `DrawingView`, `SettingsView` und `PerkWordText`, obwohl diese den Timer-Wert gar nicht anzeigen.

**Fix:** `@ObservedObject` auf granulare Sub-ViewModels aufteilen, oder in die Child-Views nur die Werte als `let`-Parameter übergeben (value-type passing).

---

### 🟠 P-05: `QuestionsGameViewModel` Combine-Forwarding triggert Gesamt-Re-Render bei jeder Engine-Änderung

**Datei:** `Games/Question/ViewModels/QuestionsGameViewModel.swift:54-63`

```swift
engine.objectWillChange
    .receive(on: DispatchQueue.main)
    .sink { [weak self] _ in self?.objectWillChange.send() }
    .store(in: &cancellables)

appModel.objectWillChange
    .receive(on: DispatchQueue.main)
    .sink { [weak self] _ in self?.objectWillChange.send() }
    .store(in: &cancellables)
```

Jede Änderung in `QuestionsEngine` ODER `AppModel` triggert `objectWillChange` im ViewModel, was wiederum alle Views die das ViewModel beobachten neu rendert. Das ist eine "Change-Flood" wenn viele Events hintereinander kommen.

Zusätzlich: `.receive(on: DispatchQueue.main)` in einem `@MainActor final class` ist redundant.

**Fix:**
- `.receive(on: RunLoop.main)` statt `DispatchQueue.main` (weniger Overhead)
- Oder besser: Die 2 Objekte direkt in Views observieren und nur spezifische Properties weiterleiten.

---

### 🟠 P-06: `AnalysisIntroView` und `ScanningBar` — Timer ohne gespeicherte Referenz

**Datei:** `Games/Question/Views/Phases/QuestionsResultsPhaseView.swift:183-191`

```swift
private func animateDots() {
    Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { timer in
        if dots.count >= 3 { dots = "" } else { dots += "." }
    }
    // Timer-Referenz wird ignoriert → Timer läuft für immer
}
```

`AnalysisIntroView` hat keinen `onDisappear`-Handler. Der Timer läuft weiter, nachdem `revealStage` wechselt und die View nicht mehr sichtbar ist. Bis die übergeordnete View verschwindet, feuert der Timer weiter und modifiziert `dots`-State auf einer nicht-sichtbaren View.

**Fix:**
```swift
.task {
    while !Task.isCancelled {
        try? await Task.sleep(for: .milliseconds(400))
        if dots.count >= 3 { dots = "" } else { dots += "." }
    }
}
```

---

### 🟡 P-07: `GameManager.notifyUIChange()` — Doppelter Main-Thread-Dispatch

**Datei:** `Games/TimesUp/Managers/GameManager.swift:40-44`

```swift
private func notifyUIChange() {
    DispatchQueue.main.async { [weak self] in  // Bereits auf MainActor!
        self?.objectWillChange.send()
    }
}
```

`GameManager` ist `@MainActor`. Alle seine Methoden laufen bereits auf dem Main Thread. `DispatchQueue.main.async` von Main Thread aus ist redundant und fügt eine zusätzliche Runloop-Runde hinzu (Verzögerung um einen Frame).

**Fix:**
```swift
private func notifyUIChange() {
    objectWillChange.send()  // Direkt, schon auf MainActor
}
```

---

### 🟡 P-08: `GameManager.appLocale` — UserDefaults-Lesung bei jedem `localized()`-Aufruf

**Datei:** `Games/TimesUp/Managers/GameManager.swift:97-110`

```swift
private var appLocale: Locale {
    let defaults = UserDefaults.standard       // Jedes Mal UserDefaults öffnen
    let useSystem: Bool
    if defaults.object(forKey: "useSystemLanguage") == nil { ... }
    let code = defaults.string(forKey: "selectedLanguageCode")
    return AppLanguage.from(code: code).locale  // Enum-Lookup jedes Mal
}
```

`appLocale` ist ein computed property das `UserDefaults` bei jedem Aufruf von `localized()` liest. Wenn `localized()` während einer Animation mehrfach pro Frame aufgerufen wird, summiert sich das.

**Fix:** `appLocale` cachen und nur bei `AppDidReset`-Notification refreshen.

---

### 🟡 P-09: `QuestionsResultsPhaseView.body` — Komplexe Logik direkt im body

**Datei:** `Games/Question/Views/Phases/QuestionsResultsPhaseView.swift:17-49`

```swift
var body: some View {
    let evaluation = viewModel.lastRevealEvaluation
    let suspectID = evaluation?.selected.first
    let suspectName = suspectID != nil ? viewModel.playerName(for: suspectID!) : "Niemand"
    let liars = evaluation?.liars ?? viewModel.currentLiarIDs
    let isLiar = suspectID != nil && liars.contains(suspectID!)
    // ... viele weitere lets
    let stampType: StampView.StampType
    let stampText: String
    // ... switch statement
    return ZStack { ... }
}
```

`body` ist kein `@State` und wird bei JEDER Re-Render komplett neu ausgewertet. Diese Berechnungen sollten in eine `private var` oder `viewModel` computed property ausgelagert werden.

Dazu: `viewModel.playerName(for: suspectID!)` — **force unwrap** auf Optional.

---

## ABSCHNITT 2: CONCURRENCY & MEMORY

---

### 🔴 C-01: `GameLogic` fehlt `@MainActor` — Timer-Callback auf unbekanntem Thread

**Datei:** `Games/Imposter/Models/GameLogic.swift:12, 576`

```swift
class GameLogic: ObservableObject {  // KEIN @MainActor
    ...
    gameTimer = Timer.scheduledTimer(withTimeInterval: timerTickInterval, repeats: true) { [weak self] _ in
        self?.handleTimerTick()  // handleTimerTick() auf welchem Thread?
    }
}
```

`GameLogic` fehlt `@MainActor`. Die Klasse hat `@Published` Properties und ändert `gameSettings` in `handleTimerTick()`. Wenn `startGameTimer()` von einem `@MainActor`-Context aus aufgerufen wird, läuft der Timer korrekt auf dem Main Runloop. Aber das ist **nicht garantiert** — der Compiler warnt auch nicht (weil `GameLogic` kein `@MainActor` ist).

**Fix:** `@MainActor class GameLogic: ObservableObject` — dann ist die Isolation klar.

---

### 🔴 C-02: `GameManager.deinit` startet Task — kann nach Deallokation nicht garantiert ausgeführt werden

**Datei:** `Games/TimesUp/Managers/GameManager.swift:212-218`

```swift
deinit {
    Task { @MainActor [weak self] in    // Task in deinit = GEFÄHRLICH
        self?.turnTimer.invalidate()
        self?.activeTimeBombTimers.values.forEach { $0.invalidate() }
    }
}
```

`Task` in `deinit` ist ein Anti-Pattern: Der Task wird gestartet, aber der Aufrufer (deinit) kehrt sofort zurück. Das Objekt könnte bereits deallokiert sein wenn der Task ausgeführt wird. Mit `[weak self]` gibt es keinen Crash, aber die Timer könnten nicht invalidiert werden wenn `self` nil ist.

**Fix:** Timer direkt in `deinit` invalidieren (ohne Task, ohne @MainActor):
```swift
deinit {
    turnTimer.invalidate()  // RepeatingMainTimer.invalidate() kann synchron aufgerufen werden
    activeTimeBombTimers.values.forEach { $0.invalidate() }
}
```

---

### 🔴 C-03: 33 `DispatchWorkItem` in GameManager — nicht alle werden bei `stop()` gecancelled

**Datei:** `Games/TimesUp/Managers/GameManager.swift`

**WorkItem-Dictionaries:**
```
swapWordTasks: [UUID: DispatchWorkItem]
invisibleWordHideTasks: [UUID: DispatchWorkItem]
englishWordExpiryTasks: [UUID: DispatchWorkItem]
attackNoticeExpiryTasks: [UUID: [UUID: DispatchWorkItem]]
```

**Problem:** Wenn das Spiel plötzlich beendet wird (User drückt "Beenden"), müssen alle pending WorkItems gecancelled werden. Gibt es eine `stopGame()` Funktion die alle 4 dictionaries leert und cancellt? Das muss geprüft werden — wenn nicht, können WorkItems nach Game-End noch feuern und auf invalid State zugreifen.

---

### 🟠 C-04: `QuestionsGameViewModel` Combine — kein `cancellables`-Cleanup

**Datei:** `Games/Question/ViewModels/QuestionsGameViewModel.swift:47`

```swift
private var cancellables = Set<AnyCancellable>()
```

`QuestionsGameViewModel` hat kein `deinit` das `cancellables.removeAll()` aufruft. In Swift werden AnyCancellable automatisch beim Dealloc der Set gecancelled (wenn die Set deallokiert wird). Das ist korrekt — aber nur wenn `QuestionsGameViewModel` selbst korrekt deallokiert wird. Wenn es durch einen Retain Cycle am Leben gehalten wird, bleiben die Subscriptions aktiv.

**Prüfen:** Ob `QuestionsEngine` oder `AppModel` eine starke Referenz auf `QuestionsGameViewModel` halten.

---

### 🟠 C-05: `MultipeerManager.session` nil-check fehlt beim Senden

**Datei:** `Games Collection/Services/MultipeerManager.swift:162-163`

```swift
func sendToAll(event: String, object: Codable? = nil) {
    guard let session = session, !session.connectedPeers.isEmpty else { return }
```

Das ist korrekt. Aber in `sendToPeer` wird zuerst `guard let session = session else { return }` geprüft, dann `session.send(data, toPeers: [peer])` aufgerufen. **Race Condition:** Zwischen dem `guard` und dem `send` könnte `session` auf einem anderen Thread zu nil gesetzt werden (obwohl `@MainActor` dies verhindert — sofern alle Aufrufe auf Main Thread sind).

---

### 🟡 C-06: `GameLogic` — `[weak self]` in Timer-Callback, aber `handleTimerTick` nicht @MainActor

**Datei:** `Games/Imposter/Models/GameLogic.swift:576-578`

```swift
gameTimer = Timer.scheduledTimer(withTimeInterval: timerTickInterval, repeats: true) { [weak self] _ in
    self?.handleTimerTick()
}
```

`handleTimerTick()` hat keine `@MainActor`-Annotation, aber modifiziert `gameSettings` (ein `@Published` Property). Das kann theoretisch Thread-Unsafe sein (kein Swift Concurrency Warning weil GameLogic kein Sendable ist).

---

### 🟡 C-07: `AppViewModel.timer` — Timer auf Main Thread via `[weak self]` + Task

**Datei:** `Games/Bet Buddy/ViewModels/AppViewModel.swift:432-438`

```swift
timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
    Task { @MainActor [weak self] in
        guard let self else { return }
        if self.timerRemaining > 0 {
            self.timerRemaining -= 1
        } else {
            self.lockVotes()
        }
    }
}
```

Dieses Pattern (Timer → `[weak self]` → `Task { @MainActor }`) ist korrekt aber hat unnötigen Overhead. Da `AppViewModel` bereits `@MainActor` ist, und der Timer normalerweise auf dem Main Runloop läuft, kann einfach `self?.timerRemaining -= 1` ohne den Task-Wrapper aufgerufen werden.

---

## ABSCHNITT 3: DATEN & BINÄR-GRÖßE

---

### 🔴 D-01: 247KB Hint-Data als kompilierter Swift-Code — Binär-Bloat und Memory-Impact

**Dateien:**
```
AlphabetHints.swift    83.173 Bytes  (~2.400+ Einträge)
PartyHints.swift       66.231 Bytes
ClassicHints.swift     48.774 Bytes
SpicyHints.swift       48.991 Bytes
GESAMT:               247.169 Bytes nur für Hints
```

**Problem:** Alle Hint-Daten sind als `static let data: [String: String]` im Swift-Quellcode. Das bedeutet:
1. **Kompilierzeit steigt** — Swift muss riesige Dictionary-Literale parsen
2. **Binär-Größe steigt** — Alle Strings sind im Binary-Segment
3. **Memory:** Sobald eines der Dictionaries zum ersten Mal zugegriffen wird, liegt es komplett im RAM

**Alternative:** JSON-Dateien in den Bundle, lazy geladen:
```swift
// AlphabetHints.json → Bundle.main
static let data: [String: String] = {
    guard let url = Bundle.main.url(forResource: "AlphabetHints", withExtension: "json"),
          let data = try? Data(contentsOf: url),
          let dict = try? JSONDecoder().decode([String: String].self, from: data) else { return [:] }
    return dict
}()
```
Das wäre auch lazy und würde die Swift-Compilierzeit drastisch reduzieren.

---

### 🟠 D-02: Challenge-Data (~100KB) als Swift-Arrays — gleiches Problem

**Dateien:**
```
ClassicChallenges.swift    ~29KB
PartyChallenges.swift      ~33KB
SpicyChallenges.swift      ~30KB
AlphabetChallenges.swift   ~9KB
```

Gleiche Empfehlung: JSON-Dateien. Außerdem könnten die Challenges **on-demand** per Kategorie geladen werden (Lazy Loading), damit nicht alle 4 Kategorie-Pools im Speicher liegen.

---

### 🟠 D-03: Keine Lazy-Loading Strategie für Game-Ressourcen

**Problem:** Alle Bet Buddy Hints + Challenges werden beim ersten Zugriff auf BetBuddyHintService komplett in den RAM geladen (alles auf einmal). Das sind ~350KB reine Textdaten.

Für ein Gerät mit 2-4GB RAM ist das kein absolutes Problem, aber auf älteren Geräten (iPhone XR, 3GB RAM) kann das Probleme verursachen wenn die App bereits viel RAM verbraucht.

**Empfehlung:** Hints per Challenge erst laden wenn der Hint-Button gedrückt wird.

---

### 🟡 D-04: `GameState` in TimesUp wird vollständig (mit allen Words) serialisiert

**Datei:** `Games/TimesUp/Managers/GameManager.swift:26-33`

Das `gameState.settings` (nur Settings) wird in UserDefaults gespeichert (korrekt). Aber `gameState` selbst (mit `terms`, `teams`, `currentTermIndex` etc.) wird nicht persistiert. Das ist eigentlich gut — aber wenn das Spiel crashed oder die App in den Background geht, ist der Spielstand verloren. Eine Checkpoint-Persistierung wäre besser.

---

## ABSCHNITT 4: GAMEMANAGER THREADING & MPC

---

### 🔴 T-01: `GameManager` — `DispatchWorkItem`-Cancellation bei Spielende unklar

**Datei:** `Games/TimesUp/Managers/GameManager.swift`

**Problem:** Der GameManager verwaltet 4 verschiedene WorkItem-Dictionaries für Perk-Effekte:
- `swapWordTasks` — Wort-Tausch nach 3 Sekunden
- `invisibleWordHideTasks` — Wort ausblenden
- `englishWordExpiryTasks` — Englisches Wort ablaufen lassen
- `attackNoticeExpiryTasks` — Angriffs-Benachrichtigungen

**Frage:** Werden alle diese WorkItems in einer `stopGame()`- oder `resetGame()`-Funktion gecancelled? Wenn nicht, können sie nach Spielende noch feuern und `gameState` verändern (das dann in einem ungültigen Zustand ist).

**Empfehlung:** Eine zentrale `cancelAllPendingTasks()` Methode die alle 4 Dictionaries leert:
```swift
func cancelAllPendingTasks() {
    swapWordTasks.values.forEach { $0.cancel() }
    swapWordTasks.removeAll()
    invisibleWordHideTasks.values.forEach { $0.cancel() }
    invisibleWordHideTasks.removeAll()
    // ...
}
```

---

### 🟠 T-02: MPC `session(_ session:, peer:, didChange state:)` — Race Condition bei schnellem reconnect

**Datei:** `Games Collection/Services/MultipeerManager.swift:301-331`

```swift
nonisolated func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
    let currentPeers = session.connectedPeers  // Snapshot auf Background Thread
    
    Task { @MainActor in
        self.connectedPeers = currentPeers     // Update auf Main Thread
        
        if self.role == .host {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.broadcastLobbyState()
            }
        }
        // ...
    }
}
```

Der 0.5 Sekunden Delay für `broadcastLobbyState()` ist als "Stabilitätsverzögerung" kommentiert. Wenn in dieser Zeitspanne ein weiterer Peer sich verbindet oder trennt, wird `broadcastLobbyState()` zweimal aufgerufen — mit leicht unterschiedlichen Peer-Listen. Das kann zu kurzen Lobby-Flackern führen.

**Fix:** Debounce-Pattern statt Fixed-Delay:
```swift
private var lobbyBroadcastTask: Task<Void, Never>?
private func debouncedBroadcastLobby() {
    lobbyBroadcastTask?.cancel()
    lobbyBroadcastTask = Task { @MainActor in
        try? await Task.sleep(for: .milliseconds(300))
        guard !Task.isCancelled else { return }
        broadcastLobbyState()
    }
}
```

---

### 🟠 T-03: `MultipeerManager.receivedMessages` Array wächst unbegrenzt

**Datei:** `Games Collection/Services/MultipeerManager.swift:31, 360`

```swift
@Published var receivedMessages: [MPCMessage] = []
// ...
self.receivedMessages.append(message)
```

Das Array wächst mit jeder empfangenen MPC-Message ohne Limit. In einem langen Multiplayer-Spiel können das tausende Messages sein. Das Array wird für Debugging/Log kommentiert, aber in Production verwendet.

**Fix:** Auf eine maximale Größe begrenzen (z.B. 100 Nachrichten) oder in Production komplett deaktivieren:
```swift
#if DEBUG
self.receivedMessages.append(message)
if self.receivedMessages.count > 100 {
    self.receivedMessages.removeFirst()
}
#endif
```

---

### 🟡 T-04: `GameLogic.startGameTimer()` — Guard nur gegen Double-Start, aber kein Cancel nach Dismiss

**Datei:** `Games/Imposter/Models/GameLogic.swift:570`

```swift
private func startGameTimer() {
    guard gameTimer == nil else { return }
    // ...
    gameTimer = Timer.scheduledTimer(...)
}
```

`deinit` invalidiert den Timer korrekt (`gameTimer?.invalidate()`). Aber wenn `GamePlayView` per `dismiss()` entfernt wird und `GameLogic` als `@StateObject` weiterlebt (weil der Parent es hält), läuft der Timer weiter. Das hängt von der EnvironmentObject-Lifetime ab.

---

### 🟡 T-05: MPC `disconnectGraceInterval` — 30 Sekunden hardcoded ohne User-Konfiguration

**Datei:** `Games Collection/Services/MultipeerManager.swift:51`

```swift
private let disconnectGraceInterval: TimeInterval = 30
```

30 Sekunden ist eine lange Wartezeit. Bei einer kurzen Verbindungsunterbrechung (Pocket-Test, Tunnelfahrt) ist das sinnvoll. Aber in einer Game-Lobby kann es frustrierend sein, wenn ein nicht mehr teilnehmender Spieler 30 Sekunden lang als "getrennt" angezeigt wird. Sollte konfigurierbar oder auf ~15 Sekunden gesenkt werden.

---

## ZUSAMMENFASSUNG PHASE 2

| Priorität | Anzahl | Größte Probleme |
|-----------|--------|-----------------|
| 🔴 Kritisch | 6 | GameState Disk-Writes bei jedem Tick (P-01), Hint-Dict neu gebaut bei jedem Aufruf (P-02), Timer 10x/Sek mit Re-Render (P-03), fehlender @MainActor auf GameLogic (C-01), deinit mit Task (C-02), WorkItem Cancel-Sicherheit (T-01) |
| 🟠 Hoch | 8 | Thundering-Herd in TimesUp Views (P-04), Combine-Flood in Questions (P-05), Timer-Leak AnalysisIntroView (P-06), 247KB Hint Binary-Bloat (D-01), Challenge-Data-Bloat (D-02), MPC receivedMessages unbegrenzt (T-03) |
| 🟡 Mittel | 7 | notifyUIChange Doppel-Dispatch (P-07), appLocale bei jedem localized() (P-08), body-Logik in QuestionsResults (P-09), Combine Cleanup (C-04) |
| 🟢 Niedrig | 2 | disconnectGraceInterval hardcoded (T-05), Timer-Pattern in AppViewModel (C-07) |
| **TOTAL** | **23** | |

---

## TOP-5 SOFORTMASSNAHMEN (Performance)

1. **P-01 FIX:** `GameState.didSet` — Settings nur bei echter Änderung persistieren → sofortiger Lag-Fix in TimesUp
2. **P-02 FIX:** `allHints` zu `static let` ändern → Dictionary wird nur 1x gebaut statt bei jedem Challenge-Wechsel
3. **P-03 FIX:** `SlotRewardFullView` Timer force-unwrap entfernen (`randomElement() ?? SlotSymbol(value: 0)`)
4. **C-01 FIX:** `GameLogic` auf `@MainActor` setzen → Thread-Safety für Imposter Timer garantiert
5. **T-01 FIX:** `cancelAllPendingTasks()` Methode in GameManager implementieren und bei Spielende aufrufen
