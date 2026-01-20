# CLAUDE.md

Diese Datei bietet Anleitungen für Claude Code (claude.ai/code) bei der Arbeit mit diesem Repository.

## Zusammenarbeit & Workflow

### Kommunikationsregeln
- **Sprache:** Die gesamte Kommunikation erfolgt ausschließlich auf **Deutsch**.
- **Rückfragen:** Bei Unklarheiten oder zur besseren Einschätzung von Features muss die KI proaktiv Fragen stellen.
- **Transparenz:** Entscheidungen und Code-Änderungen müssen kurz begründet werden.

### Phasenbasierte Entwicklung
Bei komplexeren Aufgaben oder neuen Features wird zwingend nach folgendem Prozess vorgegangen:
1. **Phasenplan erstellen:** Vor der Umsetzung wird ein klarer Plan mit nummerierten Phasen (z.B. Phase 1, 2, 3) präsentiert.
2. **Sequenzielle Abarbeitung:** Es wird immer nur **eine Phase nach der anderen** bearbeitet.
3. **Freigabe-Stopp:** Nach jeder abgeschlossenen Phase wartet die KI auf ein explizites **"OK"** des Nutzers, bevor die nächste Phase begonnen wird.

### Abschluss & Deployment
- **GitHub-Check:** Sobald alle Phasen eines Projekts oder Features komplett abgeschlossen sind, fragt die KI den Nutzer aktiv: *"Soll das Ergebnis nun auf GitHub hochgeladen werden?"*

### Lokalisierung & Texte
- Da die App primär auf Deutsch ist, aber Englisch unterstützt, muss bei jedem neuen Feature oder Text-Element sichergestellt werden, dass sowohl die deutsche als auch die englische Übersetzung in den entsprechenden `Localizable.strings` Dateien (oder via String Catalogs) vorhanden ist.

## Projekt-Übersicht

Eine SwiftUI-basierte iOS Party-Games-Collection-App mit 4 Multiplayer-Spielen:
- **Imposter**: Spionage-/Täuschungsspiel (finde den Imposter unter den Spielern)
- **Question** (Lügner): Finde den Lügner, der andere Informationen hat
- **Time's Up**: Scharade/Wörter-raten-Spiel mit Zeichen-Unterstützung
- **Bet Buddy**: Wett- und Challenge-Spiel

Die App legt Wert auf lokales Multiplayer via Apple MultipeerConnectivity, Dark-Mode-Ästhetik mit Neon-Gradienten und konsistente UX über alle Spiele hinweg.

## Build & Run Befehle

### Projekt bauen
```bash
# Build für Simulator (Debug)
xcodebuild -scheme "Games Collection" -configuration Debug -sdk iphonesimulator

# Build für Gerät (Release)
xcodebuild -scheme "Games Collection" -configuration Release -sdk iphoneos

# Build-Ordner bereinigen
xcodebuild clean -scheme "Games Collection"
```

### In Xcode ausführen
`Games Collection.xcodeproj` in Xcode öffnen und direkt ausführen. Das Projekt hat zwei Schemes:
- **Games Collection**: Standard-Build
- **Games Collection ohne Debug**: Build ohne Debug-Symbole

### Testing
**Hinweis**: Dieses Projekt hat aktuell keine automatisierten Tests. Alle Tests erfolgen manuell.

## High-Level Architektur

### Projekt-Struktur
```
Games Collection/
├── Games Collection/           # Haupt-App & gemeinsame Infrastruktur
│   ├── Games_CollectionApp.swift    # App-Einstiegspunkt (@main)
│   ├── ContentView.swift            # Home-Screen mit Spiele-Grid
│   ├── Services/                    # Globale Singletons (Manager)
│   ├── Shared/                      # Wiederverwendbare UI-Komponenten
│   └── Multiplayer/                 # MPC-Views & Utilities
│
└── Games/                      # Einzelne Spiel-Module
    ├── Imposter/
    ├── Question/
    ├── TimesUp/
    └── Bet Buddy/
```

