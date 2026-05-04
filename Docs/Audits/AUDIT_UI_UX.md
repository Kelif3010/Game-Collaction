# AUDIT: UI/UX & Design — Phase 3
## Erstellungsdatum: 2026-04-12

> Abgedeckt: iOS 26 Liquid Glass Compliance, iOS HIG, Design-Konsistenz,
> Animationen, Typography, Touch Targets, Safe Areas, Dark Mode, Deprecated APIs.

---

## ÜBERSICHT

| Kategorie | Findings | Kritisch | Hoch | Mittel | Niedrig |
|-----------|----------|----------|------|--------|---------|
| Liquid Glass (iOS 26) | 5 | 1 | 3 | 1 | 0 |
| Design-Konsistenz | 6 | 0 | 3 | 2 | 1 |
| Typography & Dynamic Type | 3 | 1 | 1 | 1 | 0 |
| Touch Targets & Gesten | 3 | 0 | 2 | 1 | 0 |
| Safe Areas & Layout | 3 | 0 | 1 | 2 | 0 |
| Dark Mode | 2 | 0 | 1 | 1 | 0 |
| Deprecated APIs | 2 | 0 | 2 | 0 | 0 |
| Animationen | 2 | 0 | 0 | 2 | 0 |
| **TOTAL** | **26** | **2** | **13** | **10** | **1** |

---

## KATEGORIE 1: LIQUID GLASS (iOS 26)

---

### UI-01: Liquid Glass fehlt in 95% der App — massives iOS 26 Defizit 🔴

**Datei:** Gesamtes Projekt (202 Dateien)

**Problem:**
Das gesamte Projekt hat nur **1 einzigen `.glassEffect()`-Aufruf** in der gesamten Codebase.
Liquid Glass wurde nur im `ContentView.swift` implementiert (CompatibleGlassEffectContainer
für die Menü-Karten). Alle Games, Sheets, Overlays, Header, Buttons und Overlays nutzen
weiterhin manuell gebaute `.background(Color.white.opacity(0.1))` oder `.ultraThinMaterial`
Pseudo-Glass-Effekte — die auf iOS 26 nicht mehr zeitgemäß aussehen.

**Betroffene Bereiche (Beispiele):**
- `Games/Imposter/Views/GameSetupView.swift` — alle Karten, Buttons, Header
- `Games/Bet Buddy/Screens/HomeView.swift` — alle Cards, Buttons
- `Games/TimesUp/Views/TimesUpGameView.swift` — alle Overlays
- `Games/Question/Views/` — alle Phasen-Views
- Alle Sheets (`ImposterMultiplayerSheet`, `QuestionsMultiplayerSheet` etc.)
- `Games Collection/MainSettingsView.swift` — Settings-Karten
- `Games Collection/GameRecommenderView.swift` — Mood/Time Buttons, GlassBox

**Bestand:**
```swift
// ContentView.swift — EINZIGE Liquid Glass Nutzung im Projekt:
struct CompatibleGlassEffectContainer<Content: View>: View {
    var body: some View {
        if #available(iOS 26, *) {
            GlassEffectContainer(spacing: spacing) { content }
        } else {
            content
        }
    }
}
```

**Fix:** Schrittweise Liquid Glass Migration:
1. Zunächst alle prominenten Buttons auf `.buttonStyle(.glass)` oder `.buttonStyle(.glassProminent)` umstellen
2. Cards/Panels mit `.glassEffect(.regular, in: .rect(cornerRadius: 16))` versehen
3. Floating Elements (FABs, Overlays) in `GlassEffectContainer` wrappen
4. Stets `if #available(iOS 26, *)` mit Fallback auf `.ultraThinMaterial`

---

### UI-02: GlassEffectContainer-Wrapping fehlt für gruppierte Elemente 🟠

**Datei:** `Games Collection/ContentView.swift`

