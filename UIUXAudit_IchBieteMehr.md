# UI/UX Audit: Ich biete mehr

Erstellt: 2026-05-01  
Basis: Vollständige Code-Analyse aller Screens (HomeView, GroupSelectionView, PlayerDrawView, ChallengeStartView, BetBuddyVotingView [inkl. GroupVoteCard], GameView, ResultView, BetBuddyInfoSheet) sowie BET_BUDDY_EXPLANATION.md und DESIGN_GUIDELINES.md.

---

## 1. Kurze Gesamteinschätzung

„Ich biete mehr!" hat ein starkes visuelles Fundament. Das Casino-Thema — Gold, Dunkelgrün, Filztextur, Spielkarten-Flip, Münzanimation — ist konsequent und hochwertig. Das Spiel könnte wirklich toll sein.

Das zentrale Problem ist nicht das Aussehen, sondern die Führung.

An mindestens fünf Stellen im Spielablauf werden neue Spieler innehalten und fragen: „Was soll ich jetzt tun?" Das ist für ein Partyspiel, das in einer lärmenden Gruppe funktionieren muss, ein ernstes Problem.

Die schlimmste Einzelstelle ist der Spielscreen (GameView): Dort muss der aktivste Moment des ganzen Spiels stattfinden, und er enthält zwei große Buttons ohne jegliche Beschriftung. Niemand weiß, was sie tun.

**Einstieg:** Wirkt nicht sofort klar. Setup-Screens fühlen sich wie eine Einstellungsmaske an, kein Spieleinstieg.

**Spielverständnis:** Das Spielprinzip erschließt sich nicht selbst. Neue Spieler brauchen Erklärungen — aber das Onboarding beschreibt an einer Stelle einen anderen Ablauf als die App tatsächlich zeigt.

**Spielgefühl:** Die Einzelmomente sind da — JACKPOT-Screen, Slot-Machine-Auslosung, Münzwurf — aber zwischen diesen Momenten fehlt der Spielfluss. Zu viele Pausen zum Nachdenken.

**Formular oder Spiel:** Der HomeView und der Setup-Bereich wirken wie Einstellungsmenüs. Das Spiel startet zu trocken.

**Größter Hebel:** Bietscreen und Spielscreen. Das sind die Herzstücke des Spiels. Beide brauchen mehr Klarheit.

---

## 2. Versteht man das Spielprinzip sofort?

**Kurzantwort: Nein, nicht ohne Erklärung.**

### Worum es geht

Die Idee des Spiels — mein Partner muss eine Anzahl schaffen, und ich wette, wie viele er schafft — ist clever. Aber sie ist nicht aus dem UI alleine erkennbar. Wer das Onboarding überspringt, steht vor einem Fragezeichen.

### Was geboten wird

Auf dem Bietscreen sieht man eine große Zahl oben. Sie hat kein Label. Neue Spieler wissen nicht: Biete ich auf Punkte? Auf Antworten? Auf Sekunden?

### Wer bietet

Der Auslosungsscreen zeigt „MACHT ES" und „BIETET" — das ist die klarste Information im ganzen Spiel. Aber auf dem Bietscreen ist diese Information verschwunden.

### Wer spielt

Auf dem Bietscreen steht nur der Teamname auf den Karten. Welcher Spieler aus dem Team die Challenge machen muss, ist nicht zu sehen.

### Wann man passt

Es gibt keinen Passen-Button. Das ist nicht per se falsch — die App zeigt eine simultane Bietrunde, bei der alle Teams gleichzeitig tippen. Aber das Onboarding beschreibt eine mündliche Auktionsrunde, bei der Teams abwechselnd bieten oder passen. Das ist ein direkter Widerspruch (→ Rückfrage am Ende).

### Wann ein Deal zustande kommt

Der „DEAL"-Button erscheint auf dem Challenge-Screen, bevor überhaupt geboten wurde. Das ist missverständlich. „Deal" klingt wie das Ergebnis einer Verhandlung — hier bedeutet es aber: „Challenge angesehen, Bietrunde starten."

### Wer die Challenge ausführen muss

Nach der Bietrunde geht es direkt zum Spielscreen. Dort steht oben der Teamname und — wenn Namen eingetragen sind — der aktive Spieler. Aber die Verbindung zur Auslosung ist verloren. Warum genau dieser Spieler? Das steht nicht da.

### Wie Punkte entstehen

Seite 3 des Onboardings erklärt die Punkte gut. Wer das Onboarding übersprungen hat, findet das auf keinem anderen Screen.

### Wann die nächste Runde startet

Der ResultView hat einen klaren „Nächste Runde"-Button. Das ist klar.

---

## 3. Einstieg und Setup

### Teamerstellung (GroupSelectionView)

Die 2/3/4-Auswahl mit animierten Kacheln funktioniert gut und fühlt sich leicht an. Das Auswählen ist sofort verständlich.

**Problem 1:** Die Caption lautet „Jede Gruppe kann aus 2 bis 4 Spielern bestehen." Das stimmt technisch, ist aber missverständlich für das Spielprinzip. Das Spiel basiert darauf, dass in jedem Team genau einer spielt und einer bietet. Mit 3 oder 4 Spielern pro Team rotiert das — aber das steht nirgendwo. Neue Spieler fragen: „Müssen wir zu zweit sein?"

**Problem 2:** Die Begriffe „Gruppe" und „Team" werden gemischt. Der Auswahlbereich heißt „Wie viele Gruppen spielen?", die Karte darunter heißt „Teams einrichten", die Auslosung sagt „Team A". Eine Sprache wählen und durchhalten.

### Spielernamen (PlayerNamesSection)

Das Layout mit nummerierten Badges und Eingabefeldern ist klar und funktioniert.

**Problem:** Nirgendwo steht, was Spieler 1 und Spieler 2 in diesem Spiel bedeuten. Spieler 1 macht die Challenge. Spieler 2 bietet. Das ist der Kern des Spiels — und es steht nirgendwo im Setup.

**Problem:** Die Spielernamen werden als „optional" behandelt. Das stimmt technisch. Aber ohne Namen erscheint auf dem Spielscreen nur „Spieler 1 ist dran" — in einer Gruppe mit 6 Personen weiß niemand, wen das bedeutet.

### Spielstart

Der goldene „Spiel starten"-Button ist klar und gut positioniert. Das ist gut.

### HomeView als Einstellungsscreen

Der HomeView zeigt 6 Einstellungs-Rows: Gruppen, Kategorien, Zeit läuft weiter, Punktabzug, Hinweise, Zeitlimit.

Das wirkt wie ein App-Einstellungsmenü. Kein Titel, kein Spielname, kein visueller Einstieg ins Spielgefühl. Ein Partyspiel sollte schon beim ersten Screen Spannung aufbauen.

