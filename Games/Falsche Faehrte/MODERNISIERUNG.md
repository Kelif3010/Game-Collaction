# Falsche Fährte — Modernisierungs-Analyse
**iOS 26 · Swift 6 · Stand: Mai 2026**

---

## Zusammenfassung

Das Spiel ist **grundsätzlich solide** gebaut — `@MainActor`-ViewModel, Swift Concurrency für den Timer, `for await` im Multiplayer-Handler. Es gibt aber eine Reihe von Stellen, die mit iOS 26 / Swift 6 veraltet sind oder von neuen APIs stark profitieren würden.

---

## 1. Swift 6 — Strenge Concurrency

### 1.1 `@Observable` statt `ObservableObject` *(höchste Priorität)*

**Betroffene Datei:** `ViewModels/FFViewModel.swift`

Das gesamte ViewModel nutzt noch den alten `ObservableObject + @Published`-Ansatz aus iOS 15. Mit Swift 6 / iOS 17 ist das `@Observable`-Makro der offizielle Nachfolger.

```swift
// Vorher (iOS 15-Stil)
@MainActor
final class FFViewModel: ObservableObject {
    @Published var gamePhase: FFGamePhase = .setup
    @Published var players: [FFPlayer] = []
    ...
}

// Danach (iOS 17+ / Swift 6)
@MainActor
@Observable
final class FFViewModel {
    var gamePhase: FFGamePhase = .setup
    var players: [FFPlayer] = []
    ...
}
```

**Views müssen ebenfalls angepasst werden:**

```swift
// Vorher
@StateObject private var viewModel = FFViewModel()
// FalscheFaehrteWrapper.swift

@EnvironmentObject private var viewModel: FFViewModel
// FFSetupView, FFBluffPhaseView, FFVotePhaseView usw.

.environmentObject(viewModel)
// FalscheFaehrteWrapper.swift

// Danach
@State private var viewModel = FFViewModel()

@Environment(FFViewModel.self) private var viewModel

.environment(viewModel)
```

> **Warum wichtig:** Mit Swift 6 Strict Concurrency erzeugt `@Published` in Kombination mit `ObservableObject` Warnungen. `@Observable` hat feinere Granularität (nur wirklich geänderte Properties triggern Neu-Renderings) und benötigt kein `Combine`.

---

### 1.2 `Combine`-Import entfernen

**Betroffene Datei:** `ViewModels/FFViewModel.swift`, Zeile 2

```swift
import Combine   // ← kann raus sobald @Observable eingesetzt wird
```

---

### 1.3 `Sendable`-Konformanz für Multiplayer-Modelle

**Betroffene Dateien:** `Models/FFPlayer.swift`, `Models/FFRound.swift`, `Models/FFQuestion.swift`, `Multiplayer/FFMultiplayerModels.swift`

Mit Swift 6 Strict Concurrency müssen alle Typen, die über Actor-Grenzen übergeben werden, `Sendable` sein. Alle betroffenen `struct`s sind value types — ein einfaches Hinzufügen genügt:

```swift
struct FFPlayer: Identifiable, Codable, Equatable, Sendable { ... }
struct FFQuestion: Identifiable, Codable, Sendable { ... }
struct FFRound: Identifiable, Sendable { ... }
struct FFGameConfigPayload: Codable, Sendable { ... }
// ... alle weiteren Payload-Structs
```

---

### 1.4 `DispatchQueue.main.asyncAfter` → `Task.sleep`

**Betroffene Datei:** `Views/FFVotePhaseView.swift`, Zeile 270

```swift
// Vorher — GCD, nicht Swift-Concurrency-konform
DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
    currentVoterIndex = nextIdx
    selectedSubmissionId = nil
    withAnimation(.easeInOut(duration: 0.2)) {
        showVoterTransition = false
    }
}

// Danach — Swift Concurrency, Swift 6 sauber
Task { @MainActor in
    try? await Task.sleep(for: .seconds(1.2))
    currentVoterIndex = nextIdx
    selectedSubmissionId = nil
    withAnimation(.easeInOut(duration: 0.2)) {
        showVoterTransition = false
    }
}
```

