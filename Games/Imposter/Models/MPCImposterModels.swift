//
//  MPCImposterModels.swift
//  Games Collection
//
//  Created for MPC Integration
//

import Foundation

// MARK: - MPC Configuration Packet
struct ImposterGameConfig: Codable, Sendable {
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
struct ImposterRolePayload: Codable, Sendable {
    let role: RoleType
    let word: String
    let categoryName: String // Category to display
    let isImposter: Bool
    let assignmentId: UUID?
    // Add other necessary fields if needed
}

// MARK: - MPC Role Ack Packet
struct ImposterRoleAckPayload: Codable, Sendable {
    let assignmentId: UUID
    let playerName: String
}

// MARK: - MPC Rejoin Request Packet
struct ImposterRejoinRequestPayload: Codable, Sendable {
    let playerName: String
    let playerId: UUID
}

// MARK: - MPC Rejoin State Packet
struct ImposterRejoinStatePayload: Codable, Sendable {
    let playerName: String
    let playerHasSeenCard: Bool
    let role: ImposterRolePayload
    let gameState: ImposterGameStateSync
    let multiplayerStartAtHostUptime: TimeInterval?
    let revealProgress: ImposterRevealProgressPayload?
    let config: ImposterGameConfig
}

// MARK: - MPC Game State Sync Packet
struct ImposterGameStateSync: Codable, Sendable {
    let timeRemaining: Int
    let timeRemainingPrecise: TimeInterval
    let isTimerPaused: Bool
    let gamePhase: ImposterGamePhase
    let currentPlayerIndex: Int // Useful for card reveal phase
    let startingPlayerName: String?
    let hostUptime: TimeInterval
}

// MARK: - MPC Card Seen Packet
struct ImposterCardSeenPayload: Codable, Sendable {
    let playerName: String
}

// MARK: - MPC Reveal Progress Packet
struct ImposterRevealProgressPayload: Codable, Sendable {
    let readyCount: Int
    let totalCount: Int
}

// MARK: - MPC Host Activity Packet
struct ImposterHostActivityPayload: Codable, Sendable {
    let message: String
}

// MARK: - MPC Game Start Payload (Sync Start Time)
struct ImposterGameStartPayload: Codable, Sendable {
    let startingPlayerName: String?
    let startAtHostUptime: TimeInterval
    let countdownSeconds: Int
}

// MARK: - MPC Time Sync Payloads
struct ImposterTimeSyncPingPayload: Codable, Sendable {
    let clientName: String
    let pingId: UUID
    let clientSendUptime: TimeInterval
}

struct ImposterTimeSyncPongPayload: Codable, Sendable {
    let clientName: String
    let pingId: UUID
    let clientSendUptime: TimeInterval
    let hostReceiveUptime: TimeInterval
    let hostSendUptime: TimeInterval
}

// MARK: - MPC Voting Payloads

/// Client sends this to Host when they submit their vote
struct ImposterVoteCastPayload: Codable, Sendable {
    let voterName: String // Who voted?
    let votedFor: [String] // Who did they vote for? (List of names, usually 1)
}

/// Host sends this to Clients to update "3/5 voted"
struct ImposterVotingStatusPayload: Codable, Sendable {
    let votesReceived: Int
    let totalVoters: Int
    let tally: [String: Int]?
}

/// Host sends this to Clients when voting is done
struct ImposterVotingResultPayload: Codable, Equatable, Sendable {
    let selectedPlayers: [String] // Names selected for voting resolution
    let identifiedSpies: [String] // All eliminated spies so far
    let revealedSpies: [String]? // All spies (only when game ended)
    let gameEnded: Bool
    let playersWon: Bool
}

/// Client sends this while choosing, to update live tally
struct ImposterVotePreviewPayload: Codable, Sendable {
    let voterName: String
    let selectedName: String?
}

/// Host sends this to Clients when spies guess the word correctly
struct ImposterWordGuessResultPayload: Codable, Equatable, Sendable {
    let correctWord: String
}

/// Host sends this to Clients when asking for a rematch
struct ImposterRematchOfferPayload: Codable, Equatable, Sendable {
    let offerId: UUID
    let hostName: String
}

/// Clients send this back to Host with their decision
struct ImposterRematchResponsePayload: Codable, Equatable, Sendable {
    let offerId: UUID
    let playerName: String
    let wantsRematch: Bool
}
