# IMPLEMENTATION STATUS — Games Collection
## Zentrale Arbeitsdatei: Was ist fertig, was läuft, was kommt
### Letzte Aktualisierung: 2026-04-14

> **Diese Datei ist die einzige, die du für den täglichen Arbeitsstand brauchst.**
> Bei Verbindungsabbruch oder neuem Session-Start: Hier einsteigen.

---

## AKTUELLER STAND

```
📍 GERADE HIER → Phase D (Accessibility + Lokalisierung)
```

| Phase | Name | Status | Commit |
|-------|------|--------|--------|
| A | App-Store-Blocker + Crashes + Quick Wins | ✅ FERTIG | c7b6249 |
| B | Kernfeature-Bugs + Performance + Stats + Multiplayer | ✅ FERTIG | d423016 |
| C | iOS 26 + Deprecated APIs + Liquid Glass + Dynamic Type | ✅ FERTIG | — (in B-Commit enthalten) |
| D | Accessibility + Lokalisierung | ⬜ AUSSTEHEND | — |
| E | Technische Schulden | ⚠️ TEILWEISE | d423016 |
| — | Geräusch-Kino (5. Spiel) | ✅ FERTIG | a6248bb |
| — | Falsche Fährte (6. Spiel) | ✅ FERTIG | 584e4de |

---

## PHASE A — App-Store-Blocker, Crashes, Quick Wins ✅

**Commit:** `c7b6249`

### A1 — App-Store-Blocker ✅
| Task | Datei | Status |
|------|-------|--------|
| `PrivacyInfo.xcprivacy` erstellt | `Games Collection/PrivacyInfo.xcprivacy` | ✅ |
| `ITSAppUsesNonExemptEncryption = false` | `Games-Collection-Info.plist` | ✅ |

> ⚠️ **Manuell in Xcode noch offen:** `PrivacyInfo.xcprivacy` ins Xcode-Target einbinden
> (Datei im Project Navigator → Target "Games Collection" anhaken)

### A2 — Force-Unwrap Crashes ✅
| Task | Datei | Finding | Status |
|------|-------|---------|--------|
| `randomElement()!` absichern | `GameLogic.swift` | IMP-01 | ✅ |
| `promptPairs.indices.randomElement()!` | `QuestionsEngine.swift:77` | Q-01 | ✅ |
| `suspectID!` (2×) | `QuestionsResultsPhaseView.swift:22` | Q-02 | ✅ |
| `symbolPool.randomElement()!` Slot-Timer | `TimesUpGameView.swift` | TU-03 | ✅ |
| `URL(string:)!` (3×) | `MainSettingsView.swift:156,166,181` | SEC-02 | ✅ |

### A3 — Quick Wins ✅
| Task | Datei | Finding | Status |
|------|-------|---------|--------|
| `receivedMessages` auf max. 100 begrenzt | `MultipeerManager.swift` | SVC-01 | ✅ |
| `timesPlayed` Doppelzählung behoben | `GlobalStatsManager.swift` | SVC-05 | ✅ |
| iCloud-Sync < 900KB Check | `GlobalPlayerManager.swift` | SEC-08 | ✅ |
| `appLocale` lazy gecacht | `TimesUp/GameManager.swift` | TU-14 | ✅ |

---

## PHASE B — Kernfeature-Bugs, Performance, Stats ✅

**Commit:** `d423016`

### B1 — Kernfeature-Bugs ✅
| Task | Datei | Finding | Status |
|------|-------|---------|--------|
| Haptics-Setting reparieren (`ensureEngine()`) | `ImposterHapticsManager.swift`, `TimesUpHapticsManager.swift` | SW-08 | ✅ |
| Bet Buddy Scores persistieren | `AppViewModel.swift` | BB-01 | ✅ |
| Imposter Silent-Failure → Alert | `GameLogic.swift`, `GameSetupView+Logic.swift` | UX-01 | ✅ |

### B2 — Timer-Leaks & Performance ✅
| Task | Datei | Finding | Status |
|------|-------|---------|--------|
| `gameState.didSet` Settings/Runtime getrennt | `TimesUp/GameManager.swift` | TU-01, P-01 | ✅ |
| `deinit` mit Task → `cleanup()` | `TimesUp/GameManager.swift` | TU-02, C-02 | ✅ |
| Timer-Leaks in Views behoben (`onDisappear`) | ContentView, WordGuessingView, QuestionsResultsPhaseView | SW-01, SW-02 | ✅ |
| Kategorie-Dictionary cachen | `Imposter/GameLogic.swift` | P-02 | ⏭ Phase E |

