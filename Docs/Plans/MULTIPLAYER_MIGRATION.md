# Multiplayer-Architektur Migration

**Ziel:** Einheitliche, moderne Multiplayer-Plattform für alle Spiele auf Basis von `AsyncStream` + `swift-async-algorithms`. Neue Spiele können mit minimalem Aufwand angebunden werden.

**Status:** ✅ Alle Phasen abgeschlossen (2026-05-02)

---

## Übersicht: Was sich ändert

| Bereich | Vorher | Nachher |
|---|---|---|
| Event-Bus | `PassthroughSubject` (Combine) | `AsyncStream` |
| Legacy-Callback | `onEventReceived: ((String, Data?) -> Void)?` | entfernt |
| Spiel-Handler | `AnyCancellable` + `.sink()` | `for await` Loop |
| Timing im Handler | `DispatchQueue.main.asyncAfter` (in @MainActor-Klasse) | `try await Task.sleep(for:)` |
| Warten auf alle Spieler | Manuelles Array + Count-Check | `collect(.byCount(n))` |
| Status-Broadcasts | Unkontrolliert bei jedem Event | `debounce` / `throttle` |
| Disconnect-Grace-Period | `[String: Task]`-Dictionary | unverändert, aber sauber isoliert |

---

## Ziel-Architektur

```
MultipeerManager          (Transport + Lobby – bleibt Singleton)
    │
    └─ events: AsyncStream<MPCEvent>   ← NEU (ersetzt PassthroughSubject)
    
GameMultiplayerHandler    (Protokoll – NEU, pro Spiel eine Implementierung)
    │
    ├─ FFMultiplayerHandler    (Falsche Fährte)
    ├─ ImposterMPCHandler      (Imposter – umbenannt/neu)
    └─ QuestionsHandler        (Questions)

Jeder Handler:
    for await event in mpc.events.filter(\.isForThisGame) {
        // typsicher, kein Combine-Import nötig
    }
```

---

## Phase 1 – MultipeerManager modernisieren

**Dateien:** `Games Collection/Services/MultipeerManager.swift`

**Keine Breaking Changes für Spiele in dieser Phase.**

### 1a – `AsyncStream` neben `PassthroughSubject` einführen

```swift
// NEU in MultipeerManager:
private var eventContinuation: AsyncStream<MPCEvent>.Continuation?
let events: AsyncStream<MPCEvent>

// MPCEvent als typsicheres Struct (ersetzt das String-Tuple):
struct MPCEvent: Sendable {
    let type: String
    let payload: Data?
}
```

- `PassthroughSubject` bleibt vorerst bestehen (beide feuern gleichzeitig)
- `onEventReceived` wird als `@available(*, deprecated)` markiert, aber noch nicht gelöscht

### 1b – `DispatchQueue.main.asyncAfter` entfernen

In `session(_:peer:didChange:)` gibt es:
```swift
// VORHER (Zeile 341) – asyncAfter innerhalb Task { @MainActor in } ist redundant:
DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
    self.broadcastLobbyState()
}

// NACHHER:
try? await Task.sleep(for: .milliseconds(500))
self.broadcastLobbyState()
```

### 1c – `nonisolated(unsafe)` Audit

Alle `nonisolated(unsafe)` Stellen im Projekt prüfen (primär in `GameLogic`). Diese sind potenzielle Dataraces unter Swift 6 Strict Concurrency. Vor Phase 4 (Imposter) beheben.

**Abnahmekriterium Phase 1:** Build erfolgreich, alle bestehenden Multiplayer-Features funktionieren unverändert.

---

## Phase 2 – Falsche Fährte als Pilot-Migration

**Dateien:**
- `Games/Falsche Faehrte/Multiplayer/FFMultiplayerHandler.swift`
- `Games/Falsche Faehrte/ViewModels/FFViewModel.swift`

**Warum zuerst Falsche Fährte?** Cleanste Trennung (dedizierter Handler), überschaubare Event-Anzahl (9 Events), kein `nonisolated(unsafe)`.

### 2a – `FFMultiplayerHandler` von Combine auf AsyncSequence

