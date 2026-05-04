# AUDIT: Question — Phase 4.3
## Erstellungsdatum: 2026-04-12

> Vollständiger Audit des Question-Spiels (Lügner-Erkennungsspiel).
> Dateien: 33 Swift-Dateien in Games/Question/

---

## ÜBERSICHT

| Kategorie | Findings |
|-----------|----------|
| Kritische Bugs | 2 |
| Logik-Fehler | 5 |
| Feature-Lücken | 4 |
| Code-Qualität | 4 |
| **TOTAL** | **15** |

---

## KATEGORIE A: KRITISCHE BUGS

---

### Q-01: Force-Unwrap `category.promptPairs.indices.randomElement()!` 🔴

**Datei:** `Games/Question/QuestionsEngine.swift:77`

```swift
let pickIndex = availableIndices.randomElement() ?? category.promptPairs.indices.randomElement()!
// ↑ Crasht wenn promptPairs leer ist
```

Wenn eine Kategorie keine Fragen-Paare hat (`promptPairs.isEmpty`),
ist auch `category.promptPairs.indices` leer — und `.randomElement()!` crasht.

Das Guard auf Zeile 73 (`guard category.promptPairs.isEmpty == false`) sollte
diesen Fall abfangen, aber er ist NACH dem `assignLiarsRandomly()` Call — wenn
zwischen dem Guard und dem Zugriff eine async Unterbrechung möglich wäre,
wäre es ein Race. Im synchronen Kontext ist es OK, aber der Force-Unwrap
sollte trotzdem entfernt werden.

**Fix:**
```swift
guard let pickIndex = availableIndices.randomElement() ?? category.promptPairs.indices.randomElement() else {
    return  // Statt crash
}
```

---

### Q-02: `suspectID!` Force-Unwrap in QuestionsResultsPhaseView 🔴

*(Bereits als P-09/UX-bezogen dokumentiert)*

**Datei:** `Games/Question/Views/Phases/QuestionsResultsPhaseView.swift:22-26`

```swift
let suspectID = evaluation?.selected.first
let suspectName = suspectID != nil ? viewModel.playerName(for: suspectID!) : "Niemand"
let isLiar = suspectID != nil && liars.contains(suspectID!)
```

Obwohl `suspectID != nil` geprüft wird, bleibt `suspectID!` ein Force-Unwrap.
Bei `nil` (z.B. wenn `evaluation` nil ist und der ternäre Operator dennoch
den `true`-Zweig evaluiert — theoretisch nicht möglich aber fragil).

**Fix:**
```swift
if let suspectID = evaluation?.selected.first {
    let suspectName = viewModel.playerName(for: suspectID)
    let isLiar = liars.contains(suspectID)
    // ...
} else {
    // Niemand wurde gewählt
}
```

---

## KATEGORIE B: LOGIK-FEHLER

---

### Q-03: Lügner-Anzahl wird in `QuestionsEngine.configure` geclampt, aber in UI nicht kommuniziert 🟠

**Datei:** `Games/Question/QuestionsEngine.swift:38`

```swift
self.config.numberOfLiars = max(0, min(numberOfLiars, max(0, players.count - 1)))
```

Wenn der Nutzer 3 Lügner konfiguriert aber nur 3 Spieler vorhanden sind,
wird `numberOfLiars` auf 2 geclampt. Der Nutzer sieht aber in der Setup-UI
noch "3 Lügner" — erst im Spiel werden es 2. Das ist verwirrend.

**Fix:** Binding-Warnung in der Setup-UI:
```swift
if numberOfLiars >= appModel.players.count {
    Text("⚠️ Zu viele Lügner für \(appModel.players.count) Spieler")
        .foregroundStyle(.orange)
}
```

---

### Q-04: `runSequence` in `QuestionsResultsPhaseView` — DispatchQueue ohne Cancellation 🟠

*(Bereits als DC-04 dokumentiert)*

8 `DispatchQueue.main.asyncAfter` Calls die nicht cancellbar sind wenn die View
verlassen wird. Kann zu "updating State after View is dismissed" Warnings führen.

---

### Q-05: `QuestionsGameViewModel` — Doppeltes `objectWillChange` durch 2 Combine-Subscriptions 🟠

*(Bereits als P-05 in AUDIT_PERFORMANCE.md dokumentiert)*

```swift
// QuestionsGameViewModel.init:
engine.objectWillChange.receive(on: ...).sink { [weak self] _ in
    self?.objectWillChange.send()  // Forward von Engine
}
appModel.objectWillChange.receive(on: ...).sink { [weak self] _ in
    self?.objectWillChange.send()  // Forward von AppModel
}
```

Jede Property-Änderung in `engine` ODER `appModel` triggert ein `objectWillChange`
in `QuestionsGameViewModel`. Views die das ViewModel observieren re-rendern
bei jedem Tick beider ObservableObjects — auch wenn die angezeigte Property
sich gar nicht geändert hat.

---

### Q-06: Scores in `AppModel` werden persistiert — Session-Reset fehlt nach Spielende 🟡

**Datei:** `Games/Question/AppModel.swift:33-40`

```swift
@Published var scores: [UUID: Int] = [:] {
    didSet {
        if let data = try? JSONEncoder().encode(scores) {
            UserDefaults.standard.set(data, forKey: "question.scores")
        }
    }
}
```

