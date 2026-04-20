# Apple On-Device AI & Apple Intelligence fuer Games Collection

Stand: 15.04.2026  
Ziel: konkrete, private und spielerisch sinnvolle AI-Ideen fuer die vorhandenen Spiele, ohne die Kernspiele von Apple Intelligence abhaengig zu machen.

## Kurzfazit

Die beste Richtung ist kein grosser Chatbot in der App. Der groesste Mehrwert entsteht durch kleine AI-Momente direkt im Spielablauf:

- bessere Inhalte generieren: neue Kategorien, Challenges, Fragen, Bluff-Ideen, Sound-Karten
- Eingaben bewerten: Luege zu offensichtlich, Begriff doppelt, Antwort zu nah an Wahrheit, Challenge zu schwer
- Runden moderieren: kurze Host-Sprueche, Reveal-Kommentare, Party-Recaps
- Spielwahl personalisieren: aus Spieleranzahl, Stimmung, Zeit und bisherigen Ergebnissen bessere Empfehlungen ableiten

Die App hat dafuer schon gute Grundlagen. `Imposter` und `Time's Up` nutzen bereits `FoundationModels` hinter Availability-Gates. Dazu gibt es Fallbacks, lokale JSON-Daten, UserDefaults-Statistiken und globale Session-Stats. Deshalb sollte AI als optionale Veredelung gebaut werden: Wenn Apple Intelligence verfuegbar ist, wird es dynamischer. Wenn nicht, bleibt jedes Spiel normal spielbar.

Meine Empfehlung fuer ein erstes AI-MVP:

1. **AI Party Director** im Spieleberater: bessere Spielauswahl, Mini-Plan fuer den Abend, Recap nach mehreren Spielen.
2. **Falsche Faehrte: Luegen-Coach**: gibt vor dem Absenden Feedback, ob eine Luege zu offensichtlich, zu nah an der Wahrheit oder zu schwach ist.
3. **Time's Up Generator 2.0**: vorhandenen AI-Kategorie-Generator mit strukturierter Ausgabe, Validierung und Review-Screen haerten.

Diese drei Features passen zum aktuellen Code, verbessern den Spassfaktor sofort und halten Datenschutz sowie App-Store-Risiko klein.

## Aktueller Stand in der Codebasis

### Imposter

`Games/Imposter/Services/AIService.swift` prueft bereits, ob `FoundationModels` verfuegbar ist, erstellt eine `LanguageModelSession` und nutzt deterministische Fallbacks, wenn Apple Intelligence nicht verfuegbar ist. Der Service generiert aktuell Mission-Flavour und Moderator-Logs. Relevant sind `AIService.isAvailable`, `SystemLanguageModel.default.availability`, `LanguageModelSession(instructions:)`, `FallbackAIService` und Text-to-Speech ueber `AVSpeechSynthesizer`.

`Games/Imposter/Services/AIService+Hints.swift` geht noch weiter: Es gibt generierte Hinweise, Fake-Hinweise, Challenges, JSON-Dekodierung, Validierung, Retry-Logik, Request-Limiter und Cache fuer Spy-Hints. Das ist aktuell die staerkste AI-Basis in der App.

`Games/Imposter/Services/AITuner.swift` ist noch deterministisch, aber als spaetere On-Device-KI-Erweiterung kommentiert. Das ist ein guter Ort fuer faire Rollen- oder Schwierigkeitsanpassung, aber nicht der erste Hebel fuer mehr Spass.

### Time's Up

`Games/TimesUp/Managers/AICategoryGenerator.swift` nutzt bereits `FoundationModels`, wenn iOS 26+ und Apple Intelligence verfuegbar sind. Wenn nicht, nimmt es Mock-/Fallback-Daten. Der Generator fordert JSON an, extrahiert Begriffe, entfernt Duplikate und fuellt bei Bedarf mit Fallback-Begriffen auf.

Das ist sehr nah an einem produktiven Feature. Der groesste naechste Schritt waere strukturierte Foundation-Models-Ausgabe statt manuellem JSON-Parsing.

### Bet Buddy

