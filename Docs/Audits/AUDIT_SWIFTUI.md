# AUDIT: SwiftUI Architektur + Swift Language + Datenhaltung
## Phase 1.1 / 1.2 / 1.3 — Erstellungsdatum: 2026-04-12

> **Legende:**
> 🔴 KRITISCH — Muss sofort behoben werden (Bugs, Crashes, Data Loss)
> 🟠 HOCH — Vor Release beheben (Performance, falsche Patterns)
> 🟡 MITTEL — Nächster Sprint (Code-Qualität, Wartbarkeit)
> 🟢 NIEDRIG — Nice-to-have (Stil, Konventionen)

---

## ABSCHNITT 1: SWIFTUI ARCHITEKTUR

---

### 🔴 SW-01: Timer-Leak in ContentView — `MenuGameCard.onAppear`

**Datei:** `Games Collection/ContentView.swift:325`

**Problem:** `MenuGameCard` erstellt in `onAppear` einen `Timer.scheduledTimer` ohne eine Referenz zu speichern. Der Timer läuft **endlos weiter**, auch wenn die View off-screen geht oder das Spiel geöffnet ist. Das kostet CPU und Batterie dauerhaft.

```swift
// FEHLER in MenuGameCard.onAppear:
Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
    hourglassFlipped.toggle()
}
// Keine Referenz → Nie invalidiert → Leak
```

**Fix:** Timer als `@State` speichern und in `onDisappear` stoppen. Besser: `TimelineView` nutzen (bereits in SnowView so gelöst).

```swift
// KORREKT:
.task {
    while !Task.isCancelled {
        try? await Task.sleep(for: .seconds(2))
        hourglassFlipped.toggle()
    }
}
```

---

### 🔴 SW-02: Timer-Leaks in mehreren Views ohne gespeicherte Referenz

**Dateien:**
- `Games/Question/Views/Phases/QuestionsResultsPhaseView.swift:184` und `:413`
- `Games/Imposter/Views/WordGuessingView.swift:336`
- `Games/Bet Buddy/Components/HoldToConfirmButton.swift:133`

**Problem:** `Timer.scheduledTimer` wird erstellt aber die Rückgabe wird ignoriert. Timer läuft nach View-Dismiss weiter.

**Anzahl:** 4 bestätigte Leaks in Views.

**Fix:** Immer `@State private var timer: Timer?` oder besser `task { }` mit `Task.sleep` verwenden.

---

### 🔴 SW-03: `Color(hex:)` Extension nur in einem Game-File definiert, aber app-weit verwendet

**Definition:** `Games/Bet Buddy/Screens/BetBuddyLeaderboardView.swift:319`
**Verwendung auch in:** `Games Collection/MainSettingsView.swift:340`

**Problem:** Eine Extension die in einem Game-spezifischen File definiert ist, wird im App-Level (MainSettingsView) verwendet. Das ist eine falsche Dependency-Richtung. Wenn Bet Buddy jemals ausgelagert oder das File verschoben wird, bricht MainSettingsView.

**Fix:** `Color+Hex.swift` im Shared-Ordner erstellen, Extension dort definieren.

---

### 🟠 SW-04: `@StateObject` für Singletons — semantisch falsch

**Betroffene Dateien (6 Stellen):**
```
ContentView.swift:41        @StateObject private var statsManager = GlobalStatsManager.shared
MainSettingsView.swift:14   @StateObject private var playerManager = GlobalPlayerManager.shared
GlobalRecapView.swift:4     @StateObject private var statsManager = GlobalStatsManager.shared
MPCDebugView.swift:5        @StateObject private var mpc = MultipeerManager.shared
ImposterMultiplayerSheet:6  @StateObject private var mpc = MultipeerManager.shared
QuestionsMultiplayerSheet:13 @StateObject private var mpc = MultipeerManager.shared
```

**Problem:** `@StateObject` ist für Objekte gedacht, die der View **besitzt und erstellt**. Für Singletons ist `@ObservedObject` korrekt. In der Praxis passiert kein Crash, aber: bei Xcode-Warnungen und Swift 6 Strict Concurrency kann das zu Problemen führen.

