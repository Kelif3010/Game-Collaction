import SwiftUI

struct SoundCinemaGameView: View {
    @EnvironmentObject private var viewModel: SoundCinemaViewModel
    @Environment(\.dismiss) private var dismiss

    // Lokale Animations-States
    @State private var eliminationScale: CGFloat = 0.7
    @State private var eliminationOpacity: Double = 0
    @State private var voteSuccessScale: CGFloat = 0.8
    @State private var cardShake: CGFloat = 0
    @State private var showQuitAlert = false

    var body: some View {
        ZStack {
            SoundCinemaBackground()

            VStack(spacing: 0) {
                // Header
                gameHeader
                    .padding(.horizontal, SoundCinemaStyle.padding)
                    .padding(.top, 12)
                    .padding(.bottom, 16)

                // Spieler-Leiste
                playerBar
                    .padding(.horizontal, SoundCinemaStyle.padding)
                    .padding(.bottom, 20)

                // Karte + Timer
                cardArea
                    .padding(.horizontal, SoundCinemaStyle.padding)

                Spacer()

                // Aktions-Buttons (nur sichtbar wenn Karte aufgedeckt)
                if viewModel.cardFlipped {
                    actionButtons
                        .padding(.horizontal, SoundCinemaStyle.padding)
                        .padding(.bottom, 32)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.75), value: viewModel.cardFlipped)

            // Voting-Ergebnis-Overlay
            if viewModel.showVoteOverlay {
                voteResultOverlay
                    .transition(.opacity.combined(with: .scale(scale: 0.85)))
            }

            // Eliminierungs-Overlay
            if case .eliminated(let name) = viewModel.phase {
                eliminationOverlay(name: name)
                    .transition(.opacity)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .alert("Spiel beenden?", isPresented: $showQuitAlert) {
            Button("Abbrechen", role: .cancel) {}
            Button("Beenden", role: .destructive) {
                viewModel.stopTimer()
                viewModel.phase = .setup
            }
        } message: {
            Text("Das aktuelle Spiel wird abgebrochen.")
        }
    }

    // MARK: - Header
    private var gameHeader: some View {
        HStack {
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                showQuitAlert = true
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .modifier(GlassCircleButtonBackground())
            }

            Spacer()

            // Karten-Zähler
            HStack(spacing: 6) {
                Image(systemName: "rectangle.stack.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(SoundCinemaStyle.accentCyan.opacity(0.7))
                Text("Karte \(viewModel.cardIndex + 1)")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(SoundCinemaStyle.textMuted)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(Capsule().fill(Color.white.opacity(0.06)))

            Spacer()

            // Timer-Ring (wenn Karte aufgedeckt)
            if viewModel.cardFlipped {
                CircularTimerRing(
                    progress: viewModel.timerProgress,
                    timeRemaining: viewModel.timeRemaining
                )
                .frame(width: 44, height: 44)
                .transition(.scale.combined(with: .opacity))
            } else {
                Color.clear.frame(width: 44, height: 44)
            }
        }
        .animation(.spring(response: 0.35), value: viewModel.cardFlipped)
    }

    // MARK: - Spieler-Leiste (alle aktiven Spieler + Leben)
    private var playerBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(Array(viewModel.players.enumerated()), id: \.element.id) { index, player in
                    let isCurrent = index == viewModel.currentPlayerIndex && !player.isEliminated
                    let maxLives  = viewModel.settings.livesMode.rawValue > 0
                                    ? viewModel.settings.livesMode.rawValue : 0

                    VStack(spacing: 5) {
                        // Name + Highlight
                        Text(player.name)
                            .font(.system(size: 12, weight: isCurrent ? .bold : .medium))
                            .foregroundStyle(isCurrent ? SoundCinemaStyle.accentCyan : SoundCinemaStyle.textMuted)
                            .lineLimit(1)

                        // Leben
                        if maxLives > 0 && !player.isEliminated {
                            LivesDisplay(
                                lives: player.livesRemaining,
                                maxLives: maxLives
                            )
                        } else if player.isEliminated {
                            Text("OUT")
                                .font(.system(size: 8, weight: .black, design: .monospaced))
                                .tracking(1)
                                .foregroundStyle(.red.opacity(0.8))
                        } else {
                            Image(systemName: "infinity")
                                .font(.system(size: 10))
                                .foregroundStyle(SoundCinemaStyle.accentMint.opacity(0.6))
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isCurrent
                                  ? SoundCinemaStyle.accentCyan.opacity(0.12)
                                  : Color.white.opacity(0.04))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(isCurrent
                                            ? SoundCinemaStyle.accentCyan.opacity(0.45)
                                            : Color.white.opacity(0.06), lineWidth: 1)
                            )
                    )
                    .opacity(player.isEliminated ? 0.4 : 1.0)
                    .scaleEffect(isCurrent ? 1.0 : 0.95)
                    .animation(.spring(response: 0.35), value: isCurrent)
                }
            }
            .padding(.horizontal, SoundCinemaStyle.padding)
        }
        .padding(.horizontal, -SoundCinemaStyle.padding) // Negative, damit ScrollView bis zum Rand geht
    }

    // MARK: - Karten-Bereich + Waveform
    private var cardArea: some View {
        VStack(spacing: 20) {
            // Aktiver Spieler-Label
            if let player = viewModel.currentPlayer {
                HStack(spacing: 8) {
                    Circle()
                        .fill(SoundCinemaStyle.accentCyan)
                        .frame(width: 8, height: 8)
                        .opacity(viewModel.cardFlipped ? 1 : 0.4)
                    Text(viewModel.cardFlipped ? "\(player.name) imitiert…" : "\(player.name) ist dran")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(SoundCinemaStyle.textMuted)
                }
                .animation(.easeInOut(duration: 0.3), value: viewModel.cardFlipped)
            }

            // Karte
            SoundCardView(
                card: viewModel.currentCard,
                isFlipped: viewModel.cardFlipped,
                onTap: {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    viewModel.revealCard()
                }
            )
            .offset(x: cardShake)

            // Waveform (nur wenn Timer läuft)
            if viewModel.cardFlipped {
                WaveformAnimation(
                    isActive: viewModel.isTimerRunning,
                    progress: viewModel.timerProgress
                )
                .frame(height: 40)
                .transition(.opacity.combined(with: .scale(scale: 0.8, anchor: .bottom)))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.cardFlipped)
    }

    // MARK: - Aktions-Buttons
    private var actionButtons: some View {
        VStack(spacing: 12) {
            // Hinweis
            Text("Hat jemand das Geräusch erraten?")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(SoundCinemaStyle.textMuted)

            HStack(spacing: 14) {
                // NICHT ERRATEN
                Button {
                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                    Task { await viewModel.handleVote(.failure) }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 18, weight: .bold))
                        Text("Nicht erraten")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 17)
                    .background(
                        Capsule()
                            .fill(Color.red.opacity(0.2))
                            .overlay(Capsule().stroke(Color.red.opacity(0.5), lineWidth: 1.5))
                    )
                }

                // ERRATEN
                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    Task { await viewModel.handleVote(.success) }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18, weight: .bold))
                        Text("Erraten!")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 17)
                    .background(
                        Capsule()
                            .fill(SoundCinemaStyle.primaryGradient)
                            .shadow(color: SoundCinemaStyle.accentCyan.opacity(0.4), radius: 10, y: 4)
                    )
                }
            }
        }
    }

    // MARK: - Voting-Ergebnis-Overlay
    private var voteResultOverlay: some View {
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(viewModel.lastVoteWasSuccess
                              ? SoundCinemaStyle.accentCyan.opacity(0.2)
                              : Color.red.opacity(0.2))
                        .frame(width: 100, height: 100)

                    Image(systemName: viewModel.lastVoteWasSuccess ? "checkmark" : "xmark")
                        .font(.system(size: 44, weight: .black))
                        .foregroundStyle(viewModel.lastVoteWasSuccess
                                         ? SoundCinemaStyle.accentCyan
                                         : .red)
                }
                .scaleEffect(voteSuccessScale)
                .onAppear {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.55)) {
                        voteSuccessScale = 1.0
                    }
                }
                .onDisappear { voteSuccessScale = 0.8 }

                Text(viewModel.lastVoteWasSuccess ? "Erraten! 🎉" : "Leider nicht 😬")
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                if !viewModel.lastVoteWasSuccess, let player = viewModel.currentPlayer,
                   viewModel.settings.livesMode != .endless {
                    Text("\(player.livesRemaining) Leben übrig")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.red.opacity(0.8))
                }
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 28)
                            .stroke(viewModel.lastVoteWasSuccess
                                    ? SoundCinemaStyle.accentCyan.opacity(0.3)
                                    : Color.red.opacity(0.3), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 40)
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: viewModel.showVoteOverlay)
    }

    // MARK: - Eliminierungs-Overlay
    private func eliminationOverlay(name: String) -> some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Text("💀")
                    .font(.system(size: 72))
                    .scaleEffect(eliminationScale)
                    .opacity(eliminationOpacity)

                Text("\(name) ist raus!")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .scaleEffect(eliminationScale)
                    .opacity(eliminationOpacity)

                Text("Alle Leben verbraucht")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.red.opacity(0.8))
                    .opacity(eliminationOpacity)
            }
            .onAppear {
                UINotificationFeedbackGenerator().notificationOccurred(.error)
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                    eliminationScale = 1.0
                    eliminationOpacity = 1.0
                }
            }
            .onDisappear {
                eliminationScale = 0.7
                eliminationOpacity = 0
            }
        }
    }
}
