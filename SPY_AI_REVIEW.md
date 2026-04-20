# Spy / Imposter AI Review

Stand: 15.04.2026  
Scope: AI/KI-Funktionen im Spy-/Imposter-Spiel, mit Fokus auf Apple Intelligence, Foundation Models, Hint-Logik, Fairness, UI-Verstaendlichkeit, Datenschutz und Spielspass.

## Kurzfazit

Die Spy-KI hat eine gute Basis, aber sie ist aktuell uneinheitlich verdrahtet.

Der staerkste und sinnvollste Teil ist die **Spion-Kartenhilfe**: Wenn ein Spieler Spion ist, kann die Karte dezente Hinweise zum geheimen Wort anzeigen. Dafuer gibt es bereits gute Bausteine: Apple-Intelligence-Availability, lokale Fallbacks, Hint-Validierung, Cache, Request-Limiter und Schutz gegen direktes Wort-Leaking.

Gleichzeitig wirken mehrere Teile groesser, als sie technisch aktuell sind:

- `AIService` sagt, KI liefere Hinweise, Rollen und Logs, aber Rollen-/Mission-Flavour-/Moderator-Log-Generierung ist im eigentlichen Spiel kaum oder gar nicht angeschlossen.
- `AITuner` klingt nach AI, ist aber deterministische Fairness-Logik.
- `HintService` kann laufende Runden-Hinweise erzeugen, wird aber aktuell nicht gestartet.
- Der Spion-Hinweis-Toggle wird deaktiviert, wenn Apple Intelligence nicht verfuegbar ist, obwohl es manuelle Hints und Fallbacks gibt.

Meine Bewertung: **6.8/10 als aktuelle Implementierung**, aber **8.5/10 Potenzial**, wenn die Begriffe, Toggles und Spielintegration sauber getrennt werden.

## Was die Spy-KI aktuell wirklich macht

### 1. Apple-Intelligence-Verfuegbarkeit

Datei: `Games/Imposter/Services/AIService.swift`

`AIService` prueft mit `#if canImport(FoundationModels)` und `#available(iOS 26.0, *)`, ob `SystemLanguageModel.default` verfuegbar ist. Wenn ja, wird eine `LanguageModelSession` erstellt. Wenn nicht, wird `isAvailable = false` gesetzt.

Das ist grundsaetzlich richtig:

- keine harte Abhaengigkeit von Apple Intelligence
- Fallbacks fuer nicht unterstuetzte Geraete
- on-device Ansatz ohne Cloud

Schwaeche:

- Es gibt nur `Bool isAvailable`, aber keinen Availability-Grund wie `deviceNotEligible`, `appleIntelligenceNotEnabled` oder `modelNotReady`.
- Es gibt keinen sichtbaren Refresh, falls Apple Intelligence nachtraeglich aktiviert oder das Modell spaeter bereit wird.
- `session` ist als `Any?` gespeichert. Das funktioniert wegen Availability-Gates, ist aber nicht besonders sauber.

### 2. Spion-Karten-Hinweise

Dateien:

- `Games/Imposter/Models/GameLogic.swift`
- `Games/Imposter/Models/HintsManager.swift`
- `Games/Imposter/Models/CategoryHints.swift`
- `Games/Imposter/Services/AIService+Hints.swift`

Wenn `gameSettings.showSpyHints` aktiv ist und ein Spieler Spion ist, wird in `assignWordsToPlayers(...)` die Spion-Karte mit `HintsManager.createSpyCardTextWithAI(...)` erzeugt. Diese Methode nutzt zuerst manuelle Hinweise und generiert bei Bedarf per Apple Intelligence neue Spy-Hints.

Das ist der beste KI-Use-Case im Spiel:

- Spione bekommen Hilfe, ohne das Wort zu sehen.
- Die Kategorie kann optional sichtbar sein.
- Andere Spione koennen optional sichtbar sein.
- AI-Hints werden gecacht.
- Wort-Leaks werden validiert.

Diese Funktion sollte bleiben und weiter ausgebaut werden.

### 3. Laufende Runden-Hinweise

Dateien:

- `Games/Imposter/Services/HintService.swift`
- `Games/Imposter/Views/Components/HintOverlay.swift`
- `Games/Imposter/Views/GamePlayView.swift`

