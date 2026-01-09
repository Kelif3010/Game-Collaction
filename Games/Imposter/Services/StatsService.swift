//
//  StatsService.swift
//  Imposter
//
//  Created by Ken on 25.09.25.
//

import Foundation
import Combine

// MARK: - Models

struct PlayerStats: Codable, Hashable, Identifiable {
    var id: String { playerName }
    let playerName: String
    
    var totalGames: Int = 0
    var imposterGames: Int = 0
    var citizenGames: Int = 0
    
    var imposterWins: Int = 0
    var citizenWins: Int = 0
    
    var totalPoints: Int = 0
    
    // Spezifische Erfolge
    var wordsGuessedCorrectly: Int = 0
    var fastWinsAsImposter: Int = 0
    var fastWinsAsCitizen: Int = 0
    var votingErrorsProvoked: Int = 0
    
    var winRateAsImposter: Double {
        guard imposterGames > 0 else { return 0 }
        return Double(imposterWins) / Double(imposterGames)
    }
    
    var winRateAsCitizen: Double {
        guard citizenGames > 0 else { return 0 }
        return Double(citizenWins) / Double(citizenGames)
    }
}

// MARK: - Point System Configuration
enum GamePoints {
    // Spion Erfolge
    static let spyWinWordGuess = 15      // Risiko-Bonus (10 Basis + 5 Risiko)
    static let spyWinWordGuessFast = 5   // Zusätzlicher Bonus für Schnelligkeit
    static let spyWinByVotingError = 10  // Der "Sudden Death" Sieg (Kernziel)
    static let spyWinTimeOut = 10        // Erfolgreich ausgesessen
    
    // Bürger Erfolge
    static let citizenWin = 10           // Da ein Fehler das Aus bedeutet -> Hohe Belohnung
    static let citizenWinFast = 5        // Zusätzlicher Bonus
}

// MARK: - Service
@MainActor
class StatsService: ObservableObject {
    static let shared = StatsService()
    
    @Published private(set) var stats: [String: PlayerStats] = [:]
    
    private let defaults = UserDefaults.standard
    private let key = "imposter_game_stats_v1"
    
    private init() {
        loadStats()
    }
    
    // MARK: - Public API
    
    func getStats(for playerName: String) -> PlayerStats {
        let normalized = playerName.trimmingCharacters(in: .whitespacesAndNewlines)
        return stats[normalized] ?? PlayerStats(playerName: normalized)
    }
    
    func getAllStats() -> [PlayerStats] {
        Array(stats.values)
    }
    
    /// Spion gewinnt durch Wortraten
    func recordSpyWinWordGuess(spyName: String, isFast: Bool) {
        var stat = getStats(for: spyName)
        stat.totalGames += 1
        stat.imposterGames += 1
        stat.imposterWins += 1
        stat.wordsGuessedCorrectly += 1
        
        var points = GamePoints.spyWinWordGuess
        if isFast {
            points += GamePoints.spyWinWordGuessFast
            stat.fastWinsAsImposter += 1
        }
        stat.totalPoints += points
        
        save(stat: stat)
    }
    
    /// Spion gewinnt durch Zeitablauf
    func recordSpyWinTimeOut(spyName: String) {
        var stat = getStats(for: spyName)
        stat.totalGames += 1
        stat.imposterGames += 1
        stat.imposterWins += 1
        stat.totalPoints += GamePoints.spyWinTimeOut
        
        save(stat: stat)
    }
    
    /// Spion gewinnt durch falsches Voting der Bürger (Sudden Death)
    func recordSpyWinByWrongVoting(spyNames: [String]) {
        for name in spyNames {
            var stat = getStats(for: name)
            stat.totalGames += 1
            stat.imposterGames += 1
            stat.imposterWins += 1
            stat.totalPoints += GamePoints.spyWinByVotingError
            stat.votingErrorsProvoked += 1
            save(stat: stat)
        }
    }
    
    /// Bürger gewinnen
    func recordCitizenWin(citizenNames: [String], isFast: Bool) {
        var points = GamePoints.citizenWin
        if isFast { points += GamePoints.citizenWinFast }
        
        for name in citizenNames {
            var stat = getStats(for: name)
            stat.totalGames += 1
            stat.citizenGames += 1
            stat.citizenWins += 1
            stat.totalPoints += points
            
            if isFast { stat.fastWinsAsCitizen += 1 }
            
            save(stat: stat)
        }
    }
    
    /// Registriert einfach nur Teilnahme und Niederlage (für die Verliererseite)
    func recordLoss(playerNames: [String], asImposter: Bool) {
        for name in playerNames {
            var stat = getStats(for: name)
            stat.totalGames += 1
            if asImposter {
                stat.imposterGames += 1
            } else {
                stat.citizenGames += 1
            }
            save(stat: stat)
        }
    }
    
    // MARK: - Persistence
    
    private func save(stat: PlayerStats) {
        stats[stat.playerName] = stat
        persist()
    }
    
    private func persist() {
        do {
            let data = try JSONEncoder().encode(stats)
            defaults.set(data, forKey: key)
        } catch {
            print("Failed to save stats: \(error)")
        }
    }
    
    private func loadStats() {
        guard let data = defaults.data(forKey: key) else { return }
        do {
            stats = try JSONDecoder().decode([String: PlayerStats].self, from: data)
        } catch {
            print("Failed to load stats: \(error)")
        }
    }
    
    /// Setzt alle Statistiken zurück
    func resetAllStats() {
        stats = [:]
        defaults.removeObject(forKey: key)
    }
}
