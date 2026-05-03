# Spy Audit: Swift 6 / iOS 26 / Package-Einsatz

Stand: 2026-02  
Scope: `Games Collection/Games/Imposter` mit Fokus auf die Spy-/Imposter-Flows

## Kurzfazit

Der `Spy`-Teil ist funktional bereits modern genug, um auf iOS 26 zu laufen, nutzt aber die Plattform noch nicht konsequent nach heutigem Stand aus. Die größten Hebel sind nicht neue Features, sondern:

- Migration von `ObservableObject`/`@Published` auf `@Observable`
- Ersetzen von `Timer`/`DispatchQueue.main.asyncAfter` in UI-nahen Flows durch Swift-Concurrency
- selektiver Einsatz von `Pow` für Reveal-/Dismiss-/Result-Animationen
- selektiver Einsatz von `swift-collections` und `swift-async-algorithms` in Multiplayer-, Hint- und Timer-Logik
- Modernisierung der Foundation Models Nutzung auf strukturierte Ausgaben statt JSON-Parsing per String

Von den installierten Packages ist für `Spy` aktuell nur `Lottie` real im Einsatz. Die übrigen Pakete sind entweder gar nicht im `Imposter`-Spiel genutzt oder dort nur indirekt sinnvoll.

## Verifizierter Ist-Zustand

### Bereits sinnvoll im Spy-Spiel

- `Lottie` ist bereits sauber eingebunden über [SharedLottieView.swift](/Users/keno/Apps/App%20Backup/Games%20Collection/Games%20Collection/Shared/SharedLottieView.swift:1) und verwendet in:
  - [SpyCardExtension.swift](/Users/keno/Apps/App%20Backup/Games%20Collection/Games%20Collection/Games/Imposter/Views/SpyCardExtension.swift:172)
  - [GamePlayView.swift](/Users/keno/Apps/App%20Backup/Games%20Collection/Games%20Collection/Games/Imposter/Views/GamePlayView.swift:573)
- `FoundationModels` wird bereits genutzt in:
  - [AIService.swift](/Users/keno/Apps/App%20Backup/Games%20Collection/Games%20Collection/Games/Imposter/Services/AIService.swift:10)
  - [AIService+Hints.swift](/Users/keno/Apps/App%20Backup/Games%20Collection/Games%20Collection/Games/Imposter/Services/AIService+Hints.swift:2)

### Im Spy-Spiel aktuell nicht genutzt

- `Pow`
- `SFSafeSymbols`
- `swift-algorithms`
- `swift-async-algorithms`
- `swift-collections`

### Architekturstand

- Das Spiel nutzt weiterhin breit `ObservableObject` / `@Published`, z. B.:
  - [GameSettings.swift](/Users/keno/Apps/App%20Backup/Games%20Collection/Games%20Collection/Games/Imposter/Models/GameSettings.swift:11)
  - [GameLogic.swift](/Users/keno/Apps/App%20Backup/Games%20Collection/Games%20Collection/Games/Imposter/Models/GameLogic.swift:13)
  - [HintService.swift](/Users/keno/Apps/App%20Backup/Games%20Collection/Games%20Collection/Games/Imposter/Services/HintService.swift:13)
- In SwiftUI-Views wird entsprechend noch viel `@ObservedObject` und `@EnvironmentObject` genutzt, z. B.:
  - [SpyOptionsView.swift](/Users/keno/Apps/App%20Backup/Games%20Collection/Games%20Collection/Games/Imposter/Views/Sheets/SpyOptionsView.swift:5)
  - [ExpandableSpyOptionsSection.swift](/Users/keno/Apps/App%20Backup/Games%20Collection/Games%20Collection/Games/Imposter/Views/Components/ExpandableSpyOptionsSection.swift:11)

## Audit nach Paket

## 1. `Lottie`

### Empfehlung

Behalten. Das ist im `Spy`-Spiel das am klarsten gerechtfertigte Paket.

### Gute Einsatzstellen heute

