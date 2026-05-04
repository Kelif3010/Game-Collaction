# AUDIT: App Store Readiness — Phase 5.4
## Erstellungsdatum: 2026-04-12

> Geprüft: Privacy Manifest, Metadaten, Icons, Export Compliance,
> Crash-Reporting, StoreKit, Entitlements, App Store Connect Checkliste.

---

## ÜBERSICHT

| Kategorie | Findings |
|-----------|----------|
| Kritisch (Blockiert Einreichung) | 3 |
| Hoch (Reviewrisiko) | 4 |
| Mittel (Best Practice) | 3 |
| Positiv | 5 |
| **TOTAL** | **15** |

---

## POSITIV — BEREIT ✅

---

### AS-GOOD-01: App-Icons für Light, Dark und Tinted vorhanden ✅

**Datei:** `Games Collection/Assets.xcassets/AppIcon.appiconset/Contents.json`

Alle drei iOS 18+ Icon-Varianten sind konfiguriert:
- Light Mode Icon (universell)
- Dark Mode Icon
- Tinted Icon

Außerdem: Alternativer App-Icon (`AppIconAlt`) in `CFBundleAlternateIcons` registriert.
Das ist ein positives Feature.

---

### AS-GOOD-02: MCSession mit Verschlüsselung ✅

`encryptionPreference: .required` — App nutzt verschlüsseltes Networking,
was beim Privacy-Review positiv bewertet wird.

---

### AS-GOOD-03: StoreKit `requestReview` korrekt verwendet ✅

**Datei:** `Games/Bet Buddy/Screens/ResultView.swift`

`requestReview` wird nach einem Spielergebnis ausgelöst — ein natürlicher,
nicht aufdringlicher Zeitpunkt. Apple bevorzugt dieses Pattern.

---

### AS-GOOD-04: `NSLocalNetworkUsageDescription` vorhanden ✅

**Datei:** `Games-Collection-Info.plist:27`

Korrekte Beschreibung für MultipeerConnectivity vorhanden. Apple Review Team
prüft diese Strings auf Vollständigkeit.

---

### AS-GOOD-05: Keine In-App-Käufe — einfacherer Review-Prozess ✅

Keine StoreKit-Produkte (außer requestReview) gefunden. Kein IAP-Review
nötig, keine Steuerformulare für digitale Güter.

---

## KRITISCHE FINDINGS (blockieren Einreichung)

---

### AS-01: `PrivacyInfo.xcprivacy` fehlt komplett — App Store Ablehnung wahrscheinlich 🔴

*(Bereits als SEC-01 dokumentiert — hier App-Store-Kontext)*

**Problem:**
Apple verlangt seit **Frühling 2024** für alle neuen App-Einreichungen und
Updates eine Privacy Manifest Datei. Die App nutzt APIs die eine Deklaration erfordern:

| API | Required Reason Code |
|-----|---------------------|
| `UserDefaults` | `CA92.1` — User Defaults |
| `NSUbiquitousKeyValueStore` | Datenschutzerklärung nötig |
| `AVSpeechSynthesizer` | Dokumentation nötig (nur Output) |
| `MultipeerConnectivity` | Netzwerk-Deklaration |

Ohne diese Datei wird die App beim automatisierten Review **oder** beim
manuellen Review abgelehnt. Die Fehlermeldung ist:

> "ITMS-91053: Missing API declaration - Your app's code references one or more
> APIs that require reasons..."

**Fix:** `PrivacyInfo.xcprivacy` ins App-Target hinzufügen:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>NSPrivacyAccessedAPITypes</key>
    <array>
        <dict>
            <key>NSPrivacyAccessedAPIType</key>
            <string>NSPrivacyAccessedAPICategoryUserDefaults</string>
            <key>NSPrivacyAccessedAPITypeReasons</key>
            <array>
                <string>CA92.1</string>
            </array>
        </dict>
    </array>
    <key>NSPrivacyCollectedDataTypes</key>
    <array/>
    <key>NSPrivacyTrackingDomains</key>
    <array/>
    <key>NSPrivacyTracking</key>
    <false/>