**Problem:**
Die `CompatibleGlassEffectContainer`-Implementierung ist vorhanden, wird aber nur für
die Hauptmenü-Karten genutzt. Wenn mehrere Glass-Elemente nebeneinander existieren
(z.B. Imposter GameSetupView Karten), werden sie ohne Container gerendert — dadurch
fehlen die Blend- und Morphing-Effekte die iOS 26 Liquid Glass so charakteristisch machen.

**Fix:**
```swift
// FALSCH — Glass ohne Container:
HStack {
    CardA().glassEffect()
    CardB().glassEffect()
}

// RICHTIG — Glass im Container:
GlassEffectContainer(spacing: 16) {
    HStack(spacing: 16) {
        CardA().glassEffect()
        CardB().glassEffect()
    }
}
```

---

### UI-03: Manuelle Glass-Simulation in BetBuddyTheme nicht durch echtes Liquid Glass ersetzt 🟠

**Datei:** `Games/Bet Buddy/Resources/BetBuddyTheme.swift`

**Problem:**
`BetBuddyTheme` hat einen `glassCard` Modifier der `.background(Color.white.opacity(0.1))` +
`.background(.ultraThinMaterial)` + `.overlay(stroke)` kombiniert — eine manuelle
Glass-Simulation die auf iOS 26 durch echtes `.glassEffect()` ersetzt werden sollte.

```swift
// BetBuddyTheme.swift — manuelle Glass-Simulation:
func glassCard() -> some View {
    self
        .background(Color.white.opacity(0.1))
        .background(.ultraThinMaterial)
        .overlay(RoundedRectangle(...).stroke(Color.white.opacity(0.2)))
}
```

**Fix:**
```swift
func glassCard() -> some View {
    if #available(iOS 26, *) {
        self
            .padding()
            .glassEffect(.regular, in: .rect(cornerRadius: 16))
    } else {
        self
            .background(Color.white.opacity(0.1))
            .background(.ultraThinMaterial)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.2)))
    }
}
```

---

### UI-04: Floating Action Buttons ohne `.interactive()` 🟠

**Datei:** `Games/Imposter/Views/Components/FloatingStartButton.swift`, diverse Views

**Problem:**
Floating Buttons die als Liquid Glass implementiert werden sollten, nutzen
`.interactive()` nicht. Das `.interactive()`-Modifier ist der Schlüssel dafür,
dass Liquid Glass auf Touch/Pointer reagiert (squeeze, ripple). Ohne es wirkt
Glass-Button leblos.

**Fix:**
```swift
Button(action: startGame) {
    Image(systemName: "play.fill")
        .font(.title2)
        .padding(20)
}
.glassEffect(.regular.tint(.blue).interactive(), in: .circle)
```

---

### UI-05: Kein glassEffectID für Morphing-Transitionen bei animierten View-Wechseln 🟡

**Datei:** Diverse Views mit `if`/`switch` Animationen

**Problem:**
In mehreren Views werden Views animiert ein-/ausgeblendet (z.B. GameSetupView
wechselt zwischen Setup-Phasen, TimesUp GameView hat Phasen-Wechsel).
Ohne `glassEffectID(_:in:)` und `@Namespace` funktioniert Liquid Glass Morphing nicht.

**Fix:**
```swift
@Namespace private var glassNamespace

GlassEffectContainer(spacing: 24) {
    if currentPhase == .setup {
        SetupCard()
            .glassEffect()
            .glassEffectID("main-card", in: glassNamespace)
    } else {
        GameCard()
            .glassEffect()
            .glassEffectID("main-card", in: glassNamespace)
    }
}
```

---

## KATEGORIE 2: DESIGN-KONSISTENZ

---

### UI-06: 4 voneinander isolierte Design-Systeme ohne gemeinsame Basis 🟠

**Problem:**
Jedes Game hat sein völlig unabhängiges Design-System:

| Design-System | Datei | Scope |
|--------------|-------|-------|
| `ImposterStyle` | `Games/Imposter/Views/Components/ImposterStyle.swift` | Nur Imposter |
| `BetBuddyTheme` | `Games/Bet Buddy/Resources/BetBuddyTheme.swift` | Nur Bet Buddy |
| `QuestionsTheme` | `Games/Question/Resources/QuestionsTheme.swift` | Nur Question |
| `TimesUpStyle` | `Games/TimesUp/Resources/TimesUpStyle.swift` | Nur TimesUp |

