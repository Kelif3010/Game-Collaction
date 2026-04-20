import UIKit

enum HapticsService {
    private static var isEnabled: Bool {
        guard UserDefaults.standard.object(forKey: "isHapticsEnabled") != nil else { return true }
        return UserDefaults.standard.bool(forKey: "isHapticsEnabled")
    }

    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        guard isEnabled else { return }
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    static func success() {
        guard isEnabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func warning() {
        guard isEnabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }

    static func selection() {
        guard isEnabled else { return }
        UISelectionFeedbackGenerator().selectionChanged()
    }
}
