# KI-Verbesserung: Spion-Hinweise (Imposter)

**Erstellt:** 2026-05-25  
**Betrifft:** `Models/CategoryHints.swift`, `Services/AIService+Hints.swift`, `Models/HintsManager.swift`, `Views/Sheets/SpyOptionsView.swift`, `Models/ImposterWordAssigner.swift`

---

## Was ist das Problem?

Die Option **"Spion-Hinweis anzeigen"** soll dem Spion dezente Tipps geben. In der Praxis passiert aber Folgendes:

- Bei den meisten Kategorien kommen **gar keine Hinweise** (leere Karte)
- Wenn doch einer kommt, ist er oft **so direkt, dass man sofort das Wort errät** (zu stark)
- Manchmal kommen Hinweise die **keinen Bezug zum Wort haben** (sinnfrei)

---

## Zwei Hinweis-Systeme — wichtig zu verstehen

Es gibt **zwei technisch getrennte Systeme**, die beide "Hinweise für Spione" heißen:

### System 1 — Karten-Hint beim Reveal
`ImposterWordAssigner.swift:81` → `HintsManager.createSpyCardTextWithAI` / `createSpyCardText`

Zeigt dem Spion beim Aufdecken der Karte einen Hinweis direkt auf der Karte. Das ist der **aktiv genutzte Pfad** im lokalen Spiel.

### System 2 — Laufzeit-Hints während der Runde  
`HintService.swift` + `HintOverlay`

Wäre für Hinweise **während der laufenden Runde** gedacht (alle 45 Sekunden, 50% Chance). Das UI-Label sagt sogar: *"Zeigt dezente Tipps für Spione in der Runde"*.

**Problem:** `HintService.startHints(...)` wird im Swift-Code aktuell offenbar **nirgendwo aufgerufen**. Es gibt UI/Overlay sowie Stop/Reset-Aufrufe, aber keinen verlässlichen Startpunkt für lokale Runden. Das Laufzeit-Hint-System ist daher faktisch nicht aktiv.

**Produktentscheidung:** Dieses Verbesserungspaket soll **nur System 1 verbessern**: Spion-Hinweise direkt beim Aufdecken der Karte. Laufzeit-Hints während des Timers sollen nicht aktiviert werden.

---

## Wo liegen die Fehler? (Ursachen)

### Ursache 1 — 12 von 15 Kategorien haben keine statischen Wort-Hinweise

In `CategoryHints.swift` gibt es eine statische Datenbank (`hintsDatabase`) mit Wort-Hinweis-Paaren.

Die App hat **15 Default-Kategorien**:  
Tiere, Länder, Berufe, Früchte, Gemüse, Städte, Sportarten, Fahrzeuge, Berühmtheiten, Marken, FSK 18, Essen, Superkräfte, Körper & Gesundheit, Orte

Davon hat die Datenbank **sinnvolle Einträge nur für 3**:

| Kategorie | Wörter mit Hints | Von insgesamt |
|---|---|---|
| Tiere | 8 | 50 |
| Essen (via "Essen & Trinken") | ~8 | 50 |
| Berufe | 8 | 50 |

Zusätzlich hat die DB noch Einträge für **"Hobbys"** und **"Gegenstände"** — beides Kategorien die aus `Category.defaultCategories` **längst entfernt wurden**. Dead Code.

Die restlichen **12 Kategorien** (Länder, Früchte, Gemüse, Städte, Sportarten, Fahrzeuge, Berühmtheiten, Marken, FSK 18, Superkräfte, Körper & Gesundheit, Orte) haben **keinen einzigen statischen Eintrag**.

---

### Ursache 2 — Ohne KI gibt es keinen Fallback (Bug)

Im Karten-Hint-Pfad läuft es so:

```
ImposterWordAssigner
  └─ wenn showSpyHints = true
       └─ CategoryHints.getHintsWithAI(word, category)
            └─ wenn AIService.isAvailable = true  → KI generiert Hints
            └─ wenn AIService.isAvailable = false → gibt direkt [] zurück
```

`AIService.generateSpyHints` hätte intern zwar einen `generateFallbackSpyHints`, aber dieser wird **nie aufgerufen**, weil `getHintsWithAI` den KI-Aufruf schon vorher abbricht wenn `isAvailable = false`.

**Ergebnis:** Ohne Apple Intelligence (iOS 26+) bekommen 12 von 15 Kategorien auf der Spy-Karte garantiert keinen Hint — auch wenn ein sinnvoller generischer Fallback vorhanden wäre.

---

### Ursache 3 — Toggle in SpyOptionsView deaktiviert bei fehlender KI (Bug)

`Views/Sheets/SpyOptionsView.swift:109`

