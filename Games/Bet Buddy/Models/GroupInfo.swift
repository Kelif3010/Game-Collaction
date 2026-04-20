import Foundation

struct GroupInfo: Identifiable, Hashable {
    let id: UUID
    let color: GroupColor
    var customName: String?
    var player1Name: String?
    var player2Name: String?
    var activePlayerIndex: Int
    var score: Int

    init(id: UUID = UUID(), color: GroupColor, customName: String? = nil,
         player1Name: String? = nil, player2Name: String? = nil,
         activePlayerIndex: Int = 0, score: Int = 0) {
        self.id = id
        self.color = color
        self.customName = customName
        self.player1Name = player1Name
        self.player2Name = player2Name
        self.activePlayerIndex = activePlayerIndex
        self.score = score
    }

    var displayName: String {
        let trimmed = customName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? color.fallbackName : trimmed
    }

    // Wer macht die Challenge diese Runde
    var activePlayerName: String {
        let name = activePlayerIndex == 0 ? player1Name : player2Name
        let trimmed = name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? (activePlayerIndex == 0 ? "Spieler 1" : "Spieler 2") : trimmed
    }

    // Wer bietet für den aktiven Spieler
    var biddingPlayerName: String {
        let name = activePlayerIndex == 0 ? player2Name : player1Name
        let trimmed = name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? (activePlayerIndex == 0 ? "Spieler 2" : "Spieler 1") : trimmed
    }

    // Haben beide Spieler Namen eingegeben?
    var hasPlayerNames: Bool {
        let p1 = player1Name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let p2 = player2Name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return !p1.isEmpty && !p2.isEmpty
    }
}
