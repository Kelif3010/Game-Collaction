# AUDIT: UX & DAU-Sicherheit — Phase 3.4
## Erstellungsdatum: 2026-04-12

> DAU = "Dümmster Anzunehmender User" — alle Szenarien wo ein Nutzer
> die App auf unerwartete Weise bedienen könnte.
> Geprüft: User-Flows, Edge Cases, Fehlerbehandlung, Bestätigungsdialoge,
> Datenintegrität, Offline-Verhalten, Onboarding, Texte.

---

## KATEGORIE 1: SILENT FAILURES — App reagiert nicht ohne Feedback

---

### UX-01: Imposter `startGame()` bricht lautlos ab wenn < 4 Spieler 🔴

**Datei:** `Games/Imposter/Models/GameLogic.swift:65-69`

**Problem:**
```swift
guard let roundCategory = gameSettings.chooseRoundCategory(),
      !roundCategory.words.isEmpty,
      gameSettings.players.count >= 4 else {
    return   // ← Silent failure! Kein Fehler, kein Alert, nichts passiert
}
```

Der `guard...return` bricht das Spiel lautlos ab wenn:
- Keine Kategorie ausgewählt ist
- Die Kategorie keine Wörter hat
- Weniger als 4 Spieler vorhanden sind

In `GameSetupView+Logic.swift` gibt es zwar `canStartGame` und `startButtonHintText`
als Prüfung, aber wenn `startGame()` direkt aufgerufen wird (z.B. über Multiplayer-Path),
ist der Nutzer ohne jedes Feedback.

**Schwere:** Bei Multiplayer kann der Host das Spiel triggern obwohl Bedingungen
nicht erfüllt sind — alle Spieler sehen dann gar nichts passieren.

**Fix:**
```swift
@MainActor
func startGame() async {
    guard let roundCategory = gameSettings.chooseRoundCategory(),
          !roundCategory.words.isEmpty else {
        gameSettings.gameError = "Keine Wörter in der gewählten Kategorie."
        return
    }
    guard gameSettings.players.count >= 4 else {
        gameSettings.gameError = "Mindestens 4 Spieler werden benötigt."
        return
    }
    // ...
}
```

---

### UX-02: Imposter Multiplayer-Modus erlaubt nur Classic — Fehlermeldung versteckt 🟠

**Datei:** `Games/Imposter/Views/GameSetupView+Logic.swift:64-67`

**Problem:**
```swift
guard gameSettings.gameMode == .classic else {
    alertMessage = "Multiplayer unterstützt aktuell nur den klassischen Modus."
    showingAlert = true
    return
}
```

Der Fehler-Alert erscheint erst beim Start-Klick. Es gibt jedoch keinen visuellen
Hinweis im UI, dass der gewählte Spielmodus (z.B. Roles) inkompatibel mit
Multiplayer ist. Ein DAU-Nutzer wählt Rollen-Modus, geht in Multiplayer, lädt
Freunde ein — und erst beim Start-Klick gibt es einen Fehler.

**Fix:** Inkompatible Modi in der Spielmodus-Auswahl als disabled markieren wenn
Multiplayer aktiv ist:
```swift
GameModeCard(mode: mode)
    .opacity(isMultiplayerActive && mode != .classic ? 0.4 : 1.0)
    .overlay(
        isMultiplayerActive && mode != .classic
            ? Text("Kein MP").font(.caption2).padding(4)
              .background(.red.opacity(0.8)).cornerRadius(4)
            : nil
    )
```

---

### UX-03: Question: Spieler-Mindestanzahl nicht durchgesetzt 🟠

**Datei:** `Games/Question/QuestionsSetupView.swift`

