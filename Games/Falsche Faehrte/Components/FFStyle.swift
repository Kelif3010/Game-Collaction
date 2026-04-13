import SwiftUI

// MARK: - Hilfs-Typen
struct FFThemeColor {
    let primary: Color
    let secondary: Color
}

// MARK: - Falsche Fährte Design-System
// Detektiv-/Verhör-Ästhetik: Violett/Indigo mit Noir-Atmosphäre

enum FFStyle {
    // MARK: Farben
    static let accentViolet  = Color(red: 0.48, green: 0.36, blue: 0.94)   // #7B5CF0
    static let accentIndigo  = Color(red: 0.33, green: 0.25, blue: 0.82)   // #543FD0
    static let accentCrimson = Color(red: 0.86, green: 0.20, blue: 0.35)   // #DC3459
    static let accentGold    = Color(red: 0.95, green: 0.78, blue: 0.22)   // #F2C738

    static let backgroundDark  = Color(red: 0.05, green: 0.04, blue: 0.12)  // tiefes Noir-Blauschwarz
    static let backgroundCard  = Color(red: 0.10, green: 0.08, blue: 0.22)  // Karten-Hintergrund
    static let textPrimary     = Color.white
    static let textMuted       = Color.white.opacity(0.55)
    static let textSubtle      = Color.white.opacity(0.35)

    // MARK: Gradienten
    static var primaryGradient: LinearGradient {
        LinearGradient(
            colors: [accentViolet, accentIndigo],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.06, green: 0.04, blue: 0.15),
                Color(red: 0.03, green: 0.02, blue: 0.08)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static var cardGradient: LinearGradient {
        LinearGradient(
            colors: [
                accentViolet.opacity(0.15),
                backgroundCard
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: Layout
    static let cornerRadius: CGFloat     = 22
    static let buttonRadius: CGFloat     = 18
    static let cardPadding: CGFloat      = 18
    static let sectionSpacing: CGFloat   = 20
    static let headerHeight: CGFloat     = 56

    // MARK: Typografie
    static func titleFont(_ size: CGFloat = 28) -> Font {
        .system(size: size, weight: .black, design: .rounded)
    }

    static func bodyFont(_ size: CGFloat = 16) -> Font {
        .system(size: size, weight: .semibold, design: .rounded)
    }

    static func labelFont(_ size: CGFloat = 13) -> Font {
        .system(size: size, weight: .bold, design: .monospaced)
    }
}

// MARK: - Hintergrund-View
struct FFBackground: View {
    var body: some View {
        ZStack {
            FFStyle.backgroundGradient
                .ignoresSafeArea()
            // Violetter Glow oben
            VStack {
                RadialGradient(
                    colors: [FFStyle.accentViolet.opacity(0.12), Color.clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: 250
                )
                .frame(height: 300)
                Spacer()
            }
        }
    }
}

// MARK: - Primärer Button
struct FFPrimaryButton: View {
    let title: String
    let icon: String?
    var isDisabled: Bool = false
    let action: () -> Void

    init(_ title: String, icon: String? = nil, isDisabled: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.isDisabled = isDisabled
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .bold))
                }
                Text(LocalizedStringKey(title))
                    .font(.system(size: 18, weight: .bold, design: .rounded))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                Capsule()
                    .fill(isDisabled ? AnyShapeStyle(Color.white.opacity(0.1)) : AnyShapeStyle(FFStyle.primaryGradient))
                    .shadow(color: isDisabled ? .clear : FFStyle.accentViolet.opacity(0.5), radius: 16, y: 6)
            )
            .opacity(isDisabled ? 0.5 : 1)
        }
        .disabled(isDisabled)
        .padding(.horizontal, 24)
    }
}

// MARK: - Header
struct FFHeader: View {
    let title: String
    var onBack: (() -> Void)?
    var trailingItems: AnyView?

    var body: some View {
        HStack(spacing: 12) {
            if let onBack {
                Button(action: onBack) {
                    ZStack {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 36, height: 36)
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
            }

            Spacer()

            Text(LocalizedStringKey(title))
                .font(FFStyle.bodyFont(17))
                .foregroundStyle(.white)

            Spacer()

            if let trailingItems {
                trailingItems
            } else if onBack != nil {
                // Platzhalter für symmetrisches Layout
                Circle()
                    .fill(Color.clear)
                    .frame(width: 36, height: 36)
            }
        }
        .padding(.horizontal, 20)
        .frame(height: FFStyle.headerHeight)
    }
}

// MARK: - Glas-Karten-Modifier
struct FFCardStyle: ViewModifier {
    var isPrimary: Bool = false

    func body(content: Content) -> some View {
        content
            .background(cardBackground)
    }

    @ViewBuilder
    private var cardBackground: some View {
        if isPrimary {
            RoundedRectangle(cornerRadius: FFStyle.cornerRadius, style: .continuous)
                .fill(FFStyle.cardGradient)
                .overlay(
                    RoundedRectangle(cornerRadius: FFStyle.cornerRadius, style: .continuous)
                        .stroke(FFStyle.accentViolet.opacity(0.4), lineWidth: 1)
                )
        } else {
            RoundedRectangle(cornerRadius: FFStyle.cornerRadius, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: FFStyle.cornerRadius, style: .continuous)
                        .stroke(FFStyle.accentViolet.opacity(0.15), lineWidth: 1)
                )
        }
    }
}

extension View {
    func ffCard(isPrimary: Bool = false) -> some View {
        modifier(FFCardStyle(isPrimary: isPrimary))
    }
}
