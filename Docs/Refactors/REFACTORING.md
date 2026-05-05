# Refactoring Schlachtplan

Ziel: Wartbarer, lesbarer, performanter Code auf Swift 6 & iOS 26 Basis. Neueste Api, neuste Code Varianten, neuste Frameworks.
Vorgehen: **Eine Phase nach der anderen.** Warte auf "go" bevor du weitermachst. Erkläre kurz bevor du anfanängst welches Paket du benutzt und welchen Skill

---

## Legende
- ✅ Erledigt
- 🔄 In Arbeit
- ⏳ Wartet auf go
    
---

## Phase 1 — Daten aus dem Code heraus ✅ ERLEDIGT
**Dateien:** AlphabetHints.swift (1323 Zeilen → 12 Zeilen)
**Was passiert ist:**
- 53 Kategorien, 83 KB Textdaten → `alphabet_hints.json` (im App-Bundle)
- `AlphabetHints.swift` ist jetzt ein 12-Zeilen JSON-Loader
- `BetBuddyHintService.swift` updated: Alphabet-Hints als fertiges `[String]`, kein String-Split mehr nötig
- Keine Compiler-Fehler

---

## Phase 2 — Restliche Hint-Dateien ebenfalls → JSON ✅ ERLEDIGT
**Dateien:** ClassicHints (272 Einträge), PartyHints (280), SpicyHints (217) → je 12-Zeilen Loader
**Was passiert ist:**
- `classic_hints.json` (64 KB), `party_hints.json` (85 KB), `spicy_hints.json` (57 KB)
- Alle 4 Hint-Dateien jetzt identisches Muster: JSON-Loader, Typ `[String: [String]]`
- `BetBuddyHintService.swift`: von 37 auf 18 Zeilen — kein String-Split mehr, sauberes Merge
- Keine Compiler-Fehler

---

## Phase 3 — ContentView.swift aufteilen ✅ ERLEDIGT
**Datei:** `ContentView.swift` (1136 Zeilen → 131 Zeilen)
**Was passiert ist:**
- `AppRouter.swift` — `ObservableObject` mit allen `isPresented`-States + `openGame(for:)` Logik
- `Views/AppBackground.swift` — MeshGradient/Fallback-Hintergrund
- `Views/PartyBannerButton.swift` — Party-starten Banner
- `Views/SnowView.swift` — Winter-Schneeeffekt + `SnowParticle`
- `Views/SessionKingCard.swift` — Session King Anzeige
- `Views/GameCards/MenuGameCard.swift` — Time's Up Karte
- `Views/GameCards/BetBuddyGameCard.swift` — Casino-Theme Karte
- `Views/GameCards/ImposterGameCard.swift` — Spy-Theme Karte
- `Views/GameCards/LugnerGameCard.swift` — Lügendetektor Karte
- `Views/GameCards/SoundCinemaGameCard.swift` — Geräusch-Kino Karte
- `Views/GameCards/FalscheFaehrteGameCard.swift` — Detektiv-Theme Karte
- `Shared/GlassEffects.swift` — `CompatibleGlassEffectContainer` + `compatibleGlassCardEffect` hinzugefügt
- `ContentView.swift` konsolidierter `gameButton`-Helper: 6 identische Button-Blöcke → 1 generische Funktion
- Keine Compiler-Fehler

---

## Phase 4 — TimesUp GameManager.swift aufteilen ✅ ERLEDIGT
**Datei:** `Games/TimesUp/Managers/GameManager.swift` (1880 Zeilen → gelöscht)
**Was passiert ist:**
- `TimesUpGameManager.swift` — Koordinator: alle Properties, Init, Team/Category-Management, Game-Flow (538 Zeilen)
- `TimesUpTimer.swift` — Timer, Freeze, Time Bomb, Rush, Slow Motion (186 Zeilen)
- `TimesUpScoring.swift` — Punkte, Strafen, Streaks, Combos, Perks (338 Zeilen)
- `TimesUpState.swift` — Nested Types (PerkToast, AwardedPerk etc.) + UI-Queries + Visual Effects + Slot Machine (601 Zeilen)
- Swift-Extension-Ansatz: Klasse bleibt `GameManager`, Properties in Hauptdatei, Methoden in Extensions
- Keine Compiler-Fehler

---

