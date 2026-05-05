//
//  ImposterGameTimerView.swift
//  Games Collection
//

import SwiftUI
import MultipeerConnectivity

// MARK: - Game Timer View (Playing Phase)
struct GameTimerView: View {
    @Environment(GameSettings.self) var gameSettings
    @Environment(GameLogic.self) var gameLogic

    @State private var showVotingView = false
    @State private var showWordGuessingView = false
    @State private var showWordGuessConfirm = false
    @State private var startWordGuessImmediateWin = false
    @State private var wasTimerPausedBeforeWordGuess = false
    @State private var showSelfCard = false

    @State private var criticalPulse = false
    @State private var criticalGlow = false
    @State private var criticalTimeFeedbackTrigger = 0

    private var isHostOrLocal: Bool {
        let role = MultipeerManager.shared.role
        return role == .host || role == .unknown
    }

    private var isGuest: Bool {
        MultipeerManager.shared.role == .peer
    }

    private var selfCard: GameCard? {
        let myName = MultipeerManager.shared.myPeerId.displayName
        guard let player = gameSettings.players.first(where: { $0.name == myName }) else { return nil }
        guard let category = gameSettings.roundCategory ?? gameSettings.selectedCategory else { return nil }
        return GameCard(player: player, category: category)
    }

    private var isCriticalTime: Bool {
        gameSettings.timeRemaining <= 30 && !gameSettings.isTimerPaused
    }

    private var isWarningTime: Bool {
        gameSettings.timeRemaining <= 60 && gameSettings.timeRemaining > 30
    }

    private var timerColor: Color {
        if isCriticalTime {
            return ImposterStyle.spyRed
        } else if isWarningTime {
            return ImposterStyle.terminalAmber
        }
        return .white
    }

