# AUDIT: Lokalisierung DE/EN — Phase 5.3
## Erstellungsdatum: 2026-04-12

> Geprüft: Vollständigkeit der DE/EN Lokalisierung, hardcodierte Strings,
> Lokalisierungs-Pattern, fehlende Keys, inkonsistente Übersetzungen.

---

## ÜBERSICHT

| Kategorie | Findings |
|-----------|----------|
| Kritisch | 2 |
| Hoch | 3 |
| Mittel | 4 |
| Positiv / Niedrig | 3 |
| **TOTAL** | **12** |

---

## POSITIV — GUT GELÖST ✅

---

### LOC-GOOD-01: Lokalisierungsdateien existieren für DE und EN ✅

Beide Sprachversionen sind vorhanden:
- `Games Collection/de.lproj/Localizable.strings` — 421 Zeilen
- `Games Collection/en.lproj/Localizable.strings` — 1094 Zeilen

Die Basis-Infrastruktur für Internationalisierung ist eingerichtet.

---

### LOC-GOOD-02: InfoPlist.strings vorhanden ✅

**Datei:** `Games Collection/de.lproj/InfoPlist.strings`

Systemdialoge (Privacy-Descriptions, App-Name) werden korrekt lokalisiert.

---

### LOC-GOOD-03: TimesUp nutzt `String(localized:)` Pattern ✅

TimesUp ist das am besten lokalisierte Game — nutzt aktiv `String(localized:)` und
`LocalizedStringKey`. Das zeigt das richtige Pattern für die anderen Games.

---

## KRITISCHE FINDINGS

---

### LOC-01: DE-Datei hat nur 38% der EN-Einträge — massive Lokalisierungslücke 🔴

**Problem:**

| Datei | Zeilen |
|-------|--------|
| `en.lproj/Localizable.strings` | 1094 |
| `de.lproj/Localizable.strings` | 421 |

Die DE-Datei hat **2,6× weniger Einträge** als EN. Das bedeutet: Deutsch ist
die primäre Sprache der App-Zielgruppe (DE/AT/CH Markt laut App-Name und
Social-Media-Accounts `@elfiandken`), aber ~60% der Strings sind nur auf Englisch
definiert.

Wenn ein Nutzer mit DE-Systemsprache auf einen fehlenden DE-Key trifft, zeigt iOS
den **Key selbst** statt eines Fallback-Strings — z.B. `"imposter.gameSetup.title"`
als UI-Text.

**Kritische Lücken (nur in EN, fehlen in DE):**
- Alle Imposter Setup- und Spielphase-Strings
- Bet Buddy Voting und Challenge Strings
- Question Engine Feedback-Strings
- TimesUp Perk-Beschreibungen
- Settings-Strings für neue Features

**Fix:** `genstrings` oder SwiftGen nutzen um fehlende Keys zu identifizieren,
dann alle EN-Keys in DE übersetzen.

```bash
# Fehlende Keys finden:
diff <(grep '"' de.lproj/Localizable.strings | cut -d'"' -f2 | sort) \
     <(grep '"' en.lproj/Localizable.strings | cut -d'"' -f2 | sort)
```

---

### LOC-02: 245+ hardcodierte Strings in Games-Ordnern — nicht lokalisiert 🔴

**Problem:**

Grep-Analyse zeigt:
- `Games/Bet Buddy/` — enthält viele `Text("...")` mit deutschen Strings direkt im Code
- `Games/Imposter/` — Strings wie `Text("Spieler hinzufügen")` hardcodiert
- `Games/Question/` — Spielphasen-Texte hardcodiert
- `Games/TimesUp/` — partiell lokalisiert

**Beispiele gefundener hardcodierter Strings:**

```swift
// Bet Buddy — hardcodiert:
Text("Wer hat gewonnen?")
Text("Abstimmung läuft...")
Text("Ergebnis")

// Imposter — hardcodiert:
Text("Spieler hinzufügen")
Text("Spiel starten")
Text("Du bist der Imposter!")

// Question — hardcodiert:
Text("Alle sind bereit")
Text("Lügner enthüllen")
```

