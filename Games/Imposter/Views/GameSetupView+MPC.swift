import SwiftUI
import MultipeerConnectivity
import Foundation

extension GameSetupView {

    // MARK: - MPC Host Logic
    
    func startMPCGame() {
        guard gameSettings.gameMode == .classic else { return }
        Task { @MainActor in
            let didStart = await gameLogic.startMultiplayerGameAsHost()
            if didStart {
                self.route = .game
            }
        }
    }
    
    // MARK: - MPC Client Listener
    func setupMPCListeners(gameSettings: GameSettings, route: Binding<SetupRoute?>) {
        let mpc = MultipeerManager.shared
        
        mpc.onEventReceived = { event, payload in
            DispatchQueue.main.async {
                switch event {
                case MPCEventType.imposterSyncConfig:
                    if let data = payload,
                       let config = try? JSONDecoder().decode(ImposterGameConfig.self, from: data) {
                        print("MPC Client: Applying Config")
                        gameSettings.applyMPCConfig(config)
                        gameSettings.timeRemaining = gameSettings.timeLimit
                    }
                    
                case MPCEventType.imposterRoleAssignment:
                    if let data = payload,
                       let roleInfo = try? JSONDecoder().decode(ImposterRolePayload.self, from: data) {
                        print("MPC Client: Role Received - \(roleInfo.role)")
                        
                        // Populate local player info
                        let myName = mpc.myPeerId.displayName
                        
                        // Ensure players list is synced (should be via Lobby Update, but safety check)
                        if gameSettings.players.isEmpty {
                            gameSettings.players = mpc.lobbyPeers.map { Player(name: $0) }
                        }
                        
                        // Find self
                        if let myIndex = gameSettings.players.firstIndex(where: { $0.name == myName }) {
                            gameSettings.players[myIndex].word = roleInfo.word
                            gameSettings.players[myIndex].isImposter = roleInfo.isImposter
                            gameSettings.players[myIndex].roleType = nil
                            gameSettings.players[myIndex].role = nil
                            gameSettings.players[myIndex].hasSeenCard = false // RESET SEEN STATE
                            gameSettings.currentPlayerIndex = myIndex // For card view
                            gameSettings.isWaitingForOtherPlayers = false // Reset waiting state
                            gameSettings.gamePhase = .cardReveal // Explicitly set phase
                            
                            // Set Category (Placeholder category for display)
                            if let realCat = gameSettings.categories.first(where: { $0.name == roleInfo.categoryName }) {
                                gameSettings.roundCategory = realCat
                            } else {
                                var dummy = Category(name: roleInfo.categoryName, words: [])
                                dummy.isCustom = true
                                gameSettings.roundCategory = dummy
                            }
                        }

                        if let assignmentId = roleInfo.assignmentId, mpc.role == .peer {
                            let ack = ImposterRoleAckPayload(
                                assignmentId: assignmentId,
                                playerName: myName
                            )
                            mpc.sendToHost(event: MPCEventType.imposterRoleAck, object: ack)
                        }
                        
                        // Navigate to Game View
                        route.wrappedValue = .game
                        
                        // Close any open sheets (Lobby)
                        gameSettings.shouldDismissSheets = true
                    }
                    
                case MPCEventType.imposterRevealStart:
                    gameSettings.gamePhase = .cardReveal
                    gameSettings.isTimerPaused = true
                    gameSettings.timeRemaining = gameSettings.timeLimit
                    gameSettings.isWaitingForOtherPlayers = false
                    gameSettings.multiplayerStartAtHostUptime = nil
                    gameSettings.revealProgress = (0, max(1, gameSettings.players.count))
                    if route.wrappedValue != .game {
                        route.wrappedValue = .game
                    }
                    
                case MPCEventType.gameStart:
                    print("MPC Client: Game Start Signal")
                    if let data = payload,
                       let startPayload = try? JSONDecoder().decode(ImposterGameStartPayload.self, from: data) {
                        gameSettings.gamePhase = .playing
                        gameSettings.isTimerPaused = true
                        gameSettings.timeRemaining = gameSettings.timeLimit
                        gameSettings.isWaitingForOtherPlayers = false // Stop waiting
                        gameSettings.startingPlayerName = startPayload.startingPlayerName
                        gameSettings.multiplayerStartAtHostUptime = startPayload.startAtHostUptime
                        gameLogic.scheduleMultiplayerStart(startAtHostUptime: startPayload.startAtHostUptime)
                        if route.wrappedValue != .game {
                            route.wrappedValue = .game
                        }
                    } else {
                        // Fallback
                        gameSettings.gamePhase = .playing
                        gameSettings.isTimerPaused = true
                        gameSettings.timeRemaining = gameSettings.timeLimit
                        gameSettings.isWaitingForOtherPlayers = false
                        gameSettings.multiplayerStartAtHostUptime = nil
                        gameLogic.scheduleMultiplayerStart(startAtHostUptime: ProcessInfo.processInfo.systemUptime)
                        if route.wrappedValue != .game {
                            route.wrappedValue = .game
                        }
                    }
                    
                case MPCEventType.imposterRevealProgress:
                     if let data = payload,
                        let progress = try? JSONDecoder().decode(ImposterRevealProgressPayload.self, from: data) {
                         gameSettings.revealProgress = (progress.readyCount, progress.totalCount)
                     }
                    
                case MPCEventType.imposterTimerSync:
                    if let data = payload,
                       let sync = try? JSONDecoder().decode(ImposterGameStateSync.self, from: data) {
                        // Apply sync
                        gameSettings.isTimerPaused = sync.isTimerPaused
                        gameSettings.gamePhase = sync.gamePhase
                        if mpc.role != .peer {
                            gameSettings.currentPlayerIndex = sync.currentPlayerIndex
                        }
                        gameSettings.startingPlayerName = sync.startingPlayerName
                        gameLogic.applyRemoteTimerSync(sync, hostClockOffset: gameSettings.hostClockOffset)
                    }

                case MPCEventType.imposterHostActivity:
                    if let data = payload,
                       let info = try? JSONDecoder().decode(ImposterHostActivityPayload.self, from: data) {
                        mpc.hostActivity = info.message
                    }

                case MPCEventType.imposterTimeSyncPing:
                    guard mpc.role == .host else { break }
                    if let data = payload,
                       let ping = try? JSONDecoder().decode(ImposterTimeSyncPingPayload.self, from: data) {
                        let hostReceiveUptime = ProcessInfo.processInfo.systemUptime
                        let pong = ImposterTimeSyncPongPayload(
                            clientName: ping.clientName,
                            pingId: ping.pingId,
                            clientSendUptime: ping.clientSendUptime,
                            hostReceiveUptime: hostReceiveUptime,
                            hostSendUptime: ProcessInfo.processInfo.systemUptime
                        )
                        mpc.sendToAll(event: MPCEventType.imposterTimeSyncPong, object: pong)
                    }

                case MPCEventType.imposterTimeSyncPong:
                    if let data = payload,
                       let pong = try? JSONDecoder().decode(ImposterTimeSyncPongPayload.self, from: data) {
                        let myName = mpc.myPeerId.displayName
                        guard pong.clientName == myName else { break }
                        let receiveUptime = ProcessInfo.processInfo.systemUptime
                        let outbound = pong.clientSendUptime
                        let inbound = receiveUptime
                        let hostDelta = pong.hostSendUptime - pong.hostReceiveUptime
                        let rtt = max(0, (inbound - outbound) - hostDelta)
                        let offset = ((pong.hostReceiveUptime - outbound) + (pong.hostSendUptime - inbound)) / 2
                        if rtt < gameSettings.hostClockOffsetRTT {
                            gameSettings.hostClockOffsetRTT = rtt
                            gameSettings.hostClockOffset = offset
                        }
                    }
                    
                case MPCEventType.playerReadyUpdate:
                    if let data = payload,
                       let info = try? JSONDecoder().decode(ReadyStatusPayload.self, from: data) {
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
                    }

                case MPCEventType.lobbyStateSync:
                    if let data = payload,
                       let list = try? JSONDecoder().decode([String].self, from: data) {
                        mpc.readyPlayers = Set(list)
                    }

                case MPCEventType.imposterStartVoting:
                    if let data = payload,
                       let status = try? JSONDecoder().decode(ImposterVotingStatusPayload.self, from: data) {
                        gameSettings.multiplayerVotingProgress = status
                        if let tally = status.tally {
                            gameSettings.multiplayerVoteTally = tally
                        } else {
                            gameSettings.multiplayerVoteTally = [:]
                        }
                    } else {
                        let total = gameSettings.players.filter { !$0.isEliminated }.count
                        gameSettings.multiplayerVotingProgress = ImposterVotingStatusPayload(votesReceived: 0, totalVoters: total, tally: nil)
                        gameSettings.multiplayerVoteTally = [:]
                    }
                    gameSettings.multiplayerVotingSelection = nil
                    gameSettings.multiplayerVotingResult = nil
                    gameSettings.shouldPresentVoting = true

                case MPCEventType.imposterVotePreview:
                    guard mpc.role == .host else { break }
                    if let data = payload,
                       let preview = try? JSONDecoder().decode(ImposterVotePreviewPayload.self, from: data) {
                        gameLogic.handleMultiplayerVotePreview(preview)
                    }

                case MPCEventType.imposterRoleAck:
                    guard mpc.role == .host else { break }
                    if let data = payload,
                       let ack = try? JSONDecoder().decode(ImposterRoleAckPayload.self, from: data) {
                        gameLogic.handleRoleAck(ack)
                    }

                case MPCEventType.imposterRejoinRequest:
                    guard mpc.role == .host else { break }
                    if let data = payload,
                       let request = try? JSONDecoder().decode(ImposterRejoinRequestPayload.self, from: data) {
                        gameLogic.registerPlayerIdentity(playerName: request.playerName, playerId: request.playerId)
                        if let peer = mpc.getPeer(byName: request.playerName),
                           let state = gameLogic.makeRejoinStatePayload(for: request.playerName) {
                            mpc.sendToPeer(event: MPCEventType.imposterRejoinState, object: state, to: peer)
                        }
                    }

                case MPCEventType.imposterRejoinState:
                    guard mpc.role == .peer else { break }
                    if let data = payload,
                       let state = try? JSONDecoder().decode(ImposterRejoinStatePayload.self, from: data) {
                        gameSettings.applyMPCConfig(state.config)
                        gameSettings.timeRemaining = state.config.timeLimit

                        if gameSettings.players.isEmpty {
                            gameSettings.players = mpc.lobbyPeers.map { Player(name: $0) }
                        }

                        let myName = state.playerName
                        if let myIndex = gameSettings.players.firstIndex(where: { $0.name == myName }) {
                            gameSettings.players[myIndex].word = state.role.word
                            gameSettings.players[myIndex].isImposter = state.role.isImposter
                            gameSettings.players[myIndex].roleType = nil
                            gameSettings.players[myIndex].role = nil
                            gameSettings.players[myIndex].hasSeenCard = state.playerHasSeenCard
                        } else {
                            var me = Player(name: myName)
                            me.word = state.role.word
                            me.isImposter = state.role.isImposter
                            me.hasSeenCard = state.playerHasSeenCard
                            gameSettings.players.append(me)
                        }

                        if let realCat = gameSettings.categories.first(where: { $0.name == state.role.categoryName }) {
                            gameSettings.roundCategory = realCat
                        } else {
                            var dummy = Category(name: state.role.categoryName, words: [])
                            dummy.isCustom = true
                            gameSettings.roundCategory = dummy
                        }

                        gameSettings.gamePhase = state.gameState.gamePhase
                        gameSettings.timeRemaining = state.gameState.timeRemaining
                        gameSettings.isTimerPaused = state.gameState.isTimerPaused
                        gameSettings.currentPlayerIndex = state.gameState.currentPlayerIndex
                        gameSettings.startingPlayerName = state.gameState.startingPlayerName
                        gameSettings.multiplayerStartAtHostUptime = state.multiplayerStartAtHostUptime
                        if let progress = state.revealProgress {
                            gameSettings.revealProgress = (progress.readyCount, progress.totalCount)
                        } else {
                            gameSettings.revealProgress = nil
                        }

                        if state.gameState.gamePhase == .cardReveal {
                            gameSettings.isWaitingForOtherPlayers = state.playerHasSeenCard
                        } else {
                            gameSettings.isWaitingForOtherPlayers = false
                        }

                        gameLogic.applyRemoteTimerSync(state.gameState, hostClockOffset: gameSettings.hostClockOffset)

                        if state.gameState.gamePhase == .playing,
                           let startAt = state.multiplayerStartAtHostUptime {
                            gameLogic.scheduleMultiplayerStart(startAtHostUptime: startAt)
                        }

                        if route.wrappedValue != .game {
                            route.wrappedValue = .game
                        }
                        
                        // Close Lobby sheet
                        gameSettings.shouldDismissSheets = true
                    }

                case MPCEventType.imposterVotingStatus:
                    if let data = payload,
                       let status = try? JSONDecoder().decode(ImposterVotingStatusPayload.self, from: data) {
                        gameSettings.multiplayerVotingProgress = status
                        if let tally = status.tally {
                            gameSettings.multiplayerVoteTally = tally
                        }
                    }

                case MPCEventType.imposterVotingResult:
                    if let data = payload,
                       let result = try? JSONDecoder().decode(ImposterVotingResultPayload.self, from: data) {
                        gameSettings.multiplayerVotingResult = result
                    }

                case MPCEventType.imposterWordGuessConfirmed:
                    if let data = payload,
                       let result = try? JSONDecoder().decode(ImposterWordGuessResultPayload.self, from: data) {
                        gameSettings.isTimerPaused = true
                        gameSettings.multiplayerWordGuessResult = result
                    }

                case MPCEventType.imposterRematchOffer:
                    if let data = payload,
                       let offer = try? JSONDecoder().decode(ImposterRematchOfferPayload.self, from: data) {
                        gameSettings.multiplayerRematchOffer = offer
                    }

                case MPCEventType.imposterRematchResponse:
                    guard mpc.role == .host else { break }
                    if let data = payload,
                       let response = try? JSONDecoder().decode(ImposterRematchResponsePayload.self, from: data) {
                        gameLogic.handleMultiplayerRematchResponse(response)
                    }

                case MPCEventType.imposterCardSeen:
                    guard mpc.role == .host else { break }
                    if let data = payload,
                       let seen = try? JSONDecoder().decode(ImposterCardSeenPayload.self, from: data) {
                        
                        // 1. Mark player as ready
                        if let index = gameSettings.players.firstIndex(where: { $0.name == seen.playerName }) {
                            gameSettings.players[index].hasSeenCard = true
                        }
                        
                        // 2. Calculate Progress
                        let readyCount = gameSettings.players.filter { $0.hasSeenCard }.count
                        let totalCount = gameSettings.players.count
                        
                        // 3. Broadcast Progress
                        let progressPayload = ImposterRevealProgressPayload(readyCount: readyCount, totalCount: totalCount)
                        mpc.sendToAll(event: MPCEventType.imposterRevealProgress, object: progressPayload)
                        
                        // Update Host UI
                        gameSettings.revealProgress = (readyCount, totalCount)
                        
                        // 4. Check Start Condition
                        if readyCount == totalCount, gameSettings.multiplayerStartAtHostUptime == nil {
                            // Delay slightly to let everyone see "5/5"
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                let countdownSeconds = 3
                                let startAtHostUptime = ProcessInfo.processInfo.systemUptime + Double(countdownSeconds)
                                let startingPlayer = gameSettings.players.randomElement()
                                gameSettings.startingPlayerName = startingPlayer?.name
                                gameSettings.multiplayerStartAtHostUptime = startAtHostUptime
                                gameSettings.gamePhase = .playing
                                gameSettings.isTimerPaused = true
                                gameSettings.timeRemaining = gameSettings.timeLimit
                                let startPayload = ImposterGameStartPayload(
                                    startingPlayerName: startingPlayer?.name,
                                    startAtHostUptime: startAtHostUptime,
                                    countdownSeconds: countdownSeconds
                                )
                                mpc.sendToAll(event: MPCEventType.gameStart, object: startPayload)
                                gameSettings.isWaitingForOtherPlayers = false
                                self.gameLogic.scheduleMultiplayerStart(startAtHostUptime: startAtHostUptime)
                            }
                        }
                    }
                    
                case MPCEventType.imposterVoteCast:
                    guard mpc.role == .host else { break }
                    if let data = payload,
                       let vote = try? JSONDecoder().decode(ImposterVoteCastPayload.self, from: data) {
                        gameLogic.handleMultiplayerVoteCast(vote)
                    }
                    
                case MPCEventType.imposterGameOver:
                    print("MPC Client: Game Over")
                    gameSettings.gamePhase = .finished
                    
                case MPCEventType.gameAbort:
                    print("MPC Client: Game Aborted")
                    route.wrappedValue = nil
                    
                default:
                    break
                }
            }
        }
    }
}

private struct ReadyStatusPayload: Codable {
    let playerName: String
    let isReady: Bool
}
