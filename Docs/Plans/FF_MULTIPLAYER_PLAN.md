# Falsche Fährte – Multiplayer Implementierungsplan

> **Status:** Planung  
> **Ziel:** Jeder Spieler spielt auf seinem eigenen Gerät via MultipeerConnectivity (MPC)  
> **Basis:** Bestehende MPC-Infrastruktur aus dem Imposter-Spiel wiederverwenden

---

## Übersicht

### Wie es aktuell funktioniert (Single-Device)
```
Ein Gerät → Spieler geben Lügen reihum ein → Pass-the-Phone
```

### Wie es danach funktioniert (Multiplayer)
```
Jedes Gerät = ein Spieler → Alle tippen gleichzeitig → Viel weniger Wartezeit
```

---

## Neuer Gameflow (Multiplayer)

```
1. HOST erstellt Raum → bekommt 4-stelligen Code
2. ALLE SPIELER joinen mit Code auf eigenem Gerät
3. HOST startet Spiel (wählt Settings)
         ↓
[Pro Runde]
4. HOST sendet Frage an alle Geräte
5. BLUFF-PHASE: Jeder tippt PRIVAT seine Lüge auf eigenem Gerät
6. Wenn alle abgeschickt haben → HOST mischt alle Lügen + echte Antwort
7. HOST sendet gemischte Antwort-Liste an alle
8. VOTE-PHASE: Jeder wählt PRIVAT auf seinem Gerät
9. Alle Votes beim HOST → Punkte berechnen
10. REVEAL: Alle sehen gleichzeitig Ergebnis auf ihrem Gerät
11. Weiter zur nächsten Runde oder Game Over
```

---

## Was wiederverwendet wird (0 Aufwand)

| Datei | Wiederverwendung |
|---|---|
| `Services/MultipeerManager.swift` | Komplett – kein Umbau nötig |
| `Services/MPCEventTypes.swift` | Erweitern mit FF-Events |
| `Imposter/Views/Components/ImposterMultiplayerSheet.swift` | Als Vorlage für FF-Lobby |

---

## Neue Dateien die erstellt werden müssen

```
Games/Falsche Faehrte/
├── Multiplayer/
│   ├── FFMultiplayerSheet.swift       # Lobby UI (Join/Host)
│   ├── FFMultiplayerModels.swift      # Payload-Strukturen (Codable)
│   └── FFMultiplayerHandler.swift     # Event-Handler (Host & Client Logik)
```

---

## Neue MPC Events (in MPCEventTypes.swift ergänzen)

```swift
// Host → Alle
static let ffGameConfig     = "FF_GAME_CONFIG"      // Einstellungen sync
static let ffQuestion       = "FF_QUESTION"          // Neue Frage senden
static let ffBluffsReady    = "FF_BLUFFS_READY"      // Gemischte Antworten
static let ffReveal         = "FF_REVEAL"            // Ergebnis + Punkte
static let ffNextRound      = "FF_NEXT_ROUND"        // Nächste Runde starten
static let ffGameOver       = "FF_GAME_OVER"         // Spiel beendet

// Client → Host
static let ffBluffSubmit    = "FF_BLUFF_SUBMITTED"   // Private Lüge
static let ffVoteCast       = "FF_VOTE_CAST"         // Abstimmung
```

---

## Neue Payload-Modelle (FFMultiplayerModels.swift)

```swift
struct FFGameConfigPayload: Codable {
    let selectedPacks: [String]
    let roundCount: Int
    let showCategoryHint: Bool
}

struct FFQuestionPayload: Codable {
    let questionId: UUID
    let questionText: String        // Auf Gerät anzeigen
    let roundIndex: Int
    let category: String?
    // KEIN correctAnswer → bleibt beim Host bis Reveal
}

struct FFBluffSubmitPayload: Codable {
    let playerId: String            // Peer Display-Name
    let bluffText: String           // Die Lüge des Spielers
    let questionId: UUID
}

struct FFBluffsReadyPayload: Codable {
    let submissions: [FFMPCSubmission]  // Gemischt, ohne Zuweisung
}

struct FFMPCSubmission: Codable, Identifiable {
    let id: UUID
    let text: String
    let isAnswer: Bool              // Nur Host kennt das, Clients sehen es erst bei Reveal
    // playerId NICHT mitsenden → noch geheim
}

struct FFVoteCastPayload: Codable {
    let voterId: String
    let submissionId: UUID
    let questionId: UUID
}

struct FFRevealPayload: Codable {
    let submissions: [FFRevealSubmission]   // Jetzt mit Zuweisungen
    let scores: [FFPlayerScore]
    let correctSubmissionId: UUID
}

struct FFRevealSubmission: Codable, Identifiable {
    let id: UUID
    let text: String
    let authorName: String          // Jetzt sichtbar
    let isAnswer: Bool
    let voterNames: [String]
}

struct FFPlayerScore: Codable {
    let playerName: String
    let roundPoints: Int
    let totalScore: Int
    let truthsFound: Int
    let bluffsSuccessful: Int
}

struct FFGameOverPayload: Codable {
    let finalScores: [FFPlayerScore]
    let mvpBluffer: String          // Bester Lügner
    let mvpDetective: String        // Bester Detektiv
}
```

