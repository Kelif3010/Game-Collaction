# AUDIT: Bet Buddy — Phase 4.2
## Erstellungsdatum: 2026-04-12

> Vollständiger Audit der Bet Buddy Spiellogik, Features, Bugs und Verbesserungspotenzial.
> Dateien: 47 Swift-Dateien in Games/Bet Buddy/

---

## ÜBERSICHT

| Kategorie | Findings |
|-----------|----------|
| Kritische Bugs | 2 |
| Logik-Fehler | 4 |
| Feature-Lücken | 5 |
| Code-Qualität | 5 |
| **TOTAL** | **16** |

---

## KATEGORIE A: KRITISCHE BUGS

---

### BB-01: Session-Scores nicht persistiert — bei App-Crash alles verloren 🔴

**Datei:** `Games/Bet Buddy/ViewModels/AppViewModel.swift`

*(Bereits als UX-15 bekannt, hier vertieft)*

```swift
@Published private(set) var scores: [UUID: Int] = [:]  // Nur RAM!
```

`scores` wird niemals in UserDefaults gespeichert. Bei:
- App-Crash
- Swipe-to-Close während einer Spielrunde
- iOS Background-Terminate

sind alle aktuellen Punkte weg. Bei langen Sessions (30+ Runden) ist das frustrierend.

**Fix:** `scores` in `didSet` persistieren:
```swift
@Published private(set) var scores: [UUID: Int] = [:] {
    didSet {
        if let data = try? JSONEncoder().encode(scores) {
            UserDefaults.standard.set(data, forKey: "betbuddy.sessionScores")
        }
    }
}
```

Und beim Init wiederherstellen:
```swift
if let data = defaults.data(forKey: "betbuddy.sessionScores"),
   let saved = try? JSONDecoder().decode([UUID: Int].self, from: data) {
    self.scores = saved
}
```

---

### BB-02: `ChallengeData.classic[0]` Force-Index bei leerem Pool 🟠

**Datei:** `Games/Bet Buddy/Services/ChallengeService.swift:30`

```swift
let resetChallenge = pool.randomElement() ?? ChallengeData.classic[0]
// ↑ ChallengeData.classic[0] crasht wenn classic leer ist
```

Der Fallback `ChallengeData.classic[0]` ist ein direkter Array-Zugriff ohne
Bounds-Check. Wenn `ChallengeData.classic` aus irgendeinem Grund leer wäre
(z.B. Build-Problem), crasht die App.

**Fix:**
```swift
let resetChallenge = pool.randomElement() ?? ChallengeData.classic.first ?? Challenge.placeholder
```

---

## KATEGORIE B: LOGIK-FEHLER

---

### BB-03: `voteCounters` werden beim Voting-Start zurückgesetzt — aber nicht beim App-Launch 🟠

**Datei:** `Games/Bet Buddy/ViewModels/AppViewModel.swift`,
`Games/Bet Buddy/Screens/BetBuddyVotingView.swift:79`

```swift
// BetBuddyVotingView.onAppear:
appModel.resetVotes()
```

`resetVotes()` beim `onAppear` der VotingView ist korrekt für eine neue Runde.
Aber: Wenn der Nutzer die App während der Voting-Phase beendet und wieder öffnet,
ist die VotingView weg und die halbfertigen Votes sind im `voteCounters` Dictionary.
Die nächste `onAppear` der VotingView resettet sie dann — aber der Nutzer sieht
kurzzeitig alte Daten.

---

### BB-04: Gewinner-Logik bei Gleichstand nicht definiert 🟠

**Datei:** `Games/Bet Buddy/Screens/GameView.swift:33-45`

```swift
private var winningGroup: GroupInfo? {
    guard let maxId = appModel.voteCounters.max(by: { $0.value < $1.value })?.key,
          let group = appModel.activeGroups.first(where: { $0.id == maxId }) else { return nil }
    return group
}
```

Bei Gleichstand (`voteCounters = [A: 5, B: 5]`) gibt `max(by:)` einfach das
erste Element zurück — welches das ist, ist nicht deterministisch. Der "Gewinner"
bei Unentschieden ist zufällig und wird dem Nutzer nicht als Unentschieden kommuniziert.

**Fix:**
```swift
private var hasDrawResult: Bool {
    let values = appModel.voteCounters.values
    guard let max = values.max() else { return false }
    return values.filter { $0 == max }.count > 1
}
```
Im ResultView "UNENTSCHIEDEN" anzeigen wenn `hasDrawResult`.

---

### BB-05: Bet Buddy Stats werden nicht in GlobalRecapView angezeigt 🟠

*(Bereits als DA-01/D-08 bekannt)*

`AppViewModel.highlights` (BetBuddy-Stats) und `GlobalStatsManager` (globale Stats)
sind komplett getrennt. Ein Bet Buddy Sieg erscheint nie im `GlobalRecapView`.
`awardScore()` in AppViewModel ruft nie `GlobalStatsManager.recordWin()` auf.

---

### BB-06: `AlphabetHints` Static Dict wird bei jedem Aufruf neu aufgebaut 🔴

*(Bereits als P-02 in AUDIT_PERFORMANCE.md dokumentiert)*

**Datei:** `Games/Bet Buddy/Services/AlphabetHints.swift`

```swift
static var allHints: [String: String] { ... }  // var, nicht let!
```

`static var` (nicht `let`) bedeutet die 247KB Daten werden bei jedem Property-Zugriff
neu berechnet. Das verursacht Jank bei jedem Hint-Display.

**Fix:**
```swift
static let allHints: [String: String] = { ... }()  // Computed once, cached
```

---

## KATEGORIE C: FEATURE-LÜCKEN

