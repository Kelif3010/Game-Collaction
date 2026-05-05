//
//  ImposterGameComponents.swift
//  Games Collection
//

import SwiftUI

// MARK: - Multiplayer Waiting View
struct MultiplayerWaitingView: View {
    @Environment(GameSettings.self) var gameSettings

    var body: some View {
        ZStack {
            ImposterStyle.backgroundGradient.ignoresSafeArea()

            VStack(spacing: 30) {
                ZStack {
                    LottieView(
                        filename: "Radar animation",
                        loopMode: .loop,
                        isPlaying: true
                    )
                    .frame(width: 200, height: 200)
                    .shadow(color: .blue.opacity(0.5), radius: 20)
                }
                .onAppear {
                    SoundManager.shared.playSound(named: "radar-beeping-192404", loop: true)
                }
                .onDisappear {
                    SoundManager.shared.stopSound()
                }

                VStack(spacing: 10) {
                    Text("WARTE AUF SPIELER")
                        .font(.headline)
                        .fontWeight(.bold)
                        .tracking(2)
                        .foregroundStyle(.white)

                    if let progress = gameSettings.revealProgress {
                        Text("\(progress.ready) / \(progress.total) BEREIT")
                            .font(.system(size: 32, weight: .black, design: .monospaced))
                            .foregroundStyle(.blue)
                    } else {
                        Text("Synchronisiere...")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }

                Text("Das Spiel startet automatisch,\nsobald alle ihre Rolle gesehen haben.")
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(.horizontal, 40)
            }
        }
    }
}

// MARK: - Game Header View (Spy/Terminal HUD)
struct ImposterGameHeaderView: View {
    @Environment(GameSettings.self) var gameSettings

    private var isMultiplayerActive: Bool {
        MultipeerManager.shared.role != .unknown
    }

    var body: some View {
        HStack {
            if !gameSettings.randomSpyCount {
                HStack(spacing: 8) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(ImposterStyle.spyRed.opacity(0.2))
                            .frame(width: 32, height: 32)
                        Image(systemName: "person.fill.viewfinder")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(ImposterStyle.spyRed)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(gameSettings.numberOfImposters)")
                            .font(.system(size: 14, weight: .black, design: .monospaced))
                            .foregroundStyle(.white)
                        Text(gameSettings.numberOfImposters == 1 ? "AGENT" : "AGENTEN")
                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                            .tracking(1)
                            .foregroundStyle(ImposterStyle.spyRed.opacity(0.8))
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.black.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(ImposterStyle.spyRed.opacity(0.3), lineWidth: 1)
                )
            }

            Spacer()

            if gameSettings.gamePhase == .cardReveal && !isMultiplayerActive {
                HStack(spacing: 8) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(gameSettings.currentPlayerIndex + 1)/\(gameSettings.players.count)")
                            .font(.system(size: 14, weight: .black, design: .monospaced))
                            .foregroundStyle(.white)
                        Text("DOSSIERS")
                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                            .tracking(1)
                            .foregroundStyle(.white.opacity(0.5))
                    }

                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.1), lineWidth: 3)
                            .frame(width: 24, height: 24)

                        let progress = Double(gameSettings.currentPlayerIndex + 1) / Double(max(1, gameSettings.players.count))
                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(ImposterStyle.terminalAmber, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                            .frame(width: 24, height: 24)
                            .rotationEffect(.degrees(-90))
                            .animation(.spring(), value: progress)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.black.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }
}

// MARK: - Starting Player Announcement
struct StartingPlayerAnnouncementView: View {
    let playerName: String?
    let countdownSeconds: Int?
    let showButton: Bool
    let onContinue: () -> Void

    init(
        playerName: String?,
        countdownSeconds: Int? = nil,
        showButton: Bool = true,
        onContinue: @escaping () -> Void
    ) {
        self.playerName = playerName
        self.countdownSeconds = countdownSeconds
        self.showButton = showButton
        self.onContinue = onContinue
    }

    private var displayName: String {
        let trimmed = playerName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? "..." : trimmed
    }

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            ZStack {
                Circle()
                    .fill(ImposterStyle.primaryGradient.opacity(0.2))
                    .frame(width: 140, height: 140)
                    .blur(radius: 20)

                Image(systemName: "flag.checkered")
                    .font(.system(size: 60))
                    .foregroundStyle(.white)
            }

            VStack(spacing: 10) {
                Text(LocalizedStringKey("Startspieler"))
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.7))
                    .textCase(.uppercase)
                    .kerning(2)

                Text(displayName)
                    .font(.system(size: 42, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
            }

            Text(LocalizedStringKey("Der ausgewählte Spieler beginnt die Runde. Danach startet der Timer."))
                .font(.body)
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            if let countdownSeconds {
                VStack(spacing: 6) {
                    Text("START IN")
                        .font(.caption.bold())
                        .tracking(2)
                        .foregroundStyle(.white.opacity(0.6))
                    Text("\(max(0, countdownSeconds))")
                        .font(.system(size: 64, weight: .black, design: .monospaced))
                        .foregroundStyle(.white)
                        .contentTransition(.numericText())
                }
            }

            Spacer()

            if showButton {
                ImposterPrimaryButton(title: "Los geht's") {
                    onContinue()
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
        }
    }
}

// MARK: - Game Footer View
struct GameFooterView: View {
    @Environment(GameSettings.self) var gameSettings
    @Environment(\.dismiss) private var dismiss
    @State private var showExitConfirmation = false

    var body: some View {
        Button {
            showExitConfirmation = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "xmark")
                    .font(.caption.bold())
                Text(LocalizedStringKey("Spiel verlassen"))
                    .font(.callout.weight(.medium))
            }
            .foregroundStyle(.white.opacity(0.7))
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color.black.opacity(0.3))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
        .padding(.bottom, 20)
        .confirmationDialog(
            "Spiel wirklich beenden?",
            isPresented: $showExitConfirmation,
            titleVisibility: .visible
        ) {
            Button("Abbrechen", role: .cancel) { }
            Button("Spiel beenden", role: .destructive) {
                if MultipeerManager.shared.role != .unknown {
                    MultipeerManager.shared.stop()
                }
                gameSettings.markRoundCompleted()
                gameSettings.resetGame()
                dismiss()
            }
        } message: {
            Text("Der aktuelle Fortschritt geht verloren.")
        }
    }
}
