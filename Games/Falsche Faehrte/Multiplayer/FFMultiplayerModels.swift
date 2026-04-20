import Foundation

// MARK: - FF Multiplayer Payload-Modelle
// Alle Structs sind Codable für MPC-Übertragung

// Host → Alle: Spielkonfiguration + Fragenreihenfolge
struct FFGameConfigPayload: Codable {
    let questionIds: [String]       // Geordnete Fragen-IDs (Host bestimmt Reihenfolge)
    let playerNames: [String]       // Alle Lobby-Spieler in Reihenfolge
    let showCategoryHint: Bool
    let bluffTimerSeconds: Int
    let roundCount: Int
}

// Client → Host: Lüge einreichen
struct FFBluffSubmitPayload: Codable {
    let playerName: String          // Peer Display-Name
    let bluffText: String
    let questionId: String
}

// Anonyme Submission für Voting-Phase (ohne Autor-Info)
struct FFMPCSubmission: Codable, Identifiable {
    let id: String                  // UUID als String (entspricht FFSubmission.id)
    let text: String
    // isAnswer und playerName werden erst beim Reveal enthüllt
}

// Host → Alle: Alle Lügen + echte Antwort (anonym, gemischt)
struct FFBluffsReadyPayload: Codable {
    let submissions: [FFMPCSubmission]
    let questionId: String
}

// Host → Alle: Fortschritt der Lügen-Eingabe
struct FFBluffingStatusPayload: Codable {
    let submittedCount: Int
    let totalPlayers: Int
}

// Client → Host: Abstimmung
struct FFVoteCastPayload: Codable {
    let voterName: String
    let submissionId: String        // UUID als String
    let questionId: String
}

// Host → Alle: Fortschritt der Abstimmung
struct FFVotingStatusPayload: Codable {
    let votedCount: Int
    let totalPlayers: Int
}

// Aufgelöste Submission für Reveal-Phase
struct FFRevealSubmission: Codable, Identifiable {
    let id: String
    let text: String
    let authorName: String          // Jetzt sichtbar
    let isAnswer: Bool
    let voterNames: [String]
}

// Punktestand eines Spielers
struct FFMPCPlayerScore: Codable, Identifiable {
    var id: String { playerName }
    let playerName: String
    let totalScore: Int
    let truthsFound: Int
    let bluffsSuccessful: Int
}

// Host → Alle: Rundenauflösung
struct FFRevealPayload: Codable {
    let submissions: [FFRevealSubmission]
    let scores: [FFMPCPlayerScore]
    let correctSubmissionId: String
    let roundIndex: Int
}

// Host → Alle: Reveal wechselt synchron zum Punktestand
struct FFRevealScoresPayload: Codable {
    let roundIndex: Int
}

// Host → Alle: Nächste Runde starten
struct FFNextRoundPayload: Codable {
    let roundIndex: Int
}

// Host → Alle: Spiel beendet
struct FFGameOverPayload: Codable {
    let finalScores: [FFMPCPlayerScore]
    let mvpBluffer: String?
    let mvpDetective: String?
}
