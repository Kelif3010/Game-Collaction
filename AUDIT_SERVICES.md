# AUDIT: Globale Services & Multiplayer — Phase 4.5
## Erstellungsdatum: 2026-04-12

> Vollständiger Audit der globalen Services: MultipeerManager (P2P Multiplayer),
> GlobalPlayerManager (iCloud), GlobalStatsManager (Statistiken), SoundManager,
> AppDelegate/SceneDelegate, QuickActionManager.
> Dateien: 11 Swift-Dateien in Games Collection/Services/

---

## ÜBERSICHT

| Kategorie | Findings |
|-----------|----------|
| Kritische Bugs | 3 |
| Logik-Fehler | 4 |
| Feature-Lücken | 4 |
| Code-Qualität | 4 |
| **TOTAL** | **15** |

---

## KATEGORIE A: KRITISCHE BUGS

---

### SVC-01: `receivedMessages` Array wächst unbegrenzt — Memory Leak im Multiplayer 🔴

**Datei:** `Games Collection/Services/MultipeerManager.swift:360`

```swift
self.receivedMessages.append(message)
// ↑ Wird NIEMALS geleert!
```

`receivedMessages: [MPCMessage]` ist ein `@Published` Array das bei jeder
empfangenen MPC-Nachricht um eine Einheit wächst und **niemals zurückgesetzt wird**.
In einer Spielsession mit 4 Spielern über 30 Minuten können hunderte Nachrichten
(Timer-Syncs, Vote-Updates, State-Broadcasts) akkumulieren.

Gleichzeitig: Views die `receivedMessages` observieren (`MPCDebugView`) re-rendern
bei jedem Append. Das kostet CPU und Speicher.

**Fix:**
```swift
// Maximale Größe begrenzen:
self.receivedMessages.append(message)
if self.receivedMessages.count > 100 {
    self.receivedMessages.removeFirst(self.receivedMessages.count - 100)
}
```

---

### SVC-02: iCloud Merge-Strategie überschreibt lokale Spieler ohne Warnung 🔴

*(Bereits als DA-02 in AUDIT_SWIFTUI.md dokumentiert — hier vertieft)*

**Datei:** `Games Collection/Services/GlobalPlayerManager.swift:113-116`

```swift
// Merge Logic: We simply take the cloud version as truth for simplicity in V1.
// In a complex app, we would merge arrays by ID.
self.players = decoded   // ← Lokale Spieler werden KOMPLETT überschrieben!
```

**Scenario:** Nutzer hat auf Gerät A 5 Spieler erstellt. Gerät B war offline und
hat 3 andere Spieler. Wenn Gerät B online geht, wird iCloud-Sync ausgelöst.
Je nach welche Version zuletzt geschrieben hat, verliert ein Gerät alle Spieler.

Der Kommentar im Code bestätigt: `"We simply take the cloud version as truth"` —
das ist bewusst primitiv und sollte für V2 gemergt werden.

**Fix (UUID-basiertes Merge):**
```swift
@objc private func iCloudDataDidUpdate(notification: NSNotification) {
    DispatchQueue.main.async { [weak self] in
        guard let self, let data = self.iCloudStore.data(forKey: self.storageKey),
              let cloudPlayers = try? JSONDecoder().decode([GlobalPlayer].self, from: data) else { return }

        // Merge: Union von lokalen und Cloud-Spielern (by ID)
        var merged = Dictionary(uniqueKeysWithValues: self.players.map { ($0.id, $0) })
        for cloudPlayer in cloudPlayers {
            merged[cloudPlayer.id] = cloudPlayer // Cloud-Version gewinnt bei Konflikt
        }
        self.players = Array(merged.values).sorted { ... }
        self.savePlayers()
    }
}
```

---

### SVC-03: Host-Disconnect während Spielrunde — Clients haben keinen Recovery-Path 🔴

*(Bereits als UX-18 dokumentiert — hier technisch vertieft)*

**Datei:** `Games Collection/Services/MultipeerManager.swift:243-279`

**Problem:**
`markPeerDisconnected()` hat eine 30-Sekunden Grace Period für Re-Joins.
Das ist gut für kurze Verbindungsunterbrechungen. Aber:

1. Wenn der **Host** disconnectet, läuft die Grace Period ab und der Host wird
   aus der Lobby entfernt — aber das Spiel läuft auf Client-Geräten weiter
   (ohne Timer-Sync, ohne Vote-Handling)
2. Es gibt keinen "Host ist weg" Notification an Clients
3. Kein automatischer Host-Transfer (das wäre komplex, aber ein Alert wäre Minimum)

```swift
// In broadcastLobbyState() — kein Check ob der Host selbst der disconnected Peer ist:
private func markPeerDisconnected(_ name: String) {
    guard role == .host else { return }  // ← Nur Host erkennt Disconnects!
    // Clients erkennen Host-Disconnect gar nicht aktiv
}
```

---

## KATEGORIE B: LOGIK-FEHLER

