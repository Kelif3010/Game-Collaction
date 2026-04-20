import SwiftUI

// MARK: - Liquid Glass View Modifiers
// Shared glass effect helpers used across all games.

/// Applies Liquid Glass on iOS 26+ and a semi-transparent circle
/// background on earlier versions. Use on icon-only buttons (44×44pt).
struct GlassCircleButtonBackground: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content
                .glassEffect(.regular.interactive(), in: Circle())
        } else {
            content
                .background(Color.white.opacity(0.1))
                .clipShape(Circle())
        }
    }
}
