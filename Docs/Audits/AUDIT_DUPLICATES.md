# AUDIT: Duplikate, toter Code & Strukturprobleme
## Phase 1.4 — Erstellungsdatum: 2026-04-12

> Jede Gruppe beschreibt: Was ist doppelt/tot/falsch, wo ist es, was ist der Fix.

---

## KATEGORIE A: TOTER CODE (Definiert, nie verwendet)

---

### D-01: `SessionKingCard` — definiert aber nie aufgerufen

**Datei:** `Games Collection/ContentView.swift:796-845`

```swift
struct SessionKingCard: View {  // ~50 Zeilen, nie referenziert
    let name: String
    let wins: Int
    ...
}
```

**Aktion:** Entweder in ContentView einbinden (zeigen wenn `statsManager.sessionKing != nil`) oder löschen.

---

### D-02: `Theme.swift` — Legacy-Wrapper ohne eigene Logik

**Datei:** `Games/Bet Buddy/Resources/Theme.swift`

```swift
enum Theme {
    static let background = BetBuddyTheme.gradient       // Nur Forward
    static let cardBackground = BetBuddyTheme.backgroundCard  // Nur Forward
    static let cardStroke = BetBuddyTheme.cardStroke     // Nur Forward
    ...
}
```

`Theme` ist ein reiner Wrapper um `BetBuddyTheme`. Es hat keinen eigenen Wert. Alle Verwendungen direkt auf `BetBuddyTheme` umstellen und `Theme.swift` löschen.

**Nutzung von `Theme.`: ~224 Treffer in Bet Buddy Files** — sollten zu `BetBuddyTheme.` umgestellt werden.

---

### D-03: `dsds.swift` — Datei mit irreführendem Namen

**Datei:** `Games/Bet Buddy/Bet Buddy Resources/dsds.swift`

Enthält die sinnvolle `Int.asAlphabet` Extension, aber der Dateiname `dsds.swift` ist komplett zufällig/falsch.

**Aktion:** Umbenennen zu `Int+Alphabet.swift` und in den Shared-Ordner verschieben.

---

### D-04: Auskommentierter Code in `AppViewModel.deductScore`

**Datei:** `Games/Bet Buddy/ViewModels/AppViewModel.swift:353-359`

```swift
/*
if var existing = highlights.allTimeScores[name] {
    existing.value = max(0, existing.value - amount)
    highlights.allTimeScores[name] = existing
}
*/
```

Auskommentierter Code sollte entfernt werden. Die Entscheidung ("erlauben wir Abzüge in der ewigen Tabelle?") sollte in einem Kommentar oder im Code dokumentiert werden, nicht als auskommentierten Code.

---

## KATEGORIE B: DOPPELTE IMPLEMENTIERUNGEN

---

### D-05: 3 verschiedene Haptics-Manager für dasselbe Ergebnis

| Manager | Datei | Game | Liest `isHapticsEnabled`? |
|---------|-------|------|--------------------------|
| `ImposterHapticsManager` | `ImposterHapticsManager.swift` | Imposter | ❌ NEIN |
| `TimesUpHapticsManager` | `TimesUpHapticsManager.swift` | TimesUp | ❌ NEIN |
| `HapticsService` | `Bet Buddy/Services/HapticsService.swift` | Bet Buddy | ❌ NEIN |
| Global Setting | `@AppStorage("isHapticsEnabled")` | App-weit | — |

**Problem:** Es gibt eine globale Einstellung zum Deaktivieren von Haptik, aber keine der 3 Implementierungen respektiert sie. Außerdem haben alle 3 fast identische Methoden (`playSuccess`, `playError`, `playTick` etc.).

**Fix:** Einen einzigen `HapticsEngine` Service erstellen der das globale Setting prüft. Die 3 Game-spezifischen Manager auf diesen delegieren oder ersetzen.

---

### D-06: `Color(hex:)` Extension — Definition und Verwendung inkonsistent

**Definiert in:** `Games/Bet Buddy/Screens/BetBuddyLeaderboardView.swift:319-340`
**Verwendet in:**
- `BetBuddyLeaderboardView.swift` (gleiche Datei)
- `Games Collection/MainSettingsView.swift:340` (anderes Layer!)

**Problem:** Eine Extension die in einem Game-spezifischen View definiert ist, wird in der App-Shell verwendet. Falsche Dependency-Richtung.