---

### 1.5 `@preconcurrency import` für Combine / MPC

Falls noch Combine gebraucht wird (z. B. wegen anderer Teile der App):

```swift
@preconcurrency import Combine
@preconcurrency import MultipeerConnectivity
```

---

## 2. iOS 26 — Neue APIs & Liquid Glass

### 2.1 `SensoryFeedback`-Modifier statt `UIImpactFeedbackGenerator`

**Betroffene Dateien:** `FFSetupView.swift`, `FFBluffPhaseView.swift`, `FFVotePhaseView.swift`, `FFGameOverView.swift`

`UIImpactFeedbackGenerator` / `UINotificationFeedbackGenerator` sind UIKit-APIs. iOS 17 hat `.sensoryFeedback(_:trigger:)` als nativen SwiftUI-Ersatz eingeführt.

```swift
// Vorher — UIKit, nicht deklarativ
Button {
    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    startSinglePlayerGame()
}

// Danach — SwiftUI, deklarativ, kein UIKit-Import nötig
@State private var hapticTrigger = false

Button {
    hapticTrigger.toggle()
    startSinglePlayerGame()
}
.sensoryFeedback(.impact(weight: .medium), trigger: hapticTrigger)
```

Für Fehler-Feedback:
```swift
.sensoryFeedback(.error, trigger: shakeTrigger)
```

---

### 2.2 Liquid Glass UI für Karten

**Betroffene Dateien:** `Components/FFStyle.swift` (`FFCardStyle`), alle Views

iOS 26 führt `.glassEffect()` als natives Systemmaterial ein — die natürliche Weiterentwicklung von `.ultraThinMaterial`. Der bestehende Noir-Look kann gezielt erweitert werden:

```swift
// Vorher
struct FFCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content.background(
            RoundedRectangle(cornerRadius: FFStyle.cornerRadius, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(...)
        )
    }
}

// Danach — iOS 26 Liquid Glass
struct FFCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .glassEffect(
                .regular.tint(FFStyle.accentViolet.opacity(0.08)),
                in: RoundedRectangle(cornerRadius: FFStyle.cornerRadius, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: FFStyle.cornerRadius, style: .continuous)
                    .stroke(FFStyle.accentViolet.opacity(0.15), lineWidth: 1)
            )
    }
}
```

> **Hinweis:** Der handgemachte Noir-Stil (tiefes Blauschwarz + Violett-Glows) ist ein bewusstes Designentscheid. Liquid Glass muss nicht überall eingesetzt werden — aber die Antwort-Karten in `FFVotePhaseView` und die Setup-Rows wären gute Kandidaten.

---

### 2.3 Modernere Animation-Syntax (iOS 17+)

**Betroffene Dateien:** alle Views

```swift
// Vorher — iOS 15 Stil
.spring(response: 0.55, dampingFraction: 0.82)
.spring(response: 0.35, dampingFraction: 0.65)

// Danach — iOS 17+ Kurzformen
.spring(duration: 0.55, bounce: 0.18)
.bouncy(duration: 0.35)
.snappy
```

---

### 2.4 `String(localized:)` statt `NSLocalizedString`

**Betroffene Datei:** `Models/FFQuestion.swift`, Zeilen 19–25

```swift
// Vorher — ObjC-Erbe
var localizedName: String {
    switch self {
    case .klassisch: return NSLocalizedString("ff.pack.klassisch", comment: "")
    ...
    }
}

// Danach — Swift-native (iOS 16+)
var localizedName: String {
    switch self {
    case .klassisch: return String(localized: "ff.pack.klassisch")
    ...
    }
}
```

---

### 2.5 `UserDefaults` aus dem Model herauslösen

**Betroffene Datei:** `Models/FFQuestion.swift`, Zeilen 62–70

Modelle sollten keine App-Infrastruktur direkt ansprechen. Das verstößt gegen Separation of Concerns und macht Unit-Tests schwer.

