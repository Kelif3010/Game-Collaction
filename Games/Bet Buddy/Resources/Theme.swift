import SwiftUI

enum Theme {
    static let background = LinearGradient(
        colors: [
            Color(red: 0.07, green: 0.07, blue: 0.12),
            Color(red: 0.05, green: 0.08, blue: 0.18)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let cardBackground = Color(red: 0.13, green: 0.14, blue: 0.20)
    static let cardStroke = Color.white.opacity(0.08)
    static let mutedText = Color.white.opacity(0.7)

    static let cornerRadius: CGFloat = 20
    static let padding: CGFloat = 20

    static func shadow(for color: GroupColor) -> Color {
        color.primary.opacity(0.3)
    }

    static func textFieldBackground() -> Color {
        Color.white.opacity(0.06)
    }
}