```swift
// VORHER:
import Combine
private var cancellable: AnyCancellable?

func activate(for viewModel: FFViewModel) {
    cancellable = MultipeerManager.shared.eventPublisher
        .receive(on: DispatchQueue.main)
        .sink { [weak self] event in
            self?.handle(type: event.type, data: event.payload)
        }
}

// NACHHER:
import AsyncAlgorithms  // für filter/map auf AsyncSequence
private var listenerTask: Task<Void, Never>?

func activate(for viewModel: FFViewModel) {
    self.viewModel = viewModel
    listenerTask = Task { @MainActor [weak self] in
        for await event in MultipeerManager.shared.events {
            guard let self, !Task.isCancelled else { break }
            self.handle(event)
        }
    }
}

func deactivate() {
    listenerTask?.cancel()
    listenerTask = nil
    viewModel = nil
}
```

- `import Combine` entfällt komplett aus `FFMultiplayerHandler`
- `handle(type:data:)` bleibt inhaltlich unverändert, nur Signatur wird `handle(_ event: MPCEvent)`

### 2b – Host-seitige Bluff/Vote-Sammlung mit `collect`

```swift
// VORHER in FFViewModel:
private var hostCollectedBluffs: [FFBluffSubmitPayload] = []

func hostCollectBluff(_ payload: FFBluffSubmitPayload) {
    hostCollectedBluffs.append(payload)
    if hostCollectedBluffs.count >= players.count {
        hostFinalizeBluffPhase()
    }
}

// NACHHER:
// Im Handler-Task gefiltert sammeln:
let bluffStream = MultipeerManager.shared.events
    .filter { $0.type == MPCEventType.ffBluffSubmit }
    .compactMap { try? decoder.decode(FFBluffSubmitPayload.self, from: $0.payload ?? Data()) }

for await bluffs in bluffStream.collect(.byCount(expectedPlayerCount)) {
    await viewModel?.hostFinalizeBluffPhase(with: bluffs)
}
```

### 2c – Status-Broadcasts throttlen

```swift
// Status-Updates maximal 1x pro 300ms senden:
sendBluffingStatus()  // wird per debounce gedrosselt
```

**Abnahmekriterium Phase 2:** Falsche Fährte Multiplayer End-to-End spielbar auf zwei Geräten. Kein `import Combine` mehr in `FFMultiplayerHandler`.

---

## Phase 3 – `nonisolated(unsafe)` in GameLogic bereinigen

**Datei:** `Games/Imposter/Models/GameLogic.swift`

Vor der Imposter-Migration müssen potenzielle Dataraces behoben werden:

```swift
// VORHER:
nonisolated(unsafe) private var gameTimer: Timer?
nonisolated(unsafe) private var scheduledStartWorkItem: DispatchWorkItem?

// NACHHER:
// Timer auf MainActor-isolierte Task-based Lösung umstellen:
private var timerTask: Task<Void, Never>?
```

`DispatchWorkItem` durch `Task` ersetzen. Das entfernt `nonisolated(unsafe)` und ermöglicht Strict Concurrency ohne Suppress.

**Abnahmekriterium Phase 3:** Build mit `-strict-concurrency=complete` zeigt keine neuen Warnings in `GameLogic`.

---

## Phase 4 – Imposter Migration

**Dateien:**
- `Games/Imposter/Models/GameLogic.swift`
- Diverse Imposter Views mit `DispatchQueue.main.asyncAfter`

### 4a – Dedizierten `ImposterMPCHandler` extrahieren

Aktuell sind Imposter-Events direkt in `GameLogic` verteilt. Ein dedizierter Handler (analog zu `FFMultiplayerHandler`) verbessert die Übersicht und macht das Muster einheitlich.

### 4b – Busy-Wait-Loop ersetzen

```swift
// VORHER (GameLogic – aktives Polling):
while !pendingRoleAcks.isEmpty && Date().timeIntervalSinceReferenceDate < deadline {
    try? await Task.sleep(nanoseconds: 150_000_000)
}

// NACHHER mit AsyncAlgorithms:
let ackStream = mpc.events
    .filter { $0.type == MPCEventType.imposterRoleAck }
    .timeout(.seconds(2.5), clock: ContinuousClock())

for await ack in ackStream {
    pendingRoleAcks.remove(ack.senderName)
    if pendingRoleAcks.isEmpty { break }
}
```