Kein gemeinsamer `AppDesignSystem` oder `SharedTheme`. Das führt zu:
- Inkonsistenten Spacing-Werten (8/12/16 gemischt)
- Inkonsistenten Corner-Radien (12/14/16/20 gemischt)
- 4 verschiedenen Shadow-Implementierungen
- Kein einheitlicher Button-Stil über Games hinweg

**Fix:**
```swift
// Games Collection/Shared/Design/AppTheme.swift (neu)
enum AppTheme {
    static let cornerRadiusSmall: CGFloat = 12
    static let cornerRadiusMedium: CGFloat = 16
    static let cornerRadiusLarge: CGFloat = 24
    static let spacingXS: CGFloat = 4
    static let spacingS: CGFloat = 8
    static let spacingM: CGFloat = 16
    static let spacingL: CGFloat = 24
    static let spacingXL: CGFloat = 32
}
```

---

### UI-07: `Theme.swift` ist reiner Wrapper ohne eigene Logik — Duplikat 🟠

**Datei:** `Games/Bet Buddy/Resources/Theme.swift`

**Problem:**
224 Verwendungen von `Theme.x` in Bet Buddy — alles Forwarding auf `BetBuddyTheme.x`.
Keine eigene Logik. Dieser Wrapper macht den Code schwerer verständlich und
verlangsamt refactoring.

```swift
enum Theme {
    static let background = BetBuddyTheme.gradient       // Pure forward
    static let cardBackground = BetBuddyTheme.backgroundCard
    // ...alle ~15 Properties sind reine Forwarder
}
```

**Fix:** `Theme.swift` löschen, alle 224 `Theme.x` → `BetBuddyTheme.x` ersetzen.

---

### UI-08: Header/Navigation-Leiste in jedem Game anders 🟠

**Problem:**

| Game | Header-Implementierung |
|------|----------------------|
| Imposter | Custom `topBar` HStack mit eigenen Buttons |
| Bet Buddy | `ScreenHeader` Component (eigener Stil) |
| Question | Inline HStack (kein Component) |
| TimesUp | Inline HStack (kein Component) |
| Einstellungen | DashboardCard-Style (eigener Stil) |

Nutzer erleben 5 verschiedene Top-Navigation-Stile in einer App.

**Fix:** `SharedGameHeader.swift` im Shared-Ordner:
```swift
struct GameHeader: View {
    let title: String
    var leadingButton: (() -> Void)?
    var trailingButton: (() -> Void)?
    var leadingIcon: String = "chevron.left"
    var trailingIcon: String?

    var body: some View {
        HStack {
            if let leading = leadingButton {
                Button(action: leading) {
                    Image(systemName: leadingIcon)
                        .font(.title3)
                }
            }
            Spacer()
            Text(title).font(.headline)
            Spacer()
            // trailing...
        }
    }
}
```

---

### UI-09: Hintergrund-Gradienten hard-coded in 8+ Views mit leichten Variationen 🟡

**Betroffene Dateien:**
- `MainSettingsView.swift:45-50` — `[.black, .indigo.opacity(0.5), .purple.opacity(0.4)]`
- `GameRecommenderView.swift:103-107` — `[.indigo.opacity(0.8), .purple.opacity(0.6), .black]`
- `OnboardingView.swift` — `ImposterStyle.backgroundGradient`
- `ImposterStyle.swift` — Definiert `backgroundGradient` Property
- `ContentView.swift` — Eigener Gradient

5 verschiedene "Dark Purple" Gradienten die fast identisch sind aber nie aus
einer gemeinsamen Quelle kommen. Wenn das App-Thema sich ändert, müssen alle
5 manuell angepasst werden.