Der Toggle für "Spion-Hinweis" ist deaktiviert, wenn `AIService.shared.isAvailable = false`. Dadurch können selbst die **vorhandenen statischen Hints** (Tiere, Berufe, Essen) nicht genutzt werden — obwohl sie ohne KI funktionieren würden.

Der User kann das Feature schlicht nicht einschalten, wenn Apple Intelligence nicht da ist.

---

### Ursache 4 — Stille Lücke auf der Spy-Karte wenn kein Hint gefunden wird

`HintsManager.swift` (AI-Pfad in `createSpyCardTextWithAI`):

Wenn der KI-Aufruf kein Ergebnis liefert und kein statischer Hint vorhanden ist, wird **gar kein Text** angehängt. Der Spy sieht eine Karte ohne Hinweis-Abschnitt und weiß nicht ob das Feature aktiv ist.

---

### Ursache 5 — Die vorhandenen statischen Hints sind zu stark

Die Hints in der DB sind direkte Alleinstellungsmerkmale des Wortes:

```
"Hund"     → "Wau Wau"      → sofort erkennbar
"Elefant"  → "Rüssel"       → einziges Tier mit Rüssel
"Arzt"     → "Stethoskop"   → nahezu eindeutig
"Pizza"    → "Käse", "Rund" → kein Bluff mehr möglich
```

Ein guter Spy-Hint sollte **mehrere Wörter der Kategorie möglich halten**, nicht auf eines zeigen.

---

### Ursache 6 — KI-Hints werden zu aggressiv herausgefiltert

`AIService+Hints.swift`, Funktion `matchesCategoryAnchor` (Zeile ~397):

KI-generierte Hints werden gegen Ankerwort-Listen geprüft. Für Tiere muss der Hint enthalten: `["tier", "lebewesen", "lebt", "natur", "beweg", "frisst", ...]`

Ein guter atmosphärischer Hint wie `"Es ist sehr weich und beruhigend"` (passt zu mehreren Tieren, gute Vaguheit) wird **verworfen** weil kein Ankerwort vorkommt. Das erklärt warum KI-Pfade auf den schlechten Fallback zurückfallen.

---

## Was ein guter Spy-Hint sein muss (Game-Design-Theorie)

Recherche zu Spyfall, Imposter (Who is the Spy?), Codenames zeigt:

> **Hints müssen vage genug sein, dass 3–5 Wörter der Kategorie plausibel bleiben.  
> Der Spy soll eingrenzen — nicht sofort bestätigen.**

Das Spiel "Imposter / Who is the Spy?" (direkter Konkurrent) nutzt **1.200+ kuratierte Wort-Hint-Paare über 32 Kategorien mit 3 Schwierigkeitsstufen** als Referenz.

### Die 5 Kriterien für gute Hints

| # | Kriterium | Schlecht → Gut |
|---|---|---|
| 1 | **Indirektion** — Atmosphäre statt Merkmal | `"Rüssel"` → `"Symbol der Kraft und Würde"` |
| 2 | **Nur eine Dimension** — Sinne, Emotion oder Kontext | `"Roher Fisch + Reis + Stäbchen"` → `"Riecht nach Meer"` |
| 3 | **Für 3–5 Wörter plausibel** — kein Alleinstellungsmerkmal | `"Stethoskop"` (nur Arzt) → `"Trägt eine Uniform"` (mehrere Berufe) |
| 4 | **Nicht falsifizierbar** — keine Fakten-Checklisten | `"Wird in Italien gegessen"` → `"Erinnert an Ferien"` |
| 5 | **Kategorie-blind** | `"Ist ein Tier mit Mähne"` → `"König in seinem Revier"` |

### Beste Hint-Typen (nach Wirksamkeit)

1. **Sensorisch** — `"Riecht nach..."`, `"Klingt wie..."` → schwer zu falsifizieren
2. **Emotional/Atmosphärisch** — `"Macht Angst"`, `"Erinnert an Urlaub"` → viel Spielraum
3. **Kontext/Nutzung** — `"Findet man in..."`, `"Benutzt man wenn..."` → klar verständlich
4. **Negation** — `"Kein Tier, aber..."` → gut für schwieriges Niveau
5. **Kategorie-Hinweis** — ⚠️ nur als Zusatz, niemals als Haupt-Hint

---

## Was konkret zu ändern ist

### Änderung 1 — Toggle von KI-Verfügbarkeit entkoppeln ⭐⭐⭐ (Bug-Fix) ✅ Erledigt

**Datei:** `Views/Sheets/SpyOptionsView.swift:109`

Den Toggle immer aktivierbar machen. Statische Hints funktionieren ohne KI. Der Hint-Pfad soll KI nutzen **wenn verfügbar**, aber nicht daran scheitern wenn sie fehlt.

---

