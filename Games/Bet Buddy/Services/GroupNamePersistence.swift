import Foundation

@MainActor
struct GroupNamePersistence {
    private let defaults = UserDefaults.standard

    private func key(for color: GroupColor) -> String { "group.name.\(color.rawValue)" }
    private func player1Key(for color: GroupColor) -> String { "group.player1.\(color.rawValue)" }
    private func player2Key(for color: GroupColor) -> String { "group.player2.\(color.rawValue)" }
    private func playerNamesKey(for color: GroupColor) -> String { "group.players.\(color.rawValue)" }

    // MARK: - Teamname

    func loadName(for color: GroupColor) -> String? {
        let value = defaults.string(forKey: key(for: color))?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return value.isEmpty ? nil : value
    }

    func save(name: String?, for color: GroupColor) {
        let trimmed = name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if trimmed.isEmpty {
            defaults.removeObject(forKey: key(for: color))
        } else {
            defaults.set(trimmed, forKey: key(for: color))
        }
    }

    // MARK: - Spielernamen

    func loadPlayer1(for color: GroupColor) -> String? {
        let value = defaults.string(forKey: player1Key(for: color))?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return value.isEmpty ? nil : value
    }

    func loadPlayer2(for color: GroupColor) -> String? {
        let value = defaults.string(forKey: player2Key(for: color))?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return value.isEmpty ? nil : value
    }

    func loadPlayerNames(for color: GroupColor) -> [String?] {
        if let data = defaults.data(forKey: playerNamesKey(for: color)),
           let decoded = try? JSONDecoder().decode([String].self, from: data) {
            return normalized(decoded)
        }

        return normalized([loadPlayer1(for: color), loadPlayer2(for: color)])
    }

    func savePlayer1(name: String?, for color: GroupColor) {
        let trimmed = name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if trimmed.isEmpty {
            defaults.removeObject(forKey: player1Key(for: color))
        } else {
            defaults.set(trimmed, forKey: player1Key(for: color))
        }
    }

    func savePlayer2(name: String?, for color: GroupColor) {
        let trimmed = name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if trimmed.isEmpty {
            defaults.removeObject(forKey: player2Key(for: color))
        } else {
            defaults.set(trimmed, forKey: player2Key(for: color))
        }
    }

    func savePlayerNames(_ names: [String], for color: GroupColor) {
        let trimmed = normalized(names)
        if trimmed.allSatisfy({ ($0 ?? "").isEmpty }) {
            defaults.removeObject(forKey: playerNamesKey(for: color))
        } else {
            let persistable = trimmed.map { $0 ?? "" }
            if let data = try? JSONEncoder().encode(persistable) {
                defaults.set(data, forKey: playerNamesKey(for: color))
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