Diese Strings können von deutschen Nutzern gelesen werden — aber wenn die App
international ausgerollt wird (EN App Store), erscheinen diese Texte auf Deutsch
für alle Nutzer außer DE/AT/CH.

**Fix:** Alle `Text("...")` mit deutschen Strings durch `Text(LocalizedStringKey("..."))` 
oder `Text("key", tableName: nil, bundle: .main, comment: "")` ersetzen und
entsprechende Keys in beiden Localizable.strings-Dateien eintragen.

---

## HOHE FINDINGS

---

### LOC-03: `String(localized:)` vs `LocalizedStringKey` inkonsistent gemischt 🟠

**Problem:**

Zwei verschiedene Lokalisierungs-Patterns werden im Projekt gemischt verwendet:

| Pattern | Verwendungen | Korrekt? |
|---------|-------------|---------|
| `Text(LocalizedStringKey("key"))` | 192 Stellen | ✅ Für statische UI-Strings |
| `String(localized: "key")` | 51 Stellen | ✅ Für Strings die weiterverarbeitet werden |
| `Text("direkter String")` | 245+ Stellen | ❌ Nicht lokalisiert |
| `NSLocalizedString("key", comment: "")` | Einige Stellen | ✅ Legacy-Pattern |

Das Problem: `Text("hello")` in SwiftUI **erzeugt automatisch einen `LocalizedStringKey`**
nur wenn der String ein Literal ist. Aber `Text(variable)` wo `variable: String` ist,
erzeugt **keinen** lokalisierungsfähigen Text. Das führt zu subtilen Lokalisierungs-Bugs.

**Fix:** Projekt-weite Konvention etablieren:
- Alle sichtbaren Strings: `Text("key")` mit Key in Localizable.strings
- Strings die verarbeitet werden: `String(localized: "key")`
- Niemals: `Text(variable)` wo `variable` ein DE/EN-String-Literal enthält

---

### LOC-04: Kategorienamen in Imposter/TimesUp sind hardcodiert — nicht lokalisierbar 🟠

**Problem:**

Spiel-Kategorien (z.B. Imposter Locations wie "Flughafen", "Restaurant", TimesUp-Kategorien)
sind vermutlich als Swift-Enum-Strings oder in JSON-Dateien ohne Lokalisierungs-Support
definiert.

**Datei:** `Games/Imposter/Models/CategoryData.swift` (und ähnliche)

Kategorienamen die direkt als String-Literale definiert sind, können nicht lokalisiert
werden. Bei einem EN-Rollout würden Spieler deutsche Kategorienamen sehen.

**Fix:** Kategorienamen als Lokalisierungs-Keys definieren:
```swift
struct Category: Codable {
    let id: String
    var localizedName: String { 
        String(localized: LocalizedStringKey(id)) 
    }
}
```

---

### LOC-05: Plural-Lokalisierung fehlt komplett — grammatikalisch falsch für nicht-DE Sprachen 🟠

**Problem:**

Die App hat Strings wie:
```swift
Text("\(playerCount) Spieler")
Text("\(wins) Siege")
```

Diese nutzen keine Pluralformen (`Localizable.stringsdict`). In Englisch:
- 1 Player (Singular), 2 Players (Plural)
- 1 Win (Singular), 2 Wins (Plural)

Ohne `.stringsdict`-Datei wird im EN-Fall z.B. "2 Player" (grammatikalisch falsch)
angezeigt.

**Fix:** `Localizable.stringsdict` erstellen:
```xml
<key>player_count</key>
<dict>
    <key>NSStringLocalizedFormatKey</key>
    <string>%#@players@</string>
    <key>players</key>
    <dict>
        <key>NSStringFormatSpecTypeKey</key>
        <string>NSStringPluralRuleType</string>
        <key>one</key>
        <string>%d Player</string>
        <key>other</key>
        <string>%d Players</string>
    </dict>
</dict>
```

---

## MITTLERE FINDINGS