### Änderung 2 — Fallback in `getHintsWithAI` reparieren ⭐⭐⭐ (Bug-Fix) ✅ Erledigt

**Datei:** `Models/CategoryHints.swift`, Funktion `getHintsWithAI`

Aktuell:
```swift
if aiService.isAvailable {
    let aiHints = await aiService.generateSpyHints(...)
    if !aiHints.isEmpty { return aiHints }
}
return [] // ← Bug: kein Fallback
```

Soll:
```swift
if aiService.isAvailable {
    let aiHints = await aiService.generateSpyHints(...)
    if !aiHints.isEmpty { return aiHints }
}
// Fallback: generische Kategorie-Hints (Änderung 4)
return CategoryHints.getFallbackHints(for: word, in: categoryName)
```

---

### Änderung 3 — Zentrale Funktion `getBestSpyHint(word:category:)` ⭐⭐⭐ ✅ Erledigt

**Datei:** `Models/CategoryHints.swift` (neue Methode)

Eine einzige Funktion die die gesamte Hint-Hierarchie kapselt:

```
1. Statischer Wort-spezifischer Hint (DB)   → bester Fall
2. KI-generierter Hint (wenn verfügbar)      → gut
3. Generischer Kategorie-Fallback-Hint       → akzeptabel
4. Universeller Letzt-Fallback               → immer vorhanden
```

So hat jede aufrufende Stelle immer einen Hint — keine stillen Lücken mehr.

Die Funktion sollte zusätzlich Debug-Metadaten liefern, z.B. `source` und `strength`:

```
source: curated | ai | categoryFallback | universalFallback
strength: weak | medium | strong
```

Damit lässt sich später nachvollziehen, warum ein bestimmter Hint angezeigt wurde und ob zu oft nur Fallbacks greifen.

---

### Änderung 4 — `CategoryHints.hintsDatabase` für alle 15 Kategorien ausbauen ⭐⭐⭐ 🟡 Teilweise erledigt

**Datei:** `Models/CategoryHints.swift`

Für jede der 15 Default-Kategorien Wort-Hint-Paare eintragen. Pro Wort **3–5 Hints** auf dem richtigen Niveau:

- ❌ Nicht: direktes Alleinstellungsmerkmal (`"Rüssel"`, `"Wau Wau"`)  
- ✅ Gut: Eigenschaft die auf mehrere Wörter zutrifft (`"Lebt in warmen Regionen"`)  
- ✅ Besser: atmosphärisch + vage (`"Symbol der Kraft und Würde"`)

Zusätzlich pro Kategorie **4–6 generische Fallback-Hints** (unabhängig vom Wort):

```
Tiere:      "Es atmet", "Es fühlt etwas", "Es hat Eltern"
Länder:     "Man kann dort Urlaub machen", "Es hat eine eigene Flagge"
Sportarten: "Man schwitzt dabei", "Es braucht Ausdauer"
Städte:     "Viele Menschen kennen es", "Man kann dorthin fliegen"
```

Dead Code entfernen: Einträge für `"Hobbys"` und `"Gegenstände"`.

**Stand:** Dead Code wurde entfernt, direkte Hints wurden entschärft und es gibt jetzt Kategorie-Fallback-Hints für alle 15 Kategorien. Noch offen ist der vollständige Ausbau wort-spezifischer Hints für jedes einzelne Wort in allen Kategorien.

---

### Änderung 5 — `matchesCategoryAnchor` entfernen oder stark lockern ⭐⭐ ✅ Erledigt

**Datei:** `Services/AIService+Hints.swift`, Zeile ~397

Die Funktion verwirft gute KI-Hints weil sie zu restriktiv auf Ankerwörter prüft. Nur behalten:
- Das Wort selbst darf nicht vorkommen ✅
- Keine Zahlen/Buchstaben ✅
- Keine direkten Wortnamen, Synonyme oder eindeutigen Alleinstellungsmerkmale ✅
- Keine plumpen Kategorie-Sätze wie `"Es ist ein Tier"` ✅

Alles andere (Ankerwort-Listen pro Kategorie) → entfernen.

---

### Änderung 6 — UI-Text präzisieren und Laufzeit-Hints aus Scope nehmen ⭐ ✅ Erledigt

**Datei:** `Views/Sheets/SpyOptionsView.swift`

Da das Feature nur Karten-Hints beim Aufdecken meint, sollte der Text nicht mehr "in der Runde" sagen.

Vorschlag:

```
Titel: Spion-Hinweis anzeigen
Subtitle: Zeigt beim Aufdecken der Spion-Karte einen dezenten Tipp.
```

`HintService.startHints(...)` wird **nicht** lokal verdrahtet. Das Laufzeit-Hint-System bleibt außerhalb dieses Pakets.

