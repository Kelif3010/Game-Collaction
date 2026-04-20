# IMPROVEMENT ROADMAP — Games Collection
## Priorisierte Verbesserungs-Roadmap
### Erstellt: 2026-04-12 · Aktualisiert: 2026-04-14

> Sprint-Status wird hier gepflegt. Für den täglichen Arbeitsstand → `IMPLEMENTATION_STATUS.md`

---

## SPRINT 0 — App-Store-Blocker ✅ ERLEDIGT (Commit c7b6249)

| # | Task | Status |
|---|------|--------|
| B-01 | `PrivacyInfo.xcprivacy` erstellt | ✅ — ⚠️ noch manuell in Xcode-Target einbinden |
| B-02 | `ITSAppUsesNonExemptEncryption = false` in Info.plist | ✅ |
| B-03 | Privacy Policy erstellen (Dokument + URL) | ⬜ manuell offen |
| B-04 | Version/Build-Nummer prüfen | ⬜ manuell offen |
| B-05 | App-Store-Texte DE + EN | ⬜ manuell offen |
| B-06 | Screenshots (iPhone 6.9" + 6.3") | ⬜ manuell offen |

---

## SPRINT 1 — Crash-Fixes ✅ ERLEDIGT (Commit c7b6249)

| # | Task | Status |
|---|------|--------|
| C-01 | Force-Unwrap `GameLogic.startGame()` bei leerer Kategorie | ✅ |
| C-02 | `promptPairs.indices.randomElement()!` in QuestionsEngine | ✅ |
| C-03 | `suspectID!` in QuestionsResultsPhaseView | ✅ |
| C-04 | `SlotRewardFullView` Timer force-unwrap | ✅ |
| C-05 | Force-Unwrap URLs in MainSettingsView | ✅ |

---

## SPRINT 2 — Kernfeature-Bugs ✅ ERLEDIGT (Commit d423016)

| # | Task | Status |
|---|------|--------|
| F-01 | Haptics-Setting reparieren | ✅ |
| F-02 | Bet Buddy Scores persistieren | ✅ |
| F-03 | GlobalStatsManager in alle Games einbinden | ⏭ Phase E |
| F-04 | iCloud UUID-basiertes Merge | ✅ |
| F-05 | Imposter Silent-Failure → Alert | ✅ |
| F-06 | `timesPlayed` Doppelzählung beheben | ✅ |
| F-07 | `hostPeerName` Property in MultipeerManager | ✅ |
| F-08 | Host-Disconnect Alert an Clients | ✅ |

---

## SPRINT 3 — Memory Leaks & Performance ✅ ERLEDIGT (Commit d423016)

| # | Task | Status |
|---|------|--------|
| P-01 | `receivedMessages` auf max. 100 begrenzen | ✅ |
| P-02 | Timer-Leaks in Views (`onDisappear` Invalidierung) | ✅ |
| P-03 | `deinit` mit Task → explizites `cleanup()` | ✅ |
| P-04 | `gameState.didSet` in TimesUp getrennt | ✅ |
| P-05 | `appLocale` gecacht | ✅ |
| P-06 | Kategorie-Dictionary in Imposter cachen | ⏭ Phase E |
| P-07 | `@MainActor` zu GameLogic + QuestionsEngine hinzufügen | ⏭ Phase E |
| P-08 | iCloud KV Store Größenprüfung (900KB) | ✅ |

---

## SPRINT 4 — UI Cleanup & iOS 26 Basis ✅ ERLEDIGT (Commit d423016)

| # | Task | Status |
|---|------|--------|
| UI-01 | 127× `cornerRadius` → `clipShape(RoundedRectangle(...))` | ✅ |
| UI-02 | `foregroundColor` → `foregroundStyle` | ✅ |
| UI-03 | `NavigationView` → `NavigationStack` | ✅ |
| UI-04 | Liquid Glass auf Circle-Buttons (29), Floating-Button, GameModeCard | ✅ |
| UI-05 | Dynamic Type: 279× feste Fontgrößen mit `relativeTo:` | ✅ |
| UI-06 | Touch Targets: 38× Buttons auf 44×44pt | ✅ |

---

## SPRINT 5 — Accessibility ⬜ AUSSTEHEND (Phase D)

> **Skill:** `swiftui-wcag-accessibility-auditor` aktivieren.

| # | Task | Finding | Aufwand |
|---|------|---------|---------|
| A-01 | `accessibilityLabel` für alle interaktiven Elemente in allen 6 Games | AC-01 | ~6h |
| A-02 | Dekorative Bilder → `accessibilityHidden(true)` | AC-02 | ~1h |
| A-03 | Lottie-Animationen → `accessibilityLabel` + Reduce-Motion | AC-12 | ~1h |
| A-04 | `accessibilityHint` für komplexe Gesten | AC-03 | ~2h |
| A-05 | Fokus-Kontrolle nach Sheet-Dismiss | AC-07 | ~1h |

**Schätzung: ~11 Stunden**

---

## SPRINT 6 — Lokalisierung ⬜ AUSSTEHEND (Phase D)

| # | Task | Finding | Aufwand |
|---|------|---------|---------|
| L-01 | Fehlende DE-Keys übersetzen (421 → ~1094 Zeilen) | LOC-01 | ~8h |
| L-02 | 50 häufigste hardcodierte Strings in Games/ lokalisieren | LOC-02 | ~4h |
| L-03 | `NSLocalNetworkUsageDescription` lokalisieren | LOC-08 | ~30 Min |
| L-04 | `Localizable.stringsdict` für Plural-Formen | LOC-05 | ~2h |