- Fingerprint-/Scanner-Reveal auf der Kartenrückseite  
  [SpyCardExtension.swift](/Users/keno/Apps/App%20Backup/Games%20Collection/Games%20Collection/Games/Imposter/Views/SpyCardExtension.swift:168)
- Multiplayer-Waiting/Radar  
  [GamePlayView.swift](/Users/keno/Apps/App%20Backup/Games%20Collection/Games%20Collection/Games/Imposter/Views/GamePlayView.swift:571)

### Was ich verbessern würde

- `Lottie` nur für klar erkennbare “hero moments” nutzen, nicht für normale UI-Zustände.
- Scanner-Reveal mit SwiftUI-State statt `Timer`-basierter Fortschrittslogik orchestrieren.
- Für einfache Statuswechsel eher native SwiftUI-Animationen statt weiterer Lottie-Dateien.

### Konkrete nächste Kandidaten im Spy-Spiel

- kurzer “target locked” Effekt in `SpyShootoutView`
- kurze “role revealed” Celebration beim Flip
- optionales “mission accepted” One-shot im Rollenmodus

## 2. `Pow`

### Empfehlung

Im `Spy`-Spiel sehr sinnvoll, aktuell aber ungenutzt.

### Wo Pow den meisten Wert bringt

- Karten-Flip-Folge und Dismiss-Moment in [SpyCardExtension.swift](/Users/keno/Apps/App%20Backup/Games%20Collection/Games%20Collection/Games/Imposter/Views/SpyCardExtension.swift:35)
- Auswahl/Bestätigung in [SpyShootoutView.swift](/Users/keno/Apps/App%20Backup/Games%20Collection/Games%20Collection/Games/Imposter/Views/Sheets/SpyShootoutView.swift:64)
- Tab-/Segment-Wechsel in [SpyOptionsView.swift](/Users/keno/Apps/App%20Backup/Games%20Collection/Games%20Collection/Games/Imposter/Views/Sheets/SpyOptionsView.swift:53)
- Result-/Timeout-/Voting-Highlights

### Sinnvolle Ersetzungen

- mehrere manuelle `.scaleEffect`, `.opacity`, `.transition`-Kombinationen können durch klarere Pow-Transitions ersetzt werden
- Pow passt besonders gut zu:
  - reveal
  - pulse
  - confirmation
  - removal/dismiss

### Priorität

`Hoch` für UI-Polish, `niedrig` für funktionale Modernisierung.

## 3. `SFSafeSymbols`

### Empfehlung

Für `Spy` nur optional. Kein Muss auf iOS 26.

### Warum

Im `Spy`-Code werden viele SF Symbols als rohe Strings verwendet, z. B.:

- `"scope"` in [SpyShootoutView.swift](/Users/keno/Apps/App%20Backup/Games%20Collection/Games%20Collection/Games/Imposter/Views/Sheets/SpyShootoutView.swift:95)
- `"touchid"` in [SpyCardExtension.swift](/Users/keno/Apps/App%20Backup/Games%20Collection/Games%20Collection/Games/Imposter/Views/SpyCardExtension.swift:183)
- `"lightbulb.max.fill"` in [SpyCardExtension.swift](/Users/keno/Apps/App%20Backup/Games%20Collection/Games%20Collection/Games/Imposter/Views/SpyCardExtension.swift:583)

Mit `SFSafeSymbols` bekommst du Typsicherheit und weniger Tippfehler. Auf iOS 26 ist das weiterhin angenehm, aber kein struktureller Gewinn.

### Wo ich es einsetzen würde

- nur in zentralen Symbol-Mappings:
  - `RoleType.icon`
  - `GameCard.cardIcon`
  - wiederkehrende HUD-/Voting-/Spy-Symbole

### Wo ich es nicht breit refactoren würde

- nicht zuerst in allen Views
- erst dann, wenn du ohnehin Symbol-Mappings aufräumst

## 4. `swift-algorithms`

### Empfehlung

Im `Spy`-Spiel punktuell nützlich, aber kein dringender Einbau.

