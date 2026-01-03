import SwiftUI

struct ResultView: View {
    let result: GameResult
    var onRestart: () -> Void
    var onNewChallenge: () -> Void

    @State private var currentScores: [UUID: Int] = [:]
    @Namespace private var leaderboardNamespace

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
            Theme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // HEADER
                topBar
                    .padding(.bottom, 30)

                // ERGEBNIS & RANGLISTE
                VStack(spacing: 24) {
                    
                    // Score & Text des Gewinners
                    VStack(spacing: 16) {
                        let topScore = currentScores[animatedLeaderboard.first?.id ?? UUID()] ?? 0
                        
                        // ANPASSUNG: Zeige Buchstaben oder Zahlen
                        if result.inputType == .alphabet {
                            LetterFlipView(
                                value: topScore,
                                color: result.outcome == .win ? .purple : .red
                            )
                            .id(animatedLeaderboard.first?.id)
                        } else {
                            FlipCounterView(
                                value: topScore,
                                color: result.outcome == .win ? .purple : .red
                            )
                            .id(animatedLeaderboard.first?.id)
                        }
                        
                        Text(result.challengeText)
                            .foregroundStyle(.white)
                            .font(.headline.weight(.semibold))
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal)
                    }

                    // Rangliste
                    leaderboardView
                        .padding(.horizontal)
                }

                Spacer()

                // BUTTONS
                HStack(spacing: 12) {
                    Button {
                        onRestart()
                    } label: {
                        Text("Neu starten")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.white.opacity(0.12))
                            .clipShape(Capsule())
                    }

                    Button {
                        onNewChallenge()
                    } label: {
                        Text("Neue Challenge")
                            .font(.headline)
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.white)
                            .clipShape(Capsule())
                    }
                }
                .padding(.top, 20)
            }
            .padding(Theme.padding)
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            startRaceAnimation()
        }
    }

    private var topBar: some View {
        HStack {
            Text("Bet Buddy")
                .foregroundStyle(.white)
                .font(.headline)
            Spacer()
            Button {
                onRestart()
            } label: {
                Image(systemName: "xmark")
                    .font(.headline.bold())
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private var leaderboardView: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(Array(animatedLeaderboard.enumerated()), id: \.element.id) { index, entry in
                let currentScore = currentScores[entry.id, default: 0]
                
                HStack(spacing: 16) {
                    Text("\(index + 1).")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(rankColor(for: index))
                        .frame(width: 30, alignment: .leading)
                        .contentTransition(.numericText())

                    Circle()
                        .fill(entry.color.gradient)
                        .frame(width: 40, height: 40)
                        .overlay(
                            Text(entry.name.prefix(1))
                                .font(.headline.weight(.bold))
                                .foregroundStyle(.white)
                        )

                    Text(entry.name)
                        .foregroundStyle(.white)
                        .font(.subheadline.weight(.semibold))
                    
                    Spacer()
                    
                    Text("\(currentScore) Pkt")
                        .foregroundStyle(Theme.mutedText)
                        .font(.subheadline.weight(.medium))
                        .contentTransition(.numericText())
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(rankColor(for: index).opacity(index == 0 ? 0.5 : 0.0), lineWidth: 1)
                )
                .matchedGeometryEffect(id: entry.id, in: leaderboardNamespace)
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: animatedLeaderboard)
    }

    private func rankColor(for index: Int) -> Color {
        switch index {
        case 0: return Color(red: 1.0, green: 0.84, blue: 0.0)
        case 1: return Color(red: 0.75, green: 0.75, blue: 0.75)
        case 2: return Color(red: 0.8, green: 0.5, blue: 0.2)
        default: return Color.white.opacity(0.3)
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