**„Zeit läuft weiter"** als Einstellungsname ist verwirrend. Es klingt wie eine Information, nicht wie eine Einstellung. Jemand, der das zum ersten Mal sieht, versteht nicht, was sich ändert, wenn er den Toggle ändert.

### Onboarding (BetBuddyInfoSheet)

Das Onboarding öffnet automatisch beim ersten Start. Das ist eine gute Idee.

**Problem 1:** Seite 2 sagt: „Jedes Team bietet geheim Punkte auf den eigenen Partner." Die Bietrunde ist aber öffentlich und simultan — alle sehen alle Karten gleichzeitig. Das Wort „geheim" ist falsch.

**Problem 2:** Seite 2 sagt: „Tippt auf 'Geschafft', um den Zähler zu senken." Einen Button namens „Geschafft" gibt es nicht. Die zwei Kreis-Buttons im Spielscreen haben kein Label. Das Onboarding referenziert etwas, das in der App nicht existiert.

**Problem 3:** Seite 4 erklärt Einstellungen (Zeit läuft weiter, Punktabzug, Kategorien). Das ist nicht spielrelevant genug für eine Onboarding-Seite eines Partyspiels. Diese Information könnte in einem kleinen „i"-Tooltip neben den Einstellungen stehen.

**Problem 4:** 4 Onboarding-Seiten sind für ein Partyspiel am Spieltisch zu viel. Bis Seite 4 hat die Gruppe das Interesse verloren.

---

## 4. Challenge-Anzeige (ChallengeStartView)

Die Challenge-Karte ist der stärkste visuelle Moment im gesamten Setup-Bereich. Der 3D-Flip beim Erscheinen, der Shimmer-Effekt, die Spielkarten-Optik — das fühlt sich wie ein Spiel an.

### Was gut ist

- Die Karte flippt mit 3D-Animation ins Bild — schöner Moment
- Der Shimmer-Effekt läuft danach über die Karte — charmantes Detail
- Das Kategorie-Badge ist erkennbar
- „Neue Karte ziehen" mit Rotation des Shuffle-Icons funktioniert gut
- Die „DIESE RUNDE"-Leiste unten zeigt aktive Spieler für alle Teams — gute Idee

### Was fehlt oder unklar ist

**Problem 1:** Der Screen heißt im Header „THE DEAL" (Englisch). Der Hauptbutton heißt ebenfalls „DEAL" (Englisch). „DEAL" klingt wie das Ergebnis einer Einigung — hier bedeutet es aber: „Challenge gesehen, weiter zur Bietrunde." Das ist für neue Spieler nicht selbsterklärend.

**Problem 2:** In der „DIESE RUNDE"-Leiste steht für jeden aktiven Spieler „macht es". Was fehlt: „[Spieler 2] bietet für ihn." Diese Info ist entscheidend und fehlt.

**Problem 3:** „KATEGORIE" als Label über dem Badge ist 10pt Monospace. Aus Abstand nicht lesbar. Für eine Gruppe, die auf einen Tisch schaut, bedeutungslos.

**Problem 4:** Die dekorativen Hintergrundkarten (Ass Pik, König Herz) sehen gut aus, lenken aber auf einem iPhone in einer Gruppe ab. Sie nehmen Platz weg, der für eine Spieler-Übersicht oder eine klarere Biet-Einleitung genutzt werden könnte.

**Problem 5:** Nirgendwo auf diesem Screen steht: „Schaut euch die Challenge an. Bietet danach, wie viele [X] euer Partner schafft." Der Übergang zur Bietrunde ist nicht erklärt.

---

## 5. Bietrunde (BetBuddyVotingView + GroupVoteCard)

Das ist der Kern des Spiels — und die schwächste Stelle im gesamten UX-Ablauf.

### 1. Ist klar, welches Team zuerst bietet?

Nein. Alle Teams bieten gleichzeitig. Es gibt keine Reihenfolge. Das ist inhaltlich in Ordnung, wenn es so gewollt ist — aber es wird nirgendwo erklärt. Das Onboarding beschreibt eine abwechselnde Bietrunde. Das widerspricht der App (→ Offene Rückfrage).

### 2. Ist klar, welcher Spieler bietet?

Nein. Die GroupVoteCard zeigt nur den Teamnamen. Der bietende Spieler wird nicht genannt. Das ist die wichtigste Information auf diesem Screen — und sie fehlt.

### 3. Ist klar, für wen geboten wird?

Nein. Auf der Karte steht nicht: „[Spieler 2] bietet jetzt, wie viele [Challenge-Objekte] [Spieler 1] schafft."

### 4. Ist klar, welches aktuelle Höchstgebot gilt?

Teilweise. Der FlipCounter ganz oben zeigt die aktuell höchste Zahl. Aber er hat kein Label. Neue Spieler wissen nicht, was diese Zahl bedeutet.

### 5. Ist klar, welches Team überbieten muss?

Nein. Bei der gleichzeitigen Bietrunde tippen alle für sich. Aber man sieht nicht, ob man bereits die höchste Wette hat oder noch nachziehen muss.

### 6. Ist klar, wie man passt?

Nein. Es gibt keinen Passen-Button. Das ist bei einer simultanen Bietrunde eventuell Absicht. Aber für Spieler, die das Onboarding gelesen haben (das eine mündliche Auktion beschreibt), fehlt dieser Button komplett.

### 7. Ist klar, wann die Bietrunde endet?

Teilweise. Der „Halten zum Bestätigen"-Button ist immer sichtbar. Spieler wissen aber nicht, wann der richtige Moment ist, ihn zu halten — wenn alle Teams ihre Zahlen eingetippt haben? Wenn alle einig sind? Das steht nicht da.

### 8. Ist klar, wer den Deal bekommt?

Ja. Die Krone auf der führenden Team-Karte zeigt klar, welches Team gerade vorne liegt. Das ist gut gelöst.

### 9. Ist die Bietrunde visuell spannend genug?

Nein. Die statischen Karten mit + und - erzeugen keine echte Spannung. Ein Wettbewerbs-Gefühl — bei dem man spürt, dass man gegen ein anderes Team kämpft — entsteht nicht. Die Karten sind isoliert voneinander.

### 10. Gibt es genug Rückmeldung nach jedem Gebot?

Teilweise. Der FlipCounter springt, die Karte skaliert kurz (scaleEffect), die Münzwurf-Animation erscheint. Das sind schöne Momente. Aber: Das Counter oben zeigt nicht, welches Team gerade führt — nur die Zahl.

### 11. Gibt es genug Übersicht bei mehreren Teams?

