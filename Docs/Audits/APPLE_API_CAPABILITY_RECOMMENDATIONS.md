# Apple API-, Capability- und Feature-Audit fuer Games Collection

Stand: 2026-05-07  
Scope: Analyse und Empfehlung, keine Code-Aenderungen, keine neuen Capabilities, keine Paketinstallation.

## 1. Kurze Gesamteinschaetzung

Die App ist bereits klar als lokale Partyspiel-Sammlung gebaut: SwiftUI, Dark-UI, mehrere eigenstaendige Spiele, Party-Modus, globale Spieler/Statistiken, Haptik, Sound, lokale Speicherung, MultipeerConnectivity, QR-Code-Erzeugung und externe Anzeige sind schon vorhanden.

Der groesste Mehrwert liegt nicht darin, moeglichst viele Apple-Frameworks zu aktivieren. Der groesste Hebel ist: schnellerer Spielstart, stabilerer lokaler Multiplayer, bessere Wiederverwendung eigener Inhalte, Premium-Angebote ohne Login-Zwang und saubere Datenschutz-Kommunikation.

Wichtig: In den Entitlements sind bereits `Game Center` und `Group Activities` eingetragen. In der Codebasis sehe ich aber keine echte GameKit- oder SharePlay-Nutzung. Das sollte bereinigt oder konsequent ausgebaut werden, weil ungenutzte Capabilities im App-Review und in der Wartung nur Ballast sind.

## 2. Top 10 sinnvollste Ergaenzungen

| Rang | Ergaenzung | Warum sinnvoll? | Empfehlung |
|---:|---|---|---|
| 1 | Lokales Netzwerk sauber fertigstellen | Multiplayer passt perfekt zu Partyspielen; MultipeerConnectivity ist schon vorhanden | Must-have |
| 2 | QR-Code-Beitritt mit Kamera-Scan | Weniger PIN-Tippen, schnellerer Spielstart | Must-have fuer Multiplayer |
| 3 | Eigene Kategorien/Decks vereinheitlichen | Nutzer bekommen Wiederspielwert; Entwickler bekommt ein klares Inhaltsmodell | Must-have |
| 4 | SwiftData fuer Custom-Inhalte | Besser als viele verstreute UserDefaults/JSON-Dateien, sobald Inhalte wachsen | Must-have mittelfristig |
| 5 | StoreKit 2 / In-App Purchase | Saubere Monetarisierung fuer Premium-Decks, Pro-Modus, KI-Funktionen | Must-have bei Monetarisierung |
| 6 | Share Sheet und Import/Export | Nutzer koennen eigene Kategorien teilen, ohne Account oder Server | Must-have fuer Custom-Decks |
| 7 | TipKit | Kleine Hinweise in komplexen Spielphasen statt langer Tutorials | Nice-to-have |
| 8 | App Intents / Shortcuts | "Starte Imposter" oder "Starte Falsche Faehrte" als Systemintegration | Nice-to-have |
| 9 | External Display / AirPlay gezielt ausbauen | TV als gemeinsames Spielfeld passt sehr gut zu Gruppen | Nice-to-have, bereits begonnen |
| 10 | CoreMotion fuer Stirn-/Scharade-Modi | Kippen fuer richtig/passen fuehlt sich natuerlich an | Nice-to-have, spielabhaengig |

## 3. Top 10 Dinge, die du NICHT hinzufuegen solltest

