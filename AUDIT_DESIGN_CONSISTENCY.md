# AUDIT: Design-Konsistenz & Animationen — Phase 3.3
## Erstellungsdatum: 2026-04-12

> Geprüft: Animations-Stile und -Konsistenz über alle Games, Empty States,
> Loading States, Transitions, Feedback-Patterns, visuelle Sprache.

---

## KATEGORIE 1: ANIMATIONS-KONSISTENZ

---

### DC-01: Kein einheitlicher Animations-Standard — jedes Game hat eigene Stile 🟠

**Problem:**
Über die 4 Games werden völlig unterschiedliche Animation-Werte und Stile verwendet.
Ein Nutzer der von Bet Buddy zu Imposter wechselt, spürt sofort die unterschiedliche
"Persönlichkeit" der Animationen — das macht die App uneinheitlich.

| Game | Animations-Stil | Charakteristik |
|------|----------------|----------------|
| Imposter | `.spring(response: 0.3-0.6, dampingFraction: 0.5-0.8)` | Fedrig, mittelschwer |
| Bet Buddy | `.spring(response: 0.4-0.6, dampingFraction: 0.7-0.8)` + Lottie Money Rain | Casino-Dramatik |
| Question | `DispatchQueue.asyncAfter` Stagger + `.spring()` | Theatrical, phasenbasiert |
| TimesUp | `.easeInOut(duration: 0.1-1.2)` + `.easeIn` | Linear/Ease dominiert |

TimesUp nutzt hauptsächlich `easeInOut` während alle anderen Games `spring()` bevorzugen.
Das macht TimesUp "steifer" und weniger spielerisch als die anderen Games.

**Fix:** Einen App-weiten `AnimationTokens`-Namespace definieren:
```swift
// Games Collection/Shared/Design/AnimationTokens.swift
enum AppAnimation {
    static let standard = Animation.spring(response: 0.35, dampingFraction: 0.8)
    static let bouncy = Animation.spring(response: 0.4, dampingFraction: 0.6)
    static let quick = Animation.easeInOut(duration: 0.2)
    static let slow = Animation.easeInOut(duration: 0.5)
    static func stagger(_ index: Int, base: Double = 0.1) -> Animation {
        standard.delay(Double(index) * base)
    }
}
```

---

### DC-02: `withAnimation(.spring())` ohne Parameter — deprecated-adjacent 🟠

**Datei:** `Games/TimesUp/Views/AICategoryGeneratorView.swift:248`

**Problem:**
```swift
withAnimation(.spring()) {  // Alte API, kein response/damping gesetzt
    ...
}
```

`.spring()` ohne Parameter nutzt System-Defaults die sich zwischen iOS Versionen ändern können.
Explizite Spring-Parameter sind stabiler und vorhersehbarer.

**Fix:**
```swift
withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
    ...
}
```

---

### DC-03: Animationen ohne `value:` Parameter (deprecated Syntax) 🟡

**Problem:**
Mehrere Views nutzen `.animation()` Modifier ohne den erforderlichen `value:` Parameter.
Seit iOS 15 ist `.animation()` ohne `value:` deprecated — es animiert ungezielt alle
State-Änderungen in der View.

Gefunden in: diverse Views (detaillierte Liste in `AUDIT_UI_UX.md` → UI-26)

**Fix:**
```swift
// DEPRECATED:
.animation(.spring())

// KORREKT:
.animation(.spring(response: 0.35, dampingFraction: 0.8), value: isExpanded)
```

---

### DC-04: DispatchQueue-Stagger in QuestionsResultsPhaseView — nicht cancellable 🟡

**Datei:** `Games/Question/Views/Phases/QuestionsResultsPhaseView.swift:102-155`

**Problem:**
Die `runSequence()` Funktion kaskadiert 6 `DispatchQueue.main.asyncAfter` Calls
mit Delays von 1.5s bis 4.5s. Das hat mehrere Probleme:

1. Wenn der User die View vor 4.5s verlässt (z.B. durch Dismissal), laufen die
   gecancelten Closures trotzdem und verändern State in einer nicht mehr sichtbaren View
2. Keine Berücksichtigung von "Reduce Motion"
3. Schwer testbar und wartbar

