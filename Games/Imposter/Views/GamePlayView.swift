//
//  GamePlayView.swift
//  Imposter
//
//  Created by Ken on 22.09.25.
//

import SwiftUI
import MultipeerConnectivity
import Foundation

struct GamePlayView: View {
    @Environment(GameSettings.self) var gameSettings
    @Environment(GameLogic.self) var gameLogic
    @Environment(\.dismiss) private var dismiss
    @Environment(MultipeerManager.self) private var mpc

    @State private var currentCard: GameCard?
    @State private var hasRevealedOwnCard = false

    @State private var showStartingPlayerAnnouncement = false
    @State private var startingPlayer: Player?
    @State private var didRequestTimeSync = false
    @State private var didSendRejoinRequest = false
    @State private var myPlayerIdentity: PlayerIdentity?
    @State private var lastConnectedPeerNames: Set<String> = []

    @State private var showDisconnectToast = false
    @State private var disconnectToastName = ""

    @State private var showReconnectToast = false
    @State private var reconnectToastName = ""

    private let hintService = HintService.shared

    private var isMultiplayerActive: Bool {
        MultipeerManager.shared.role != .unknown
    }

    private var isHostOrLocal: Bool {
        let role = MultipeerManager.shared.role
        return role == .host || role == .unknown
    }

    var body: some View {
        ZStack {
            ImposterStyle.backgroundGradient
                .ignoresSafeArea()

            VStack(spacing: 0) {
                ImposterGameHeaderView()
                    .padding(.bottom, 10)

                mainContent

                Spacer()

                GameFooterView()
            }

            if showDisconnectToast {
                VStack {
                    HStack(spacing: 12) {
                        Image(systemName: "wifi.slash")
                            .font(.headline)
                            .foregroundStyle(.white)

                        Text("\(disconnectToastName) hat die Verbindung verloren")
                            .font(.subheadline.bold())
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.red.opacity(0.9))
                    .clipShape(Capsule())
                    .shadow(color: .black.opacity(0.3), radius: 10, y: 5)
                    .padding(.top, 60)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(100)

                    Spacer()
                }
            }

            if showReconnectToast {
                VStack {
                    HStack(spacing: 12) {
                        Image(systemName: "wifi")
                            .font(.headline)
                            .foregroundStyle(.white)

                        Text("\(reconnectToastName) ist zurückgekehrt")
                            .font(.subheadline.bold())
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.green.opacity(0.9))
                    .clipShape(Capsule())
                    .shadow(color: .black.opacity(0.3), radius: 10, y: 5)
                    .padding(.top, 60)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(101)

                    Spacer()
                }
            }
        }
        .onAppear {
            resetLocalState()
            lastConnectedPeerNames = Set(mpc.connectedPeers.map { $0.displayName })
            if isMultiplayerActive {
                hasRevealedOwnCard = false
                requestTimeSyncSamplesIfNeeded()
                sendRejoinRequestIfNeeded()
            }
            startGame()
        }
        .onDisappear {
            resetLocalState()
            gameLogic.stopGameTimer()
        }
        .toolbar(.hidden, for: .navigationBar)
        .onChange(of: mpc.lastReconnectedPlayerName) { _, newName in
            if let name = newName {
                reconnectToastName = name
                withAnimation(.spring()) { showReconnectToast = true }
                Task {
                    try? await Task.sleep(for: .seconds(3))
                    withAnimation { showReconnectToast = false }
                }
            }
        }
        .onChange(of: mpc.lastDisconnectedPlayerName) { _, newName in
            if let name = newName {
                disconnectToastName = name
                withAnimation(.spring()) { showDisconnectToast = true }
                Task {
                    try? await Task.sleep(for: .seconds(3))
                    withAnimation { showDisconnectToast = false }
                }
            }
        }
        .onChange(of: gameSettings.requestExitToMain) { _, newValue in
            if newValue { dismiss() }
        }
        .onChange(of: gameSettings.requestExitToSetup) { _, newValue in
            if newValue {
                gameSettings.requestExitToSetup = false
                dismiss()
            }
        }
        .onChange(of: mpc.lobbyPeers) { _, _ in
            gameLogic.handleRematchLobbyUpdate()
        }
        .onChange(of: mpc.connectedPeers) { _, newPeers in
            let newNames = Set(newPeers.map { $0.displayName })
            if newPeers.isEmpty {
                didRequestTimeSync = false
                didSendRejoinRequest = false
                lastConnectedPeerNames = []
                return
            }
            if mpc.role == .host, gameSettings.gamePhase != .setup {
                let joined = newNames.subtracting(lastConnectedPeerNames)
                for name in joined {
                    guard gameSettings.players.contains(where: { $0.name == name }) else { continue }
                    if let peer = mpc.getPeer(byName: name),
                       let state = gameLogic.makeRejoinStatePayload(for: name) {
                        mpc.sendToPeer(event: MPCEventType.imposterRejoinState, object: state, to: peer)
                    }
                }
            }
            lastConnectedPeerNames = newNames
            requestTimeSyncSamplesIfNeeded()
            sendRejoinRequestIfNeeded()
        }
        .onChange(of: gameSettings.startingPlayerName) { _, newName in
            if let newName = newName {
                startingPlayer = gameSettings.players.first(where: { $0.name == newName })
            }
        }
        .onChange(of: gameSettings.gamePhase) { _, newPhase in
            if newPhase == .finished {
                gameLogic.stopGameTimer()
            } else if newPhase == .cardReveal {
                if isMultiplayerActive {
                    let myName = mpc.myPeerId.displayName
                    let hasSeen = gameSettings.players.first(where: { $0.name == myName })?.hasSeenCard ?? false
                    hasRevealedOwnCard = hasSeen
                    currentCard = nil
                    gameSettings.isWaitingForOtherPlayers = hasSeen
                    showStartingPlayerAnnouncement = false
                    startingPlayer = nil
                    if !hasSeen { prepareMultiplayerCardIfNeeded() }
                } else {
                    showStartingPlayerAnnouncement = false
                    gameSettings.isTimerPaused = true
                    prepareNextCard()
                }
            }
        }
        .onChange(of: gameSettings.players) { oldPlayers, newPlayers in
            guard isMultiplayerActive else { return }
            guard !hasRevealedOwnCard else { return }
            let myName = MultipeerManager.shared.myPeerId.displayName
            let oldSelf = oldPlayers.first(where: { $0.name == myName })
            let newSelf = newPlayers.first(where: { $0.name == myName })
            let oldIdentity = PlayerIdentity(from: oldSelf)
            let newIdentity = PlayerIdentity(from: newSelf)
            hasRevealedOwnCard = newSelf?.hasSeenCard ?? false
            if oldIdentity != newIdentity { myPlayerIdentity = newIdentity }
        }
        .onChange(of: myPlayerIdentity) { _, _ in
            guard isMultiplayerActive, !hasRevealedOwnCard else { return }
            currentCard = nil
            prepareMultiplayerCardIfNeeded()
        }
        .onChange(of: gameSettings.roundCategory) { _, _ in
            if isMultiplayerActive { prepareMultiplayerCardIfNeeded() }
        }
        .onChange(of: gameSettings.currentPlayerIndex) { _, _ in
            if isMultiplayerActive && !hasRevealedOwnCard {
                currentCard = nil
                prepareMultiplayerCardIfNeeded()
            }
        }
    }