### Gute Kandidaten

- Rollenverteilung / Spielerpaarungen / Gruppenbildung in [GameLogic.swift](/Users/keno/Apps/App%20Backup/Games%20Collection/Games%20Collection/Games/Imposter/Models/GameLogic.swift:289)
- Hint-/Fallback-Auswahl
- deduplizierte oder geregelte Sequenzen bei Rollen, Challenges und Voting-Ergebnissen

### Konkrete sinnvolle APIs

- `chunked` oder `chunks`  
  Ihr habt bereits eine eigene Variante in `Array+Chunked.swift`; die könnte mittelfristig durch das Paket ersetzt werden, wenn ihr Konsistenz wollt.
- `combinations`  
  nützlich für faire Paarbildung, Twins, Team-Checks
- `uniqued`  
  nützlich in Hint-/Role-/Player-Auswahl

### Priorität

`Mittel`. Nur dort einsetzen, wo die Logik wirklich lesbarer wird.

## 5. `swift-async-algorithms`

### Empfehlung

Das ist im `Spy`-Spiel das interessanteste noch ungenutzte Paket für echte Modernisierung.

### Beste Einsatzstellen

- Hint-Intervall statt `Timer.scheduledTimer`
  - [HintService.swift](/Users/keno/Apps/App%20Backup/Games%20Collection/Games%20Collection/Games/Imposter/Services/HintService.swift:80)
- Game-Timer / Tick-Sync statt klassischem `Timer`
  - [GameLogic.swift](/Users/keno/Apps/App%20Backup/Games%20Collection/Games%20Collection/Games/Imposter/Models/GameLogic.swift:573)
- zeitgesteuerte UI-Delays statt `DispatchQueue.main.asyncAfter`
  - [SpyCardExtension.swift](/Users/keno/Apps/App%20Backup/Games%20Collection/Games%20Collection/Games/Imposter/Views/SpyCardExtension.swift:95)
  - [HintService.swift](/Users/keno/Apps/App%20Backup/Games%20Collection/Games%20Collection/Games/Imposter/Services/HintService.swift:253)

### Warum das modern ist

Für Swift 6 / iOS 26 ist der bessere Stil:

- strukturierte `Task`-basierte Abläufe
- Cancellation statt manuellem Invalidieren von Timern
- Async-Sequenzen statt verstreuter Callback-/Timer-Logik

### Konkreter Nutzen

- weniger Race-Conditions
- leichter testbar
- sauberer mit Swift-6-Concurrency
- weniger UIKit-/RunLoop-Denken in SwiftUI-naher Logik

### Priorität

`Sehr hoch` für echte Modernisierung.

## 6. `swift-collections`

### Empfehlung

Sinnvoll für `Spy`, aber gezielt. Nicht überall.

### Beste Kandidaten

- Voting-Tally / stabile Anzeige-Reihenfolge
- Multiplayer-Event-Historie
- recent hints / recent moderator events
- pending acknowledgements / reveal progress / rematch responses

### Konkrete Typen

- `OrderedDictionary`
  - für Voting-Resultate und stabile Reihenfolgen
- `OrderedSet`
  - für eindeutige, aber geordnete Spieler- oder Kategorieauswahlen
- `Deque`
  - für kleine Event- oder Hint-Historien

### Wo es heute passt

- `pendingRoleAcks`, `rematchResponses`, `multiplayerVoteTally`
  in [GameLogic.swift](/Users/keno/Apps/App%20Backup/Games%20Collection/Games%20Collection/Games/Imposter/Models/GameLogic.swift:21)
- `activeHints` / `hintHistory`
  in [HintService.swift](/Users/keno/Apps/App%20Backup/Games%20Collection/Games%20Collection/Games/Imposter/Services/HintService.swift:16)

### Priorität

`Mittel`. Gut für Datenstrukturen, aber nicht der erste Modernisierungsschritt.

## Swift-6- und iOS-26-Modernisierung

## 1. Observation-Migration

### Empfehlung

