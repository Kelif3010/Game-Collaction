import SwiftUI
import StoreKit
import Foundation
import Pow
import SFSafeSymbols

struct ResultView: View {
    let result: GameResult
    @Environment(AppViewModel.self) private var appModel

    var onRestart: () -> Void
    var onNewChallenge: () -> Void

    @State private var currentScores: [UUID: Int] = [:]
    @Namespace private var leaderboardNamespace
    @Environment(\.requestReview) var requestReview

    @State private var showRestartAlert = false
    @State private var showOutcome = false
    @State private var showLeaderboard = false
    @State private var jackpotPulse = false
    @State private var outcomeEffectTrigger = 0

    /// Normiert den Top-Score auf 0.6–1.0 — höherer Score = intensiverer Geldregen
    private var winIntensity: CGFloat {
        let topScore = result.leaderboard.map(\.score).max() ?? 0
        guard topScore > 0 else { return 0.8 }
        return min(1.0, 0.6 + CGFloat(topScore) / 50.0)
    }

    private var animatedLeaderboard: [LeaderboardEntry] {
        result.leaderboard.sorted { lhs, rhs in
            let scoreL = currentScores[lhs.id, default: 0]
            let scoreR = currentScores[rhs.id, default: 0]

            if scoreL != scoreR {
                return scoreL > scoreR
            }
            return lhs.name < rhs.name
        }
    }

    private var topAnimatedScore: Int {
        guard let leaderID = animatedLeaderboard.first?.id else { return 0 }
        return currentScores[leaderID, default: 0]
    }

