import SwiftUI
import StoreKit
import Foundation

struct ResultView: View {
    let result: GameResult
    @EnvironmentObject private var appModel: AppViewModel

    var onRestart: () -> Void
    var onNewChallenge: () -> Void

    @State private var currentScores: [UUID: Int] = [:]
    @Namespace private var leaderboardNamespace
    @Environment(\.requestReview) var requestReview

    @State private var showRestartAlert = false
    @State private var showOutcome = false
    @State private var showLeaderboard = false

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

    var body: some View {
        ZStack {
            BetBuddyBackgroundView(intensity: 1.0)

            // Casino Chip Rain (Win) or Subtle Rain (Lose)
            if result.outcome == .win {
                CasinoChipRainView()
            } else {
                ParticleEffectView(type: .rain)
            }

            VStack(spacing: 0) {
                topBar
                    .padding(.bottom, 20)

                // Outcome Banner
                outcomeBanner
                    .padding(.bottom, 20)
                    .scaleEffect(showOutcome ? 1.0 : 0.5)
                    .opacity(showOutcome ? 1.0 : 0)

                // Score Display
                scoreDisplay
                    .padding(.bottom, 16)

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
        .onAppear {
            // Staggered animations
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.2)) {
                showOutcome = true
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.5)) {
                showLeaderboard = true
            }

            startRaceAnimation()
            recordStats()

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
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
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.08))
                            .overlay(
                                Circle()
                                    .stroke(BetBuddyTheme.accentGold.opacity(0.2), lineWidth: 1)
                            )
                    )
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
        let topScore = currentScores[animatedLeaderboard.first?.id ?? UUID()] ?? 0
        let displayColor = result.outcome == .win ? BetBuddyTheme.accentGold : BetBuddyTheme.accentRuby

        return Group {
            if result.inputType == .alphabet {
                LetterFlipView(
                    value: topScore,
                    color: displayColor
                )
                .id(animatedLeaderboard.first?.id)
            } else {
                FlipCounterView(
                    value: topScore,
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

    private func startRaceAnimation() {
        for entry in result.leaderboard {
            currentScores[entry.id] = 0
        }

        Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { timer in
            var allDone = true

            for entry in result.leaderboard {
                let current = currentScores[entry.id, default: 0]
                let target = entry.score

                if current < target {
                    let step = max(1, (target - current) / 12)
                    currentScores[entry.id] = current + step
                    allDone = false
                }
            }

            if allDone {
                timer.invalidate()
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
        default: return ""
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

// MARK: - Casino Chip Rain
struct CasinoChipRainView: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(0..<30, id: \.self) { index in
                    CasinoChipParticle(screenSize: geometry.size, index: index)
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

struct CasinoChipParticle: View {
    let screenSize: CGSize
    let index: Int

    @State private var position: CGPoint = .zero
    @State private var rotation: Double = 0
    @State private var opacity: Double = 0

    private let chipColors: [Color] = [
        BetBuddyTheme.accentGold,
        BetBuddyTheme.accentEmerald,
        BetBuddyTheme.accentRuby,
        Color(red: 0.2, green: 0.4, blue: 0.8),
        Color.purple
    ]

    private var chipColor: Color {
        chipColors[index % chipColors.count]
    }

    private var size: CGFloat {
        CGFloat.random(in: 20...35)
    }

    private var delay: Double {
        Double(index) * 0.1
    }

    private var duration: Double {
        Double.random(in: 3.0...5.0)
    }

    var body: some View {
        ZStack {
            // Chip base
            Circle()
                .fill(
                    LinearGradient(
                        colors: [chipColor, chipColor.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // Chip ring
            Circle()
                .stroke(Color.white.opacity(0.4), lineWidth: 2)

            // Inner detail
            Circle()
                .stroke(chipColor.opacity(0.5), lineWidth: 1)
                .padding(4)
        }
        .frame(width: size, height: size)
        .rotation3DEffect(.degrees(rotation), axis: (x: 1, y: 0.5, z: 0))
        .position(position)
        .opacity(opacity)
        .onAppear {
            let startX = CGFloat.random(in: 0...screenSize.width)
            position = CGPoint(x: startX, y: -50)
            opacity = 1.0

            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.linear(duration: duration).repeatForever(autoreverses: false)) {
                    position.y = screenSize.height + 100
                    position.x += CGFloat.random(in: -50...50)
                }

                withAnimation(.linear(duration: 0.5).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            }
        }
    }
}

struct ParticleEffectView: View {
    enum EffectType {
        case confetti
        case rain
    }
    
    let type: EffectType
    
    private var particleCount: Int {
        type == .rain ? 200 : 50
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(0..<particleCount, id: \.self) { index in
                    Particle(type: type, screenSize: geometry.size)
                        .id("\(geometry.size.width)-\(index)")
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

struct Particle: View {
    let type: ParticleEffectView.EffectType
    let screenSize: CGSize
    
    @State private var position: CGPoint = CGPoint(x: -100, y: -100)
    @State private var opacity: Double = 0
    @State private var rotation: Double = 0
    @State private var scale: CGFloat = 1.0
    
    let speed: Double
    let size: CGFloat
    let color: Color
    let delay: Double
    
    init(type: ParticleEffectView.EffectType, screenSize: CGSize) {
        self.type = type
        self.screenSize = screenSize
        self.delay = Double.random(in: 0...2.0)
        
        if type == .confetti {
            self.speed = Double.random(in: 2.0...5.0)
            self.size = CGFloat.random(in: 6...12)
            self.color = [Color.red, .blue, .green, .yellow, .pink, .purple, .cyan].randomElement()!
        } else {
            self.speed = Double.random(in: 0.8...1.6)
            self.size = CGFloat.random(in: 20...40)
            self.color = Color.white.opacity(Double.random(in: 0.1...0.4))
        }
    }
    
    var body: some View {
        Group {
            if type == .confetti {
                if Bool.random() {
                    Circle().fill(color)
                } else {
                    Rectangle().fill(color)
                }
            } else {
                Rectangle()
                    .fill(LinearGradient(
                        colors: [color.opacity(0), color],
                        startPoint: .top,
                        endPoint: .bottom
                    ))
                    .frame(width: 2, height: size)
            }
        }
        .frame(width: type == .confetti ? size : 2, height: size)
        .scaleEffect(type == .rain ? scale : 1.0)
        .position(position)
        .opacity(opacity)
        .rotationEffect(.degrees(rotation))
        .onAppear {
            configureAndAnimate()
        }
    }
    
    private func configureAndAnimate() {
        opacity = 1.0
        if type == .rain {
            scale = CGFloat.random(in: 0.5...1.0)
            rotation = 10
        }
        
        let safePadding: CGFloat = 100
        let minX = -safePadding
        let maxX = screenSize.width + safePadding
        
        let startX = Double.random(in: minX...maxX)
        let startY = Double.random(in: -200 ... -50)
        
        position = CGPoint(x: startX, y: startY)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            withAnimation(
                .linear(duration: speed)
                .repeatForever(autoreverses: false)
            ) {
                let endY = screenSize.height + 100
                let xOffset = type == .rain ? CGFloat(tan(10 * .pi / 180) * endY) : 0
                
                position.y = endY
                position.x += xOffset
                
                if type == .confetti {
                    rotation = Double.random(in: 0...360)
                }
            }
            
            if type == .confetti {
                withAnimation(
                    .easeInOut(duration: Double.random(in: 1...3))
                    .repeatForever(autoreverses: true)
                ) {
                    position.x += CGFloat.random(in: -30...30)
                }
            }
        }
    }
}