**Fix:** Extension in `Games Collection/Shared/Extensions/Color+Hex.swift` auslagern.

---

### D-07: Spieler-Verwaltung parallel in 4 Systemen

| System | Datei | Typ | Scope |
|--------|-------|-----|-------|
| `GlobalPlayerManager` | `GlobalPlayerManager.swift` | `[GlobalPlayer]` | App-weit (iCloud) |
| `GameSettings.players` | `GameSettings.swift` | `[Player]` (Imposter) | Nur Imposter |
| `GroupInfo` | `AppViewModel.groups` | `[GroupInfo]` (Bet Buddy) | Nur Bet Buddy |
| `lobbyPeers` in MPC | `MultipeerManager.swift` | `[String]` | Multiplayer |

**Problem:** Wenn ein Nutzer in den globalen Einstellungen Spieler hinzufügt, werden diese nicht automatisch in Imposter oder Bet Buddy übernommen (obwohl `GameSettings.players` von `GlobalPlayerManager` befüllt werden könnte). Der Nutzer muss Spieler in jeder Game-Setup erneut eingeben.

**Imposter bietet das an:** `GameSetupView` hat einen "Spieler aus Crew laden" Button. Bet Buddy und Question fehlt das.

---

### D-08: Stats-Systeme — 3 parallel, keine Verbindung

| System | Key | Was wird getrackt |
|--------|-----|-------------------|
| `GlobalStatsManager` | `"GlobalStats_V1"` | Wins/Losses/timesPlayed per Spieler |
| `AppViewModel.highlights` | `"BetBuddy_GlobalStats_V1"` | Bet Buddy Streaks, FastestWin, AllTimeScores |
| `StatsService` (Imposter) | Unbekannt | Imposter-spezifische Wins |

**Problem:** `GlobalRecapView` zeigt nur `GlobalStatsManager` an. Ein Bet Buddy-Sieg erscheint dort nicht, weil `AppViewModel.awardScore` nie `GlobalStatsManager.recordWin` aufruft.

---

### D-09: Header/TopBar-Pattern in jedem Game anders implementiert

Jedes Game hat seinen eigenen Header-Stil:

| Game | Implementierung | Konsistenz |
|------|----------------|------------|
| Imposter | Custom `topBar` in GameSetupView (HStack mit Buttons) | Eigener Stil |
| Bet Buddy | `ScreenHeader` Component | Eigener Stil |
| Question | Inline in QuestionsSetupView | Kein Component |
| TimesUp | Inline HStack | Kein Component |
| Main App | HStack in ContentView | Eigener Stil |

**Fix:** Eine gemeinsame `GameHeader` Component im Shared-Ordner die alle Games nutzen. Konfigurierbar per Parameter (Titel, Left/Right Buttons).

---

### D-10: Multiplayer-Sheet — separates File pro Game ohne Shared-Basis

| Game | Sheet-Datei |
|------|------------|
| Imposter | `ImposterMultiplayerSheet.swift` |
| Question | `QuestionsMultiplayerSheet.swift` |

Bet Buddy und TimesUp haben **keine** Multiplayer-Sheets, aber der MPC-Manager ist global verfügbar. Imposter und Question Multiplayer-Sheets haben vermutlich sehr ähnliche Lobby/Join/Host-UIs.

**Fix:** Einen `SharedMultiplayerSheetView` erstellen der für alle Games genutzt werden kann, mit game-spezifischen Konfigurations-Parametern.

---

### D-11: `LinearGradient`-Hintergründe identisch kopiert

**Problem:** Die Hintergrund-Gradients von `MainSettingsView` und `GameRecommenderView` sind identisch:

```swift
// MainSettingsView.swift:45-50:
LinearGradient(
    colors: [Color.black, Color.indigo.opacity(0.5), Color.purple.opacity(0.4)],
    startPoint: .top, endPoint: .bottom
)

// GameRecommenderView.swift:103-107:
LinearGradient(
    colors: [Color.indigo.opacity(0.8), Color.purple.opacity(0.6), Color.black],
    startPoint: .topLeading, endPoint: .bottomTrailing
)
```

Fast identisch, aber leicht unterschiedliche Parametrisierung. Sollten in `ImposterStyle` oder einem neuen `AppStyle` zentralisiert werden.

---

### D-12: `GlassBox` in GameRecommenderView — identisch zu `DashboardCard` Stil

**Datei:** `Games Collection/GameRecommenderView.swift:400-416`

