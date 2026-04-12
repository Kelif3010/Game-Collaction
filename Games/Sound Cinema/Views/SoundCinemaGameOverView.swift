import SwiftUI

struct SoundCinemaGameOverView: View {
    @EnvironmentObject private var viewModel: SoundCinemaViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var appeared = false
    @State private var pulseCrown = false

    private var sortedPlayers: [SoundCinemaPlayer] {
        viewModel.players.sorted { lhs, rhs in
            // Aktive Spieler vor eliminierten
            if lhs.isEliminated != rhs.isEliminated { return !lhs.isEliminated }
            return lhs.score > rhs.score
        }
    }

    private var winner: SoundCinemaPlayer? {
        sortedPlayers.first
    }

    var body: some View {
        ZStack {
            SoundCinemaBackground()

            // Subtile Partikel-Welle im Hintergrund
            WaveformAnimation(isActive: true, progress: 1.0)
                .frame(height: 60)
                .opacity(0.15)
                .frame(maxHeight: .infinity, alignment: .center)
                .allowsHitTesting(false)

            VStack(spacing: 0) {
                // Header
                HStack {
                    Spacer()
                    Button {
                        viewModel.phase = .setup
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .modifier(GlassCircleButtonBackground())
                    }
                }
                .padding(.horizontal, SoundCinemaStyle.padding)
                .padding(.top, 12)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {

                        // Gewinner-Banner
                        winnerBanner
                            .opacity(appeared ? 1 : 0)
                            .scaleEffect(appeared ? 1 : 0.7)

                        // Rangliste
                        rankingSection
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 24)

                        // Buttons
                        buttonSection
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 32)

                        Color.clear.frame(height: 20)
                    }
                    .padding(.horizontal, SoundCinemaStyle.padding)
                    .padding(.top, 20)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.7).delay(0.15)) {
                appeared = true
            }
            withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true).delay(0.7)) {
                pulseCrown = true
            }
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
    }

    // MARK: - Gewinner-Banner
    private var winnerBanner: some View {
        VStack(spacing: 16) {
            // Krone
            ZStack {
                Circle()
                    .fill(SoundCinemaStyle.accentCyan.opacity(0.15))
                    .frame(width: 110, height: 110)
                    .shadow(color: SoundCinemaStyle.accentCyan.opacity(pulseCrown ? 0.5 : 0.15), radius: pulseCrown ? 24 : 8)

                Image(systemName: "crown.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(SoundCinemaStyle.primaryGradient)
                    .rotationEffect(.degrees(pulseCrown ? -8 : 8))
            }

            VStack(spacing: 6) {
                Text("Spiel beendet!")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .tracking(2)
                    .foregroundStyle(SoundCinemaStyle.textMuted)

                if let winner {
                    Text(winner.name)
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundStyle(.white)

                    Text("gewinnt mit \(winner.score) Punkt\(winner.score == 1 ? "" : "en")")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(SoundCinemaStyle.accentCyan)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .soundCinemaCard(highlighted: true)
    }

    // MARK: - Rangliste
    private var rankingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Label
            HStack(spacing: 6) {
                Image(systemName: "list.number")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(SoundCinemaStyle.accentCyan)
                Text("RANGLISTE")
                    .font(SoundCinemaStyle.labelFont)
                    .foregroundStyle(SoundCinemaStyle.textMuted)
                    .tracking(1.5)
            }

            VStack(spacing: 8) {
                ForEach(Array(sortedPlayers.enumerated()), id: \.element.id) { index, player in
                    rankRow(index: index, player: player)
                }
            }
        }
        .padding(16)
        .soundCinemaCard()
    }

    private func rankRow(index: Int, player: SoundCinemaPlayer) -> some View {
        let isWinner = index == 0 && !player.isEliminated
        let rankColor: Color = {
            switch index {
            case 0: return SoundCinemaStyle.accentCyan
            case 1: return Color(red: 0.75, green: 0.75, blue: 0.78)
            case 2: return Color(red: 0.80, green: 0.55, blue: 0.25)
            default: return SoundCinemaStyle.textMuted.opacity(0.5)
            }
        }()

        return HStack(spacing: 14) {
            // Rang-Badge
            ZStack {
                Circle()
                    .fill(rankColor.opacity(0.18))
                    .frame(width: 34, height: 34)
                if index < 3 {
                    Image(systemName: index == 0 ? "crown.fill" : "medal.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(rankColor)
                } else {
                    Text("\(index + 1)")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(rankColor)
                }
            }

            // Avatar
            ZStack {
                Circle()
                    .fill(SoundCinemaStyle.accentCyan.opacity(0.15))
                    .frame(width: 38, height: 38)
                Text(String(player.name.prefix(1)).uppercased())
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(SoundCinemaStyle.accentCyan)
            }

            // Name
            Text(player.name)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(player.isEliminated ? SoundCinemaStyle.textMuted : .white)
                .lineLimit(1)

            if player.isEliminated {
                Text("OUT")
                    .font(.system(size: 9, weight: .black, design: .monospaced))
                    .tracking(1)
                    .foregroundStyle(.red.opacity(0.7))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.red.opacity(0.1)))
            }

            Spacer()

            // Score
            HStack(spacing: 4) {
                Image(systemName: "waveform")
                    .font(.system(size: 10))
                    .foregroundStyle(rankColor.opacity(0.7))
                Text("\(player.score)")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(isWinner ? SoundCinemaStyle.accentCyan : .white)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(isWinner ? SoundCinemaStyle.accentCyan.opacity(0.08) : Color.white.opacity(0.03))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(isWinner ? SoundCinemaStyle.accentCyan.opacity(0.35) : Color.white.opacity(0.06), lineWidth: 1)
        )
        .opacity(player.isEliminated ? 0.6 : 1.0)
    }

    // MARK: - Buttons
    private var buttonSection: some View {
        VStack(spacing: 12) {
            // Rematch
            SoundCinemaPrimaryButton("Nochmal spielen", icon: "arrow.counterclockwise") {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                viewModel.restart()
            }

            // Zurück zum Menü
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                viewModel.phase = .setup
            } label: {
                Text("Zurück zum Setup")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(SoundCinemaStyle.textMuted)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.06))
                            .overlay(Capsule().stroke(Color.white.opacity(0.1), lineWidth: 1))
                    )
            }
        }
    }
}
