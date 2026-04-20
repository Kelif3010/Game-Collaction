# Party-Modul – Fortschritt & Aufgabenliste

Zuletzt aktualisiert: 2026-04-15 (Session 4 abgeschlossen – alle Tier-1 & Tier-2 Items erledigt)

---

## Status-Übersicht

| # | Aufgabe | Status |
|---|---------|--------|
| 0 | `@StateObject`-Fix in PartySetupView (GlobalPlayerManager) | ✅ Erledigt |
| 1 | Fix: Dismiss-Logik | ✅ Erledigt |
| 2 | Fix: Force-Unwraps entfernen | ✅ Erledigt |
| 3 | Feature: minPlayers-Validierung | ✅ Erledigt |
| 4 | Feature: Validierungs-Feedback unter Start-Button | ✅ Erledigt |
| 5 | Feature: Session-Persistenz | ✅ Erledigt |
| 6 | Feature: Party-Spieler in Spiele durchreichen (PartyGameLaunchContext) | ✅ Erledigt |
| 7 | Feature: Drag & Drop Spielreihenfolge | ✅ Erledigt |
| 8 | Feature: Session-Verlauf / History | ⏳ Ausstehend |
| 9 | Feature: Ergebnisse teilen (Share Sheet) | ⏳ Ausstehend |
| 10 | Feature: Gast vs. Crew beim Spieler hinzufügen | ✅ Erledigt |

---

## Erledigte Änderungen

### 0 – `@StateObject`-Fix (`PartySetupView.swift`)
- **Was:** `@ObservedObject` → `@StateObject` für `GlobalPlayerManager.shared`
- **Warum:** `@StateObject` hält die Instanz stabil über View-Neuerstellungen hinweg.
  Bei Singletons die inline initialisiert werden ist das die korrekte Wahl.
- **Datei:** `Games Collection/Party/Views/PartySetupView.swift`, Zeile 7

---

### 1 – Dismiss-Logik Fix (`PartyHubView.swift`)
- **Was:** `onDismiss` des `fullScreenCover` rief immer direkt `gameDismissed()` auf.
  Das führte dazu, dass die "Wer hat gewonnen?"-Bridge erschien, selbst wenn
  jemand ein Spiel nur kurz öffnete und direkt wieder schloss.
- **Fix:** Neues `showDismissAlert` State. Nach Dismiss erscheint ein Alert:
  - "Ergebnis eintragen" → `gameDismissed()` (Bridge öffnet sich)
  - "Abgebrochen" → nichts passiert, Session läuft weiter
- **Datei:** `Games Collection/Party/Views/PartyHubView.swift`

---

### 2 – Force-Unwraps entfernen (`PartyHubView.swift`, `PartyRecapView.swift`)
- **Was:** `manager.session!` konnte bei unerwarteten States crashen.
- **Fix:** `manager.session ?? PartySession(players: [], games: [])` als sicherer Fallback.
  Da `PartyWrapper` diese Views nur zeigt wenn `session != nil`, wird der
  Fallback nie tatsächlich genutzt – ist aber crashsicher.
- **Dateien:**
  - `Games Collection/Party/Views/PartyHubView.swift`, Zeile 11
  - `Games Collection/Party/Views/PartyRecapView.swift`, Zeile 11

---

### 3 – minPlayers-Validierung (`PartySession.swift`, `PartySetupView.swift`)
- **Was:** Alle Spiele wurden mit min. 2 Spielern als startbar markiert.
  Imposter mit 2 Spielern zu starten ergibt keinen Sinn.
- **Fix:** `minPlayers`-Property zu `PartyGame` hinzugefügt:
  - `imposter`: 4
  - `falscheFaehrte`: 3
  - `question`: 3
  - alle anderen: 2
- `canStart` in `PartySetupView` prüft nun das Maximum aller gewählten Spiele.
- **Dateien:**
  - `Games Collection/Party/PartySession.swift`
  - `Games Collection/Party/Views/PartySetupView.swift`

---

### 4 – Validierungs-Feedback (`PartySetupView.swift`)
- **Was:** Start-Button war einfach deaktiviert ohne Erklärung.
- **Fix:** Kleiner Hinweis-Text unter dem Button zeigt was noch fehlt, z.B.:
  - "Wähle noch 1 Spiel aus"
  - "Imposter braucht mind. 4 Spieler"
  - "Wähle noch 2 Spiele und 1 Spieler"
- **Datei:** `Games Collection/Party/Views/PartySetupView.swift`

---

### 5 – Session-Persistenz (`PartySessionManager.swift`)
- **Was:** Laufende Party-Session ging verloren wenn die App im Hintergrund
  beendet wurde (Speicherdruck, Anruf, etc.)
- **Fix:** `PartySessionManager` speichert die Session nach jeder Änderung
  in `UserDefaults`. Beim Start wird automatisch wiederhergestellt.
  - Abgeschlossene Sessions (`.complete`) werden nicht wiederhergestellt.
  - War die Session im Zustand `.enteringResults` (Bridge offen), wird
    die Bridge beim Wiederherstellen automatisch wieder geöffnet.
- **Storage-Key:** `PartySession_Active_V1`
- **Datei:** `Games Collection/Party/PartySessionManager.swift`

---

## Ausstehende Aufgaben

### 6 – PartyGameLaunchContext (Hoch / 1-2 Tage)
Im Party-Setup gewählte Spieler werden aktuell **nicht** an die einzelnen
Spiele weitergegeben. Jedes Spiel startet mit seiner eigenen Spielerliste.

Geplante Lösung:
```swift
struct PartyGameLaunchContext {
    let partyPlayers: [PartyPlayer]
    let onFinished: ([UUID]) -> Void  // Gewinner-IDs
}
```
Alle 6 Game-Wrapper müssten einen optionalen `partyContext`-Parameter bekommen.

Betroffene Dateien: Alle `*Wrapper.swift` Dateien + `PartyHubView.swift`

---

### 7 – Drag & Drop Spielreihenfolge (Mittel / 2-3h)
Aktuell bestimmt die Tap-Reihenfolge die Spielabfolge (Badge 1, 2, 3...).
Geplant: `.onMove` Modifier in der Game-Liste für direktes Umordnen.

---

### 8 – Session-Verlauf / History (Mittel / 3-4h)
Abgeschlossene Sessions in einem `[PartySessionRecord]` persistieren.
Abrufbar über einen "Vergangene Partys"-Button.

---

### 9 – Ergebnisse teilen (Klein / 1h)
Am Ende der `PartyRecapView` einen Share-Button hinzufügen der die
Ergebnisse als formatierten Text über den nativen Share-Sheet teilt.

---

### 10 – Gast vs. Crew (Klein / 1-2h)
Im `AddPartyPlayerSheet` zwei Optionen anbieten:
- "Nur für diese Party" → bleibt temporär in `customPlayers`
- "Zur Crew hinzufügen" → wird über `GlobalPlayerManager.addPlayer()` dauerhaft gespeichert
