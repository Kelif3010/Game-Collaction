import SwiftUI

// MARK: - Game Over: Endergebnis + Sieger-Banner
struct FFGameOverView: View {
    @Environment(FFViewModel.self) private var viewModel
    @Environment(\.dismiss) private var dismiss

    @State private var appeared = false
    @State private var crownScale: CGFloat = 0
    @State private var showStats = false
    @State private var lightHaptic = false
    @State private var mediumHaptic = false

    private var sorted: [FFPlayer] { viewModel.sortedPlayers }
    private var winner: FFPlayer? { sorted.first }

    var body: some View {
        ZStack {
            FFBackground()

            // Violetter Confetti-Glow
            VStack {
                RadialGradient(
                    colors: [FFStyle.accentViolet.opacity(0.22), Color.clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: 280
                )
                .frame(height: 350)
                Spacer()
            }

            VStack(spacing: 0) {
                gameOverHeader
                    .padding(.horizontal, 20)
                    .padding(.top, 12)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 22) {
                        winnerBanner
                            .opacity(appeared ? 1 : 0)
                            .scaleEffect(appeared ? 1 : 0.92)

                        if showStats {
                            leaderboard
                                .transition(.opacity.combined(with: .move(edge: .bottom)))

                            statsHighlights
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }

                        Color.clear.frame(height: 130)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }

            // Aktions-Buttons unten
            VStack {
                Spacer()
                actionButtons
                    .padding(.bottom, 36)
                    .opacity(appeared ? 1 : 0)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .sensoryFeedback(.impact(weight: .light), trigger: lightHaptic)
        .sensoryFeedback(.impact(weight: .medium), trigger: mediumHaptic)
        .onAppear {
            withAnimation(.bouncy(duration: 0.6).delay(0.1)) {
                appeared = true
                crownScale = 1
            }
            withAnimation(.spring(duration: 0.5, bounce: 0.2).delay(0.7)) {
                showStats = true
            }
        }
    }

    // MARK: - Header
    private var gameOverHeader: some View {
        HStack {
            Spacer()

            Text("Spielende")
                .font(.system(size: 17, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            Spacer()
        }
    }

    // MARK: - Sieger-Banner
    private var winnerBanner: some View {
        VStack(spacing: 16) {
            // Krone
            ZStack {
                Circle()
                    .fill(FFStyle.accentGold.opacity(0.15))
                    .frame(width: 100, height: 100)
                    .shadow(color: FFStyle.accentGold.opacity(0.3), radius: 20)

                Circle()
                    .stroke(FFStyle.accentGold.opacity(0.3), lineWidth: 1.5)
                    .frame(width: 100, height: 100)

                Image(systemName: "crown.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [FFStyle.accentGold, FFStyle.accentGold.opacity(0.7)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: FFStyle.accentGold.opacity(0.5), radius: 12)
                    .scaleEffect(crownScale)
            }

            VStack(spacing: 6) {
                Text("Sieger")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundStyle(FFStyle.accentGold.opacity(0.8))
                    .tracking(2)

                Text(winner?.displayName ?? "")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                Text("\(winner?.score ?? 0) Punkte")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(FFStyle.accentGold)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: FFStyle.cornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [FFStyle.accentGold.opacity(0.1), FFStyle.backgroundCard],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: FFStyle.cornerRadius, style: .continuous)
                        .stroke(FFStyle.accentGold.opacity(0.35), lineWidth: 1.5)
                )
        )
    }

    // MARK: - Rangliste
    private var leaderboard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "list.number")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(FFStyle.accentViolet)
                Text("RANGLISTE")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(FFStyle.textMuted)
                    .tracking(1.5)
            }

            VStack(spacing: 8) {
                ForEach(Array(sorted.enumerated()), id: \.element.id) { idx, player in
                    leaderboardRow(player: player, rank: idx + 1)
                }
            }
        }
        .padding(16)
        .ffCard()
    }

    private func leaderboardRow(player: FFPlayer, rank: Int) -> some View {
        let isWinner = rank == 1
        let rankColor: Color = rank == 1 ? FFStyle.accentGold : (rank == 2 ? Color.gray : Color.gray.opacity(0.6))

        return HStack(spacing: 14) {
            // Rang-Badge
            ZStack {
                Circle()
                    .fill(isWinner ? FFStyle.accentGold.opacity(0.2) : Color.white.opacity(0.07))
                    .frame(width: 36, height: 36)
                if isWinner {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(FFStyle.accentGold)
                } else {
                    Text("\(rank)")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundStyle(rankColor)
                }
            }

            // Avatar-Initiale
            ZStack {
                Circle()
                    .fill(FFStyle.accentViolet.opacity(0.15))
                    .frame(width: 36, height: 36)
                Text(String(player.displayName.prefix(1).uppercased()))
                    .font(.system(size: 14, weight: .black))
                    .foregroundStyle(FFStyle.accentViolet)
            }

            Text(player.displayName)
                .font(.system(size: 15, weight: isWinner ? .black : .semibold))
                .foregroundStyle(isWinner ? .white : Color.white.opacity(0.85))

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(player.score) Pkt")
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(isWinner ? FFStyle.accentGold : .white)
                HStack(spacing: 4) {
                    if player.truthScore > 0 {
                        Text("🔍 \(player.truthScore / 2)×")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(Color.green.opacity(0.7))
                    }
                    if player.bluffSuccesses > 0 {
                        Text("🎭 \(player.bluffSuccesses)×")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(FFStyle.accentGold.opacity(0.7))
                    }
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isWinner ? FFStyle.accentGold.opacity(0.06) : Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isWinner ? FFStyle.accentGold.opacity(0.25) : Color.clear, lineWidth: 1)
                )
        )
    }