**Fix:** Alle 6 Stellen zu `@ObservedObject` ändern.

---

### 🟠 SW-05: `applySetupBindings` — 5-fach verschachtelte `AnyView` Kette

**Datei:** `Games/Imposter/Views/GameSetupView.swift:159-241`

**Problem:** Die Funktion `applySetupBindings(to:)` kettet 5 `AnyView`-Wrapper hintereinander:
```swift
let step1 = AnyView(content.onChange(...))
let step2 = AnyView(step1.onChange(...))
let step3 = AnyView(step2.onChange(...))
let step4 = AnyView(step3.onChange(...))
let step5 = AnyView(step4.onAppear(...))
return AnyView(step5.safeAreaInset(...))
```

`AnyView` löscht Typinformationen → SwiftUI kann keine Differenzierung vornehmen → **alle Modifiers werden bei jeder Änderung neu ausgewertet**. Das ist einer der schwerwiegendsten Performance-Killer in SwiftUI.

**Fix:** `.onChange` Modifiers direkt in der `body`-Property oder einem dedizierten `ViewModifier` anwenden (ohne AnyView).

---

### 🟠 SW-06: `AnyView` in `GameRecommendation.targetView`

**Datei:** `Games Collection/GameRecommenderView.swift:94`

**Problem:**
```swift
struct GameRecommendation: Identifiable {
    let targetView: AnyView
}
```

`AnyView` in Datenmodellen ist ein Anti-Pattern. Jedes Mal wenn `recommendations` (als computed var) neu berechnet wird, werden neue Wrapper-Views erstellt. SwiftUI kann diese nicht mit vorherigen abgleichen.

**Fix:** Einen `GameDestination` Enum verwenden:
```swift
enum GameDestination { case betBuddy, imposter, timesUp, question }
```

---

### 🟠 SW-07: `recommendations` ist computed var — bei jeder Änderung vollständig neu berechnet

**Datei:** `Games Collection/GameRecommenderView.swift:286`

**Problem:** Das computed property `recommendations` enthält 100+ Zeilen Logik und erstellt mehrere `GameRecommendation`-Objekte inkl. `AnyView` Instanzen. Dieses wird bei **jeder State-Änderung** (`playerCount`, `mood`, `timeCategory`, `playMode`) vollständig neu ausgeführt.

**Fix:** Als `@State var recommendations: [GameRecommendation]` speichern und nur in `onChange` aktualisieren.

---

### 🟠 SW-08: Globales `isHapticsEnabled` Setting nicht mit Haptics-Managern verbunden

**Datei:** `Games Collection/MainSettingsView.swift:11`

**Problem:** Das Setting `@AppStorage("isHapticsEnabled")` existiert, wird aber von `ImposterHapticsManager` und `TimesUpHapticsManager` nicht gelesen. Die Haptics laufen immer, unabhängig vom Setting.

**Beweise:**
- `ImposterHapticsManager.swift` liest `isHapticsEnabled` nicht
- `TimesUpHapticsManager.swift` liest `isHapticsEnabled` nicht
- Bet Buddy `HapticsService` liest `isHapticsEnabled` nicht

**Fix:** Jeden HapticsManager so ändern, dass er das globale Setting prüft, oder einen einzigen zentralen `GlobalHapticsManager` erstellen.

---

### 🟠 SW-09: 127 veraltete `.cornerRadius()` Aufrufe

**Problem:** `.cornerRadius()` ist seit iOS 16 deprecated zugunsten von `.clipShape(RoundedRectangle(cornerRadius:, style: .continuous))`. In iOS 26 mit Liquid Glass Material hat das Auswirkungen, da Liquid Glass auf Shape-basiertes Clipping angewiesen ist.

**Verteilung über 33 Dateien**, größte Vorkommen:
- `Games Collection/GameRecommenderView.swift`: 11x
- `Games/TimesUp/Views/SettingsView.swift`: 7x
- `Games/Imposter/Views/ImposterCategoryDetailView.swift`: 5x

