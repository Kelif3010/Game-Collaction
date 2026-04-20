# Produktchancen und fehlende Kernfeatures

## Ziel

Dieses Dokument bündelt die größten Produktchancen der App `Games Collection`.
Der Fokus liegt nicht auf Bugfixes oder technischem Cleanup, sondern auf Features,
die die App von einer guten Spielesammlung zu einem starken, wiederkehrend
genutzten Party-Produkt weiterentwickeln.

---

## 1. App-weites Onboarding

### Warum das fehlt

Aktuell wirkt der Einstieg noch zu sehr wie eine direkte Spielauswahl.
Ein gutes app-weites Onboarding würde neue Nutzer schneller zu einer passenden
Spielentscheidung führen und den Recommender zum zentralen Einstiegspunkt machen.

### Zielbild

- Nutzer beantworten direkt beim Einstieg:
- Wie viele seid ihr?
- Wie lange habt ihr?
- Wollt ihr laut, intim, aktiv oder clever spielen?
- Danach bekommt die Gruppe 3 kuratierte Spielvorschläge
- Jeder Vorschlag soll mit einem Tap direkt startbar sein

### Nutzen

- Schnellere Time-to-Fun
- Weniger Entscheidungsfriktion
- Höhere Relevanz der Spielvorschläge
- Besserer erster Eindruck für neue Nutzer

### Mögliche MVP-Umsetzung

- Intro-Flow mit 3 bis 4 Fragen
- Übergabe der Antworten an den bestehenden Recommender
- Anzeige von Top-3-Empfehlungen mit klarem CTA
- Option: „Direkt loslegen“ oder „Weitere Spiele ansehen“

---

## 2. Meta-Session statt Einzelspiel-Start

### Warum das fehlt

Die App besteht aktuell primär aus einzelnen Spielen.
Es fehlt eine verbindende Session-Ebene, die mehrere Spiele zu einer gemeinsamen
Party oder einem Abend zusammenführt.

### Zielbild

- Nutzer können eine komplette Party-Session starten
- Eine Session besteht aus mehreren Spielen hintereinander
- Es gibt Gesamtpunkte, Teamduelle und Session-Ziele
- Am Ende erscheint ein gemeinsamer Recap für den ganzen Abend

### Nutzen

- Aus einer Spielesammlung wird ein echtes Party-System
- Höhere Session-Länge
- Mehr Retention durch zusammenhängenden Spielfortschritt
- Klarere soziale Dynamik in Gruppen

### Mögliche MVP-Umsetzung

- Neuer Einstiegspunkt: „Party starten“
- Auswahl von 3 bis 5 Spielen für eine Session
- Globaler Session-Score für Teams oder Spieler
- Abschluss-Screen mit Gewinnern und Highlights

---

## 3. Persistente Party-Profile

### Warum das fehlt

Wiederkehrende Gruppen sollten nicht bei jeder Session erneut alles konfigurieren
müssen. Die App hat bereits Ansätze mit Crew-Management, aber noch keine
vollständigen Party-Profile.

### Zielbild

- Crews dauerhaft speichern
- Lieblingsmodi speichern
- Letzte Einstellungen pro Spiel merken
- Wiederkehrende Gruppen mit einem Tap laden

### Nutzen

- Weniger Setup-Aufwand
- Schnellere Starts für bekannte Gruppen
- Höhere Wahrscheinlichkeit für Wiederbenutzung
- Bessere Personalisierung

### Mögliche MVP-Umsetzung

- Profilmodell für Gruppenname, Spieler, bevorzugte Spiele, letzte Modi
- „Letzte Runde fortsetzen“ oder „Crew erneut laden“
- Pro Spiel zuletzt genutzte Settings automatisch vorschlagen

---

## 4. App-weite Achievements und Progression

### Warum das fehlt

Es gibt bereits Stats-Ansätze, aber noch kein echtes app-weites
Progressionssystem mit klarer Motivation und Belohnungslogik.

### Zielbild

- App-weite Achievements
- Fortschritt über alle Spiele hinweg
- Sichtbare Meilensteine und Sammelziele

### Beispiel-Achievements

- 100 Runden gespielt
- Imposter 5x gewonnen
- Perfekte Bet-Buddy-Runde
- 6-Spiel-Challenge abgeschlossen