</dict>
</plist>
```

**Priorität:** Muss vor der ersten Einreichung erledigt sein.

---

### AS-02: `ITSAppUsesNonExemptEncryption` fehlt im Plist — Export Compliance Fehler 🔴

**Problem:**
`Games-Collection-Info.plist` enthält keinen `ITSAppUsesNonExemptEncryption` Key.
Apple verlangt diese Deklaration für alle Apps.

Die App nutzt:
- `MCSession` mit `encryptionPreference: .required` (System-TLS)
- iCloud KV Store (Apple-seitig verschlüsselt)
- Keine eigene Kryptographie

Beide nutzen **Standard-iOS-Verschlüsselung (AES/TLS)** — das ist
**US Export Exempt** unter BIS EAR.

Wenn `ITSAppUsesNonExemptEncryption` fehlt, fragt Apple Connect beim Upload
interaktiv nach — das verzögert den Einreichungsprozess.

**Fix:** Zum Plist hinzufügen:
```xml
<key>ITSAppUsesNonExemptEncryption</key>
<false/>
```

*(Wert `false` ist korrekt da nur Standard-iOS-Encryption genutzt wird)*

---

### AS-03: `CFBundleVersion` und `CFBundleShortVersionString` nicht im Plist — Build-Fehler 🔴

**Problem:**
`Games-Collection-Info.plist` enthält keine expliziten `CFBundleVersion` oder
`CFBundleShortVersionString` Keys. Diese sind vermutlich in der `project.pbxproj`
über Build Settings (`CURRENT_PROJECT_VERSION`, `MARKETING_VERSION`) definiert.

Das ist per se OK, aber:
1. Es gibt kein explizites Version-Tracking in der Plist-Datei
2. Bei der Einreichung prüft Apple ob Version > letzte veröffentlichte Version
3. Build Number muss **monoton steigen** (nicht zurücksetzen!)

**Prüfen:** In App Store Connect: Welche Version wurde zuletzt eingereicht?
Sicherstellen dass `MARKETING_VERSION` (z.B. `1.0.0`) und `CURRENT_PROJECT_VERSION`
(Build Number, z.B. `1`) korrekt gesetzt sind.

---

## HOHE FINDINGS (Reviewrisiko)

---

### AS-04: Keine Privacy Policy URL in App Store Connect 🟠

*(Bereits als SEC-04 dokumentiert — hier App-Store-Kontext)*

**Problem:**
Die App synchronisiert Spielernamen via iCloud. Das sind personenbezogene Daten.
Apple **verlangt** eine Privacy Policy URL für:
- Apps die personenbezogene Daten sammeln/synchronisieren
- Apps die mit iCloud-Services arbeiten
- DSGVO/GDPR-pflichtige Apps (EU-Markt)

Ohne Privacy Policy URL in App Store Connect kann die App nicht eingereicht werden.

**Fix:**
1. Privacy Policy Dokument erstellen (kann auf GitHub Pages, eigener Website oder
   in App als In-App-Screen sein)
2. URL in App Store Connect unter "App Information" → "Privacy Policy URL" eintragen
3. In App unter Settings einen Link zur Privacy Policy hinzufügen

---

### AS-05: Keine Altersfreigabe-Kategorien definiert — Standard (4+) möglicherweise falsch 🟠

**Problem:**
Die App enthält:
- Spielinhalt der von Jugendlichen bis Erwachsenen gespielt wird
- Möglichkeit eigene Spieler/Namen hinzuzufügen (User-generierter Content!)
- Imposter "Spy"-Thema

Bei User-generiertem Content (Spielernamen, eigene Kategorien) verlangt Apple
**Altersfreigabe 12+** oder **17+** je nach Moderations-Policy.

**Prüfen in App Store Connect:**
- Ist "User-Generated Content" aktiviert?
- Gibt es Moderations-Features (Melden, Blockieren)?
- Ist "Unrestricted Web Access" aktiviert?

---

### AS-06: App-Beschreibung für App Store nicht vorbereitet 🟠

**Problem:**
Kein `AppStoreDescription.md` oder ähnliches Dokument im Projekt. Der App-Store-
Eintrag braucht:

| Element | Status |
|---------|--------|
| App-Name (30 Zeichen max.) | Unklar |
| Untertitel (30 Zeichen max.) | Fehlt |
| Beschreibung (4000 Zeichen max.) | Fehlt |
| Promo-Text (170 Zeichen max.) | Fehlt |
| Keywords (100 Zeichen max.) | Fehlt |
| Screenshots (6.9" + 6.3" + 12.9" iPad) | Fehlt |
| App-Preview-Video (optional) | Fehlt |

**Empfehlung:** App-Store-Texte vorbereiten und Screenshots mit dem Simulator
erstellen (iPhone 16 Pro Max 6.9" + iPhone 16 6.3" minimum).

---

### AS-07: Keine In-App Hinweise für neue Features — Onboarding fehlt 🟠

*(Bereits als UX-Finding dokumentiert — hier App-Store-Relevanz)*

**Problem:**
Apple Review Team testet jede App. Ohne Onboarding oder Demo-Modus kann der
Reviewer folgendes nicht verstehen:
- Wie startet man eine Multiplayer-Session?
- Wie funktioniert das Imposter-Spiel?
- Was ist TimesUp?

Apps die beim Review unklar sind, erhalten häufiger Ablehnungen oder Nachfragen.

**Empfehlung:** Kurzes Onboarding für neue Nutzer oder "Demo-Modus" mit
vorausgefüllten Spielern für den ersten Start.

---

## MITTLERE FINDINGS

---

### AS-08: Kein Crash-Reporter integriert — post-Launch Debugging schwierig 🟡

**Problem:**
Die App hat keinen Crash-Reporter (Firebase Crashlytics, Sentry, etc.).
Nach dem App-Store-Launch gibt es keine Möglichkeit Crashes von echten Nutzern
zu analysieren.

Xcode Organizer zeigt zwar Apple-interne Crash-Reports, aber:
- Symbolisierung ist manchmal unvollständig
- Kein Custom-Context möglich
- Kein Alert bei kritischen Absturzraten

**Empfehlung für Post-Launch:** Firebase Crashlytics oder Sentry einbinden.
Das erfordert ein weiteres Privacy-Update, da Crash-Daten an externe Server
gesendet werden.

---

### AS-09: App-Icon für iPad nicht explizit definiert 🟡

**Datei:** `Games Collection/Assets.xcassets/AppIcon.appiconset/Contents.json`

Das Icon ist als `"idiom": "universal", "platform": "ios"` definiert.
iPadOS akzeptiert das universelle Icon, aber für einen optimalen App-Store-Eintrag
sollte das Icon explizit für iPad getestet werden (große Fläche → andere Wirkung).

---

### AS-10: `NSBonjourServices` nur TCP+UDP — kein HTTPS-Only Mode 🟡

**Datei:** `Games-Collection-Info.plist:21-25`

```xml
<key>NSBonjourServices</key>
<array>
    <string>_gc-party._tcp</string>
    <string>_gc-party._udp</string>