`GlassBox` ist eine generic Container-View mit `.background(Color.white.opacity(0.1)).cornerRadius(16)`. Das ist fast identisch zum Basis-Stil der `DashboardCard` in MainSettingsView. Diese könnten vereinheitlicht werden.

---

### D-13: MoodButton und TimeButton in GameRecommenderView — identisches Muster

**Datei:** `Games Collection/GameRecommenderView.swift:419-467`

`MoodButton` und `TimeButton` sind fast identisch strukturiert: isSelected-State, Button mit Background-Wechsel, `.animation(.spring())`. Das könnte durch eine generische `ToggleChipButton<T>` View ersetzt werden.

---

## KATEGORIE C: INKONSISTENTE ARCHITEKTUR

---

### D-14: Game-Wrapper Pattern inkonsistent

| Game | Wrapper-Datei | NavigationStack? | Presentation |
|------|--------------|------------------|--------------|
| Imposter | `ImposterGameWrapper.swift` | Ja | fullScreenCover |
| Bet Buddy | `BetBuddyWrapper.swift` | Ja | fullScreenCover |
| Question | `QuestionGameWrapper.swift` | Ja | fullScreenCover |
| TimesUp | `TimesUpWrapper.swift` | Ja | fullScreenCover |

Das Muster ist konsistent (gut!), aber die interne Implementierung der Wrapper variiert. Sollte einen gemeinsamen `GameWrapperModifier` haben.

---

### D-15: `EnvironmentObject` vs. direkte Abhängigkeiten — gemischt

**Problem:** Imposter übergibt `GameSettings` und `GameLogic` über `@EnvironmentObject`:
```swift
.environmentObject(gameSettings)
.environmentObject(gameLogic)
```

Bet Buddy übergibt `AppViewModel` direkt als `@ObservedObject` Parameter.
Question nutzt `QuestionsGameViewModel` über direkte Initialisierung.

Das macht die Games schwer zu vergleichen und neue Entwickler verstehen die Architektur nicht auf Anhieb.

---

### D-16: Lottie-Animationen in Imposter, Heartbeat ECG in Question — nicht vereinheitlicht

**Imposter Resources:** 5 Lottie JSON Files
**Question Resources:** 1 Heartbeat ECG JSON

Beide nutzen `LottieView` (vermutlich das gleiche Component). Aber die Resources liegen in game-spezifischen Ordnern. Wenn `LottieView` component geteilt wird, sollte es im Shared-Ordner liegen.

**Prüfen:** Gibt es eine `LottieView.swift` im Shared-Ordner oder nur in Imposter?

Fundstelle: `Games/Imposter/Views/Components/LottieView.swift` — nur in Imposter! Question nutzt vermutlich auch eine LottieView aber von wo? Das muss geprüft werden.

---

## ZUSAMMENFASSUNG PHASE 1.4

| Kategorie | Probleme | Schwere |
|-----------|----------|---------|
| Toter Code | 4 | Niedrig-Mittel |
| Doppelte Implementierungen | 9 | Hoch (Haptics, Stats, Player) |
| Architektur-Inkonsistenz | 3 | Mittel |
| **TOTAL** | **16** | |

---

## EMPFOHLENE SHARED-DATEIEN (neu zu erstellen)

```
Games Collection/Shared/
├── Extensions/
│   ├── Color+Hex.swift          (aus BetBuddyLeaderboardView extrahieren)
│   ├── Int+Alphabet.swift       (aus dsds.swift umbenennen & verschieben)
│   └── View+GameCard.swift      (gemeinsame Card-Modifier)
├── Components/
│   ├── GameHeader.swift         (einheitlicher Header für alle Games)
│   ├── SharedMultiplayerSheet.swift  (Basis für alle MP-Sheets)
│   └── LottieView.swift         (aus Imposter in Shared verschieben)
└── Services/
    └── HapticsEngine.swift      (einheitlicher Haptics-Service)
```

---

## EMPFOHLENE LÖSCHUNGEN

| Datei | Grund |
|-------|-------|
| `Theme.swift` | Nur Wrapper um BetBuddyTheme |
| `dsds.swift` (nach Umbenennung) | Inhalt in richtiges File |
| `SessionKingCard` (in ContentView) | Nie verwendet (oder einbinden) |
| Auskommentierter Code in AppViewModel | Entscheidung treffen & dokumentieren |