### B3 — iCloud Merge + Stats ✅
| Task | Datei | Finding | Status |
|------|-------|---------|--------|
| UUID-basiertes iCloud-Merge | `GlobalPlayerManager.swift` | DA-02, SVC-02 | ✅ |
| GlobalStatsManager in Bet Buddy einbinden | `AppViewModel.swift` | DA-01 | ⏭ Phase E |
| GlobalStatsManager in Question einbinden | `QuestionsGameViewModel.swift` | DA-01 | ⏭ Phase E |
| GlobalStatsManager in TimesUp einbinden | `TimesUp/GameManager.swift` | DA-01 | ⏭ Phase E |

### B4 — Multiplayer Host-Disconnect ✅
| Task | Datei | Finding | Status |
|------|-------|---------|--------|
| `hostPeerName` Property + `hostDidDisconnect` Flag | `MultipeerManager.swift` | SVC-03, SVC-06, UX-18 | ✅ |

---

## PHASE C — iOS 26 + UI Cleanup ✅

*(In commit `d423016` enthalten — kein separater Commit)*

| Task | Finding | Status | Details |
|------|---------|--------|---------|
| 127× `cornerRadius` → `clipShape(RoundedRectangle(...))` | SW-09 | ✅ | 166 gesamt (inkl. 39 die schon vorhanden waren) |
| `foregroundColor` → `foregroundStyle` | SW-10 | ✅ | Bereits vollständig migriert |
| `NavigationView` → `NavigationStack` | SW-11 | ✅ | `navigationViewStyle` in ImposterSettingsView entfernt |
| Dynamic Type: 279× feste Fontgrößen angepasst | UI-12 | ✅ | `relativeTo:` ergänzt |
| Touch Targets: 38× Buttons auf 44×44pt erhöht | UI-15 | ✅ | WCAG-konform |
| Liquid Glass auf Circle-Buttons (29 Stück) | UI-01 | ✅ | `GlassCircleButtonBackground` ViewModifier in `Shared/GlassEffects.swift` |
| Liquid Glass: FloatingStartButton (Imposter) | UI-01 | ✅ | Capsule auf iOS 26+ |
| Liquid Glass: GameModeCard | UI-01 | ✅ | Mit Tint auf iOS 26+ |
| `@StateObject` für Singletons → `@ObservedObject` | SW-04 | ✅ | 8 Views korrigiert |
| MPC-Events typsicher (Enum statt Strings) | SVC-14 | ✅ | `MPCEventType` Konstanten in allen Views |

---

## PHASE D — Accessibility + Lokalisierung ⬜

> **Skill für diese Phase:** `swiftui-wcag-accessibility-auditor` aktivieren.
> Er liefert WCAG-genaue Findings mit patch-ready Code-Snippets für jeden Screen.

| Task | Datei | Finding | Status |
|------|-------|---------|--------|
| `accessibilityLabel` für alle interaktiven Buttons | App-weit | AC-01 | ⬜ |
| Dekorative Bilder → `accessibilityHidden(true)` | App-weit | AC-02 | ⬜ |
| Lottie-Views → `accessibilityLabel` + Reduce-Motion-Fallback | Lottie-Views | AC-12 | ⬜ |
| Komplexe Gesten → `accessibilityHint` | App-weit | AC-03 | ⬜ |
| Fokus-Kontrolle nach Sheet-Dismiss | App-weit | AC-07 | ⬜ |
| Fehlende DE-Keys übersetzen | `de.lproj/Localizable.strings` | LOC-01 | ⬜ |
| 50 häufigste hardcodierte Strings lokalisieren | `Games/` | LOC-02 | ⬜ |
| `NSLocalNetworkUsageDescription` lokalisieren | `InfoPlist.strings` | LOC-08 | ⬜ |
| `Localizable.stringsdict` für Plural-Formen anlegen | — | LOC-05 | ⬜ |

---

## PHASE E — Technische Schulden ⚠️ (teilweise)

*(Kein Launch-Blocker — nach V1.1 oder bei Gelegenheit)*