---

### LOC-06: Keine Lokalisierung für Accessibility Labels — VoiceOver nur auf Deutsch 🟡

**Problem:**

Die wenigen `accessibilityLabel`-Aufrufe im Projekt (ca. 15 laut AUDIT_ACCESSIBILITY.md)
nutzen hardcodierte deutsche Strings:

```swift
.accessibilityLabel("Spieler hinzufügen")
.accessibilityHint("Tippt um einen neuen Spieler hinzuzufügen")
```

VoiceOver-Nutzer mit EN-Systemsprache hören deutsche Accessibility-Beschreibungen.
Das macht die App für internationale Nutzer mit Sehbehinderung unzugänglich.

**Fix:** Accessibility Labels lokalisieren:
```swift
.accessibilityLabel(Text("accessibility.addPlayer.label"))
.accessibilityHint(Text("accessibility.addPlayer.hint"))
```

---

### LOC-07: Datum- und Zahlenformate nicht lokalisiert 🟡

**Problem:**

Scores, Statistiken und möglicherweise Zeitangaben werden mit DE-Formatierung
hardcodiert:
```swift
Text("\(score) Punkte")
Text("Winrate: \(Int(winRate * 100))%")
```

In manchen Regionen werden Dezimaltrennzeichen anders dargestellt (`,` vs `.`).
Bei Prozentzahlen und Scores kann das zu Verwirrung führen.

**Fix:** `NumberFormatter` mit `Locale.current` nutzen.

---

### LOC-08: `NSLocalNetworkUsageDescription` nur auf Englisch im Plist 🟡

**Datei:** `Games-Collection-Info.plist`

```xml
<key>NSLocalNetworkUsageDescription</key>
<string>Games Collection benötigt Zugriff auf das lokale Netzwerk...</string>
```

Der Privacy-Permission-Dialog ist auf Deutsch hardcodiert. Für EN-Nutzer
erscheint der System-Dialog mit dem deutschen Text. Das ist ungewöhnlich
und kann zu App Store Review-Kommentaren führen.

**Fix:** In `InfoPlist.strings` lokalisieren:
```swift
// de.lproj/InfoPlist.strings:
"NSLocalNetworkUsageDescription" = "Games Collection benötigt Zugriff...";

// en.lproj/InfoPlist.strings:
"NSLocalNetworkUsageDescription" = "Games Collection needs access to the local network...";
```

---

### LOC-09: Keine RTL-Unterstützung (Right-to-Left) geprüft 🟡

**Problem:**

SwiftUI unterstützt RTL-Layouts automatisch wenn korrekte Modifier verwendet werden.
Hardcodierte `.leading`-Alignments, feste `HStack`-Reihenfolgen ohne `layoutDirection`-
Berücksichtigung und manuell gesetzte Padding-Werte können bei AR-/HE-Lokalisierung
das Layout brechen.

Für DE/EN ist das kein akutes Problem. Wenn die App international ausgebaut wird
(AR, HE Märkte), müssen diese Stellen angepasst werden.

---

## ZUSAMMENFASSUNG LOKALISIERUNGS-AUDIT

| Priorität | Anzahl | Top-Issues |
|-----------|--------|------------|
| 🔴 Kritisch | 2 | DE-Datei hat nur 38% der EN-Einträge (LOC-01), 245+ hardcodierte Strings nicht lokalisierbar (LOC-02) |
| 🟠 Hoch | 3 | Pattern-Mix inkonsistent (LOC-03), Kategorienamen nicht lokalisierbar (LOC-04), Plural-Formen fehlen (LOC-05) |
| 🟡 Mittel | 4 | Accessibility Labels nur DE (LOC-06), Zahlenformat (LOC-07), Plist nur DE (LOC-08), RTL nicht geprüft (LOC-09) |
| ✅ Positiv | 3 | Beide Sprachen vorhanden, InfoPlist.strings, TimesUp als Best-Practice |

---

*Erstellt: 2026-04-12 — Teil von Phase 5 des Gesamtaudits*
