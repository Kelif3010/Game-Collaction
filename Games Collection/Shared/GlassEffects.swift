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

/// Wraps children in a GlassEffectContainer on iOS 26+; passthrough on earlier versions.
struct CompatibleGlassEffectContainer<Content: View>: View {
    private let spacing: CGFloat
    private let content: () -> Content

    init(spacing: CGFloat = 24, @ViewBuilder content: @escaping () -> Content) {
        self.spacing = spacing
        self.content = content
    }

    @ViewBuilder
    var body: some View {
        if #available(iOS 26.0, *) {
            GlassEffectContainer(spacing: spacing) {
                content()
            }
        } else {
            content()
        }
    }
}

extension View {
    /// Applies a glass card effect on iOS 26+ and an ultraThinMaterial background on earlier versions.
    @ViewBuilder
    func compatibleGlassCardEffect(cornerRadius: CGFloat) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        if #available(iOS 26.0, *) {
            glassEffect(.regular.interactive(), in: shape)
                .clipShape(shape)
        } else {
            clipShape(shape)
                .background(.ultraThinMaterial, in: shape)
        }
    }
}
