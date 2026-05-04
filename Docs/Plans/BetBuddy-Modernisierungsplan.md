# Bet Buddy — Modernisierungsplan

> **Ziel:** Alle installierten Pakete sinnvoll einsetzen + Swift 6 / iOS 26 konformer Code  
> **Strategie:** Jede Phase ist eigenständig buildbar — kein Big-Bang-Refactoring  
> **Erstellt:** 2026-05-02

---

## Installierte Pakete

| Paket | Version | Status |
|---|---|---|
| Lottie | 4.6.0 | Aktuell |
| Pow | 1.0.6 | Aktuell |
| SFSafeSymbols | 7.0.0 | Aktuell |
| swift-algorithms | 1.2.1 | Aktuell |
| swift-async-algorithms | 1.1.3 | Aktuell |
| swift-collections | 1.4.1 | Aktuell |

---

## Zeitplan-Übersicht

```
Phase 1 → SFSafeSymbols         [~2h]  rein mechanisch, sicher
Phase 2 → @Observable            [~3h]  Swift 6 Kern
Phase 3 → Concurrency            [~2h]  Timer/Dispatch bereinigen
Phase 4 → Pow                    [~2h]  sichtbarer UX-Gewinn
Phase 5 → Lottie                 [~2h]  Struktur + Coin Flip
Phase 6 → swift-collections      [~1h]  gezielt
Phase 7 → swift-algorithms       [~1h]  punktuell
Phase 8 → iOS 26 Extras          [~2h]  plattform-spezifisch
─────────────────────────────────────────
Gesamt                           ~15–18h
```

Jede Phase einzeln committen und testen.

---

## Phase 1 — SFSafeSymbols: Typsichere SF Symbols

**Ziel:** Alle String-basierten `systemName`-Aufrufe ersetzen  
**Risiko:** Sehr gering — rein mechanischer Find & Replace  
**Paket:** `SFSafeSymbols 7.0.0`

### Betroffene Dateien

| Datei | Typ |
|---|---|
| `Models/CategoryType.swift` | `systemImage:` Strings in Enum |
| `Screens/HomeView.swift` | Icons in Navigation/Buttons |
| `Screens/GameView.swift` | Toolbar- und Button-Icons |
| `Screens/ResultView.swift` | Score/Award-Icons |
| `Screens/BetBuddyLeaderboardView.swift` | Rang-Icons |
| `Screens/BetBuddyVotingView.swift` | Vote-Icons |
| `Screens/GroupSelectionView.swift` | Gruppen-Icons |
| `Components/SettingsRow.swift` | Settings-Chevrons |
| `Components/HintChipsView.swift` | Checkmark-Icons |
| `Components/GroupCountRow.swift` | Zähler-Icons |
| `BetBuddyInfoSheet.swift` | Tutorial-Icons |

### Aufgaben

- [ ] `import SFSafeSymbols` zu allen betroffenen Dateien hinzufügen
- [ ] `Image(systemName: "...")` → `Image(.symbolName)` ersetzen
- [ ] `Label("Text", systemImage: "...")` → `Label("Text", systemSymbol: .symbolName)` ersetzen
- [ ] Alle `systemImage:` in `CategoryType.swift` Enum-Definitionen ersetzen
- [ ] Build + kurze Sichtprüfung aller Icons

---

## Phase 2 — @Observable: Swift 6 Observation-Migration

**Ziel:** `ObservableObject` + `@Published` durch `@Observable` ersetzen  
**Risiko:** Mittel — betrifft View-Binding-Syntax überall  
**Framework:** Swift 5.9+ / iOS 17+ Standard (kein externes Paket)

### Betroffene Dateien

| Datei | Änderung |
|---|---|
| `ViewModels/AppViewModel.swift` | `@MainActor @Observable class` statt `ObservableObject` |
| `Services/GameTimer.swift` | `@Observable` statt `ObservableObject` |
| `BetBuddyWrapper.swift` | `@State` statt `@StateObject` |
| `Screens/GameView.swift` | `@Environment` / `@Bindable` statt `@ObservedObject` |
| Alle anderen Views die `AppViewModel` nutzen | Binding-Syntax anpassen |

### Aufgaben

- [ ] `AppViewModel`: `ObservableObject` → `@Observable`, alle `@Published` entfernen
- [ ] `GameTimer`: gleiche Migration
- [ ] `BetBuddyWrapper`: `@StateObject` → `@State`
- [ ] Alle Views: `@ObservedObject`/`@EnvironmentObject` → `@Environment`/`@Bindable`
- [ ] Swift 6 Sendable-Conformances für Datenmodelle prüfen (`GroupInfo`, `Challenge`, `GameResult`)
- [ ] Build + alle Screens einmal durchklicken