```swift
// runSequence() — 6 asyncAfter Calls, keine Cancellation:
DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { ... }
DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { ... }
DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { ... }
DispatchQueue.main.asyncAfter(deadline: .now() + 3.05) { ... }  // Haptic
DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) { ... }
```

**Fix:** Task-basiert mit Cancellation:
```swift
@State private var animationTask: Task<Void, Never>?

private func runSequence() {
    animationTask = Task { @MainActor in
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        guard !Task.isCancelled else { return }
        withAnimation(AppAnimation.bouncy) {
            revealStage = 1
            documentOffset = 0
            documentOpacity = 1
        }
        // ... weitere Schritte
    }
}

// Aufräumen:
.onDisappear { animationTask?.cancel() }
```

---

## KATEGORIE 2: EMPTY STATES

---

### DC-05: Empty States inkonsistent — nur Imposter Leaderboard hat dedizierte EmptyStateView 🟠

**Problem:**
Nur `LeaderboardView.swift` in Imposter hat eine dedizierte `EmptyStateView` Komponente
mit Icon + Text + hilfreicher Erklärung. Alle anderen Empty States sind primitive
Inline-Texte:

| View | Empty State | Qualität |
|------|------------|----------|
| `LeaderboardView` (Imposter) | `EmptyStateView()` mit Icon + Text | ✅ Gut |
| `CategoryDetailView` (TimesUp) | `Text("Keine Wörter vorhanden.")` | ⚠️ Minimal |
| `QuestionsPlayerManagementSheet` | `Text("Keine Spieler hinzugefuegt.")` | ⚠️ Minimal + Typo |
| `GamePlayView` (Imposter) | `Text("Keine Karte verfügbar")` | ⚠️ Minimal |
| Bet Buddy Leaderboard | Unklar — nicht geprüft | ❓ |

**Zusätzlich:** "hinzugefuegt" ist ein Rechtschreibfehler (muss "hinzugefügt" heißen).

**Fix:** Die Imposter `EmptyStateView` in Shared verschieben und überall verwenden:
```swift
// Games Collection/Shared/Components/EmptyStateView.swift
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text(title).font(.headline)
            Text(message).font(.subheadline).foregroundStyle(.secondary)
        }
        .multilineTextAlignment(.center)
        .padding(32)
    }
}
```

---

### DC-06: Kein Loading State für AI-generierte Inhalte in Imposter 🟡

**Datei:** `Games/Imposter/Services/AIService.swift`,
`Games/Imposter/Views/Components/HintOverlay.swift`

**Problem:**
Wenn Imposter AI-Hinweise lädt, gibt es keinen klaren Loading-Indikator.
Der Nutzer weiß nicht ob der Hint lädt oder ob ein Fehler aufgetreten ist.

**Fix:**
```swift
if hintService.isLoading {
    ProgressView()
        .scaleEffect(1.5)
} else if let hint = hintService.currentHint {
    Text(hint)
} else {
    Text("Hinweis konnte nicht geladen werden")
        .foregroundStyle(.secondary)
}
```

---

## KATEGORIE 3: TRANSITIONS & PHASEN-WECHSEL

---

### DC-07: Phasen-Wechsel in TimesUp ohne Transition-Animation 🟠

**Datei:** `Games/TimesUp/Views/TimesUpGameView.swift:10-32`

**Problem:**
Die `switch gameManager.gameState.phase` Struktur wechselt zwischen Phasen-Views
ohne jegliche Transition-Animation:

```swift
// Kein .transition() Modifier, kein withAnimation beim Phasenwechsel:
switch gameManager.gameState.phase {
case .setup:    SetupPhaseView(...)
case .playing:  PlayingPhaseView(...)
case .roundEnd: RoundEndView(...)
case .gameEnd:  GameEndView(...)
}
```

Der Übergang von "Spielen" zu "Rundenende" ist abrupt — ein visuelles Feedback
(z.B. `.transition(.opacity)` oder `.transition(.scale)`) würde das Spiel flüssiger machen.

