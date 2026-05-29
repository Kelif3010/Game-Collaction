//
//  Term.swift
//  TimesUp
//
//  Created by Ken  on 23.09.25.
//

import Foundation

struct Term: Identifiable, Codable, Equatable {
    var id = UUID()
    var text: String
    var englishTranslation: String?
    var isCompleted: Bool = false
    var completedInRounds: [Bool] = [false, false, false, false] // Runde 1, 2, 3, 4
    var assignedTeamId: UUID? = nil
    var availableFromTeamTurn: Int = 0
    
    init(text: String, englishTranslation: String? = nil) {
        self.text = text
        self.englishTranslation = englishTranslation
    }
    
    mutating func markCompleted(in round: Int, for gameMode: TimesUpGameMode = .classic) {
        guard round >= 0 && round < completedInRounds.count else { return }
        completedInRounds[round] = true
        updateIsCompleted(for: gameMode)
    }
    
    mutating func reset() {
        isCompleted = false
        completedInRounds = [false, false, false, false]
        assignedTeamId = nil
        availableFromTeamTurn = 0
    }
    
    // Überprüfe ob Term für einen bestimmten Modus vollständig abgeschlossen ist
    mutating func updateIsCompleted(for gameMode: TimesUpGameMode = .classic) {
        let requiredRounds = gameMode.totalRounds
        isCompleted = completedInRounds.prefix(requiredRounds).allSatisfy { $0 }
    }
    
    private mutating func updateIsCompleted() {
        // Standard: alle 4 Runden müssen komplett sein (für Rückwärtskompatibilität)
        isCompleted = completedInRounds.allSatisfy { $0 }
    }
}