---

## Umsetzungsstand 2026-05-25

### Erledigt

- ✅ Toggle `Spion-Hinweise anzeigen` ist nicht mehr von Apple Intelligence abhängig.
- ✅ Karten-Hints nutzen eine zentrale Hint-Hierarchie: kuratiert → KI → Kategorie-Fallback → Universal-Fallback.
- ✅ Es gibt keine leeren Spion-Karten mehr, wenn `showSpyHints` aktiv ist.
- ✅ Dead Code für alte Kategorien `Hobbys` und `Gegenstände` wurde entfernt.
- ✅ Direkte Alt-Hints wie `"Wau Wau"`, `"Rüssel"`, `"Stethoskop"` wurden entschärft.
- ✅ Kategorie-Fallback-Hints decken alle 15 Default-Kategorien ab.
- ✅ KI-Filter verwirft atmosphärische Hints nicht mehr wegen fehlender Kategorie-Anker.
- ✅ UI-Subtitle beschreibt jetzt Karten-Hints beim Aufdecken statt Laufzeit-Hints.
- ✅ XcodeBuildMCP Simulator-Build erfolgreich: `Games Collection`, Debug, iPhone 17 Simulator.

### Offen

- 🟡 Vollständige kuratierte Wort-Hint-Datenbank für alle Wörter aller 15 Kategorien.
- 🟡 Optional: manuelle Playtests pro Kategorie, um zu starke oder zu generische Fallbacks nachzuschärfen.
- 🟡 Optional: separate Debug-Ansicht oder Log-Auswertung für `source`/`strength`, falls später geprüft werden soll, wie oft Fallbacks statt kuratierter Hints greifen.

---

## Reihenfolge der Umsetzung

### Schritt 1 — Feature-Scope festlegen: nur Karten-Hints

**Entscheidung:** Dieses Paket verbessert nur den Karten-Hint beim Aufdecken der Spion-Karte.

Laufzeit-Hints während des Timers werden nicht aktiviert.

**Warum:** Dieser Pfad ist bereits produktiv genutzt und direkt mit der Option `Spion-Hinweis anzeigen` verbunden. Das verhindert, dass Karten- und Rundensystem weiter vermischt werden.

### Schritt 2 — Bug-Fixes, damit überhaupt immer ein Hint möglich ist

1. **Änderung 1:** Toggle von KI-Verfügbarkeit entkoppeln  
2. **Änderung 2:** Fallback in `getHintsWithAI` reparieren

**Warum:** Solange der Toggle ohne KI deaktiviert ist und `getHintsWithAI` bei fehlender KI `[]` liefert, bleibt das Feature für viele Nutzer und Kategorien kaputt. Das sind kleine Änderungen mit großem Effekt.

### Schritt 3 — Hint-Hierarchie zentralisieren

3. **Änderung 3:** `getBestSpyHint(word:category:)` als zentrale Funktion

**Warum:** Erst danach lohnt sich der Ausbau der Datenbank richtig, weil alle Quellen über dieselbe Logik laufen: kuratiert, KI, Kategorie-Fallback, universeller Fallback. Das verhindert doppelte Sonderlogik in `HintsManager`, `CategoryHints` und `AIService`.

### Schritt 4 — Inhaltliche Qualität verbessern

4. **Änderung 4:** `hintsDatabase` für alle 15 Kategorien ausbauen + direkte Hints entschärfen  
5. **Änderung 5:** `matchesCategoryAnchor` lockern

**Warum:** Jetzt gibt es eine stabile Pipeline. Danach kann man die Qualität erhöhen, ohne dass Hinweise wieder in leeren Pfaden verschwinden oder gute KI-Hints unnötig verworfen werden.

### Schritt 5 — UI-Text an Karten-Hints anpassen

6. **Änderung 6:** UI-Label auf Karten-Hints anpassen

**Warum:** Das Feature soll nicht während der Runde funken, sondern beim Karten-Aufdecken helfen. Der Text muss dieses Verhalten klar beschreiben.

---

## Schnell-Check: Dateien die angefasst werden

| Datei | Was ändert sich |
|---|---|
| `Views/Sheets/SpyOptionsView.swift` | Toggle entkoppelt von KI-Verfügbarkeit |
| `Models/CategoryHints.swift` | getHintsWithAI Fallback repariert, getBestSpyHint neu, DB für alle 15 Kategorien, Dead Code raus |
| `Services/AIService+Hints.swift` | matchesCategoryAnchor entfernt/gelockert |
| `Models/HintsManager.swift` | Nutzt getBestSpyHint statt direktem DB-Lookup |
| `Views/Sheets/SpyOptionsView.swift` | Subtitle auf Karten-Hints präzisieren |

---

*Ende des Dokuments.*