`HintService` kann alle 45 Sekunden Hinweise, Fake-Hinweise oder Challenges erzeugen und per `HintOverlay` anzeigen. Das System hat Timer, Verlauf, Voice-Ausgabe und AI/Fallback-Content.

Problem: `HintService.startHints(...)` wird im aktuellen Imposter-Code nicht aufgerufen. Es gibt nur `resetState()` und `stopHints()`. In `GameLogic.nextPlayer()` steht sogar ein Kommentar, dass Hinweise vorbereitet werden koennten, aber "hier machen wir nichts".

Das bedeutet praktisch:

- Der Toggle "Hinweise aktivieren" in den Imposter-Einstellungen wirkt wahrscheinlich wie eine tote Einstellung.
- `HintOverlay` ist eingebaut, bekommt aber keine aktiven Hints.
- `generateGameContent(...)` fuer laufende Hinweise ist groesstenteils ungenutzt.

Das ist der wichtigste funktionale Befund.

### 4. Moderator-Logs

Dateien:

- `Games/Imposter/Services/ModeratorLog.swift`
- `Games/Imposter/Services/AIService.swift`

`ModeratorLog.logImposterSelection(...)` kann eine AI-Erklaerung zur Spion-Auswahl generieren. Im Suchlauf wurde aber kein echter Aufruf von `logImposterSelection(...)` gefunden. In `GameLogic.selectRandomImposters()` wird nur `logDebug(...)` aufgerufen.

Damit ist die "KI generiert Logs"-Aussage aktuell irrefuehrend. Der Code ist vorhanden, aber nicht im Spielablauf genutzt.

### 5. Rollen-Generierung

Datei: `Games/Imposter/Services/AIService+Hints.swift`

Es gibt `generateRole(...)` und `generateRoles(...)`. Diese Methoden werden aktuell nicht aufgerufen. Dazu enthalten sie Kommentare wie "Platzhalter fuer Verkuerzung im Diff" und liefern nur einfache String-Ausgaben bzw. JSON-Array-Parsing.

Diese Methoden sollten entweder entfernt oder richtig neu gebaut werden, bevor man sie als Feature betrachtet.

### 6. Fairness / AITuner

Dateien:

- `Games/Imposter/Services/AITuner.swift`
- `Games/Imposter/Models/GameLogic.swift`

`AITuner` berechnet Gewichtungs-Multiplikatoren fuer die Spion-Auswahl. Das ist keine generative KI und nutzt kein Foundation Model. Es ist regelbasierte Fairness-Logik.

Das ist fachlich gut, aber die Benennung ist missverstaendlich. In `GameLogic.selectRandomImposters()` wird sogar geloggt: "Spion-Verteilung: KI verfuegbar", obwohl die Auswahl nicht von Apple Intelligence abhaengt. Das sollte umbenannt werden.

## Staerken

### Gute Graceful-Degradation-Basis

Die KI ist nicht hart fuer das Spiel erforderlich. Wenn `FoundationModels` nicht importierbar oder iOS 26 nicht verfuegbar ist, fallen die Funktionen auf lokale Logik zurueck. Das ist fuer deine App wichtig, weil das Haupttarget auf iOS 17.6 ausgelegt wirkt.

### Gute Spoiler-Schutz-Idee

`AIService+Hints.swift` prueft AI-Hints auf:

- geheimes Wort
- Wortvarianten
- Zahlen
- Buchstaben-/Laengen-Hinweise
- zu kurze oder zu lange Texte
- bestimmte Kategorie-Anker

Das ist genau die richtige Richtung. Bei einem Spy-Spiel ist ein AI-Leak der groesste Schaden.

### Cache und Request-Limiter sind sinnvoll

`SpyHintCache` verhindert doppelte Generierung fuer dasselbe Wort/Kategorie-Paar. `AIRequestLimiter` serialisiert AI-Anfragen. Das reduziert Latenz, Kosten im lokalen Modell und vermeidet parallele Foundation-Models-Sessions.

### Fake-Hints sind UI-seitig gut getarnt

`HintType.fake` nutzt denselben Display-Namen und dasselbe Icon wie normale Hinweise. Wenn Fake-Hints wirklich als Spielmechanik gedacht sind, ist das gut, weil die UI die Wahrheit nicht verraten sollte.