### Nutzen

- Höhere Retention
- Mehr Motivation zum Ausprobieren aller Spiele
- Mehr Langzeitwert auch für bestehende Nutzer

### Mögliche MVP-Umsetzung

- Achievement-Datenmodell mit IDs, Regeln und Fortschrittswerten
- Zentrale Achievement-Übersicht in den Einstellungen oder im Recap
- Kleine Unlock-Momente mit Animation und Haptik

---

## 5. Shareable Recaps

### Warum das fehlt

Die App erzeugt soziale Momente, aber diese Momente sind noch nicht stark genug
nach außen teilbar. Genau hier steckt virales Potenzial.

### Zielbild

- Session-Recaps als teilbare Karten oder Stories
- Inhalte wie:
- lustigste Runde
- Sieger-Team
- meistgesagter Begriff
- Session-Statistik als Bild oder Story-Format

### Nutzen

- Mehr organische Reichweite
- Höhere emotionale Bindung
- Sichtbare Erinnerung an den Abend

### Mögliche MVP-Umsetzung

- 1 bis 2 visuell starke Share-Cards
- Export als Bild
- Direktes Teilen in Instagram Stories, WhatsApp oder iMessage

---

## 6. Robuster Universal-Multiplayer

### Warum das fehlt

Multiplayer ist vorhanden, aber noch nicht als vollständig einheitlicher,
spielübergreifender Produktlayer gelöst.

### Zielbild

- Einheitlicher Lobby-Flow für alle Spiele
- Spielwechsel ohne Session-Verlust
- Host-Wechsel oder Host-Recovery
- QR-Join für einfacheren Einstieg

### Nutzen

- Weniger Setup-Reibung
- Höhere Stabilität in echten Gruppensituationen
- Klarer Differenziator gegenüber einfachen Party-Game-Apps

### Mögliche MVP-Umsetzung

- Gemeinsame Lobby vor Spielstart
- Session-Zustand zentral statt nur spielbezogen
- QR-Code zum Beitreten
- Basale Recovery, wenn der Host ausfällt

---

## 7. UGC und Content-Packs

### Warum das fehlt

Content ist bei Party-Games direkt gleichbedeutend mit Replayability.
Sobald Nutzer eigene Inhalte oder Packs anlegen können, steigt der Langzeitwert
der App deutlich.

### Zielbild

- Eigene Fragen
- Eigene Kategorien
- Private Pack-Sammlungen
- Thematische Packs wie:
- Date Night
- Family
- Office
- Festival

### Nutzen

- Mehr Wiederholungswert
- Stärkere Personalisierung
- Bessere Eignung für unterschiedliche Zielgruppen
- Potenziell spätere Monetarisierungsoptionen

### Mögliche MVP-Umsetzung

- Pro Spiel einfache Custom-Pack-Erstellung
- Lokales Speichern privater Packs
- Packs im Setup auswählbar machen
- Export/Import als spätere Ausbaustufe

---

## Priorisierung nach Produktimpact

### Höchste Priorität

- App-weites Onboarding
- Meta-Session
- Persistente Party-Profile
- App-weite Achievements und Progression

### Mittlere Priorität

- Shareable Recaps
- Robuster Universal-Multiplayer

### Strategisch sehr wertvoll

- UGC und Content-Packs

---

## Empfehlung für die Umsetzung

### Phase 1: Einstieg und Produktstruktur

- App-weites Onboarding
- Persistente Party-Profile
- Meta-Session Basis

### Phase 2: Bindung und Wiederkehr

- Achievements und Progression
- Shareable Recaps

### Phase 3: Differenzierung und Skalierung

- Universal-Multiplayer
- UGC und Content-Packs

---

## Zusammenfassung

Die größten Chancen liegen nicht nur in weiteren Einzelspielen, sondern in der
Meta-Ebene der App:

- besserer Einstieg
- schnellere Gruppensetups
- zusammenhängende Sessions
- stärkere Wiederkehr
- mehr Social- und Share-Potenzial
- mehr eigener Content

Wenn diese Bereiche ausgebaut werden, entwickelt sich `Games Collection` von
einer starken Spielesammlung zu einem deutlich eigenständigeren Party-Produkt
mit mehr Retention, mehr Persönlichkeit und mehr Viralität.