---

## Phase 3 — Concurrency-Modernisierung

**Ziel:** Alten Timer- und DispatchQueue-Code durch Swift Concurrency ersetzen  
**Risiko:** Mittel — Timer-Logik ist gameplay-kritisch, sorgfältig testen  
**Framework:** Swift Concurrency (nativ) + `swift-async-algorithms` nur wo sinnvoll

### 3a — DispatchQueue entfernen

- [ ] `ChallengeStartView.swift`: mind. 3× `DispatchQueue.main.asyncAfter` → `Task { try? await Task.sleep(for: .seconds(...)) }`
- [ ] Alle weiteren `DispatchQueue.main.asyncAfter`-Vorkommen im Bet-Buddy-Ordner ersetzen

### 3b — GameTimer modernisieren

- [ ] `GameTimer.swift`: `Timer.scheduledTimer` durch task-basierten Loop ersetzen
- [ ] `AppViewModel.swift`: verbleibende `Timer`-Nutzung prüfen + ersetzen

### 3c — NotificationCenter → scenePhase

- [ ] `GameView.swift`: `NotificationCenter`-Observer für Foreground/Background → `scenePhase`-Environment
- [ ] `BetBuddyVotingView.swift`: gleiche Migration
- [ ] `AppViewModel.swift`: Lifecycle-Notifications auf `scenePhase` oder `task`-Modifier umstellen

---

## Phase 4 — Pow: UX-Animations-Polish

**Ziel:** Handgemachte Partikel- und Burst-Animationen durch Pow ersetzen  
**Risiko:** Gering — rein additiv, kein Gameplay betroffen  
**Paket:** `Pow 1.0.6`

### Betroffene Stellen

| Datei | Alt | Neu mit Pow |
|---|---|---|
| `ResultView.swift` | `ParticleEffectView` + `Particle`-Struct (~100 Zeilen) | `.changeEffect(.spray(...))` oder `.confetti` |
| `ResultView.swift` | Jackpot-Puls-Animation | `.changeEffect(.glow(...))` |
| `HoldToConfirmButton.swift` | Manueller Pulse nach Abschluss | `.changeEffect(.spray(...))` on completion |
| `BetBuddyVotingView.swift` | Kein visuelles Vote-Feedback | `.changeEffect(...)` bei Vote-Abgabe |
| `Screens/GroupSelectionView.swift` | `.transition(.opacity.combined(...))` | Pow-Transition evaluieren |

### Aufgaben

- [ ] `import Pow` zu betroffenen Dateien
- [ ] `ResultView`: `ParticleEffectView` + `Particle`-Struct entfernen, durch Pow-Effekt ersetzen
- [ ] `ResultView`: Jackpot-/Bust-Moment mit Pow-Effekt versehen
- [ ] `HoldToConfirmButton`: Abschluss-Effekt mit Pow
- [ ] `BetBuddyVotingView`: Vote-Feedback mit Pow
- [ ] Vor/Nachher visuell vergleichen, nichts visuell verschlechtern

---

## Phase 5 — Lottie: Strukturbereinigung + 3D Coin Flip

**Ziel:** Lottie-Wrapper zentralisieren + `3D coin flip.lottie` einbauen  
**Risiko:** Gering  
**Paket:** `Lottie 4.6.0`

### Problem-Ist-Zustand

Der `LottieView`-Wrapper liegt im **Imposter**-Bereich, nicht in einem gemeinsamen `Shared`-Ordner. Bet Buddy nutzt ihn aber bereits — das ist eine versteckte Abhängigkeit.

### 5a — Wrapper zentralisieren

- [ ] Gemeinsamen `Shared/Components/LottieView.swift` erstellen
- [ ] Imposter-seitigen Wrapper darauf umleiten (Import-Pfad anpassen)
- [ ] Bet-Buddy-seitige Nutzung auf neuen Wrapper umstellen
- [ ] Build prüfen — beide Spiele müssen noch funktionieren

### 5b — 3D Coin Flip einbauen

- [ ] `PlayerDrawView.swift`: Aktuellen Task-basierten Spin-Counter analysieren
- [ ] `LottieView` mit `3D coin flip.lottie` in `PlayerDrawView` einbauen
- [ ] Lottie-Animation mit dem Reveal-Moment synchronisieren (Completion-Callback)
- [ ] Spieltest: Animation fühlt sich richtig an?