### Multiplayer-Sicherheit ist konservativ

Im Multiplayer verteilt der Host konkrete Karteninhalte. Das ist grundsaetzlich gut, weil Clients nicht selbst geheime Inhalte generieren muessen.

## Kritische Befunde

### Hoch: Das laufende Hinweis-System ist aktuell nicht gestartet

`HintService.startHints(for:category:players:)` existiert, wird aber nicht aufgerufen.

Auswirkung:

- Der globale Toggle "Hinweise aktivieren" hat kaum sichtbaren Effekt.
- `HintOverlay` bleibt leer.
- Ein grosser Teil der AI-/Voice-Hint-Logik ist praktisch tot.

Empfehlung:

- Entscheiden: Soll es laufende Runden-Funksprueche geben oder nicht?
- Wenn ja, Startpunkt sauber setzen, z. B. nach der Startspieler-Ankuendigung, sobald der Timer wirklich laeuft.
- Wenn nein, `HintService`, `HintOverlay` und den Toggle aus UI/Kommunikation entfernen oder spaeter parken.

Wichtig: Wenn laufende Hinweise fuer alle sichtbar sind, duerfen sie nicht echte Hinweise zum Wort sein. Sonst koennen sie das Spiel zu stark beeinflussen. Fuer oeffentliche Funksprueche waeren Challenges und neutrale Chaos-Meldungen besser als echte Wort-Hints.

### Hoch: UI verspricht mehr KI, als aktuell genutzt wird

In `ImposterSettingsView` steht: "KI generiert Hinweise, Rollen und Logs." Aktuell ist das in dieser Form nicht korrekt.

Realistisch:

- Spion-Karten-Hints: ja
- laufende Hinweise: Code vorhanden, aber nicht gestartet
- Rollen: Methoden vorhanden, aber ungenutzt
- Logs: AI-Methode vorhanden, aber Selection-Log nicht angeschlossen

Empfehlung:

Den Text aendern zu:

> "Apple Intelligence kann Spion-Hinweise verbessern. Wenn nicht verfuegbar, nutzt das Spiel lokale Hinweise."

Das ist ehrlich und fuer Nutzer verstaendlicher.

### Hoch: Spion-Hinweise sind an Apple Intelligence gekoppelt, obwohl Fallbacks existieren

In `SpyOptionsView` ist "Spion-Hinweise anzeigen" deaktiviert, wenn `AIService.shared.isAvailable == false`.

Das ist fachlich unguenstig, weil:

- `CategoryHints` hat manuelle Hinweise.
- `AIService+Hints` hat Fallback-Hints.
- Ohne Apple Intelligence koennte die Funktion trotzdem sinnvoll funktionieren.

Aktuell wirkt es fuer viele Nutzer so, als waeren Spion-Hinweise ein reines Apple-Intelligence-Feature. Besser waere:

- Toggle immer erlauben: "Spion-Hinweise"
- Badge nur wenn AI aktiv: "AI verbessert"
- Detailtext:
  - AI verfuegbar: "Lokale KI erzeugt zusaetzliche Hinweise."
  - AI nicht verfuegbar: "Es werden lokale Standardhinweise genutzt."

### Mittel: Raw JSON Parsing statt strukturierter Foundation-Models-Ausgabe

`AIService+Hints.swift` fordert JSON per Prompt an und extrahiert `{...}` oder `[...]` aus Text. Das ist besser als freie Antworten, aber fragiler als Foundation Models mit strukturierter Ausgabe.

Risiko:

- Modell schreibt Zusatztext um JSON herum.
- JSON ist syntaktisch knapp daneben.
- Felder passen nicht exakt.
- `isTrue` kann inkonsistent zum `type` sein.

Empfehlung:

Auf `@Generable` / strukturierte Ausgabe umstellen:

```swift
@Generable
struct SpyHintCandidate {
    @Guide(description: "hint, fake_hint oder challenge")
    var type: String

    @Guide(description: "Ein kurzer deutscher Satz ohne geheimes Wort")
    var content: String

    @Guide(description: "Ob der Hinweis sachlich zum geheimen Wort passt")
    var isTrue: Bool
}
```

