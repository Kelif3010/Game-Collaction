# AUDIT: Imposter — Phase 4.1
## Erstellungsdatum: 2026-04-12

> Vollständiger Audit der Imposter-Spiellogik, Features, Bugs und Verbesserungspotenzial.
> Dateien: 58 Swift-Dateien in Games/Imposter/

---

## ÜBERSICHT

| Kategorie | Findings |
|-----------|----------|
| Kritische Bugs | 3 |
| Logik-Fehler | 4 |
| Feature-Lücken | 5 |
| Code-Qualität | 6 |
| **TOTAL** | **18** |

---

## KATEGORIE A: KRITISCHE BUGS

---

### IMP-01: Force-Unwrap in `selectWordsForGameMode` — Crash bei leerer Kategorie 🔴

**Datei:** `Games/Imposter/Models/GameLogic.swift:429`

```swift
case .classic:
    let word = category.words.randomElement()!  // ← CRASH wenn words leer!
    return GameWords(primary: word, secondary: nil)
```

Obwohl `startGame()` mit `guard !roundCategory.words.isEmpty` prüft, gibt es
andere Codepfade (z.B. `startMultiplayerGameAsHost`) die `selectWordsForGameMode`
aufrufen können ohne dieselbe Guard-Prüfung. Ein leeres Kategorie-Words-Array
crasht die App.

**Fix:**
```swift
case .classic:
    guard let word = category.words.randomElement() else { return GameWords(primary: "?", secondary: nil) }
    return GameWords(primary: word, secondary: nil)
```

---

### IMP-02: `distributeRoles` nutzt `DispatchQueue.main.async` für gameSettings innerhalb `async` Funktion 🔴

**Datei:** `Games/Imposter/Models/GameLogic.swift:475`

```swift
DispatchQueue.main.async { [weak gameSettings] in
    gameSettings?.numberOfImposters = imposterCount
}
```

`selectRandomImposters()` wird aus einer `@MainActor` `async` Funktion aufgerufen.
Das `DispatchQueue.main.async` innerhalb einer `@MainActor`-Funktion erzeugt ein
unnötiges Dispatch, das den State asynchron ändert NACHDEM die umgebende Funktion
bereits weitergelaufen ist. Das kann zu Race Conditions führen wo `gameSettings.numberOfImposters`
noch den alten Wert hat wenn die folgende Logik ihn liest.

**Fix:**
```swift
// @MainActor context — direkte Zuweisung:
gameSettings.numberOfImposters = imposterCount
```

---

### IMP-03: `GameSettings` Init lädt `spyCanSeeCategory` ohne `bool(forKey:)` Default — immer false 🟠

**Datei:** `Games/Imposter/Models/GameSettings.swift:134`

```swift
self.spyCanSeeCategory = defaults.bool(forKey: "imposter.spyCanSeeCategory")
self.spiesCanSeeEachOther = defaults.bool(forKey: "imposter.spiesCanSeeEachOther")
self.randomSpyCount = defaults.bool(forKey: "imposter.randomSpyCount")
self.showSpyHints = defaults.bool(forKey: "imposter.showSpyHints")
```

`UserDefaults.bool(forKey:)` gibt `false` zurück wenn der Key nicht existiert.
Wenn ein Nutzer die App zum ersten Mal startet, sind alle 4 Bool-Settings `false`.
Das ist für `spyCanSeeCategory` und `spiesCanSeeEachOther` zwar OK, aber wenn
gewünschte Defaults `true` wären (z.B. `showSpyHints = true` beim ersten Start),
würde es nie korrekt gesetzt.

Kein aktiver Bug, aber fragile Architektur ohne explizite Default-Dokumentation.

---

## KATEGORIE B: LOGIK-FEHLER

---

### IMP-04: `isRolesCategorySelected` prüft nur auf "Orte" — inkonsistent mit Feature-Name 🟠

**Datei:** `Games/Imposter/Models/GameSettings.swift:192-203`

```swift
var isRolesCategorySelected: Bool {
    ...
    return (category.sourceName ?? category.name).lowercased() == "orte"  // Nur "Orte"!
}
```

Der Roles-Spielmodus (`ImposterGameMode.roles`) wird nur für die Kategorie "Orte"
aktiviert. Warum? Das ist im Code nicht dokumentiert. Wenn der Nutzer eine eigene
Kategorie mit Orten erstellt und diese auswählt, kann er den Roles-Modus nicht
aktivieren — der Button bleibt disabled.

**Problem:** Feature ist auf eine hartcodierte Kategorie beschränkt ohne Erklärung.

---

### IMP-05: `timesPlayed` wird doppelt gezählt — in `StatsService` UND `GlobalStatsManager` 🟠

**Datei:** `Games/Imposter/Services/StatsService.swift` + `Games Collection/Services/GlobalStatsManager.swift`