    var body: some View {
        ZStack {
            BetBuddyBackgroundView(intensity: 1.0)

            // Lottie Money Rain fuer Win-Momente
            if result.outcome == .win {
                MoneyRainLottieView(intensity: winIntensity)
            }

            VStack(spacing: 0) {
                topBar
                    .padding(.bottom, 20)

                // Outcome Banner
                outcomeBanner
                    .padding(.bottom, 20)
                    .scaleEffect(showOutcome ? 1.0 : (result.outcome == .win ? 0.5 : 0.85))
                    .opacity(showOutcome ? 1.0 : 0)
                    .shadow(
                        color: result.outcome == .win
                            ? BetBuddyTheme.accentGold.opacity(jackpotPulse ? 0.6 : 0.0)
                            : Color.clear,
                        radius: jackpotPulse ? 20 : 0
                    )
                    .changeEffect(.spray(origin: .center) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(BetBuddyTheme.accentGold)
                    }, value: outcomeEffectTrigger, isEnabled: result.outcome == .win)
                    .changeEffect(.shake, value: outcomeEffectTrigger, isEnabled: result.outcome == .lose)

                // Score Display
                scoreDisplay
                    .padding(.bottom, 16)
                    .changeEffect(.jump(height: 12), value: topAnimatedScore, isEnabled: topAnimatedScore > 0)

                // Challenge Text
                challengeText
                    .padding(.bottom, 20)

                // Leaderboard
                leaderboardView
                    .padding(.horizontal)
                    .opacity(showLeaderboard ? 1.0 : 0)
                    .offset(y: showLeaderboard ? 0 : 20)

                Spacer()

                // Action Buttons
                actionButtons
                    .padding(.top, 16)
            }
            .padding(Theme.padding)
        }
        .toolbar(.hidden, for: .navigationBar)
        .alert("Neu starten", isPresented: $showRestartAlert) {
            Button("Abbrechen", role: .cancel) { }
            Button("Alles löschen", role: .destructive) {
                appModel.resetSessionScores()
                onRestart()
            }
            Button("Punkte behalten") {
                onRestart()
            }
        } message: {
            Text("Möchtest du die Punkte behalten oder alles auf 0 setzen?")
        }
        .sensoryFeedback(trigger: outcomeEffectTrigger) {
            guard HapticsService.isEnabled, outcomeEffectTrigger > 0 else { return nil }
            return result.outcome == .win ? .success : .warning
        }
        .onAppear {
            startRaceAnimation()
            recordStats()
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(200))
                if result.outcome == .win {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.45)) {
                        showOutcome = true
                    }
                    outcomeEffectTrigger += 1
                    try? await Task.sleep(for: .milliseconds(500))
                    withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                        jackpotPulse = true
                    }
                } else {
                    withAnimation(.easeIn(duration: 0.22)) {
                        showOutcome = true
                    }
                    outcomeEffectTrigger += 1
                }

                try? await Task.sleep(for: .milliseconds(300))
                withAnimation(.easeOut(duration: 0.5)) {
                    showLeaderboard = true
                }

                try? await Task.sleep(for: .seconds(1))
                requestReview()
            }
        }
    }

    // MARK: - Top Bar
    private var topBar: some View {
        HStack {
            // Results Title
            HStack(spacing: 8) {
                Image(systemName: result.outcome == .win ? "crown.fill" : "xmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(result.outcome == .win ? BetBuddyTheme.accentGold : BetBuddyTheme.accentRuby)

                Text("RESULTS")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(BetBuddyTheme.textGold)
                    .tracking(2)
            }

            Spacer()

            Button {
                onRestart()
            } label: {
                Image(systemName: "xmark")
                    .font(.headline.bold())
                    .foregroundStyle(BetBuddyTheme.textChampagne)
                    .frame(width: 44, height: 44)
                    .modifier(GlassCircleButtonBackground())
            }
        }
    }

    // MARK: - Outcome Banner
    private var outcomeBanner: some View {
        HStack(spacing: 12) {
            if result.outcome == .win {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(BetBuddyTheme.accentGold)

                Text("JACKPOT!")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(BetBuddyTheme.accentGold)
                    .tracking(2)

                Image(systemName: "trophy.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(BetBuddyTheme.accentGold)
            } else {
                Image(systemName: "hand.thumbsdown.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(BetBuddyTheme.accentRuby)

                Text("BUST")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(BetBuddyTheme.accentRuby)
                    .tracking(2)

                Image(systemName: "hand.thumbsdown.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(BetBuddyTheme.accentRuby)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
        .background(
            Capsule()
                .fill(
                    result.outcome == .win
                        ? BetBuddyTheme.accentGold.opacity(0.15)
                        : BetBuddyTheme.accentRuby.opacity(0.15)
                )
                .overlay(
                    Capsule()
                        .stroke(
                            result.outcome == .win
                                ? BetBuddyTheme.accentGold.opacity(0.4)
                                : BetBuddyTheme.accentRuby.opacity(0.4),
                            lineWidth: 2
                        )
                )
        )
        .shadow(
            color: result.outcome == .win
                ? BetBuddyTheme.accentGold.opacity(0.3)
                : BetBuddyTheme.accentRuby.opacity(0.2),
            radius: 12
        )
    }

    // MARK: - Score Display
    private var scoreDisplay: some View {
        let displayColor = result.outcome == .win ? BetBuddyTheme.accentGold : BetBuddyTheme.accentRuby

        return Group {
            if result.inputType == .alphabet {
                LetterFlipView(
                    value: topAnimatedScore,
                    color: displayColor
                )
                .id(animatedLeaderboard.first?.id)
            } else {
                FlipCounterView(
                    value: topAnimatedScore,
                    color: displayColor
                )
                .id(animatedLeaderboard.first?.id)
            }
        }
    }

    // MARK: - Challenge Text
    private var challengeText: some View {
        Text(result.challengeText)
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(BetBuddyTheme.textChampagne)
            .multilineTextAlignment(.center)
            .lineSpacing(2)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(BetBuddyTheme.accentGold.opacity(0.1), lineWidth: 1)
                    )
            )
    }

    // MARK: - Leaderboard
    private var leaderboardView: some View {
        VStack(spacing: 8) {
            // Header
            HStack {
                Text("RANGLISTE")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(BetBuddyTheme.textSilver)
                    .tracking(2)

                Spacer()

                Text("PUNKTE")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(BetBuddyTheme.textSilver)
                    .tracking(1)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 4)

            // Entries
            ForEach(Array(animatedLeaderboard.enumerated()), id: \.element.id) { index, entry in
                LeaderboardRowView(
                    index: index,
                    entry: entry,
                    currentScore: currentScores[entry.id, default: 0],
                    namespace: leaderboardNamespace
                )
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: animatedLeaderboard)
    }

    // MARK: - Action Buttons
    private var actionButtons: some View {
        HStack(spacing: 12) {
            // Restart Button
            Button {
                HapticsService.impact(.medium)
                showRestartAlert = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 14, weight: .bold))
                    Text("Neustart")
                        .font(.system(size: 15, weight: .bold))
                }
                .foregroundStyle(BetBuddyTheme.textChampagne)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.08))
                        .overlay(
                            Capsule()
                                .stroke(BetBuddyTheme.accentGold.opacity(0.2), lineWidth: 1)
                        )
                )
            }

            // New Challenge Button
            Button {
                HapticsService.impact(.light)
                onNewChallenge()
            } label: {
                HStack(spacing: 8) {
                    Text("Nächste Runde")
                        .font(.system(size: 15, weight: .bold))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .bold))
                }
                .foregroundStyle(BetBuddyTheme.textOnLight)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    Capsule()
                        .fill(BetBuddyTheme.goldGradient)
                        .shadow(color: BetBuddyTheme.accentGold.opacity(0.4), radius: 10, y: 4)
                )
                .overlay(
                    Capsule()
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.3), Color.clear],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1
                        )
                )
            }
        }
    }

    // MARK: - Helper Functions
    private func recordStats() {
        let sorted = result.leaderboard.sorted { $0.score > $1.score }
        guard let topScore = sorted.first?.score, topScore > 0 else { return }

        let winners = sorted.filter { $0.score == topScore }
        let others = sorted.filter { $0.score < topScore }

        for winner in winners {
            GlobalStatsManager.shared.recordWin(for: winner.name)
        }
        for player in others {
            GlobalStatsManager.shared.recordParticipation(for: player.name)
        }
    }

    @MainActor
    private func startRaceAnimation() {
        for entry in result.leaderboard {
            currentScores[entry.id] = 0
        }

        Task { @MainActor in
            while true {
                var allDone = true
                for entry in result.leaderboard {
                    let current = currentScores[entry.id, default: 0]
                    let target = entry.score
                    if current < target {
                        let step = max(1, (target - current) / 8)
                        currentScores[entry.id] = min(current + step, target)
                        allDone = false
                    }
                }

                if allDone {
                    break
                }

                try? await Task.sleep(for: .milliseconds(50))
            }
        }
    }
}

