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
    
    init(player: Player, category: Category) {
        self.player = player
        self.category = category
        self.word = player.word
        self.isImposter = player.isImposter
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
    
    /// Gibt die Farbe für die Karte zurück
    var cardColor: String {
        return isImposter ? "red" : "blue"
    }
    
    /// Gibt das Icon für die Karte zurück
    var cardIcon: String {
        return isImposter ? "eye.slash.fill" : "eye.fill"
    }
}
