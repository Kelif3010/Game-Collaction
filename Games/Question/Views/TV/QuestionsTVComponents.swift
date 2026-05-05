//
//  QuestionsTVComponents.swift
//  Games Collection
//
//  Cinematic Reveal + Header
//

import SwiftUI

// MARK: - Cinematic Reveal (Stempel-Animation)

struct TVCinematicRevealView: View {
    @ObservedObject var viewModel: QuestionsGameViewModel
    @Environment(\.tvScale) private var tvScale
    @State private var stampScale: CGFloat = 2.0
    @State private var stampOpacity: Double = 0
    @State private var stampRotation: Double = -20
    @State private var flashOpacity: Double = 0
    @State private var shakeOffset: CGFloat = 0

    private var evaluation: QuestionsVoteEvaluation? {
        viewModel.revealEvaluation ?? viewModel.lastRevealEvaluation
    }

    private var citizensWon: Bool {
        evaluation?.citizensWon ?? false
    }

    var body: some View {
        ZStack {
            // Dunkler Overlay mit Farbton
            LinearGradient(
                colors: [
                    Color.black.opacity(0.95),
                    citizensWon
                        ? QuestionsTheme.accentSuccess.opacity(0.3)
                        : QuestionsTheme.accentDanger.opacity(0.3)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Vignette
            RadialGradient(
                colors: [Color.clear, Color.black.opacity(0.6)],
                center: .center,
                startRadius: scaled(100),
                endRadius: scaled(500)
            )
            .ignoresSafeArea()

            // Content
            VStack(spacing: scaled(30)) {
                Text("AKTE GEÖFFNET")
                    .font(.system(size: scaled(24), weight: .bold, design: .monospaced))
                    .foregroundStyle(QuestionsTheme.accentGreen)
                    .tracking(scaled(8))

                dossierBox

                StampView(
                    text: citizensWon ? "LÜGNER" : "ENTKOMMEN",
                    type: citizensWon ? .guilty : .escaped,
                    rotation: stampRotation
                )
                .scaleEffect(stampScale * tvScale)
                .opacity(stampOpacity)
                .offset(x: shakeOffset)
            }

            // Flash
            Rectangle()
                .fill(Color.white)
                .opacity(flashOpacity)
                .ignoresSafeArea()
        }
        .onAppear {
            runAnimation()
        }
    }

    private var dossierBox: some View {
        RoundedRectangle(cornerRadius: scaled(12))
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 0.10, green: 0.08, blue: 0.06),
                        Color(red: 0.06, green: 0.05, blue: 0.03)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: scaled(500), height: scaled(120))
            .overlay(
                RoundedRectangle(cornerRadius: scaled(12))
                    .stroke(QuestionsTheme.accentGreen.opacity(0.3), lineWidth: scaled(1))
            )
            .overlay(
                VStack(spacing: scaled(8)) {
                    Text("IDENTITÄT VERIFIZIERT")
                        .font(.system(size: scaled(14), weight: .medium, design: .monospaced))
                        .foregroundStyle(QuestionsTheme.textMuted)
                        .tracking(scaled(3))

                    Text(targetLine)
                        .font(.system(size: scaled(28), weight: .bold, design: .monospaced))
                        .foregroundStyle(QuestionsTheme.textTypewriter)
                }
            )
    }

    private var targetLine: String {
        let names = evaluation?.liars.map { viewModel.playerName(for: $0) } ?? []
        if names.isEmpty { return "UNBEKANNT" }
        return names.sorted().joined(separator: " • ").uppercased()
    }

    private func runAnimation() {
        withAnimation(.easeOut(duration: 0.15)) { flashOpacity = 0.6 }
        withAnimation(.easeIn(duration: 0.3).delay(0.15)) { flashOpacity = 0 }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.4)) {
                stampScale = 1.0
                stampOpacity = 1.0
                stampRotation = citizensWon ? -12 : -8
            }
            withAnimation(.easeOut(duration: 0.05)) { shakeOffset = 15 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                withAnimation(.easeOut(duration: 0.05)) { shakeOffset = -12 }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeOut(duration: 0.1)) { shakeOffset = 0 }
            }
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
    }

    private func scaled(_ value: CGFloat) -> CGFloat { value * tvScale }
}

// MARK: - Header

struct TVHeaderView: View {
    @ObservedObject var viewModel: QuestionsGameViewModel
    @Environment(\.tvScale) private var tvScale

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: scaled(6)) {
                Text("LÜGENDETEKTOR")
                    .font(.system(size: scaled(18), weight: .bold, design: .monospaced))
                    .foregroundStyle(QuestionsTheme.accentGreen)
                    .tracking(scaled(4))

                if let category = viewModel.selectedCategory {
                    Text(category.name.uppercased())
                        .font(.system(size: scaled(28), weight: .bold, design: .monospaced))
                        .foregroundStyle(QuestionsTheme.textTypewriter)
                }
            }

            Spacer()

            if viewModel.discussionTime > 0 &&
                (viewModel.currentPhase == .overview || viewModel.currentPhase == .voting) {
                timerDisplay
            }
        }
    }

    private var timerDisplay: some View {
        HStack(spacing: scaled(12)) {
            Circle()
                .fill(timerColor)
                .frame(width: scaled(12), height: scaled(12))
                .shadow(color: timerColor, radius: scaled(6))

            Text("VERBLEIBEND")
                .font(.system(size: scaled(14), weight: .medium, design: .monospaced))
                .foregroundStyle(QuestionsTheme.textMuted)
                .tracking(scaled(2))

            Text(viewModel.timeString(from: viewModel.timeRemaining))
                .font(.system(size: scaled(48), weight: .bold, design: .monospaced))
                .foregroundStyle(timerColor)
                .monospacedDigit()
        }
        .padding(.horizontal, scaled(24))
        .padding(.vertical, scaled(12))
        .background(
            RoundedRectangle(cornerRadius: scaled(12))
                .fill(Color.black.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: scaled(12))
                        .stroke(timerColor.opacity(0.3), lineWidth: scaled(1))
                )
        )
    }

    private var timerColor: Color {
        if viewModel.timeRemaining < 10 { return QuestionsTheme.accentDanger }
        if viewModel.timeRemaining < 30 { return QuestionsTheme.accentAmber }
        return QuestionsTheme.accentGreen
    }

    private func scaled(_ value: CGFloat) -> CGFloat { value * tvScale }
}