`Games/Bet Buddy/ViewModels/AppViewModel.swift` hat viele Signale, die AI sinnvoll nutzen kann:

- ausgewaehlte Kategorien
- Gruppenanzahl und Gruppennamen
- Timer- und Party-Modus
- Kategorie-Statistiken
- All-Time-Scores
- aktuelle Votes und Score-Verlauf

Der Content selbst ist heute statisch ueber Challenge- und Hint-Daten. AI koennte hier sehr gut als optionaler Content-Mixer dienen: neue Challenges, bessere Hinweise, gruppenbezogene Varianten, Risiko-Anpassung und kurze Ergebnis-Kommentare.

Wichtig: Bei Bet Buddy muss AI besonders kontrolliert sein, weil es 18+-Kontext, peinliche Aufgaben oder sensible Gruppendynamik geben kann. Daher nur mit klaren Kategorien, lokalen Safety-Regeln und Review/Retry vor dem Anzeigen.

### Falsche Faehrte

`Games/Falsche Faehrte/ViewModels/FFViewModel.swift` hat einen perfekten AI-Hook: Spieler geben Luegen ein, danach wird die echte Antwort angehaengt und alles gemischt. Genau vor `submitBluff(_:)` und `submitBluffMultiplayer(_:)` kann ein AI-Check sitzen.

Sinnvolle Checks:

- Luege ist fast identisch zur echten Antwort
- Luege ist zu kurz oder zu generisch
- Luege ist zu offensichtlich falsch
- Luege enthaelt problematische Inhalte
- mehrere Spieler geben sehr aehnliche Luegen ab

Wichtig: Die AI darf niemals die Wahrheit verraten. Sie sollte nur Feedback geben wie: "Klingt zu allgemein", "Besser konkreter machen", "Zu nah an der echten Antwort".

### Questions

`Games/Question/QuestionsEngine.swift` arbeitet mit Prompt-Paaren fuer normale Spieler und Luegner, sammelt Antworten, zeigt die echte Frage und fuehrt dann ins Voting. AI kann hier zwei Dinge gut:

- neue Prompt-Paare generieren, die fair sind
- Antworten nach der Runde zusammenfassen, ohne die Rolle vorher zu verraten

Besonders stark waere ein "Diskussions-Starter" nach dem Reveal: "Achtet auf sehr konkrete Antworten" oder "Eine Antwort wirkt auffaellig ausweichend". Das sollte aber erst nach der Antwortphase erscheinen, damit die AI nicht das Spiel kaputt moderiert.

### Sound Cinema

`Games/Sound Cinema/ViewModels/SoundCinemaViewModel.swift` hat Karten, Timer, Voting, Leben und Score. AI kann hier neue Sound-Karten generieren oder nach einer Runde kleine Awards vergeben.

Vorsicht bei automatischer Audio-Bewertung: Sound Analysis oder Speech kann helfen, aber sollte nicht entscheiden, ob jemand gewonnen hat. Bei Partyspielen ist subjektives Voting oft lustiger und fairer als ein Modellurteil.

### Spieleberater / Party Hub

`Games Collection/GameRecommenderView.swift` hat bereits Spielerzahl, Zeit, Stimmung und Modus. Die Logik ist aktuell regelbasiert. `Games Collection/Services/GlobalStatsManager.swift` speichert Wins, Losses, Teilnahmen, gespielte Spiele und Session-Wins. Daraus laesst sich ein sehr gutes On-Device-AI-Feature bauen.

Beispiel:

- "Ihr seid 6 Leute, habt 20 Minuten und wollt reden: startet mit Falsche Faehrte, danach Bet Buddy."
- "Ken hat oft gewonnen, heute lieber ein Spiel mit mehr Zufall."
- "Ihr habt Sound Cinema noch nicht gespielt, passt aber zu Aktiv + kurzer Zeit."

Das ist vermutlich das beste Apple-Intelligence-Feature fuer die ganze App, weil es alle Spiele verbindet.

## Apple-Frameworks, die hier wirklich passen

### Foundation Models / Apple Intelligence

Einsatz:

- kreative Textgenerierung
- strukturierte Ausgaben fuer Spielcontent
- kurze Moderationstexte
- Party-Recaps
- lokale Empfehlungen auf Basis von Stats
- Tool-Calling spaeter fuer lokale Datenabfragen

Gute Use-Cases in dieser App:

- Time's Up Kategorien generieren
- Falsche-Faehrte-Luegen bewerten
- Bet-Buddy-Challenges erzeugen
- Questions-Prompt-Paare erzeugen
- Imposter-Hints und Moderator-Logs verbessern
- Spieleberater als AI Party Director

Grenzen:

- Nur auf kompatiblen Geraeten mit Apple Intelligence.
- Nicht fuer Kernfunktionen voraussetzen.
- Ausgabe immer validieren, weil generative Modelle variieren.
- Keine vertraulichen Party-Inhalte ohne klare lokale Verarbeitung und Nutzerkontrolle verwenden.

### Natural Language

Einsatz:

- Sprache erkennen
- Texte tokenisieren
- Namen, Orte, Organisationen erkennen
- Aehnlichkeit, Klassifikation oder Vorfilterung ergaenzen
- einfache Textqualitaet pruefen

Gute Use-Cases:

- Falsche Faehrte: Luege ist zu nah an Wahrheit
- Time's Up: doppelte oder zu aehnliche Begriffe entfernen
- Questions: Antworten vergleichen, sehr kurze/ausweichende Antworten markieren
- Bet Buddy: Challenge-Text auf Laenge, Kategorie und Sprache pruefen

Vorteil: Funktioniert breiter als Apple Intelligence und passt gut als lokaler Validator.

### Speech

Einsatz:

- Spracheingabe fuer Antworten oder Begriffe
- Transkription in Sound Cinema oder Time's Up
- optionaler Hands-free Party Mode

Gute Use-Cases:

- Spieler diktieren Bluff oder Antwort statt zu tippen
- Sound Cinema kann gesprochene Beschreibungen erkennen, wenn ein Modus das erlaubt
- Time's Up kann erklaerte Begriffe optional transkribieren

Vorsicht:

- Mikrofon-Permission und klare Erklaerung noetig.
- Nicht als harter Schiedsrichter verwenden.
- Lauter Party-Kontext kann Erkennung verschlechtern.

### Vision

Einsatz:

- OCR fuer Text aus Bildern
- Karten, handschriftliche Begriffe oder Listen einscannen

Gute Use-Cases:

- eigene Time's-Up-Liste aus Foto importieren
- Fragen oder Begriffe von Papier scannen
- schnelle Pack-Erstellung aus vorhandenen Notizen

Vorsicht:

- Braucht Kamera-/Foto-Berechtigungen je nach Flow.
- Fuer den ersten AI-Ausbau nicht so wichtig wie Foundation Models und Natural Language.

### Core ML

Einsatz:

- eigene kleine Modelle
- Text-/Audio-/Bildklassifikation
- lokale Vorhersagen ohne Netzwerk

Gute Use-Cases:

- Challenge-Schwierigkeit klassifizieren
- problematische Inhalte lokal flaggen
- spaeter eigenes Fun-Score-Modell aus anonymen lokalen Signalen

Vorsicht:

- Mehr Aufwand als Foundation Models oder Natural Language.
- Erst lohnend, wenn genug klare Trainingsdaten oder feste Regeln existieren.

### Sound Analysis

Einsatz:

- Soundklassifikation
- Audioereignisse erkennen

Gute Use-Cases:

- Sound Cinema: optional erkennen, ob jemand spricht, singt, klatscht oder lacht
- Party-Recap: "lauteste Runde" oder "meiste Lacher" nur als Gag, nicht als Bewertung

Vorsicht:

- Nicht robust genug als alleiniger Gewinner-Entscheider.
- Mikrofon- und Datenschutz-Kommunikation muessen sauber sein.

### App Intents

Einsatz:

- Siri, Spotlight, Shortcuts und Apple-Intelligence-Systemerlebnisse
- haeufige Aktionen direkt erreichbar machen

Gute Use-Cases:

- "Starte Bet Buddy"
- "Empfiehl ein Partyspiel"
- "Oeffne Time's Up Kategorie Generator"
- "Zeig den Punktestand"
- Spotlight-Suche nach Spielen, Kategorien oder zuletzt gespielten Modi

Das steigert nicht direkt den Runden-Spass, aber die App fuehlt sich moderner und tiefer in iOS integriert an.

## Priorisierte Feature-Ideen

### P0: AI Party Director

**Wo:** `GameRecommenderView` plus `GlobalStatsManager`  
**Framework:** Foundation Models, Fallback regelbasiert  
**Spassfaktor:** sehr hoch  
**Risiko:** niedrig bis mittel  
**Aufwand:** mittel

Der aktuelle Spieleberater nutzt Spielerzahl, Zeit, Stimmung und Modus. Mit den vorhandenen globalen Stats kann daraus ein kleiner Party-Host werden.

Beispiele:

- "Ihr seid 5 Spieler, 20 Minuten, Stimmung lustig: Bet Buddy als Warm-up, danach Falsche Faehrte."
- "Ihr habt heute schon viel geraten. Jetzt etwas Aktives: Sound Cinema."
- "Max hat 4 Siege in Folge. Waehlt ein Spiel mit mehr Chaos."

Wichtig fuer die Umsetzung:

- AI nur als Erklaerer und Sortierer verwenden.
- Harte Regeln bleiben im Code: Mindestspieler, Multiplayer-Support, Dauer.
- Ausgabe strukturiert erzeugen: `gameId`, `reason`, `partyPlan`, `fallbackReason`.
- Ohne AI bleibt die vorhandene Empfehlung aktiv.

Warum es sinnvoll ist:

- Verbindet alle Spiele.
- Nutzt Daten, die schon lokal vorhanden sind.
- Fuehlt sich sofort wie intelligente App an, ohne einzelne Spiele riskant umzubauen.

### P0: Falsche Faehrte Luegen-Coach

**Wo:** vor `submitBluff(_:)` und `submitBluffMultiplayer(_:)`  
**Framework:** Natural Language plus Foundation Models optional  
**Spassfaktor:** sehr hoch  
**Risiko:** niedrig, wenn spoiler-sicher gebaut  
**Aufwand:** mittel

Der Coach bewertet eine Luege vor dem Absenden:

- "Zu offensichtlich"
- "Zu nah an der Wahrheit"
- "Zu kurz"
- "Gute Luege"
- "Mach sie konkreter"

Wichtig:

- Die echte Antwort darf im UI nie genannt werden.
- AI-Feedback darf nur abstrakt sein.
- Spieler kann trotzdem absenden, wenn er moechte.
- Im Multiplayer nur lokal beim Spieler oder host-seitig ohne Offenlegung der Wahrheit an Clients.

Empfohlene Ausgabe:

```swift
struct LieFeedback: Codable {
    let score: Int // 0...100
    let label: String // "stark", "zu offensichtlich", "zu nah", "zu kurz"
    let hint: String // spoilerfrei
    let shouldWarnBeforeSubmit: Bool
}
```

Warum es sinnvoll ist:

- Direkt im Kernspiel.
- Verbessert die Qualitaet der Luegen.
- Macht schwache Runden lustiger, ohne das Spielprinzip zu veraendern.

### P0: Time's Up Generator 2.0

**Wo:** `AICategoryGenerator`  
**Framework:** Foundation Models mit strukturierter Ausgabe, Natural Language als Validator  
**Spassfaktor:** hoch  
**Risiko:** niedrig  
**Aufwand:** niedrig bis mittel

Der Generator existiert bereits. Die naechste Version sollte:

- strukturierte Ausgabe statt manuell extrahiertem JSON nutzen
- Begriffe nach Schwierigkeit klassifizieren
- problematische oder zu lange Begriffe entfernen
- dem Nutzer vor dem Speichern eine Review-Liste zeigen
- Varianten anbieten: "leichter", "chaotischer", "prominenter", "kindertauglich", "18+ aus"

Empfohlene Ausgabe:

```swift
struct GeneratedTimesUpCategory: Codable {
    let title: String
    let terms: [GeneratedTerm]
    let warnings: [String]
}

struct GeneratedTerm: Codable {
    let text: String
    let difficulty: String
    let reason: String
}
```

Warum es sinnvoll ist:

- Bestehender Code ist schon nah dran.
- Geringer Umbau mit grosser Wirkung.
- Fallbacks sind bereits vorhanden.

### P1: Bet Buddy Dynamic Challenge Mixer

**Wo:** Challenge-Service und Result-/Challenge-Screen  
**Framework:** Foundation Models, Natural Language, lokale Safety-Regeln  
**Spassfaktor:** hoch  
**Risiko:** mittel wegen 18+-Kontext  
**Aufwand:** mittel

AI kann neue Challenges generieren, aber nicht ungefiltert. Besser ist ein Mixer:

- Kategorie und Intensitaet bleiben im Code gesetzt.
- AI erzeugt 3 Kandidaten.
- lokale Regeln filtern Laenge, Sprache, verbotene Inhalte, direkte Beleidigungen.
- Nutzer bekommt eine Challenge oder kann neu wuerfeln.

Zusaetzlich:

- smartere Hints fuer Alphabet-/Party-Hints
- Ergebnis-Kommentar nach Voting
- adaptive Timer-Empfehlung je nach Gruppe

### P1: Imposter AI Moderator 2.0

**Wo:** vorhandener `AIService`, `AIService+Hints`, `AITuner`  
**Framework:** Foundation Models  
**Spassfaktor:** mittel bis hoch  
**Risiko:** mittel wegen Spoiler-Gefahr  
**Aufwand:** niedrig bis mittel

Da Imposter schon AI hat, sollte hier eher gehaertet als neu erfunden werden:

- strukturierte Ausgabe fuer Mission-Flavour, Hints und Challenges
- einheitliche Safety-/Spoiler-Validierung
- persona-basierte Moderator-Stile: "Agent", "Game Show", "Mystery"
- bessere Fallback-Kataloge
- AI-Tuner nur erklaerend, nicht als alleinige Fairness-Instanz

Wichtig:

- Das geheime Wort darf nie in Hint oder Fake-Hint leaken.
- Generated Content immer gegen `word` und Kategorie validieren.
- Cache pro Wort/Kategorie behalten.

### P1: Questions Prompt Pair Generator

**Wo:** Kategorie-/Prompt-Daten und `QuestionsEngine`  
**Framework:** Foundation Models, Natural Language  
**Spassfaktor:** hoch  
**Risiko:** mittel  
**Aufwand:** mittel

AI kann faire Prompt-Paare erzeugen:

- normale Frage: "Was ist ein Ort, an dem du dich sofort entspannst?"
- Luegner-Frage: "Was ist ein Ort, an dem viele Menschen unruhig werden?"

Die Fragen muessen nah genug sein, damit Luegner plausibel antworten, aber weit genug, damit Unterschiede entstehen.

Validierung:

- beide Prompts gleiche Laenge und Tonalitaet
- keine identischen Kernwoerter
- keine zu privaten oder sensiblen Fragen
- Kategorie passend

Zusatzidee:

- Nach der Antwortphase generiert AI einen kurzen Diskussionsimpuls, ohne Rollen direkt zu nennen.

### P2: Sound Cinema AI Card Studio

**Wo:** SoundCard-Daten und Setup  
**Framework:** Foundation Models, optional Speech/Sound Analysis  
**Spassfaktor:** mittel bis hoch  
**Risiko:** mittel  
**Aufwand:** mittel bis hoch

AI kann neue Karten generieren:

- "Toaster in Panik"
- "Staubsauger im Opernhaus"
- "Roboter versucht zu niesen"

Gute UI:

- Spieler waehlt Pack, Intensitaet und Stil.
- AI erzeugt 10 Karten.
- Nutzer kann Karten loeschen oder speichern.

Optional spaeter:

- Speech-Transkription fuer gesprochene Erklaerungen
- Sound Analysis fuer Spass-Awards wie "lauteste Runde"

Nicht empfehlen:

- automatische Gewinnentscheidung durch Audio-Modell.

### P2: Party Recap / Aftershow

**Wo:** `GlobalStatsManager`, Game-Over-Screens, Home  
**Framework:** Foundation Models  
**Spassfaktor:** hoch  
**Risiko:** niedrig bis mittel  
**Aufwand:** mittel

Nach mehreren Spielen kann die App einen lokalen Recap erzeugen:

- "MVP des Abends"
- "groesste Pechstraehne"
- "chaotischstes Spiel"
- "naechste Empfehlung"

Die Daten sind bereits lokal da:

- Wins
- Losses
- Teilnahmen
- Session-King
- gespielte Spiele

Wichtig:

- Spieler sollten Recaps deaktivieren koennen.
- Ton freundlich halten, keine persoenlichen Angriffe.
- Bei Kindern/Family-Modus besonders harmlos formulieren.

### P2: App Intents fuer Siri, Spotlight und Shortcuts

**Wo:** neue App-Intents-Dateien  
**Framework:** App Intents  
**Spassfaktor:** indirekt  
**Risiko:** niedrig  
**Aufwand:** mittel

Sinnvolle Intents:

- `StartGameIntent(gameId:)`
- `RecommendGameIntent(playerCount:mood:time:)`
- `OpenScoreboardIntent`
- `GenerateTimesUpCategoryIntent(theme:)`

Nicht zu viele App Shortcuts. Fuer diese App reichen 3 bis 5.

## Empfohlene Architektur

Nicht jede Spiel-View sollte direkt `LanguageModelSession` bauen. Besser ist ein gemeinsamer AI-Layer:

```swift
protocol GameAIProviding {
    var availability: GameAIAvailability { get }
    func generateRecommendation(context: PartyContext) async throws -> PartyRecommendation
    func reviewLie(_ input: LieReviewInput) async throws -> LieFeedback
    func generateTimesUpCategory(_ input: CategoryGenerationInput) async throws -> GeneratedTimesUpCategory
}

enum GameAIAvailability {
    case unavailable(reason: String)
    case localValidatorsOnly
    case appleIntelligence
}
```

Konkrete Bausteine:

- `GameAIService`: Fassade fuer alle Spiele
- `FoundationModelsGameAIService`: iOS 26+ Implementierung
- `LocalTextAnalysisService`: Natural-Language-Checks fuer iOS 17+
- `GeneratedContentValidator`: Laenge, Duplikate, verbotene Woerter, Spoiler
- `GeneratedContentStore`: lokal gespeicherte Kategorien/Karten
- `AIFeatureFlags`: einzelne Features pro Spiel aktivieren/deaktivieren

Das passt gut zur aktuellen Struktur, weil `Imposter` und `Time's Up` schon je eigene Services haben. Langfristig koennen diese Services in eine gemeinsame Schicht wandern, damit Availability, Logging, Fallbacks und Validierung nicht doppelt entstehen.

## Verfuegbarkeit und Fallbacks

Die App scheint im Haupttarget auf iOS 17.6 zu zielen, waehrend Apple-Intelligence-Code mit `#available(iOS 26.0, *)` abgesichert ist. Deshalb:

- Kernspiele muessen weiter ab iOS 17.6 funktionieren.
- Apple-Intelligence-Features nur als Bonus anzeigen.
- UI sollte klar sagen: "Auf diesem Geraet nicht verfuegbar" statt kaputt zu wirken.
- Fallbacks sollen nicht wie Fehler wirken, sondern normaler Modus sein.

Empfohlene UI-Texte:

- "AI-Vorschlag lokal erstellen"
- "Auf deinem Geraet nicht verfuegbar"
- "Standardmodus verwenden"
- "Neu generieren"
- "Vorschlag uebernehmen"

## Datenschutz und App Store

Das Privacy-Manifest deklariert aktuell UserDefaults-Zugriff und keine gesammelten Daten, kein Tracking und keine Tracking-Domains. Das ist eine starke Ausgangslage. On-device AI sollte diesen Vorteil behalten.

Regeln:

- Keine Cloud-AI fuer Partytexte, Namen, Antworten oder Luegen verwenden, ausser der Nutzer stimmt bewusst zu.
- Keine generierten Inhalte ungeprueft speichern oder teilen.
- Bei Mikrofon/Speech klare Permission-Texte und sichtbare Aufnahme-Indikatoren.
- Bei Kamera/Vision klare Begruendung fuer Scan-Features.
- 18+-nahe Inhalte in Bet Buddy immer mit lokalen Grenzen, Kategorien und Opt-in behandeln.
- AI-Ausgaben als AI-Vorschlag kennzeichnen.
- Nutzer muss generierte Inhalte verwerfen, neu generieren oder bearbeiten koennen.

Wichtig fuer App Review:

- AI darf keine beleidigenden, diskriminierenden oder gefaehrlichen Aufgaben erzeugen.
- Bei Spielen mit Alkohol/18+ sollte die App keine riskanten Aufgaben erfinden.
- Generated Content braucht Safety-Filter und moderaten Ton.
- Wenn irgendwann Server-AI genutzt wird, muss das Privacy-Manifest und die App-Store-Datenerklaerung neu bewertet werden.

## Roadmap

### Phase 1: Gemeinsame AI-Basis

Ziel: saubere Infrastruktur, ohne UI gross umzubauen.

- `GameAIAvailability` einfuehren
- gemeinsamen Validator bauen
- Foundation-Models-Availability zentralisieren
- Natural-Language-Checks als iOS-17-kompatible Basis ergaenzen
- bestehende `Time's Up` und `Imposter` AI-Logik perspektivisch daran anbinden

Ergebnis: ein stabiler AI-Unterbau mit Fallbacks.

### Phase 2: Time's Up und Falsche Faehrte

Ziel: zwei direkt spuerbare Features.

- Time's Up Generator strukturieren und Review-Screen verbessern
- Falsche-Faehrte-Luegen-Coach als optionalen Check vor Submit bauen
- Multiplayer-Fall spoiler-sicher pruefen

Ergebnis: mehr Content und bessere Bluff-Qualitaet.

### Phase 3: AI Party Director

Ziel: App-weites Highlight.

- `GameRecommenderView` mit lokalen Stats verbinden
- AI-Empfehlung strukturiert generieren
- Party-Plan und Erklaerung anzeigen
- Fallback auf bestehende Regel-Logik

Ergebnis: die App wirkt deutlich intelligenter, ohne einzelne Spiele riskant zu machen.

### Phase 4: Bet Buddy und Questions

Ziel: Content-Generatoren fuer weitere Spiele.

- Bet Buddy Challenge Mixer mit Safety-Leveln
- Questions Prompt Pair Generator
- lokale Review- und Bearbeitungs-UI

Ergebnis: mehr Wiederspielwert.

### Phase 5: Speech, Vision, Sound Analysis und App Intents

Ziel: fortgeschrittene Systemintegration.

- Spracheingabe fuer Antworten oder Begriffe
- OCR-Import fuer eigene Listen
- optionale Sound-Cinema-Awards
- Siri/Spotlight/Shortcuts fuer haeufige Aktionen

Ergebnis: moderne iOS-Integration, aber erst nach stabiler Text-AI.

## Bewertung nach Wirkung

| Feature | Spassfaktor | Aufwand | Risiko | Empfehlung |
|---|---:|---:|---:|---|
| AI Party Director | sehr hoch | mittel | niedrig | zuerst bauen |
| Falsche Faehrte Luegen-Coach | sehr hoch | mittel | niedrig-mittel | zuerst bauen |
| Time's Up Generator 2.0 | hoch | niedrig-mittel | niedrig | zuerst bauen |
| Bet Buddy Challenge Mixer | hoch | mittel | mittel | danach |
| Imposter Moderator 2.0 | mittel-hoch | niedrig-mittel | mittel | haerten, nicht neu bauen |
| Questions Prompt Pair Generator | hoch | mittel | mittel | danach |
| Sound Cinema Card Studio | mittel-hoch | mittel | mittel | spaeter |
| Party Recap | hoch | mittel | niedrig-mittel | nach Party Director |
| App Intents | mittel | mittel | niedrig | spaeter |
| Audio-basierte Bewertung | mittel | hoch | hoch | nicht als Kernlogik |