| Task | Finding | Status |
|------|---------|--------|
| `GameManager` (TimesUp) aufteilen | TU-12 | ⏭ V1.2 — zu riskant vor Launch |
| `TimesUpGameView` aufteilen (1600+ Zeilen) | TU-15 | ⏭ V1.2 — zu riskant vor Launch |
| Legacy `onEventReceived` Callback entfernen | SVC-12 | ⏭ V1.2 — braucht Architektur-Migration |
| Kategorie-Dictionary in Imposter cachen | P-02 | ⏭ Phase E |
| GlobalStatsManager in alle Games einbinden | DA-01 | ⏭ Phase E |
| Duplikat-HapticsManager entfernen | D-01, D-05 | ⏭ Phase E |

---

## GEPLANTE FEATURES (noch nicht gestartet)

### ProMotion / Sheet-Performance (PERFORMANCE_PROMOTION.md)
- `DispatchQueue.main.asyncAfter` in ContentView → `Task { @MainActor }` (6 Spielkarten-Buttons)
- `FFBackground` Duplizierung entfernen
- `preferredFrameRateRange` für Animationen setzen
- **Schätzung:** ~1.5h, kein Regressionsrisiko

### Falsche Fährte Multiplayer (FF_MULTIPLAYER_PLAN.md)
- MPC-basierter Multiplayer: Jeder auf eigenem Gerät tippt Lügen + votet
- Neue MPC-Events: `FF_GAME_CONFIG`, `FF_QUESTION`, `FF_BLUFFS_READY`, `FF_REVEAL`, etc.
- `FFMultiplayerSheet`, `FFMultiplayerHandler`, `FFMultiplayerModels`
- **Schätzung:** ~5–7 Tage

### Bet Buddy Spielernamen + PlayerDraw ✅ (implementiert)
- `PlayerDrawView.swift` existiert bereits im Code
- Rotation der aktiven Spieler nach jeder Runde

---

## OFFENE MANUELLE SCHRITTE

| Schritt | Warum | Erledigt? |
|---------|-------|-----------|
| `PrivacyInfo.xcprivacy` in Xcode-Target einbinden | Muss in Xcode Project Navigator gezogen werden | ⬜ |
| Privacy Policy Dokument + URL (elfiandken@icloud.com) | App Store Connect erfordert URL | ⬜ |
| App-Store-Texte (Titel, Beschreibung, Keywords DE + EN) | App Store Connect | ⬜ |
| Screenshots erstellen (iPhone 6.9" + 6.3" Minimum) | App Store Connect | ⬜ |
| Version/Build-Nummer in Xcode prüfen | Build Settings | ⬜ |

---

## STATISTIK

| | Anzahl |
|-|--------|
| Swift-Dateien im Projekt | 202+ |
| Findings gesamt (Audit 2026-04-12) | 248 |
| Findings behoben (Phase A–C + E-Teile) | ~60 |
| Findings noch offen (geschätzt) | ~188 |
| Kritische Findings gesamt | 39 |
| Kritische Findings behoben | ~18 |
| Commits (Audit-Arbeit) | 2 (c7b6249, d423016) |
| Commits (neue Spiele) | 2 (a6248bb, 584e4de) |

---

## REFERENZ-DATEIEN

| Datei | Inhalt |
|-------|--------|
| `MASTER_AUDIT_REPORT.md` | Alle 248 Findings im Überblick — Ausgangslage |
| `IMPROVEMENT_ROADMAP.md` | Sprint-Plan 0–8 mit Aufwand-Schätzungen + aktuellem Status |
| `AUDIT_ACCESSIBILITY.md` | Details für Phase D (Accessibility) |
| `AUDIT_LOCALIZATION.md` | Details für Phase D (Lokalisierung) |
| `PREMIUM_DESIGN_AUDIT.md` | Premium Design Review — Haupt-/Menü-Screen, Imposter, Bet Buddy, etc. |
| `PRODUCT_OPPORTUNITIES.md` | Zukunfts-Features: Onboarding, Meta-Session, Achievements, Shareable Recaps |
| `FF_MULTIPLAYER_PLAN.md` | Technischer Plan für Falsche Fährte Multiplayer |
| `PERFORMANCE_PROMOTION.md` | ProMotion-Performance Fix für alle 6 Spielkarten-Buttons |
| `BET_BUDDY_EXPLANATION.md` | Spielregeln Bet Buddy — Referenz für neue Sessions |
| `AUDIT_PROGRESS.md` | Übersicht über alle 19 Audit-Dateien und ihre Entstehung |

---

*Zuletzt aktualisiert: 2026-04-14 — Phase A, B, C, E(teil) fertig · Phase D als nächstes*
