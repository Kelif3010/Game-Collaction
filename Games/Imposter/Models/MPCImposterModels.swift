//
//  MPCImposterModels.swift
//  Games Collection
//
//  Created for MPC Integration
//

import Foundation

// MARK: - MPC Configuration Packet
struct ImposterGameConfig: Codable {
    let numberOfImposters: Int
    let timeLimit: Int
    let gameMode: ImposterGameMode
    let spyCanSeeCategory: Bool
    let spiesCanSeeEachOther: Bool
    let randomSpyCount: Bool
    let showSpyHints: Bool
    let activeRoles: Set<RoleType>
    let selectedCategoryIds: Set<UUID>
    let isMixAllCategories: Bool
}

// MARK: - MPC Role Assignment Packet
struct ImposterRolePayload: Codable {
    let role: RoleType
    let word: String
    let categoryName: String // Category to display
    let isImposter: Bool
    // Add other necessary fields if needed
}

// MARK: - MPC Game State Sync Packet
struct ImposterGameStateSync: Codable {
    let timeRemaining: Int
    let timeRemainingPrecise: TimeInterval
    let isTimerPaused: Bool
    let gamePhase: ImposterGamePhase
    let currentPlayerIndex: Int // Useful for card reveal phase
    let startingPlayerName: String?
    let hostUptime: TimeInterval
}

// MARK: - MPC Card Seen Packet
struct ImposterCardSeenPayload: Codable {
    let playerName: String
}

// MARK: - MPC Reveal Progress Packet
struct ImposterRevealProgressPayload: Codable {
    let readyCount: Int
    let totalCount: Int
}

// MARK: - MPC Host Activity Packet
struct ImposterHostActivityPayload: Codable {
    let message: String
}

// MARK: - MPC Game Start Payload (Sync Start Time)
struct ImposterGameStartPayload: Codable {
    let startingPlayerName: String?
    let startAtHostUptime: TimeInterval
    let countdownSeconds: Int
}

// MARK: - MPC Time Sync Payloads
struct ImposterTimeSyncPingPayload: Codable {
    let clientName: String
    let pingId: UUID
    let clientSendUptime: TimeInterval
}

struct ImposterTimeSyncPongPayload: Codable {
    let clientName: String
    let pingId: UUID
    let clientSendUptime: TimeInterval
    let hostReceiveUptime: TimeInterval
    let hostSendUptime: TimeInterval
}

// MARK: - MPC Voting Payloads

/// Client sends this to Host when they submit their vote
struct ImposterVoteCastPayload: Codable {
    let voterName: String // Who voted?
    let votedFor: [String] // Who did they vote for? (List of names, usually 1)
}

/// Host sends this to Clients to update "3/5 voted"
struct ImposterVotingStatusPayload: Codable {
    let votesReceived: Int
    let totalVoters: Int
    let tally: [String: Int]?
}

/// Host sends this to Clients when voting is done
struct ImposterVotingResultPayload: Codable, Equatable {
    let selectedPlayers: [String] // Names selected for voting resolution
    let identifiedSpies: [String] // All eliminated spies so far
    let revealedSpies: [String]? // All spies (only when game ended)
    let gameEnded: Bool
    let playersWon: Bool
}

/// Client sends this while choosing, to update live tally
struct ImposterVotePreviewPayload: Codable {
    let voterName: String
    let selectedName: String?
}

/// Host sends this to Clients when spies guess the word correctly
struct ImposterWordGuessResultPayload: Codable, Equatable {
    let correctWord: String
}
