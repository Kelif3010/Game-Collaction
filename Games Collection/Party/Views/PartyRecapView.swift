import SwiftUI

struct PartyRecapView: View {
    var manager: PartySessionManager
    let onDismiss: () -> Void

    @State private var showPodium    = false
    @State private var showRanking   = false
    @State private var showGameBreak = false

    private var session: PartySession {
        manager.session ?? PartySession(players: [], games: [])
    }
    private var sorted: [PartyPlayer] { session.sortedPlayers }

    var body: some View {
        ZStack {
            // Hintergrund
            LinearGradient(
                colors: [.black, Color.indigo.opacity(0.5), Color.purple.opacity(0.4)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {

                    // ── Header ────────────────────────────────────────
                    recapHeader

                    // ── Podium ────────────────────────────────────────
                    if sorted.count >= 2 {
                        podiumView
                            .opacity(showPodium ? 1 : 0)
                            .offset(y: showPodium ? 0 : 30)
                    }

                    // ── Vollständige Rangliste ────────────────────────
                    fullRanking
                        .opacity(showRanking ? 1 : 0)
                        .offset(y: showRanking ? 0 : 20)

                    // ── Spiel-für-Spiel ───────────────────────────────
                    gameBreakdown
                        .opacity(showGameBreak ? 1 : 0)

                    // ── Buttons ───────────────────────────────────────
                    bottomButtons
                        .opacity(showRanking ? 1 : 0)

                    Spacer(minLength: 40)
                }
                .padding(.horizontal)
                .padding(.top, 20)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.75).delay(0.2)) {
                showPodium = true
            }
            withAnimation(.easeOut(duration: 0.4).delay(0.7)) {
                showRanking = true
            }
            withAnimation(.easeOut(duration: 0.4).delay(0.9)) {
                showGameBreak = true
            }
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
    }

    // MARK: - Header

    private var recapHeader: some View {
        VStack(spacing: 8) {
            Text("SESSION BEENDET")
                .font(.system(size: 11, weight: .semibold))
                .tracking(3)
                .foregroundStyle(.white.opacity(0.38))

            Text("Gesamtwertung")
                .font(.system(size: 32, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            if let winner = sorted.first {
                HStack(spacing: 6) {
                    Image(systemName: "crown.fill")
                        .foregroundStyle(Color(red: 1.0, green: 0.83, blue: 0.15))
                    Text("\(winner.name) gewinnt die Party!")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.7))
                }
                .padding(.top, 2)
            }
        }
        .multilineTextAlignment(.center)
    }

    // MARK: - Podium

    private var podiumView: some View {
        HStack(alignment: .bottom, spacing: 10) {

            // 2. Platz (links)
            if sorted.count >= 2 {
                podiumColumn(player: sorted[1], place: 2, height: 100)
            }

            // 1. Platz (Mitte, größer)
            podiumColumn(player: sorted[0], place: 1, height: 140)

            // 3. Platz (rechts)
            if sorted.count >= 3 {
                podiumColumn(player: sorted[2], place: 3, height: 70)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }

    @ViewBuilder
    private func podiumColumn(player: PartyPlayer, place: Int, height: CGFloat) -> some View {
        VStack(spacing: 8) {
            // Avatar
            ZStack {
                Circle()
                    .fill(player.avatarGradient)
                    .frame(width: place == 1 ? 70 : 56, height: place == 1 ? 70 : 56)
                    .shadow(
                        color: place == 1
                        ? Color(red: 1.0, green: 0.83, blue: 0.15).opacity(0.5)
                        : .clear,
                        radius: 12
                    )
                    .overlay(
                        Circle()
                            .strokeBorder(
                                place == 1
                                ? Color(red: 1.0, green: 0.83, blue: 0.15)
                                : Color.white.opacity(0.15),
                                lineWidth: place == 1 ? 2.5 : 1
                            )
                    )

                Text(player.initial)
                    .font(.system(size: place == 1 ? 26 : 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }

            if place == 1 {
                Image(systemName: "crown.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(Color(red: 1.0, green: 0.83, blue: 0.15))
            }

            Text(player.name)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.8))
                .lineLimit(1)

            Text("\(player.totalScore) Pkt")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            // Podest-Block
            ZStack(alignment: .center) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        place == 1
                        ? LinearGradient(
                            colors: [
                                Color(red: 1.0, green: 0.83, blue: 0.15),
                                Color(red: 1.0, green: 0.65, blue: 0.05)
                            ],
                            startPoint: .top, endPoint: .bottom
                        )
                        : LinearGradient(
                            colors: [Color.white.opacity(0.12), Color.white.opacity(0.06)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .frame(height: height)

                Text("\(place).")
                    .font(.system(size: place == 1 ? 36 : 28, weight: .black, design: .rounded))
                    .foregroundStyle(place == 1 ? .black.opacity(0.4) : .white.opacity(0.2))
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Vollständige Rangliste

    private var fullRanking: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("RANGLISTE")
                .font(.system(size: 11, weight: .semibold))
                .tracking(1.5)
                .foregroundStyle(.white.opacity(0.38))

            VStack(spacing: 6) {
                ForEach(Array(sorted.enumerated()), id: \.element.id) { idx, player in
                    HStack(spacing: 14) {
                        // Platz
                        Text("\(idx + 1)")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(idx == 0 ? Color(red: 1.0, green: 0.83, blue: 0.15) : .white.opacity(0.4))
                            .frame(width: 24)

                        // Avatar
                        ZStack {
                            Circle()
                                .fill(player.avatarGradient)
                                .frame(width: 38, height: 38)
                            Text(player.initial)
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                        }

                        // Name
                        Text(player.name)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)

                        Spacer()

                        // Punkte
                        Text("\(player.totalScore)")
                            .font(.system(size: 18, weight: .black, design: .rounded))
                            .foregroundStyle(idx == 0 ? Color(red: 1.0, green: 0.83, blue: 0.15) : .white)

                        Text("Pkt")
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(idx == 0 ? .white.opacity(0.09) : .white.opacity(0.04))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .strokeBorder(
                                        idx == 0
                                        ? Color(red: 1.0, green: 0.83, blue: 0.15).opacity(0.3)
                                        : Color.white.opacity(0.05),
                                        lineWidth: 1
                                    )
                            )
                    )
                }
            }
        }
    }

    // MARK: - Game Breakdown

    private var gameBreakdown: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("SPIEL-FÜR-SPIEL")
                .font(.system(size: 11, weight: .semibold))
                .tracking(1.5)
                .foregroundStyle(.white.opacity(0.38))

            VStack(spacing: 8) {
                ForEach(session.results) { result in
                    HStack(spacing: 12) {
                        // Game Icon
                        ZStack {
                            RoundedRectangle(cornerRadius: 9)
                                .fill(result.game.gradient)
                                .frame(width: 36, height: 36)
                            Image(systemName: result.game.icon)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(.white)
                        }

                        // Game Name
                        Text(result.game.displayName)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)

                        Spacer()

                        // Gewinner-Namen
                        let winnerNames = result.winnerIDs.compactMap { wid in
                            session.players.first(where: { $0.id == wid })?.name
                        }
                        Text(winnerNames.joined(separator: ", "))
                            .font(.system(size: 13))
                            .foregroundStyle(.white.opacity(0.6))
                            .lineLimit(1)

                        Image(systemName: "crown.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(Color(red: 1.0, green: 0.83, blue: 0.15))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }

    // MARK: - Bottom Buttons

    private var bottomButtons: some View {
        VStack(spacing: 12) {
            // Neue Party
            Button {
                manager.endSession()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.black.opacity(0.7))
                    Text("Neue Party")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(.black)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [
                            Color(red: 1.0, green: 0.83, blue: 0.15),
                            Color(red: 1.0, green: 0.65, blue: 0.05)
                        ],
                        startPoint: .leading, endPoint: .trailing
                    ),
                    in: RoundedRectangle(cornerRadius: 16)
                )
            }

            // Fertig
            Button { onDismiss() } label: {
                Text("Fertig")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.5))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 16))
            }
        }
    }
}
