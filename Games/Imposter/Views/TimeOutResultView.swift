//
//  TimeOutResultView.swift
//  Imposter
//
//  Created by Ken on 06.01.2026.
//  Redesigned for Premium Spy-Theme on 2026-01-22
//

import SwiftUI
import MultipeerConnectivity

struct TimeOutResultView: View {
    @EnvironmentObject var gameSettings: GameSettings
    @EnvironmentObject var gameLogic: GameLogic
    @Environment(\.dismiss) var dismiss

    @State private var showContent = false
    @State private var showBadge = false

    // Logic
    private var isMultiplayer: Bool {
        MultipeerManager.shared.role != .unknown
    }

    private var isHost: Bool {
        MultipeerManager.shared.role == .host
    }

    private var localPlayerIsSpy: Bool {
        guard isMultiplayer else { return false }
        let myName = MultipeerManager.shared.myPeerId.displayName
        if let player = gameSettings.players.first(where: { $0.name == myName }) {
            return player.isImposter || player.roleType?.team == .imposter
        }
        return false
    }

    // Theme (Time Out = Spy Win)
    private var theme: ResultTheme {
        if isMultiplayer && !localPlayerIsSpy {
            // Citizen: FAILURE
            return ResultTheme(
                title: "ZEIT ABGELAUFEN",
                subtitle: "Die Agenten konnten nicht rechtzeitig identifiziert werden.",
                badgeText: "TIMEOUT",
                icon: "clock.badge.xmark.fill",
                accentColor: ImposterStyle.spyRed,
                isVictory: false
            )
        } else {
            // Spy (or Single Device): VICTORY
            return ResultTheme(
                title: "MISSION ERFOLGREICH",
                subtitle: "Die Zeit hat für euch gespielt. Perfekte Tarnung.",
                badgeText: "ERFOLG",
                icon: "clock.badge.checkmark.fill",
                accentColor: ImposterStyle.terminalAmber,
                isVictory: true
            )
        }
    }

    struct ResultTheme {
        let title: String
        let subtitle: String
        let badgeText: String
        let icon: String
        let accentColor: Color
        let isVictory: Bool
    }

    var body: some View {
        ZStack {
            // Background
            Color.black.ignoresSafeArea()

            // Subtle gradient
            RadialGradient(
                colors: [theme.accentColor.opacity(0.15), Color.black],
                center: .center,
                startRadius: 50,
                endRadius: 400
            )
            .ignoresSafeArea()

            // Scanlines
            ScanlineOverlay(lineSpacing: 4, opacity: 0.025)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top Status Bar
                HStack {
                    MissionStatusIndicator(
                        status: "Timeout",
                        isActive: true,
                        activeColor: theme.accentColor
                    )

                    Spacer()

                    ClassifiedBadge(
                        text: theme.badgeText,
                        color: theme.accentColor
                    )
                    .scaleEffect(showBadge ? 1 : 0.8)
                    .opacity(showBadge ? 1 : 0)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)

                Spacer()

                // Main Content
                VStack(spacing: 32) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(theme.accentColor.opacity(0.1))
                            .frame(width: 100, height: 100)

                        Circle()
                            .stroke(theme.accentColor.opacity(0.3), lineWidth: 2)
                            .frame(width: 100, height: 100)

                        Image(systemName: theme.icon)
                            .font(.system(size: 40, weight: .medium))
                            .foregroundColor(theme.accentColor)
                    }
                    .scaleEffect(showContent ? 1 : 0.8)
                    .opacity(showContent ? 1 : 0)

                    // Text
                    VStack(spacing: 12) {
                        Text(theme.title)
                            .font(.system(size: 24, weight: .bold, design: .monospaced))
                            .tracking(2)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)

                        Text(theme.subtitle)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                            .padding(.horizontal, 40)
                    }
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 15)
                }

                Spacer()

                // Revealed Spies
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 8) {
                        Rectangle()
                            .fill(theme.accentColor)
                            .frame(width: 3, height: 14)

                        Text("ENTTARNTE AGENTEN")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .tracking(2)
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .padding(.horizontal, 24)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(gameSettings.players.filter { $0.isImposter || $0.roleType?.team == .imposter }) { player in
                                DossierCard(
                                    player: player,
                                    accentColor: theme.accentColor
                                )
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                }
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)
                .padding(.bottom, 24)

                // Buttons
                VStack(spacing: 14) {
                    if isMultiplayer {
                        if isHost {
                            if gameSettings.multiplayerRematchWaiting {
                                waitingIndicator
                            } else {
                                SpyActionButton(
                                    title: "NEUE MISSION",
                                    subtitle: "Rematch starten",
                                    icon: "arrow.counterclockwise",
                                    style: .primary,
                                    action: {
                                        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                                        gameLogic.startMultiplayerRematchOffer()
                                    }
                                )
                            }
                        } else {
                            waitingIndicator
                        }
                    } else {
                        SpyActionButton(
                            title: "NEUE MISSION",
                            subtitle: "Nochmal spielen",
                            icon: "arrow.counterclockwise",
                            style: .primary,
                            action: {
                                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                                Task { @MainActor in
                                    await gameLogic.restartGame()
                                }
                            }
                        )
                    }

                    Button {
                        endGameAndExit()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 12, weight: .semibold))
                            Text("BEENDEN")
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .tracking(1)
                        }
                        .foregroundColor(.white.opacity(0.4))
                        .padding(.vertical, 12)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
                .opacity(showContent ? 1 : 0)
            }
        }
        .onAppear {
            if theme.isVictory {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            } else {
                UINotificationFeedbackGenerator().notificationOccurred(.error)
            }

            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1)) {
                showContent = true
            }

            withAnimation(.spring(response: 0.4, dampingFraction: 0.6).delay(0.4)) {
                showBadge = true
            }
        }
        .alert("Neue Runde?", isPresented: Binding(
            get: { gameSettings.multiplayerRematchOffer != nil },
            set: { newValue in
                if !newValue {
                    gameSettings.multiplayerRematchOffer = nil
                }
            }
        )) {
            Button("Nein", role: .destructive) {
                gameLogic.sendRematchResponse(wantsRematch: false)
            }
            Button("Ja") {
                gameLogic.sendRematchResponse(wantsRematch: true)
            }
        } message: {
            Text("Der Host möchte eine neue Runde starten.")
        }
    }

    private var waitingIndicator: some View {
        HStack(spacing: 10) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white.opacity(0.5)))
                .scaleEffect(0.8)

            Text(isHost ? "Warte auf Antworten..." : "Warte auf Host...")
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundColor(.white.opacity(0.5))
        }
        .padding(.vertical, 16)
    }

    private func endGameAndExit() {
        if isMultiplayer {
            MultipeerManager.shared.stop()
        }
        gameSettings.requestExitToSetup = true
        dismiss()
    }
}