```swift
// Vorher — Model greift direkt auf UserDefaults zu
var localizedQuestion: String {
    let code = UserDefaults.standard.string(forKey: "selectedLanguageCode") ?? "de"
    return code == "en" ? en_question : de_question
}

// Danach — Sprache wird von außen injiziert
func localizedQuestion(languageCode: String = "de") -> String {
    languageCode == "en" ? en_question : de_question
}

// Oder via @AppStorage im ViewModel:
// @AppStorage("selectedLanguageCode") private var languageCode = "de"
// round.question.localizedQuestion(languageCode: languageCode)
```

---

## 3. Pakete — Bessere Nutzung vorhandener Dependencies

### 3.1 `swift-async-algorithms` — Timer ersetzen

Das Paket ist bereits eingebunden (`swift-async-algorithms 1.1.3`). Der Timer in `FFViewModel` kann mit `AsyncTimerSequence` (oder `Clock`) eleganter und testbarer geschrieben werden:

```swift
// Vorher
func startTimer(seconds: Int) {
    timerTask?.cancel()
    timeRemaining = seconds
    timerTask = Task {
        while timeRemaining > 0 && !Task.isCancelled {
            try? await Task.sleep(for: .seconds(1))
            if !Task.isCancelled { timeRemaining -= 1 }
        }
    }
}

// Danach — mit swift-async-algorithms
import AsyncAlgorithms

func startTimer(seconds: Int) {
    timerTask?.cancel()
    timeRemaining = seconds
    timerTask = Task {
        for await _ in AsyncTimerSequence.repeating(every: .seconds(1)) {
            guard !Task.isCancelled, timeRemaining > 0 else { break }
            timeRemaining -= 1
        }
    }
}
```

---

### 3.2 `swift-algorithms` — Fragenauswahl

Das Paket ist bereits eingebunden (`swift-algorithms 1.2.1`). Statt `.shuffled().prefix(n)` kann `.randomSample(count:)` verwendet werden — es zieht garantiert `n` eindeutige Elemente:

```swift
import Algorithms

// Vorher
let count = min(settings.roundCount.rawValue, questionPool.count)
for i in 0..<count {
    let question = questionPool[i]
    ...
}

// Danach
let selectedQuestions = questionPool.randomSample(count: settings.roundCount.rawValue)
for question in selectedQuestions {
    ...
}
```

---

### 3.3 `swift-collections` — `OrderedDictionary` für Votes

Das Paket ist bereits eingebunden (`swift-collections 1.4.1`). Das Votes-Dictionary `[UUID: UUID]` in `FFRound` könnte als `OrderedDictionary` für deterministische Iterationsreihenfolge geführt werden — wichtig beim Punkterechnen:

```swift
import Collections

struct FFRound {
    var votes: OrderedDictionary<UUID, UUID>  // statt [UUID: UUID]
    ...
}
```

---

## 4. Code-Qualität & Muster

### 4.1 Fehlerbehandlung im JSON-Decoder

**Betroffene Datei:** `Multiplayer/FFMultiplayerHandler.swift`

Alle `try? decoder.decode(...)` schlucken Fehler stillschweigend. Mit Swift 6 sollte zumindest geloggt werden:

```swift
// Vorher
let payload = try? decoder.decode(FFBluffSubmitPayload.self, from: d)

// Danach
do {
    let payload = try decoder.decode(FFBluffSubmitPayload.self, from: d)
    vm.hostCollectBluff(payload)
} catch {
    // os_log oder print für Debug-Builds
    assertionFailure("FF Decode error: \(error)")
}
```

---

### 4.2 `FFQuestionDatabase` — Fehlerbehandlung bei JSON-Loading

**Betroffene Datei:** `Models/FFQuestion.swift`, Zeile 75

```swift
// Vorher — stiller Fallback auf leeres Array
static var all: [FFQuestion] = {
    guard let url = Bundle.main.url(...),
          let data = try? Data(contentsOf: url),
          let questions = try? JSONDecoder().decode([FFQuestion].self, from: data)
    else { return [] }
    return questions
}()

// Danach — Crash im Debug-Build, damit Fehler sofort auffallen
static var all: [FFQuestion] = {
    guard let url = Bundle.main.url(forResource: "ff_questions", withExtension: "json") else {
        assertionFailure("ff_questions.json nicht gefunden")
        return []
    }
    do {
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode([FFQuestion].self, from: data)
    } catch {
        assertionFailure("ff_questions.json Decodierfehler: \(error)")
        return []
    }
}()
```

