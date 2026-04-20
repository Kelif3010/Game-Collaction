//
//  QuestionsTheme.swift
//  Question
//
//  Created by Ken  on 27.12.25.
//  Redesigned: Lügendetektor / Verhörraum Aesthetic
//

import SwiftUI

// MARK: - Design Theme: "Verhörraum"
enum QuestionsTheme {

    // MARK: Hauptfarben - Dunkel, Klinisch, Bedrohlich

    /// Fast-Schwarz - Haupthintergrund
    static let backgroundDark = Color(red: 0.04, green: 0.04, blue: 0.04)

    /// Dunkelbraun-Grau - Sekundär
    static let backgroundMid = Color(red: 0.08, green: 0.07, blue: 0.05)

    /// Schwarz-Oliv - Akzent-Hintergrund
    static let backgroundAccent = Color(red: 0.10, green: 0.09, blue: 0.06)

    // MARK: Akzentfarben

    /// Giftgrün - Polygraph-Linie, Hauptakzent
    static let accentGreen = Color(red: 0.22, green: 1.0, blue: 0.08)

    /// Bernstein - Warnungen, sekundärer Akzent
    static let accentAmber = Color(red: 1.0, green: 0.75, blue: 0.0)

    /// Dunkelrot - Stempel "LÜGNER", Gefahr
    static let accentDanger = Color(red: 0.55, green: 0.0, blue: 0.0)

    /// Militärgrün - Stempel "EHRLICH", Erfolg
    static let accentSuccess = Color(red: 0.18, green: 0.35, blue: 0.15)

    // MARK: Textfarben

    /// Haupttext - Helles Grau
    static let textPrimary = Color(red: 0.88, green: 0.88, blue: 0.88)

    /// Gedämpfter Text
    static let textMuted = Color(red: 0.42, green: 0.42, blue: 0.42)

    /// Schreibmaschinen-Text - Vergilbtes Weiß
    static let textTypewriter = Color(red: 0.77, green: 0.73, blue: 0.60)

    /// Text auf dunklem Button
    static let textOnDark = Color(red: 0.04, green: 0.04, blue: 0.04)

    // MARK: Gradienten