### Spiel-Modul-Pattern
Jedes Spiel folgt dieser Struktur:
```
GameName/
├── [GameName]Wrapper.swift    # Einstiegspunkt (erstellt ViewModel)
├── Models/                    # Datenstrukturen (Codable, Identifiable)
├── Views/ oder Screens/       # SwiftUI-Views
├── Services/ oder Managers/   # Business-Logik & externe Integrationen
├── ViewModels/                # @ObservableObject State-Management
└── Resources/                 # JSON-Daten, Sounds, Themes
```

**Entry Flow**: `ContentView` → Button-Tap → `.fullScreenCover` präsentiert `GameWrapper` → Wrapper erstellt `@StateObject ViewModel` → Übergibt an Root-View des Spiels

**Exit Flow**: Spiele werden über den Zurück-Button beendet, der `@Environment(\.dismiss)` aufruft. Es sollte kein separater X-Button hinzugefügt werden.

### State Management (Drei-Ebenen-Pattern)

1. **Globale Singletons** (`@MainActor` mit `.shared`):
   - `MultipeerManager`: Multiplayer-Netzwerk
   - `GlobalStatsManager`: Spielübergreifende Spieler-Statistiken & Session-Tracking
   - `GlobalPlayerManager`: Spielernamen-Registry (iCloud-synchronisiert)
   - `AppLifecycleManager`: Crash-Erkennung & Factory-Reset
   - `SoundManager`: Audio-Wiedergabe
   - `ExternalDisplayManager`: TV/externer Bildschirm-Support

2. **Spielspezifische ViewModels**:
   - **Imposter**: `GameSettings` (ObservableObject)
   - **Bet Buddy**: `AppViewModel`
   - **TimesUp**: `CategoryManager`, `GameManager`
   - **Question**: `AppModel`, `QuestionsEngine`

3. **View State**: Views nutzen `@StateObject`, `@ObservedObject` oder `@EnvironmentObject` für Injection

**Datenfluss**: User-Aktion → View → ViewModel-Methode → Model-Update → `@Published`-Änderungen → View re-rendert

### Multiplayer-Architektur (MultipeerConnectivity)

**Kern-Komponente**: `MultipeerManager` (Singleton) verwaltet Peer-Discovery, Sessions und Verbindungen.

**Raum-Code-System**: Hosts senden einen 4-stelligen Raum-Code in den Discovery-Infos; Peers filtern nach passendem Code.

**Nachrichten-Protokoll**:
```swift
struct MPCMessage: Codable {
    let type: String      // Event-Identifier (z.B. "IMPOSTER_ROLE_ASSIGNMENT")
    let payload: Data?    // JSON-kodierte Spiel-Daten
}
```

**Event-Typen** (definiert in `MPCEventTypes.swift`):
- Global: `LOBBY_UPDATE`, `GAME_START`, `GAME_ABORT`
- Spielspezifisch: Namespaced wie `IMPOSTER_*`, `TIMESUP_*`

**Multiplayer-Ablauf**:
1. Host erstellt Raum → Sendet Code
2. Peers entdecken & beitreten → Lobby-Sync
3. Host konfiguriert Spiel → Sendet Start
4. Rollen-Zuweisungen werden individuell gesendet (via `sendToSpecificPeer`)
5. Spiel-Events werden synchronisiert (`sendToAll`)
6. Abstimmung: Stimmen sammeln → auszählen → Ergebnis senden
7. Rematch-Verhandlung

**Wichtige Features**:
- **Fairness-System**: Verhindert, dass Spieler wiederholt Imposter/Lügner sind
- **Rejoin-Support**: 30-Sekunden-Kulanzzeit für Wiederverbindung
- **Zeit-Sync**: Ping-Pong-Protokoll zur Uhr-Synchronisation
- **Sanfte Trennung**: Spieler werden als "disconnected" markiert, aber nicht sofort entfernt

**Aktueller Support**: Nur **Imposter** hat volle MPC-Integration. Framework ist bereit für andere Spiele.

### Kategorie-/Challenge-Management

Alle Spiele nutzen ein Kategorie-System für Wortlisten/Challenges:

**Kategorie-Typen**:
- **Default**: Eingebaut, nur lesbar
- **Custom**: Nutzer-erstellt, editierbar
- **AI-Generated**: Via Claude API (`AIService`)

**Content-Ratings**: Allgemein vs. 18+ Filterung

**Persistierung**: JSON-Encoding zu `UserDefaults` oder Documents-Ordner

**Gemeinsames Pattern**:
- Zugriff über 📂-Icon im Spiel-Header
- Listenansicht mit Hinzufügen (+), Bearbeiten (✏️), Löschen (🗑️) Aktionen
- Standard-Kategorien mit 🔒-Icon gesperrt
- Detail-Ansicht über `NavigationLink` geöffnet

### Design-System (DESIGN_GUIDELINES.md)

**Alle Spiele MÜSSEN diese Regeln befolgen**:

1. **Navigation**:
   - Kein Hauptmenü; Spiele starten direkt im Setup-Screen
   - `NavigationStack` für In-Game-Navigation
   - Standard-Header: Zurück-Button (links) + 🏆📂⚙️❓ Icons (rechts, 36×36pt Kreise)

2. **Visueller Stil**:
   - Nur Dark Mode
   - Dunkle `LinearGradient`-Hintergründe (Neon-Akzente)
   - `.ultraThinMaterial` Glaseffekte für Karten
   - Container-Eckenradius: 22pt
   - Button-Eckenradius: 18pt (Zeilen) oder `Capsule()` (primäre Aktionen)

3. **Primärer Button** (Spiel starten):
   - `Capsule()`-Form mit Gradient
   - Positioniert 32pt vom unteren Rand
   - `.padding(.vertical, 16)` oder 18

4. **Haptik**:
   - `.light` für Toggles/Auswahl
   - `.medium` für wichtige Aktionen (Start, Speichern)