| Thema | Warum nicht? | Empfehlung |
|---|---|---|
| App Tracking Transparency | Tracking passt nicht zur App und schreckt Nutzer ab | Nein |
| Standort | Kein echter Nutzen fuer Partyspiele | Nein |
| Kontakte | Spieler koennen Namen selbst eingeben; Kontakte wirken invasiv | Nein |
| Sign in with Apple | Login bremst Partys aus; lokale Profile reichen | Nein |
| Apple Pay | Digitale Inhalte laufen ueber StoreKit, nicht Apple Pay | Nein |
| HealthKit | Kein Bezug zum Produkt | Nein |
| HomeKit | Kein Bezug zum Produkt | Nein |
| CoreBluetooth direkt | MultipeerConnectivity deckt den Bedarf besser ab | Nein, ausser Spezialhardware |
| Firebase/Tracking-SDKs | Datenschutz- und Wartungsballast fuer wenig Nutzermehrwert | Eher nein |
| Push-Marketing | Partyspiel-Apps sollten nicht nerven | Nein, lokale Timer-Hinweise hoechstens spaeter |

## 4. Apple APIs & Frameworks

| API / Framework | Was ist es? | Entwickler-Mehrwert | Nutzer-Mehrwert | Passt? | Empfehlung |
|---|---|---|---|---|---|
| SwiftUI | UI-Framework fuer moderne Apple-Apps | Schnellere UI-Entwicklung, gute Systemintegration | Moderne Bedienung, Dynamic Type moeglich | Ja, bereits Kern | Must-have |
| Observation | Moderner Zustand fuer SwiftUI | Weniger Boilerplate als ObservableObject | Stabilere, direktere UI-Updates | Ja, bereits genutzt | Weiter ausbauen |
| Combine | Reaktive Datenstroeme | Gut fuer bestehende Timer/Publisher/NotificationCenter-Bruecken | Indirekt stabilere App | Teilweise | Nur dort behalten, wo es schon passt |
| SwiftData | Lokale Datenbank | Sauberere Modelle fuer Spieler, Statistiken, Kategorien | Eigene Decks bleiben erhalten und sind besser verwaltbar | Ja | Must-have mittelfristig |
| StoreKit 2 | In-App-Kaeufe und Bewertungen | Monetarisierung ohne Backend | Sicherer Kaufprozess | Ja bei Pro-Version | Must-have bei Premium |
| Game Center | Achievements, Leaderboards, Challenges | App-Store-Signal, Spielziele | Erfolge koennen motivieren | Nur begrenzt | Vielleicht, nicht fuer Matchmaking |
| SharePlay | Gemeinsames Spielen ueber FaceTime | Kein eigener Server fuer Remote-Runden | Familie/Freunde koennen remote spielen | Ja, aber komplex | Spaeter |
| MultipeerConnectivity | Lokales WLAN/Bluetooth-Multiplayer | Kein Server, offlinefaehig | Spieler im Raum verbinden sich direkt | Ja, bereits vorhanden | Must-have |
| Network Framework | Tieferes Netzwerk-Framework | Mehr Kontrolle als MPC | Nur indirekt | Eher nicht | Nur falls MPC nicht reicht |
| Nearby Interaction | Praezise Naehe/Richtung per UWB | Spezialeffekte moeglich | "Finde den Spieler" waere nett | Kaum Kernnutzen | Eher nicht |
| CoreBluetooth | Direkte Bluetooth-Kommunikation | Kontrolle auf Geraeteebene | Kein Mehrwert gegenueber MPC | Nein | Unnoetig |
| App Intents / Shortcuts | Systemaktionen fuer Siri/Spotlight | Bessere Wiederkehrpfade | Spiele schneller starten | Ja | Nice-to-have |
| TipKit | Kleine native Hilfetipps | Weniger eigenes Tutorial-UI | Weniger Erklaerungsaufwand | Ja | Nice-to-have |
| WidgetKit | Homescreen/Lockscreen Widgets | App-Praesenz ausserhalb der App | Spielidee des Tages | Begrenzt | Spaeter |
| ActivityKit | Live Activities/Dynamic Island | Sichtbarer Timer ausserhalb der App | Timer bleibt sichtbar | Fuer Timer-Spiele ja | Spaeter |
| UserNotifications | Lokale/Push-Benachrichtigungen | Timer-/Reminder-Features | Reminder oder Rundenende | Eher lokal | Vielleicht spaeter |
| AVFoundation | Audio, Sprache, Kamera/Medien | Sound/TTS zentral umsetzbar | Mehr Atmosphaere | Ja, bereits genutzt | Must-have |
| Speech Framework | Sprache zu Text | Voice-Eingaben moeglich | Hands-free Antworten | Risiko/Komplexitaet hoch | Eher nicht |
| Vision | Bilderkennung, QR/Barcode | QR-Scan moeglich | Schneller Beitritt | Ja fuer QR | Nur fuer QR |
| CoreImage | Bildfilter, QR-Erzeugung | QR-Codes ohne Paket | Teilen/Beitreten | Ja, bereits genutzt | Behalten |
| PhotosUI | Fotos aus Mediathek | Avatare/Deck-Bilder | Personalisierung | Nicht zentral | Eher nicht |
| CoreLocation | Standort | Kaum Nutzen | Kein echter Nutzen | Nein | Unnoetig |
| CoreMotion | Bewegungssensoren | Neigungssteuerung | Stirnspiel fuehlt sich natuerlich an | Ja fuer Charade/TimesUp | Nice-to-have |
| CoreHaptics | Praezise Haptik | Wiederverwendbare Haptik-Muster | Spannung bei Timer/Voting | Ja, bereits teils genutzt | Ausbauen |
| LocalAuthentication | Face ID/Touch ID | Schutz fuer private Bereiche | Kaum Nutzen | Nein | Unnoetig |
| CloudKit / iCloud | Sync und Backup | Geraetewechsel ohne Account | Eigene Decks bleiben erhalten | Ja fuer Custom-Decks | Spaeter |
| App Groups | Datenaustausch mit Widgets | Widget kann App-Daten lesen | Bessere Widgets | Nur mit Widgets | Spaeter |
| Keychain | Sicherer Speicher | Tokens/Kaufstatus nicht noetig; StoreKit verwaltet Kaeufe | Kein direkter Nutzen | Kaum | Eher nicht |
| Privacy Manifest | Datenschutz-Erklaerung fuer APIs | App-Review sauberer | Vertrauen | Ja, bereits vorhanden | Pflegen |
| Accessibility APIs | VoiceOver, Dynamic Type, Reduce Motion | Weniger Support, bessere Qualitaet | Mehr Menschen koennen spielen | Ja | Must-have |
| ATT | Tracking-Erlaubnis | Nur fuer Werbe-Tracking | Misstrauen | Nein | Nicht nutzen |

