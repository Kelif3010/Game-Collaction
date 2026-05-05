# Schlachtplan: Imposter Modul Refactoring (Swift 6 & iOS 18+)

Dieser Schlachtplan beschreibt die schrittweise Optimierung und Modernisierung des Imposter-Moduls. Unser Fokus liegt auf der sauberen Trennung von Verantwortlichkeiten, der Reduzierung von Boilerplate und Wiederholungen sowie der Nutzung von modernem Swift 6, den neuesten iOS-APIs und den von dir gewünschten Swift-Paketen.

---

## Phase 1: Architektur & Zustandstrennung (Verantwortung sauber trennen)
Aktuell ist `GameSettings` ein "God-Object", das persistente Einstellungen (UserDefaults), temporären Laufzeitzustand (z.B. `timeRemaining`, `players`), UI-Navigation (`requestExitToMain`, `shouldDismissSheets`) und Multiplayer-Status vermischt. Das macht den Code fragil und schwer testbar.

- **Schritt 1.1: Navigations- und UI-State extrahieren**
  - Erstellen eines `ImposterRouter` oder `ImposterCoordinator` (mit `@Observable` und `@MainActor`), der sich **ausschließlich** um Sheets, Alerts und Routen (Flow Control) kümmert.
  - Dadurch werden `requestExitToMain` und `shouldDismissSheets` aus `GameSettings` entfernt.
- **Schritt 1.2: Settings vs. Session State**
  - Aufteilen von `GameSettings` in:
    - `ImposterSettingsStore`: Verwaltet nur persistente Daten (UserDefaults via `@AppStorage` oder SwiftData).
    - `GameSessionState`: Verwaltet nur den aktuellen Spielzustand (`timeRemaining`, `players`, `gamePhase`).
- **Schritt 1.3: Swift 6 Concurrency (Sendable & Actors)**
  - Sicherstellen, dass alle `@Observable` ViewModels mit `@MainActor` isoliert sind.
  - Alle Payload-Modelle für MPC (Multipeer Connectivity) müssen explizit als `Sendable` deklariert werden, um Swift 6 Data-Race Warnings zu beheben.

## Phase 2: Refactoring der Views & Aufräumen (Wiederholungen entfernen)
`GameSetupView` hat über 600 Zeilen und viele redundante UI-Bausteine.

- **Schritt 2.1: Modularisierung der Setup-View**
  - Die einzelnen Bereiche (Players, Imposters, Dauer, Modus) werden als separate, zustandslose Views (`Components/SetupRows`) in eigene Dateien ausgelagert.
  - `GameSetupSheetsModifier` wird vereinfacht und durch den neuen `ImposterRouter` gesteuert.
- **Schritt 2.2: Typsicherheit mit SFSafeSymbols**
  - Paket: **SFSafeSymbols 7.0.0**
  - Ersetzen aller Magic-Strings wie `Image(systemName: "person.3.fill")` durch `Image(systemSymbol: .person3Fill)`. Das verhindert Abstürze oder fehlerhafte Icons durch Tippfehler.

## Phase 3: Moderne Swift & iOS APIs
Die Spiel-Logik und Datenverarbeitung kann durch die nativen Swift-Pakete deutlich effizienter und sicherer gemacht werden.

- **Schritt 3.1: Elegante Datenverarbeitung mit Swift-Algorithms & Collections**
  - Pakete: **swift-algorithms 1.2.1** & **swift-collections 1.4.1**
  - Beim Zuweisen der Spione (`imposterIndices`) nutzen wir `.randomSample(count:)` aus `swift-algorithms` anstatt Arrays manuell zu shufflen und abzuschneiden.
  - Konsequente Nutzung von `OrderedSet` (aus `swift-collections`) für Spieler-Listen im Multiplayer, um deterministische Reihenfolgen bei allen Clients zu garantieren.
- **Schritt 3.2: Moderner Timer mit Swift-Async-Algorithms**
  - Paket: **swift-async-algorithms 1.1.3**
  - Der aktuelle Timer in `ImposterGameState.swift` (`AsyncTimerSequence`) wird in einen isolierten `TimerService` (Actor) verpackt, der über Swift 6 Features sicherer gestartet und gestoppt werden kann.
- **Schritt 3.3: Numerische Operationen (Fairness & Matchmaking)**
  - Paket: **swift-numerics 1.1.1**
  - Wenn die `FairnessPolicy` komplexere Strafen/Boni berechnet, können wir Swift Numerics einsetzen, um Float/Double Interpolationen sicherer zu machen.

## Phase 4: Animationen & Modernes UI
Um das Spiel visuell auf das Level von iOS 18+ zu heben, verbessern wir die UI-Übergänge.

- **Schritt 4.1: Pow für Magische Übergänge**
  - Paket: **Pow 1.0.6**
  - Einbau von fließenden `.transition(.movingParts...)` für das Aufdecken der Karten (Card Reveal Phase), Punktevergabe und den Übergang in die Spielphase. Das lässt die UI modern und organisch wirken.
- **Schritt 4.2: Zentralisiertes Lottie-Management**
  - Paket: **Lottie 4.6.0**
  - Refactoring von `LottieView` zu einem sauberen Wrapper, der den neuesten Lottie-Standard nutzt (z.B. mit asynchronem Laden und Caching). 

## Phase 5: Multiplayer & Code-Strukturierung (Klare Namen)
- **Schritt 5.1: Abstraktion des MPCHandlers**
  - Entkopplung von `ImposterMPCHandler` und `GameLogic`. Nutzung eines sauberen Protokolls (`MultiplayerServiceType`), um lokales und Netzwerk-Spiel leichter testen zu können.
- **Schritt 5.2: Namenskonventionen**
  - Eindeutige und einheitliche Namensgebung einführen (z.B. Prefix `Imposter...` konsequent für alle spielspezifischen Views verwenden oder ganz weglassen, da sie durch den Ordner `Games/Imposter` sowieso ge-namespaced sind).

---

### Nächste Schritte
Wenn du mit diesem Schlachtplan einverstanden bist, gib mir einfach das **"Go"**. 
Ich schlage vor, wir beginnen dann direkt mit **Phase 1: Architektur & Zustandstrennung**, indem wir `GameSettings` in dedizierte Stores und Router aufteilen.