### 5c — Money Rain prüfen

- [ ] Intensitätskurve in `ResultView` prüfen — ist `0.7 + (intensity * 0.5)` sinnvoll skaliert?
- [ ] Lottie 4.6.0 API: neuere Swift-Concurrency-freundliche APIs prüfen

---

## Phase 6 — swift-collections: Gezielte Datenstruktur-Verbesserungen

**Ziel:** Nur dort einsetzen, wo es ein echtes Problem löst  
**Risiko:** Gering  
**Paket:** `swift-collections 1.4.1`

### Konkrete Einsatzstellen

| Datei | Aktuell | Besser | Grund |
|---|---|---|---|
| `AppViewModel.swift` | `Set<CategoryType>` | `OrderedSet<CategoryType>` | UI-Reihenfolge stabil halten |
| `AppViewModel.swift` | `[VoteEntry]` voteHistory | `Deque<VoteEntry>` | Effizientes prepend |
| `AppViewModel.swift` | `[UUID: Int]` scores | `OrderedDictionary<UUID, Int>` | Leaderboard-Reihenfolge ohne extra sort |

### Aufgaben

- [ ] `import Collections` in `AppViewModel.swift`
- [ ] `selectedCategories` auf `OrderedSet<CategoryType>` umstellen
- [ ] `voteHistory` auf `Deque<VoteEntry>` umstellen — API-Calls prüfen (`append` bleibt gleich, `prepend` neu)
- [ ] `scores`-Dictionary evaluieren: lohnt `OrderedDictionary` oder reicht sort-on-read?
- [ ] Build + Leaderboard-Reihenfolge manuell prüfen

---

## Phase 7 — swift-algorithms: Punktuelle Code-Vereinfachungen

**Ziel:** Lesbarkeit verbessern, kein Over-Engineering  
**Risiko:** Sehr gering  
**Paket:** `swift-algorithms 1.2.1`

### Konkrete Einsatzstellen

| Datei | Aktuell | Mit Algorithmen |
|---|---|---|
| `Services/ChallengeService.swift` | `shuffle()` + `prefix()` | `.randomSample(count:)` |
| `AppViewModel.swift` | Manuelle Duplikat-Checks | `.uniqued()` |
| `Services/ChallengeService.swift` | Kategorien-Filterung | `.chunked(on:)` evaluieren |

### Aufgaben

- [ ] `import Algorithms` wo nötig
- [ ] `ChallengeService`: Shuffle+Prefix durch `randomSample` ersetzen
- [ ] `AppViewModel`: Duplikat-Logik mit `.uniqued()` vereinfachen wo vorhanden
- [ ] Keine erzwungenen Anwendungen — nur dort wo es kürzer und klarer ist

> **Hinweis:** `swift-async-algorithms` hat in Bet Buddy niedrigen ROI. Nur einsetzen wenn sich ein konkreter Anwendungsfall zeigt — nicht künstlich einbauen.

---

## Phase 8 — iOS 26 / SwiftUI-Modernisierung

**Ziel:** Plattform-spezifische neue APIs nutzen  
**Risiko:** Mittel — neue APIs sorgfältig testen

### Aufgaben

- [ ] **`sensoryFeedback`**: `HapticsService.swift` evaluieren — `sensoryFeedback`-Modifier direkt in Views statt zentralem UIKit-Service
- [ ] **`onTapGesture` → `Button`**: `GameView.swift` und andere Views auf echte `Button`-Strukturen prüfen (Accessibility)
- [ ] **Liquid Glass Material**: `BetBuddyTheme.swift` — `CasinoCardBackground` und Sheet-Overlays auf neue Material-API prüfen
- [ ] **Force Unwrap entfernen**: `ResultView.swift` ~Zeile 576 `.randomElement()!` durch `guard let` oder `?? defaultValue` ersetzen
- [ ] **Typsichere UserDefaults-Keys**: Keys-Enum in `GroupNamePersistence.swift` einführen statt Hardcoded Strings

---

## Entscheidungslog

| Entscheidung | Begründung |
|---|---|
| SFSafeSymbols vor Pow | Typsicherheit > UX-Polish als erstes angehen |
| @Observable vor Pow | Swift 6 Kern zuerst, dann aufbauen |
| swift-async-algorithms: niedrige Prio | In Bet Buddy kein starker Anwendungsfall, scenePhase wichtiger |
| Lottie erst in Phase 5 | Strukturproblem (falscher Wrapper-Ort) zuerst lösen |
| swift-algorithms nur punktuell | Standard-Swift reicht für die meisten Fälle aus |