Nein. Bei 4 Teams ist das 2×2-Grid auf einem iPhone eng. Für eine Gruppe, die auf den Tisch schaut, ist der Text auf den Karten zu klein.

### 12. Wirkt die Bietrunde schnell und spielerisch?

Nein. Sie wirkt wie stilles Formular-Ausfüllen. Das „Wettstreit"-Gefühl einer Casino-Auktion fehlt vollständig.

---

## 6. Aktiver Spieler und Teamwechsel

### Auslosungsscreen (PlayerDrawView) — Stärke des Spiels

Der Slot-Machine-Effekt ist einer der besten Momente im ganzen Spiel:
- Staffel-Animation pro Team
- Haptik beim Einrasten
- Klare „MACHT ES" / „BIETET" Labels
- Grüner Haken nach dem Einrasten

Das ist gut gemacht. Das Spielgefühl kommt hier stark rüber.

**Problem:** Bei Teams mit mehr als 2 Spielern steht statt „BIETET" das Label „NÄCHSTE/R". Das ist technisch korrekt (der nächste Spieler in der Rotation), aber für neue Spieler unklar. Was bedeutet „NÄCHSTE/R"? Der nächste, der dran ist? Der nächste in der Warteschlange?

### Bietscreen (BetBuddyVotingView) — größter Informationsverlust

Die klare Information aus der Auslosung — wer macht es, wer bietet — ist auf diesem Screen komplett verschwunden. Das ist ein harter Bruch in der Spielerführung.

### Spielscreen (GameView)

Oben steht der Teamname und (wenn Namen vorhanden) „[Spieler] ist dran". Das ist ein guter Ansatz. Aber:
- Es fehlt der Hinweis an den Partner: „[Spieler 2] — bitte schweig!"
- Es fehlt die Erklärung warum dieser Spieler dran ist

### Spielerwechsel nach jeder Runde

Der Wechsel passiert automatisch im Hintergrund. Nach „Nächste Runde" erscheint direkt die neue Challenge — aber es gibt keine Ankündigung: „Jetzt ist Spieler 2 aus Team A dran." Spieler merken das erst mitten in der nächsten Challenge.

---

## 7. Buttons und Aktionen

### Spiel starten (HomeView)
Klar, groß, goldfarben, gut positioniert. **Stark.**

### DEAL (ChallengeStartView)
Englisches Wort. Bedeutet hier: „Challenge gesehen, Bietrunde starten." Das erschließt sich nicht von selbst.  
**Empfehlung:** „Bietrunde starten" oder „Wetten!" wäre klarer.

### + und − (GroupVoteCard)
Die großen Kreis-Buttons sind für einen Touch-Screen angemessen groß. Die visuelle Unterscheidung (grüner + vs roter −) ist klar.  
**Problem:** Kein Textlabel erklärt, wofür man das + drückt. „Wette erhöhen" als kleiner Text würde helfen.

### Halten zum Bestätigen (BetBuddyVotingView)
Die Idee eines Hold-Buttons ist gut — verhindert versehentliches Bestätigen. Aber der Moment ist unklar: Wann soll man halten? Das steht nicht da. Und der Button ist immer sichtbar, auch wenn noch niemand geboten hat — er ist aber erst aktiv, wenn wenigstens eine Wette > 0 ist. Das ist nicht sichtbar.

### Aktionsbuttons im Spielscreen (GameView) — größtes Problem

Zwei große Kreis-Buttons ohne jegliches Textlabel.

- **Linker Button** (rot umrandet, kleiner): `chevron.down` im Normal-Modus, `chevron.up` im Alphabet-Modus → bedeutet Korrektur/Zurück
- **Rechter Button** (gold, größer): `chevron.up` im Normal-Modus, `chevron.down` im Alphabet-Modus → bedeutet „Richtig! Eine Antwort geschafft"

Das sind vertauschte Symbole je nach Modus — was das Verständnis noch zusätzlich erschwert.

In einem Partyspiel unter Zeitdruck weiß niemand, welcher Button was tut. Das führt garantiert zu Fehlern und Diskussionen.

**Empfehlung:** Kurze Labels unter den Buttons, z.B. „Richtig" (goldener Button) und „Zurück" (roter Button). Alternativ: gut erkennbare Icons wie ✓ und ↩.

### Aufgeben (GameView)
Klar benannt, hat einen Bestätigungsdialog. **Gut.**

**Aber:** Als großer Outline-Button nimmt er fast die volle Breite ein. Er ist fast so auffällig wie die Aktionsbuttons oben. In einem Partyspiel könnte jemand versehentlich aufgeben wollen.

### Neustart (ResultView)
Der X-Button oben rechts in der TopBar geht direkt zu `onRestart()` ohne Alert. Das ist gefährlich — ein versehentliches Tippen startet das Spiel neu. Es gibt zwar einen Alert beim großen Neustart-Button unten, aber nicht beim TopBar-X.  
**Empfehlung:** Auch der X-Button oben sollte einen Alert auslösen.

### Nächste Runde (ResultView)
Klar benannt, goldfarben hervorgehoben, gut positioniert. **Stark.**

---

## 8. Punkte, Ergebnis und Fortschritt

### Spielstand während des Spiels

Im Spielscreen (GameView) gibt es keinen sichtbaren Gesamtstand. Spieler wissen nicht, ob ihr Team führt oder zurückliegt. Das nimmt Spannung.

### Wann eine Runde vorbei ist

Der Übergang zum ResultView passiert automatisch, wenn der Zähler 0 erreicht oder die Zeit abläuft. Das ist klar.

### Warum ein Team Punkte bekommen hat

Der ResultView zeigt nochmal die Challenge-Text und den JACKPOT/BUST-Status. Das ist gut — Spieler verstehen sofort, was passiert ist.

### Wie viele Runden noch kommen

Nicht sichtbar. Es gibt kein Rundenende oder Punkteziel.

### Wann das Spiel endet

Das Spiel läuft unbegrenzt weiter, bis jemand auf „Neustart" drückt. Für Gruppen, die wissen wollen wann es endet — und wer gewonnen hat — ist das frustrierend.

### Gewinner-Screen

Es gibt keinen Abschluss-Screen. Nach dem letzten „Neustart" wird der Score entweder gelöscht oder behalten. Kein „Team A hat gewonnen!" — kein klarer Moment des Sieges.

### ResultView als Ganzes

Das animierte Leaderboard mit den hochzählenden Punkten ist optisch einer der besten Momente im Spiel. Die Rangliste mit Krone/Medaille/etc. macht den Spielstand interessant. Das ist gut.

---

## 9. Texte und Sprache

### Englische Begriffe — ein Muster

Folgende englische Texte erscheinen mitten in einem deutschen Spiel:

| Screen | Englischer Text | Problem |
|--------|----------------|---------|
| ChallengeStartView | „THE DEAL" | Spielanweisung auf Englisch |
| ChallengeStartView | „DEAL" (Button) | Aktion auf Englisch |
| BetBuddyVotingView | „PLACE YOUR BETS" | Spielanweisung auf Englisch |
| BetBuddyVotingView | „BETTING TABLE" | Abschnittsbezeichnung auf Englisch |
| GroupVoteCard | „RAISE" | Hinweistext auf Englisch |
| GameView | „SHOWDOWN" | Header auf Englisch |
| ResultView | „RESULTS" | Header auf Englisch |
| ResultView | „JACKPOT!" | Ergebnis auf Englisch |
| ResultView | „BUST" | Ergebnis auf Englisch |

**Einschätzung:** „JACKPOT" und „BUST" sind als Casino-Begriffe auch im Deutschen bekannt und funktionieren gut als atmosphärische Elemente. Spielanweisungen wie „PLACE YOUR BETS", „SHOWDOWN" und „THE DEAL" als interaktive Labels oder Aufforderungen in einem deutschen Kontext sind problematisch.

**Empfehlung:** Atmosphärische Dekorationsworte dürfen englisch bleiben. Aber aktive Spielanweisungen und Button-Labels sollten auf Deutsch sein.

### Onboarding-Texte

- „Tippt auf 'Geschafft', um den Zähler zu senken." — Der Button heißt nicht „Geschafft". Er hat kein Label.
- „Jedes Team bietet geheim Punkte auf den eigenen Partner." — Die Bietrunde ist öffentlich und simultan.
- „Zeit läuft weiter: Bei Treffern startet die Zeit nicht neu." — Verständlich, aber zu technisch für eine Party-Erklärung.
- „Punktabzug: Legt fest, wie viele Punkte bei einer verlorenen Runde weg sind." — Korrekt, aber kein Spielgefühl.

### Challenge-Texte

Die Challenges selbst sind gut formuliert: kurz, klar, spielerisch. Das ist eine Stärke des Spiels.

### HomeView-Einstellungen

- „Zeit läuft weiter" klingt wie eine Information, keine Einstellungsoption.
- Besser wäre: „Timer neu starten bei Treffer" (an/aus) — dann ist sofort klar was sich ändert.

---

## 10. Visuelles Design

### Casino-Thema

Das Thema ist eindeutig, konsequent und hochwertig. Die Kombination aus Dunkelgrün, Gold, Champagner-Text, Filztextur und Kartenoptik ergibt eine klare visuelle Identität. Das hebt das Spiel aus dem App-Alltag heraus.

### Modern und hochwertig

Ja. Das Design ist visuell auf einem sehr guten Niveau und wirkt wie ein fertiges Produkt.

### Spielerisch

Teilweise. Die Spielkarten-Flip-Animation, der Slot-Machine-Effekt und die Münzwurf-Animation sind spielerisch. Viele andere Screens — HomeView, VotingView — sind eher statisch.

### Teamfarben

Teamfarben sind konsistent eingesetzt: Farb-Balken in Karten, farbige Punkte, farbige Texte. Das hilft bei der Orientierung erheblich und ist eine echte Stärke des Designs.

### Aktive Zustände

Leader-Krone auf der VoteCard ist klar erkennbar. Gesperrte Auslosungskarte leuchtet in Teamfarbe auf. Beides gut.

### Schriftgrößen und Ablesbarkeit

- Challenge auf der Karte: 20pt Semibold — für eine Gruppe, die auf einen Tisch schaut, gerade noch okay. 22–24pt wäre besser.
- TeamName auf VoteCard: 14pt — zu klein für einen Gruppentisch.
- „RAISE"-Label auf VoteCard: 9pt Monospace — niemand liest das.
- Challenge auf dem Spielscreen: `.title3.weight(.semibold)` — okay, aber knapp.

### Zu leer oder zu voll

Einige Screens wirken zu leer (HomeView mit Formular-Charakter, VotingView ohne Spannung). Die ChallengeStartView ist etwas überladen — dekorative Hintergrundkarten, Badge, Card, Shuffle-Button, Players-Bar, Deal-Button.

---

## 11. Spielgefühl und Spannung

### Auslosung
Hoch. Der Slot-Machine-Effekt, die Staffelung, die Haptik — das ist einer der wenigen Momente, in denen das Spiel sich wirklich wie ein Spiel anfühlt.

### Challenge-Anzeige
Gut. Der Flip und der Shimmer erzeugen kurze Spannung. Aber danach wird zu viel erklärt ohne Aktion — der DEAL-Button macht den Übergang nicht spannend.

### Bietrunde
Niedrig. Alle tippen still für sich. Kein Wettbewerb, kein Duell. Das ist der größte Spannungsverlust im ganzen Spiel.

### Spielmoment (GameView)
Mittel. Timer in Rot bei wenig Zeit ist gut. Der Zähler, der runterzählt, erzeugt Spannung. Aber die unbeschrifteten Buttons brechen den Fluss.

### JACKPOT-Screen
Hoch. Geldregen, Bounce, Glow, Krone — das ist outstanding. Echter Belohnungsmoment.

### BUST-Screen
Mittel. Regen-Animation und dunkleres Farbschema sind stimmig — für ein Partyspiel aber zu düster. Verlieren soll nicht schmerzhaft sein, sondern lustig.

### Wechsel zur nächsten Runde
Gut. „Nächste Runde" geht sofort zurück zur Challenge-Ansicht.

---

## 12. Nutzung in einer Gruppe

### Schriftgröße aus Abstand

| Element | Größe | Ablesbar aus ~1m? |
|---------|-------|-------------------|
| Challenge-Text (Karte) | 20pt Semibold | Ja, knapp |
| Challenge-Text (Spielscreen) | title3 ≈ 20pt | Ja, knapp |
| Team-Name auf VoteCard | 14pt | Nein |
| FlipCounter oben | ca. 60–70pt (Chip-Style) | Ja |
| Timer | 26pt Monospace | Ja |
| „RAISE"-Label | 9pt | Nein |
| Aktive Spieler in Players-Bar | 13pt | Nein |

### Typische Partyspiel-Situation

Das iPhone liegt auf einem Tisch. Mehrere Personen schauen darauf. Nicht alle Personen können kleine Texte lesen. Aktionen müssen sofort erkennbar sein.

**Was in dieser Situation nicht funktioniert:**
- Die beiden Aktionsbuttons im Spielscreen — kein Textlabel, unter Zeitdruck garantiert Fehler
- Die Team-Karten auf dem Bietscreen — zu klein für 6+ Personen am Tisch
- Die Players-Bar auf der Challenge-Ansicht — von einer Person gehalten, andere sehen die kleinen Texte nicht
- Die „NÄCHSTE/R"-Info auf der Auslosung — zu kleine Schrift