Danach trotzdem validieren. Strukturierte Ausgabe ersetzt keine Safety-Pruefung, macht aber die Pipeline stabiler.

### Mittel: `generateRole` und `generateRoles` wirken unfertig

Die Rollen-Methoden enthalten Platzhalter-Kommentare und sind nicht sauber validiert. Wenn diese Methoden spaeter genutzt werden, koennen sie Rollen mit Zusatztext, Duplikaten oder falscher Anzahl liefern.

Empfehlung:

- Falls nicht geplant: entfernen.
- Falls geplant: neu als strukturiertes `GeneratedRoles`-Modell bauen.
- Rollen nie direkt ins Spiel lassen, ohne Whitelist oder Review.

### Mittel: Multiplayer nutzt nicht dieselbe AI-Hint-Pipeline wie Local

Im Multiplayer-Host-Start wird `HintsManager.createSpyCardText(...)` genutzt, nicht die async AI-Variante. Damit werden im Multiplayer nur manuelle Hinweise genutzt, selbst wenn Apple Intelligence verfuegbar waere.

Das ist nicht zwingend falsch, aber es sollte bewusst sein:

- Local: AI-Hints moeglich
- Multiplayer: eher manuelle Hints

Empfehlung:

Entweder:

- Multiplayer bewusst bei manuellen Hinweisen lassen und UI so kommunizieren.

Oder:

- Host generiert AI-Hints vor Role-Payload-Erstellung und verschickt dann die fertigen Karteninhalte.

Wichtig: Clients sollten niemals selbst aus geheimem Wort und Kategorie AI-Hints generieren muessen.

### Mittel: `AITuner` sollte nicht "AI" heissen

`AITuner` ist regelbasiert. Der Name suggeriert aber KI. Das ist fuer Wartung und Nutzerkommunikation schlecht.

Bessere Namen:

- `FairnessTuner`
- `ImposterWeightTuner`
- `RoleFairnessAdjuster`

Auch der Logtext "Spion-Verteilung: KI verfuegbar" sollte geaendert werden, z. B.:

- "Spion-Verteilung: Fairness-Gewichtung aktiv"
- "Spion-Verteilung: Standard-Fairness aktiv"

### Mittel: Public Runtime-Hints koennen das Spiel kippen

Wenn `HintService` spaeter gestartet wird, muss klar sein, wer die Hinweise sehen soll.

Aktuell liegt `HintOverlay` in der normalen Spielansicht. Das bedeutet: Alle sehen die Hinweise. Einige Fallback-Hints sagen z. B. erster Buchstabe oder Wortlaenge. Das waere fuer alle Spieler extrem stark und koennte das Raten zu leicht machen.

Empfehlung:

Fuer oeffentliche Runden-Hints:

- keine Buchstaben
- keine Laenge
- keine echten objektiven Wort-Hints
- eher Aufgaben: "Alle muessen eine Frage stellen", "Der Startspieler muss antworten"
- Fake/Neutral-Funksprueche als Atmosphaere

Fuer Spion-Hints:

- nur auf der privaten Spion-Karte
- nicht im oeffentlichen Overlay

### Mittel: Debug-Logs koennen geheime Inhalte speichern

`HintService.generateHint()` loggt `word`, `type` und `content` in `ModeratorLog`. `ModeratorLog` kann exportiert werden.

Das ist lokal, aber trotzdem relevant:

- waehrend einer Runde koennte ein Debug-/Log-Screen Spoiler enthalten
- exportierte Logs koennen private Spielernamen und geheime Woerter enthalten

Empfehlung:

- Debug-Logs nur in `DEBUG` Builds oder hinter Entwickler-Schalter.
- Geheimwort in Logs maskieren: `wordHash` statt `word`.
- Export nur nach Spielende oder mit Warnung.

### Niedrig bis Mittel: Doppelte Voice-Verantwortung

`AIService` hat einen eigenen `AVSpeechSynthesizer`, `VoiceService` ebenfalls. Praktisch scheint `VoiceService` der aktive Weg zu sein.

Empfehlung:

- TTS aus `AIService` entfernen oder klar in `VoiceService` zentralisieren.
- `AIService` nur fuer Text-/Content-Generierung verwenden.

### Niedrig: Availability-UI ist zu grob

