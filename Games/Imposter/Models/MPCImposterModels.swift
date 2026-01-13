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
    let isTimerPaused: Bool
    let gamePhase: ImposterGamePhase
    let currentPlayerIndex: Int // Useful for card reveal phase
    let startingPlayerName: String?
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