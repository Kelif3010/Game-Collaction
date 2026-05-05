import Foundation

struct FFPlayer: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    var name: String
    var score: Int
    var bluffScore: Int       // Punkte durch getäuschte Spieler
    var truthScore: Int       // Punkte durch erkannte Wahrheit
    var bluffSuccesses: Int   // Wie oft hat jemand meine Lüge gewählt
    var roundsPlayed: Int

    init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
        self.score = 0
        self.bluffScore = 0
        self.truthScore = 0
        self.bluffSuccesses = 0
        self.roundsPlayed = 0
    }

    var displayName: String { name.isEmpty ? "Spieler" : name }

    // 2 Punkte für Wahrheit erkannt, 1 Punkt pro getäuschten Spieler
    mutating func awardTruth() {
        truthScore += 2
        score += 2
    }

    mutating func awardBluff(count: Int) {
        let pts = count
        bluffScore += pts
        bluffSuccesses += count
        score += pts
    }

    mutating func incrementRound() {
        roundsPlayed += 1
    }
}