`GameSettings`, `GameLogic`, `HintService`, `AIService` mittelfristig auf `@Observable` umstellen.

### Warum

Apple empfiehlt für moderne SwiftUI-Apps mit iOS 17+ Observation statt `ObservableObject`. Auf iOS 26 gibt es keinen Grund, neue Arbeit noch auf `@Published` aufzubauen.

### Besonders relevant für Spy

- [GameSettings.swift](/Users/keno/Apps/App%20Backup/Games%20Collection/Games%20Collection/Games/Imposter/Models/GameSettings.swift:11)
- [GameLogic.swift](/Users/keno/Apps/App%20Backup/Games%20Collection/Games%20Collection/Games/Imposter/Models/GameLogic.swift:13)
- [HintService.swift](/Users/keno/Apps/App%20Backup/Games%20Collection/Games%20Collection/Games/Imposter/Services/HintService.swift:13)

### Zielbild

- `@Observable` Modelle
- `@Environment(GameSettings.self)` statt `@EnvironmentObject`
- `@Bindable` in Edit-/Settings-Views

### Priorität

`Sehr hoch`.

## 2. Timer/Delay-Modernisierung

### Aktuell alt wirkende Stellen

- `Timer.scheduledTimer` in:
  - [SpyCardExtension.swift](/Users/keno/Apps/App%20Backup/Games%20Collection/Games%20Collection/Games/Imposter/Views/SpyCardExtension.swift:243)
  - [GameLogic.swift](/Users/keno/Apps/App%20Backup/Games%20Collection/Games%20Collection/Games/Imposter/Models/GameLogic.swift:580)
  - [HintService.swift](/Users/keno/Apps/App%20Backup/Games%20Collection/Games%20Collection/Games/Imposter/Services/HintService.swift:82)
- `DispatchQueue.main.asyncAfter` in:
  - [SpyCardExtension.swift](/Users/keno/Apps/App%20Backup/Games%20Collection/Games%20Collection/Games/Imposter/Views/SpyCardExtension.swift:95)
  - [SpyCardExtension.swift](/Users/keno/Apps/App%20Backup/Games%20Collection/Games%20Collection/Games/Imposter/Views/SpyCardExtension.swift:293)
  - [HintService.swift](/Users/keno/Apps/App%20Backup/Games%20Collection/Games%20Collection/Games/Imposter/Services/HintService.swift:253)

### Empfehlung

- UI-nahe Delays auf `Task.sleep(for:)`
- länger laufende Ticks auf Async-Sequenzen
- Cancellation explizit modellieren

### Priorität

`Sehr hoch`.

## 3. Haptics in SwiftUI-Screens

### Aktuell

Viele Views lösen `UIImpactFeedbackGenerator` direkt aus, z. B.:

- [SpyCardExtension.swift](/Users/keno/Apps/App%20Backup/Games%20Collection/Games%20Collection/Games/Imposter/Views/SpyCardExtension.swift:115)
- [SpyShootoutView.swift](/Users/keno/Apps/App%20Backup/Games%20Collection/Games%20Collection/Games/Imposter/Views/Sheets/SpyShootoutView.swift:72) indirekt per Auswahlfluss

### Empfehlung

In reinen SwiftUI-Views eher `sensoryFeedback` verwenden und nur den spezialisierten Haptik-Manager für komplexe Pattern behalten.

### Priorität

`Mittel bis hoch`.

## 4. Foundation Models Modernisierung

### Aktuell

Die AI-Nutzung ist gut gedacht, aber technisch noch halb “erste Generation”:

- String-Prompt
- JSON als Text
- manuelles Extrahieren mit `{...}` oder `[...]`
  - [AIService+Hints.swift](/Users/keno/Apps/App%20Backup/Games%20Collection/Games%20Collection/Games/Imposter/Services/AIService+Hints.swift:175)
  - [AIService+Hints.swift](/Users/keno/Apps/App%20Backup/Games%20Collection/Games%20Collection/Games/Imposter/Services/AIService+Hints.swift:279)

### Empfehlung

