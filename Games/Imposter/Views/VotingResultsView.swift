//
//  VotingResultsView.swift
//  Imposter
//
//  Created by Ken on 23.09.25.
//  Redesigned for Premium Spy-Theme on 2026-01-22
//

import SwiftUI
import MultipeerConnectivity

// MARK: - Main View
struct VotingResultsView: View {
    @ObservedObject var votingManager: VotingManager
    let gameSettings: GameSettings
    let onNewGame: () -> Void
    let onContinueToGameplay: () -> Void
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var gameLogic: GameLogic

    @State private var showContent = false
    @State private var showBadge = false

    // Derived States
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

    // Game Outcome Logic
    private var isRescue: Bool { votingManager.lastRescueMessage != nil }
    private var spiesWon: Bool { votingManager.gameEnded && !votingManager.playersWon }
    private var citizensWon: Bool { votingManager.gameEnded && votingManager.playersWon }
    private var isRoundContinue: Bool { !votingManager.gameEnded && !isRescue }

    // MARK: - Theme Engine (Simplified)
    struct ResultTheme {
        let title: String
        let subtitle: String
        let badgeText: String
        let icon: String
        let accentColor: Color
        let isVictory: Bool
    }

    private var currentTheme: ResultTheme {
        // SCENARIO 1: RETTUNG
        if isRescue {
            return ResultTheme(
                title: "RETTUNG ERFOLGREICH",
                subtitle: votingManager.lastRescueMessage ?? "Der Leibwächter hat eingegriffen.",
                badgeText: "GESCHÜTZT",
                icon: "shield.lefthalf.filled",
                accentColor: .green,
                isVictory: true
            )
        }

        // SCENARIO 2: NARR GEWINNT
        if votingManager.jesterWon {
            let myName = MultipeerManager.shared.myPeerId.displayName
            let amIJester = gameSettings.players.first(where: { $0.name == myName })?.roleType == .fool

            if amIJester {
                return ResultTheme(
                    title: "NARR GEWINNT",
                    subtitle: "Du wurdest rausgewählt! Genau das war dein Plan.",
                    badgeText: "GETÄUSCHT",
                    icon: "theatermasks.fill",
                    accentColor: .purple,
                    isVictory: true
                )
            } else {
                return ResultTheme(
                    title: "GETÄUSCHT",
                    subtitle: "Ihr habt den Narren rausgewählt. Er gewinnt alleine.",
                    badgeText: "FEHLSCHLAG",
                    icon: "theatermasks.fill",
                    accentColor: .purple,
                    isVictory: false
                )
            }
        }

        // SCENARIO 3: RUNDE GEHT WEITER
        if isRoundContinue {
            return ResultTheme(
                title: "ZIEL NEUTRALISIERT",
                subtitle: "Ein Agent wurde enttarnt. Bleibt wachsam.",
                badgeText: "TREFFER",
                icon: "scope",
                accentColor: ImposterStyle.terminalAmber,
                isVictory: true
            )
        }

        // SCENARIO 4: SPIONE GEWINNEN
        if spiesWon {
            if isMultiplayer && localPlayerIsSpy {
                return ResultTheme(
                    title: "MISSION ERFOLGREICH",
                    subtitle: "Hervorragende Arbeit, Agent. Das System gehört uns.",
                    badgeText: "ERFOLG",
                    icon: "lock.open.fill",
                    accentColor: ImposterStyle.spyRed,
                    isVictory: true
                )
            } else if isMultiplayer {
                return ResultTheme(
                    title: "MISSION GESCHEITERT",
                    subtitle: "Die Agenten haben die Kontrolle übernommen.",
                    badgeText: "VERSAGT",
                    icon: "exclamationmark.triangle.fill",
                    accentColor: ImposterStyle.spyRed,
                    isVictory: false
                )
            } else {
                return ResultTheme(
                    title: "AGENTEN GEWINNEN",
                    subtitle: "Die Spione haben das Spiel für sich entschieden.",
                    badgeText: "SIEG",
                    icon: "person.fill.viewfinder",
                    accentColor: ImposterStyle.spyRed,
                    isVictory: false
                )
            }
        }

        // SCENARIO 5: BÜRGER GEWINNEN
        if citizensWon {
            if isMultiplayer && localPlayerIsSpy {
                return ResultTheme(
                    title: "ENTTARNT",
                    subtitle: "Deine Tarnung ist aufgeflogen. Zugriff verweigert.",
                    badgeText: "GEFASST",
                    icon: "hand.raised.fill",
                    accentColor: ImposterStyle.spyRed,
                    isVictory: false
                )
            } else {
                return ResultTheme(
                    title: "BEDROHUNG ELIMINIERT",
                    subtitle: "Alle Agenten wurden identifiziert. Das System ist sicher.",
                    badgeText: "ERFOLG",
                    icon: "checkmark.shield.fill",
                    accentColor: .green,
                    isVictory: true
                )
            }
        }

        return ResultTheme(
            title: "ERGEBNIS",
            subtitle: "Unbekannter Status",
            badgeText: "---",
            icon: "questionmark",
            accentColor: .gray,
            isVictory: false
        )
    }

    private var frozenIdentifiedSpies: [Player] {
        if votingManager.gameEnded {
            return gameSettings.players.filter { $0.isImposter || $0.roleType?.team == .imposter }
        }
        let selected = votingManager.selectedPlayers
        return gameSettings.players.filter { selected.contains($0.id) && ($0.isImposter || $0.roleType?.team == .imposter) }
    }