**Problem (bereits als SL-08 bekannt, hier Imposter-spezifisch):**
Wenn Imposter eine Runde beendet, werden Stats in `StatsService` (Imposter-spezifisch)
UND in `GlobalStatsManager` (App-weit) geschrieben. Ein Spieler der 10 Runden
Imposter gespielt hat, hat in `GlobalStatsManager` möglicherweise 20+ `timesPlayed`
weil beide Systeme inkrementieren.

---

### IMP-06: `maxAllowedImposters` erlaubt bei 4 Spielern nur 1 Imposteur — korrekt, aber nicht kommuniziert 🟡

**Datei:** `Games/Imposter/Models/GameLogic.swift:449-455`

```swift
private func maxAllowedImposters(for playersCount: Int) -> Int {
    if playersCount <= 1 { return 0 }
    if playersCount == 4 { return 1 }       // Hard-coded: 4 Spieler = max 1 Spion
    let cap = max(1, playersCount / 2)
    return min(cap, playersCount - 1)
}
```

Der Stepper für "Anzahl Imposteure" sollte diese Logik mit einem informativen
Hinweistext koppeln (`"Max. 1 Spion bei 4 Spielern"`), damit der Nutzer versteht
warum er nicht mehr wählen kann.

---

### IMP-07: Kein Schutz gegen doppelte Spielernamen 🟡

**Datei:** `Games/Imposter/Views/Components/PlayerManagementSheet.swift`

**Problem:**
Spieler können denselben Namen mehrfach hinzugefügt werden ("Max", "Max", "Max").
Bei der Rollen-Zuweisung gibt es dann mehrere `Player`-Objekte mit gleichem `.name`
aber unterschiedlichen `.id`s. In der Voting-Anzeige können dann zwei "Max" im
Abstimmungs-UI erscheinen — verwirrend.

**Fix:**
```swift
func addPlayer(name: String) {
    let trimmed = name.trimmingCharacters(in: .whitespaces)
    guard !trimmed.isEmpty else { return }
    guard !gameSettings.players.contains(where: { $0.name.lowercased() == trimmed.lowercased() }) else {
        // Hinweis: Name bereits vorhanden
        return
    }
    gameSettings.players.append(Player(name: trimmed))
}
```

---

## KATEGORIE C: FEATURE-LÜCKEN

---

### IMP-08: `roles` Spielmodus in Multiplayer nicht unterstützt — kein UI-Hinweis 🟠

**Datei:** `Games/Imposter/Views/GameSetupView+Logic.swift:64-67`

Nur `classic` und `twoWords` werden im Multiplayer unterstützt. Der Modus `roles`
ist bei aktivem Multiplayer zwar im UI sichtbar, aber das Start-Button gibt erst
beim Drücken einen Fehler. Es gibt keinen proaktiven Hinweis im Spielmodus-Sheet.

---

### IMP-09: KI-Hinweise nur lokal verfügbar — im Multiplayer sieht nur der Host die Hinweise 🟠

**Datei:** `Games/Imposter/Services/HintService.swift`, `Games/Imposter/Views/Components/HintOverlay.swift`

**Problem:**
`HintService.shared` lädt KI-generierte Hinweise für die Kategorie. In Multiplayer
erhalten nur der Host und möglicherweise lokale Spieler diese Hinweise. Clients
die über Peer-to-Peer verbunden sind, erhalten keine Hint-Broadcasts.

**Erwartetes Verhalten:** Host broadcastet Hints an alle Clients über MPC.

---

### IMP-10: Spieler-Statistiken werden nicht in GlobalRecapView angezeigt 🟠

**Datei:** `Games Collection/Shared/GlobalRecapView.swift`

**Problem (bereits als DA-01 bekannt):**
`GlobalRecapView` zeigt nur `GlobalStatsManager` Daten. Die detaillierten
Imposter-Stats aus `StatsService` (Imposter-Wins, Citizen-Wins, fastWins etc.)
sind nirgendwo in der App-weiten Übersicht zu sehen.

---

### IMP-11: Keine "Rematch"-Funktion im Einzelspieler-Modus 🟡

**Datei:** `Games/Imposter/Views/VotingResultsView.swift`

**Problem:**
Im Multiplayer gibt es `multiplayerRematchOffer` Logik (inkl. Payload-Modelle).
Im Einzelspieler gibt es nur "Neue Runde" (= komplett neues Setup). Ein direktes
"Gleiche Spieler, neue Runde" ohne zurück zum Setup zu gehen fehlt als Quick-Action.

---

### IMP-12: `WordGuessingView` — Imposteur kann Wort raten, aber keine Zeitbegrenzung für Eingabe 🟡

**Datei:** `Games/Imposter/Views/WordGuessingView.swift`

**Problem:**
Im Roles-/Classic-Modus kann der Imposteur nach der Abstimmung das Wort erraten
und so gewinnen. Es gibt keine Zeitbegrenzung für diese Eingabe — der Imposteur
kann theoretisch unbegrenzt Zeit nehmen.