**Was in dieser Situation funktioniert:**
- FlipCounter oben auf Biet- und Spielscreen — groß genug
- Timer — groß und rot bei Zeitdruck, gut sichtbar
- JACKPOT/BUST — groß, animiert, jeder sieht es sofort

### Mögliche Diskussionen während des Spiels

An diesen Stellen werden Spieler höchstwahrscheinlich streiten oder stoppen:
1. „Wer muss jetzt die Challenge machen?" (Bietscreen zeigt es nicht)
2. „Welcher Button ist 'richtig'?" (Spielscreen, keine Labels)
3. „Was bedeutet die große Zahl oben?" (Kein Label)
4. „Wann halten wir den Button?" (Bestätigungsmoment unklar)
5. „Hat er/sie jetzt genug Antworten gesagt?" (Kein klares Signal)

---

## 13. Entfernen aus UI-/UX-Sicht

### „KATEGORIE"-Label über dem Badge

**Warum entfernen?**  
Das 10pt Monospace-Label über dem Kategorie-Badge ist zu klein, um aus Abstand gelesen zu werden. Das Badge darunter zeigt das Icon und den Kategorienamen bereits — das Label darüber ist redundant.

**Was wird dadurch besser?**  
Weniger visuelle Ebenen, mehr Klarheit auf der Challenge-Ansicht.

**Alternative:**  
Nur das Badge mit Icon und Kategoriename zeigen — der Kontext ist klar genug.

---

### „RAISE"-Indikator auf GroupVoteCard

**Warum entfernen?**  
9pt Monospace-Text in Silbergrau. Niemand liest das. Es erklärt nicht wirklich etwas. Spieler schauen auf die + und − Buttons, nicht auf diesen Hinweis.

**Was wird dadurch besser?**  
Platz für eine sinnvollere Information: z.B. wer bietet für wen.

**Alternative:**  
Kleiner Text: „[Spieler 2] bietet" unter dem Teamnamen auf der Karte.

---

### Dekorative Hintergrundkarten auf ChallengeStartView

**Warum entfernen?**  
Die zwei 80×110pt Spielkarten (Ass Pik, König Herz) im Hintergrund sehen schön aus — aber sie nehmen Aufmerksamkeit weg von der eigentlichen Challenge-Karte. Für eine Gruppe, die auf das Telefon schaut, sind sie Ablenkung ohne Information.

**Was wird dadurch besser?**  
Mehr Fokus auf die Challenge. Mehr Platz für eine Spieler-Übersicht.

**Alternative:**  
Subtile Kartenelemente als Teil des Hintergrundgradienten (z.B. sehr schwach aufgelöste Muster). Das Casino-Flair bleibt, ohne abzulenken.

---

### Onboarding Seite 4 (Einstellungen)

**Warum entfernen?**  
Seite 4 erklärt Einstellungen: „Zeit läuft weiter: Bei Treffern startet die Zeit nicht neu." Das ist keine Spielanleitung, sondern ein Settings-Erklärer. Im Onboarding vor dem ersten Spiel ist das fehl am Platz.

**Was wird dadurch besser?**  
Onboarding wird kürzer (3 Seiten statt 4) und schließt mit dem Motivations-Satz auf Seite 3 ab. Weniger lesen, schneller spielen.

**Alternative:**  
Kurze Tooltip-Icons (ⓘ) neben den Einstellungs-Rows auf dem HomeView erklären die Optionen bei Bedarf.

---

### X-Button oben rechts im ResultView ohne Alert

**Warum entfernen?**  
Der X-Button in der TopBar des ResultViews ruft direkt `onRestart()` auf — ohne Bestätigungs-Alert. Ein versehentliches Tippen löscht die Runde. Der große „Neustart"-Button unten hat einen Alert, der X-Button oben nicht.

**Was wird dadurch besser?**  
Kein versehentlicher Neustart.

**Alternative:**  
Auch der X-Button sollte `showRestartAlert = true` setzen — oder er navigiert nur „zurück zur Challenge", nicht zum Neustart.

---

## 14. Hinzufügen aus UI-/UX-Sicht

### Textlabels für die Aktionsbuttons im Spielscreen

**Was fehlt:**  
Kurze Labels unter den zwei Kreis-Buttons: z.B. „Richtig" (goldener Button) und „Zurück" (roter Button). Alternativ: ✓ und ↩ als gut erkennbare Icons.

**Warum wichtig:**  
In keinem anderen Moment ist Klarheit wichtiger als hier — alle schauen zu, die Zeit läuft, Druck ist da.

---

### „Wer bietet für wen" auf dem Bietscreen

**Was fehlt:**  
Auf jeder GroupVoteCard oder als fixer Banner oben: „[Spieler 2] bietet für [Spieler 1]." (Sehr klein, aber es muss da sein.)

**Warum wichtig:**  
Das ist die Kern-Information der Runde. Ohne sie ist die Bietrunde nicht vollständig verständlich.

---

### Label für den FlipCounter oben auf dem Bietscreen

**Was fehlt:**  
Über dem großen Counter: „Höchste Wette" oder „Aktuelles Höchstgebot".

**Warum wichtig:**  
Ohne Label weiß niemand, was diese Zahl bedeutet — besonders bei einem ersten Spiel.

---

### Ankündigung des Spielerwechsels nach jeder Runde

**Was fehlt:**  
Nach „Nächste Runde" gibt es keinen Hinweis, wer jetzt dran ist. Das könnte auf der Challenge-Ansicht als kleiner Hinweis erscheinen: „Diese Runde: Spieler 2 ist dran — Spieler 1 bietet für sie/ihn."

**Warum wichtig:**  
Ohne diesen Hinweis merken Spieler den Wechsel erst mitten in der Runde.

---

### Spielstand im Spielscreen (mini Scoreboard)

**Was fehlt:**  
Ein kleines Score-Banner oben im GameView: z.B. „🔵 12 · 🔴 8 · 🟢 5". Kann sehr klein sein — muss nur vorhanden sein.

**Warum wichtig:**  
Spannung entsteht, wenn man weiß, wofür man kämpft. „Wenn ich das jetzt schaffe, liegen wir vorne" ist ein Motivationsmoment.

---

### Spielende-Mechanismus (optional, aber wichtig für Gruppen)

**Was fehlt:**  
Eine Möglichkeit, ein Spielende zu definieren: „Endet nach X Runden" oder „Endet, wenn ein Team Y Punkte hat."

**Warum wichtig:**  
Gruppen wollen wissen, wann das Spiel offiziell endet. Ohne ein Ende fehlt der dramatische Gewinner-Moment.