    // MARK: - Main Content (Phase Router)

    @ViewBuilder
    private var mainContent: some View {
        ZStack {
            if isMultiplayerActive {
                switch gameSettings.gamePhase {
                case .finished:
                    TimeOutResultView()
                        .transition(.opacity)
                case .cardReveal:
                    if hasRevealedOwnCard {
                        MultiplayerWaitingView()
                            .transition(.opacity)
                    } else {
                        ImposterCardRevealPhaseView(
                            currentCard: currentCard,
                            isMultiplayer: true,
                            onCardTap: {},
                            onCardDismissed: { handleCardDismissed() }
                        )
                        .transition(.opacity)
                    }
                case .playing:
                    if gameSettings.isWaitingForOtherPlayers {
                        MultiplayerWaitingView()
                            .transition(.opacity)
                    } else if gameSettings.multiplayerStartAtHostUptime != nil {
                        ImposterPlayingPhaseView(
                            showStartingPlayerAnnouncement: false,
                            startingPlayerName: startingPlayerDisplayName,
                            isMultiplayerCountdown: true,
                            hintService: hintService,
                            onAnnouncementDone: {}
                        )
                    } else {
                        ImposterPlayingPhaseView(
                            showStartingPlayerAnnouncement: showStartingPlayerAnnouncement,
                            startingPlayerName: startingPlayerDisplayName,
                            isMultiplayerCountdown: false,
                            hintService: hintService,
                            onAnnouncementDone: { beginRoundAfterAnnouncement() }
                        )
                    }
                default:
                    EmptyView()
                }
            } else {
                switch gameSettings.gamePhase {
                case .cardReveal:
                    ImposterCardRevealPhaseView(
                        currentCard: currentCard,
                        isMultiplayer: false,
                        onCardTap: { gameLogic.markCurrentPlayerCardSeen() },
                        onCardDismissed: { handleCardDismissed() }
                    )
                case .playing:
                    ImposterPlayingPhaseView(
                        showStartingPlayerAnnouncement: showStartingPlayerAnnouncement,
                        startingPlayerName: startingPlayerDisplayName,
                        isMultiplayerCountdown: false,
                        hintService: hintService,
                        onAnnouncementDone: { beginRoundAfterAnnouncement() }
                    )
                case .finished:
                    TimeOutResultView()
                        .transition(.opacity)
                default:
                    EmptyView()
                }
            }
        }
    }

    // MARK: - Logic

    private var startingPlayerDisplayName: String? {
        if let name = gameSettings.startingPlayerName, !name.isEmpty { return name }
        return startingPlayer?.name
    }