**Fix:**
```swift
Group {
    switch gameManager.gameState.phase {
    case .setup:   SetupPhaseView(gameManager: gameManager)
    case .playing: PlayingPhaseView(gameManager: gameManager)
    case .roundEnd: RoundEndView(gameManager: gameManager)
    case .gameEnd: GameEndView(gameManager: gameManager)
    }
}
.animation(.easeInOut(duration: 0.3), value: gameManager.gameState.phase)
.transition(.opacity)
```

---

### DC-08: TimesUp NavigationStack inline — visuell inkonsistent mit anderen Games 🟡

**Datei:** `Games/TimesUp/Views/TimesUpGameView.swift`

**Problem:**
TimesUp rendert sein Game direkt in einem NavigationStack mit Standard-Toolbar.
Das führt zu einem Standard iOS-Navbaraussehen (weißer Hintergrund, Standard-Buttons)
inmitten eines Dark-Mode-Games.

```swift
// TimesUpGameView:
NavigationStack {
    VStack { /* ... */ }
    .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
            Button("Beenden") { showingEndGame = true }
        }
    }
}
.toolbar(.hidden, for: .navigationBar)   // Dann doch versteckt?!
```

Zeile 70 versteckt die Toolbar wieder mit `.toolbar(.hidden)` — warum wird
dann überhaupt `.toolbar { }` definiert? Das ist inkonsistenter Code.

---

### DC-09: Result-Screens über 4 Games vollständig verschieden — kein Pattern 🟡

**Problem:**
Jedes Game hat seinen eigenen Result-Screen ohne gemeinsame Basis:

| Game | Result-Screen | Features |
|------|--------------|----------|
| Imposter | `VotingResultsView` — Abstimmung + Ergebnis | Lottie, Konfetti |
| Bet Buddy | `ResultView` — Leaderboard + Outcome | Lottie Money Rain, Scores |
| Question | `QuestionsResultsPhaseView` — Dossier + Stempel | Dramatic reveal |
| TimesUp | `GameEndView` — Teams + Gewinner | Einfach |

Das ist zum Teil gewollt (verschiedene Games sollen unterschiedlich aussehen).
Das Problem ist dass `GameEndView` in TimesUp deutlich weniger poliert ist als
die anderen Games. Kein Konfetti, kein Lottie, keine besondere Reveal-Animation.

---

## KATEGORIE 4: FEEDBACK-PATTERNS

---

### DC-10: Haptic Feedback inkonsistent — 3 verschiedene Manager, kein globales Setting 🟠

*(Bereits als D-05 in AUDIT_DUPLICATES.md dokumentiert)*

**Ergänzung — Animationsperspektive:**
Haptic Feedback ist Teil des "Game Feel" — es sollte mit Animationen synchronisiert sein.
In QuestionsResultsPhaseView ist der Stempel-Haptic korrekt synchronisiert (Zeile 143).
In TimesUp wird Haptic beim Start-Button korrekt ausgelöst.
In Bet Buddy fehlt Haptic bei wichtigen Momenten (z.B. Voting-Abschluss).

---

### DC-11: Lottie-Animationen nur in Bet Buddy und Question verfügbar 🟡

**Problem:**
`MoneyRainLottieView` und `ParticleEffectView` in Bet Buddy ResultView zeigen
dass das Team in Feiern investiert hat. TimesUp GameEndView hat keine
vergleichbare Celebration-Animation.

Imposter hat Lottie für Karten-Rückseitenanimation (Fingerprint) — gut.
Question hat Lottie für Hintergrundeffekte — gut.
TimesUp: Keine Celebration bei Spielende — Versäumnis.

---

## ZUSAMMENFASSUNG PHASE 3.3 (Design-Konsistenz & Animationen)

| Priorität | Anzahl | Top-Issues |
|-----------|--------|------------|
| 🟠 Hoch | 5 | Kein Animations-Standard (DC-01), Empty States inkonsistent (DC-05), deprecated spring() (DC-02), TimesUp Phasen ohne Transition (DC-07), Haptics inkonsistent (DC-10) |
| 🟡 Mittel | 6 | asyncAfter ohne Cancellation (DC-04), Loading State AI (DC-06), TimesUp Toolbar-Duplikat (DC-08), Result-Screens Qualitätslücke (DC-09), Lottie fehlt in TimesUp (DC-11) |

---

*Erstellt: 2026-04-12 — Teil von Phase 3 des Gesamtaudits*
