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
    private let iCloudStore = NSUbiquitousKeyValueStore.default
    
    private init() {
        loadPlayers()

        // iCloud Sync Setup
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(iCloudDataDidUpdate),
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: iCloudStore
        )
        iCloudStore.synchronize()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
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
            }
        }
        if changed {
            savePlayers()
        }
    }
    
    func getAllNames() -> [String] {
        return players
            .sorted { ($0.lastPlayed ?? .distantPast) > ($1.lastPlayed ?? .distantPast) }
            .map { $0.name }
    }
    
    // MARK: - Persistence & Sync
    
    private func savePlayers() {
        // 1. Save Local
        if let data = try? JSONEncoder().encode(players) {
            UserDefaults.standard.set(data, forKey: storageKey)

            // 2. Save to iCloud (nur wenn unter 900KB Limit)
            if data.count < 900_000 {
                iCloudStore.set(data, forKey: storageKey)
                iCloudStore.synchronize()
            }
        }
    }
    
    private func loadPlayers() {
        // 1. Try iCloud first (it's the master)
        if let data = iCloudStore.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([GlobalPlayer].self, from: data) {
            self.players = decoded
            // Sync back to local to keep them in sync
            UserDefaults.standard.set(data, forKey: storageKey)
        } 
        // 2. Fallback to Local
        else if let data = UserDefaults.standard.data(forKey: storageKey),
                let decoded = try? JSONDecoder().decode([GlobalPlayer].self, from: data) {
            self.players = decoded
        }
    }
    
    @objc private func iCloudDataDidUpdate(notification: NSNotification) {
        // Called when data changes on another device
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            guard let data = self.iCloudStore.data(forKey: self.storageKey),
                  let cloudPlayers = try? JSONDecoder().decode([GlobalPlayer].self, from: data)
            else { return }

            // UUID-basiertes Merge: Vereinigt lokale + Cloud-Spieler (DA-02 / SVC-02 Fix)
            // Cloud-Version gewinnt bei Konflikten (neuere Geräte-Änderungen)
            var merged = Dictionary(uniqueKeysWithValues: self.players.map { ($0.id, $0) })
            for cloudPlayer in cloudPlayers {
                merged[cloudPlayer.id] = cloudPlayer
            }
            self.players = Array(merged.values).sorted { $0.name < $1.name }

            // Gemergten Stand lokal sichern
            if let mergedData = try? JSONEncoder().encode(self.players) {
                UserDefaults.standard.set(mergedData, forKey: self.storageKey)
            }
        }
    }
    
    // MARK: - Helpers
    
    private func randomColorHex() -> String {
        let colors = ["#FF3B30", "#007AFF", "#34C759", "#FFCC00", "#AF52DE", "#FF9500", "#FF2D55", "#30B0C7"]
        return colors.randomElement() ?? "#007AFF"
    }
}
