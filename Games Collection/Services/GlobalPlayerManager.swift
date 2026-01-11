import Foundation
import SwiftUI
import Combine

struct GlobalPlayer: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var avatarColorHex: String // Für später: Personalisierte Farbe
    var lastPlayed: Date?      // Für Sortierung "Häufig gespielt"
}

@MainActor
final class GlobalPlayerManager: ObservableObject {
    static let shared = GlobalPlayerManager()
    
    @Published private(set) var players: [GlobalPlayer] = []
    
    private let storageKey = "GlobalPlayers_V1"
    
    private init() {
        loadPlayers()
    }
    
    // MARK: - Actions
    
    func addPlayer(name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard !players.contains(where: { $0.name.lowercased() == trimmed.lowercased() }) else { return }
        
        let newPlayer = GlobalPlayer(
            name: trimmed,
            avatarColorHex: randomColorHex(),
            lastPlayed: Date()
        )
        players.append(newPlayer)
        savePlayers()
    }
    
    func removePlayer(id: UUID) {
        players.removeAll { $0.id == id }
        savePlayers()
    }
    
    func updateLastPlayed(for names: [String]) {
        var changed = false
        for name in names {
            if let index = players.firstIndex(where: { $0.name.lowercased() == name.lowercased() }) {
                players[index].lastPlayed = Date()
                changed = true
            } else {
                // Auto-Add new names? Optional. Let's do it for convenience.
                // addPlayer(name: name) 
                // Nein, lieber explizit hinzufügen lassen, sonst müllt die Liste zu.
            }
        }
        if changed {
            savePlayers()
        }
    }
    
    func getAllNames() -> [String] {
        // Sortiert: Zuletzt gespielt zuerst
        return players
            .sorted { ($0.lastPlayed ?? .distantPast) > ($1.lastPlayed ?? .distantPast) }
            .map { $0.name }
    }
    
    // MARK: - Persistence
    
    private func savePlayers() {
        if let data = try? JSONEncoder().encode(players) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
    
    private func loadPlayers() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([GlobalPlayer].self, from: data) else {
            return
        }
        self.players = decoded
    }
    
    // MARK: - Helpers
    
    private func randomColorHex() -> String {
        let colors = ["#FF3B30", "#007AFF", "#34C759", "#FFCC00", "#AF52DE", "#FF9500", "#FF2D55", "#30B0C7"]
        return colors.randomElement() ?? "#007AFF"
    }
}