**Fix:** In `AppTheme` zentralisieren:
```swift
extension AppTheme {
    static var mainBackgroundGradient: LinearGradient {
        LinearGradient(
            colors: [.black, .indigo.opacity(0.5), .purple.opacity(0.4)],
            startPoint: .top, endPoint: .bottom
        )
    }
}
```

---

### UI-10: OnboardingView verwendet `ImposterStyle.backgroundGradient` — falsche Dependency 🟡

**Datei:** `Games Collection/Shared/OnboardingView.swift`

**Problem:**
Die globale OnboardingView (die bei App-Start erscheint, vor Spielauswahl) importiert
indirekt `ImposterStyle.backgroundGradient`. Das ist eine falsche Dependency-Richtung:
App-Shell → Game-spezifisches Design-System.

```swift
// OnboardingView.swift:
.background(ImposterStyle.backgroundGradient)  // Falsch!
```

**Fix:** `AppTheme.mainBackgroundGradient` verwenden (nach UI-09 Fix).

---

### UI-11: `dsds.swift` — Datei mit sinnlosem Namen 🟢

**Datei:** `Games/Bet Buddy/Bet Buddy Resources/dsds.swift`

**Problem:**
Die Datei enthält die nützliche `Int.asAlphabet` Extension, aber der Dateiname
`dsds.swift` ist offensichtlich ein Test/Platzhalter-Name der nie bereinigt wurde.

**Fix:** Umbenennen zu `Int+Alphabet.swift`, in `Games Collection/Shared/Extensions/`
verschieben.

---

## KATEGORIE 3: TYPOGRAPHY & DYNAMIC TYPE

---

### UI-12: 322 Aufrufe von `.font(.system(size:))` — Dynamic Type vollständig ignoriert 🔴

**Statistik:**
```
.font(.system(size: ...)) in 65 Dateien: 322 Treffer
```

**Problem:**
Nahezu jede Schriftgröße im Projekt ist hard-coded. Wenn ein Nutzer in iOS
`Einstellungen → Bedienungshilfen → Schriftgröße` ändert, bleibt die App komplett
starr. Das ist:
- Barrierefreiheits-Verstoß (WCAG 1.4.4 Resize Text)
- iOS HIG Verletzung (Apple empfiehlt semantische Fonts)
- App Store Rejection Risk bei Accessibility Review

**Betroffene Pattern (Beispiele):**
```swift
.font(.system(size: 32, weight: .bold))      // Soll .largeTitle oder .title sein
.font(.system(size: 14, weight: .medium))    // Soll .caption oder .subheadline sein
.font(.system(size: 11))                     // Soll .caption2 sein
.font(.system(size: 18, weight: .semibold))  // Soll .headline sein
```

**Mapping für häufige Größen:**
| Fixed Size | Semantisches Äquivalent |
|-----------|------------------------|
| 34-40 | `.largeTitle` |
| 28-32 | `.title` |
| 22-24 | `.title2` |
| 20 | `.title3` |
| 16-18 | `.headline` oder `.body` |
| 14-15 | `.subheadline` |
| 12-13 | `.caption` |
| 10-11 | `.caption2` |

**Fix (schrittweise):**
```swift
// VORHER:
Text("Spieler").font(.system(size: 18, weight: .semibold))

// NACHHER:
Text("Spieler").font(.headline)

// Falls custom weight/design nötig:
Text("Spieler").font(.headline.weight(.semibold))
```

---

### UI-13: Fehlende `lineLimit` und `minimumScaleFactor` für lange Texte 🟠

**Problem:**
Spielernamen, Kategorienamen und Spieltitel werden ohne `lineLimit` oder
`minimumScaleFactor` gerendert. Bei langen Namen (z.B. "Konstantinos") können
Labels brechen oder Labels kürzen sich ohne Feedback ab.

**Betroffene Dateien:**
- `Games/Imposter/Views/Components/CompactPlayersList.swift` — Spielernamen
- `Games/Bet Buddy/Components/GroupVoteCard.swift` — Spielernamen in Cards
- `Games/TimesUp/Views/Components/` — Team-Namen

