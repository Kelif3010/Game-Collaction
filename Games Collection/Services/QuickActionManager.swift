import UIKit
import SwiftUI
import Combine

enum QuickActionType: String {
    case betBuddy = "quickaction.betbuddy"
    case timesUp = "quickaction.timesup"
    case question = "quickaction.question"
    case imposter = "quickaction.imposter"

    var gameId: String {
        switch self {
        case .betBuddy: return "BetBuddy"
        case .timesUp: return "TimesUp"
        case .question: return "Question"
        case .imposter: return "Imposter"
        }
    }

    var title: String {
        switch self {
        case .betBuddy:
            return NSLocalizedString("Bet Buddy", comment: "Quick action title")
        case .timesUp:
            return NSLocalizedString("Time's Up!", comment: "Quick action title")
        case .question:
            return NSLocalizedString("Lügner", comment: "Quick action title")
        case .imposter:
            return NSLocalizedString("Imposter", comment: "Quick action title")
        }
    }

    var icon: UIApplicationShortcutIcon {
        switch self {
        case .betBuddy:
            return UIApplicationShortcutIcon(systemImageName: "person.2.fill")
        case .timesUp:
            return UIApplicationShortcutIcon(systemImageName: "hourglass")
        case .question:
            return UIApplicationShortcutIcon(systemImageName: "person.fill.questionmark")
        case .imposter:
            return UIApplicationShortcutIcon(systemImageName: "theatermasks.fill")
        }
    }
}

@MainActor
final class QuickActionManager: ObservableObject {
    static let shared = QuickActionManager()

    @Published var pendingAction: QuickActionType?

    private init() {}

    func updateQuickActions() {
        let subtitle = NSLocalizedString("Start", comment: "Quick action subtitle")
        let items = [
            QuickActionType.betBuddy,
            QuickActionType.timesUp,
            QuickActionType.question,
            QuickActionType.imposter
        ].map { type in
            UIApplicationShortcutItem(
                type: type.rawValue,
                localizedTitle: type.title,
                localizedSubtitle: subtitle,
                icon: type.icon,
                userInfo: nil
            )
        }
        UIApplication.shared.shortcutItems = items
    }

    func handleShortcutItem(_ shortcutItem: UIApplicationShortcutItem) -> Bool {
        guard let action = QuickActionType(rawValue: shortcutItem.type) else {
            return false
        }
        DispatchQueue.main.async {
            self.pendingAction = action
        }
        return true
    }
}