**Problem:**
Question benötigt mindestens 3 Spieler (1 Lügner + 2 ehrliche). Es gibt zwar
`canStart` Prüfung, aber was "canStart" bedeutet ist nicht klar aus dem Code.
Wenn ein Nutzer mit 2 Spielern startet:
- `QuestionLiarPicker` hat `guard count > 0, !players.isEmpty` — würde 1 Lügner bei 2 Spielern erlauben
- Das Spiel würde starten aber die Mechanik macht bei 2 Spielern keinen Sinn

---

### UX-04: Bet Buddy: Gruppen können denselben Namen bekommen — keine Warnung 🟡

**Datei:** `Games/Bet Buddy/Screens/GroupSelectionView.swift`,
`Games/Bet Buddy/Services/GroupNamePersistence.swift`

**Problem:**
Nutzer können "Team Rot" und "Team Blau" umbenennen zu "Team" und "Team".
Im Leaderboard stehen dann zwei Einträge mit dem Namen "Team" — unmöglich
auseinanderzuhalten.

```swift
// GroupSelectionView.swift — kein Duplikat-Check:
GroupNameField(group: group) { newName in
    appModel.updateName(newName, for: group.color)  // Kein Check ob Name schon existiert
}
```

**Fix:**
```swift
func updateName(_ name: String, for color: GroupColor) {
    let trimmed = name.trimmingCharacters(in: .whitespaces)
    guard !trimmed.isEmpty else { return }
    
    // Duplikat-Check:
    let isDuplicate = groups.contains { $0.color != color && $0.displayName == trimmed }
    if isDuplicate {
        // Warnhinweis anzeigen
        nameWarning = "Dieser Name wird schon von einer anderen Gruppe verwendet."
        return
    }
    // Namen setzen...
}
```

---

## KATEGORIE 2: FEHLENDE BESTÄTIGUNGEN (DESTRUKTIVE AKTIONEN)

---

### UX-05: TimesUp "Beenden" löscht laufendes Spiel mit Bestätigung — GUT ✅

**Datei:** `Games/TimesUp/Views/TimesUpGameView.swift:53-61`

```swift
.alert("Spiel beenden?", isPresented: $showingEndGame) {
    Button("Abbrechen", role: .cancel) { }
    Button("Beenden", role: .destructive) { dismiss() }
}
```
Korrekt implementiert. Alle Fortschritte gehen verloren → Bestätigung vorhanden.

---

### UX-06: Bet Buddy ChallengeStartView hat Exit-Bestätigung — GUT ✅

**Datei:** `Games/Bet Buddy/Screens/ChallengeStartView.swift:53-61`

Ebenfalls korrekt implementiert.

---

### UX-07: Imposter — kein Bestätigungs-Dialog beim Verlassen eines laufenden Spiels 🟠

**Datei:** `Games/Imposter/Views/GamePlayView.swift`

**Problem:**
In `GamePlayView` gibt es einen "Beenden" Button im Footer. Wird der Nutzer
nach einer Confirmation gefragt? Aus dem Code nicht ersichtlich ob ein Alert existiert.
TimesUp macht das korrekt (UX-05) — Imposter sollte konsistent sein.

**Erwartetes Verhalten:**
```swift
Button("Spiel beenden") {
    showEndGameAlert = true
}
.alert("Spiel beenden?", isPresented: $showEndGameAlert) {
    Button("Abbrechen", role: .cancel) { }
    Button("Beenden", role: .destructive) {
        gameSettings.requestExitToMain = true
    }
} message: {
    Text("Das aktuelle Spiel wird beendet. Alle Punkte gehen verloren.")
}
```

---

### UX-08: Imposter Kategorie-Löschen ohne Bestätigung in `ImposterCategoryDetailView` 🟡

**Datei:** `Games/Imposter/Views/ImposterCategoryDetailView.swift`

**Problem:**
Wenn ein Nutzer eine selbst erstellte Kategorie löscht, ist unklar ob eine
Bestätigung erscheint. Custom Kategorien mit vielen selbst eingegebenen Wörtern
sind wertvolle User-Daten — Verlust ist ärgerlich.

