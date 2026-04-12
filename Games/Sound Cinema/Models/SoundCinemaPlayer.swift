import Foundation

// MARK: - Spieler-Model
struct SoundCinemaPlayer: Identifiable, Equatable {
    let id: UUID
    var name: String
    var livesRemaining: Int
    var score: Int              // Erfolgreich erratene Geräusche
    var isEliminated: Bool

    init(name: String, lives: Int) {
        self.id = UUID()
        self.name = name
        self.livesRemaining = lives
        self.score = 0
        self.isEliminated = false
    }

    mutating func loseLife() {
        guard livesRemaining > 0 else { return }
        livesRemaining -= 1
        if livesRemaining == 0 {
            isEliminated = true
        }
    }

    mutating func gainPoint() {
        score += 1
    }
}
