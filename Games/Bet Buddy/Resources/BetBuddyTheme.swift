//
//  BetBuddyTheme.swift
//  Bet Buddy
//
//  Redesigned: "High Stakes Casino / Poker Room" Aesthetic
//

import SwiftUI

// MARK: - Design Theme: "Casino Royale"
enum BetBuddyTheme {

    // MARK: Hauptfarben - Luxuriös, Elegant, High-Stakes

    /// Tiefschwarz mit Smaragd-Schimmer - Haupthintergrund
    static let backgroundDark = Color(red: 0.03, green: 0.05, blue: 0.04)

    /// Poker-Filz-Dunkelgrün - Sekundär
    static let backgroundFelt = Color(red: 0.05, green: 0.12, blue: 0.08)

    /// Akzent-Hintergrund für Karten
    static let backgroundCard = Color(red: 0.08, green: 0.10, blue: 0.08)

    // MARK: Akzentfarben

    /// Gold/Messing - Hauptakzent für Premium-Gefühl
    static let accentGold = Color(red: 0.85, green: 0.65, blue: 0.12)

    /// Helles Gold - Highlights
    static let accentGoldLight = Color(red: 0.95, green: 0.80, blue: 0.35)

    /// Poker-Tisch-Grün - Sekundärer Akzent
    static let accentEmerald = Color(red: 0.15, green: 0.55, blue: 0.35)

    /// Casino-Rot - Spannung, Gefahr, Verlust
    static let accentRuby = Color(red: 0.65, green: 0.12, blue: 0.15)

    /// Gewinner-Grün - Erfolg
    static let accentSuccess = Color(red: 0.20, green: 0.65, blue: 0.40)

    // MARK: Textfarben

    /// Champagner - Eleganter Haupttext
    static let textChampagne = Color(red: 0.95, green: 0.92, blue: 0.85)

    /// Silber - Gedämpfter Text
    static let textSilver = Color(red: 0.60, green: 0.60, blue: 0.58)

    /// Gold-Text für Highlights
    static let textGold = Color(red: 0.90, green: 0.75, blue: 0.30)

    /// Dunkler Text auf hellem Hintergrund
    static let textOnLight = Color(red: 0.08, green: 0.08, blue: 0.06)

    // MARK: Gradienten