**Erwartetes Verhalten:**
```swift
.confirmationDialog("Kategorie löschen?",
    isPresented: $showDeleteConfirm, titleVisibility: .visible) {
    Button("Löschen", role: .destructive) { deleteCategory() }
    Button("Abbrechen", role: .cancel) { }
} message: {
    Text("Die Kategorie '\(category.name)' und alle \(category.words.count) Wörter werden dauerhaft gelöscht.")
}
```

---

## KATEGORIE 3: EDGE CASES & GRENZWERTE

---

### UX-09: Imposter mit exakt 4 Spielern und 3 Impostoren — mathematisch absurd 🟠

**Datei:** `Games/Imposter/Views/GameSetupView+Logic.swift`

**Problem:**
`canStartGame` prüft nur `numberOfImposters < players.count`. Bei 4 Spielern
und 3 Impostoren wäre die Bedingung erfüllt (3 < 4 = true). Das Spiel würde
mit 3 Impostoren gegen 1 ehrlichen Spieler starten — das ist mechanisch sinnlos.

Eine sinnvolle Regel: Impostoren dürfen maximal die Hälfte der Spieler sein
(Minimum: 1 ehrlicher auf 1 Imposteur macht Sinn, aber 3:1 nicht).

**Aktueller Stand von `maxAllowedImposters`:**
```swift
private func maxAllowedImposters(for count: Int) -> Int {
    // Muss geprüft werden ob diese Funktion sinnvolle Grenzen setzt
}
```

---

### UX-10: Bet Buddy — was passiert bei 0 aktiven Kategorien? 🟡

**Datei:** `Games/Bet Buddy/Screens/CategorySelectionView.swift`

**Problem:**
Wenn ein Nutzer alle Kategorien deaktiviert und dann "Spiel starten" drückt,
hat `currentChallenge` nichts zu ziehen. Was zeigt `ChallengeService` dann?
Führt das zu einem leeren/kaputten State?

---

### UX-11: TimesUp — was passiert wenn alle Wörter in einer Runde verbraucht sind? 🟡

**Datei:** `Games/TimesUp/Managers/GameManager.swift`

**Problem:**
Wenn alle Begriffe einer Kategorie bereits in früheren Runden erraten wurden
und in Runde 4 (Zeichnen) keine Begriffe mehr übrig sind, was passiert?
Das ist ein realistischer Edge Case bei kleinen Kategorien mit wenigen Begriffen.

---

### UX-12: Question — Lügner-Anzahl kann die Spieler-Anzahl übersteigen 🟠

**Datei:** `Games/Question/QuestionsSetupView.swift`

**Problem:**
```swift
// QuestionsGameViewModel:
var maxVotes: Int {
    let liars = engine.config.numberOfLiars > 0 ? engine.config.numberOfLiars : numberOfLiars
    return playerCount * max(0, liars)
}
```

Wenn `numberOfLiars` größer als `playerCount - 1` ist, wäre jeder ein Lügner
außer einem. Das macht das Spiel kaputt. Die Setup-UI muss sicherstellen dass
`numberOfLiars <= playerCount - 2` (mindestens 2 ehrliche).

---

## KATEGORIE 4: ONBOARDING & ERSTE NUTZUNG

---

### UX-13: Nur Bet Buddy hat ein automatisches Onboarding-Sheet 🟠

**Problem:**
Bet Buddy zeigt beim ersten Start automatisch `BetBuddyInfoSheet`. Die anderen
Games (Imposter, Question, TimesUp) haben zwar Info-Buttons, aber keinen
automatischen Onboarding-Flow beim ersten Mal.

```swift
// HomeView.swift — nur Bet Buddy hat dieses Pattern:
@AppStorage("hasSeenBetBuddyOnboarding") private var hasSeenOnboarding: Bool = false

.onAppear {
    if !hasSeenOnboarding {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            showInfoSheet = true
        }
    }
}
```

