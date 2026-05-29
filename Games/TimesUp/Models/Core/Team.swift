//
//  Team.swift
//  TimesUp
//
//  Created by Ken  on 23.09.25.
//

import Foundation

struct Team: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var score: Int = 0
    var roundScores: [Int] = [0, 0, 0, 0] // Punkte für Runde 1, 2, 3, 4
    var pendingRoundPenalties: [Int] = [0, 0, 0, 0]
    
    init(name: String) {
        self.name = name
    }
    
    mutating func addScore(_ points: Int, for round: Int) {
        guard round >= 0 && round < roundScores.count else { return }
        let newValue = roundScores[round] + points
        roundScores[round] = max(0, newValue)
        updateTotalScore()
    }
    
    mutating func applyPenalty(_ points: Int, for round: Int, revealAtEnd: Bool = false) {
        guard round >= 0 && round < roundScores.count else { return }
        if revealAtEnd {
            pendingRoundPenalties[round] += points
        } else {
            // Ziehe Punkte von der Rundensumme ab, aber nie unter 0
            roundScores[round] = max(0, roundScores[round] - points)
            updateTotalScore()
        }
    }
    
    mutating func resetScores() {
        score = 0
        roundScores = [0, 0, 0, 0]
        pendingRoundPenalties = [0, 0, 0, 0]
    }
    
    // Berechne Gesamtpunktzahl basierend auf Spielmodus
    mutating func updateTotalScore(for gameMode: TimesUpGameMode = .classic) {
        let relevantRounds = gameMode.totalRounds
        score = roundScores.prefix(relevantRounds).reduce(0, +)
    }
    
    // Hilfsmethode für kompatibilität
    private mutating func updateTotalScore() {
        score = roundScores.reduce(0, +)
    }
    
    mutating func revealPendingPenalties(for gameMode: TimesUpGameMode) {
        let relevantRounds = gameMode.totalRounds
        for round in 0..<min(relevantRounds, pendingRoundPenalties.count) {
            guard pendingRoundPenalties[round] > 0 else { continue }
            roundScores[round] = max(0, roundScores[round] - pendingRoundPenalties[round])
            pendingRoundPenalties[round] = 0
        }
        updateTotalScore(for: gameMode)
    }
    
    func pendingPenaltyTotal(for gameMode: TimesUpGameMode) -> Int {
        let relevantRounds = min(gameMode.totalRounds, pendingRoundPenalties.count)
        return pendingRoundPenalties.prefix(relevantRounds).reduce(0, +)
    }
}