## 5. Geraetefunktionen & Berechtigungen

| Berechtigung / Funktion | Braucht die App das wirklich? | Feature | Mehrwert fuer Spieler | Datenschutz-/Review-Risiko | Info.plist-Erklaerung |
|---|---|---|---|---|---|
| Kamera | Ja, wenn QR-Scan kommt | Lobby/Deck per QR scannen | Beitritt in Sekunden | Mittel, klar begruenden | "Wird nur zum Scannen von QR-Codes fuer Spielbeitritt und Kategorien genutzt. Es werden keine Fotos gespeichert." |
| Mikrofon | Eher nein | Applaus-/Lautstaerke-Modus | Witziger Party-Effekt | Hoch, Nutzer sind sensibel | "Wird genutzt, um im Spiel die Lautstaerke zu messen. Audio wird nicht gespeichert oder uebertragen." |
| QR-Code-Scan | Ja | Kamera + Vision/AVFoundation | Weniger Tippen | Mittel | Siehe Kamera |
| WLAN / lokales Netzwerk | Ja fuer Multiplayer | Host und Mitspieler im selben Raum | Offline-Multiplayer | Mittel, Local-Network-Prompt | "Erlaubt das Finden von Spielern im selben lokalen Netzwerk fuer gemeinsame Spielrunden." |
| Bluetooth | Indirekt ueber MPC | Lokale Verbindung | Hilft ohne klassisches WLAN | Niedrig bis mittel | Normalerweise keine separate Bluetooth-Erklaerung bei MPC |
| Standort | Nein | Keine passende Kernfunktion | Keiner | Hoch | Nicht anfordern |
| Kontakte | Nein | Spielerimport | Spart etwas Tippen | Hoch, wirkt unnoetig | Nicht anfordern |
| Fotos | Eher nein | Avatare/Kategorie-Bilder | Personalisierung | Mittel | Nur bei echtem Avatar-Feature |
| Benachrichtigungen | Eher spaeter | Lokaler Timer/Reminder | Timer sichtbar/erinnernd | Mittel, Push vermeiden | "Sendet lokale Hinweise fuer laufende Spieltimer und optionale Erinnerungen." |
| Haptik | Ja | Timer, Reveal, Voting | Mehr Spannung | Niedrig, keine Permission | Keine Info.plist noetig |
| Face ID / Touch ID | Nein | Schutz fuer Eltern-/Premiumbereich | Gering | Mittel, wirkt uebertrieben | Nicht anfordern |
| Spracheingabe | Eher nein | Antworten diktieren | Hands-free | Hoch wegen Mikro/Speech | Nur mit sehr starkem Use Case |
| Bewegungssensoren | Vielleicht | Stirnspiel: kippen fuer richtig/passen | Sehr intuitiv | Niedrig | Meist keine Permission |
| Bildschirmhelligkeit | Vielleicht ohne Permission | "Tischmodus" heller Bildschirm | Besser lesbar in Gruppen | Niedrig, aber nicht ungefragt stark aendern | Keine |
| AirPlay / externe Anzeige | Ja, bereits begonnen | TV zeigt Board, iPhone steuert | Gruppen sehen alles besser | Niedrig | Keine normale Permission |
| Share Sheet | Ja | Decks/Kategorien teilen | Einfaches Teilen | Niedrig | Keine Permission |
| Apple Watch | Eher nicht | Timer/Vibration am Handgelenk | Gering | Aufwand hoch | Nicht priorisieren |