Ein DAU-Nutzer der Imposter zum ersten Mal öffnet, versteht ohne Anleitung
nicht sofort was Imposter ist oder wie es gespielt wird — er muss aktiv den
Info-Button finden.

**Fix:** Für alle Games dasselbe `hasSeenOnboarding` Pattern implementieren.

---

### UX-14: Imposter Rollenkarten-Beschriftung — "Android Fingerprint" als interne Bezeichnung sichtbar? 🟡

**Datei:** `Games/Imposter/Models/GameLogic.swift:62-63`

**Problem:**
```swift
let animations = ["Fingerprint biometric scan", "Android Fingerprint"]
gameSettings.currentCardBackAnimation = animations.randomElement() ?? ...
```

"Android Fingerprint" und "Fingerprint biometric scan" sind interne Dateinamen
für Lottie-Animationen. Falls diese irgendwo im UI angezeigt werden (z.B. in
Debug-Views oder Logs), wäre das ein schlechter Eindruck. Diese sollten als
enum-Werte gekapselt sein, nicht als Raw-Strings.

---

## KATEGORIE 5: DATENINTEGRITÄT & PERSISTENZ

---

### UX-15: Bet Buddy Scores verschwinden bei App-Neustart ohne "Spiel beenden" 🟠

**Datei:** `Games/Bet Buddy/ViewModels/AppViewModel.swift`

**Problem:**
`scores: [UUID: Int]` ist nur im RAM gespeichert und wird nicht persistiert.
Wenn die App crasht oder der Nutzer per Swipe beendet während ein Spiel läuft,
sind alle Punkte weg. Das ist besonders ärgerlich bei langen Spielrunden.

```swift
// AppViewModel — scores nur in-memory:
@Published private(set) var scores: [UUID: Int] = [:]   // Nicht persistiert
```

**Fix:** Scores regelmäßig in UserDefaults spiegeln (bei jeder Punkteänderung):
```swift
@Published private(set) var scores: [UUID: Int] = [:] {
    didSet { persistScores() }
}
```

---

### UX-16: Imposter spieler werden bei Multiplayer-Lobby durch MPC-Peers überschrieben 🟠

**Datei:** `Games/Imposter/Views/GameSetupView.swift:173-180`

**Problem:**
```swift
.onChange(of: mpc.lobbyPeers) { _, newPeers in
    if mpc.role != .unknown, route == nil, gameSettings.gamePhase == .setup {
        let mpcPlayers = newPeers.map { Player(name: $0) }
        gameSettings.players = mpcPlayers   // ← ÜBERSCHREIBT lokale Spieler!
    }
}
```

Wenn der Host die Lobby betritt (Multiplayer-Setup), werden die zuvor
hinzugefügten lokalen Spieler sofort durch die MPC-Peer-Namen ersetzt.
Das ist gewollt für Multiplayer — aber wenn ein Nutzer aus Versehen den
Multiplayer-Button angetippt hat und wieder zurückgeht, sind seine Spieler weg.

---

### UX-17: Rechtschreibfehler in UI-Texten 🟡

**Problem:**
Gefundene Rechtschreibfehler die Nutzer sehen:

| Text (falsch) | Korrekt | Datei |
|--------------|---------|-------|
| "Keine Spieler hinzugefuegt." | "hinzugefügt" | `QuestionsPlayerManagementSheet.swift:318` |
| "Host waehlt Anzahl Spione" | "wählt" | `GameSetupView+Logic.swift` |
| "Host waehlt Kategorie" | "wählt" | `GameSetupView+Logic.swift` |
| "Host aktiviert Rollen und Regeln" | Grammatik OK, aber "Rollen" = Spielrollen | Unklar |

Die "waehlt"-Strings sind MPC-Broadcast-Nachrichten die möglicherweise
auf anderen Geräten angezeigt werden — diese sollten korrekte Umlaute haben.

---

## KATEGORIE 6: NETZWERK & OFFLINE

