//
//  Player.swift
//  Imposter
//
//  Created by Ken on 22.09.25.
//

import Foundation

struct Player: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var isImposter: Bool
    var word: String
    var hasSeenCard: Bool
    /// Marks a player as eliminated from the current game (e.g., correctly voted imposter)
    var isEliminated: Bool
    /// Role assigned to the player (used in roles game mode)
    var role: String?
    /// Special role type for the Werewolf mode
    var roleType: RoleType?
    /// If true, this player is protected by the Bodyguard
    var isProtected: Bool
    
    init(name: String) {
        self.id = UUID()
        self.name = name
        self.isImposter = false
        self.word = ""
        self.hasSeenCard = false
        self.isEliminated = false
        self.role = nil
        self.roleType = nil
        self.isProtected = false
    }
    
}
