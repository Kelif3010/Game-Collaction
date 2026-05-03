import Foundation

@MainActor
struct GroupNamePersistence {
    private let defaults = UserDefaults.standard

    private enum Key {
        static func groupName(_ color: GroupColor) -> String { "group.name.\(color.rawValue)" }
        static func player1(_ color: GroupColor) -> String { "group.player1.\(color.rawValue)" }
        static func player2(_ color: GroupColor) -> String { "group.player2.\(color.rawValue)" }
        static func playerNames(_ color: GroupColor) -> String { "group.players.\(color.rawValue)" }
    }

    // MARK: - Teamname

    func loadName(for color: GroupColor) -> String? {
        let value = defaults.string(forKey: Key.groupName(color))?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return value.isEmpty ? nil : value
    }

    func save(name: String?, for color: GroupColor) {
        let trimmed = name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if trimmed.isEmpty {
            defaults.removeObject(forKey: Key.groupName(color))
        } else {
            defaults.set(trimmed, forKey: Key.groupName(color))
        }
    }

    // MARK: - Spielernamen

    func loadPlayer1(for color: GroupColor) -> String? {
        let value = defaults.string(forKey: Key.player1(color))?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return value.isEmpty ? nil : value
    }

    func loadPlayer2(for color: GroupColor) -> String? {
        let value = defaults.string(forKey: Key.player2(color))?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return value.isEmpty ? nil : value
    }

    func loadPlayerNames(for color: GroupColor) -> [String?] {
        if let data = defaults.data(forKey: Key.playerNames(color)),
           let decoded = try? JSONDecoder().decode([String].self, from: data) {
            return normalized(decoded)
        }

        return normalized([loadPlayer1(for: color), loadPlayer2(for: color)])
    }

    func savePlayer1(name: String?, for color: GroupColor) {
        let trimmed = name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if trimmed.isEmpty {
            defaults.removeObject(forKey: Key.player1(color))
        } else {
            defaults.set(trimmed, forKey: Key.player1(color))
        }
    }

    func savePlayer2(name: String?, for color: GroupColor) {
        let trimmed = name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if trimmed.isEmpty {
            defaults.removeObject(forKey: Key.player2(color))
        } else {
            defaults.set(trimmed, forKey: Key.player2(color))
        }
    }

    func savePlayerNames(_ names: [String], for color: GroupColor) {
        let trimmed = normalized(names)
        if trimmed.allSatisfy({ ($0 ?? "").isEmpty }) {
            defaults.removeObject(forKey: Key.playerNames(color))
        } else {
            let persistable = trimmed.map { $0 ?? "" }
            if let data = try? JSONEncoder().encode(persistable) {
                defaults.set(data, forKey: Key.playerNames(color))
            }
        }

        savePlayer1(name: trimmed[safe: 0] ?? nil, for: color)
        savePlayer2(name: trimmed[safe: 1] ?? nil, for: color)
    }

    private func normalized(_ names: [String?]) -> [String?] {
        var result = Array(names.prefix(GroupInfo.maxPlayerCount)).map { name -> String? in
            let trimmed = name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return trimmed.isEmpty ? nil : trimmed
        }
        while result.count < GroupInfo.minPlayerCount {
            result.append(nil)
        }
        return result
    }

    private func normalized(_ names: [String]) -> [String?] {
        normalized(names.map { Optional($0) })
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