---

### 4.3 Doppelte Antwort-Karten-Logik konsolidieren

**Betroffene Datei:** `Views/FFVotePhaseView.swift`

`answerCard(submission:index:)` (Single-Device) und der inline-Code in `mpAnswersStack` (Multiplayer) sind fast identisch (~60 Zeilen). Diese können in eine gemeinsame `AnswerCardView` extrahiert werden.

---

### 4.4 `AnyShapeStyle`-Erasure vereinfachen

**Betroffene Dateien:** `FFStyle.swift`, `FFSetupView.swift`, `FFBluffPhaseView.swift`

```swift
// Vorher — unnötige Type-Erasure
.fill(isDisabled ? AnyShapeStyle(Color.white.opacity(0.1)) : AnyShapeStyle(FFStyle.primaryGradient))

// Danach — iOS 17+ erlaubt ShapeStyle direkt in bedingten Ausdrücken
.fill(isDisabled ? Color.white.opacity(0.1) as (any ShapeStyle) : FFStyle.primaryGradient)
// oder einfacher mit einer Hilfsfunktion / @ViewBuilder
```

---

### 4.5 Accessibility — fehlende Labels auf Vote-Karten

**Betroffene Datei:** `Views/FFVotePhaseView.swift`

Die Antwort-Buttons haben keine `accessibilityLabel`-Modifikatoren. VoiceOver liest nur den Text, nicht den Kontext:

```swift
answerCard(...)
    .accessibilityLabel("Antwort \(String(UnicodeScalar(65 + index)!)): \(submission.text)")
    .accessibilityAddTraits(isSelected ? .isSelected : [])
```

---

## 5. Priorisierung

| Priorität | Änderung | Aufwand | Benefit |
|-----------|----------|---------|---------|
| 🔴 Hoch | `@Observable` Macro einführen | Mittel | Swift 6 konform, bessere Performance |
| 🔴 Hoch | `Sendable` auf allen Modellen | Niedrig | Swift 6 Strict Concurrency |
| 🟡 Mittel | `SensoryFeedback` statt UIKit-Haptics | Niedrig | Deklarativ, kein UIKit-Import |
| 🟡 Mittel | `DispatchQueue` → `Task.sleep` | Niedrig | Swift Concurrency konform |
| 🟡 Mittel | `String(localized:)` statt `NSLocalizedString` | Niedrig | Swift-native |
| 🟢 Optional | Liquid Glass `.glassEffect()` auf Karten | Niedrig | iOS 26 Design Language |
| 🟢 Optional | `AsyncTimerSequence` aus swift-async-algorithms | Niedrig | Eleganterer Timer-Code |
| 🟢 Optional | `.randomSample(count:)` aus swift-algorithms | Niedrig | Semantisch klarer |
| 🟢 Optional | Decoder-Fehlerbehandlung im MP-Handler | Niedrig | Debug-Sicherheit |
| 🟢 Optional | Doppelte Vote-Card-Logik konsolidieren | Mittel | Code-Reduktion |

---

## 6. Was bereits modern ist ✅

- `@MainActor` auf `FFViewModel` — korrekt
- `Task` + `Task.sleep(for:)` für den Timer — Swift Concurrency konform
- `for await event in events` im Multiplayer-Handler — modernes Async/Await
- `keyframeAnimator` für `ShakeModifier` — iOS 17+ API
- `.toolbar(.hidden, for: .navigationBar)` — moderner API
- `safeAreaInset(edge:)` — moderner als `padding`-Hacks
- `@FocusState` für Keyboard-Handling
- `onChange(of:)` mit zwei Parametern (new-style, iOS 17+)
- Strukturierte Trennung: Models / ViewModels / Views / Components / Multiplayer