## 6. Signing & Capabilities

| Capability | Aktivieren? | Warum? | Konkretes Feature | Aufwand | Risiko |
|---|---|---|---|---|---|
| Push Notifications | Nein | Kein Kernnutzen | Nur spaeter lokale Timer ohne Push moeglich | Mittel | Mittel |
| iCloud | Vielleicht | Backup eigener Decks/Spieler | iCloud Sync fuer Custom-Inhalte | Mittel | Niedrig |
| CloudKit | Vielleicht | Strukturierter Sync | Eigene Kategorien auf neues Geraet | Mittel | Mittel |
| App Groups | Vielleicht | Nur fuer Widgets/Extensions | Widget liest Spielideen/Statistik | Mittel | Niedrig |
| Game Center | Vielleicht | Achievements ja, Matchmaking nein | "Erste Runde gewonnen", globale Statistiken optional | Mittel | Mittel |
| Associated Domains | Vielleicht | Deep Links fuer geteilte Decks | Link oeffnet Import direkt in App | Mittel | Mittel |
| In-App Purchase | Ja bei Premium | Saubere Monetarisierung | Pro, Premium-Decks, KI-Packs | Mittel | Niedrig |
| Sign in with Apple | Nein | Login bremst lokale Party | Kein Kernfeature | Hoch | Mittel |
| Background Modes | Nein | Timer kann ueber ActivityKit/Scene-State laufen | Kein echter Dauer-Hintergrundbedarf | Mittel | Hoch |
| Keychain Sharing | Nein | Keine sensiblen geteilten Tokens | Kein Feature | Niedrig | Niedrig |
| Nearby Interaction | Nein | UWB-Spielerei | "Finde Spieler" | Hoch | Mittel |
| Access WiFi Information | Nein | Fuer MPC normalerweise nicht noetig | SSID-basierte Logik vermeiden | Mittel | Hoch |
| Multicast Networking | Vielleicht nur bei eigener Discovery | MPC/Bonjour reicht meist | Eigener lokaler Server | Hoch | Mittel |
| Apple Pay | Nein | Nicht fuer digitale App-Inhalte | Keins | Hoch | Hoch |
| HealthKit | Nein | Kein Produktbezug | Keins | Hoch | Hoch |
| HomeKit | Nein | Kein Produktbezug | Keins | Hoch | Hoch |
| Siri / App Intents | Vielleicht | Komfortabler Spielstart | "Starte Imposter" | Mittel | Niedrig |
| Maps / Location | Nein | Kein Produktbezug | Keins | Mittel | Hoch |
| Group Activities | Vielleicht | Nur wenn SharePlay wirklich gebaut wird | FaceTime-Spielrunde | Hoch | Mittel |