    /// Hauptgradient - Casino-Atmosphäre
    static let gradient = LinearGradient(
        colors: [
            backgroundDark,
            backgroundFelt,
            Color(red: 0.04, green: 0.08, blue: 0.05)
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    /// Gold-Gradient - Für Premium-Buttons und Highlights
    static let goldGradient = LinearGradient(
        colors: [
            accentGoldLight,
            accentGold,
            Color(red: 0.70, green: 0.50, blue: 0.10)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Emerald-Gradient - Für sekundäre Elemente
    static let emeraldGradient = LinearGradient(
        colors: [
            Color(red: 0.20, green: 0.65, blue: 0.45),
            accentEmerald
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Ruby-Gradient - Für Verlust/Aufgeben
    static let rubyGradient = LinearGradient(
        colors: [
            Color(red: 0.75, green: 0.20, blue: 0.20),
            accentRuby
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: Legacy Support (für bestehende Views während Migration)
    static let background = gradient
    static let cardBackground = backgroundCard
    static let cardStroke = accentGold.opacity(0.15)
    static let mutedText = textSilver
    static let cornerRadius: CGFloat = 16
    static let padding: CGFloat = 20

    static func shadow(for color: GroupColor) -> Color {
        color.primary.opacity(0.3)
    }

    static func textFieldBackground() -> Color {
        Color.white.opacity(0.06)
    }
}

// MARK: - Animated Background: "Casino Table"
struct BetBuddyBackgroundView: View {
    var intensity: CGFloat = 0.5

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            ZStack {
                // Basis: Dunkler Smaragd-Gradient
                BetBuddyTheme.gradient
                    .ignoresSafeArea()

                // Poker-Filz-Textur (Subtil)
                FeltTextureOverlay()
                    .opacity(0.04)
                    .ignoresSafeArea()

                // Vignette für Spotlight-Effekt
                RadialGradient(
                    colors: [
                        Color.clear,
                        Color.black.opacity(0.5)
                    ],
                    center: .center,
                    startRadius: width * 0.25,
                    endRadius: width * 0.85
                )
                .ignoresSafeArea()

                // Subtiler Gold-Schimmer von oben (wie Casino-Beleuchtung)
                LinearGradient(
                    colors: [
                        BetBuddyTheme.accentGold.opacity(0.03 * intensity),
                        Color.clear
                    ],
                    startPoint: .top,
                    endPoint: .center
                )
                .ignoresSafeArea()

                // Ambient Glow bei hoher Intensität (Spannung)
                if intensity > 0.7 {
                    RadialGradient(
                        colors: [
                            BetBuddyTheme.accentGold.opacity(0.08),
                            Color.clear
                        ],
                        center: .top,
                        startRadius: 0,
                        endRadius: 300
                    )
                    .ignoresSafeArea()
                }
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Felt Texture Overlay (Poker Table)
struct FeltTextureOverlay: View {
    var body: some View {
        Canvas { context, size in
            // Subtiles Rauschen für Filz-Textur
            for _ in 0..<Int(size.width * size.height / 50) {
                let x = CGFloat.random(in: 0...size.width)
                let y = CGFloat.random(in: 0...size.height)
                let dotSize = CGFloat.random(in: 0.5...1.5)

                let rect = CGRect(x: x, y: y, width: dotSize, height: dotSize)
                context.opacity = Double.random(in: 0.3...0.7)
                context.fill(Path(ellipseIn: rect), with: .color(BetBuddyTheme.accentEmerald))
            }
        }
    }
}

// MARK: - Chip Counter Digit (Casino Style)
struct ChipDigitView: View {
    let digit: String
    let color: Color

    var body: some View {
        ZStack {
            // Chip-Basis
            RoundedRectangle(cornerRadius: 10)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.12, green: 0.12, blue: 0.10),
                            Color(red: 0.06, green: 0.06, blue: 0.05)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            // Metallic Rand
            RoundedRectangle(cornerRadius: 10)
                .stroke(
                    LinearGradient(
                        colors: [
                            BetBuddyTheme.accentGold.opacity(0.6),
                            BetBuddyTheme.accentGold.opacity(0.2),
                            BetBuddyTheme.accentGold.opacity(0.4)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )

            // Innerer Schimmer
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
                .padding(3)

            // Die Ziffer
            Text(digit)
                .font(.system(size: 40, weight: .heavy, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [color, color.opacity(0.8)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: color.opacity(0.5), radius: 4, y: 2)
        }
        .frame(width: 58, height: 68)
        .shadow(color: BetBuddyTheme.accentGold.opacity(0.15), radius: 8, y: 4)
    }
}

// MARK: - Casino Card Background
struct CasinoCardBackground: View {
    var highlighted: Bool = false
    var highlightColor: Color = BetBuddyTheme.accentGold

    var body: some View {
        ZStack {
            // Basis
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.10, green: 0.12, blue: 0.10),
                            Color(red: 0.06, green: 0.08, blue: 0.06)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // Filz-Textur
            FeltTextureOverlay()
                .opacity(0.02)
                .clipShape(RoundedRectangle(cornerRadius: 16))

            // Highlight Glow
            if highlighted {
                RoundedRectangle(cornerRadius: 16)
                    .fill(highlightColor.opacity(0.08))
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    highlighted
                        ? highlightColor.opacity(0.5)
                        : BetBuddyTheme.accentGold.opacity(0.12),
                    lineWidth: highlighted ? 2 : 1
                )
        )
        .shadow(
            color: highlighted ? highlightColor.opacity(0.2) : Color.black.opacity(0.3),
            radius: highlighted ? 12 : 8,
            y: 4
        )
    }
}

// MARK: - Gold Accent Button Style
struct GoldButtonStyle: ButtonStyle {
    var isDisabled: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.bold))
            .foregroundStyle(isDisabled ? BetBuddyTheme.textSilver : BetBuddyTheme.textOnLight)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(
                Group {
                    if isDisabled {
                        Capsule()
                            .fill(Color.white.opacity(0.08))
                    } else {
                        Capsule()
                            .fill(BetBuddyTheme.goldGradient)
                            .shadow(color: BetBuddyTheme.accentGold.opacity(0.4), radius: 12, y: 4)
                    }
                }
            )
            .overlay(
                Capsule()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.3),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
                    .opacity(isDisabled ? 0 : 1)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Secondary Button Style (Outline)
struct CasinoOutlineButtonStyle: ButtonStyle {
    var color: Color = BetBuddyTheme.accentGold

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .foregroundStyle(color)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(
                Capsule()
                    .fill(color.opacity(0.08))
            )
            .overlay(
                Capsule()
                    .stroke(color.opacity(0.4), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Chip Stack Indicator
struct ChipStackView: View {
    let count: Int
    let color: Color

    var body: some View {
        ZStack {
            ForEach(0..<min(count, 5), id: \.self) { index in
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                color.opacity(0.9),
                                color.opacity(0.6)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 24, height: 24)
                    .overlay(
                        Circle()
                            .stroke(BetBuddyTheme.accentGold.opacity(0.5), lineWidth: 1.5)
                    )
                    .offset(y: CGFloat(-index * 4))
                    .shadow(color: Color.black.opacity(0.3), radius: 2, y: 2)
            }

            if count > 5 {
                Text("+\(count - 5)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(BetBuddyTheme.textChampagne)
                    .offset(y: -24)
            }
        }
    }
}

// MARK: - Preview
#Preview("Casino Theme") {
    ZStack {
        BetBuddyBackgroundView(intensity: 0.8)

        VStack(spacing: 24) {
            Text("HIGH STAKES")
                .font(.system(size: 32, weight: .black, design: .rounded))
                .foregroundStyle(BetBuddyTheme.textGold)
                .tracking(4)

            HStack(spacing: 8) {
                ChipDigitView(digit: "0", color: BetBuddyTheme.accentGold)
                ChipDigitView(digit: "4", color: BetBuddyTheme.accentGold)
                ChipDigitView(digit: "2", color: BetBuddyTheme.accentGold)
            }

            CasinoCardBackground(highlighted: true, highlightColor: .green)
                .frame(height: 120)
                .overlay(
                    Text("Team Alpha")
                        .font(.title2.bold())
                        .foregroundStyle(BetBuddyTheme.textChampagne)
                )
                .padding(.horizontal, 40)

            Button("ALL IN") {}
                .buttonStyle(GoldButtonStyle())
                .padding(.horizontal, 40)

            Button("Passen") {}
                .buttonStyle(CasinoOutlineButtonStyle())
                .padding(.horizontal, 40)

            HStack(spacing: 20) {
                ChipStackView(count: 3, color: .red)
                ChipStackView(count: 7, color: .blue)
                ChipStackView(count: 5, color: .green)
            }
        }
        .padding()
    }
}