---

### SVC-04: `GlobalStatsManager.recordWin` wird nur von Imposter aufgerufen — BetBuddy/Question ignoriert es 🟠

*(Bereits als DA-01/D-08 bekannt)*

**Datei:** `Games Collection/Services/GlobalStatsManager.swift`

`GlobalStatsManager` hat `recordWin()`, `recordLoss()`, `recordParticipation()` APIs.
Nur Imposter ruft diese auf. Bet Buddy nutzt sein eigenes `AppViewModel.highlights`
System. Question nutzt `AppModel.scores`. TimesUp hat keine externe Stats-Anbindung.

Das `GlobalRecapView` zeigt dadurch fast keine sinnvollen Daten für 3 von 4 Games.

**Fix:** In jedem Game am Ende einer Runde `GlobalStatsManager.shared.recordWin/Loss` aufrufen.

---

### SVC-05: `GlobalStatsManager.timesPlayed` wird doppelt gezählt 🟠

*(Bereits als SL-08 dokumentiert)*

**Datei:** `Games Collection/Services/GlobalStatsManager.swift:40-57`

```swift
func recordWin(for playerName: String) {
    updateStat(for: playerName) { stats in
        stats.wins += 1
        stats.timesPlayed += 1   // +1 hier
    }
}

func recordLoss(for playerName: String) {
    updateStat(for: playerName) { stats in
        stats.losses += 1
        stats.timesPlayed += 1   // +1 hier
    }
}
```

Wenn für einen Spieler zuerst `recordWin` und dann `recordParticipation` aufgerufen wird
(was passiert wenn beides nach einer Runde gecallt wird), zählt `timesPlayed` zweimal.
`winRate = wins / timesPlayed` wird dadurch zu niedrig berechnet.

---

### SVC-06: `sendToHost` nutzt Konvention "erster in lobbyPeers ist Host" — fragil 🟠

**Datei:** `Games Collection/Services/MultipeerManager.swift:202-215`

```swift
func sendToHost(event: String, object: Codable? = nil) {
    guard role == .peer else { return }
    guard let hostName = lobbyPeers.first else { return }  // Konvention: erster = Host
    // ...
}
```

`lobbyPeers` ist eine `[String]` ohne klare Reihenfolge-Garantie. In `broadcastLobbyState()`
wird `allNames = Array(Set(allNames))` genutzt — `Set` hat keine definierte Reihenfolge.
Das bedeutet: der "erste" in `lobbyPeers` ist nach einem Lobby-Rebuild möglicherweise
nicht mehr der Host.

**Fix:** Host-Name explizit speichern:
```swift
@Published var hostPeerName: String? = nil

// In startHosting:
self.hostPeerName = myPeerId.displayName

// In sendToHost:
guard let hostName = hostPeerName else { return }
```

---

### SVC-07: `broadcastLobbyState` nutzt `DispatchQueue.main.asyncAfter(0.5s)` für Stabilität 🟡

**Datei:** `Games Collection/Services/MultipeerManager.swift:311-315`

```swift
DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
    self.broadcastLobbyState()
}
```

Eine 500ms Verzögerung für "Stabilität" ist ein Code Smell. Das deutet auf
eine Race Condition hin die mit einem Timing-Hack gelöst wurde statt mit
korrektem Concurrency-Management.

---

## KATEGORIE C: FEATURE-LÜCKEN

---

### SVC-08: Kein Multiplayer für Bet Buddy oder TimesUp 🟠

**Problem:**
`MultipeerManager` ist global verfügbar und bereits von Imposter und Question
genutzt. Bet Buddy und TimesUp haben kein Multiplayer-Support obwohl der
Infrastructure-Layer vorhanden ist.

Bet Buddy würde sich besonders gut für Multiplayer eignen: Jede Gruppe könnte
auf ihrem Gerät abstimmen, der Host koordiniert die Runde.

---

### SVC-09: QR-Code Service (`QRCodeService`) — Verwendung unklar 🟡

**Datei:** `Games Collection/Services/QRCodeService.swift`

`QRCodeService.swift` existiert in den globalen Services. Wo wird er verwendet?
Für Raum-Code Sharing (statt manueller Zahleneingabe) könnte ein QR-Code sehr
nützlich sein. Ist das Feature noch nicht implementiert oder irgendwo versteckt?

---

### SVC-10: `GlobalStatsManager` hat kein iCloud Backup — Stats nur lokal 🟠

**Datei:** `Games Collection/Services/GlobalStatsManager.swift`

`GlobalPlayerManager` hat iCloud-Sync via `NSUbiquitousKeyValueStore`.
`GlobalStatsManager` speichert nur lokal in UserDefaults. Bei einem Geräte-Wechsel
oder App-Löschung gehen alle Statistiken aller Spieler verloren.

**Fix:** Dasselbe iCloud-Pattern wie `GlobalPlayerManager` verwenden.

---

### SVC-11: Kein Notification-System für kritische Multiplayer-Events in non-game Views 🟡