</array>
```

MultipeerConnectivity (Bonjour) nutzt lokales Netzwerk direkt. Das ist korrekt.
Aber: Apple bevorzugt Apps die ihre Netzwerkkommunikation beschreiben.
Ein Privacy-Reviewer könnte nach der Notwendigkeit von UDP fragen.

---

## APP STORE SUBMISSION CHECKLISTE

```
✅ App-Icons: Light / Dark / Tinted vorhanden
✅ Alternative App-Icons konfiguriert
✅ NSLocalNetworkUsageDescription vorhanden
✅ Keine externen API-Keys im Code
✅ MCSession verschlüsselt

❌ PrivacyInfo.xcprivacy fehlt → BLOCKER
❌ ITSAppUsesNonExemptEncryption fehlt → BLOCKER
❓ Privacy Policy URL in App Store Connect? → Prüfen
❓ Altersfreigabe korrekt konfiguriert? → Prüfen
❓ Version/Build-Nummer korrekt? → Prüfen

⬜ App-Store-Texte (Beschreibung, Keywords, Untertitel)
⬜ Screenshots (6.9" + 6.3" minimum)
⬜ Testnotizen für App-Review-Team vorbereiten
```

---

## ZUSAMMENFASSUNG APP STORE READINESS

| Priorität | Anzahl | Top-Issues |
|-----------|--------|------------|
| 🔴 Kritisch (Blocker) | 3 | Privacy Manifest fehlt (AS-01), Export Compliance fehlt (AS-02), Version unklar (AS-03) |
| 🟠 Hoch (Review-Risiko) | 4 | Keine Privacy Policy (AS-04), Altersfreigabe (AS-05), Kein App-Store-Text (AS-06), Kein Onboarding (AS-07) |
| 🟡 Mittel | 3 | Kein Crash-Reporter (AS-08), iPad-Icon (AS-09), NSBonjour UDP (AS-10) |
| ✅ Positiv | 5 | Icons vollständig, Verschlüsselung, requestReview, NSLocalNetworkUsage, Kein IAP |

---

*Erstellt: 2026-04-12 — Teil von Phase 5 des Gesamtaudits*
