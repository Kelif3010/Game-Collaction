import UIKit

enum HapticsService {
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func warning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }
    
    // Das hat gefehlt:
    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }
}