    // MARK: - Stat-Highlights
    private var statsHighlights: some View {
        let bestBluffer = viewModel.players.max(by: { $0.bluffSuccesses < $1.bluffSuccesses })
        let bestDetective = viewModel.players.max(by: { $0.truthScore < $1.truthScore })

        return VStack(spacing: 10) {
            if let bluffer = bestBluffer, bluffer.bluffSuccesses > 0 {
                statBadge(
                    icon: "theatermasks.fill",
                    color: FFStyle.accentGold,
                    title: "Bester Lügner",
                    name: bluffer.displayName,
                    detail: "\(bluffer.bluffSuccesses)× andere getäuscht"
                )
            }
            if let detective = bestDetective, detective.truthScore > 0 {
                statBadge(
                    icon: "magnifyingglass",
                    color: Color.cyan,
                    title: "Bester Detektiv",
                    name: detective.displayName,
                    detail: "\(detective.truthScore / 2)× Wahrheit gefunden"
                )
            }
        }
    }

    private func statBadge(icon: String, color: Color, title: String, name: String, detail: String) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.18))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title.uppercased())
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(FFStyle.textMuted)
                    .tracking(1.5)
                Text(name)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                Text(detail)
                    .font(.system(size: 12))
                    .foregroundStyle(FFStyle.textMuted)
            }
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .ffCard()
    }

    // MARK: - Aktions-Buttons
    private var actionButtons: some View {
        VStack(spacing: 12) {
            // Nochmal spielen
            Button {
                mediumHaptic.toggle()
                viewModel.restartGame()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 16, weight: .bold))
                    Text("Nochmal spielen")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                }
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    Capsule()
                        .fill(FFStyle.primaryGradient)
                        .shadow(color: FFStyle.accentViolet.opacity(0.5), radius: 16, y: 6)
                )
            }

            // Zur Übersicht
            Button {
                lightHaptic.toggle()
                viewModel.returnToSetup()
            } label: {
                Text("Zur Übersicht")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(FFStyle.textMuted)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.07))
                            .overlay(Capsule().stroke(Color.white.opacity(0.12), lineWidth: 1))
                    )
            }
        }
        .padding(.horizontal, 24)
    }
}

#Preview {
    FFGameOverView()
        .environment(FFViewModel.preview)
}
