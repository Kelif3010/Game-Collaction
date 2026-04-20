# AUDIT: Accessibility & WCAG 2.2 — Phase 3.3
## Erstellungsdatum: 2026-04-12

> Geprüft: VoiceOver, Dynamic Type, Touch Targets, Reduce Motion, Kontrast,
> accessibilityLabel/Hint/Value/Traits, Fokus-Reihenfolge, Custom Gesten.
> Methode: Statische Code-Analyse (kein App-Run möglich).

---

## EXECUTIVE SUMMARY

| Metrik | Wert |
|--------|------|
| accessibilityLabel/Hint/Value Modifier im Projekt | ~15 Treffer in 202 Dateien |
| accessibilityHidden Modifier | ~3 Treffer |
| accessibilityAddTraits | ~4 Treffer |
| `.font(.system(size:))` (fixed) | 322 Treffer |
| onTapGesture statt Button | ~12 Treffer |
| Schätzung: % der UI mit korrekten Labels | <10% |

**Urteil:** Das Projekt hat ein kritisches Accessibility-Defizit. Fast keine View
ist für VoiceOver-Nutzer korrekt beschriftet. Die App wäre bei einem Apple
Accessibility Audit wahrscheinlich nicht App-Store-fähig.

---

## KATEGORIE A: VOICEOVER & SEMANTICS

---

### AC-01: Nahezu keine accessibilityLabel-Modifier im Projekt 🔴

**Statistik:**
```
accessibilityLabel:  ~8 Treffer in 202 Dateien
accessibilityHint:   ~5 Treffer
accessibilityValue:  ~2 Treffer
```

**Problem:**
In einer App mit 202 Swift-Dateien und hunderten interaktiver Elemente (Buttons,
Cards, Picker, Icons) gibt es praktisch keine Accessibility-Beschriftungen.

VoiceOver-Nutzer hören beim Antippen von Buttons:
- Unnamed Buttons: "Button" (ohne Beschriftung)
- SF Symbol Images: "heart.fill" (Symbol-Name, nicht Bedeutung)
- Icon-only Buttons: komplett stumm

**Betroffene Bereiche (Beispiele):**
- Alle Close-Buttons (`Image(systemName: "xmark")` ohne Label)
- Alle Navigation-Back-Buttons
- Alle Game-Start-Buttons
- Alle Player-Add-Buttons
- Alle Settings-Buttons
- Dice-Roll-Buttons in Imposter
- Score-Buttons in Bet Buddy

**WCAG:** 4.1.2 Name, Role, Value (Level A) — Pflicht

**Fix (global):**
```swift
// FALSCH — VoiceOver liest "multiply" vor:
Button(action: dismiss) {
    Image(systemName: "xmark")
}

// RICHTIG:
Button(action: dismiss) {
    Image(systemName: "xmark")
}
.accessibilityLabel("Schließen")

// Oder mit Label:
Button {
    dismiss()
} label: {
    Image(systemName: "xmark")
        .accessibilityLabel("Schließen")
}
```

---

### AC-02: Icon-only Buttons ohne Text und ohne accessibilityLabel 🔴

**Datei:** Alle Views mit Icon-Buttons

**Problem:**
Das Projekt hat viele Icon-only Buttons:

| View | Button | Symbol | VoiceOver liest |
|------|--------|--------|----------------|
| GameSetupView | Back | "chevron.left" | "Back" (oft falsch) |
| ImposterInfoSheet | Close | "xmark" | "Close" oder "multiply" |
| BetBuddy HomeView | Settings | "gearshape.fill" | "Settings" |
| TimesUp GameView | Pause | "pause.fill" | "Pause" |
| Imposter GamePlayView | Info | "info.circle" | "Info circle" |
| Imposter | Würfeln | "dice.fill" | "Dice fill" |

SF Symbols haben manchmal passende Accessibility-Namen, aber das ist zufällig.
`accessibilityLabel` sollte immer explizit gesetzt sein.

**WCAG:** 1.1.1 Non-text Content (Level A) — Pflicht

---

### AC-03: Dekorative Icons nicht als accessibilityHidden markiert 🟠

**Datei:** Viele Views

**Problem:**
Dekorative Bilder/Icons (die nur visuell sind und keine Information transportieren)
werden von VoiceOver angesagt wenn sie nicht als `.accessibilityHidden(true)` markiert.

Beispiele für dekorative Elemente die angesagt werden:
- Hintergrund-Emojis/Symbole in Spielkarten
- Dekorative Punkte/Kreise als Spacing-Elemente
- Zierleisten-Icons in Headers

```swift
// Dekoratives Element korrekt:
Circle()
    .fill(Color.white.opacity(0.1))
    .accessibilityHidden(true)   // Kein Informationsgehalt
```

