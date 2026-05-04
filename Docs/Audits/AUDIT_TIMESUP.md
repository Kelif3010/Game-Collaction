# AUDIT: TimesUp — Phase 4.4
## Erstellungsdatum: 2026-04-12

> Vollständiger Audit des TimesUp-Spiels (Begriffe-Rate-Spiel mit Perks).
> Dateien: 35 Swift-Dateien in Games/TimesUp/

---

## ÜBERSICHT

| Kategorie | Findings |
|-----------|----------|
| Kritische Bugs | 3 |
| Logik-Fehler | 5 |
| Feature-Lücken | 3 |
| Code-Qualität | 5 |
| **TOTAL** | **16** |

---

## KATEGORIE A: KRITISCHE BUGS

---

### TU-01: `gameState.didSet` schreibt bei JEDEM State-Change auf Disk 🔴

*(Bereits als P-01 in AUDIT_PERFORMANCE.md dokumentiert — hier vertieft)*

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

`gameState` enthält Settings UND Spiel-State (Punkte, aktuelles Wort, Timer etc.).
Bei jedem Timer-Tick, jedem Wort-Wechsel, jedem Perk-Trigger wird der gesamte
`gameState` encodiert und auf Disk geschrieben. Timer-Takt: 0.1 Sekunden →
**10× pro Sekunde Disk-IO**. Das frisst Batterie und verlangsamt das UI.

**Fix:** Nur Settings persistieren, nicht den Laufzeit-State:
```swift
// Nur wenn Settings sich ändern:
private func saveSettings() {
    if let data = try? JSONEncoder().encode(gameState.settings) {
        UserDefaults.standard.set(data, forKey: "timesup.settings")
    }
}

// In didSet nur Settings-Änderungen triggern saveSettings()
```

---

### TU-02: `deinit` mit Task auf `@MainActor` — Task wird nie ausgeführt wenn Actor freigegeben wird 🔴

*(Bereits als C-02 in AUDIT_PERFORMANCE.md dokumentiert)*

**Datei:** `Games/TimesUp/Managers/GameManager.swift:212-218`

```swift
deinit {
    Task { @MainActor [weak self] in
        self?.turnTimer.invalidate()
        self?.activeTimeBombTimers.values.forEach { $0.invalidate() }
    }
}
```

`deinit` läuft auf einem beliebigen Thread. Das `Task` wird einem Executor übergeben,
der zu dem Zeitpunkt möglicherweise bereits freigegeben ist. Timer werden dann
nie invalidiert → **Memory Leak / Timer-Leak**.

**Fix:**
```swift
// turnTimer als nonisolated struct der sich selbst deinit:
// Oder: Explizites cleanup() aufrufen bevor dismiss
func cleanup() {
    turnTimer.invalidate()
    activeTimeBombTimers.values.forEach { $0.invalidate() }
    activeTimeBombTimers.removeAll()
}
```

---

### TU-03: `SlotRewardFullView` Timer mit force-unwrap — Crash möglich 🔴

*(Bereits als P-03 in AUDIT_PERFORMANCE.md dokumentiert)*

**Datei:** `Games/TimesUp/Views/TimesUpGameView.swift`

```swift
// SlotRewardFullView nutzt Timer 10x/Sekunde mit force-unwrap auf Team-Zugriff
```

Der SlotReward-View läuft einen hochfrequenten Timer der auf Team-Daten zugreift.
Force-Unwrap bei der Slot-Animationslogik kann bei ungültigem State crashen.

---

## KATEGORIE B: LOGIK-FEHLER

---

### TU-04: `GameManager` hat 33 `DispatchWorkItem` Instanzen — kein zentrales Lifecycle-Management 🟠

*(Bereits als T-01 in AUDIT_PERFORMANCE.md dokumentiert)*

```swift
// Beispiele aus GameManager.swift:
private var swapWordTasks: [UUID: DispatchWorkItem] = [:]
private var invisibleWordHideTasks: [UUID: DispatchWorkItem] = [:]
private var englishWordExpiryTasks: [UUID: DispatchWorkItem] = [:]
private var attackNoticeExpiryTasks: [UUID: [UUID: DispatchWorkItem]] = [:]
```

