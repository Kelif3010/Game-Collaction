# Audit: Falsche Fährte

## 1. Gesamteindruck

„Falsche Fährte" hat eine klare Design-DNA: Violett-Indigo Noir-Palette, dunkles Blauschwarz, monospaced Labels für Atmosphäre. Die Basis ist solider als ein typisches Prototyp-Spiel. Dennoch bleibt das Spiel hinter seinem Potenzial: Der Setup-Screen hat keine Spielidentität (kein Spieltitel sichtbar), die Bluff-Phase wirkt klinisch statt spannungsvoll, und der Reveal-Screen zeigt in der Preview gar keine Inhalte (Animation-State-Problem). Das Spiel fühlt sich wie 70% fertig an — die Struktur ist da, aber der emotionale Impact fehlt an genau den falschen Stellen: Spielstart, Lügen-Eingabe und Enthüllung.

---

## 2. Premium-Score: 6 / 10

**Begründung:**
- Das Design-System (FFStyle) ist durchdacht und konsistent — das ist professionell.
- Die Typografie-Hierarchie (.black für Titel, .monospaced für Labels) gibt es Charakter.
- Abgezogen werden Punkte wegen: fehlendem Hero-Moment beim Spielstart, generischer Bluff-Eingabe, flachem Reveal-Screen, keinem Confetti/Celebration-Effekt im Game Over.
- Die Karte sieht nicht nach „published App" aus, sondern nach „sehr gepflegtem Beta".

---

## 3. Spielgefühl-Score: 5 / 10

**Begründung:**
- Das Spielprinzip (Lügen erfinden, Täuschung, Enthüllung) ist in der visuellen Sprache kaum spürbar.
- Es gibt keinen echten „Mystery-Moment" — weder beim Start noch bei der Eingabe.
- Der beste Screen (Auflösung mit gestaffelten Karten) ist in der Preview leer wegen des Animation-Delays — das muss gelöst werden.
- Das Detektiv/Täuschungs-Feeling verlangt nach mehr Dramatik: Dunkel, Spannung, Enthüllung. Aktuell fühlt es sich eher nach einer Pub-Quiz-App an.

---

## 4. Was bereits gut funktioniert

- **Design-System:** FFStyle mit Farben, Gradienten, Spacing, Typografie ist sauber zentralisiert.
- **Spieler-Divider in der Bluff-Phase:** Der Name des aktuellen Spielers als Badge in einer Trennlinie ist eine originelle Detail-Lösung.
- **Animationssystem:** Spring-Physik durchgehend, konsistente Einblend-Delays, ShakeModifier für Fehler.
- **Haptik:** .sensoryFeedback durchgehend und semantisch korrekt (light/medium/error).
- **Pack-Picker Sheet:** Bester Sheet-Screen — Emojis als Identifikation, klarer Kontrast aktiv/inaktiv, gute Hierarchie.
- **Accessibility:** Die meisten Buttons haben .accessibilityLabel, VoiceOver-Unterstützung ist vorhanden.
- **Multiplayer-States:** Warte-Screens (Bluff submitted, Vote submitted) sind clean und informativ.
- **Kapseln als primäre Buttons:** Die Capsule-Form mit Gradient ist konsistent und sieht nativ aus.
- **Score-Interlude-Screen:** Das Konzept (Zwischenstand nach jeder Runde) ist stark — die Umsetzung mit gestaffelten Zeilen und Crown für Platz 1 ist solid.

---

## 5. Was aktuell nicht hochwertig genug wirkt

1. **Setup-Screen hat keine Spielidentität** — kein "Falsche Fährte"-Titel, kein Logo, keine Tagline. Der erste visuelle Eindruck ist ein generisches Settings-Panel.
2. **Bluff-Eingabe ist klinisch** — das Input-Feld sieht aus wie ein Notes-App-Textfeld. Kein Mystery-Feeling, keine Spannung, keine thematischen Elemente.
3. **Reveal-Screen zeigt in der Preview keine Karten** — wegen des cardsVisible-Delays in onAppear (Task.sleep 0.4s). Der spannendste Moment des Spiels ist nicht isoliert testbar.
4. **Game Over ist zu funktional** — kein Confetti, kein Feier-Moment, "Spielende" als Titel ist emotionslos.
5. **Info Sheet bricht den Dark Mode** — die FFBackground in einem NavigationStack-Sheet rendert nicht korrekt; es erscheint ein hellgrauer Standard-Hintergrund oben statt Noir.
6. **Rang 2/3/4 im Leaderboard identisch** — alle in Gray, kein Silber/Bronze-Differenzierung.
7. **Background-Glow ist zu subtil** — der RadialGradient-Glow mit opacity(0.12) ist auf realen Geräten kaum wahrnehmbar.