## Phase 5 — TimesUpGameView.swift aufteilen ✅ ERLEDIGT
**Datei:** `Games/TimesUp/Views/TimesUpGameView.swift` (1636 Zeilen → 92 Zeilen)
**Was passiert ist:**
- `TimesUpGameView.swift` — Root/Navigation/Toolbar/Preview
- `TimesUpRoundView.swift` — normale Spielrunde, Word-Banner, Action-Buttons, Perk-Notices, Streak
- `TimesUpTransitionView.swift` — Setup, Round-End, Slot-Bonus
- `TimesUpResultView.swift` — Game-End, Scoreboard, Penalty-Reveal
- `TimesUpGameComponents.swift` — Team-Badges, Score-Bursts, Header-Komponente
- Neue Dateien werden über Xcodes file-system-synchronized Groups automatisch ins Target aufgenommen
- Keine Compiler-Fehler

---

## Phase 6 — TimesUp SettingsView.swift aufteilen ✅ ERLEDIGT
**Datei:** `Games/TimesUp/Views/SettingsView.swift` (1299 Zeilen → 247 Zeilen)
**Was passiert ist:**
- `TimesUpSettingsComponents.swift` — `TimesUpSettingsRow` + `TimesUpSelectionSheetHeader` (139 Zeilen)
- `TimesUpTeamsDetailView.swift` — Teams-Verwaltung mit Add/Remove (126 Zeilen)
- `TimesUpCategoriesDetailView.swift` — Kategorienauswahl + `TimesUpCategoryRowView` (142 Zeilen)
- `TimesUpTimeAndWordsSheet.swift` — Zeit & Wörter Sliders (121 Zeilen)
- `TimesUpDifficultySheet.swift` — Schwierigkeit-Auswahl (111 Zeilen)
- `TimesUpGameModeSheet.swift` — Spielmodus-Auswahl (104 Zeilen)
- `TimesUpPerkSettingsView.swift` — `PerkSettingsDetailView` + `PerkPackCard` + `CustomPerkSelectionView` (265 Zeilen)
- `TimesUpLeaderboardInfoViews.swift` — Leaderboard + Info Placeholders (37 Zeilen)
- `SettingsView.swift` — Nur noch Hauptview mit Navigation/Sheets (247 Zeilen)
- Keine Compiler-Fehler

---

## Phase 7 — Imposter GameLogic.swift aufteilen ✅ ERLEDIGT
**Datei:** `Games/Imposter/Models/GameLogic.swift` (1058 Zeilen → 364 Zeilen)
**Was passiert ist:**
- `ImposterWordAssigner.swift` — Rollen- & Wortverteilung: `distributeRoles`, `assignWordsToPlayers`, `selectWordsForGameMode`, `selectRandomImposters` (233 Zeilen)
- `ImposterGameState.swift` — Timer, Game-Flow, MPC-Broadcast, Computed Properties, Restart (294 Zeilen)
- `ImposterVotingLogic.swift` — Abstimmungslogik: `startMultiplayerVoting`, `handleMultiplayerVoteCast`, Tally-Berechnung (157 Zeilen)
- `GameLogic.swift` — Koordinator: Properties, Init, startGame, Multiplayer-Setup, Rematch-Orchestrierung (364 Zeilen)
- Swift-Extension-Ansatz: Klasse bleibt `GameLogic`, Properties in Hauptdatei, Methoden in Extensions
- Keine Compiler-Fehler

---

## Phase 8 — Imposter GamePlayView.swift aufteilen ✅ ERLEDIGT
**Datei:** `Games/Imposter/Views/GamePlayView.swift` (1302 Zeilen → 467 Zeilen)
**Was passiert ist:**
- `ImposterCardRevealPhaseView.swift` — Kartenaufdeckungs-Phase (38 Zeilen)
- `ImposterPlayingPhaseView.swift` — Spielphase + Multiplayer-Countdown inkl. `countdownSeconds` Berechnung (57 Zeilen)
- `ImposterGameTimerView.swift` — `GameTimerView` + `SpyActionButton` + `GameControlBtn` (443 Zeilen)
- `ImposterGameComponents.swift` — `MultiplayerWaitingView`, `ImposterGameHeaderView`, `StartingPlayerAnnouncementView`, `GameFooterView` (275 Zeilen)
- `GamePlayView.swift` — Koordinator: States, Phase-Router (`mainContent`), alle `onChange`-Handler, Logik-Methoden, `PlayerIdentity` (467 Zeilen)
- Keine Compiler-Fehler

---

