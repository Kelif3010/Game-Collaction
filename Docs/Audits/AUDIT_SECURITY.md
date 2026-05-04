# AUDIT: Security & iOS Best Practices — Phase 5.1 + 5.2
## Erstellungsdatum: 2026-04-12

> Geprüft: API Keys, Datenspeicherung, Netzwerksicherheit, Privacy,
> Entitlements, iOS Security Best Practices.

---

## ÜBERSICHT

| Kategorie | Findings |
|-----------|----------|
| Kritisch | 2 |
| Hoch | 3 |
| Mittel | 4 |
| Niedrig / Positiv | 5 |
| **TOTAL** | **14** |

---

## POSITIV — GUT GELÖST ✅

---

### SEC-GOOD-01: Keine externen API-Keys im Code ✅

`AIService` nutzt **Apple Intelligence** (`FoundationModels`) — keine OpenAI-,
Anthropic- oder anderen externen API-Keys. Kein Risiko von Key-Leaks.

```swift
// AIService.swift — Apple On-Device AI:
#if canImport(FoundationModels)
import FoundationModels
// session = LanguageModelSession(instructions: ...)
#endif
```

---

### SEC-GOOD-02: MCP-Session mit `.required` Verschlüsselung ✅

```swift
// MultipeerManager.swift:284
session = MCSession(peer: myPeerId, securityIdentity: nil, encryptionPreference: .required)
```

Multiplayer-Traffic ist verschlüsselt. Korrekt.

---

### SEC-GOOD-03: Keine hardcodierten Credentials im Quellcode ✅

Kein `password`, `secret`, `token` oder `credential` String-Literal in UserDefaults-Keys.

---

### SEC-GOOD-04: Entitlements minimal — Principle of Least Privilege ✅

**Datei:** `Games Collection/Games Collection.entitlements`

```xml
<dict>
    <key>com.apple.developer.icloud-container-identifiers</key>
    <array/>
    <key>com.apple.developer.ubiquity-kvstore-identifier</key>
    <string>$(TeamIdentifierPrefix)$(CFBundleIdentifier)</string>
</dict>
```

Nur iCloud KV Store — keine Push Notifications, keine Background Fetch,
keine unnötigen Capabilities. Sauber.

---

### SEC-GOOD-05: `NSLocalNetworkUsageDescription` vorhanden ✅

**Datei:** `Games-Collection-Info.plist`

```xml
<key>NSLocalNetworkUsageDescription</key>
<string>Games Collection benötigt Zugriff auf das lokale Netzwerk...</string>
```

Korrekt für MultipeerConnectivity (Bonjour/TCP+UDP).

---

## KRITISCHE FINDINGS

---

### SEC-01: Fehlende Privacy Manifest Datei (`.xcprivacy`) — App Store Ablehnung möglich 🔴

**Problem:**
Apple verlangt seit 2024 für alle Apps die bestimmte APIs nutzen eine
**Privacy Manifest** Datei (`PrivacyInfo.xcprivacy`). Die App nutzt:

| API | Benötigt Privacy Manifest-Eintrag |
|-----|----------------------------------|
| `UserDefaults` (Nutzerdaten) | `NSPrivacyAccessedAPICategoryUserDefaults` |
| `NSUbiquitousKeyValueStore` (iCloud) | Datenschutzerklärung nötig |
| `AVSpeechSynthesizer` (TTS) | Mikrofon-nahes API |
| `MultipeerConnectivity` | Netzwerk-Nutzung |

Ohne `PrivacyInfo.xcprivacy` kann Apple die App ablehnen oder aus dem Store entfernen.

**Fix:** `PrivacyInfo.xcprivacy` in das App-Target hinzufügen:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC ...>
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

---

### SEC-02: Force-Unwrap auf Social-Media URLs — Crash bei Typo 🔴

**Datei:** `Games Collection/MainSettingsView.swift:156, 166, 181`

```swift
Link(destination: URL(string: "https://www.youtube.com/@elfiandken")!) { ... }
Link(destination: URL(string: "https://www.instagram.com/elfiandken/")!) { ... }
Link(destination: URL(string: "mailto:elfiandken@icloud.com")!) { ... }
```

Alle drei URLs sind force-unwrapped. Falls je ein Tippfehler in einer URL entsteht
(bei einem Update), crasht die App beim Rendern von `MainSettingsView`.

**Fix:**
```swift
if let url = URL(string: "https://www.youtube.com/@elfiandken") {
    Link(destination: url) { ... }
}
```

---

## HOHE FINDINGS

---

### SEC-03: Kein `NSSpeechRecognitionUsageDescription` trotz TTS-Feature 🟠

**Problem:**
Die App nutzt `AVSpeechSynthesizer` für Text-to-Speech in Imposter.
Obwohl TTS keine Mikrofon-Berechtigung benötigt (es ist Output, kein Input),
sollte in der Privacy Manifest klar deklariert sein, dass kein Mikrofon
genutzt wird. Apple App Reviewers können bei AVFoundation-Imports ohne
Privacy-Deklaration nachfragen.