    // MARK: - Body
    var body: some View {
        let theme = currentTheme

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
                // MARK: - Top Status Bar
                HStack {
                    MissionStatusIndicator(
                        status: theme.isVictory ? "Abgeschlossen" : "Fehlgeschlagen",
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

                // MARK: - Main Content (Clean & Minimal)
                VStack(spacing: 32) {
                    // Icon (smaller, cleaner)
                    ZStack {
                        Circle()
                            .fill(theme.accentColor.opacity(0.1))
                            .frame(width: 100, height: 100)

                        Circle()
                            .stroke(theme.accentColor.opacity(0.3), lineWidth: 2)
                            .frame(width: 100, height: 100)

                        Image(systemName: theme.icon)
                            .font(.system(size: 40, weight: .medium))
                            .foregroundStyle(theme.accentColor)
                    }
                    .scaleEffect(showContent ? 1 : 0.8)
                    .opacity(showContent ? 1 : 0)

                    // Text
                    VStack(spacing: 12) {
                        Text(theme.title)
                            .font(.system(size: 24, weight: .bold, design: .monospaced))
                            .tracking(2)
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)

                        Text(theme.subtitle)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                            .padding(.horizontal, 40)
                    }
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 15)
                }

                Spacer()

                // MARK: - Revealed Agents (Dossier Style)
                if !frozenIdentifiedSpies.isEmpty && !isRescue {
                    VStack(alignment: .leading, spacing: 16) {
                        // Header
                        HStack(spacing: 8) {
                            Rectangle()
                                .fill(theme.accentColor)
                                .frame(width: 3, height: 14)

                            Text("ENTTARNTE AGENTEN")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .tracking(2)
                                .foregroundStyle(.white.opacity(0.5))
                        }
                        .padding(.horizontal, 24)

                        // Cards
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(frozenIdentifiedSpies) { player in
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
                }

                // MARK: - Buttons
                VStack(spacing: 14) {
                    if isRescue {
                        SpyActionButton(
                            title: "MISSION FORTSETZEN",
                            subtitle: "Weiter spielen",
                            icon: "play.fill",
                            style: .primary,
                            action: { continueRound() }
                        )
                    } else if !votingManager.gameEnded {
                        SpyActionButton(
                            title: "MISSION FORTSETZEN",
                            subtitle: "Nächste Runde starten",
                            icon: "play.fill",
                            style: .primary,
                            action: { continueRound() }
                        )
                    } else {
                        // Game End Buttons
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
                                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
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
                                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                    Task { @MainActor in
                                        await gameLogic.restartGame()
                                        onNewGame()
                                    }
                                }
                            )
                        }

                        // Exit Button
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
                            .foregroundStyle(.white.opacity(0.4))
                            .padding(.vertical, 12)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
                .opacity(showContent ? 1 : 0)
            }
        }
        .onAppear {
            if currentTheme.isVictory {
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

            if votingManager.gameEnded && !isRescue {
                recordStats(spiesWon: spiesWon)
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

    // MARK: - Subviews
    private var waitingIndicator: some View {
        HStack(spacing: 10) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white.opacity(0.5)))
                .scaleEffect(0.8)

            Text(isHost ? "Warte auf Antworten..." : "Warte auf Host...")
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.5))
        }
        .padding(.vertical, 16)
    }

    // MARK: - Actions
    private func endGameAndExit() {
        if isMultiplayer {
            MultipeerManager.shared.stop()
        }
        gameSettings.requestExitToSetup = true
        dismiss()
    }

    private func continueRound() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        if !isRescue {
            let previouslyFound = votingManager.foundSpies
            let eliminatedIDs = Set(frozenIdentifiedSpies.map { $0.id })
            votingManager.resetForNextRound()
            votingManager.foundSpies = previouslyFound.union(eliminatedIDs)
        } else {
            votingManager.resetForNextRound()
        }
        votingManager.restoreTimerState()
        onContinueToGameplay()
    }

    private func recordStats(spiesWon: Bool) {
        let imposters = gameSettings.players.filter { $0.isImposter || $0.roleType?.team == .imposter }
        let citizens = gameSettings.players.filter { !$0.isImposter && $0.roleType?.team != .imposter }

        if spiesWon {
            for imp in imposters { GlobalStatsManager.shared.recordWin(for: imp.name) }
            for cit in citizens { GlobalStatsManager.shared.recordLoss(for: cit.name) }
        } else {
            for imp in imposters { GlobalStatsManager.shared.recordLoss(for: imp.name) }
            for cit in citizens { GlobalStatsManager.shared.recordWin(for: cit.name) }
        }
    }
}

// MARK: - Dossier Card (Premium Agent Card)
struct DossierCard: View {
    let player: Player
    var accentColor: Color = ImposterStyle.spyRed

    var body: some View {
        VStack(spacing: 0) {
            // Header Strip
            HStack {
                Text("DOSSIER")
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .tracking(1)
                    .foregroundStyle(accentColor)

                Spacer()

                Circle()
                    .fill(accentColor)
                    .frame(width: 6, height: 6)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(accentColor.opacity(0.1))

            // Content
            VStack(spacing: 10) {
                // Avatar
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.05))
                        .frame(width: 50, height: 50)

                    Text(String(player.name.prefix(1)).uppercased())
                        .font(.system(size: 22, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)
                }

                // Name
                Text(player.name)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                // Role Badge
                Text(player.roleType?.rawValue.uppercased() ?? "AGENT")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .tracking(1)
                    .foregroundStyle(accentColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(accentColor.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 12)
        }
        .frame(width: 120)
        .background(Color.black.opacity(0.4))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(accentColor.opacity(0.25), lineWidth: 1)
        )
    }
}

// MARK: - Legacy Support (ImposterResultCard - kept for compatibility)
struct ImposterResultCard: View {
    let player: Player
    var isRevealed: Bool
    var isVictory: Bool
    var themeColor: Color = .white

    var body: some View {
        DossierCard(player: player, accentColor: themeColor)
    }
}