**Fix:**
```swift
Text(playerName)
    .lineLimit(1)
    .minimumScaleFactor(0.7)
    .truncationMode(.tail)
```

---

### UI-14: Feste Schriftgrößen in `ImposterStyle` Design-System 🟡

**Datei:** `Games/Imposter/Views/Components/ImposterStyle.swift`

**Problem:**
Das Imposter Design-System definiert Buttons, Labels und Headers alle mit
`.font(.system(size: X))`. Das propagiert fixed-size Fonts durch alle
Imposter-Views.

```swift
// ImposterStyle.swift:
struct ImposterPrimaryButton: View {
    var body: some View {
        Text(title)
            .font(.system(size: 18, weight: .bold))  // Fix: .headline.bold()
    }
}
```

**Fix:** Semantische Fonts im Design-System verwenden → alle Views erben automatisch
korrektes Dynamic Type Verhalten.

---

## KATEGORIE 4: TOUCH TARGETS & GESTEN

---

### UI-15: 268 feste `.frame(width:height:)` — viele Buttons unter Apple-Minimum 44pt 🟠

**Statistik:**
```
.frame(width: ..., height: ...) in Projekt: 268 Treffer
```

**Problem:**
Apple HIG und WCAG 2.5.5 schreiben Mindest-Touch-Targets von 44×44 Points vor.
Identifizierte Probleme:

| View | Buttons-Größe | Problem |
|------|--------------|---------|
| `ImposterIconBadge` | 36×36 | Unter Minimum |
| `FloatingStartButton` | 40×40 | Grenzwertig |
| `BetBuddy ScreenHeader` | 32×32 | Deutlich unter Minimum |
| `ImposterInfoSheet` close button | 30×30 | Deutlich unter Minimum |
| `GameModeCard` info button | 24×24 | Stark unter Minimum |

**Fix:**
```swift
// FALSCH:
Button(action: close) {
    Image(systemName: "xmark")
        .frame(width: 30, height: 30)
}

// RICHTIG:
Button(action: close) {
    Image(systemName: "xmark")
}
.frame(minWidth: 44, minHeight: 44)
// Oder mit contentShape für größeren Tap-Bereich:
.contentShape(Rectangle())
.frame(width: 44, height: 44)
```

---

### UI-16: Drag-Gesten ohne Haptic-Feedback und ohne Accessibility-Alternative 🟠

**Datei:** `Games/TimesUp/Views/TimesUpGameView.swift`, `Games/Imposter/Views/`

**Problem:**
Swipe-Gesten (Karte wischen, Team-Auswahl) haben:
1. Kein Haptic-Feedback bei Aktivierung (obwohl HapticsManager vorhanden)
2. Keine Accessibility-Alternative für Nutzer die Gesten nicht nutzen können

**Fix:**
```swift
.gesture(
    DragGesture()
        .onEnded { value in
            if value.translation.width > 50 {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                swipeRight()
            }
        }
)
.accessibilityAction(named: "Richtig") { swipeRight() }   // Alternative
.accessibilityAction(named: "Falsch") { swipeLeft() }
```

---

### UI-17: `onTapGesture` statt `Button` für klickbare Elemente 🟡

**Datei:** Mehrere Views (GameModeCard, GroupVoteCard etc.)

**Problem:**
Einige "Buttons" sind als View mit `.onTapGesture` implementiert statt als
echte `Button`-Views. Das verliert:
- Automatische Accessibility-Semantik (Role: Button)
- Automatisches Highlight/Feedback beim Drücken
- VoiceOver kündigt Element nicht als Button an

```swift
// FALSCH:
RoundedRectangle(cornerRadius: 16)
    .fill(Color.blue)
    .onTapGesture { selectMode() }

// RICHTIG:
Button(action: selectMode) {
    RoundedRectangle(cornerRadius: 16)
        .fill(Color.blue)
}
```

---

## KATEGORIE 5: SAFE AREAS & LAYOUT

---

### UI-18: 99 `ignoresSafeArea()` Aufrufe — viele zu aggressiv 🟠

**Statistik:**
```
.ignoresSafeArea() im Projekt: 99 Treffer
```