Konkreter Ist-Zustand: `Games Collection.entitlements` enthaelt Game Center und Group Activities. Wenn du diese Features nicht kurzfristig baust, wuerde ich sie entfernen. Wenn du sie behalten willst, sollten sie in einer Roadmap bewusst umgesetzt werden.

## 7. Externe Pakete / Swift Packages

Vorhanden: Lottie, Pow, SFSafeSymbols, Swift Algorithms, Swift Async Algorithms, Swift Collections, Swift Numerics.

| Kategorie | Paket noetig? | Native Alternative | Bewertung |
|---|---|---|---|
| Animationen | Teilweise | SwiftUI Animationen, PhaseAnimator, KeyframeAnimator, sensoryFeedback | Lottie/Pow behalten, aber nicht weiter ausufern lassen |
| Onboarding | Nein | SwiftUI + TipKit | Kein extra Paket |
| Paywall / Revenue | Vielleicht | StoreKit 2 pur | Erst StoreKit nativ pruefen; RevenueCat nur bei A/B, Webhooks, vielen Produkten |
| Analytics | Eher nein | App Store Connect, MetricKit, einfache lokale Events | Kein Tracking-SDK zum Start |
| Crash Reporting | Vielleicht | Xcode Organizer, MetricKit | Sentry nur, wenn echte Produktions-Crashes schwer greifbar sind |
| Remote Config | Eher nein | Lokale Feature Flags, ggf. CloudKit spaeter | Kein SDK am Anfang |
| QR-Code | Nein fuer Erzeugung, Scan nativ | CoreImage, AVFoundation/Vision | Native Loesung reicht |
| Charts | Nein | Swift Charts | Nur fuer Statistik-Ansichten |
| Haptics | Nein | CoreHaptics, sensoryFeedback | Native Loesung |
| Lottie | Bereits vorhanden | SwiftUI Animationen | Fuer hochwertige Assets okay, sparsam nutzen |
| Confetti / Effects | Nein | SwiftUI Canvas/Particles | Kein Paket noetig |
| Local Database | Nein | SwiftData | Native Loesung |
| Networking | Nein | MultipeerConnectivity, URLSession | Kein Alamofire noetig |
| Testing | Ja moeglich | XCTest, Swift Testing | SnapshotTesting als Test-only Paket sinnvoll |
| Snapshot Testing | Ja fuer UI-Qualitaet | XCTest Screenshots sind weniger komfortabel | Sinnvoll als Test-only |
| Design System | Nein | Eigene SwiftUI-Komponenten | Bestehende Styles konsolidieren statt Paket |

## 8. Feature-Ideen mit echtem Mehrwert