### 4c – `DispatchQueue.main.asyncAfter` in Views

Alle Animation-Delays in Imposter Views auf `Task.sleep(for:)` umstellen. Nicht eilig, aber vereinheitlicht das Muster.

**Abnahmekriterium Phase 4:** Imposter Multiplayer End-to-End spielbar. Kein `DispatchQueue.main.asyncAfter` mehr in Multiplayer-relevantem Code.

---

## Phase 5 – Questions Migration

Gleiche Struktur wie Falsche Fährte:
- Dedizierten `QuestionsMultiplayerHandler` erstellen (analog `FFMultiplayerHandler`)
- `for await` Loop statt Combine
- 13 Event-Types abdecken

**Abnahmekriterium Phase 5:** Questions Multiplayer funktioniert mit neuem Handler.

---

## Phase 6 – Combine komplett entfernen + Template ✅

### 6a – Legacy-Cleanup (erledigt)

- `eventPublisher` (PassthroughSubject) aus `MultipeerManager` entfernt
- `import Combine` bleibt in `MultipeerManager` (nötig für `@Published` / `ObservableObject`)
- `Task.sleep(nanoseconds:)` → `Task.sleep(for:)` in SoundCinema + BetBuddy

> **Hinweis:** `onEventReceived` bleibt vorerst erhalten (noch genutzt von `FFMultiplayerSheet` +
> `ImposterMultiplayerSheet` für den Lobby-Join-Flow). Bereits als `@available(*, deprecated)` markiert.

### 6b – Neues Spiel anbinden: Template

Ein neues Spiel braucht genau drei Dinge:

**1. Event-Types registrieren** in `MPCEventTypes.swift`:
```swift
// MARK: - MeinSpiel
enum MeinSpielEvent {
    static let start = "meinspiel.start"
    static let action = "meinspiel.action"
}
```

**2. Payload-Structs** (Codable):
```swift
struct MeinSpielStartPayload: Codable, Sendable { ... }
```

**3. Handler erstellen:**
```swift
@MainActor
final class MeinSpielMPCHandler {
    weak var viewModel: MeinSpielViewModel?
    private var listenerTask: Task<Void, Never>?

    func activate(for viewModel: MeinSpielViewModel) {
        self.viewModel = viewModel
        listenerTask = Task { @MainActor [weak self] in
            for await event in MultipeerManager.shared.events {
                guard let self, !Task.isCancelled else { break }
                self.handle(event)
            }
        }
    }

    func deactivate() {
        listenerTask?.cancel()
        listenerTask = nil
        viewModel = nil
    }

    private func handle(_ event: MPCEvent) {
        guard let vm = viewModel else { return }
        switch event.type {
        case MeinSpielEvent.start:
            // ...
        default:
            break
        }
    }
}
```

**Abnahmekriterium Phase 6:** `import Combine` existiert in keiner Spiel-Datei mehr. Das Template funktioniert für ein neues Testspiel.

---

## Reihenfolge & Abhängigkeiten

```
Phase 1  ──►  Phase 2  ──►  Phase 3  ──►  Phase 4  ──►  Phase 5  ──►  Phase 6
(MPC Base)    (FF Pilot)    (Unsafe Fix)   (Imposter)    (Questions)   (Cleanup)
```

Jede Phase ist unabhängig testbar. Phasen 2 und 3 können parallel bearbeitet werden.

---

## Pakete die aktiv genutzt werden

| Paket | Wo genutzt |
|---|---|
| `swift-async-algorithms` | `collect`, `debounce`, `throttle`, `timeout` in Handlern |
| `swift-algorithms` | bereits genutzt, unverändert |
| `swift-collections` | bereits genutzt, unverändert |

`Combine` wird nach Phase 6 aus allen Spieledateien entfernt. In `MultipeerManager` selbst kann es für `@Published` Properties (SwiftUI-Binding) noch vorhanden sein – das ist akzeptabel.