**Problem:**
Wenn ein Spieler eine Multiplayer-Einladung erhält während er im Hauptmenü ist
(nicht in einer Imposter/Question Setup-View), gibt es keine Push-ähnliche
Benachrichtigung. Der Nutzer muss aktiv in die entsprechende Game-Setup-View
navigieren um den Einladungs-Status zu sehen.

---

## KATEGORIE D: CODE-QUALITÄT

---

### SVC-12: `onEventReceived` Legacy Callback neben `eventPublisher` — Deprecated nicht entfernt 🟡

**Datei:** `Games Collection/Services/MultipeerManager.swift:62`

```swift
/// Legacy Callback für Abwärtskompatibilität (wird zusätzlich zum Publisher aufgerufen)
/// DEPRECATED: Bitte eventPublisher.sink verwenden
var onEventReceived: ((String, Data?) -> Void)?
```

Der Legacy-Callback ist als `DEPRECATED` markiert, bleibt aber im Code. Wenn
alle Consumer bereits auf `eventPublisher` migriert sind, sollte der Callback
entfernt werden.

---

### SVC-13: `GlobalPlayerManager.deinit` ruft `removeObserver` auf `@MainActor` Klasse auf 🟡

**Datei:** `Games Collection/Services/GlobalPlayerManager.swift:34-36`

```swift
deinit {
    NotificationCenter.default.removeObserver(self)
}
```

`deinit` läuft auf einem beliebigen Thread. `NotificationCenter.removeObserver`
ist thread-safe, aber das Pattern mit `addObserver(self, selector:...)` in einem
`@MainActor`-Singleton der niemals de-initialisiert wird, ist unnötig.

Da `GlobalPlayerManager.shared` ein Singleton ist, wird `deinit` nie aufgerufen.
Der Observer wird also nie entfernt — das ist OK, aber der `deinit` Block
suggeriert eine Cleanup-Logik die nie ausgeführt wird.

---

### SVC-14: `MPCEventTypes` als Strings — kein Typ-Safety zwischen Games 🟠

**Datei:** `Games Collection/Services/MPCEventTypes.swift`

MPC-Events werden als String-Konstanten definiert. Wenn ein Event-Name sich ändert
oder ein Tippfehler entsteht, gibt es keinen Compile-Fehler. Das ist besonders
kritisch da Imposter und Question beide auf denselben EventType-Strings aufbauen.

**Fix:**
```swift
// Statt String-Konstanten:
enum MPCEventType {
    static let lobbyUpdate = "LOBBY_UPDATE"
    static let imposterSyncConfig = "IMPOSTER_SYNC_CONFIG"
    // ...
}

// BESSER — typisiertes Enum das Codable Events wrапpt:
enum GameEvent: Codable {
    case imposterSyncConfig(ImposterConfigPayload)
    case lobbyUpdate([String])
    case votingResult(VotingPayload)
}
```

---

### SVC-15: Drei Singleton-Patterns — `static let shared`, `@StateObject` und `@EnvironmentObject` gemischt 🟠

*(Bereits als SW-04 in AUDIT_SWIFTUI.md dokumentiert — hier Service-Perspektive)*

| Service | Zugriffs-Pattern |
|---------|-----------------|
| `MultipeerManager` | `MultipeerManager.shared` (Singleton) |
| `GlobalPlayerManager` | `GlobalPlayerManager.shared` (Singleton) |
| `GlobalStatsManager` | `GlobalStatsManager.shared` (Singleton) |
| `StatsService` (Imposter) | `StatsService.shared` (Singleton) |
| `HintService` (Imposter) | `HintService.shared` (Singleton) + `@StateObject` in Views |
| `AIService` (Imposter) | `AIService.shared` (Singleton) |

Singletons werden in manchen Views über `.shared` direkt zugegriffen,
in anderen über `@StateObject` wrapping. Das macht Dependency-Tracking schwerer.

---

## ZUSAMMENFASSUNG SERVICES AUDIT

| Priorität | Anzahl | Top-Findings |
|-----------|--------|-------------|
| 🔴 Kritisch | 3 | receivedMessages Memory Leak (SVC-01), iCloud überschreibt lokale Daten (SVC-02), Host-Disconnect ohne Recovery (SVC-03) |
| 🟠 Hoch | 6 | Stats nur in Imposter (SVC-04), timesPlayed Doppelzählung (SVC-05), sendToHost fragil (SVC-06), kein MP für BetBuddy/TimesUp (SVC-08), Stats kein iCloud (SVC-10), MPCEventTypes nicht typsicher (SVC-14) |
| 🟡 Mittel | 6 | asyncAfter Hack (SVC-07), QRCode unklar (SVC-09), kein MP Notification (SVC-11), Legacy Callback (SVC-12), deinit auf Singleton (SVC-13), Singleton-Mix (SVC-15) |

---

*Erstellt: 2026-04-12 — Teil von Phase 4 des Gesamtaudits*