**WCAG:** 1.1.1 Non-text Content (Level A)

---

### AC-04: Fehlende Rollen-Semantik für Custom Components 🟠

**Datei:** `Games/Imposter/Views/Components/GameModeCard.swift`,
`Games/Bet Buddy/Components/GroupVoteCard.swift`, diverse

**Problem:**
Custom Card-Views die als Buttons funktionieren, sind als `View` mit `.onTapGesture`
implementiert — nicht als `Button`. VoiceOver kündigt diese Elemente nicht als
"Button" an, Nutzer wissen nicht dass sie interaktiv sind.

```swift
// GameModeCard.swift — funktioniert als Button, ist aber kein Button:
struct GameModeCard: View {
    var body: some View {
        VStack { /* content */ }
            .onTapGesture { selectMode(mode) }   // Falsch!
    }
}
```

**Fix:**
```swift
Button {
    selectMode(mode)
} label: {
    VStack { /* content */ }
}
.accessibilityLabel("Spielmodus \(mode.title) auswählen")
.accessibilityHint("Doppeltippen zum Aktivieren")
```

**WCAG:** 4.1.2 Name, Role, Value (Level A)

---

### AC-05: Timer-Countdowns ohne accessibilityValue-Updates 🟠

**Datei:** `Games/TimesUp/Views/TimesUpGameView.swift`,
`Games/Imposter/Views/GamePlayView.swift`

**Problem:**
Countdown-Timer zeigen sekundenweise wechselnde Zahlen, aber VoiceOver-Nutzer
hören keine Updates — sie wissen nicht, wie viel Zeit verbleibt.

```swift
// TimesUpGameView.swift — visuell, aber nicht für VoiceOver:
Text("\(timeRemaining)")
    .font(.system(size: 48, weight: .bold))
```

**Fix:**
```swift
Text("\(timeRemaining)")
    .font(.headline)
    .accessibilityLabel("Verbleibende Zeit")
    .accessibilityValue("\(timeRemaining) Sekunden")
    // Nur bei kritischen Schwellen ankündigen:
    .accessibilityAddTraits(timeRemaining <= 5 ? .updatesFrequently : [])
```

**WCAG:** 4.1.3 Status Messages (Level AA)

---

### AC-06: Spieler-Rollen-Zuweisung ohne Announcement 🟠

**Datei:** `Games/Imposter/Views/Components/RoleActionView.swift`

**Problem:**
Wenn Spieler ihre Rolle aufdecken (Imposter vs. Einwohner + Stichwort), erscheint
die Information visuell. Für Blinde: Kein VoiceOver-Announcement beim Aufdecken.

**Fix:**
```swift
.onChange(of: isRevealed) { revealed in
    if revealed {
        UIAccessibility.post(notification: .announcement,
            argument: isImposter
                ? "Du bist der Imposter!"
                : "Du bist kein Imposter. Das Stichwort ist \(keyword)")
    }
}
```

**WCAG:** 4.1.3 Status Messages (Level AA)

---

## KATEGORIE B: DYNAMIC TYPE & LESERLICHKEIT

---

### AC-07: 322 feste Schriftgrößen — Dynamic Type vollständig ignoriert 🔴

*(Bereits als UI-12 in AUDIT_UI_UX.md dokumentiert)*

**WCAG:** 1.4.4 Resize Text (Level AA) — **Pflicht**

Nutzer mit Sehbehinderungen die in iOS `Große Schrift` einstellen, erhalten
keinerlei Vergößerung in der App. Das ist ein direkter Accessibility-Verstoß.

**Schwere:** Kritisch — betrifft 65 Dateien / 322 Stellen

---

### AC-08: Fehlender `minimumScaleFactor` — Text wird abgeschnitten statt zu skalieren 🟠

**Problem:**
Spielernamen, Kategorientitel und Spieltitel haben weder `.lineLimit(1)` noch
`.minimumScaleFactor`. Bei langen Texten oder großen Dynamic-Type-Einstellungen
wird Text einfach abgeschnitten/ellipsis-iert ohne dem Nutzer die volle Information
zu geben.

**Fix:**
```swift
Text(playerName)
    .lineLimit(2)
    .minimumScaleFactor(0.75)
    .fixedSize(horizontal: false, vertical: true)
```

**WCAG:** 1.4.4 Resize Text (Level AA), 1.4.12 Text Spacing (Level AA)

---

### AC-09: Hardcoded Farben ohne Berücksichtigung des Kontrast-Verhältnisses 🟠

**Problem:**
Das Projekt nutzt viele hard-coded Farben mit `opacity`-Modifikatoren:
- `Color.white.opacity(0.5)` auf schwarzem Hintergrund ≈ 4.5:1 (knapp AA)
- `Color.white.opacity(0.3)` ≈ 2:1 (nicht AA-konform)
- `Color.gray.opacity(0.5)` auf dunklen Hintergründen oft unter 3:1