| Feature | Warum es passt | APIs | Empfehlung |
|---|---|---|---|
| QR-Beitritt zur Lobby | Schnellster Multiplayer-Start | Kamera, AVFoundation/Vision, MPC | Sofort sinnvoll |
| Host-Geraet + Mitspieler-Geraete | Perfekt fuer Imposter/Falsche Faehrte/Fragen | MPC, External Display | Sofort sinnvoll |
| TV-Modus | Ein Bildschirm fuer Gruppe, private Infos auf iPhones | External Display, AirPlay | Spaeter ausbauen |
| Teilbare Kategorien | Freunde koennen eigene Inside-Joke-Decks teilen | Share Sheet, Deep Links, SwiftData | Sofort sinnvoll |
| Eigene Kategorien zentral | Derzeit mehrere Speicherwege; vereinheitlichen | SwiftData | Sofort sinnvoll |
| Premium-Decks / Pro | Klare Monetarisierung ohne Ads | StoreKit 2 | Premium |
| Game Center Achievements | Kleine Motivation, kein Kernspiel | GameKit | Spaeter |
| SharePlay | Remote-Party ueber FaceTime | GroupActivities | Spaeter, hoher Aufwand |
| Live Activity Timer | Sichtbarer Timer bei Time's Up/Scharade | ActivityKit | Spaeter |
| Widgets mit Spielidee | App bleibt praesent, ohne zu nerven | WidgetKit | Spaeter |
| App Shortcuts | schneller Start einzelner Spiele | App Intents | Nice-to-have |
| Haptik- und Sound-Design pro Spiel | Mehr Spannung und Wertigkeit | CoreHaptics, AVFoundation | Sofort sinnvoll |
| Mikrofon-Lautstaerke-Modus | Lustig, aber Datenschutz/Fehlmessungen | AVFoundation | Experiment, nicht Kern |
| Kamera-Foto-Challenges | Datenschutz wird schwerer | Kamera/PhotosUI | Eher nicht |

## 9. Datenschutz- und App-Review-Risiken

Aktuell stark: Privacy Manifest sagt keine Datenerfassung und kein Tracking. Das ist ein echter Vorteil fuer Vertrauen und App Store.

Kritische Punkte:

- Lokales Netzwerk: Wenn MultipeerConnectivity aktiv ist, braucht die App eine sehr klare `NSLocalNetworkUsageDescription`. Aktuell sehe ich `NSBonjourServices`, aber keine entsprechende Erklaerung im Info.plist-Auszug.
- Kamera: Nur fuer QR-Scan einsetzen. Keine Fotos speichern, keine Kamera als Gimmick erzwingen.
- Mikrofon und Speech: Nur einbauen, wenn das Feature stark genug ist. Sonst wirkt es fuer Nutzer unverhaeltnismaessig.
- Standort, Kontakte, Tracking: Nicht anfragen. Das wuerde Vertrauen kosten und Apple koennte den Zweck hinterfragen.
- Foundation Models / Apple Intelligence: Sehr interessant fuer Kategorie-Generierung, aber immer mit lokalem Fallback, klarer Verfuegbarkeitsanzeige und ohne falsche Versprechen.
- UserDefaults: Fuer Einstellungen okay. Fuer umfangreiche Kategorien, Statistiken und Profile mittelfristig besser in SwiftData migrieren.

Daten, die lokal bleiben sollten:

- Spielernamen
- lokale Statistiken
- eigene Kategorien
- Spielverlauf / Party-Session
- Haptik-/Sound-/Spracheinstellungen

iCloud waere sinnvoll fuer:

- eigene Kategorien/Decks
- eigene Spielerprofile
- gekaufte/entsperrte lokale Inhaltszuordnung nur als Komfort, Kaufstatus bleibt StoreKit

Tracking/Analytics:

- Kein ATT.
- Keine personenbezogene Analytics.
- Wenn ueberhaupt: datensparsame, anonyme technische Events oder nur App Store Connect/MetricKit.

## 10. Entwickler- und Endanwender-Mehrwert