---

## 6. Konkrete Probleme pro Screen

### Setup-Screen (FFSetupView.swift)

| Problem | Schwere | Zeile |
| :--- | :--- | :--- |
| Kein Spieltitel / kein Hero-Element | 🔴 Kritisch | header (Z. 98–142) |
| Alle 5 Rows visuell identisch — kein Pflicht/Optional-Unterschied | 🟡 Mittel | setupCard (Z. 145–163) |
| „Spieler"-Row ist Pflicht, aber nicht hervorgehoben | 🟡 Mittel | playerRow (Z. 165–180) |
| Hintergrund-Glow kaum sichtbar | 🟢 Klein | FFBackground |
| Start-Button zeigt foregroundStyle(.black) auf Violet-Gradient — Text fast unlesbar | 🔴 Kritisch | Z. 261 |

*Zur Start-Button-Farbe: Das Button-Label ist .foregroundStyle(canStart ? .black : ...). Schwarzer Text auf einem violetten Gradient ist sehr schlecht lesbar — .white oder ein helles Creme wäre korrekt.*

---

### Bluff-Phase (FFBluffPhaseView.swift)

| Problem | Schwere | Zeile |
| :--- | :--- | :--- |
| Input-Zone wirkt wie normales TextField, kein Spielcharakter | 🟡 Mittel | inputZone (Z. 272–343) |
| „DEINE LÜGE" Label zu unscheinbar (opacity 0.65, 9pt) | 🟡 Mittel | Z. 274 |
| Background-Glow opacity(0.22) kaum sichtbar auf Device | 🟢 Klein | questionZone (Z. 155–159) |
| Story-Segmente 3px Höhe — zu klein als Fortschrittsanzeige | 🟢 Klein | Z. 137 |
| Timer-UI fehlt komplett — der FFBluffTimer ist einstellbar aber im Bluff-Screen nicht sichtbar | 🔴 Kritisch | gesamte View |
| submitButton zeigt .foregroundStyle(.black) auf Violet-Gradient | 🔴 Kritisch | Z. 373 |

*Zum Timer: FFSettings.bluffTimer ist konfigurierbar (30s/40s/60s/90s), aber in FFBluffPhaseView wird der Timer viewModel.startTimer() nirgends aufgerufen. Die Lügen-Zeit läuft nicht. Das ist ein funktionaler Bug mit UX-Auswirkung.*

---

### Vote-Phase (FFVotePhaseView.swift)

| Problem | Schwere | Zeile |
| :--- | :--- | :--- |
| Voter-Transition-Overlay wirkt abrupt — schwaches Design | 🟢 Klein | voterTransitionOverlay (Z. 385–412) |
| voterBadge bei Multiplayer ausgeblendet — UX-Info fehlt | 🟡 Mittel | Z. 51–55 |
| Antwort-Karten haben zu wenig visuellen Gewicht für diese kritische Interaktion | 🟡 Mittel | FFVoteAnswerCard (Z. 417–469) |
| Der „Hand" Icon für eigene Lüge (hand.raised.fill) ist kein intuitives "Du kannst nicht wählen"-Signal | 🟢 Klein | Z. 444 |

---

### Reveal-Phase (FFRevealPhaseView.swift)

| Problem | Schwere | Zeile |
| :--- | :--- | :--- |
| Preview zeigt keine Karten (cardsVisible bleibt false in static Preview) | 🔴 Kritisch | onAppear Task.sleep (Z. 69–78) |
| "WER HAT WEN VERARSCHT" als Section-Label — problematischer Ton | 🟡 Mittel | Z. 180 |
| Grüne Farbe für richtige Antwort ist generisch — nicht im FF-Farbsystem | 🟢 Klein | Z. 242/258 |
| revealNextButton ist grayed-out bis Timer läuft — Nutzer sieht keinen Grund für die Verzögerung | 🟡 Mittel | nextEnabled-Logic (Z. 73–78) |
| Score-Interlude-View hat keinen eigenen Preview | 🟡 Mittel | FFScoreInterludeView (Z. 359) |

---

### Game Over (FFGameOverView.swift)

| Problem | Schwere | Zeile |
| :--- | :--- | :--- |
| "Spielende" als Titel — emotionslos | 🟡 Mittel | Z. 86 |
| Kein Confetti-Effekt oder Partikel-Animation für Gewinner | 🟡 Mittel | gesamte View |
| Rang 2/3/4 alle identical Gray — kein Silber/Bronze | 🟡 Mittel | Z. 180 |
| Stats (Bester Lügner, Bester Detektiv) erscheinen erst nach 0.7s Delay — zu lang | 🟢 Klein | Z. 75–78 |
| "0 Punkte" im Preview da Mocks ohne Scoring — kein Preview-Problem aber kein realer Eindruck | 🟢 Klein | Mock-Data |