**Empfehlung:** Im Privacy Manifest explizit dokumentieren dass nur
`AVSpeechSynthesizer` (Output) genutzt wird, kein Speech Recognition.

---

### SEC-04: Spielernamen in `NSUbiquitousKeyValueStore` ohne Datenschutzhinweis 🟠

**Datei:** `Games Collection/Services/GlobalPlayerManager.swift`

Spielernamen werden via iCloud KV Store zwischen Geräten synchronisiert.
Das sind personenbezogene Daten (Namen echter Personen). In der DSGVO/GDPR
und beim App Store erfordert das:

1. Eine Datenschutzerklärung (Privacy Policy) die diese Sync-Funktion erwähnt
2. Einen In-App-Hinweis beim ersten Sync dass Namen in iCloud gespeichert werden
3. Eine Möglichkeit zum Löschen ("Alle Daten löschen" Button existiert — gut!)

**Prüfen:** Hat die App eine Privacy Policy URL im App Store Connect eingetragen?

---

### SEC-05: `UserDefaults` für alle Spielerdaten — kein Keychain für sensible Settings 🟠

**Problem:**
Alle Settings, Spielernamen, Scores und Konfiguration werden in `UserDefaults`
gespeichert. UserDefaults ist unverschlüsselt. Bei einem Jailbreak-Gerät oder
forensischen Analyse sind alle Nutzerdaten auslesbar.

Für eine Party-Game-App ist das Risiko gering (keine Passwörter, keine Zahlungsdaten),
aber es sollte dokumentiert sein. Wenn zukünftig sensiblere Daten gespeichert werden
(z.B. Account-Tokens), muss Keychain verwendet werden.

---

## MITTLERE FINDINGS

---

### SEC-06: `AVAudioSession` ohne Error-Handling — stiller Fail bei Audio-Konflikten 🟡

**Datei:** `Games Collection/Services/SoundManager.swift:35-36`

```swift
try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
try AVAudioSession.sharedInstance().setActive(true)
```

Diese Calls sind in einem try-catch, aber wenn sie fehlschlagen (z.B. während
eines Telefonanrufs), könnte der Sound still versagen. Nutzer wissen dann nicht
warum kein Sound kommt.

---

### SEC-07: `MPC Room Code` ohne Brute-Force Schutz 🟡

**Datei:** `Games Collection/Services/MultipeerManager.swift`

Raum-Codes sind kurze Strings (vermutlich 4-6 Zeichen). Im lokalen Netzwerk
kann ein Angreifer theoretisch alle Codes durchprobieren um einer Lobby beizutreten.
Für eine Party-Game-App im Home-Netz ist das Risiko niedrig, aber ein Code mit
mindestens 6 alphanumerischen Zeichen und einer Rate-Limiting-Logik wäre besser.

---

### SEC-08: `iCloud KV Store` Limit — 1 MB Datenlimit nicht überwacht 🟡

**Datei:** `Games Collection/Services/GlobalPlayerManager.swift`

`NSUbiquitousKeyValueStore` hat ein **1 MB Limit** pro App. Bei vielen Spielern
mit langen Namen kann dieses Limit theoretisch erreicht werden. Es gibt keine
Größenprüfung vor dem Speichern.

```swift
// Keine Größenprüfung:
iCloudStore.set(data, forKey: storageKey)
```

**Fix:** Datenmenge vor Sync prüfen:
```swift
if data.count < 900_000 {  // 900KB Sicherheitspuffer
    iCloudStore.set(data, forKey: storageKey)
}
```

---

### SEC-09: `com.apple.developer.icloud-container-identifiers` ist leer 🟡

**Datei:** `Games Collection/Games Collection.entitlements`

```xml
<key>com.apple.developer.icloud-container-identifiers</key>
<array/>   <!-- ← Leer! -->
```

Die iCloud-Container-IDs sind nicht eingetragen. Das bedeutet kein CloudKit-Zugriff
(nur KV Store). Wenn zukünftig iCloud Drive oder CloudKit genutzt werden soll,
müssen die Container-IDs hier eingetragen werden.

---

## ZUSAMMENFASSUNG SECURITY AUDIT

| Priorität | Anzahl | Top-Issues |
|-----------|--------|------------|
| 🔴 Kritisch | 2 | Privacy Manifest fehlt (App Store Ablehnung!), Force-Unwrap URLs |
| 🟠 Hoch | 3 | TTS ohne Privacy-Deklaration, Spielernamen in iCloud ohne Privacy Policy, UserDefaults unverschlüsselt |
| 🟡 Mittel | 4 | Audio Fehler-Handling, Room Code, iCloud Limit, Container IDs |
| ✅ Positiv | 5 | Keine API-Keys, MCP verschlüsselt, Entitlements minimal, NSLocalNetwork vorhanden, keine Credentials |

---

*Erstellt: 2026-04-12 — Teil von Phase 5 des Gesamtaudits*