Für iOS 26 auf guided generation umstellen:

- `@Generable`-Typen für `GameContent`
- strukturierte Ausgaben statt String-JSON
- Sessions knapper halten
- Verfügbarkeit granularer behandeln

### Zusätzlich wichtig

Apple hat Foundation Models im Februar 2026 erneut aktualisiert. Prompts sollten deshalb gegen die aktuelle Modellversion getestet werden, besonders bei strengem Format-Output.

### Priorität

`Sehr hoch`.

## 5. SwiftUI-Interaktionsmodell

### Positiv

- `NavigationView` scheint im `Spy`-Code nicht mehr verwendet zu werden
- `onChange` wird bereits in moderner no-argument Form verwendet, z. B.:
  - [SpyOptionsView.swift](/Users/keno/Apps/App%20Backup/Games%20Collection/Games%20Collection/Games/Imposter/Views/Sheets/SpyOptionsView.swift:59)

### Verbesserbar

- in einigen Views werden Taps noch eher wie “freie Gesten” behandelt, obwohl `Button` semantisch besser wäre
- das betrifft besonders dismiss/select/reveal-nahe Flows in `SpyCardExtension`

### Priorität

`Mittel`.

## Was ich im Spy-Spiel konkret einbauen würde

## Sofort sinnvoll

1. `Pow` für:
   - Card reveal success
   - target lock
   - voting/result emphasis

2. `swift-async-algorithms` für:
   - Hint-Timer
   - Reveal/scan progression
   - Multiplayer countdown/tick handling

3. `swift-collections` für:
   - vote tally
   - reveal ack order
   - recent event history

## Nur bei passender Refactor-Runde

1. `SFSafeSymbols`
2. `swift-algorithms`

## Nicht als Selbstzweck

- Mehr `Lottie` nur weil das Paket da ist
- blindes Ersetzen aller Arrays/Sets durch Collection-Typen

## Priorisierte Reihenfolge

## Phase 1

- Observation-Migration
- Timer/Delay-Migration auf Concurrency
- Foundation Models structured output

## Phase 2

- `Pow` für Spy-UI-Polish
- `swift-collections` für Voting/History/Multiplayer-State

## Phase 3

- selektive `SFSafeSymbols`-Einführung
- `swift-algorithms` dort, wo Logik spürbar klarer wird

## Klare Empfehlungen pro Paket

| Paket | Für Spy jetzt? | Empfehlung |
|---|---:|---|
| `Lottie` | Ja | behalten, gezielt für hero moments |
| `Pow` | Ja | als nächstes einbauen |
| `SFSafeSymbols` | Eher optional | nur für zentrale Symbol-Mappings |
| `swift-algorithms` | Teilweise | punktuell bei Auswahl-/Gruppenlogik |
| `swift-async-algorithms` | Ja | hoher Mehrwert, aktiv nutzen |
| `swift-collections` | Ja | gezielt für Voting/History/Multiplayer-State |

## Endbewertung

Wenn das Ziel wirklich `Swift 6 + iOS 26 + neueste APIs + moderne Code-Variante` ist, dann würde ich für `Spy` nicht zuerst optisch, sondern in dieser Reihenfolge modernisieren:

1. Observation
2. Async/Concurrency statt Timer/DispatchQueue
3. Foundation Models structured generation
4. Pow für UI-Finish
5. Collections/Algorithms nur gezielt

Damit bekommst du den größten realen Gewinn bei Wartbarkeit, Swift-6-Sicherheit, moderner Apple-API-Nutzung und Zukunftsfähigkeit.

## Verifizierte Apple-Referenzen

- SwiftUI: `Migrating from the Observable Object protocol to the Observable macro`
- SwiftUI: `Managing model data in your app`
- SwiftUI: `Migrating to new navigation types`
- SwiftUI: `Unifying your app’s animations`
- Foundation Models: `Generating content and performing tasks with Foundation Models`
- Foundation Models: `Generating Swift data structures with guided generation`
- Foundation Models Updates: `February 2026`
