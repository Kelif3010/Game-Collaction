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
    /// Marks a player as eliminated from the current game (e.g., correctly voted spy)
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
    
    private enum CodingKeys: String, CodingKey {
        case id, name, isImposter, word, hasSeenCard, isEliminated, role, roleType, isProtected
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.name = try container.decode(String.self, forKey: .name)
        self.isImposter = try container.decodeIfPresent(Bool.self, forKey: .isImposter) ?? false
        self.word = try container.decodeIfPresent(String.self, forKey: .word) ?? ""
        self.hasSeenCard = try container.decodeIfPresent(Bool.self, forKey: .hasSeenCard) ?? false
        self.isEliminated = try container.decodeIfPresent(Bool.self, forKey: .isEliminated) ?? false
        self.role = try container.decodeIfPresent(String.self, forKey: .role)
        self.roleType = try container.decodeIfPresent(RoleType.self, forKey: .roleType)
        self.isProtected = try container.decodeIfPresent(Bool.self, forKey: .isProtected) ?? false
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(isImposter, forKey: .isImposter)
        try container.encode(word, forKey: .word)
        try container.encode(hasSeenCard, forKey: .hasSeenCard)
        try container.encode(isEliminated, forKey: .isEliminated)
        try container.encodeIfPresent(role, forKey: .role)
        try container.encodeIfPresent(roleType, forKey: .roleType)
        try container.encode(isProtected, forKey: .isProtected)
    }
}