**Problem:**
`ignoresSafeArea()` ohne `.edges` Parameter ignoriert ALLE Safe Areas
(top, bottom, leading, trailing). Das ist oft korrekt für Hintergrund-Views,
aber wenn es auf Content-Container angewendet wird, ragt Content unter
Dynamic Island, Home Indicator oder Notch.

**Korrekte Verwendung:**
```swift
// NUR für Hintergrund korrekt:
Color.black.ignoresSafeArea()

// NUR untere Safe Area für Full-Bleed:
Color.black.ignoresSafeArea(edges: .bottom)

// FALSCH für Content:
VStack { /* spielerinhalt */ }.ignoresSafeArea()  // Content kann unter Dynamic Island rutschen
```

---

### UI-19: `safeAreaInset` nicht genutzt — Floating Buttons überdecken Content 🟡

**Datei:** `Games/Imposter/Views/Components/FloatingStartButton.swift`,
`Games/Bet Buddy/Screens/HomeView.swift`

**Problem:**
Floating Buttons (`FloatingStartButton`, "Bet erstellen" in BetBuddy) werden
mit `ZStack` + `.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)`
positioniert. Der darunterliegende ScrollView-Content wird dadurch verdeckt.
`safeAreaInset` löst das elegant:

```swift
// FALSCH — Button überdeckt letzten Listeneintrag:
ZStack(alignment: .bottom) {
    ScrollView { content }
    FloatingButton()
}

// RICHTIG — ScrollView weiß von Button und scrollt frei:
ScrollView { content }
    .safeAreaInset(edge: .bottom) {
        FloatingButton()
    }
```

---

### UI-20: Deprecated `UIScreen.main.bounds` in BetBuddyBackgroundView 🟡

**Datei:** `Games/Bet Buddy/Resources/BetBuddyTheme.swift`

**Problem:**
`UIScreen.main` ist seit iOS 16 deprecated. In Multi-Window Umgebungen (iPad
Multitasking, macOS Catalyst) gibt `UIScreen.main` falsche Werte zurück.

```swift
// BetBuddyTheme.swift — deprecated:
let screenWidth = UIScreen.main.bounds.width
```

**Fix:**
```swift
// iOS 26 kompatibel:
// In SwiftUI: GeometryReader verwenden
GeometryReader { proxy in
    let width = proxy.size.width
}

// Oder in SwiftUI: UIScreen(mainScreen) via scene
```

---

## KATEGORIE 6: DARK MODE

---

### UI-21: `.preferredColorScheme(.dark)` auf App-Ebene — Nutzer-Präferenz ignoriert 🟠

**Datei:** `Games Collection/ContentView.swift`

**Problem:**
```swift
.preferredColorScheme(.dark)   // ContentView.swift
```

Die App erzwingt Dark Mode, ignoriert System-Einstellung und respektiert
nicht "Light Mode" Nutzer. Das ist:
- iOS HIG Verletzung (Apps sollen Nutzer-Präferenz respektieren)
- Kann Accessibility-Anforderungen einiger Nutzer verletzen
- Verhindert das Testen von Light Mode Aussehen

**Fix-Strategie:**
Wenn das App-Design NUR für Dark Mode ausgelegt ist: In Info.plist
`UIUserInterfaceStyle = Dark` setzen und die SwiftUI Einstellung entfernen.
Wenn Light Mode Support gewünscht: Semantic Colors in allen Views prüfen.

---

### UI-22: Picker in GameRecommenderView erzwingt `.colorScheme(.dark)` 🟡

**Datei:** `Games Collection/GameRecommenderView.swift`

**Problem:**
```swift
Picker("...", selection: ...) { ... }
    .colorScheme(.dark)  // Nur für diesen Picker
```

Wenn die App jemals Light Mode unterstützt, sieht dieser Picker anders aus als
der Rest. Inkonsistent.

**Fix:** Entfernen wenn App Dark Mode erzwingt. Oder semantische Farben nutzen
die in beiden Modes funktionieren.