---

### Kurze Erklärung vor der ersten Bietrunde

**Was fehlt:**  
Beim allerersten Aufruf des Bietscreens: ein kurzes Banner oder ein kleiner Overlay-Hinweis: „Jeder bietet, wie viele [Challenge-Typ] der Partner schafft. Das höchste Gebot muss liefern." Nur einmal — danach verschwindet es.

**Warum wichtig:**  
Das Spielprinzip erschließt sich auf dem Bietscreen nicht von selbst.

---

## 15. Was besonders gut ist

### Casino-Theme
Das visuelle Konzept ist eindeutig, konsequent und hochwertig. Gold, Dunkelgrün, Filztextur, Kartenoptik — das ergibt eine starke Spielpersönlichkeit. Das sollte auf keinen Fall verwässert werden.

### Spielkarten-Flip auf der Challenge-Ansicht
3D-Flip + Shimmer-Effekt ist der visuelle Höhepunkt des Setup-Bereichs. Das fühlt sich nach einem echten Kartenspiel an.

### Auslosungsscreen mit Slot-Machine-Effekt
Einer der besten Momente im Spiel. Spannung, Animation, Haptik, klare Labels — das funktioniert.

### JACKPOT!-Screen
Der beste Moment im ganzen Spiel. Geldregen, federnder Bounce, Gold-Glow — das belohnt wirklich und fühlt sich verdient an.

### Münzwurf-Animation beim Erhöhen
Kleines Detail, große Wirkung. Genau der Typ von Feedback, der ein Spiel lebendig macht.

### Teamfarben durchgängig eingesetzt
Farbige Balken, Punkte, Texte — über alle Screens konsistent. Das hilft bei der Orientierung und macht die Teams erkennbar.

### Leader-Krone auf der VoteCard
Subtil, effektiv. Man erkennt sofort, wer gerade führt.

### Animiertes Leaderboard im ResultView
Das schrittweise Hochzählen der Punkte ist visuell stark und macht den Spielstand interessant.

### Timer mit Rot bei Zeitdruck
Klar, gut skaliert, visuell eindeutig. Erzeugt echten Druck.

### Hold-to-Confirm-Button Konzept
Die Idee ist gut — verhindert versehentliches Bestätigen. Der Zeitpunkt braucht mehr Klarheit, die Idee selbst ist behaltenswert.

### Aufgeben-Button mit Bestätigung
Gut beschriftet, hat einen Alert. Niemand kann aus Versehen aufgeben.

### Haptik
Sinnvoll eingesetzt: Tippen, Einrasten, Erfolg, Auswahl. Macht das Spiel haptisch angenehm.

---

## 16. Größte UI/UX-Probleme

### Problem 1: Keine Beschriftung der Aktionsbuttons im Spielscreen

**Was ist das Problem?**  
Im wichtigsten Moment des ganzen Spiels — der aktive Spieler führt die Challenge aus, alle schauen zu — gibt es zwei große Kreis-Buttons mit reinen Pfeil-Symbolen. Kein Text. Kein Hinweis. Kein Label.

**Warum ist es wichtig?**  
In einer Gruppe unter Zeitdruck muss jede Aktion sofort erkennbar sein. Niemand sollte fragen müssen: „Welchen Knopf drücke ich, wenn er eine richtige Antwort sagt?" Diese Frage darf nicht entstehen.

**Empfehlung:**  
Kurze Labels unter den Buttons: „Richtig ✓" für den goldenen Button, „↩ Zurück" für den roten. Alternativ: Icons, die eindeutig sind (z.B. ein Häkchen-Icon statt Pfeil).

---

### Problem 2: Die Bietrunde erklärt sich nicht selbst

**Was ist das Problem?**  
Der Bietscreen zeigt Team-Karten mit + und − und einen großen Counter oben. Nirgendwo steht: Was bedeutet diese Zahl? Wer muss die Challenge machen? Biete ich meine eigenen Fähigkeiten oder die meines Partners?

**Warum ist es wichtig?**  
Das ist der Mechanismus des Spiels. Wenn Spieler hier nicht verstehen was sie tun, bricht alles zusammen. In der Praxis tippen Spieler bei unklaren UIs einfach irgendwas — was zu Verwirrung und falschen Ergebnissen führt.

**Empfehlung:**  
Auf jeder Team-Karte: „[Spieler 2] bietet für [Spieler 1]". Über dem FlipCounter: „Höchste Wette". Kleiner Einleitungstext: „Wie viele [Challenge-Einheit] schafft euer Partner?"

---

### Problem 3: Widerspruch zwischen Onboarding und App

**Was ist das Problem?**  
Das Onboarding auf Seite 2 sagt: „Jedes Team bietet geheim Punkte auf den eigenen Partner." Die App zeigt eine öffentliche, simultane Bietrunde — alle Teams tippen gleichzeitig für sich, alle sehen alle Karten.

Außerdem referenziert das Onboarding einen Button „Geschafft" — der nicht existiert.

**Warum ist es wichtig?**  
Spieler, die das Onboarding gelesen haben, spielen die App falsch. Spieler, die es nicht gelesen haben, sind verwirrt. In beiden Fällen entstehen unnötige Diskussionen.

**Empfehlung:**  
Das Onboarding muss den tatsächlichen Ablauf beschreiben. Außerdem: Klärung nötig, ob die simultane oder eine abwechselnde Bietrunde gewollt ist (→ Rückfrage).

---

### Problem 4: Der „DEAL"-Button bedeutet nicht das, was er sagt

**Was ist das Problem?**  
„DEAL" klingt wie das Ergebnis einer Einigung — das Ende einer Verhandlung. Hier bedeutet er: „Challenge gesehen, weiter zur Bietrunde." Das ist das Gegenteil — ein Beginn, keine Einigung.

**Warum ist es wichtig?**  
Spieler zögern beim ersten Mal. Das bricht den Spielfluss und macht die App unsicherer wirken, als sie ist.

**Empfehlung:**  
„Bietrunde starten" ist eindeutig. Wenn Casino-Flair gewünscht: „PLACE YOUR BETS" als Buttontext wäre zumindest inhaltlich korrekter.

---

### Problem 5: Kein Spielstand während des Spiels sichtbar

**Was ist das Problem?**  
Im Spielscreen (GameView) sieht man nur den Fortschritt der aktuellen Challenge. Der Gesamtstand aller Teams ist nicht sichtbar.

**Warum ist es wichtig?**  
Bei einem Wettspiel lebt die Spannung davon, zu wissen, ob man führt oder aufholen muss. Ohne Spielstand fehlt die Motivation.