---

### Info Sheet (FFSetupComponents.swift — FFInfoSheet)

| Problem | Schwere | Zeile |
| :--- | :--- | :--- |
| FFBackground() im NavigationStack.ZStack rendert nicht korrekt | 🟡 Mittel | Z. 137–138 |
| Navigation-Bar-Title "Spielregeln" ist standard — kein FF-Branding | 🟢 Klein | Z. 175 |
| Kein Spielbild / Visual neben dem Text — reine Liste | 🟢 Klein | gesamte View |

---

### GameCard (FalscheFaehrteGameCard.swift)

| Problem | Schwere |
| :--- | :--- |
| Kein #Preview — nicht isoliert testbar | 🔴 Kritisch |
| Icon magnifyingglass.circle.fill = Detektiv-Symbol, aber Icon sitzt auf einem simplen violetten Kreis | 🟢 Klein |
| "?", "!", "?" als Hintergrundzeichen sind sehr subtil (opacity 0.05–0.10) | 🟢 Klein |

---

## 7. Must-Fix Punkte

1. **Spieltitel auf Setup-Screen** — „Falsche Fährte" + Tagline „Lüge. Täusche. Entlarve." als Hero-Header oben, bevor die Setup-Card beginnt. Ohne das fehlt dem Screen die Identität.
2. **Schwarzer Text auf Violett-Gradient-Button** — FFSetupView Z. 261 und FFBluffPhaseView Z. 373 nutzen .foregroundStyle(.black) auf dem violetten Primär-Gradienten. Das ist zu dunkel — .white verwenden.
3. **Bluff-Timer in FFBluffPhaseView implementieren** — Der Timer ist konfigurierbar, wird aber nie gestartet. viewModel.startTimer(seconds: viewModel.settings.bluffTimer.rawValue) muss in .onAppear aufgerufen werden, plus eine sichtbare Timer-Anzeige.
4. **FFBackground im Info Sheet NavigationStack fixen** — .scrollContentBackground(.hidden) und .toolbarBackground(FFStyle.backgroundDark, for: .navigationBar) hinzufügen.
5. **Preview für FalscheFaehrteGameCard.swift hinzufügen** — ohne kann der Card-Screen nicht visuell geprüft werden.
6. **cardsVisible Preview-Problem in FFRevealPhaseView** — einen separaten Preview mit #Preview("Reveal mit Karten") erstellen, der cardsVisible = true direkt setzt.

---

## 8. Should-Improve Punkte

7. **Spieler-Row auf Setup visuell priorisieren** — z. B. leicht größer, violetter Rand stärker wenn leer, oder ein separater Card-Bereich „Pflicht" vs. „Optional".
8. **Bluff-Input-Zone mit Themen-Charakter** — das Eingabefeld sollte sich nach „Verhörprotokoll" anfühlen: z. B. eine leicht schräg gedruckte Hintergrundlinie, ein Schreibmaschinen-Font-Hint, oder ein Feder-Icon.
9. **Silber/Bronze für Ränge 2/3 in FFGameOverView (leaderboardRow)** — Rang 2 = Color.gray zu hell, Rang 3 = bronze-ähnlich.
10. **Story-Segmente in Bluff-Phase vergrößern** — von 3px auf 5px Höhe, damit sie als Fortschrittsanzeige wahrnehmbar sind.
11. **Voter-Transition Overlay aufwerten** — aktuell nur schwarzer Hintergrund mit Text. Könnte eine Fingerabdruck-Animation oder einen „Handy-Weitergabe"-Illustration haben.
12. **FFScoreInterludeView eigenen Preview** — wird nach jeder Runde angezeigt, aber ist nicht isoliert testbar. Eigener #Preview("Score Interlude") mit Mock-Daten einfügen.
13. **Section-Label "WER HAT WEN VERARSCHT" umbenennen** — z. B. „AUFLÖSUNG", „DIE WAHRHEIT" oder „WHODUNIT?".
14. **Background-Glow verstärken** — RadialGradient-Opacity von 0.12 auf 0.20–0.28 erhöhen, damit die violette Atmosphäre auf realen Geräten spürbar ist.

---

## 9. Nice-to-Have Punkte