**Fix:** Alle `.cornerRadius(x)` durch `.clipShape(RoundedRectangle(cornerRadius: x, style: .continuous))` ersetzen. Für Views mit Background: `background(..., in: RoundedRectangle(cornerRadius: x, style: .continuous))`.

---

### 🟡 SW-10: 168 `print()` Statements in Production-Code

**Problem:** 24 Swift-Dateien enthalten `print()`. Das beeinträchtigt Performance (Logging ist synchron), und sensitive Informationen (Spielernamen, Roomcodes) erscheinen in Device-Logs.

**Größte Verursacher:**
- `MultipeerManager.swift`: 20 prints
- `TimesUpGameView.swift` (enthält Drawingcode)
- `AICategoryGenerator.swift`: 21 prints

**Fix:** Vor App Store Release alle `print()` entfernen oder durch `#if DEBUG print() #endif` ersetzen.

---

### 🟡 SW-11: 40+ `DispatchQueue.main.asyncAfter` — nicht Task-cancellable

**Problem:** Bei View-Dismiss laufen verzögerte Callbacks weiter und können auf deallokierten State zugreifen. Besonders kritisch in:
- `Games/TimesUp/Managers/GameManager.swift`: 12+ Stellen
- `Games/Question/Views/Phases/QuestionsResultsPhaseView.swift`: 8 Stellen

**Fix:** 
```swift
// ALT (nicht cancellable):
DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { self.state = .next }

// NEU (Task-cancellable):
Task {
    try await Task.sleep(for: .seconds(1.5))
    state = .next
}
```

---

### 🟡 SW-12: Doppelte `withAnimation` auf selber View (BetBuddyGameCard, ImposterGameCard)

**Datei:** `Games Collection/ContentView.swift:471, 621`

**Problem:** In `BetBuddyGameCard.onAppear` und `ImposterGameCard.onAppear` werden zwei separate `withAnimation(.easeInOut.repeatForever)` auf denselben View-State angewendet. Das kann zu Animation-Konflikten und unerwartetem Verhalten führen, besonders wenn einer der States die andere Animation beeinflusst.

---

### 🟢 SW-13: `SessionKingCard` definiert aber nie verwendet

**Datei:** `Games Collection/ContentView.swift:796`

**Problem:** `struct SessionKingCard: View` ist komplett implementiert (15+ Zeilen) aber wird an keiner Stelle im Projekt aufgerufen. Toter Code.

**Fix:** Entweder einbinden (z.B. im MainScreen wenn ein Session-König ermittelt wurde) oder löschen.

---

### 🟢 SW-14: `SnowParticle.id = UUID()` bei jeder Update-Runde

**Datei:** `Games Collection/ContentView.swift:789`

```swift
struct SnowParticle: Identifiable {
    var id = UUID()  // var statt let → wird bei Updates neu gesetzt?
```

`id` ist als `var` deklariert. In `updateParticles()` wird zwar nicht die `id` geändert, aber da es `var` ist, könnte das aus Versehen passieren. Als `let` deklarieren.

---

## ABSCHNITT 2: SWIFT LANGUAGE PATTERNS

---

### 🔴 SL-01: `GlobalPlayerManager.deinit` entfernt Observer — aber `deinit` wird bei Singleton nie aufgerufen

**Datei:** `Games Collection/Services/GlobalPlayerManager.swift:34`

```swift
deinit {
    NotificationCenter.default.removeObserver(self)
}
```

Da `GlobalPlayerManager` ein `static let shared` Singleton ist, wird `deinit` **nie aufgerufen**. Der Observer wird also nie deregistriert. Das ist zwar kein Leak (da das Objekt immer lebt), aber irreführender Code.

**Fix:** `deinit` entfernen. Falls sicher sein soll dass Notifications aufgeräumt werden: Verwende `NotificationCenter.default.addObserver(forName:...) { [weak self] }` mit `Cancellable`-Speicherung.

---

### 🔴 SL-02: Doppelte `ChallengeService` Instanziierung in `AppViewModel.init`

**Datei:** `Games/Bet Buddy/ViewModels/AppViewModel.swift:93, 141`