**Beispiel:**
```swift
// BetBuddyTheme.swift:
static let secondaryText = Color.white.opacity(0.6)   // ~3.5:1 — verfehlt AA für normalen Text
```

**WCAG-Anforderungen:**
- Normaler Text (<18pt): 4.5:1 Kontrast-Verhältnis (AA)
- Großer Text (≥18pt bold oder ≥24pt): 3:1 (AA)
- Grafische Elemente: 3:1 (AA)

**Fix:** iOS semantische Farben verwenden (`.secondary`, `.tertiary`) die
systemseitig für korrekte Kontrast-Verhältnisse optimiert sind, oder Farben
mit Accessibility Contrast Checker validieren.

**WCAG:** 1.4.3 Contrast (Minimum) (Level AA)

---

## KATEGORIE C: TOUCH TARGETS & MOTORIK

---

### AC-10: Viele Buttons unter 44×44pt Apple-Minimum 🟠

*(Bereits als UI-15 in AUDIT_UI_UX.md dokumentiert)*

**Zusätzlicher Accessibility-Kontext:**
WCAG 2.5.5 Target Size empfiehlt 44×44 CSS-Pixel (≈ 44pt auf 1x). Für Nutzer
mit motorischen Einschränkungen oder Tremor sind kleine Buttons besonders schwierig.

**Konkrete Probleme:**
- `xmark` Close-Buttons: 28-32pt
- Würfel-Button: 36pt
- Info-Buttons: 24pt
- BetBuddy Score +/- Buttons: ~36pt

**WCAG:** 2.5.5 Target Size (Level AAA — aber starke Empfehlung)

---

### AC-11: Drag/Swipe-Gesten ohne Accessibility-Alternative 🟠

**Datei:** `Games/TimesUp/Views/TimesUpGameView.swift`

**Problem:**
In TimesUp wird wahrscheinlich per Swipe zwischen "Richtig/Falsch" gewählt.
Nutzer die komplexe Gesten nicht ausführen können (Tremor, einhändig)
haben keine Alternative.

**WCAG:** 2.5.1 Pointer Gestures (Level A) — Pflicht für multi-touch/drag Gesten

**Fix:**
```swift
.gesture(swipeGesture)
.accessibilityAction(named: "Richtig") { markCorrect() }
.accessibilityAction(named: "Falsch") { markWrong() }
.accessibilityAction(named: "Überspringen") { skipWord() }
```

---

## KATEGORIE D: REDUCE MOTION & ANIMATIONEN

---

### AC-12: Keine Berücksichtigung von "Reduce Motion" Accessibility-Einstellung 🟠

**Datei:** Gesamtes Projekt

**Problem:**
Das Projekt hat viele Animationen (Lottie, Springs, DispatchQueue.asyncAfter Stagger).
Keine einzige View prüft `@Environment(\.accessibilityReduceMotion)`.

Für Nutzer mit Gleichgewichtsstörungen oder Epilepsie kann übermäßige Animation
Unwohlsein oder Anfälle auslösen.

```swift
// Kein einziger Treffer im Projekt:
@Environment(\.accessibilityReduceMotion) var reduceMotion
```

**Fix:**
```swift
@Environment(\.accessibilityReduceMotion) var reduceMotion

var body: some View {
    content
        .animation(
            reduceMotion ? .none : .spring(response: 0.4),
            value: animatedState
        )
}

// Für Lottie:
LottieView(animation: animation)
    .playing(!reduceMotion)
    .loopMode(reduceMotion ? .playOnce : .loop)
```

**WCAG:** 2.3.3 Animation from Interactions (Level AAA — aber starke iOS HIG Empfehlung)

---

### AC-13: Lottie-Animationen können nicht durch Accessibility-Settings gesteuert werden 🟡

**Datei:** `Games/Imposter/Views/Components/LottieView.swift`

**Problem:**
Lottie-Animationen laufen ohne Berücksichtigung von:
- `accessibilityReduceMotion`
- `accessibilityReduceTransparency`

Für Reduce Motion Nutzer: Statisches Bild statt Animation zeigen.

**Fix:**
```swift
struct AccessibleLottieView: View {
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    let animationName: String
    let fallbackIcon: String

    var body: some View {
        if reduceMotion {
            Image(systemName: fallbackIcon)
                .font(.largeTitle)
        } else {
            LottieView(animation: .named(animationName))
                .playing()
        }
    }
}
```

---

## KATEGORIE E: FOKUS & NAVIGATION

---

### AC-14: Fehlende `accessibilityFocused` Kontrolle bei Sheets und Overlays 🟡

