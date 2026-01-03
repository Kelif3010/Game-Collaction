import Foundation

struct GroupNamePersistence {
    private let defaults = UserDefaults.standard
    private func key(for color: GroupColor) -> String { "group.name.\(color.rawValue)" }

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
}