```swift
private let challengeService = ChallengeService()  // Zeile 93 — Property

// ... in init():
let service = ChallengeService()                    // Zeile 141 — ZWEITE Instanz!
let startResult = service.randomChallenge(...)
```

`ChallengeService` wird zweimal instanziiert — einmal als Property und einmal im init. Der lokale `service` in `init()` sollte `self.challengeService` verwenden.

---

### 🟠 SL-03: `MultipeerManager` session als `var` — Race Condition bei stop/start

**Datei:** `Games Collection/Services/MultipeerManager.swift:45, 283`

**Problem:** `private var session: MCSession?` wird in `setupSession()` neu erstellt. Bei schnellem `stop()` → `start()` kann ein bereits laufender Delegate-Callback (auf dem Background-Thread der MCSession) noch auf die alte Session verweisen, während `self.session` schon die neue ist.

---

### 🟠 SL-04: `MultipeerManager.broadcastLobbyState` — DispatchQueue.main statt @MainActor

**Datei:** `Games Collection/Services/MultipeerManager.swift:312`

```swift
// In @MainActor class — sollte nicht mehr DispatchQueue.main nutzen:
DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
    self.broadcastLobbyState()
}
```

Da die Klasse `@MainActor` ist, reicht `Task { await Task.sleep(for: .milliseconds(500)); broadcastLobbyState() }`.

---

### 🟠 SL-05: `UserDefaults`-Keys als Inline-Strings ohne Zentralisierung

**Problem:** Über das Projekt verteilt sind UserDefaults-Keys als String-Literale:
```
"betbuddy.groupCount", "betbuddy.timerSelection", "betbuddy.isTimerEnabled",
"betbuddy.isHintsEnabled", "betbuddy.isPartyMode", "betbuddy.isPenaltyEnabled",
"betbuddy.penaltyLevel", "betbuddy.selectedCategories",
"GlobalPlayers_V1", "GlobalStats_V1", "BetBuddy_GlobalStats_V1",
"mpc.playerId", "mpc.lastRoomCode", "myPlayerName", "selectedLanguageCode",
"useSystemLanguage", "isHapticsEnabled"
```

**Risiko:** Tippfehler, doppelte Keys, keine IDE-Unterstützung.

**Fix:** Enum mit statischen Keys:
```swift
enum StorageKeys {
    static let myPlayerName = "myPlayerName"
    static let isHapticsEnabled = "isHapticsEnabled"
    // ...
}
```

---

### 🟠 SL-06: `AppViewModel.init` Größe — 60 Zeilen, sehr schwer testbar

**Datei:** `Games/Bet Buddy/ViewModels/AppViewModel.swift:100-160`

Der `init()` von AppViewModel macht zu viel: lädt Settings, erstellt Groups, erstellt Challenge, lädt Stats, registriert NotificationCenter Observer. Das macht Unit Tests praktisch unmöglich.

**Fix:** Aufteilen in `loadSettings()`, `loadStats()`, `setupGroups()` private Methoden die vom init aufgerufen werden.

---

### 🟡 SL-07: `GlobalPlayerManager.iCloudDataDidUpdate` verwendet `DispatchQueue.main.async` in `@MainActor`-Klasse

**Datei:** `Games Collection/Services/GlobalPlayerManager.swift:106`

```swift
@objc private func iCloudDataDidUpdate(notification: NSNotification) {
    DispatchQueue.main.async { [weak self] in  // Unnötig in @MainActor class
```

In einer `@MainActor`-Klasse ist `DispatchQueue.main.async` redundant. Stattdessen: `Task { @MainActor in ... }`.

---

### 🟡 SL-08: `GlobalStatsManager` — `timesPlayed` wird bei Win + Participation doppelt erhöht

**Datei:** `Games Collection/Services/GlobalStatsManager.swift:41-62`

```swift
func recordWin(for playerName: String) {
    // sessionWins erhöhen
    updateStat(for: playerName) { stats in
        stats.wins += 1
        stats.timesPlayed += 1  // ← erhöht timesPlayed
    }
}

func recordParticipation(for playerName: String) {
    updateStat(for: playerName) { stats in
        stats.timesPlayed += 1  // ← erhöht timesPlayed NOCHMAL
    }
}
```

