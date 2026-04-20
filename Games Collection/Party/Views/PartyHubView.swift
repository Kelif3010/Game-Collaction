import SwiftUI

struct PartyHubView: View {
    @Bindable var manager: PartySessionManager
    let onDismiss: () -> Void

    // Welches Spiel ist gerade aktiv im fullScreenCover?
    @State private var isGamePresented  = false
    @State private var showEndAlert     = false
    @State private var showDismissAlert = false

    private var session: PartySession {
        manager.session ?? PartySession(players: [], games: [])
    }

    var body: some View {
        ZStack {
            // Hintergrund
            LinearGradient(
                colors: [.black, Color.indigo.opacity(0.5), Color.purple.opacity(0.4)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {

                // ── Top Bar ──────────────────────────────────────────
                topBar
                    .padding(.top, 12)
                    .padding(.horizontal)

                // ── Progress Chips ────────────────────────────────────
                progressStrip
                    .padding(.top, 24)

                Spacer()

                // ── Hero Card ─────────────────────────────────────────
                if let game = session.currentGame {
                    heroCard(for: game)
                        .padding(.horizontal, 24)
                }

                Spacer()

                // ── Spieler Leaderboard (kompakt) ─────────────────────
                miniLeaderboard
                    .padding(.horizontal)

                Spacer(minLength: 24)

                // ── Spielen-Button ────────────────────────────────────
                playButton
                    .padding(.horizontal)
                    .padding(.bottom, 36)
            }
        }
        // Spiel als fullScreenCover präsentieren
        .fullScreenCover(isPresented: $isGamePresented, onDismiss: {
            showDismissAlert = true
        }) {
            gameView(for: session.currentGame)
        }
        // Bridge-Sheet nach jedem Spiel
        .sheet(isPresented: $manager.showBridge) {
            if let game = session.currentGame {
                PartyBridgeView(
                    manager: manager,
                    game: game,
                    players: session.players
                )
                .presentationDetents([.medium])
                .presentationCornerRadius(28)
                .presentationBackground(.ultraThinMaterial)
            }
        }
        .alert("Spiel beendet?", isPresented: $showDismissAlert) {
            Button("Ergebnis eintragen") { manager.gameDismissed() }
            Button("Abgebrochen", role: .cancel) { }
        } message: {
            Text("Wurde das Spiel zu Ende gespielt?")
        }
        .alert("Session beenden?", isPresented: $showEndAlert) {
            Button("Abbrechen", role: .cancel) { }
            Button("Beenden", role: .destructive) {
                manager.endSession()
                onDismiss()
            }
        } message: {
            Text("Der aktuelle Spielstand geht verloren.")
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Button { showEndAlert = true } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.6))
                    .frame(width: 36, height: 36)
                    .background(.white.opacity(0.08), in: Circle())
            }

            Spacer()

            VStack(spacing: 2) {
                Text("Party")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text(manager.progressText)
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.45))
            }

            Spacer()

            // Balance — Spieleranzahl-Badge
            Text("\(session.players.count) Spieler")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white.opacity(0.6))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.white.opacity(0.08), in: Capsule())
        }
    }

    // MARK: - Progress Chips

    private var progressStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(session.selectedGames.enumerated()), id: \.offset) { idx, game in
                    let isDone    = idx < session.gamesPlayed
                    let isCurrent = idx == session.currentGameIndex

                    HStack(spacing: 6) {
                        ZStack {
                            Circle()
                                .fill(isDone ? game.gradientColors[0] : .white.opacity(0.08))
                                .frame(width: 28, height: 28)

                            if isDone {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 11, weight: .black))
                                    .foregroundStyle(.white)
                            } else {
                                Image(systemName: game.icon)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(isCurrent ? game.gradientColors[0] : .white.opacity(0.35))
                            }
                        }

                        if isCurrent {
                            Text(game.displayName)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.white)
                                .transition(.move(edge: .leading).combined(with: .opacity))
                        }
                    }
                    .padding(.horizontal, isCurrent ? 10 : 4)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(
                                isCurrent
                                ? AnyShapeStyle(LinearGradient(
                                    colors: game.gradientColors,
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ).opacity(0.25))
                                : AnyShapeStyle(Color.white.opacity(isDone ? 0.06 : 0.04))
                            )
                            .overlay(
                                Capsule()
                                    .strokeBorder(
                                        isCurrent
                                        ? game.gradientColors[0].opacity(0.5)
                                        : Color.clear,
                                        lineWidth: 1
                                    )
                            )
                    )
                    .animation(.spring(response: 0.35), value: session.currentGameIndex)
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Hero Card

    @ViewBuilder
    private func heroCard(for game: PartyGame) -> some View {
        ZStack {
            // Gradient-Hintergrund
            RoundedRectangle(cornerRadius: 28)
                .fill(game.gradient)
                .shadow(color: game.gradientColors[0].opacity(0.5), radius: 24, y: 12)

            // Content
            VStack(spacing: 16) {
                Image(systemName: game.icon)
                    .font(.system(size: 56, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.9))
                    .shadow(color: .black.opacity(0.2), radius: 8, y: 4)

                VStack(spacing: 6) {
                    Text(game.displayName)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Nächstes Spiel")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.65))
                }
            }
            .padding(.vertical, 48)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Mini Leaderboard

    private var miniLeaderboard: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Aktueller Stand")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1.2)
                    .foregroundStyle(.white.opacity(0.38))
                Spacer()
            }
            .padding(.bottom, 10)

            HStack(spacing: 0) {
                ForEach(Array(manager.leaderboard.prefix(5).enumerated()), id: \.element.id) { idx, player in
                    VStack(spacing: 5) {
                        ZStack {
                            Circle()
                                .fill(player.avatarGradient)
                                .frame(width: 38, height: 38)
                            Text(player.initial)
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                        }

                        Text("\(player.totalScore)")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)

                        Text(player.name)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(.white.opacity(0.5))
                            .lineLimit(1)
                            .frame(width: 48)
                    }
                    .frame(maxWidth: .infinity)
                }

                if manager.leaderboard.count > 5 {
                    VStack(spacing: 5) {
                        ZStack {
                            Circle()
                                .fill(.white.opacity(0.08))
                                .frame(width: 38, height: 38)
                            Text("+\(manager.leaderboard.count - 5)")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white.opacity(0.5))
                        }
                        Text("–")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white.opacity(0.3))
                        Color.clear.frame(height: 12)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(16)
        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(.white.opacity(0.07), lineWidth: 1)
        )
    }

    // MARK: - Play Button

    private var playButton: some View {
        Button {
            isGamePresented = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: session.currentGame?.icon ?? "play.fill")
                    .font(.system(size: 18, weight: .bold))

                Text("Jetzt spielen")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                session.currentGame.map { game in
                    AnyShapeStyle(LinearGradient(
                        colors: game.gradientColors,
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
                } ?? AnyShapeStyle(Color.white.opacity(0.15)),
                in: RoundedRectangle(cornerRadius: 18)
            )
            .shadow(
                color: (session.currentGame?.gradientColors[0] ?? .clear).opacity(0.4),
                radius: 12,
                y: 6
            )
        }
    }

    // MARK: - Game View Factory

    @ViewBuilder
    private func gameView(for game: PartyGame?) -> some View {
        let ctx = PartyGameLaunchContext(playerNames: session.players.map(\.name))
        switch game {
        case .betBuddy:       BetBuddyWrapper()               // Gruppen-Modell – kein Auto-Import
        case .timesUp:        TimesUpWrapper()                 // Kein Spieler-System
        case .question:       QuestionGameWrapper(partyContext: ctx)
        case .imposter:       ImposterGameWrapper(partyContext: ctx)
        case .soundCinema:    SoundCinemaWrapper(partyContext: ctx)
        case .falscheFaehrte: FalscheFaehrteWrapper(partyContext: ctx)
        case .none:           EmptyView()
        }
    }
}
