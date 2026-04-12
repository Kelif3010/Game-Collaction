import SwiftUI

// MARK: - Farb-Palette
enum SoundCinemaColor {
    case cyan
    case mint
    case orange

    var primary: Color {
        switch self {
        case .cyan:   return Color(red: 0.0, green: 0.83, blue: 1.0)
        case .mint:   return Color(red: 0.25, green: 0.95, blue: 0.75)
        case .orange: return Color(red: 1.0, green: 0.5, blue: 0.1)
        }
    }

    var secondary: Color {
        switch self {
        case .cyan:   return Color(red: 0.2, green: 0.6, blue: 1.0)
        case .mint:   return Color(red: 0.1, green: 0.8, blue: 0.6)
        case .orange: return Color(red: 1.0, green: 0.3, blue: 0.2)
        }
    }

    var gradient: LinearGradient {
        LinearGradient(
            colors: [primary, secondary],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Haupt-Design-System
enum SoundCinemaStyle {

    // MARK: Farben
    static let accentCyan    = Color(red: 0.0,  green: 0.83, blue: 1.0)
    static let accentMint    = Color(red: 0.25, green: 0.95, blue: 0.75)
    static let accentOrange  = Color(red: 1.0,  green: 0.5,  blue: 0.1)
    static let textPrimary   = Color.white
    static let textMuted     = Color.white.opacity(0.6)
    static let cardFill      = Color.white.opacity(0.06)
    static let cardStroke    = Color.white.opacity(0.10)

    // MARK: Primärer Gradient (Cyan → Blau-Lila)
    static let primaryGradient = LinearGradient(
        colors: [
            Color(red: 0.0,  green: 0.83, blue: 1.0),
            Color(red: 0.35, green: 0.45, blue: 1.0)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: Hintergrund-Gradient
    static let backgroundGradient = LinearGradient(
        colors: [
            Color(red: 0.02, green: 0.06, blue: 0.18),
            Color(red: 0.05, green: 0.12, blue: 0.25),
            Color(red: 0.02, green: 0.08, blue: 0.20)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: Layout
    static let containerCornerRadius: CGFloat = 22
    static let rowCornerRadius: CGFloat       = 18
    static let buttonCornerRadius: CGFloat    = 16
    static let padding: CGFloat               = 20

    // MARK: Fonts
    static let titleFont   = Font.system(size: 28, weight: .black, design: .rounded)
    static let headingFont = Font.system(size: 18, weight: .bold,  design: .rounded)
    static let bodyFont    = Font.system(size: 15, weight: .medium)
    static let labelFont   = Font.system(size: 11, weight: .bold,  design: .monospaced)
}

// MARK: - Hintergrund-View
struct SoundCinemaBackground: View {
    var body: some View {
        ZStack {
            SoundCinemaStyle.backgroundGradient
                .ignoresSafeArea()

            // Subtile Radial-Glow in Cyan
            RadialGradient(
                colors: [
                    SoundCinemaStyle.accentCyan.opacity(0.08),
                    Color.clear
                ],
                center: .top,
                startRadius: 0,
                endRadius: 400
            )
            .ignoresSafeArea()
        }
    }
}

// MARK: - Glass Card Modifier
struct SoundCinemaCardStyle: ViewModifier {
    var cornerRadius: CGFloat = SoundCinemaStyle.containerCornerRadius
    var highlighted: Bool = false

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(highlighted
                          ? SoundCinemaStyle.accentCyan.opacity(0.12)
                          : SoundCinemaStyle.cardFill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        highlighted
                            ? SoundCinemaStyle.accentCyan.opacity(0.5)
                            : SoundCinemaStyle.cardStroke,
                        lineWidth: highlighted ? 1.5 : 1
                    )
            )
    }
}

extension View {
    func soundCinemaCard(cornerRadius: CGFloat = SoundCinemaStyle.containerCornerRadius,
                         highlighted: Bool = false) -> some View {
        modifier(SoundCinemaCardStyle(cornerRadius: cornerRadius, highlighted: highlighted))
    }
}

// MARK: - Primärer Button
struct SoundCinemaPrimaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    var isDisabled: Bool = false

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
                        .font(.system(size: 16, weight: .bold))
                }
                Text(title)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
            }
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                Capsule()
                    .fill(SoundCinemaStyle.primaryGradient)
                    .shadow(color: SoundCinemaStyle.accentCyan.opacity(0.4), radius: 12, y: 5)
            )
        }
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.45 : 1.0)
    }
}

// MARK: - Header
struct SoundCinemaHeader: View {
    let title: String
    var trailingButtons: [HeaderButton] = []
    var onBack: (() -> Void)?

    @Environment(\.dismiss) private var dismiss

    struct HeaderButton: Identifiable {
        let id = UUID()
        let icon: String
        let action: () -> Void
    }

    var body: some View {
        HStack(spacing: 0) {
            // Zurück-Button
            Button {
                onBack?() ?? dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(SoundCinemaStyle.textPrimary)
                    .frame(width: 44, height: 44)
                    .modifier(GlassCircleButtonBackground())
            }

            Spacer()

            Text(title)
                .font(SoundCinemaStyle.headingFont)
                .foregroundStyle(SoundCinemaStyle.accentCyan)
                .tracking(0.5)

            Spacer()

            // Trailing-Buttons oder Platzhalter
            if trailingButtons.isEmpty {
                Color.clear.frame(width: 44, height: 44)
            } else {
                HStack(spacing: 8) {
                    ForEach(trailingButtons) { btn in
                        Button(action: btn.action) {
                            Image(systemName: btn.icon)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(SoundCinemaStyle.textPrimary)
                                .frame(width: 44, height: 44)
                                .modifier(GlassCircleButtonBackground())
                        }
                    }
                }
            }
        }
        .padding(.top, 4)
        .padding(.bottom, 8)
    }
}