Wenn nach einem Win auch `recordParticipation` aufgerufen wird, wird `timesPlayed` doppelt gezählt. Die Win-Rate ist dann verfälscht.

---

### 🟢 SL-09: `isSoundEnabled` in `MainSettingsView` — `nonmutating set` computed property

**Datei:** `Games Collection/MainSettingsView.swift:25`

```swift
var isSoundEnabled: Bool {
    get { SoundManager.shared.isSoundEnabled }
    nonmutating set { SoundManager.shared.isSoundEnabled = newValue }
}
```

Das funktioniert, ist aber ungewöhnlich. Besser wäre `@ObservedObject private var soundManager = SoundManager.shared` mit `@Published var isSoundEnabled` im SoundManager.

---

### 🟢 SL-10: `accentColor` in iOS 26 — `.accentColor` ist deprecated

**Problem:** An mehreren Stellen wird `.tint(.accentColor)` oder `color: .accentColor` verwendet. In iOS 26 sollte immer `.tint(.blue)` oder eine spezifische Farbe verwendet werden.

---

## ABSCHNITT 3: DATENHALTUNG & PERSISTENZ

---

### 🔴 DA-01: Kein zentrales Datenhaltungs-Framework — 3 parallele Stats-Systeme

**Problem:** Das Projekt hat drei unabhängige Stats/Score-Systeme die nie synchronisiert werden:

| System | Datei | Persistenz | Scope |
|--------|-------|------------|-------|
| `GlobalStatsManager` | `GlobalStatsManager.swift` | UserDefaults `GlobalStats_V1` | Alle Games (Wins/Losses) |
| `AppViewModel.highlights` | `AppViewModel.swift` | UserDefaults `BetBuddy_GlobalStats_V1` | Nur Bet Buddy |
| `StatsService` (Imposter) | `StatsService.swift` | Vermutlich UserDefaults | Nur Imposter |

**Folge:** Ein Sieg in Bet Buddy wird in `AppViewModel.highlights` gespeichert, aber der Spieler erscheint nicht im `GlobalRecapView` (welcher `GlobalStatsManager` nutzt). Die "Session Recap" zeigt also **nicht alle Spiele**.

---

### 🔴 DA-02: iCloud Sync überschreibt lokale Änderungen ohne Merge

**Datei:** `Games Collection/Services/GlobalPlayerManager.swift:113`

```swift
// "Merge Logic: We simply take the cloud version as truth for simplicity in V1."
self.players = decoded  // Cloud überschreibt lokal komplett
```

Szenario: Gerät A ist offline, fügt 3 Spieler hinzu. Gerät B ist online, löscht 2 Spieler. Wenn Gerät A online geht, werden seine 3 neu hinzugefügten Spieler von der Cloud-Version überschrieben und sind weg.

**Fix für V2:** Merge-Strategie mit `id`-basiertem Abgleich:
```swift
// Spieler-IDs als Set → Union der IDs, Cloud hat Priorität bei Konflikten
```

---

### 🟠 DA-03: Keine SwiftData-Verwendung — alles in UserDefaults

**Problem:** Das gesamte Projekt speichert alle Daten in `UserDefaults`. UserDefaults ist für:
- Kleine Einstellungen (Bool, Int, String) gedacht
- **NICHT** für Arrays von Objekten, komplexe Graphen, oder große Datensätze

**Was aktuell in UserDefaults liegt:**
- Spieler-Liste (JSONEncoded Array of GlobalPlayer)
- Spieler-Statistiken (JSONEncoded Dictionary)
- Bet Buddy Highlights (JSONEncoded GameHighlights)
- Kategorie-Einstellungen

**Empfehlung:** SwiftData für `GlobalPlayer`, `GlobalPlayerStats`, `GameHighlights` einführen. UserDefaults nur für primitive Settings behalten.

---

### 🟠 DA-04: Keine Migrations-Strategie trotz Version-Suffix in Keys