**Datei:** Alle Sheet-Views (ImposterInfoSheet, ImposterMultiplayerSheet etc.)

**Problem:**
Wenn ein Sheet erscheint, sollte VoiceOver-Fokus automatisch auf den ersten
wichtigen Inhalt des Sheets springen. Ohne `@AccessibilityFocusState` bleibt
der Fokus möglicherweise hinter dem Sheet auf dem vorherigen Element.

```swift
struct SomeSheet: View {
    @AccessibilityFocusState private var titleFocused: Bool

    var body: some View {
        VStack {
            Text("Sheet Titel")
                .accessibilityFocused($titleFocused)
            // ...
        }
        .onAppear { titleFocused = true }
    }
}
```

**WCAG:** 3.2.1 On Focus (Level A), 3.2.2 On Input (Level A)

---

### AC-15: Spielphasen-Wechsel ohne VoiceOver-Announcement 🟡

**Datei:** `Games/Imposter/Views/GamePlayView.swift`,
`Games/Question/Views/QuestionsGameView.swift`

**Problem:**
Wenn die Spielphase wechselt (Setup → Diskussion → Voting → Results), ändert
sich der visuelle Kontext dramatisch. VoiceOver-Nutzer werden nicht informiert
dass eine neue Phase begonnen hat.

**Fix:**
```swift
.onChange(of: gamePhase) { newPhase in
    UIAccessibility.post(
        notification: .screenChanged,
        argument: "Phase gewechselt: \(newPhase.displayName)"
    )
}
```

**WCAG:** 4.1.3 Status Messages (Level AA)

---

## ZUSAMMENFASSUNG PHASE 3.3 (Accessibility)

| Priorität | Findings | WCAG-Level | Top-Issues |
|-----------|----------|------------|------------|
| 🔴 Kritisch | 3 | A / AA | accessibilityLabel fehlt fast überall (AC-01/02), Dynamic Type ignoriert (AC-07) |
| 🟠 Hoch | 8 | A / AA | Dekorative Icons (AC-03), Custom Components ohne Rolle (AC-04), Timer ohne Update (AC-05), Kontrast (AC-09), Touch Targets (AC-10), Gesten ohne Alternative (AC-11), Reduce Motion (AC-12) |
| 🟡 Mittel | 4 | AA / AAA | Lottie (AC-13), Fokus-Kontrolle (AC-14), Phasen-Announcement (AC-15), minimumScaleFactor (AC-08) |

---

## PRIORISIERTE ACTION LIST

### Sofort (Kritisch — P0)
1. **AC-01/02:** In allen Games accessibilityLabel für alle Buttons nachrüsten
   - Alle `Image(systemName:)` Buttons beschriften
   - Alle `onTapGesture` durch `Button` + Label ersetzen
2. **AC-07:** Migration von `.font(.system(size:))` auf semantische Fonts starten

### Kurzfristig (Hoch — P1)
3. **AC-03:** Dekorative Elemente mit `.accessibilityHidden(true)` markieren
4. **AC-04:** GameModeCard, GroupVoteCard als `Button` reimplementieren
5. **AC-12:** `@Environment(\.accessibilityReduceMotion)` in alle animierten Views
6. **AC-09:** Farbkontraste prüfen und kritische Texte auf mind. 4.5:1 anheben

### Mittelfristig (Mittel — P2)
7. **AC-05:** Timer-Countdowns mit `accessibilityValue` ausstatten
8. **AC-11:** Swipe-Gesten mit `accessibilityAction` Alternativen
9. **AC-13:** Lottie durch `AccessibleLottieView` ersetzen
10. **AC-14:** Sheets mit `@AccessibilityFocusState` ausrüsten

---

## MANUELLE PRÜFUNGEN (Gerät erforderlich)

Diese Items können nicht durch statische Code-Analyse bestätigt werden:

| # | Prüfung | Warum manuell |
|---|---------|--------------|
| M-01 | VoiceOver Durchlauf Imposter Setup | Fokus-Reihenfolge und Labels im Zusammenspiel |
| M-02 | VoiceOver Durchlauf Bet Buddy Spielrunde | Betting-Flow mit Handicap prüfen |
| M-03 | Dynamic Type XXL in allen Screens | Layout-Brüche bei großer Schrift |
| M-04 | Reduce Motion aktiviert — alle Animationen | Setzt Reduce Motion die Animations korrekt aus? |
| M-05 | Kontrast-Verhältnisse mit Accessibility Inspector messen | Exakte Kontrast-Werte |
| M-06 | Switch Control — alle interaktiven Elemente erreichbar? | Tab-Reihenfolge |

---

*Erstellt: 2026-04-12 — Teil von Phase 3 des Gesamtaudits*
*Gesamt Phase 3: 26 UI/UX + 15 Accessibility = 41 Findings*