| Bereich | Entwickler-Mehrwert | Endanwender-Mehrwert |
|---|---|---|
| SwiftData | weniger verstreute Speicherlogik | eigene Inhalte gehen weniger verloren |
| Einheitliches Game-Modell | neue Spiele einfacher ergaenzen | konsistentere Bedienung |
| MPC stabilisieren | kein Backend, weniger Kosten | schneller lokaler Multiplayer |
| QR-Join | weniger Lobby-Fehler | schnellerer Spielstart |
| StoreKit 2 | klare Einnahmequelle | faire Pro-Funktionen ohne Werbung |
| Accessibility | weniger Sonderfaelle, bessere Qualitaet | Kinder, Erwachsene und groessere Gruppen kommen besser zurecht |
| Haptik/Sound-System | wiederverwendbare Spielsignale | hochwertigeres Gefuehl |
| Privacy-first | weniger Review- und Support-Risiko | mehr Vertrauen |

## 11. Priorisierte Roadmap

### Sofort sinnvoll

1. MultipeerConnectivity produktionsreif machen: klare Lobby-Zustaende, Reconnect, Fehlertexte, Local-Network-Erklaerung.
2. QR-Code-Scan fuer Lobby und Kategorieimport ergaenzen.
3. Custom-Kategorien/Spieler/Statistiken in ein gemeinsames Speicherkonzept ueberfuehren.
4. Haptik und Sound zentralisieren, damit jedes Spiel konsistent reagiert.
5. Accessibility-Audit pro Spielphase: Dynamic Type, VoiceOver-Namen, Reduce Motion, Kontrast.
6. Ungenutzte Capabilities pruefen: Game Center und Group Activities entweder umsetzen oder entfernen.

### Spaeter sinnvoll

1. SwiftData-Migration fuer eigene Decks, Spielerprofile und Statistiken.
2. External Display/TV-Modus fuer mehr Spiele.
3. App Intents fuer Schnellstart einzelner Spiele.
4. TipKit fuer neue oder komplexe Spielphasen.
5. Game Center Achievements, wenn du kleine Ziele und Wiederspielwert willst.
6. iCloud Sync fuer Custom-Decks, wenn Nutzer viele eigene Inhalte erstellen.

### Nur bei Premium-Version sinnvoll

1. StoreKit 2 fuer Pro-Funktionen.
2. Premium-Kategorien oder grosse Themenpakete.
3. SharePlay als hochwertiges Remote-Feature.
4. Associated Domains fuer teilbare Deck-Links.
5. WidgetKit/Live Activities als Premium-Polish, nicht als Basis.

### Eher nicht sinnvoll

1. Login-System.
2. Standort, Kontakte, Tracking.
3. Apple Watch als eigener Client.
4. CoreBluetooth direkt.
5. Push-Marketing.
6. HealthKit, HomeKit, Apple Pay.

## 12. Entscheidungstabelle