**Empfehlung:**  
Kleines Score-Banner im Header oder Footer des Spielscreens mit dem aktuellen Punktestand aller Teams.

---

## 17. Konkrete Verbesserungsvorschläge

- Die Aktionsbuttons im Spielscreen müssen Text-Labels bekommen: „Richtig" für den goldenen Button, „Zurück" für den roten. Das ist das dringendste Problem der gesamten App.

- Die große Zahl oben im Bietscreen muss beschriftet sein: „Höchste Wette". Ohne dieses Label ist der schönste visuelle Element des Screens bedeutungslos für neue Spieler.

- Auf jeder Team-Karte im Bietscreen sollte stehen, wer für wen bietet: „[Spieler 2] bietet für [Spieler 1]." Das kann sehr klein sein — aber es muss vorhanden sein.

- Der „DEAL"-Button sollte umbenannt werden in etwas, das erklärt was als nächstes passiert: z.B. „Jetzt bieten" oder „Wetten starten".

- Das Onboarding muss den tatsächlichen Spielablauf beschreiben — nicht eine mündliche Auktion, wenn die App eine simultane Abstimmung verwendet. Außerdem: Der referenzierte „Geschafft"-Button muss im Onboarding korrekt beschrieben sein.

- Nach jeder Runde sollte kurz gezeigt werden, wer jetzt dran ist: „Nächste Runde: Spieler 2 aus Team A — Spieler 1 bietet für sie." Das kann auf der Challenge-Ansicht als kleines Banner erscheinen.

- Im Spielscreen sollte ein kleiner Gesamtstand sichtbar sein, damit Spieler wissen wofür sie kämpfen.

- Englische Spielanweisungen (PLACE YOUR BETS, THE DEAL, SHOWDOWN) sollten auf Deutsch übersetzt werden — oder es wird eine bewusste Entscheidung getroffen, das gesamte Spiel auf Englisch zu führen.

- Die Spielernamen-Felder im Setup sollten kurz erklären, welche Rolle Spieler 1 und Spieler 2 haben: z.B. kleiner Hinweistext: „Spieler 1 macht die Challenge — Spieler 2 bietet für ihn."

- Der X-Button im ResultView oben rechts sollte denselben Bestätigungs-Alert auslösen wie der „Neustart"-Button unten.

- Das Onboarding sollte auf 3 Seiten reduziert werden. Seite 4 (Einstellungen) kann als Tooltip-System direkt in den HomeView-Settings eingebaut werden.

---

## 18. Prioritätenliste

### Sofort ändern

Diese Probleme beeinflussen direkt das Spielverständnis oder verursachen Fehler:

1. **Aktionsbuttons im GameView beschriften** — kein Spieler weiß sonst was zu drücken ist
2. **Label für den FlipCounter oben im Bietscreen** — „Höchste Wette" macht alles sofort klarer
3. **Wer-bietet-für-wen auf dem Bietscreen anzeigen** — Kern-Information der Runde
4. **Onboarding: Widersprüche korrigieren** — „geheim", „Geschafft"-Button, abwechselnde vs simultane Bietrunde (nach Klärung)
5. **„DEAL"-Button umbenennen** — unklar für neue Spieler

### Danach verbessern

Diese Punkte verbessern das Spielerlebnis deutlich:

6. **Spielstand im Spielscreen** — kleiner Mini-Scoreboard oben
7. **Spielerwechsel-Ankündigung nach jeder Runde** — kurzer Banner auf Challenge-Ansicht
8. **Englische Spielanweisungen übersetzen** — PLACE YOUR BETS, THE DEAL, SHOWDOWN
9. **Spielernamen-Felder im Setup erklären** — Rolle von Spieler 1 und 2 klarmachen
10. **X-Button im ResultView mit Alert absichern**
11. **Onboarding auf 3 Seiten reduzieren**
12. **„Zeit läuft weiter" als Einstellungsname verbessern**

### Optional später

Diese Elemente würden das Spielgefühl verfeinern:

13. **Spielende-Mechanismus** — Rundenanzahl oder Punktziel einführen
14. **Bietrunde spannender gestalten** — mehr visuelles Wettbewerbs-Gefühl (z.B. Pulsieren der führenden Karte)
15. **„BUST"-Screen freundlicher gestalten** — weniger düster für Partys
16. **Dekorative Hintergrundkarten auf Challenge-Ansicht reduzieren**
17. **„NÄCHSTE/R"-Label bei 3+ Spielern klarer beschriften**
18. **Gewinner-Screen nach dem letzten Neustart hinzufügen**

---

## 19. UI/UX Tabelle