    var body: some View {
        ZStack {
            ScanlineOverlay(lineSpacing: 4, opacity: 0.03)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    MissionStatusIndicator(
                        status: gameSettings.isTimerPaused ? "Pausiert" : "Aktiv",
                        isActive: !gameSettings.isTimerPaused,
                        activeColor: isCriticalTime ? ImposterStyle.spyRed : ImposterStyle.terminalAmber
                    )

                    Spacer()

                    ClassifiedBadge(
                        text: isCriticalTime ? "KRITISCH" : "GEHEIM",
                        color: isCriticalTime ? ImposterStyle.spyRed : ImposterStyle.spyRed.opacity(0.7)
                    )
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)

                Spacer()

                VStack(spacing: 24) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.black.opacity(0.7))
                            .frame(width: 280, height: 160)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(
                                        isCriticalTime ? ImposterStyle.spyRed.opacity(0.8) :
                                            (isWarningTime ? ImposterStyle.terminalAmber.opacity(0.5) : Color.white.opacity(0.15)),
                                        lineWidth: isCriticalTime ? 2 : 1
                                    )
                            )
                            .shadow(color: isCriticalTime ? ImposterStyle.spyRed.opacity(0.4) : .clear, radius: 20)

                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.clear)
                            .frame(width: 280, height: 160)
                            .overlay(
                                ScanlineOverlay(lineSpacing: 3, opacity: 0.06)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                            )

                        VStack(spacing: 8) {
                            Text("VERBLEIBENDE ZEIT")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .tracking(3)
                                .foregroundStyle(Color.white.opacity(0.4))

                            Text(timeString)
                                .font(.system(size: 64, weight: .bold, design: .monospaced))
                                .foregroundStyle(timerColor)
                                .contentTransition(.numericText())
                                .scaleEffect(isCriticalTime && criticalPulse ? 1.03 : 1.0)
                                .shadow(color: isCriticalTime ? ImposterStyle.spyRed.opacity(0.5) : .clear, radius: 10)

                            HStack(spacing: 6) {
                                Circle()
                                    .fill(gameSettings.isTimerPaused ? ImposterStyle.terminalAmber : (isCriticalTime ? ImposterStyle.spyRed : Color.green))
                                    .frame(width: 6, height: 6)

                                Text(gameSettings.isTimerPaused ? "MISSION PAUSIERT" : (isCriticalTime ? "ZEIT KRITISCH" : "MISSION LÄUFT"))
                                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                    .tracking(1)
                                    .foregroundStyle(gameSettings.isTimerPaused ? ImposterStyle.terminalAmber : (isCriticalTime ? ImposterStyle.spyRed : Color.green.opacity(0.8)))
                            }
                        }
                    }
                    .onTapGesture {
                        togglePause()
                    }
                    .onChange(of: isCriticalTime) { _, newValue in
                        if newValue {
                            withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                                criticalPulse = true
                            }
                            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                                criticalGlow = true
                            }
                            criticalTimeFeedbackTrigger += 1
                        } else {
                            criticalPulse = false
                            criticalGlow = false
                        }
                    }
                    .sensoryFeedback(.impact(weight: .medium), trigger: criticalTimeFeedbackTrigger)

                    if isHostOrLocal {
                        Text(isCriticalTime ? "⚠ ZEITDRUCK" : "[ ANTIPPEN ZUM PAUSIEREN ]")
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .tracking(1)
                            .foregroundStyle(isCriticalTime ? ImposterStyle.spyRed.opacity(0.7) : Color.white.opacity(0.3))
                    }
                }

                Spacer()

                VStack(spacing: 14) {
                    if isGuest {
                        SpyActionButton(
                            title: "DOSSIER EINSEHEN",
                            subtitle: "Deine Rolle & Hinweise",
                            icon: "doc.text.magnifyingglass",
                            style: .secondary,
                            action: { showSelfCard = true }
                        )
                    } else {
                        SpyActionButton(
                            title: "ABSTIMMUNG EINLEITEN",
                            subtitle: "Verdächtigen identifizieren",
                            icon: "target",
                            style: .primary,
                            isEnabled: isHostOrLocal,
                            action: {
                                if isHostOrLocal {
                                    if MultipeerManager.shared.role == .host {
                                        gameLogic.startMultiplayerVoting()
                                    } else {
                                        showVotingView = true
                                    }
                                }
                            }
                        )

                        SpyActionButton(
                            title: "INTEL KOMPROMITTIEREN",
                            subtitle: "Nur für Agenten",
                            icon: "key.fill",
                            style: .danger,
                            isEnabled: isHostOrLocal,
                            action: {
                                if isHostOrLocal { showWordGuessConfirm = true }
                            }
                        )
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 30)
            }
        }
        .sheet(isPresented: $showVotingView) {
            VotingView(gameSettings: gameSettings)
                .environment(gameLogic)
                .interactiveDismissDisabled(true)
                .onDisappear {
                    if MultipeerManager.shared.role != .unknown {
                        gameSettings.shouldPresentVoting = false
                    }
                }
        }
        .sheet(isPresented: $showSelfCard) {
            ZStack {
                ImposterStyle.backgroundGradient.ignoresSafeArea()
                if let card = selfCard {
                    SpyCardFrontView(
                        card: card,
                        gameSettings: gameSettings,
                        isMultiplayer: true,
                        onDismiss: { showSelfCard = false }
                    )
                    .frame(width: 320, height: 500)
                } else {
                    Text("Keine Karte verfügbar")
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
        }
        .onChange(of: gameSettings.shouldPresentVoting) { _, newValue in
            if newValue { showVotingView = true }
        }
        .onChange(of: gameSettings.gamePhase) { _, newPhase in
            if newPhase == .cardReveal {
                showWordGuessingView = false
                showWordGuessConfirm = false
                startWordGuessImmediateWin = false
            }
        }
        .alert(LocalizedStringKey("Spion enttarnt sich?"), isPresented: $showWordGuessConfirm) {
            Button("Abbrechen", role: .cancel) { }
            Button(LocalizedStringKey("Ja, Wort lösen")) {
                wasTimerPausedBeforeWordGuess = gameSettings.isTimerPaused
                gameSettings.isTimerPaused = true
                if MultipeerManager.shared.role == .host {
                    let correctWord = gameSettings.players.first { !$0.isImposter }?.word ?? "Unbekannt"
                    let payload = ImposterWordGuessResultPayload(correctWord: correctWord)
                    MultipeerManager.shared.sendToAll(event: MPCEventType.imposterWordGuessConfirmed, object: payload)
                }
                startWordGuessImmediateWin = true
                showWordGuessingView = true
            }
        } message: {
            Text(LocalizedStringKey("Willst du als Spion versuchen das Wort zu erraten, um sofort zu gewinnen?"))
        }
        .fullScreenCover(isPresented: $showWordGuessingView) {
            WordGuessingView(gameSettings: gameSettings, startWithImmediateWin: startWordGuessImmediateWin)
                .environment(gameLogic)
                .onDisappear {
                    if !wasTimerPausedBeforeWordGuess {
                        gameSettings.isTimerPaused = false
                    }
                    startWordGuessImmediateWin = false
                }
        }
        .fullScreenCover(
            isPresented: Binding(
                get: { gameSettings.multiplayerWordGuessResult != nil },
                set: { newValue in
                    if !newValue { gameSettings.multiplayerWordGuessResult = nil }
                }
            )
        ) {
            if let payload = gameSettings.multiplayerWordGuessResult {
                WordGuessResultView(
                    result: WordGuessResult(
                        wasCorrect: true,
                        correctWord: payload.correctWord,
                        spyWon: true,
                        gameEnded: true
                    ),
                    spies: gameSettings.players.filter { $0.isImposter },
                    onNewGame: {},
                    onExitToMain: {},
                    showActions: false
                )
                .interactiveDismissDisabled(true)
            }
        }
    }

    private func togglePause() {
        guard isHostOrLocal else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        withAnimation {
            gameSettings.isTimerPaused.toggle()
            if MultipeerManager.shared.role == .host {
                gameLogic.broadcastGameState()
            }
        }
    }

    private var timeString: String {
        let minutes = gameSettings.timeRemaining / 60
        let seconds = gameSettings.timeRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - Helper Button Component
struct GameControlBtn: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 50, height: 50)

                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundStyle(color)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(LocalizedStringKey(title))
                        .font(.headline.bold())
                        .foregroundStyle(.white)

                    if !subtitle.isEmpty {
                        Text(LocalizedStringKey(subtitle))
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(.white.opacity(0.3))
            }
            .padding(16)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(.white.opacity(0.1), lineWidth: 1)
            )
        }
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.6)
    }
}

// MARK: - Spy Action Button (Terminal/Geheimdienst Style)
struct SpyActionButton: View {
    enum Style {
        case primary
        case secondary
        case danger
    }

    let title: String
    let subtitle: String
    let icon: String
    var style: Style = .primary
    var isEnabled: Bool = true
    let action: () -> Void

    private var accentColor: Color {
        switch style {
        case .primary: return ImposterStyle.spyRed
        case .secondary: return Color.white.opacity(0.6)
        case .danger: return ImposterStyle.terminalAmber
        }
    }

    private var backgroundColor: Color {
        switch style {
        case .primary: return ImposterStyle.spyRed.opacity(0.15)
        case .secondary: return Color.white.opacity(0.05)
        case .danger: return ImposterStyle.terminalAmber.opacity(0.1)
        }
    }

    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            action()
        }) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(accentColor.opacity(0.2))
                        .frame(width: 44, height: 44)

                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(accentColor)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .tracking(0.5)
                        .foregroundStyle(.white)

                    Text(subtitle)
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.5))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(accentColor.opacity(0.6))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(backgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(accentColor.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.5)
    }
}