---

## KATEGORIE D: CODE-QUALITÄT

---

### IMP-13: `GameLogic` ist nicht `@MainActor` annotiert — teilweise async, teilweise sync 🟠

**Datei:** `Games/Imposter/Models/GameLogic.swift`

`startGame()` und `startMultiplayerGameAsHost()` sind `@MainActor async`, aber
die Klasse selbst hat kein `@MainActor`. Das bedeutet nicht-async Methoden können
von beliebigen Threads aufgerufen werden und auf `@Published` Properties zugreifen
ohne Thread-Sicherheit.

**Fix:** `@MainActor` auf Klassen-Ebene:
```swift
@MainActor
class GameLogic: ObservableObject { ... }
```

---

### IMP-14: `GameSettings` hat 40+ `@Published` Properties — Gott-Objekt-Anti-Pattern 🟡

**Datei:** `Games/Imposter/Models/GameSettings.swift`

`GameSettings` ist sowohl das Settings-Model als auch der Spiel-State-Container.
Wenn sich ein Timer-Tick-Property ändert, re-rendern alle Views die `@ObservedObject var gameSettings`
halten — auch Views die nur den Spielernamen anzeigen.

**Fix:** State aufteilen in `GameSettings` (Setup-Config) und `GameState` (Laufzeit-State).

---

### IMP-15: `applySetupBindings` — 5-fache AnyView-Kette 🟠

**Datei:** `Games/Imposter/Views/GameSetupView.swift:159-241`

*(Bereits als SW-05 in AUDIT_SWIFTUI.md dokumentiert)*

Die 5 verschachtelten `AnyView` wraps in `applySetupBindings` verhindern
SwiftUI's strukturelle Identitäts-Optimierungen und verlangsamen den Diff-Algorithmus.

**Fix:** ViewModifier oder `.onChange` direkt auf dem Basis-View ketten.

---

### IMP-16: `AIService` wird im `HintService` genutzt aber API-Key-Validierung fehlt 🟡

**Datei:** `Games/Imposter/Services/AIService.swift`, `Games/Imposter/Services/HintService.swift`

`AIService.shared.isAvailable` wird vor Hints-Calls geprüft. Aber was genau
"available" bedeutet (API-Key vorhanden, Internet vorhanden, Rate-Limit nicht erreicht)
ist nicht aus dem Code ersichtlich. Bei einem Rate-Limit-Fehler gibt es kein
Retry-Logic oder User-freundliche Fehlermeldung.

---

### IMP-17: Lottie-Animationen als Strings — kein Typ-Safety 🟡

**Datei:** `Games/Imposter/Models/GameLogic.swift:62-63`

```swift
let animations = ["Fingerprint biometric scan", "Android Fingerprint"]
gameSettings.currentCardBackAnimation = animations.randomElement() ?? ...
```

Wenn ein Lottie-Dateiname sich ändert, gibt es keinen Compile-Fehler.

**Fix:**
```swift
enum CardBackAnimation: String, CaseIterable {
    case fingerprintBiometric = "Fingerprint biometric scan"
    case androidFingerprint = "Android Fingerprint"
}
```

---

### IMP-18: `SavedPlayersManager` und `GlobalPlayerManager` parallel — Spieler werden nicht synchronisiert 🟠

**Datei:** `Games/Imposter/Models/SavedPlayers.swift`,
`Games Collection/Services/GlobalPlayerManager.swift`

Imposter hat seinen eigenen `SavedPlayersManager` der Spielernamen lokal speichert.
`GlobalPlayerManager` verwaltet die App-weite Spieler-Crew. Diese werden NICHT
automatisch synchronisiert. Der "Aus Crew laden" Button in `GameSetupView` ist ein
manueller Ein-Weg-Import, keine echte Synchronisation.

---

## ZUSAMMENFASSUNG IMPOSTER-AUDIT

| Priorität | Anzahl | Top-Findings |
|-----------|--------|-------------|
| 🔴 Kritisch | 2 | Force-Unwrap Crash (IMP-01), Race Condition bei Rollen-Verteilung (IMP-02) |
| 🟠 Hoch | 7 | GameSettings-Laden fragil (IMP-03), Stats-Doppelzählung (IMP-05), kein Multiplayer für alle Modi (IMP-08), KI-Hints nicht in MP (IMP-09), GlobalRecap fehlt (IMP-10), @MainActor fehlt (IMP-13), AnyView-Kette (IMP-15) |
| 🟡 Mittel | 9 | isRolesCategorySelected hart-coded (IMP-04), doppelte Spielernamen (IMP-07), kein Rematch (IMP-11), WordGuessing ohne Timer (IMP-12), Gott-Objekt (IMP-14), Lottie-Strings (IMP-17), SavedPlayers-Sync (IMP-18) |

---

*Erstellt: 2026-04-12 — Teil von Phase 4 des Gesamtaudits*
