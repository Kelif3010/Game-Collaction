import SwiftUI

enum ImposterStyle {
    // MARK: - Legacy Gradients (für Kompatibilität)
    static let backgroundGradient = LinearGradient(
        colors: [
            Color.black,
            Color(red: 0.16, green: 0.02, blue: 0.08),
            Color(red: 0.28, green: 0.02, blue: 0.18)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let primaryGradient = LinearGradient(
        colors: [Color(red: 1.0, green: 0.41, blue: 0.23), Color(red: 0.94, green: 0.16, blue: 0.47)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: - Spy Theme Colors (Geheimdienst)
    static let spyRed = Color(red: 0.85, green: 0.15, blue: 0.15)
    static let spyDarkRed = Color(red: 0.5, green: 0.08, blue: 0.08)
    static let terminalGreen = Color(red: 0.2, green: 0.8, blue: 0.3)
    static let terminalAmber = Color(red: 1.0, green: 0.75, blue: 0.0)
    static let classifiedRed = Color(red: 0.9, green: 0.2, blue: 0.2)

    // MARK: - Layout Constants
    static let darkCardFill = Color.black.opacity(0.25)
    static let containerBackground = Color.black.opacity(0.25)
    static let rowBackground = Color.black.opacity(0.25)
    static let cardStroke = Color.white.opacity(0.08)
    static let containerCornerRadius: CGFloat = 22
    static let rowCornerRadius: CGFloat = 18
    static let padding: CGFloat = 20
    static let mutedText = Color.white.opacity(0.7)
}

// MARK: - Scanline Overlay (Terminal-Effekt)
struct ScanlineOverlay: View {
    var lineSpacing: CGFloat = 3
    var opacity: Double = 0.04

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: lineSpacing) {
                ForEach(0..<Int(geo.size.height / lineSpacing), id: \.self) { _ in
                    Rectangle()
                        .fill(Color.white.opacity(opacity))
                        .frame(height: 1)
                }
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Classified Badge (TOP SECRET, etc.)
struct ClassifiedBadge: View {
    let text: String
    var color: Color = ImposterStyle.classifiedRed

    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .black, design: .monospaced))
            .tracking(2)
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(color.opacity(0.15))
            .overlay(
                Rectangle()
                    .stroke(color.opacity(0.6), lineWidth: 1.5)
            )
    }
}

// MARK: - Terminal Text Style
struct TerminalText: View {
    let text: String
    var size: CGFloat = 14
    var color: Color = .white
    var tracking: CGFloat = 1

    var body: some View {
        Text(text)
            .font(.system(size: size, weight: .bold, design: .monospaced))
            .tracking(tracking)
            .foregroundStyle(color)
    }
}

// MARK: - Mission Status Indicator
struct MissionStatusIndicator: View {
    let status: String
    let isActive: Bool
    var activeColor: Color = ImposterStyle.spyRed

    @State private var blink = false

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(isActive ? activeColor : Color.gray.opacity(0.5))
                .frame(width: 8, height: 8)
                .opacity(isActive && blink ? 0.4 : 1.0)

            Text(status.uppercased())
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .tracking(2)
                .foregroundStyle(isActive ? activeColor : .gray)
        }
        .onAppear {
            if isActive {
                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                    blink = true
                }
            }
        }
    }
}

extension View {
    func imposterRowStyle() -> some View {
        self
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: ImposterStyle.rowCornerRadius, style: .continuous)
                    .fill(ImposterStyle.rowBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: ImposterStyle.rowCornerRadius, style: .continuous)
                    .stroke(ImposterStyle.cardStroke, lineWidth: 1)
            )
    }
}

struct ImposterPrimaryButton: View {
    let title: String
    let action: () -> Void
    var isDisabled: Bool = false

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
        }
        .background(
            Capsule()
                .fill(ImposterStyle.primaryGradient)
        )
        .shadow(color: .black.opacity(0.25), radius: 16, y: 8)
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.6 : 1.0)
    }
}

struct ImposterSheetHeader: View {
    let title: LocalizedStringKey
    let onBack: () -> Void

    var body: some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.headline.bold())
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .modifier(GlassCircleButtonBackground())
            }

            Spacer()

            Text(title)
                .font(.title3.bold())
                .foregroundStyle(.white)

            Spacer()

            Color.clear
                .frame(width: 44, height: 44)
        }
        .padding(.top, 20)
        .padding(.bottom, 8)
    }
}

struct ImposterIconBadge: View {
    let systemName: String
    let tint: Color

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [tint.opacity(0.35), tint.opacity(0.15)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            Image(systemName: systemName)
                .foregroundStyle(tint)
                .font(.system(size: 18, weight: .semibold))
        }
        .frame(width: 44, height: 44)
    }
}

