import SwiftUI

// MARK: - Legacy Theme Wrapper
// Verweist auf BetBuddyTheme für einheitliches Casino-Design
enum Theme {
    // Neuer Casino-Gradient (Smaragd/Gold)
    static let background = BetBuddyTheme.gradient

    // Casino-Karten-Hintergrund
    static let cardBackground = BetBuddyTheme.backgroundCard
    static let cardStroke = BetBuddyTheme.cardStroke
    static let mutedText = BetBuddyTheme.textSilver

    static let cornerRadius: CGFloat = BetBuddyTheme.cornerRadius
    static let padding: CGFloat = BetBuddyTheme.padding

    static func shadow(for color: GroupColor) -> Color {
        color.primary.opacity(0.3)
    }

    static func textFieldBackground() -> Color {
        Color.white.opacity(0.06)
    }
}