// MARK: - Leaderboard Row
struct LeaderboardRowView: View {
    let index: Int
    let entry: LeaderboardEntry
    let currentScore: Int
    let namespace: Namespace.ID

    private var displayName: String {
        NSLocalizedString(entry.name, comment: "")
    }

    private var rankColor: Color {
        switch index {
        case 0: return BetBuddyTheme.accentGold
        case 1: return Color(red: 0.75, green: 0.75, blue: 0.78)
        case 2: return Color(red: 0.80, green: 0.55, blue: 0.25)
        default: return BetBuddyTheme.textSilver.opacity(0.5)
        }
    }

    private var rankIcon: String {
        switch index {
        case 0: return "crown.fill"
        case 1: return "medal.fill"
        case 2: return "medal.fill"
        default: return "circle.fill"
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // Rank Badge
            ZStack {
                if index < 3 {
                    Circle()
                        .fill(rankColor.opacity(0.2))
                        .frame(width: 32, height: 32)

                    Image(systemName: rankIcon)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(rankColor)
                } else {
                    Text("\(index + 1)")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(BetBuddyTheme.textSilver)
                        .frame(width: 32, height: 32)
                }
            }

            // Team Chip
            ZStack {
                Circle()
                    .fill(entry.color.primary)
                    .frame(width: 38, height: 38)

                Circle()
                    .stroke(Color.white.opacity(0.3), lineWidth: 2)
                    .frame(width: 38, height: 38)

                Text(String(displayName.prefix(1)))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
            }

            // Team Name
            Text(displayName)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(BetBuddyTheme.textChampagne)
                .lineLimit(1)

            Spacer()

            // Score with Chip Icon
            HStack(spacing: 6) {
                Text("\(currentScore)")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(index == 0 ? BetBuddyTheme.accentGold : BetBuddyTheme.textChampagne)
                    .contentTransition(.numericText())

                Image(systemName: "circle.fill")
                    .font(.system(size: 8))
                    .foregroundStyle(rankColor.opacity(0.6))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(index == 0 ? BetBuddyTheme.accentGold.opacity(0.1) : Color.black.opacity(0.3))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(
                    index == 0 ? BetBuddyTheme.accentGold.opacity(0.4) : BetBuddyTheme.accentGold.opacity(0.08),
                    lineWidth: index == 0 ? 2 : 1
                )
        )
        .shadow(
            color: index == 0 ? BetBuddyTheme.accentGold.opacity(0.15) : Color.clear,
            radius: 8
        )
        .matchedGeometryEffect(id: entry.id, in: namespace)
    }
}

// MARK: - Money Rain Lottie Animation
struct MoneyRainLottieView: View {
    /// 0.0 – 1.0: skaliert Sichtbarkeit und Geschwindigkeit der Geldanimation
    var intensity: CGFloat = 1.0

    var body: some View {
        BetBuddyLottieView(
            filename: "Money rain",
            loopMode: .loop,
            isPlaying: true,
            contentMode: .scaleAspectFill,
            animationSpeed: 0.7 + (intensity * 0.5)
        )
        .opacity(0.6 + (intensity * 0.4))
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

#Preview {
    ResultView(
        result: GameResult(
            outcome: .win,
            finalScore: 10,
            challengeText: "How many cities in Italy?",
            inputType: .numeric,
            leaderboard: [
                LeaderboardEntry(groupId: UUID(), name: "Team Blue", color: .blue, score: 20),
                LeaderboardEntry(groupId: UUID(), name: "Team Red", color: .red, score: 15)
            ]
        ),
        onRestart: {},
        onNewChallenge: {}
    )
    .environment(AppViewModel())
}
