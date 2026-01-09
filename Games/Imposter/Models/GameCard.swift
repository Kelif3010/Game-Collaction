//
//  GameCard.swift
//  Imposter
//
//  Created by Ken on 22.09.25.
//

import Foundation

struct GameCard: Identifiable {
    let id = UUID()
    let player: Player
    let category: Category
    let word: String
    let isImposter: Bool
    let roleType: RoleType?
    
    init(player: Player, category: Category) {
        self.player = player
        self.category = category
        self.word = player.word
        self.isImposter = player.isImposter
        self.roleType = player.roleType
    }
    
    /// Gibt den anzuzeigenden Text für die Karte zurück
    var displayWord: String {
        if isImposter {
            return word // word enthält bereits "SPION" oder "SPION\n(Kategorie: ...)"
        } else {
            // Im Rollen-Modus: Zeige Ort und Rolle
            if let role = player.role, !role.isEmpty {
                return "\(word)\n\nRolle: \(role)"
            }
            return word
        }
    }
    
    /// Returns the short instruction for the role
    var shortInstruction: String {
        if let roleType = roleType {
            return roleType.shortInstruction
        }
        return isImposter ? "Bleib undercover und finde das Wort." : "Beschreibe dein Wort vorsichtig."
    }
    
    /// Gibt die Farbe für die Karte zurück
    var cardColorName: String {
        if let roleType = roleType {
            return roleType.cardColorName
        }
        return isImposter ? "darkRed" : "darkBlue"
    }
    
    /// Gibt das Icon für die Karte zurück
    var cardIcon: String {
        if let roleType = roleType {
            return roleType.cardIcon
        }
        return isImposter ? "eye.slash.fill" : "eye.fill"
    }
    
    var cardTitle: String {
        if let roleType = roleType {
            return roleType.cardTitle
        }
        return isImposter ? "DU BIST SPION" : "BÜRGER"
    }
}
