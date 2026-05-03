import Foundation

@MainActor @Observable
final class SettingsService {
    static let shared = SettingsService()

    // UserDefaults keys
    private let enableHintsKey = "settings.enableHints"

    var enableHints: Bool {
        didSet { UserDefaults.standard.set(enableHints, forKey: enableHintsKey) }
    }

    private init() {
        let defaults = UserDefaults.standard
        if defaults.object(forKey: enableHintsKey) == nil {
            defaults.set(true, forKey: enableHintsKey)
        }
        self.enableHints = defaults.bool(forKey: enableHintsKey)
    }
}