5. **Farben**: Jedes Spiel hat einen einzigartigen Gradient (z.B. rot/pink für Imposter, orange/rot für Time's Up)

### Lokalisierung

**Sprachen**: Deutsch (primär) + Englisch

**Implementierung**:
- `@AppStorage("selectedLanguageCode")` + `useSystemLanguage`-Toggle
- Alle UI-Texte nutzen `LocalizedStringKey`
- Dynamisches Umschalten via `Games_CollectionApp.swift` mit `.environment(\.locale, activeLocale)`

### AI-Integration (Claude API)

**Service**: `AIService` in `Games Collection/Services/`

**Verwendung**:
- **Imposter**: Dynamische Hints, Rollen-Generierung, Wort-Vorschläge
- **TimesUp**: Kategorie-Generierung, Begriff-Übersetzung

**Pattern**: Async/await mit Error-Handling

### Persistierungs-Strategie

- **UserDefaults**: Einstellungen, kleine Daten (Scores, Präferenzen)
- **Documents Directory**: Größere JSON-Dateien (eigene Kategorien)
- **iCloud Key-Value Store**: Spieler-Sync (`GlobalPlayerManager`)
- **Kein CoreData**: Reiner Codable/JSON-Ansatz

### External Display Support

**Zweck**: Party-Game-Anzeige auf TV

**Komponenten**:
- `ExternalDisplayManager`: Erkennt externe Bildschirme
- `TVRootView`: Separate UI für externe Anzeige
- Nutzt moderne UIScene-API

## Häufige Patterns & Konventionen

### Namenskonventionen
- **Dateien**: PascalCase (z.B. `GameSetupView.swift`)
- **Manager**: `[Domain]Manager` (z.B. `CategoryManager`)
- **Services**: `[Domain]Service` (z.B. `AIService`)
- **ViewModels**: `AppViewModel` oder `[Game]ViewModel`
- **Wrapper**: `[GameName]Wrapper` für Einstiegspunkte

### Geteilte Komponenten (Games Collection/Shared/)
- `InfoTickerView`: Animierter scrollender Stats-Ticker
- `GlobalRecapView`: Session-Zusammenfassung/Leaderboard
- `MPCDebugView`: Multiplayer-Diagnose
- `OnboardingView`: Erstnutzer-Willkommen

### Abhängigkeiten
- **Lottie** (4.6.0): Animations-Bibliothek (via SPM)

## Kritische Dateien zum Verständnis

| Datei | Zweck |
|-------|-------|
| `Games Collection/ContentView.swift` | Spiel-Launcher mit 4 Spiel-Buttons |
| `Games Collection/Services/MultipeerManager.swift` | Multiplayer-Netzwerk-Kern |
| `Games Collection/Services/GlobalStatsManager.swift` | Spielübergreifendes Statistik-Tracking |
| `Games/[Game]/[Game]Wrapper.swift` | Einstiegs-Pattern für jedes Spiel |
| `DESIGN_GUIDELINES.md` | Verpflichtende UI/UX-Standards |

## Arbeiten mit dieser Codebase

### Ein neues Spiel hinzufügen
1. `Games/NewGame/`-Ordner erstellen
2. `NewGameWrapper.swift` mit `@StateObject` ViewModel erstellen
3. Button in `ContentView.swift` mit `.fullScreenCover` hinzufügen
4. Spiel-Modul-Pattern folgen (Models, Views, Services)
5. Standard-Header mit 4 Icons implementieren
6. Design-Guidelines anwenden (dunkler Gradient, 22pt Radius, Floating-Button)
7. Mit `GlobalStatsManager.markGameAsPlayed("NewGame")` registrieren

### Multiplayer zu einem Spiel hinzufügen
1. Event-Typen zu `MPCEventTypes.swift` hinzufügen
2. Im ViewModel `MultipeerManager.shared` beobachten
3. `onMessageReceived`-Callback für Spiel-Events handhaben
4. `sendToAll()` für Broadcasts, `sendToSpecificPeer()` für Rollen-Zuweisungen nutzen
5. Lobby-Sync, Rollen-Verteilung, Voting-Flow implementieren
6. Rejoin-Handling mit Kulanzzeit hinzufügen

### Geteilte Services modifizieren
**Wichtig**: Änderungen an Singletons betreffen alle Spiele. Gründlich testen:
- `MultipeerManager`: Betrifft alle zukünftigen Multiplayer-Spiele
- `GlobalStatsManager`: Trackt Spieler-Siege über alle Spiele
- `SoundManager`: Globale Audio-Wiedergabe
- `AppLifecycleManager`: Crash-Erkennung und Factory-Reset

### Mit Kategorien arbeiten
1. Kategorie-Model definieren, das `Codable` und `Identifiable` entspricht
2. Manager/Service für CRUD-Operationen erstellen
3. In `UserDefaults` (klein) oder Documents-Ordner (groß) speichern
4. UI mit Listenansicht + Detail-Ansicht-Pattern hinzufügen
5. AI-Generierung via `AIService` integrieren, falls benötigt
6. 18+-Filterung implementieren, falls zutreffend

### Style-Guidelines-Checkliste
Beim Erstellen neuer Views:
- [ ] Dunkler Gradient-Hintergrund mit spielspezifischer Akzentfarbe
- [ ] Standard-Header: Zurück-Button + 4 Icons (36×36pt)
- [ ] Container-Eckenradius: 22pt
- [ ] Listenelement-Eckenradius: 18pt
- [ ] Primärer Button: Capsule(), 32pt vom unteren Rand
- [ ] Haptik-Feedback bei Interaktionen
- [ ] Alle Texte nutzen `LocalizedStringKey`
- [ ] Kein separater X-Button über fullScreenCover

## Architektur-Philosophie

- **Spiele sind unabhängige Module**: Minimale Kopplung zwischen Spielen
- **Geteilte Services sind opt-in**: Spiele können Stats, Multiplayer etc. ignorieren
- **Konvention über Konfiguration**: Konsistente Patterns, keine komplexe DI
- **SwiftUI-native**: Reaktives State-Management durchgehend
- **Party-Game-fokussiert**: Lokales Multiplayer, externe Anzeige, soziale Features
