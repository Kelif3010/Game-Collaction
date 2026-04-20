import Foundation

@MainActor
struct GroupNamePersistence {
    private let defaults = UserDefaults.standard

    private func key(for color: GroupColor) -> String { "group.name.\(color.rawValue)" }
    private func player1Key(for color: GroupColor) -> String { "group.player1.\(color.rawValue)" }
    private func player2Key(for color: GroupColor) -> String { "group.player2.\(color.rawValue)" }

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
}
