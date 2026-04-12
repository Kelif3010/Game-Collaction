import Foundation
import SwiftUI
import Combine

struct GlobalPlayerStats: Codable, Identifiable {
    var id: String { name }
    let name: String
    var wins: Int = 0
    var losses: Int = 0
    var timesPlayed: Int = 0
    
    var winRate: Double {
        return timesPlayed > 0 ? Double(wins) / Double(timesPlayed) : 0.0
    }
}

@MainActor
final class GlobalStatsManager: ObservableObject {
    static let shared = GlobalStatsManager()
    
    @Published private(set) var stats: [String: GlobalPlayerStats] = [:]
    @Published private(set) var sessionWins: [String: Int] = [:]
    @Published private(set) var playedGameIDs: Set<String> = []
    
    private let storageKey = "GlobalStats_V1"
    
    private init() {
        loadStats()
    }
    
    // MARK: - Session Context
    func markGameAsPlayed(_ gameId: String) {
        if !playedGameIDs.contains(gameId) {
            playedGameIDs.insert(gameId)
        }
    }
    
    // MARK: - Recording Actions
    
    func recordWin(for playerName: String) {
        let trimmed = playerName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            sessionWins[trimmed, default: 0] += 1
        }

        updateStat(for: playerName) { stats in
            stats.wins += 1
            // timesPlayed wird nur in recordParticipation gezählt
        }
    }

    func recordLoss(for playerName: String) {
        updateStat(for: playerName) { stats in
            stats.losses += 1
            // timesPlayed wird nur in recordParticipation gezählt
        }
    }
    
    func recordParticipation(for playerName: String) {
        updateStat(for: playerName) { stats in
            stats.timesPlayed += 1
        }
    }
    
    // MARK: - Analysis
    
    var mvp: GlobalPlayerStats? {
        stats.values.max(by: { $0.wins < $1.wins })
    }
    
    var unluckyPlayer: GlobalPlayerStats? {
        stats.values.max(by: { $0.losses < $1.losses })
    }
    
    /// Der aktuelle Spitzenreiter der Sitzung
    var sessionKing: (name: String, wins: Int)? {
        guard let maxEntry = sessionWins.max(by: { $0.value < $1.value }), maxEntry.value > 0 else {
            return nil
        }
        return (name: maxEntry.key, wins: maxEntry.value)
    }
    
    // MARK: - Internal Helper
    
    private func updateStat(for name: String, mutation: (inout GlobalPlayerStats) -> Void) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        var current = stats[trimmed] ?? GlobalPlayerStats(name: trimmed)
        mutation(&current)
        stats[trimmed] = current
        saveStats()
    }
    
    // MARK: - Persistence
    
    private func saveStats() {
        if let data = try? JSONEncoder().encode(stats) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
    
    private func loadStats() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([String: GlobalPlayerStats].self, from: data) {
            self.stats = decoded
        }
    }
    
    func resetAllStats() {
        stats = [:]
        UserDefaults.standard.removeObject(forKey: storageKey)
    }
}