Keine dieser Tasks wird in einer zentralen `cancelAllTasks()` Methode gecancelt.
Wenn Teams mitten im Spiel entfernt werden oder das Spiel endet, können verwaiste
DispatchWorkItems noch auf freigegebene Objekte zugreifen.

---

### TU-05: Timer-Werte bei GameStart inkonsistent initialisiert 🟠

**Datei:** `Games/TimesUp/Managers/GameManager.swift:293-300`

`startGame()` initialisiert Timer-Werte aus `gameState.settings`.
Wenn `gameState.settings` aus einem vorherigen Spiel geladen wurde (persistence),
können alte Timer-Restwerte den neuen Spielstart beeinflussen.

Es fehlt ein explizites `resetRuntimeState()` beim `startGame()`.

---

### TU-06: Perks-System — `maxPerksPerTurn` wird nicht durchgesetzt bei gleichzeitigen Perk-Aktivierungen 🟠

**Datei:** `Games/TimesUp/Managers/GameManager.swift:93-95`

```swift
private var maxPerksPerTurn: Int {
    gameState.settings.perkPartyMode ? 3 : 2
}
```

`perksTriggeredThisTurn` zählt aktivierte Perks. Aber bei gleichzeitigen
Aktivierungen (z.B. zwei Perks die beide durch das gleiche Event getriggert werden)
kann `maxPerksPerTurn` überschritten werden wenn die Checks nicht atomar laufen.

---

### TU-07: Runde 4 (Zeichnen) wird ohne Kategorienprüfung gestartet 🟡

**Datei:** `Games/TimesUp/Views/TimesUpGameView.swift:14-19`

```swift
if gameManager.gameState.currentRound == .round4 {
    DrawingView(gameManager: gameManager)
}
```

`DrawingView` wird gestartet wenn `currentRound == .round4`. Aber die Zeichnen-
Runde ist nur im Modus `withDrawing` verfügbar. Wenn irgendwie `currentRound`
auf `.round4` gesetzt wird obwohl der Modus `classic` ist, startet die Zeichnen-
Runde unerwartet.

---

### TU-08: Wörter-Pool — keine Prüfung ob genug Wörter für alle Teams vorhanden 🟡

**Datei:** `Games/TimesUp/Managers/GameManager.swift:293-305`

```swift
var allAvailableTerms = gameState.settings.selectedCategories.flatMap { $0.terms }
allAvailableTerms.shuffle()
```

Wenn `allAvailableTerms.count < settings.wordsPerTeam * teams.count` gibt es
nicht genug Wörter. Die App füllt wahrscheinlich mit Duplikaten oder läuft in
einen leeren State. Das Minimum-Wörter-Limit wird nicht explizit kommuniziert.

---

## KATEGORIE C: FEATURE-LÜCKEN

---

### TU-09: Kein Pause-Feature für laufende Timer-Runden 🟠

**Datei:** `Games/TimesUp/Views/TimesUpGameView.swift`

Im PlayingPhaseView gibt es keinen "Pause" Button für den Timer. Ein Spieler
muss kurz weg (Toilette), das Telefon klingelt — der Timer läuft trotzdem weiter.
Bet Buddy hat einen Pause-Button für den Timer; TimesUp sollte dasselbe haben.

---

### TU-10: KI-Kategorie-Generator — kein Offline-Fallback, keine Fehler-UX 🟠

**Datei:** `Games/TimesUp/Views/AICategoryGeneratorView.swift`

`AICategoryGeneratorView` nutzt `AIService` für OpenAI-basierte Kategorie-Generierung.
Wenn kein Internet vorhanden oder der API-Key fehlt, gibt es keinen klaren
Offline-Fallback. Der Nutzer sieht wahrscheinlich eine spinning ProgressView
oder einen generischen Fehler.

---

### TU-11: Zeichnen-Runde ohne Canvas-Export — gezeichnete Bilder verschwinden nach Runde 🟡

**Datei:** `Games/TimesUp/Views/Drawing/DrawingView.swift`