---

## KATEGORIE 7: DEPRECATED APIs

---

### UI-23: `cornerRadius(_:)` deprecated — 127 Treffer im Projekt 🟠

**Statistik:**
```
.cornerRadius( im Projekt: 127 Treffer
```

**Problem:**
`.cornerRadius(_:)` ist seit iOS 16 deprecated. Der Ersatz ist `.clipShape`:

```swift
// DEPRECATED (seit iOS 16):
view.cornerRadius(16)

// MODERN:
view.clipShape(RoundedRectangle(cornerRadius: 16))

// Oder mit Antialiasing-Control:
view.clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
```

`.continuous` Corner Style entspricht dem Apple "Squircle" Design-Prinzip
und sieht besser aus als der default `.circular`.

---

### UI-24: `UIScreen.main.bounds` in BetBuddyTheme deprecated 🟠

*(Bereits als UI-20 dokumentiert — hier für Vollständigkeit)*

**Datei:** `Games/Bet Buddy/Resources/BetBuddyTheme.swift`
**Fix:** GeometryReader oder Environment(\.mainWindowSize) auf iOS 17+

---

## KATEGORIE 8: ANIMATIONEN

---

### UI-25: `DispatchQueue.main.asyncAfter` für UI-Animationen statt SwiftUI-Animationen 🟡

**Datei:** `Games/Question/Views/Phases/QuestionsResultsPhaseView.swift`,
`Games Collection/Shared/OnboardingView.swift`

**Problem:**
```swift
// QuestionsResultsPhaseView.swift — 8 Staggered asyncAfter:
DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { showElement1 = true }
DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { showElement2 = true }
DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) { showElement3 = true }
// ...
```

`asyncAfter` für Animationen ist fragil: keine Cancellation bei View-Dismiss,
kein Respect für "Reduce Motion" Accessibility-Setting, schwer testbar.

**Fix:**
```swift
// SwiftUI-native Stagger Animation:
ForEach(elements.indices, id: \.self) { index in
    element[index]
        .opacity(showElements ? 1 : 0)
        .animation(
            .easeOut(duration: 0.4).delay(Double(index) * 0.15),
            value: showElements
        )
}
.onAppear { showElements = true }
```

---

### UI-26: Animationen ohne `.animation(.default, value:)` — ungezielte Animationen 🟡

**Problem:**
Viele Views nutzen `.animation(.spring())` ohne `value:` Parameter. Das animiert
ALLE State-Änderungen in der View, nicht nur die gewünschten. Seit iOS 15 ist
`.animation()` ohne `value:` deprecated.

```swift
// DEPRECATED/PROBLEMATISCH:
VStack { ... }
    .animation(.spring())

// KORREKT — nur wenn specificState sich ändert:
VStack { ... }
    .animation(.spring(), value: isExpanded)
```

---

## ZUSAMMENFASSUNG PHASE 3.1–3.2 (UI/UX & Liquid Glass)

| Priorität | Anzahl | Top-Issues |
|-----------|--------|------------|
| 🔴 Kritisch | 2 | Liquid Glass fehlt in 95% der App (UI-01), 322 fixed font sizes (UI-12) |
| 🟠 Hoch | 13 | Kein GlassEffectContainer (UI-02), 4 Design-Systeme ohne Basis (UI-06), Headers inkonsistent (UI-08), Touch Targets zu klein (UI-15), 99x ignoresSafeArea (UI-18), 127x deprecated cornerRadius (UI-23) |
| 🟡 Mittel | 10 | Gradient Duplikate (UI-09), OnboardingView Dependency (UI-10), lineLimit fehlt (UI-13), safeAreaInset fehlt (UI-19), Dark Mode (UI-21), Animationen (UI-25/26) |
| 🟢 Niedrig | 1 | dsds.swift Umbenennung (UI-11) |

---

*Erstellt: 2026-04-12 — Teil von Phase 3 des Gesamtaudits*
*Nächste Datei: AUDIT_ACCESSIBILITY.md (Phase 3.3)*
