import Foundation

// MARK: - Eingereichte Antwort eines Spielers
struct FFSubmission: Identifiable, Equatable {
    let id: UUID
    let playerId: UUID
    let playerName: String
    var text: String
    var isAnswer: Bool   // true = die echte Antwort
    var voterIds: [UUID] // Spieler, die diese Antwort gewählt haben

    init(playerId: UUID, playerName: String, text: String, isAnswer: Bool = false) {
        self.id = UUID()
        self.playerId = playerId
        self.playerName = playerName
        self.text = text
        self.isAnswer = isAnswer
        self.voterIds = []
    }

    var bluffSuccessCount: Int { voterIds.count }
}

// MARK: - Eine Spielrunde
struct FFRound: Identifiable {
    let id: UUID
    let roundNumber: Int
    let question: FFQuestion
    var submissions: [FFSubmission]  // Lügen der Spieler + echte Antwort
    var displayOrder: [UUID]         // Zufällige Anzeigereihenfolge der submission IDs
    var votes: [UUID: UUID]          // playerId → submissionId
    var phase: FFRoundPhase
    var currentInputPlayerIndex: Int  // Für Single-Device-Modus

    init(number: Int, question: FFQuestion) {
        self.id = UUID()
        self.roundNumber = number
        self.question = question
        self.submissions = []
        self.displayOrder = []
        self.votes = [:]
        self.phase = .bluffing
        self.currentInputPlayerIndex = 0
    }

    // Einreich-Reihenfolge zufällig mischen (echter Antwort drin)
    mutating func shuffleDisplayOrder() {
        displayOrder = submissions.map { $0.id }.shuffled()
    }

    var answeredSubmission: FFSubmission? {
        submissions.first { $0.isAnswer }
    }

    func submission(for id: UUID) -> FFSubmission? {
        submissions.first { $0.id == id }
    }
}

// MARK: - Rundenphase
enum FFRoundPhase: Equatable {
    case bluffing       // Spieler tippen ihre Lügen ein
    case voting         // Alle stimmen ab
    case reveal         // Auflösung + Punkte-Vergabe
    case finished       // Runde abgeschlossen
}