15. **Confetti-Effekt im Game Over** — z. B. ein simples Canvas-basiertes Partikel-System mit violetten und goldenen Partikeln beim ersten Erscheinen des Winner-Banners.
16. **Animated Reveal-Karten mit Flip-Effekt** — statt nur move(edge: .bottom) beim Einblenden der Auflösungskarten einen kurzen Flip-Effekt (.rotation3DEffect) nutzen.
17. **Micro-Animation auf der GameCard** — die pulsierenden ?!-Zeichen könnten stärker animiert sein (Opacity 0.05→0.15 statt fast unsichtbar).
18. **Liquid Glass auf Antwort-Karten (FFVotePhaseView)** — iOS 26's .glassEffect() wäre hier ideal für die Vote-Karten; gibt ihnen Tiefe ohne den Noir-Stil zu brechen.
19. **Dark Mode / Light Mode Test** — FalscheFaehrteWrapper setzt .preferredColorScheme(.dark) — richtig. Aber die Sheets (Player Picker, Pack Picker) erben das nicht immer korrekt. Testen.
20. **Warte-Screen Multiplayer animieren** — Der Puls-Kreis im mpWaitingView animiert nicht (nur statische Kreise ohne .scaleEffect-Animation). Fehlende Puls-Animation im Code.

---

## 10. Empfohlene Designrichtung

**Thema: „Noir-Detektiv-Kabinett" — Verhör-Atmosphäre trifft Partyspiel-Energie**

**Was es braucht:**
- **Mehr Spannung im Spielstart:** Ein kurzer Moment wo der Titel „Falsche Fährte" dramatisch erscheint — z. B. eine leicht animierte Schrift, ein Lupe-Icon mit Puls, ein Tagline wie „Lüge. Täusche. Entlarve."
- **Mehr Charaktertiefe in der Bluff-Phase:** Das Eingabefeld sollte sich anfühlen wie eine geheime Notiz, nicht wie ein Suchfeld. Dunkler Hintergrund, schmalere Linie, vielleicht ein „Stift"-Cursor-Effekt.
- **Mehr Dramatik in der Enthüllung:** Die gestaffelte Reveal-Animation ist bereits im Code — nur visuell stärker. Grüner Glow für die richtige Antwort, rotes Aufleuchten für Lügen, größere Schrift.
- **Weniger generische Systemfarben** (z. B. Color.green für "richtig" — eher ein eigenes FFStyle.accentSuccess = Color(red: 0.1, green: 0.85, blue: 0.5) mit Noir-Tönung).

---

## 11. Konkreter Umsetzungsplan (Schritt für Schritt)

### Phase 1 — Bugs & Blockers

| Schritt | Datei | Was |
| :--- | :--- | :--- |
| 1a | FFSetupView.swift | Button foregroundStyle .black → .white auf Gradient |
| 1b | FFBluffPhaseView.swift | Button foregroundStyle .black → .white auf Gradient |
| 1c | FFBluffPhaseView.swift | viewModel.startTimer() in .onAppear + sichtbare Timer-Anzeige |
| 1d | FFSetupComponents.swift | FFInfoSheet NavigationStack Background fixen |
| 1e | FalscheFaehrteGameCard.swift | #Preview hinzufügen |

### Phase 2 — Spielidentität

| Schritt | Datei | Was |
| :--- | :--- | :--- |
| 2a | FFSetupView.swift | Hero-Header mit „Falsche Fährte" Titel + Tagline oben einfügen |
| 2b | FFSetupView.swift | Spieler-Row visuell priorisieren (stärkerer Rand wenn leer, Pflicht-Badge) |
| 2c | FFRevealPhaseView.swift | Section-Label "WER HAT WEN VERARSCHT" umbenennen |
| 2d | FFGameOverView.swift | Header "Spielende" → z. B. "Lügner enthüllt! 🎭" |

### Phase 3 — Atmosphäre & Spielgefühl

| Schritt | Datei | Was |
| :--- | :--- | :--- |
| 3a | FFStyle.swift | Glow-Opacity erhöhen (0.12 → 0.22), accentSuccess Farbe hinzufügen |
| 3b | FFBluffPhaseView.swift | Input-Zone mit mehr Charakter (Thema "Geheimnotiz") |
| 3c | FFRevealPhaseView.swift | Preview mit cardsVisible = true State-Trick hinzufügen |
| 3d | FFRevealPhaseView.swift | Richtige Antwort: stärkerer Glow + eigene accentSuccess Farbe |
| 3e | FFGameOverView.swift | Rang 2/3 Silber/Bronze-Farben |

### Phase 4 — Polishing (Nice-to-Haves)

| Schritt | Datei | Was |
| :--- | :--- | :--- |
| 4a | FFGameOverView.swift | Confetti-Effekt bei Winner-Reveal |
| 4b | FFVotePhaseView.swift | Liquid Glass für Antwort-Karten (iOS 26) |
| 4c | FFBluffPhaseView.swift | Multiplayer Puls-Animation in mpWaitingView |
| 4d | FFRevealPhaseView.swift | Flip-Effekt auf Aufdeckungs-Karten |
| 4e | FFRevealPhaseView.swift | Eigener isolierter Preview für FFScoreInterludeView |