**Problem:** Keys wie `"GlobalPlayers_V1"`, `"GlobalStats_V1"`, `"BetBuddy_GlobalStats_V1"` implizieren dass Migrationen geplant sind. Wenn sich das Datenmodell ändert und ein User ein Update installiert, werden die alten Daten einfach ignoriert (JSONDecoder fail → leere Daten). Keine Warnung, kein Migrate.

---

### 🟠 DA-05: Factory Reset löscht `UserDefaults` — aber `AppViewModel` im Speicher hält alte Werte

**Datei:** `Games Collection/Services/AppLifecycleManager.swift`

**Problem:** `factoryReset()` ruft `UserDefaults.standard.removePersistentDomain` auf, aber bereits instanziierte ViewModels (wie `AppViewModel`) haben die Werte in ihren `@Published` Properties. Ein App-Neustart ist nötig. Das wird durch `NotificationCenter.AppDidReset` teilweise gelöst, aber nicht für alle ViewModels.

---

### 🟠 DA-06: `MultipeerManager.playerId` UUID — geht bei Factory Reset verloren

**Datei:** `Games Collection/Services/MultipeerManager.swift:66-73`

Die Player-UUID wird in `UserDefaults.standard` gespeichert. Nach einem Factory Reset wird eine **neue UUID generiert**. Das bedeutet: Ein Spieler der nach einem Reset wieder dem selben Host-Raum beitritt, wird als neuer Spieler erkannt (andere UUID). Sein alter "Disconnect-Grace"-Slot im Host ist noch aktiv → Verwirrung.

---

### 🟡 DA-07: `@AppStorage` und `UserDefaults.standard` gemischt für denselben Key

**Problem:** `myPlayerName` wird sowohl über `@AppStorage("myPlayerName")` (in MainSettingsView) als auch über `UserDefaults.standard.string(forKey: "myPlayerName")` (in MultipeerManager.init) gelesen. Das funktioniert, ist aber inkonsistent und fehleranfällig.

---

### 🟡 DA-08: `playedChallengeIDs` in AppViewModel — nicht persistiert

**Datei:** `Games/Bet Buddy/ViewModels/AppViewModel.swift:90`

```swift
private var playedChallengeIDs: Set<UUID> = []
```

Diese Set wird bei App-Neustart zurückgesetzt. Das bedeutet: Es können wieder die zuletzt gespielten Challenges erscheinen. Vermutlich gewollt, aber nirgendwo dokumentiert.

---

### 🟢 DA-09: `GroupNamePersistence` — separater Persistence-Layer für Gruppe-Namen

**Datei:** `Games/Bet Buddy/Services/GroupNamePersistence.swift`

Gruppen-Namen werden über einen dedizierten Service gespeichert (separat von AppViewModel). Das ist gut strukturiert, aber `GroupNamePersistence` sollte den gleichen Factory-Reset-Observer wie `AppViewModel` haben.

---

## ZUSAMMENFASSUNG PHASE 1.1–1.3

| Priorität | Anzahl | Beschreibung |
|-----------|--------|--------------|
| 🔴 Kritisch | 6 | Timer-Leaks, Color-Extension Dep., Datenverlust-Risiko |
| 🟠 Hoch | 12 | StateObject-Missbrauch, AnyView-Ketten, Haptics-Disconnect, deprecated APIs |
| 🟡 Mittel | 9 | DispatchQueue-Patterns, Keys-Zentralisierung, Stats-Synchronisation |
| 🟢 Niedrig | 4 | Tote Views, var vs let, Konventionen |
| **TOTAL** | **31** | |

---

## NÄCHSTE SCHRITTE (nach User-Freigabe)

1. **Sofort:** Timer-Leaks beheben (SW-01, SW-02) — Batterie-kritisch
2. **Vor Release:** `.cornerRadius` Migration (SW-09) — iOS 26 Liquid Glass
3. **Sprint 1:** Color-Extension zentralisieren, `@StateObject` → `@ObservedObject`
4. **Sprint 2:** SwiftData Einführung (DA-03)
5. **Sprint 3:** Stats-Systeme vereinheitlichen (DA-01)
