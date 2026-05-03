import Foundation

struct GroupInfo: Identifiable, Hashable, Sendable {
    static let minPlayerCount = 2
    static let maxPlayerCount = 4

    let id: UUID
    let color: GroupColor
    var customName: String?
    var playerNames: [String?]
    var activePlayerIndex: Int
    var score: Int

    init(id: UUID = UUID(), color: GroupColor, customName: String? = nil,
         player1Name: String? = nil, player2Name: String? = nil,
         playerNames: [String?]? = nil,
         activePlayerIndex: Int = 0, score: Int = 0) {
        self.id = id
        self.color = color
        self.customName = customName
        self.playerNames = Self.normalizedPlayerNames(playerNames ?? [player1Name, player2Name])
        self.activePlayerIndex = activePlayerIndex
        self.score = score
    }

    var player1Name: String? {
        get { playerName(at: 0) }
        set { setPlayerName(newValue, at: 0) }
    }

    var player2Name: String? {
        get { playerName(at: 1) }
        set { setPlayerName(newValue, at: 1) }
    }

    var displayName: String {
        let trimmed = customName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? color.fallbackName : trimmed
    }

    var playerSlotCount: Int {
        max(Self.minPlayerCount, min(playerNames.count, Self.maxPlayerCount))
    }

    var displayPlayerNames: [String] {
        (0..<playerSlotCount).map { displayPlayerName(at: $0) }
    }

    var namedPlayersCount: Int {
        playerNames.filter { name in
            !(name?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        }.count
    }

    // Wer macht die Challenge diese Runde
    var activePlayerName: String {
        displayPlayerName(at: normalizedActivePlayerIndex)
    }

    // Wer bietet als naechstes fuer den aktiven Spieler
    var biddingPlayerName: String {
        displayPlayerName(at: (normalizedActivePlayerIndex + 1) % playerSlotCount)
    }

    // Haben mindestens zwei Spieler Namen eingegeben?
    var hasPlayerNames: Bool {
        namedPlayersCount >= Self.minPlayerCount
    }

    func playerName(at index: Int) -> String? {
        guard playerNames.indices.contains(index) else { return nil }
        return playerNames[index]
    }

    func displayPlayerName(at index: Int) -> String {
        let name = playerName(at: index)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return name.isEmpty ? "Spieler \(index + 1)" : name
    }

    mutating func setPlayerName(_ name: String?, at index: Int) {
        guard index >= 0, index < Self.maxPlayerCount else { return }
        while playerNames.count <= index {
            playerNames.append(nil)
        }
        let trimmed = name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        playerNames[index] = trimmed.isEmpty ? nil : trimmed
        playerNames = Self.normalizedPlayerNames(playerNames)
        activePlayerIndex = min(activePlayerIndex, playerSlotCount - 1)
    }

    private var normalizedActivePlayerIndex: Int {
        max(0, min(activePlayerIndex, playerSlotCount - 1))
    }

    private static func normalizedPlayerNames(_ names: [String?]) -> [String?] {
        var normalized = Array(names.prefix(maxPlayerCount)).map { name -> String? in
            let trimmed = name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return trimmed.isEmpty ? nil : trimmed
        }
        while normalized.count < minPlayerCount {
            normalized.append(nil)
        }
        return normalized
    }
}
