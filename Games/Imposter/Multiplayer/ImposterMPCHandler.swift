import Foundation
import MultipeerConnectivity

// MARK: - Imposter Multiplayer Event-Handler
// Routet eingehende MPC-Events an GameSettings/GameLogic.
// Wird in GameLogic gehalten und über setupMPCListeners aktiviert.

@MainActor
final class ImposterMPCHandler {
    weak var gameSettings: GameSettings?
    weak var gameLogic: GameLogic?
    var onNavigate: ((SetupRoute?) -> Void)?

    private var listenerTask: Task<Void, Never>?
    private let decoder = JSONDecoder()

    func activate(gameSettings: GameSettings, gameLogic: GameLogic, onNavigate: @escaping (SetupRoute?) -> Void) {
        self.gameSettings = gameSettings
        self.gameLogic = gameLogic
        self.onNavigate = onNavigate
        listenerTask = Task { @MainActor [weak self] in
            for await event in MultipeerManager.shared.events {
                guard let self, !Task.isCancelled else { break }
                self.handle(event)
            }
        }
    }

    func deactivate() {
        listenerTask?.cancel()
        listenerTask = nil
        gameSettings = nil
        gameLogic = nil
        onNavigate = nil
    }

    // MARK: - Event Routing

    private func handle(_ event: MPCEvent) {
        guard let gs = gameSettings, let gl = gameLogic else { return }
        let mpc = MultipeerManager.shared

        switch event.type {

        case MPCEventType.imposterSyncConfig:
            guard let d = event.payload,
                  let config = try? decoder.decode(ImposterGameConfig.self, from: d) else { return }
            gs.applyMPCConfig(config)
            gs.timeRemaining = gs.timeLimit

        case MPCEventType.imposterRoleAssignment:
            guard let d = event.payload,
                  let roleInfo = try? decoder.decode(ImposterRolePayload.self, from: d) else { return }
            let myName = mpc.myPeerId.displayName
            if gs.players.isEmpty {
                gs.players = mpc.lobbyPeers.map { Player(name: $0) }
            }
            if let myIndex = gs.players.firstIndex(where: { $0.name == myName }) {
                gs.players[myIndex].word = roleInfo.word
                gs.players[myIndex].isImposter = roleInfo.isImposter
                gs.players[myIndex].roleType = nil
                gs.players[myIndex].role = nil
                gs.players[myIndex].hasSeenCard = false
                gs.currentPlayerIndex = myIndex
                gs.isWaitingForOtherPlayers = false
                gs.gamePhase = .cardReveal
                if let realCat = gs.categories.first(where: { $0.name == roleInfo.categoryName }) {
                    gs.roundCategory = realCat
                } else {
                    var dummy = Category(name: roleInfo.categoryName, words: [])
                    dummy.isCustom = true
                    gs.roundCategory = dummy
                }
            }
            if let assignmentId = roleInfo.assignmentId, mpc.role == .peer {
                let ack = ImposterRoleAckPayload(assignmentId: assignmentId, playerName: myName)
                mpc.sendToHost(event: MPCEventType.imposterRoleAck, object: ack)
            }
            onNavigate?(.game)
            gs.shouldDismissSheets = true

        case MPCEventType.imposterRevealStart:
            gs.gamePhase = .cardReveal
            gs.isTimerPaused = true
            gs.timeRemaining = gs.timeLimit
            gs.isWaitingForOtherPlayers = false
            gs.multiplayerStartAtHostUptime = nil
            gs.revealProgress = (0, max(1, gs.players.count))
            onNavigate?(.game)

        case MPCEventType.gameStart:
            if let d = event.payload,
               let startPayload = try? decoder.decode(ImposterGameStartPayload.self, from: d) {
                gs.gamePhase = .playing
                gs.isTimerPaused = true
                gs.timeRemaining = gs.timeLimit
                gs.isWaitingForOtherPlayers = false
                gs.startingPlayerName = startPayload.startingPlayerName
                gs.multiplayerStartAtHostUptime = startPayload.startAtHostUptime
                gl.scheduleMultiplayerStart(startAtHostUptime: startPayload.startAtHostUptime)
            } else {
                gs.gamePhase = .playing
                gs.isTimerPaused = true
                gs.timeRemaining = gs.timeLimit
                gs.isWaitingForOtherPlayers = false
                gs.multiplayerStartAtHostUptime = nil
                gl.scheduleMultiplayerStart(startAtHostUptime: ProcessInfo.processInfo.systemUptime)
            }
            onNavigate?(.game)

        case MPCEventType.imposterRevealProgress:
            guard let d = event.payload,
                  let progress = try? decoder.decode(ImposterRevealProgressPayload.self, from: d) else { return }
            gs.revealProgress = (progress.readyCount, progress.totalCount)

        case MPCEventType.imposterTimerSync:
            guard let d = event.payload,
                  let sync = try? decoder.decode(ImposterGameStateSync.self, from: d) else { return }
            gs.isTimerPaused = sync.isTimerPaused
            gs.gamePhase = sync.gamePhase
            if mpc.role != .peer {
                gs.currentPlayerIndex = sync.currentPlayerIndex
            }
            gs.startingPlayerName = sync.startingPlayerName
            gl.applyRemoteTimerSync(sync, hostClockOffset: gs.hostClockOffset)

        case MPCEventType.imposterHostActivity:
            guard let d = event.payload,
                  let info = try? decoder.decode(ImposterHostActivityPayload.self, from: d) else { return }
            mpc.hostActivity = info.message

        case MPCEventType.imposterTimeSyncPing:
            guard mpc.role == .host,
                  let d = event.payload,
                  let ping = try? decoder.decode(ImposterTimeSyncPingPayload.self, from: d) else { return }
            let hostReceiveUptime = ProcessInfo.processInfo.systemUptime
            let pong = ImposterTimeSyncPongPayload(
                clientName: ping.clientName,
                pingId: ping.pingId,
                clientSendUptime: ping.clientSendUptime,
                hostReceiveUptime: hostReceiveUptime,
                hostSendUptime: ProcessInfo.processInfo.systemUptime
            )
            mpc.sendToAll(event: MPCEventType.imposterTimeSyncPong, object: pong)

        case MPCEventType.imposterTimeSyncPong:
            guard let d = event.payload,
                  let pong = try? decoder.decode(ImposterTimeSyncPongPayload.self, from: d) else { return }
            let myName = mpc.myPeerId.displayName
            guard pong.clientName == myName else { return }
            let receiveUptime = ProcessInfo.processInfo.systemUptime
            let hostDelta = pong.hostSendUptime - pong.hostReceiveUptime
            let rtt = max(0, (receiveUptime - pong.clientSendUptime) - hostDelta)
            let offset = ((pong.hostReceiveUptime - pong.clientSendUptime) + (pong.hostSendUptime - receiveUptime)) / 2
            if rtt < gs.hostClockOffsetRTT {
                gs.hostClockOffsetRTT = rtt
                gs.hostClockOffset = offset
            }

        case MPCEventType.playerReadyUpdate:
            guard let d = event.payload,
                  let info = try? decoder.decode(ImposterReadyStatusPayload.self, from: d) else { return }
            if info.isReady {
                mpc.readyPlayers.insert(info.playerName)
            } else {
                mpc.readyPlayers.remove(info.playerName)
            }
            if mpc.role == .host {
                let validPlayers = Set(mpc.lobbyPeers)
                mpc.readyPlayers = mpc.readyPlayers.intersection(validPlayers)
                mpc.sendToAll(event: MPCEventType.lobbyStateSync, object: Array(mpc.readyPlayers))
            }

        case MPCEventType.lobbyStateSync:
            guard let d = event.payload,
                  let list = try? decoder.decode([String].self, from: d) else { return }
            mpc.readyPlayers = Set(list)

        case MPCEventType.imposterStartVoting:
            if let d = event.payload,
               let status = try? decoder.decode(ImposterVotingStatusPayload.self, from: d) {
                gs.multiplayerVotingProgress = status
                gs.multiplayerVoteTally = status.tally ?? [:]
            } else {
                let total = gs.players.filter { !$0.isEliminated }.count
                gs.multiplayerVotingProgress = ImposterVotingStatusPayload(votesReceived: 0, totalVoters: total, tally: nil)
                gs.multiplayerVoteTally = [:]
            }
            gs.multiplayerVotingSelection = nil
            gs.multiplayerVotingResult = nil
            gs.shouldPresentVoting = true

        case MPCEventType.imposterVotePreview:
            guard mpc.role == .host,
                  let d = event.payload,
                  let preview = try? decoder.decode(ImposterVotePreviewPayload.self, from: d) else { return }
            gl.handleMultiplayerVotePreview(preview)

        case MPCEventType.imposterRoleAck:
            guard mpc.role == .host,
                  let d = event.payload,
                  let ack = try? decoder.decode(ImposterRoleAckPayload.self, from: d) else { return }
            gl.handleRoleAck(ack)

        case MPCEventType.imposterRejoinRequest:
            guard mpc.role == .host,
                  let d = event.payload,
                  let request = try? decoder.decode(ImposterRejoinRequestPayload.self, from: d) else { return }
            gl.registerPlayerIdentity(playerName: request.playerName, playerId: request.playerId)
            if let peer = mpc.getPeer(byName: request.playerName),
               let state = gl.makeRejoinStatePayload(for: request.playerName) {
                mpc.sendToPeer(event: MPCEventType.imposterRejoinState, object: state, to: peer)
            }

        case MPCEventType.imposterRejoinState:
            guard mpc.role == .peer,
                  let d = event.payload,
                  let state = try? decoder.decode(ImposterRejoinStatePayload.self, from: d) else { return }
            gs.applyMPCConfig(state.config)
            gs.timeRemaining = state.config.timeLimit
            if gs.players.isEmpty {
                gs.players = mpc.lobbyPeers.map { Player(name: $0) }
            }
            let myName = state.playerName
            if let myIndex = gs.players.firstIndex(where: { $0.name == myName }) {
                gs.players[myIndex].word = state.role.word
                gs.players[myIndex].isImposter = state.role.isImposter
                gs.players[myIndex].roleType = nil
                gs.players[myIndex].role = nil
                gs.players[myIndex].hasSeenCard = state.playerHasSeenCard
            } else {
                var me = Player(name: myName)
                me.word = state.role.word
                me.isImposter = state.role.isImposter
                me.hasSeenCard = state.playerHasSeenCard
                gs.players.append(me)
            }
            if let realCat = gs.categories.first(where: { $0.name == state.role.categoryName }) {
                gs.roundCategory = realCat
            } else {
                var dummy = Category(name: state.role.categoryName, words: [])
                dummy.isCustom = true
                gs.roundCategory = dummy
            }
            gs.gamePhase = state.gameState.gamePhase
            gs.timeRemaining = state.gameState.timeRemaining
            gs.isTimerPaused = state.gameState.isTimerPaused
            gs.currentPlayerIndex = state.gameState.currentPlayerIndex
            gs.startingPlayerName = state.gameState.startingPlayerName
            gs.multiplayerStartAtHostUptime = state.multiplayerStartAtHostUptime
            if let progress = state.revealProgress {
                gs.revealProgress = (progress.readyCount, progress.totalCount)
            } else {
                gs.revealProgress = nil
            }
            gs.isWaitingForOtherPlayers = state.gameState.gamePhase == .cardReveal ? state.playerHasSeenCard : false
            gl.applyRemoteTimerSync(state.gameState, hostClockOffset: gs.hostClockOffset)
            if state.gameState.gamePhase == .playing, let startAt = state.multiplayerStartAtHostUptime {
                gl.scheduleMultiplayerStart(startAtHostUptime: startAt)
            }
            onNavigate?(.game)
            gs.shouldDismissSheets = true

        case MPCEventType.imposterVotingStatus:
            guard let d = event.payload,
                  let status = try? decoder.decode(ImposterVotingStatusPayload.self, from: d) else { return }
            gs.multiplayerVotingProgress = status
            if let tally = status.tally {
                gs.multiplayerVoteTally = tally
            }

        case MPCEventType.imposterVotingResult:
            guard let d = event.payload,
                  let result = try? decoder.decode(ImposterVotingResultPayload.self, from: d) else { return }
            gs.multiplayerVotingResult = result

        case MPCEventType.imposterWordGuessConfirmed:
            guard let d = event.payload,
                  let result = try? decoder.decode(ImposterWordGuessResultPayload.self, from: d) else { return }
            gs.isTimerPaused = true
            gs.multiplayerWordGuessResult = result

        case MPCEventType.imposterRematchOffer:
            guard let d = event.payload,
                  let offer = try? decoder.decode(ImposterRematchOfferPayload.self, from: d) else { return }
            gs.multiplayerRematchOffer = offer

        case MPCEventType.imposterRematchResponse:
            guard mpc.role == .host,
                  let d = event.payload,
                  let response = try? decoder.decode(ImposterRematchResponsePayload.self, from: d) else { return }
            gl.handleMultiplayerRematchResponse(response)

        case MPCEventType.imposterCardSeen:
            guard mpc.role == .host,
                  let d = event.payload,
                  let seen = try? decoder.decode(ImposterCardSeenPayload.self, from: d) else { return }
            if let index = gs.players.firstIndex(where: { $0.name == seen.playerName }) {
                gs.players[index].hasSeenCard = true
            }
            let readyCount = gs.players.filter { $0.hasSeenCard }.count
            let totalCount = gs.players.count
            let progressPayload = ImposterRevealProgressPayload(readyCount: readyCount, totalCount: totalCount)
            mpc.sendToAll(event: MPCEventType.imposterRevealProgress, object: progressPayload)
            gs.revealProgress = (readyCount, totalCount)
            if readyCount == totalCount, gs.multiplayerStartAtHostUptime == nil {
                Task { @MainActor [weak self] in
                    try? await Task.sleep(for: .seconds(1))
                    guard let self, let gs = self.gameSettings, let gl = self.gameLogic else { return }
                    let countdownSeconds = 3
                    let startAtHostUptime = ProcessInfo.processInfo.systemUptime + Double(countdownSeconds)
                    let startingPlayer = gs.players.randomElement()
                    gs.startingPlayerName = startingPlayer?.name
                    gs.multiplayerStartAtHostUptime = startAtHostUptime
                    gs.gamePhase = .playing
                    gs.isTimerPaused = true
                    gs.timeRemaining = gs.timeLimit
                    let startPayload = ImposterGameStartPayload(
                        startingPlayerName: startingPlayer?.name,
                        startAtHostUptime: startAtHostUptime,
                        countdownSeconds: countdownSeconds
                    )
                    mpc.sendToAll(event: MPCEventType.gameStart, object: startPayload)
                    gs.isWaitingForOtherPlayers = false
                    gl.scheduleMultiplayerStart(startAtHostUptime: startAtHostUptime)
                }
            }

        case MPCEventType.imposterVoteCast:
            guard mpc.role == .host,
                  let d = event.payload,
                  let vote = try? decoder.decode(ImposterVoteCastPayload.self, from: d) else { return }
            gl.handleMultiplayerVoteCast(vote)

        case MPCEventType.imposterGameOver:
            gs.gamePhase = .finished

        case MPCEventType.gameAbort:
            onNavigate?(nil)

        default:
            break
        }
    }
}

// Lokales Payload-Struct für Ready-Status (nur intern)
private struct ImposterReadyStatusPayload: Codable {
    let playerName: String
    let isReady: Bool
}