---

### UX-18: Host-Disconnect während Spielrunde — kein definiertes Verhalten 🔴

**Datei:** `Games/Imposter/Views/GamePlayView.swift`,
`Games Collection/Services/MultipeerManager.swift`

**Problem:**
Wenn der Host während einer laufenden Multiplayer-Runde die Verbindung verliert:
- Clients sehen den "Disconnect Toast" (korrekt!)
- Aber: Es gibt keinen "Host ist weg, Spiel kann nicht fortgesetzt werden" State
- Clients sind in einer laufenden Spielrunde gefangen

Der Client kann zwar die Runde lokal "beenden" aber alle synchronisierten States
(Timer, Votes, Phase) bleiben stecken.

**Erwartetes Verhalten:**
- Wenn Host disconnectet: "Der Host hat die Verbindung verloren. Das Spiel wird beendet." Alert
- Optional: Einen Client automatisch zum neuen Host promoten (komplexer)

---

### UX-19: Keine Offline-Erkennung für AI-Features (AIService) 🟡

**Datei:** `Games/Imposter/Services/AIService.swift`

**Problem:**
`AIService` macht API-Calls für KI-generierte Hinweise. Wenn kein Internet
vorhanden ist, schlägt der API-Call fehl. Aber was sieht der Nutzer?
Ohne spezifische Netzwerk-Fehlerbehandlung wahrscheinlich: Nichts (Silent Failure)
oder einen generischen Fehler ohne Handlungsempfehlung.

**Fix:**
```swift
func generateHints() async {
    guard NetworkMonitor.shared.isConnected else {
        self.error = .noInternet
        return
    }
    // ... API call
}
```

---

## ZUSAMMENFASSUNG PHASE 3.4 (UX & DAU-Sicherheit)

| Priorität | Anzahl | Top-Issues |
|-----------|--------|------------|
| 🔴 Kritisch | 2 | Silent Failure bei Imposter-Start (UX-01), Host-Disconnect ohne Recovery (UX-18) |
| 🟠 Hoch | 7 | Multiplayer-Modus-Inkompatibilität zu spät gemeldet (UX-02), Question Lügner-Limit fehlt (UX-12), kein Bestätigung beim Imposter-Beenden (UX-07), Bet Buddy Scores nicht persistiert (UX-15), Player-Überschreibung bei MPC (UX-16), Onboarding nur bei BetBuddy (UX-13), MPC-Spieler überschreiben lokale (UX-16) |
| 🟡 Mittel | 10 | Gruppen-Doppelnamen (UX-04), Kategorie-Löschen ohne Alert (UX-08), 0-Kategorien Edge Case (UX-10), Wort-Erschöpfung Edge Case (UX-11), Rechtschreibfehler (UX-17), AI offline (UX-19) |

---

## KRITISCHE USER-FLOWS DIE GETESTET WERDEN MÜSSEN

| Flow | Risiko | Erwartet |
|------|--------|---------|
| Imposter: Start mit 3 Spielern | Silent Failure (UX-01) | Alert: "4 Spieler nötig" |
| Imposter MP: Rollen-Modus wählen → Starten | Zu späte Fehlermeldung (UX-02) | Modus disabled in MP |
| Imposter MP: Host verlässt laufendes Spiel | Clients gefangen (UX-18) | Alert + Rückkehr zum Menü |
| Bet Buddy: App crashed während Spiel | Scores weg (UX-15) | Persistierte Recovery |
| Question: 6 Lügner bei 5 Spielern | Mechanik kaputt (UX-12) | Limit enforced |
| Bet Buddy: Alle Kategorien deaktivieren | Leere Challenge (UX-10) | Min. 1 Kategorie required |

---

*Erstellt: 2026-04-12 — Teil von Phase 3 des Gesamtaudits*
*Damit: Phase 3 vollständig abgeschlossen (3.1 + 3.2 + 3.3 + 3.4)*