| Funktion / API / Capability | Was macht es? | Entwickler-Mehrwert | Nutzer-Mehrwert | Aufwand | Risiko | Empfehlung |
|---|---|---|---|---|---|---|
| SwiftUI | Baut die Oberflaeche | Hohe Geschwindigkeit, moderne APIs | Moderne App | Niedrig | Niedrig | Must-have, behalten |
| Observation | Verwaltet App-Zustand | Weniger Boilerplate | Stabilere UI | Mittel | Niedrig | Ausbauen |
| Combine | Datenstroeme/Publisher | Gut fuer bestehende Services | Indirekt | Niedrig | Niedrig | Gezielt behalten |
| SwiftData | Lokale Datenbank | Sauberere Persistenz | Eigene Inhalte bleiben sauber | Mittel | Mittel | Mittelfristig ja |
| StoreKit 2 | In-App-Kaeufe | Umsatz ohne Backend | Faire Premium-Funktionen | Mittel | Niedrig | Ja bei Premium |
| Game Center | Achievements/Leaderboards | App-Store-Feature | Ziele und Erfolge | Mittel | Mittel | Vielleicht |
| SharePlay | FaceTime-Spielrunden | Kein eigener Remote-Server | Remote-Gruppen | Hoch | Mittel | Spaeter |
| MultipeerConnectivity | Lokaler Multiplayer | Kein Backend | Offline im Raum spielen | Mittel | Mittel | Must-have |
| QR-Code-Scan | Beitritt/Import per Kamera | Weniger Support | Schneller Start | Mittel | Mittel | Must-have fuer Multiplayer |
| CoreImage QR | QR-Codes erzeugen | Kein Paket | Einfaches Teilen | Niedrig | Niedrig | Behalten |
| AVFoundation Audio | Sound/TTS | Zentrale Audiofeatures | Stimmung | Niedrig | Niedrig | Must-have |
| CoreHaptics | Praezise Vibration | Wiederverwendbare Effekte | Spannung | Niedrig | Niedrig | Ausbauen |
| CoreMotion | Neigung erkennen | Neue Spielmodi | Natuerliche Steuerung | Niedrig | Niedrig | Spielabhaengig ja |
| TipKit | Kleine Hinweise | Weniger eigenes Tutorial | Weniger Frust | Niedrig | Niedrig | Nice-to-have |
| App Intents | Siri/Spotlight-Aktionen | Systemintegration | Schnellstart | Mittel | Niedrig | Nice-to-have |
| WidgetKit | Homescreen-Widgets | Mehr Praesenz | Spielideen | Mittel | Niedrig | Spaeter |
| ActivityKit | Live Timer | Modernes iOS-Feature | Timer bleibt sichtbar | Mittel | Niedrig | Spaeter |
| UserNotifications | Hinweise | Timer/Reminder | Erinnerung | Mittel | Mittel | Nur lokal, spaeter |
| CloudKit/iCloud | Sync/Backup | Kein eigenes Backend | Decks auf neuem Geraet | Mittel | Mittel | Spaeter |
| App Groups | App-Extension-Daten | Widget-Zugriff | Bessere Widgets | Mittel | Niedrig | Nur mit Widget |
| Associated Domains | Universal Links | Geteilte Decks sauber oeffnen | Einfacher Import | Mittel | Mittel | Bei Sharing ja |
| Local Network | Netzwerk-Prompt | Multiplayer moeglich | Geräte finden sich | Niedrig | Mittel | Ja, sauber erklaeren |
| Camera Permission | Kamera nutzen | QR-Scan | Beitritt in Sekunden | Mittel | Mittel | Nur fuer QR |
| Microphone | Audio aufnehmen/messen | neue Party-Modi | Applaus/Lautstaerke | Mittel | Hoch | Eher nicht |
| PhotosUI | Fotos waehlen | Avatare | Personalisierung | Mittel | Mittel | Eher nicht |
| CoreLocation | Standort | keiner | keiner | Mittel | Hoch | Nein |
| Contacts | Kontakte lesen | wenig | wenig | Mittel | Hoch | Nein |
| LocalAuthentication | Face ID | Schutz | kaum | Mittel | Mittel | Nein |
| Keychain | Geheimnisse speichern | Tokens sicher | unsichtbar | Niedrig | Niedrig | Derzeit nein |
| ATT | Tracking | Werbedaten | kein Nutzen | Mittel | Hoch | Nein |
| HealthKit | Gesundheitsdaten | keiner | keiner | Hoch | Hoch | Nein |
| HomeKit | Smart Home | keiner | keiner | Hoch | Hoch | Nein |
| Apple Pay | Zahlungen | fuer physische Leistungen | kein passender Use Case | Hoch | Hoch | Nein |
| Lottie | Designer-Animationen | hochwertige Effekte | Polished UI | Niedrig | Mittel | Behalten, sparsam |
| Pow | SwiftUI-Effekte | schnelle Effekte | Wertigkeit | Niedrig | Mittel | Behalten, sparsam |
| SFSafeSymbols | Typsichere Symbole | weniger Tippfehler | konsistente Icons | Niedrig | Niedrig | Behalten |
| SnapshotTesting | UI-Tests | Layout-Regressionsschutz | weniger UI-Fehler | Mittel | Niedrig | Test-only sinnvoll |