## Was ich nicht empfehlen wuerde

- Einen allgemeinen Chatbot auf die Startseite setzen.
- Apple Intelligence fuer den Start eines Spiels voraussetzen.
- AI automatisch Gewinner bestimmen lassen.
- Spielertexte an Cloud-AI schicken.
- 18+-Challenges komplett frei generieren lassen.
- Luegen-Coach so bauen, dass er die Wahrheit indirekt verraet.
- Zu viele AI-Toggles in Settings verstecken.

AI sollte sich wie ein Party-Host anfuehlen, nicht wie ein Technik-Menue.

## Konkreter MVP-Vorschlag

### MVP 1: AI Party Director

UI:

- im Spieleberater ein Button: "AI-Vorschlag"
- Ergebnis als eine Hauptempfehlung plus kurzer Party-Plan
- Hinweis, wenn nur Standardlogik genutzt wird

Input:

- Spieleranzahl
- Zeit
- Stimmung
- Single Device oder Multiplayer
- gespielte Spiele dieser Session
- Session-King und globale Stats

Output:

```swift
struct PartyRecommendation: Codable {
    let primaryGameId: String
    let title: String
    let reason: String
    let nextGameId: String?
    let hostLine: String
}
```

### MVP 2: Falsche Faehrte Luegen-Coach

UI:

- unter dem Luegen-Textfeld ein kleiner Check-Button
- Ergebnis als Ampel: stark, ok, riskant
- "Trotzdem absenden" bleibt moeglich

Input:

- Frage
- echte Antwort, nur intern
- Luege
- Kategorie
- bereits abgegebene Luegen, wenn lokal verfuegbar

Output:

```swift
struct LieFeedback: Codable {
    let score: Int
    let label: String
    let spoilerSafeHint: String
    let issueCodes: [String]
}
```

### MVP 3: Time's Up Generator 2.0

UI:

- Thema eingeben
- Schwierigkeit waehlen
- generierte Begriffe reviewen
- einzelne Begriffe entfernen oder neu generieren

Input:

- Thema
- Sprache
- Schwierigkeit
- Anzahl Begriffe
- optionale Ausschlussliste

Output:

```swift
struct GeneratedTermPack: Codable {
    let title: String
    let terms: [String]
    let rejectedExamples: [String]
}
```

## Technischer Implementierungsstil

Wichtig ist, AI-Ausgaben als untrusted input zu behandeln:

1. Prompt eng halten.
2. Strukturierte Ausgabe verwenden.
3. Ergebnis dekodieren.
4. Ergebnis validieren.
5. Fallback verwenden, wenn Validierung scheitert.
6. Nutzer entscheiden lassen, ob der Vorschlag uebernommen wird.

Bei bestehenden Stellen mit manuellem JSON-Parsing, wie im Time's-Up-Generator, wuerde ich mittelfristig auf strukturierte Ausgabe umstellen. Das reduziert fragile String-Extraktion und passt besser zu Foundation Models.

## Quellen

- Apple Developer Documentation: Foundation Models  
  https://developer.apple.com/documentation/foundationmodels
- Apple Human Interface Guidelines: Generative AI  
  https://developer.apple.com/design/human-interface-guidelines/generative-ai
- Apple Developer Documentation: App Intents  
  https://developer.apple.com/documentation/appintents
- Apple Developer Documentation: Accelerating app interactions with App Intents  
  https://developer.apple.com/documentation/appintents/acceleratingappinteractionswithappintents
- Apple Developer Documentation: Natural Language  
  https://developer.apple.com/documentation/naturallanguage
- Apple Developer Documentation: Speech  
  https://developer.apple.com/documentation/speech
- Apple Developer Documentation: Vision  
  https://developer.apple.com/documentation/vision
- Apple Developer Documentation: Core ML  
  https://developer.apple.com/documentation/coreml
- Apple Developer Documentation: Sound Analysis  
  https://developer.apple.com/documentation/soundanalysis