    private func requestTimeSyncSamplesIfNeeded() {
        guard isMultiplayerActive else { return }
        if MultipeerManager.shared.role == .host {
            gameSettings.hostClockOffset = 0
            gameSettings.hostClockOffsetRTT = 0
            return
        }
        guard !didRequestTimeSync else { return }
        didRequestTimeSync = true
        Task {
            for index in 0..<5 {
                if index > 0 { try? await Task.sleep(for: .milliseconds(250)) }
                sendTimeSyncPing()
            }
        }
    }

    private func sendRejoinRequestIfNeeded() {
        let mpc = MultipeerManager.shared
        guard isMultiplayerActive, mpc.role == .peer else { return }
        guard !didSendRejoinRequest else { return }
        guard !mpc.connectedPeers.isEmpty else { return }
        let payload = ImposterRejoinRequestPayload(
            playerName: mpc.myPeerId.displayName,
            playerId: mpc.playerId
        )
        mpc.sendToHost(event: MPCEventType.imposterRejoinRequest, object: payload)
        didSendRejoinRequest = true
    }

    private func sendTimeSyncPing() {
        let payload = ImposterTimeSyncPingPayload(
            clientName: MultipeerManager.shared.myPeerId.displayName,
            pingId: UUID(),
            clientSendUptime: ProcessInfo.processInfo.systemUptime
        )
        MultipeerManager.shared.sendToHost(event: MPCEventType.imposterTimeSyncPing, object: payload)
    }

    private func startGame() {
        gameLogic.stopGameTimer()

        if isMultiplayerActive {
            prepareMultiplayerCardIfNeeded()
            return
        }

        if gameSettings.gamePhase == .setup {
            Task { @MainActor in
                await gameLogic.startGame()
                prepareNextCard()
            }
        } else {
            prepareNextCard()
        }
    }

    private func prepareMultiplayerCardIfNeeded() {
        guard !hasRevealedOwnCard else { return }
        guard let player = gameLogic.currentPlayer else { return }
        let myName = MultipeerManager.shared.myPeerId.displayName
        guard player.name == myName else { return }
        if currentCard?.player.name != player.name { currentCard = nil }
        if currentCard == nil { prepareNextCard() }
        myPlayerIdentity = PlayerIdentity(from: player)
    }

    private func markMultiplayerCardSeen() {
        let myName = MultipeerManager.shared.myPeerId.displayName
        if let myIndex = gameSettings.players.firstIndex(where: { $0.name == myName }) {
            gameSettings.players[myIndex].hasSeenCard = true
        }
        withAnimation { gameSettings.isWaitingForOtherPlayers = true }

        let payload = ImposterCardSeenPayload(playerName: myName)
        if MultipeerManager.shared.role == .host {
            let payloadData = try? JSONEncoder().encode(payload)
            MultipeerManager.shared.injectLocalEvent(type: MPCEventType.imposterCardSeen, payload: payloadData)
        } else {
            MultipeerManager.shared.sendToHost(event: MPCEventType.imposterCardSeen, object: payload)
        }
    }

    private func prepareNextCard() {
        guard let player = gameLogic.currentPlayer,
              let category = gameSettings.roundCategory ?? gameSettings.selectedCategory else { return }
        currentCard = GameCard(player: player, category: category)
    }

    private func handleCardDismissed() {
        if isMultiplayerActive {
            hasRevealedOwnCard = true
            markMultiplayerCardSeen()
            return
        }

        let isLastPlayer = gameSettings.currentPlayerIndex >= gameSettings.players.count - 1

        if isLastPlayer {
            if MultipeerManager.shared.role == .host || MultipeerManager.shared.role == .unknown {
                let picked = gameSettings.pickStartingPlayer()
                startingPlayer = picked
                gameLogic.broadcastGameState()
            }
            gameSettings.isTimerPaused = true
            showStartingPlayerAnnouncement = true
        }

        gameLogic.nextPlayer()

        if gameSettings.gamePhase == .cardReveal {
            prepareNextCard()
        }
    }

    private func beginRoundAfterAnnouncement() {
        withAnimation { showStartingPlayerAnnouncement = false }
        gameSettings.isTimerPaused = false
    }

    private func resetLocalState() {
        currentCard = nil
        hasRevealedOwnCard = false
        showStartingPlayerAnnouncement = false
        startingPlayer = nil
        myPlayerIdentity = nil
        didSendRejoinRequest = false
    }
}

// MARK: - Player Identity (Equatable snapshot für onChange-Vergleiche)
private struct PlayerIdentity: Equatable {
    let name: String
    let word: String
    let isImposter: Bool
    let roleType: RoleType?
    let role: String?

    init?(from player: Player?) {
        guard let player else { return nil }
        name = player.name
        word = player.word
        isImposter = player.isImposter
        roleType = player.roleType
        role = player.role
    }
}

#Preview {
    let settings = GameSettings()
    settings.players = [Player(name: "Demo"), Player(name: "Demo 2")]
    return GamePlayView()
        .environment(settings)
        .environment(GameLogic(gameSettings: settings))
}