**Schätzung: ~15 Stunden**

---

## SPRINT 7 — Architektur & Technische Schulden ⚠️ TEILWEISE

| # | Task | Finding | Status |
|---|------|---------|--------|
| ARC-01 | Duplikat-HapticsManager entfernen | D-01, D-05 | ⏭ offen |
| ARC-02 | Legacy `onEventReceived` Callback entfernen | SVC-12 | ⏭ V1.2 |
| ARC-03 | `GameManager` (TimesUp) aufteilen | TU-12 | ⏭ V1.2 |
| ARC-04 | MPC-Events typsicher (Enum statt Strings) | SVC-14 | ✅ |
| ARC-05 | `GlobalStatsManager` iCloud-Sync | SVC-10 | ⏭ offen |
| ARC-06 | `TimesUpGameView` aufteilen (1600+ Zeilen) | TU-15 | ⏭ V1.2 |
| ARC-07 | Toten Code entfernen (D-13..D-16) | D-13..D-16 | ⏭ offen |
| ARC-08 | `@StateObject` für Singletons → `@ObservedObject` | SW-04 | ✅ |
| ARC-09 | Kategorie-Dictionary in Imposter cachen | P-02 | ⏭ offen |
| ARC-10 | GlobalStatsManager in Bet Buddy, Question, TimesUp | DA-01 | ⏭ offen |

---

## SPRINT 8 — ProMotion & Performance-Polishing ⬜ GEPLANT

*Basiert auf `PERFORMANCE_PROMOTION.md`*

| # | Task | Datei | Aufwand |
|---|------|-------|---------|
| PR-01 | `asyncAfter(0.18s)` → `Task { @MainActor }` (6 Spielkarten-Buttons) | `ContentView.swift` | 15 Min |
| PR-02 | `FFBackground` Duplizierung entfernen (6× auf 1× reduzieren) | `FalscheFaehrteWrapper.swift` + Sub-Views | 30 Min |
| PR-03 | `preferredFrameRateRange` für Animations-Transactions setzen | `ContentView.swift` + Wrapper | 30 Min |
| PR-04 | `.animation()` vom ZStack auf `Group` einengen | Alle 6 Wrapper-Dateien | 10 Min |

**Schätzung: ~1.5 Stunden — geringes Risiko, sichtbarer Impact (120fps Animationen)**

---

## SPRINT 9 — Nice-to-have & Feature-Gaps ⬜ OFFEN

*Basiert auf `PRODUCT_OPPORTUNITIES.md`*

| # | Task | Finding | Aufwand |
|---|------|---------|---------|
| N-01 | Question: Kategorie-Editor für eigene Fragen | Q-09 | ~8h |
| N-02 | TimesUp: Pause-Feature | TU-09 | ~2h |
| N-03 | App-weites Onboarding | AS-07, UX-19 | ~8h |
| N-04 | Crash-Reporter (Crashlytics / Sentry) | AS-08 | ~3h |
| N-05 | QR-Code für Raum-Code-Sharing | SVC-09 | ~3h |
| N-06 | Meta-Session (mehrere Spiele am Stück) | — | ~15h |
| N-07 | App-weite Achievements und Progression | — | ~12h |
| N-08 | Shareable Recaps (Bild/Story-Export) | — | ~8h |

---

## SPRINT 10 — Falsche Fährte Multiplayer ⬜ GEPLANT

*Basiert auf `FF_MULTIPLAYER_PLAN.md` — Jeder spielt auf eigenem Gerät*

| Phase | Task | Aufwand |
|-------|------|---------|
| 1 | `FFMultiplayerModels.swift` + neue MPC-Events in `MPCEventTypes.swift` | 0.5 Tage |
| 2 | `FFMultiplayerSheet.swift` (Lobby) + Host-Logik in `FFViewModel` | 2–3 Tage |
| 3 | `FFBluffPhaseView` + `FFVotePhaseView` Multiplayer-Branch | 1 Tag |
| 4 | Tests (2 Geräte), Disconnect-Handling, UI-Polishing | 1–2 Tage |

**Schätzung: ~5–7 Tage**

---

## ROADMAP-ÜBERSICHT

```
SPRINT 0   App-Store-Blocker        ✅  ~9h
SPRINT 1   Crash-Fixes              ✅  ~2h
SPRINT 2   Kernfeature-Bugs         ✅ ~11h
SPRINT 3   Memory Leaks             ✅  ~8h
SPRINT 4   iOS 26 + UI Cleanup      ✅ ~18h
──────────────────────────────────────────
           V1.0 Launch-ready ← WIR SIND HIER
──────────────────────────────────────────
SPRINT 5   Accessibility            ⬜ ~11h
SPRINT 6   Lokalisierung            ⬜ ~15h
SPRINT 7   Architektur-Schulden     ⚠️ ~21h (teilw. erledigt)
SPRINT 8   ProMotion-Performance    ⬜  ~1.5h  ← Quick Win!
──────────────────────────────────────────
           V1.1 stabiles Release
──────────────────────────────────────────
SPRINT 9   Features & Nice-to-have  ⬜ ~59h
SPRINT 10  FF Multiplayer           ⬜  ~5–7 Tage
──────────────────────────────────────────
           V2.0 vollständig poliert
```

**Restaufwand bis V1.1: ~49 Stunden**
**Restaufwand bis V2.0: ~120+ Stunden**

---

*Erstellt: 2026-04-12 · Aktualisiert: 2026-04-14 — Sprints 0–4 abgeschlossen*