## Phase 9 — Falsche Fährte FFSetupView.swift aufteilen ✅ ERLEDIGT
**Datei:** `Games/Falsche Faehrte/Views/FFSetupView.swift` (947 Zeilen → 340 Zeilen)
**Was passiert ist:**
- `FFSetupComponents.swift` — `FFSetupActionRow`, `FFSetupToggleRow`, `FFSetupIconBadge`, `FFInfoSheet` (211 Zeilen)
- `FFSetupSheets.swift` — `FFPlayerPickerSheet`, `FFPackPickerSheet`, `FFRoundsPickerSheet`, `FFBluffTimerPickerSheet` (425 Zeilen)
- `FFSetupView.swift` — Koordinator: States, Header, Setup-Card, Start-Button, Multiplayer-Sheet, Game-Start-Logik (340 Zeilen)
- Keine Compiler-Fehler

---

## Phase 10 — Questions TV-Board & Sound Cinema aufteilen ✅ ERLEDIGT
**Dateien:**
- `Games/Question/Views/TV/QuestionsTVBoardView.swift` (924 Zeilen → 77 Zeilen)
- `Games/Sound Cinema/Views/SoundCinemaSetupView.swift` (778 Zeilen → 264 Zeilen)

**Was passiert ist:**
- `QuestionsTVComponents.swift` — `TVCinematicRevealView` (Stempel-Animation) + `TVHeaderView` (211 Zeilen)
- `QuestionsTVSetupView.swift` — `TVSetupView` + `TVPlayerTickerBand` + `TVPlayerChip` (177 Zeilen)
- `QuestionsTVCollectingView.swift` — `TVCollectingView` + `TVSignalLine` (EKG) + `TVCollectingStatusRow` + `TVCollectingChip` + `CollectingStatus` (219 Zeilen)
- `QuestionsTVOverviewView.swift` — `TVOverviewView` + `TVAnswerCard` (143 Zeilen)
- `QuestionsTVResultsView.swift` — `TVResultsView` (82 Zeilen)
- `QuestionsTVBoardView.swift` — Koordinator: Hintergrund, Phase-Router, Cinematic-Trigger (77 Zeilen)
- `SoundCinemaSetupComponents.swift` — `SoundCinemaSetupActionRow` + `SoundCinemaSetupIconBadge` (91 Zeilen)
- `SoundCinemaSetupSheets.swift` — `SoundCinemaPlayerPickerSheet`, `SoundCinemaPackPickerSheet`, `SoundCinemaTimerPickerSheet`, `SoundCinemaLivesPickerSheet` (428 Zeilen)
- `SoundCinemaInfoSheet.swift` — `SoundCinemaInfoSheet` (Spielregeln) (84 Zeilen)
- `SoundCinemaSetupView.swift` — Koordinator: States, Header, Setup-Card, Start-Button (264 Zeilen)
- Keine Compiler-Fehler

---

## Phase 11 — Swift 6 Modernisierung ⏳
**Betrifft:** Alle Manager- und Service-Dateien
**Problem:** Ältere async-Patterns, möglicherweise Data-Races.
**Lösung:**
- `@Observable` statt `ObservableObject` / `@Published`
- `actor` für thread-sichere Services
- Keine Combine-Abhängigkeiten mehr
- `async/await` durchgängig

---

## Phase 12 — iOS 26 / Liquid Glass Design ⏳
**Betrifft:** Alle Views
**Problem:** App nutzt noch das alte Design-System.
**Lösung:**
- Liquid Glass Materialien einsetzen wo es passt
- Neue NavigationStack / TabView Patterns
- Neue Button-Styles, Sheet-Darstellungen
- Nach Phase 11, denn in kleinen Dateien ist das viel einfacher

---

## Verfügbare Pakete (können wir nutzen)
| Paket | Zweck |
|---|---|
| Lottie 4.6.0 | Animationen — bereits genutzt |
| Pow 1.0.6 | Effekte für Übergänge |
| SFSafeSymbols 7.0.0 | Typsichere SF Symbols |
| swift-algorithms 1.2.1 | Shuffling, Chunking, Sliding Window |
| swift-async-algorithms 1.1.3 | Async Streams & Sequenzen |
| swift-collections 1.4.1 | OrderedDictionary, Deque |
| swift-numerics 1.1.1 | Numerische Präzision |

---
Skills benutzten falls sinvoll und Nötig

*Letzte Aktualisierung: Phase 10 abgeschlossen*