Nutzer sehen nur "Apple Intelligence nicht verfuegbar". Besser waere eine genauere Info:

- Geraet nicht kompatibel
- Apple Intelligence nicht aktiviert
- Modell noch nicht bereit
- iOS-Version zu alt

Das ist besonders wichtig, weil Nutzer sonst denken, die App sei kaputt.

## Spielspass-Bewertung

### Spion-Karten-Hints: sehr sinnvoll

Das Feature verbessert den Spass direkt:

- Spione sind weniger verloren.
- Neue Spieler kommen leichter rein.
- Runden werden weniger schnell enttarnt.
- Kategorie/Hints/andere Spione geben gute Schwierigkeitsregler.

Aber: Die Hinweise muessen vage bleiben. Je konkreter die Hints, desto weniger ist es ein Bluff-Spiel.

### Fake-Hints: gut, aber nur mit Kontrolle

Fake-Hints koennen lustig sein, wenn sie selten und subtil sind. Zu viele Fake-Hints fuehlen sich aber unfair an.

Aktuelle Verteilung in `generateGameContent(...)`:

- 50 Prozent echte Hinweise
- 30 Prozent Challenges
- 20 Prozent Fake-Hints

Das ist als Start okay. Fuer oeffentliche Funksprueche waere ich vorsichtiger. Fuer Spion-Hilfe auf Karten sollten Fake-Hints nicht ungekennzeichnet erscheinen, weil der Spion ohnehin schon benachteiligt ist.

Empfehlung:

- Spion-Karte: eher echte, vage Hints.
- Public Funk: Fake/Chaos erlaubt.
- Settings: "Mehr Chaos" koennte Fake-Hints erhoehen.

### AI-Fairness: aktuell eher Marketing als Feature

Die Fairness-Logik ist gut, aber nicht AI. Sie sollte als Fairness-System verkauft werden, nicht als KI.

Das ist auch besser fuer Vertrauen:

- Spieler akzeptieren faire Rotation.
- Spieler misstrauen eher einer "KI", die heimlich Rollen verteilt.

## Code-Qualitaetsbewertung

| Bereich | Bewertung | Kommentar |
|---|---:|---|
| Foundation-Models-Gating | 7/10 | Gute Grundstruktur, aber Availability-Grund fehlt. |
| Hint-Validierung | 8/10 | Starke Richtung, aber noch keine strukturierte Ausgabe. |
| Fallbacks | 7/10 | Vorhanden, aber UI deaktiviert einige Fallbacks unnoetig. |
| Spielintegration | 5/10 | Spy-Karten gut, Runtime-Hints/Logs/Rollen nicht sauber verdrahtet. |
| Datenschutz | 7/10 | On-device gut, Logs sollten Geheimnisse maskieren. |
| Swift Concurrency | 6/10 | Actor/Request-Limiter gut, aber statische mutable Rotation ist nicht ideal. |
| UI-Verstaendlichkeit | 5/10 | "KI", "Hinweise", "Spion-Hinweise" und "Apple Intelligence" sind zu vermischt. |
| Spielspass-Potenzial | 9/10 | Besonders Spion-Hints und AI-Moderator koennen stark werden. |

Gesamt aktuell: **6.8/10**  
Nach Bereinigung der Integration: **8.5/10 realistisch**

## Priorisierte Empfehlungen

### Prioritaet 1: Begriffe und Toggles sauber trennen

Empfohlene Nutzerbegriffe:

- "Spion-Hilfen" fuer private Karten-Hints
- "Runden-Funksprueche" fuer oeffentliche laufende Meldungen
- "Apple Intelligence" nur als technischer Status im Detail
- "Fairness-System" statt AI fuer Rollenverteilung

Damit versteht der Nutzer, was passiert.

### Prioritaet 2: Spion-Hints ohne Apple Intelligence erlauben

Der Toggle sollte nicht von `AIService.shared.isAvailable` abhaengen. Die App hat lokale Hinweise und Fallbacks.

Zielverhalten:

- AI verfuegbar: manuelle Hints + generierte Hints
- AI nicht verfuegbar: manuelle Hints + generische Fallbacks
- keine Hints vorhanden: trotzdem Kategorie/andere Spione anzeigen, wenn aktiviert

