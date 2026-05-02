import SwiftUI

// MARK: - PartyGame

enum PartyGame: String, CaseIterable, Identifiable, Codable {
    case betBuddy       = "betBuddy"
    case timesUp        = "timesUp"
    case question       = "question"
    case imposter       = "imposter"
    case soundCinema    = "soundCinema"
    case falscheFaehrte = "falscheFaehrte"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .betBuddy:       return "Ich biete mehr!"
        case .timesUp:        return "Time's Up"
        case .question:       return "Finde den Lügner"
        case .imposter:       return "Imposter"
        case .soundCinema:    return "Geräusch-Kino"
        case .falscheFaehrte: return "Falsche Fährte"
        }
    }

    var icon: String {
        switch self {
        case .betBuddy:       return "dollarsign.circle.fill"
        case .timesUp:        return "hourglass.fill"
        case .question:       return "questionmark.bubble.fill"
        case .imposter:       return "person.fill.questionmark"
        case .soundCinema:    return "waveform.circle.fill"
        case .falscheFaehrte: return "magnifyingglass.circle.fill"
        }
    }

    var gradientColors: [Color] {
        switch self {
        case .betBuddy:
            return [Color(red: 0.85, green: 0.65, blue: 0.13), Color(red: 0.97, green: 0.82, blue: 0.32)]
        case .timesUp:
            return [Color.orange, Color.red]
        case .question:
            return [Color(red: 0.2, green: 0.55, blue: 1.0), Color(red: 0.45, green: 0.3, blue: 0.9)]
        case .imposter:
            return [Color(red: 0.75, green: 0.1, blue: 0.1), Color(red: 0.55, green: 0.05, blue: 0.05)]
        case .soundCinema:
            return [Color.cyan, Color.teal]
        case .falscheFaehrte:
            return [Color(red: 0.48, green: 0.36, blue: 0.94), Color(red: 0.62, green: 0.28, blue: 0.85)]
        }
    }

    var gradient: LinearGradient {
        LinearGradient(colors: gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    var minPlayers: Int {
        switch self {
        case .imposter:       return 4
        case .falscheFaehrte: return 3
        case .question:       return 3
        default:              return 2
        }
    }
}

// MARK: - PartyPlayer

struct PartyPlayer: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var name: String
    var totalScore: Int

    init(id: UUID = UUID(), name: String, totalScore: Int = 0) {
        self.id = id
        self.name = name
        self.totalScore = totalScore
    }

    var initial: String {
        String(name.prefix(1)).uppercased()
    }

    static let gradientPalette: [[Color]] = [
        [.blue, .cyan],
        [.purple, .indigo],
        [.orange, .pink],
        [.green, .teal],
        [.red, .orange],
        [.indigo, .blue],
        [.pink, .purple],
        [.teal, .green],
    ]

    var avatarGradient: LinearGradient {
        let idx = abs(name.hashValue) % Self.gradientPalette.count
        let colors = Self.gradientPalette[idx]
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

// MARK: - PartyGameResult

struct PartyGameResult: Identifiable, Codable {
    let id: UUID
    let game: PartyGame
    let winnerIDs: [UUID]
    let pointsEarned: [UUID: Int]

    init(game: PartyGame, winnerIDs: [UUID], allPlayerIDs: [UUID]) {
        self.id = UUID()
        self.game = game
        self.winnerIDs = winnerIDs
        var points: [UUID: Int] = [:]
        for pid in allPlayerIDs {
            points[pid] = winnerIDs.contains(pid) ? 3 : 1
        }
        self.pointsEarned = points
    }
}

// MARK: - PartySessionState

enum PartySessionState: Codable, Equatable {
    case playing
    case enteringResults
    case complete
}

// MARK: - PartySession

struct PartySession: Identifiable, Codable {
    let id: UUID
    var players: [PartyPlayer]
    var selectedGames: [PartyGame]
    var results: [PartyGameResult]
    var currentGameIndex: Int
    var state: PartySessionState

    init(players: [PartyPlayer], games: [PartyGame]) {
        self.id = UUID()
        self.players = players
        self.selectedGames = games
        self.results = []
        self.currentGameIndex = 0
        self.state = .playing
    }

    var currentGame: PartyGame? {
        guard currentGameIndex < selectedGames.count else { return nil }
        return selectedGames[currentGameIndex]
    }

    var isLastGame: Bool {
        currentGameIndex >= selectedGames.count - 1
    }

    var gamesPlayed: Int { results.count }
    var gamesTotal: Int  { selectedGames.count }

    var sortedPlayers: [PartyPlayer] {
        players.sorted { $0.totalScore > $1.totalScore }
    }
}