Gezeichnete Bilder (PencilKit Canvas) werden nicht gespeichert. Am Ende der
Zeichnen-Runde gibt es keine Möglichkeit, die lustigsten Zeichnungen zu sehen
oder zu teilen. Das wäre ein großes Social-Feature.

---

## KATEGORIE D: CODE-QUALITÄT

---

### TU-12: `GameManager` ist ein 500+ Zeilen Gott-Objekt 🟠

**Datei:** `Games/TimesUp/Managers/GameManager.swift`

`GameManager` handhabt:
- Team-Management
- Timer-Logic
- Perk-System (20+ Perks)
- Slot-Machine-Logic
- Zeichnen-Runden-Integration
- Scoring
- Score-Bursts / Visual Effects
- AI-Kategorie-Generator
- Word Translation
- DispatchWorkItem-Management

Das ist zu viel für eine Klasse. Aufteilen in:
- `GameManager` (Core: Timer, Teams, Words)
- `PerkManager` (Perks, Slots, Visual Effects)
- `ScoreManager` (Scoring, Bursts)

---

### TU-13: Toolbar in `TimesUpGameView` doppelt definiert — einmal `.toolbar` dann `.toolbar(.hidden)` 🟡

*(Bereits als DC-08 dokumentiert)*

**Datei:** `Games/TimesUp/Views/TimesUpGameView.swift:35-52, 70`

```swift
.toolbar {
    ToolbarItem(...) { Button("Beenden") { } }
    ToolbarItem(...) { TeamBadgeBar(...) }
}
// ...
.toolbar(.hidden, for: .navigationBar)  // Und dann versteckt!
```

Wenn die Toolbar mit `.hidden` versteckt wird, sind die definierten Toolbar-Items
dead code. Entweder `.toolbar(.hidden)` entfernen (dann sieht man die Toolbar)
oder die `.toolbar { }` Blöcke entfernen (und Beenden-Button anders einbauen).

---

### TU-14: `appLocale` Property in `GameManager` — bei jedem Aufruf UserDefaults-Lesung 🟠

*(Bereits als T-04 in AUDIT_PERFORMANCE.md dokumentiert)*

```swift
private var appLocale: Locale {
    let defaults = UserDefaults.standard     // Jedes Mal lesen!
    let useSystem: Bool
    if defaults.object(forKey: "useSystemLanguage") == nil { ... }
}
```

`appLocale` ist ein computed property das bei jedem Aufruf `UserDefaults.standard`
liest. Es wird in `localized()` aufgerufen, das wiederum bei jedem Wort-Wechsel
aufgerufen wird. Das sind hunderte UserDefaults-Reads pro Spielminute.

**Fix:** Einmalig cachen und bei Settings-Änderung neu setzen.

---

### TU-15: `TimesUpGameView` hat 1600+ Zeilen — Split in mehrere View-Dateien nötig 🟡

**Datei:** `Games/TimesUp/Views/TimesUpGameView.swift`

Mit 1600+ Zeilen ist `TimesUpGameView.swift` die längste View-Datei im Projekt.
Sie enthält SetupPhaseView, SlotRewardFullView, PlayingPhaseView, RoundEndView,
GameEndView alle in einer Datei. Das macht die Datei schwer navigierbar.

---

## ZUSAMMENFASSUNG TIMESUP AUDIT

| Priorität | Anzahl | Top-Findings |
|-----------|--------|-------------|
| 🔴 Kritisch | 3 | Disk-IO bei jedem Timer-Tick (TU-01), Timer-Leak in deinit (TU-02), SlotReward Force-Unwrap (TU-03) |
| 🟠 Hoch | 5 | 33 unkontrollierte DispatchWorkItems (TU-04), GameManager Gott-Objekt (TU-12), appLocale Performance (TU-14), kein Pause (TU-09), KI offline (TU-10) |
| 🟡 Mittel | 8 | Timer-Init (TU-05), Perks Race (TU-06), Runde4 ohne Check (TU-07), Wörter-Pool (TU-08), Canvas Export (TU-11), Toolbar-Duplikat (TU-13), 1600-Zeilen View (TU-15) |

---

*Erstellt: 2026-04-12 — Teil von Phase 4 des Gesamtaudits*