### Prioritaet 3: Entscheiden, ob Runtime-Hints bleiben

Wenn ja:

- `HintService.startHints(...)` wirklich starten
- nur nach Startspieler-Ankuendigung
- stop bei Spielende, Voting, Timeout und Exit
- Content stark entschärfen
- keine echten Wort-Hints fuer alle

Wenn nein:

- `HintService`, `HintOverlay`, `enableHints` UI vorerst entfernen oder ausblenden
- AI-Fokus auf Spion-Karten legen

### Prioritaet 4: Strukturierte Foundation-Models-Ausgabe

Fuer alle AI-Antworten:

- weg von "Antworte NUR JSON"
- hin zu `@Generable`
- danach weiterhin harte lokale Validierung
- Retry nur bei konkretem Validierungsfehler

### Prioritaet 5: Tote/unfertige AI-Pfade entfernen oder anschliessen

Pruefen:

- `generateMissionFlavor(...)`
- `generateModeratorLog(...)`
- `generateRole(...)`
- `generateRoles(...)`
- `AIHintDTO`

Wenn sie nicht produktiv genutzt werden: rausnehmen oder als geplante Phase sauber dokumentieren. Unfertiger AI-Code macht spaetere Bugs wahrscheinlicher.

### Prioritaet 6: Tests fuer Spoiler-Schutz

Unbedingt automatisierte Tests fuer:

- Wort darf nie im Hint vorkommen
- zusammengesetzte Begriffe
- Umlaute/ss/ß
- Mehrwort-Begriffe
- Zahlen/Buchstaben-Hints
- Fake-Hint vs echter Hint
- Kategorie-Anker
- Fallback bei ungueltiger AI-Ausgabe

## Konkrete Zielarchitektur

Statt `AIService` als Sammelbecken fuer alles:

```swift
protocol SpyAIProviding {
    var availability: SpyAIAvailability { get }
    func generateSpyHintPack(input: SpyHintInput) async -> SpyHintPack
    func generateRoundBroadcast(input: RoundBroadcastInput) async -> RoundBroadcast
    func explainFairness(input: FairnessExplanationInput) async -> FairnessExplanation
}

enum SpyAIAvailability {
    case unavailable(reason: String)
    case localFallbackOnly
    case appleIntelligence
}
```

Dann klare Services:

- `SpyCardHintService`: private Spion-Karten-Hilfen
- `RoundBroadcastService`: oeffentliche Runden-Funksprueche
- `FairnessExplanationService`: erklaert Fairness, entscheidet sie aber nicht
- `SpyAIValidator`: Wort-Leak- und Safety-Validierung

Das wuerde die aktuelle Vermischung von AI, Voice, Logs, Rollen und Hints deutlich reduzieren.

## Meine Produkt-Empfehlung

Fuer die naechste Version wuerde ich nicht versuchen, "mehr KI" einzubauen. Ich wuerde die vorhandene KI enger, ehrlicher und sichtbarer machen:

1. **Spion-Hilfen immer verfuegbar machen**, auch ohne Apple Intelligence.
2. **Apple Intelligence als Verbesserung kennzeichnen**, nicht als Voraussetzung.
3. **Runtime-Hints entweder korrekt starten oder entfernen.**
4. **AI-Rollen/Logs/Mission-Flavour nicht bewerben**, solange sie nicht wirklich genutzt werden.
5. **AI-Ausgabe auf strukturierte Foundation-Models-Ausgabe umstellen.**

Das Ergebnis waere fuer Nutzer verstaendlicher und fuer dich technisch leichter wartbar.

## Endbewertung

Die Idee ist sehr gut: On-device KI passt perfekt zu einem Spy-Spiel, weil sie private, variable und situationsbezogene Hinweise liefern kann. Die App hat schon mehrere richtige Schutzmechanismen. Der aktuelle Schwachpunkt ist nicht die Idee, sondern die Produktklarheit:

- Was ist echte KI?
- Was ist Fallback?
- Was ist Spion-Hilfe?
- Was ist oeffentlicher Hinweis?
- Was ist Fairness-Logik?

Wenn diese Grenzen sauber gezogen werden, kann die Spy-KI eines der staerksten Features in der ganzen Games Collection werden.