Question persistiert `scores` in UserDefaults — das ist gut (im Gegensatz zu Bet Buddy).
Aber: Beim Start eines neuen Spiels werden die alten Scores aus dem vorherigen
Spiel geladen. Gibt es einen expliziten "Scores zurücksetzen" Flow beim neuen Spiel?

---

### Q-07: Fairness-System trackt Lügner-History, aber wird bei App-Reset nicht geleert 🟡

**Datei:** `Games/Question/AppModel.swift:24-30`

`fairnessState` wird persistiert. Wenn der Nutzer einen "Reset" in den Einstellungen
macht, sollte `fairnessState` auch zurückgesetzt werden. Ob das passiert, ist
unklar — der `AppDidReset` Observer wurde in AppModel nicht gefunden.

---

## KATEGORIE C: FEATURE-LÜCKEN

---

### Q-08: Keine Übersicht über Kategorien mit Anzahl der verfügbaren Fragen 🟡

**Datei:** `Games/Question/Views/Setup/QuestionsCategorySheet.swift`

Nutzer können Kategorien wählen, sehen aber nicht wie viele Fragen-Paare
(`promptPairs`) eine Kategorie hat. Eine Kategorie mit 3 Paaren "erschöpft"
sich nach 3 Runden — das ist nicht vorab erkennbar.

---

### Q-09: Kein Kategorie-Editor — Nutzer können keine eigenen Fragen hinzufügen 🟠

**Problem:**
Imposter und TimesUp haben Kategorie-Editoren (Custom Categories). Question hat
nur die eingebauten `QuestionsDefaults`. Nutzer können keine eigenen Lügen-Fragen
(Promptpaare) erstellen — das schränkt die Langzeit-Motivation stark ein.

---

### Q-10: TV-Board (`QuestionsTVBoardView`) — nicht dokumentiert wann/wie nutzbar 🟡

**Datei:** `Games/Question/Views/TV/QuestionsTVBoardView.swift`

Es gibt eine `QuestionsTVBoardView` für externe Bildschirme/AirPlay. Aber:
Gibt es eine Anleitung oder UI-Hinweis wie der Nutzer das aktiviert?
`TVRootView` in den globalen Services deutet auf externe Display-Support hin,
aber die Verbindung ist unklar.

---

### Q-11: Keine Punkte-Anzeige während der Collecting-Phase 🟡

**Datei:** `Games/Question/Views/Phases/QuestionsCollectingPhaseView.swift`

Während die Spieler ihre Antworten eingeben, gibt es keinen Score-Überblick.
Ein "Aktueller Stand" Element würde die Motivation erhöhen.

---

## KATEGORIE D: CODE-QUALITÄT

---

### Q-12: `QuestionsGameViewModel` ist `@MainActor final` aber `QuestionsEngine` nicht 🟠

**Datei:** `Games/Question/ViewModels/QuestionsGameViewModel.swift`,
`Games/Question/QuestionsEngine.swift`

`QuestionsEngine` ist `final class` ohne `@MainActor`. Methods wie `startNewRound()`,
`submitAnswer()` etc. werden aus `QuestionsGameViewModel` (`@MainActor`) aufgerufen.
Das ist nicht thread-safe wenn `QuestionsEngine` Properties von anderen Threads
gelesen/geschrieben werden.

---

### Q-13: `QuestionsVotingViews.swift` — 138 Zeilen leere State-Texte ohne Kontext 🟡

**Datei:** `Games/Question/QuestionsVotingViews.swift:138-168`

```swift
Text("Keine Verdächtigen gewählt")   // Line 138
Text("Keine Lügner")                  // Line 168
```

Diese leeren State-Texte sind ohne Icon, ohne Kontext, ohne Handlungsaufforderung.
(Bereits als DC-05 dokumentiert — Empty States inkonsistent.)

---

### Q-14: `AppModel` ist nicht `@MainActor` — aber `scores` didSet schreibt auf UserDefaults 🟡

**Datei:** `Games/Question/AppModel.swift`

`AppModel: ObservableObject` ohne `@MainActor`. `scores.didSet` schreibt synchron
auf `UserDefaults.standard` — das kann von beliebigen Threads aus passieren.

---

### Q-15: `QuestionsModels.swift` — Viele Modelle in einer Datei, schwer navigierbar 🟡

**Datei:** `Games/Question/QuestionsModels.swift`

Alle Modelle für Question (Questions-Kategorien, Phasen, Antworten, Konfig, Rollen etc.)
sind in einer einzigen `QuestionsModels.swift` Datei. Bei wachsender Komplexität
wird die Datei schwer navigierbar.

---

## ZUSAMMENFASSUNG QUESTION AUDIT

| Priorität | Anzahl | Top-Findings |
|-----------|--------|-------------|
| 🔴 Kritisch | 2 | Force-Unwrap Crash QuestionsEngine (Q-01), suspectID! (Q-02) |
| 🟠 Hoch | 4 | Lügner-Clamp ohne UI-Feedback (Q-03), Combine-Flood (Q-05), kein Kategorie-Editor (Q-09), @MainActor fehlt in Engine (Q-12) |
| 🟡 Mittel | 9 | asyncAfter ohne Cancellation (Q-04), Score-Reset (Q-06), Fairness-Reset (Q-07), Kategorie-Info (Q-08), TV-Board Doku (Q-10), Punkte während Collect (Q-11) |

---

*Erstellt: 2026-04-12 — Teil von Phase 4 des Gesamtaudits*