---

## FFViewModel – Umbau-Strategie

Das bestehende `FFViewModel.swift` wird **erweitert**, nicht ersetzt.

### Neue Properties hinzufügen

```swift
// Multiplayer-State
@Published var isMultiplayer: Bool = false
@Published var isHost: Bool = false
@Published var waitingForBluffs: Set<String> = []   // Wer hat noch nicht abgeschickt?
@Published var waitingForVotes: Set<String> = []    // Wer hat noch nicht gevoted?
@Published var hasSubmittedBluff: Bool = false       // Eigene Lüge abgeschickt?
@Published var hasVoted: Bool = false                // Eigene Stimme abgeschickt?
```

### Neue Methoden hinzufügen

```swift
// HOST-Logik
func hostSendQuestion()                 // Aktuelle Frage an alle senden
func hostCollectBluff(_ payload: FFBluffSubmitPayload)  // Lüge empfangen
func hostFinalizeBluffPhase()          // Wenn alle abgeschickt haben
func hostCollectVote(_ payload: FFVoteCastPayload)      // Vote empfangen
func hostFinalizeVotePhase()           // Wenn alle gevoted haben → Reveal

// CLIENT-Logik
func clientReceiveQuestion(_ payload: FFQuestionPayload)
func clientSubmitBluff(_ text: String)  // Sendet an Host
func clientReceiveBluffs(_ payload: FFBluffsReadyPayload)
func clientCastVote(_ submissionId: UUID)
func clientReceiveReveal(_ payload: FFRevealPayload)
```

---

## Views – Was sich ändert

### FFSetupView.swift
- Multiplayer-Button hinzufügen (öffnet `FFMultiplayerSheet`)
- Bei Multiplayer: Spieler-Liste kommt aus Lobby, nicht manuell eingeben

### FFBluffPhaseView.swift
- **Multiplayer-Modus**: Kein "Gerät weitergeben"-Screen mehr
- Jeder Spieler sieht **seinen eigenen** Input auf seinem Gerät
- Status-Anzeige: "3 von 5 Spielern haben abgeschickt"
- Nach Submit: Warteschirm mit Fortschritt

### FFVotePhaseView.swift
- **Multiplayer-Modus**: Kein Pass-the-Phone
- Jeder sieht sofort die Antwort-Liste auf eigenem Gerät
- Status: "Warte auf 2 weitere Spieler..."

### FFRevealPhaseView.swift
- Identisch mit Single-Player-Version – keine Änderung nötig
- Daten kommen einfach vom Host statt lokal

### FFGameOverView.swift
- Identisch – keine Änderung nötig

---

## Implementierungs-Reihenfolge (Schritt für Schritt)

### Phase 1 – Fundament (Tag 1)
- [ ] `FFMultiplayerModels.swift` erstellen (alle Payload-Structs)
- [ ] `MPCEventTypes.swift` um FF-Events ergänzen
- [ ] `FFMultiplayerSheet.swift` aus ImposterMultiplayerSheet kopieren & anpassen

### Phase 2 – Host-Logik (Tag 2–3)
- [ ] `FFViewModel` um Multiplayer-Properties erweitern
- [ ] Host-Methoden implementieren (Frage senden, Bluffs sammeln, Votes auswerten)
- [ ] `FFMultiplayerHandler.swift` für Event-Routing erstellen

### Phase 3 – Views anpassen (Tag 4)
- [ ] `FFSetupView` – Multiplayer-Einstieg hinzufügen
- [ ] `FFBluffPhaseView` – Multiplayer-Branch (eigene Eingabe + Warteschirm)
- [ ] `FFVotePhaseView` – Multiplayer-Branch (direkt voten + Warteschirm)

### Phase 4 – Testen & Feinschliff (Tag 5–7)
- [ ] Tests mit 2 physischen Geräten
- [ ] Disconnect-Handling (Was passiert wenn jemand das Spiel verlässt?)
- [ ] Edge Cases: Alle tippen gleiche Lüge, Spieler verlässt während Bluff-Phase
- [ ] UI-Polishing (Lade-Animationen, Fortschritts-Indikatoren)

---

## Offene Fragen / Entscheidungen

- [ ] **Min. Spieleranzahl Multiplayer?** → Empfehlung: mind. 3 Geräte
- [ ] **Was passiert bei Disconnect?** → Spieler wird übersprungen oder Spiel pausiert?
- [ ] **Kann man Multiplayer + Single-Device mischen?** → Eher nein (zu komplex)
- [ ] **Host-Migration?** → Falls Host disconnectet, bricht das Spiel ab?

---

## Zeitschätzung

| Phase | Aufwand |
|---|---|
| Phase 1 – Fundament | 0.5 Tage |
| Phase 2 – Host-Logik | 2–3 Tage |
| Phase 3 – Views | 1 Tag |
| Phase 4 – Testen | 1–2 Tage |
| **Gesamt** | **~5–7 Tage** |

---

*Erstellt: 2026-04-13*
