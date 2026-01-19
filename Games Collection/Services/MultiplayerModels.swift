import Foundation

// MARK: - Globale Multiplayer Events
// Diese Strukturen können von ALLEN Spielen genutzt werden.

/// Event: Das Spiel startet (vom Host an alle)
struct MPCGameStartEvent: Codable {
    let gameId: String // z.B. "imposter", "timesup"
    let timestamp: Date
    // Optional: Generische Settings als JSON-Data, falls nötig
    let settingsData: Data? 
}

/// Event: Zuweisung einer Rolle/Information an einen spezifischen Spieler
struct MPCRoleAssignment: Codable {
    let playerId: String // PeerID DisplayName oder UUID
    let roleName: String // z.B. "Spion", "Bürger", "Erklärer"
    let secretInfo: String? // z.B. das Wort "Banane"
    let isSpy: Bool
}

/// Event: Status-Update während des Spiels (Timer, Phase)
struct MPCGameStateUpdate: Codable {
    let phase: String // "playing", "voting", "finished"
    let timeRemaining: Int?
    let activePlayerId: String? // Wer ist gerade dran?
}

/// Event: Spielende
struct MPCGameEndEvent: Codable {
    let reason: String // "timeout", "voting", "victory"
    let winners: [String] // Liste der Gewinner-Namen
}

// MARK: - Questions Specific Payloads

struct QuestionsRolePayload: Codable {
    let role: QuestionsRole
    let prompt: String
}