    /// Hauptgradient - Verhörraum-Atmosphäre
    static let gradient = LinearGradient(
        colors: [
            backgroundDark,
            backgroundMid,
            Color(red: 0.06, green: 0.06, blue: 0.04)
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    /// Akzent-Gradient - Für Buttons und Highlights
    static let accentGradient = LinearGradient(
        colors: [
            accentGreen,
            Color(red: 0.15, green: 0.75, blue: 0.05)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Gefahr-Gradient - Für negative Ergebnisse
    static let dangerGradient = LinearGradient(
        colors: [
            Color(red: 0.6, green: 0.1, blue: 0.1),
            accentDanger
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: Legacy Support (für bestehende Views)
    static let accent = accentGreen
    static let textAccent = textOnDark
}

// MARK: - Animated Background: "Polygraph Monitor"
struct QuestionsBackgroundView: View {
    var stressLevel: CGFloat = 0.0
    private let ecgAnimationName = "Heartbeat _ ECG _ Loader"

    var body: some View {
        ZStack {
            // Basis: Dunkler Gradient
            QuestionsTheme.gradient
                .ignoresSafeArea()

            // Subtile Vignette für Tiefe
            RadialGradient(
                colors: [
                    Color.clear,
                    Color.black.opacity(0.4)
                ],
                center: .center,
                startRadius: UIScreen.main.bounds.width * 0.3,
                endRadius: UIScreen.main.bounds.width * 0.8
            )
            .ignoresSafeArea()

            // Subtiles Rauschen/Körnung für analogen Look
            Rectangle()
                .fill(Color.white.opacity(0.015))
                .ignoresSafeArea()

            // EKG-Linien-Loop (jetzt in Grün getönt durch Blend)
            LottieView(
                filename: ecgAnimationName,
                loopMode: .loop,
                isPlaying: true,
                contentMode: .scaleAspectFill
            )
            .opacity(0.08 + (0.12 * stressLevel))
            .blendMode(.screen)
            .scaleEffect(1.1)
            .blur(radius: 0.3)
            .allowsHitTesting(false)
            // Grün-Tönung
            .colorMultiply(QuestionsTheme.accentGreen.opacity(0.7))
            .animation(.easeInOut(duration: 0.6), value: stressLevel)

            // Intensiveres EKG bei hohem Stress
            if stressLevel > 0.5 {
                LottieView(
                    filename: ecgAnimationName,
                    loopMode: .loop,
                    isPlaying: true,
                    contentMode: .scaleAspectFill
                )
                .opacity(0.15 * stressLevel)
                .blendMode(.screen)
                .scaleEffect(1.2)
                .blur(radius: 1.0)
                .allowsHitTesting(false)
                .colorMultiply(QuestionsTheme.accentGreen)
            }

            // Scan-Linien-Effekt (CRT-Monitor-Look)
            ScanLinesOverlay()
                .opacity(0.03)
                .allowsHitTesting(false)
        }
    }
}

// MARK: - CRT Scan Lines Overlay
struct ScanLinesOverlay: View {
    var body: some View {
        GeometryReader { geo in
            Canvas { context, size in
                let lineSpacing: CGFloat = 3
                var y: CGFloat = 0

                while y < size.height {
                    let rect = CGRect(x: 0, y: y, width: size.width, height: 1)
                    context.fill(Path(rect), with: .color(.black))
                    y += lineSpacing
                }
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Shared Style Constants
enum QuestionsStyle {
    static let backgroundGradient = QuestionsTheme.gradient

    // Container-Stil: Dunkles Glas mit grünem Schimmer
    static let containerBackground = Color.black.opacity(0.4)
    static let rowBackground = Color.black.opacity(0.3)
    static let cardStroke = QuestionsTheme.accentGreen.opacity(0.15)
    static let containerCornerRadius: CGFloat = 12  // Kantiger für Tech-Look
    static let rowCornerRadius: CGFloat = 8
    static let padding: CGFloat = 20
    static let mutedText = QuestionsTheme.textMuted

    // Button-Gradient: Grün-Akzent
    static let primaryGradient = QuestionsTheme.accentGradient

    static let buttonGradient = LinearGradient(
        colors: [
            QuestionsTheme.accentGreen,
            Color(red: 0.18, green: 0.80, blue: 0.08)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Sekundärer Button (weniger prominent)
    static let secondaryButtonBackground = Color.white.opacity(0.08)
    static let secondaryButtonStroke = QuestionsTheme.accentGreen.opacity(0.3)
}

// MARK: - Stempel-Komponente für Results
struct StampView: View {
    let text: String
    let type: StampType
    let rotation: Double

    enum StampType {
        case guilty      // LÜGNER - Rot
        case innocent    // EHRLICH - Grün
        case escaped     // ENTKOMMEN - Bernstein

        var color: Color {
            switch self {
            case .guilty: return QuestionsTheme.accentDanger
            case .innocent: return QuestionsTheme.accentSuccess
            case .escaped: return QuestionsTheme.accentAmber
            }
        }

        var borderColor: Color {
            switch self {
            case .guilty: return Color(red: 0.7, green: 0.1, blue: 0.1)
            case .innocent: return Color(red: 0.25, green: 0.5, blue: 0.2)
            case .escaped: return Color(red: 0.85, green: 0.6, blue: 0.0)
            }
        }
    }

    var body: some View {
        ZStack {
            // Äußerer Rahmen
            RoundedRectangle(cornerRadius: 4)
                .stroke(type.borderColor, lineWidth: 4)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(type.color.opacity(0.15))
                )

            // Innerer Rahmen
            RoundedRectangle(cornerRadius: 2)
                .stroke(type.color, lineWidth: 2)
                .padding(6)

            // Text
            Text(text)
                .font(.system(size: 32, weight: .black, design: .monospaced))
                .tracking(4)
                .foregroundStyle(type.color)

            // Textur-Overlay für "abgenutzt"-Look
            RoundedRectangle(cornerRadius: 4)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.05),
                            Color.clear,
                            Color.black.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .frame(width: 220, height: 70)
        .rotationEffect(.degrees(rotation))
        .shadow(color: type.color.opacity(0.5), radius: 8, x: 0, y: 4)
        .shadow(color: Color.black.opacity(0.5), radius: 4, x: 2, y: 2)
    }
}

// MARK: - Typewriter Text Effect
struct TypewriterText: View {
    let fullText: String
    let onComplete: (() -> Void)?

    @State private var displayedText = ""
    @State private var currentIndex = 0

    init(_ text: String, onComplete: (() -> Void)? = nil) {
        self.fullText = text
        self.onComplete = onComplete
    }

    var body: some View {
        Text(displayedText + (currentIndex < fullText.count ? "▌" : ""))
            .font(.system(size: 28, weight: .bold, design: .monospaced))
            .foregroundStyle(QuestionsTheme.textTypewriter)
            .onAppear {
                typeNextCharacter()
            }
    }

    private func typeNextCharacter() {
        guard currentIndex < fullText.count else {
            onComplete?()
            return
        }

        let index = fullText.index(fullText.startIndex, offsetBy: currentIndex)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            displayedText += String(fullText[index])
            currentIndex += 1

            // Haptik für jeden Buchstaben
            UISelectionFeedbackGenerator().selectionChanged()

            typeNextCharacter()
        }
    }
}

// MARK: - Screen Shake Modifier
struct QuestionsShakeEffect: GeometryEffect {
    var amount: CGFloat = 10
    var shakesPerUnit: CGFloat = 3
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        let translation = amount * sin(animatableData * .pi * shakesPerUnit)
        return ProjectionTransform(CGAffineTransform(translationX: translation, y: 0))
    }
}

extension View {
    func shake(trigger: Bool, intensity: CGFloat = 10) -> some View {
        self.modifier(QuestionsShakeEffect(amount: intensity, animatableData: trigger ? 1 : 0))
    }
}

// MARK: - Preview
#Preview("Theme Colors") {
    VStack(spacing: 20) {
        QuestionsBackgroundView(stressLevel: 0.7)
            .overlay(
                VStack(spacing: 16) {
                    Text("VERHÖRRAUM")
                        .font(.largeTitle.bold())
                        .foregroundStyle(QuestionsTheme.textPrimary)

                    Text("Lügendetektor aktiv")
                        .font(.subheadline)
                        .foregroundStyle(QuestionsTheme.accentGreen)

                    StampView(text: "LÜGNER", type: .guilty, rotation: -12)
                        .padding(.top, 40)

                    StampView(text: "EHRLICH", type: .innocent, rotation: -8)

                    StampView(text: "ENTKOMMEN", type: .escaped, rotation: -15)
                }
            )
    }
}