| Bereich | Element | Bewertung | Empfehlung | Grund |
|---------|---------|-----------|------------|-------|
| HomeView | Spielkarte „Ich biete mehr!" (App-Einstieg) | Stark | Beibehalten | Visuell hochwertig, klare Casino-Identität |
| HomeView | Setup als Einstellungsmenü | Unklar | Spielerischer gestalten | Kein Spielgefühl beim Einstieg |
| HomeView | „Zeit läuft weiter" als Setting-Name | Unklar | Klarer benennen | Klingt wie Information, nicht wie Einstellung |
| HomeView | Goldener „Spiel starten"-Button | Stark | Beibehalten | Klar, gut positioniert |
| Teamerstellung | 2/3/4-Gruppen-Kacheln | Stark | Beibehalten | Klar, animiert, gut |
| Teamerstellung | „Jede Gruppe kann aus 2 bis 4 Spielern bestehen" | Unklar | Spielprinzip besser erklären | Missverständlich für Bieter-Mechanismus |
| Teamerstellung | Spielernamen optional | Gut, aber verbessern | Rollen (macht es / bietet) erklären | Spieler 1 und 2 haben unterschiedliche Rollen |
| Teamerstellung | „Gruppe" vs „Team" gemischt | Unklar | Konsequent „Team" verwenden | Inkonsistent über alle Screens |
| Auslosung | Slot-Machine-Effekt | Stark | Beibehalten | Spannung, Spielgefühl, klar |
| Auslosung | „MACHT ES" / „BIETET" Labels | Stark | Beibehalten | Klarste Information im ganzen Spiel |
| Auslosung | „NÄCHSTE/R" bei 3+ Spielern | Unklar | Besser beschriften | Verwirrend für neue Spieler |
| Onboarding | Automatischer Start beim ersten Mal | Stark | Beibehalten | Gut gedacht |
| Onboarding | „geheim" und simultane Bietrunde | Zu schwach | Korrigieren | Widerspruch zur App |
| Onboarding | Button „Geschafft" referenziert | Zu schwach | Korrigieren | Dieser Button existiert nicht |
| Onboarding | Seite 4 (Einstellungen) | Entfernen | Als Tooltips im HomeView | Zu trocken für Partyspiel-Onboarding |
| Challenge-Anzeige | Spielkarten-Flip-Animation | Stark | Beibehalten | Spielgefühl, Spannung |
| Challenge-Anzeige | Challenge-Text auf Karte (20pt) | Gut, aber verbessern | 22–24pt wäre besser | Für Gruppenlesbarkeit |
| Challenge-Anzeige | „THE DEAL"-Header | Unklar | Auf Deutsch übersetzen | Englische Spielanweisung |
| Challenge-Anzeige | „DEAL"-Button | Unklar | Umbenennen: „Wetten starten" | Englisch und missverständlich |
| Challenge-Anzeige | Dekorative Hintergrundkarten | Zu viel | Reduzieren oder entfernen | Ablenkung vom Kerninhalt |
| Challenge-Anzeige | „KATEGORIE"-Label (10pt) | Entfernen | Badge alleine reicht | Zu klein, redundant |
| Challenge-Anzeige | „DIESE RUNDE"-Leiste | Gut, aber verbessern | Bieter-Info ergänzen | „macht es" alleine reicht nicht |
| Bietrunde | Header „PLACE YOUR BETS" | Unklar | Auf Deutsch: „Jetzt bieten" | Spielanweisung auf Englisch |
| Bietrunde | FlipCounter oben (kein Label) | Zu schwach | „Höchste Wette" hinzufügen | Ohne Label unverständlich |
| Bietrunde | Team-Karten ohne Bieter-Info | Zu schwach | Bieter-Namen auf Karte | Kern-Information fehlt |
| Bietrunde | Leader-Krone | Stark | Beibehalten | Schnell erkennbar, schöner Effekt |
| Bietrunde | Münzwurf-Animation beim + | Stark | Beibehalten | Spielerischer Moment |
| Bietrunde | „RAISE"-Label (9pt Monospace) | Entfernen | Durch Bieter-Info ersetzen | Niemand liest das |
| Bietrunde | „BETTING TABLE"-Label | Unklar | Auf Deutsch übersetzen | Englisch |
| Bietrunde | „Halten zum Bestätigen" | Gut, aber verbessern | Zeitpunkt klarstellen | Wann soll man halten? |
| Spielscreen | Header „♣ SHOWDOWN ♥" | Unklar | Teamname / Spieler anzeigen | Englisch + nicht hilfreich |
| Spielscreen | Aktionsbuttons ohne Label | Zu schwach | Sofort beschriften | Größtes UI-Problem der App |
| Spielscreen | Timer (Rot bei Zeitdruck) | Stark | Beibehalten | Klar, skaliert, erzeugt Druck |
| Spielscreen | Challenge-Text | Gut, aber verbessern | Leicht größer | Für Gruppenspiele |
| Spielscreen | „Aufgeben"-Button | Gut, aber verbessern | Kleiner machen | Zu prominent neben Aktionsbuttons |
| Spielscreen | Kein Spielstand sichtbar | Zu schwach | Mini-Scoreboard hinzufügen | Motivation und Spannung fehlen |
| Ergebnis | „JACKPOT!" mit Geldregen | Stark | Beibehalten | Bester Moment im Spiel |
| Ergebnis | „BUST" mit Regen-Animation | Gut, aber verbessern | Freundlicher formulieren | Für Partys zu düster |
| Ergebnis | Animiertes Leaderboard | Stark | Beibehalten | Toll, spannend |
| Ergebnis | „Nächste Runde"-Button | Stark | Beibehalten | Klar, gut positioniert |
| Ergebnis | X-Button oben ohne Alert | Unklar | Alert hinzufügen | Versehentlicher Neustart möglich |
| Ergebnis | Kein Gewinner-Screen am Ende | Hinzufügen | Optionalen Abschluss-Screen | Kein definitives Spielende |

---

## 20. Zielbild für das Spiel

„Ich biete mehr!" soll sich so anfühlen: Man setzt sich hin, tippt kurz auf „Spiel starten" und nach wenigen Sekunden läuft das erste Spiel. Die Auslosung baut Spannung auf — Rollen klar, wer macht was. Die Challenge erscheint als große Karte, alle sehen sie sofort. Die Bietrunde ist ein echtes Duell — man sieht, welches Team höher geht, und der Wettbewerb ist spürbar. Dann übernimmt ein Spieler die Bühne und alle anderen tracken mit — mit einem klaren, sofort verständlichen Button — jeden Treffer. Am Ende: ein JACKPOT-Moment, der sich wirklich wie ein Gewinn anfühlt. Die nächste Runde startet sofort, alle wissen wer jetzt dran ist. Das Spiel wirkt nicht wie eine Formularsoftware. Es wirkt wie ein Duell am Pokertisch — mit dem Thrill einer Wette, dem Jubel eines Treffers und dem Lachen nach einem Fehlschlag.

---

## Rückfragen vor der Umsetzung

### Offene Frage 1: Simultane oder abwechselnde Bietrunde?

**Was ist aktuell in der App vorhanden?**  
Der BetBuddyVotingView zeigt alle Teams gleichzeitig. Jedes Team tippt seine eigene Wette still für sich. Es gibt keinen Passen-Button und keine Reihenfolge.

**Was beschreiben die Dokumente?**  
BET_BUDDY_EXPLANATION.md und das Onboarding (Seite 2) beschreiben eine mündliche Auktionsrunde: Team A bietet, Team B muss überbieten oder passen, dann wieder Team A — bis ein Team passt.

**Was schlage ich vor?**  
Diese Frage muss entschieden werden, bevor UI-Änderungen umgesetzt werden:

- **Option A – Simultane Bietrunde beibehalten:** Onboarding und Erklärungsdatei werden angepasst. Kein Passen-Button nötig. Bietscreen wird mit mehr Kontext beschriftet (Label für Counter, Bieter-Info auf Karten). Einfacher umzusetzen.
- **Option B – Abwechselnde Bietrunde einführen:** App zeigt aktiv welches Team gerade an der Reihe ist. Ein Passen-Button kommt hinzu. Deutlich aufwändiger, aber spielerisch spannender und näher am beschriebenen Konzept.

**Welche Screens wären betroffen?**  
BetBuddyVotingView, BetBuddyInfoSheet, BET_BUDDY_EXPLANATION.md.

**Risiken:**  
Option A: Das Spielgefühl bleibt weniger wettbewerbsorientiert. Option B: Erheblicher Entwicklungsaufwand, UI-Grundstruktur des Bietscreens ändert sich komplett.

**Soll ich diese Änderung später umsetzen?**  
→ Bitte Antwort abwarten.

---

*Ende des Audits. Keine Codeänderungen wurden vorgenommen.*