---

### BB-07: Nur 2, 3, oder 4 Gruppen möglich — nicht konfigurierbar 🟡

**Datei:** `Games/Bet Buddy/Screens/GroupSelectionView.swift:16`

```swift
ForEach([2, 3, 4], id: \.self) { count in ...
```

Die Gruppenanzahl ist hard-coded auf 2, 3, 4. Für größere Runden (6+ Gruppen,
z.B. Schulfeste, Vereinsabende) ist das zu wenig. Sollte konfigurierbar bis ~8 sein.

---

### BB-08: Kein "Spieler aus Crew laden" Feature — muss Gruppen immer neu eingeben 🟠

**Datei:** `Games/Bet Buddy/Screens/GroupSelectionView.swift`

Imposter hat einen "Aus Crew laden" Button. Bet Buddy hat keine vergleichbare
Funktion. Gruppen-Namen werden über `GroupNamePersistence` zwischen Sessions
gespeichert, aber globale `GlobalPlayerManager` Spieler können nicht importiert werden.

---

### BB-09: Keine Statistiken pro Kategorie — Nutzer weiß nicht welche Kategorie am meisten gespielt 🟡

**Datei:** `Games/Bet Buddy/ViewModels/AppViewModel.swift`

`GameHighlights` trackt Wins/Losses, Streaks, FastestWin, AllTimeScores — aber
NICHT welche Kategorien wie oft gespielt wurden. Ein "Lieblings-Kategorie" Feature
oder Kategorie-Statistik fehlt komplett.

---

### BB-10: Timer läuft weiter wenn App in den Hintergrund geht 🟠

**Datei:** `Games/Bet Buddy/Services/GameTimer.swift`

**Problem:**
Wenn der Nutzer während einer laufenden Runde per Home-Button die App verlässt,
läuft der `GameTimer` weiter und läuft ab. Der Nutzer kehrt zurück und das
Zeitlimit ist bereits überschritten — ohne Chance die Runde fortzusetzen.

**Fix:**
```swift
.onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) {
    gameTimer.pause()
}
.onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) {
    gameTimer.resume()
}
```

---

### BB-11: Keine Undo-Funktion für versehentliche Score-Änderungen 🟡

**Datei:** `Games/Bet Buddy/Screens/BetBuddyVotingView.swift`

In der Voting-Phase können Punkte schnell mal falsch abgestimmt werden.
Es gibt keinen "Rückgängig"-Button für die letzte Vote-Aktion.

---

## KATEGORIE D: CODE-QUALITÄT

---

### BB-12: `AppViewModel` ist `@MainActor final` — aber `GroupNamePersistence` nicht 🟡

**Datei:** `Games/Bet Buddy/ViewModels/AppViewModel.swift:32`

`AppViewModel` ist korrekt mit `@MainActor` annotiert. Aber `GroupNamePersistence`
(ein Dependency) ist nicht `@MainActor` und macht Disk-IO ohne explizite
Thread-Sicherheit.

---

### BB-13: `Theme.swift` — 224 Usages von `Theme.x` statt `BetBuddyTheme.x` 🟠

*(Bereits als D-02 / UI-07 bekannt)*

`Theme.swift` ist ein reiner Wrapper ohne eigene Logik. 224 Stellen im Code
nutzen `Theme.x` statt direkt `BetBuddyTheme.x`. Sollte konsolidiert werden.

---

### BB-14: `ChallengeService` ist ein struct ohne Injection — nicht testbar 🟡

**Datei:** `Games/Bet Buddy/Services/ChallengeService.swift`

`ChallengeService` ist ein reines struct. Das ist gut für Immutabilität, aber
`AppViewModel` erstellt intern `let challengeService = ChallengeService()` ohne
Dependency Injection. Unit-Tests für Challenge-Auswahl-Logik sind damit schwerer.

---

### BB-15: `HapticsService` ignoriert globales `isHapticsEnabled` Setting 🟠

*(Bereits als D-05 / SW-08 bekannt)*

`HapticsService.impact()` etc. prüfen nie `@AppStorage("isHapticsEnabled")`.
Das ist ein bekannter Bug: Der Nutzer deaktiviert Haptik in den Settings, aber
Bet Buddy ignoriert das.

---

### BB-16: `dsds.swift` — falsch benannte Datei mit `Int.asAlphabet` Extension 🟢

*(Bereits als D-03 bekannt)*

**Datei:** `Games/Bet Buddy/Bet Buddy Resources/dsds.swift`

Umbenennen zu `Int+Alphabet.swift` und in `Shared/Extensions/` verschieben.

---

## ZUSAMMENFASSUNG BET BUDDY AUDIT

| Priorität | Anzahl | Top-Findings |
|-----------|--------|-------------|
| 🔴 Kritisch | 2 | Session-Scores nicht persistiert (BB-01), AlphabetHints var statt let (BB-06) |
| 🟠 Hoch | 6 | Force-Index Crash (BB-02), Gleichstand-Logik fehlt (BB-04), Stats nicht in GlobalRecap (BB-05), Timer im Hintergrund (BB-10), Haptik-Setting ignoriert (BB-15), Theme-Wrapper (BB-13) |
| 🟡 Mittel | 7 | VoteCounters-Reset Timing (BB-03), Gruppenanzahl hard-coded (BB-07), kein Crew-Import (BB-08), keine Kategorie-Stats (BB-09), kein Undo (BB-11), MainActor-Lücke (BB-12) |
| 🟢 Niedrig | 1 | dsds.swift (BB-16) |

---

*Erstellt: 2026-04-12 — Teil von Phase 4 des Gesamtaudits*
