import Foundation
import Observation

struct GlobalPlayer: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var avatarColorHex: String
    var lastPlayed: Date?
}

@MainActor
@Observable
final class GlobalPlayerManager {
    static let shared = GlobalPlayerManager()

    private(set) var players: [GlobalPlayer] = []

    private let storageKey = "GlobalPlayers_V1"
    private let iCloudStore = NSUbiquitousKeyValueStore.default
    private init() {
        loadPlayers()

        // Singleton lebt für die gesamte App-Laufzeit – kein Cleanup nötig
        NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: iCloudStore,
            queue: .main
        ) { [weak self] _ in
            self?.iCloudDataDidUpdate()
        }
        iCloudStore.synchronize()
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
        if changed { savePlayers() }
    }

    func getAllNames() -> [String] {
        players
            .sorted { ($0.lastPlayed ?? .distantPast) > ($1.lastPlayed ?? .distantPast) }
            .map { $0.name }
    }

    // MARK: - Persistence & Sync

    private func savePlayers() {
        guard let data = try? JSONEncoder().encode(players) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
        if data.count < 900_000 {
            iCloudStore.set(data, forKey: storageKey)
            iCloudStore.synchronize()
        }
    }

    private func loadPlayers() {
        if let data = iCloudStore.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([GlobalPlayer].self, from: data) {
            players = decoded
            UserDefaults.standard.set(data, forKey: storageKey)
        } else if let data = UserDefaults.standard.data(forKey: storageKey),
                  let decoded = try? JSONDecoder().decode([GlobalPlayer].self, from: data) {
            players = decoded
        }
    }

    private func iCloudDataDidUpdate() {
        guard let data = iCloudStore.data(forKey: storageKey),
              let cloudPlayers = try? JSONDecoder().decode([GlobalPlayer].self, from: data)
        else { return }

        // UUID-basiertes Merge: Cloud gewinnt bei Konflikten
        var merged = Dictionary(uniqueKeysWithValues: players.map { ($0.id, $0) })
        for cloudPlayer in cloudPlayers {
            merged[cloudPlayer.id] = cloudPlayer
        }
        players = Array(merged.values).sorted { $0.name < $1.name }

        if let mergedData = try? JSONEncoder().encode(players) {
            UserDefaults.standard.set(mergedData, forKey: storageKey)
        }
    }

    // MARK: - Helpers

    private func randomColorHex() -> String {
        let colors = ["#FF3B30", "#007AFF", "#34C759", "#FFCC00", "#AF52DE", "#FF9500", "#FF2D55", "#30B0C7"]
        return colors.randomElement() ?? "#007AFF"
    }
}
