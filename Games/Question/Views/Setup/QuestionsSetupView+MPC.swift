//
//  QuestionsSetupView+MPC.swift
//  Games Collection
//
//  Created by Gemini on 17.01.2026.
//

import SwiftUI
import MultipeerConnectivity
import Foundation

extension QuestionsSetupView {
    
    // MARK: - MPC Listeners
    
    func setupMPCListeners(viewModel: QuestionsGameViewModel, route: Binding<SetupRoute?>) {
        let mpc = MultipeerManager.shared
        
        mpc.onEventReceived = { event, payload in
            print("🧪 [MPC] Event empfangen: \(event)")
            DispatchQueue.main.async {
                switch event {
                case MPCEventType.questionsSyncConfig:
                    if let data = payload,
                       let config = try? JSONDecoder().decode(QuestionsConfig.self, from: data) {
                        print("🧪 [CLIENT] Konfiguration und Spielerliste synchronisiert")
                        viewModel.selectedCategory = config.selectedCategory
                        viewModel.numberOfLiars = config.numberOfLiars
                        viewModel.discussionTime = config.discussionTime
                        
                        if !config.players.isEmpty {
                            appModel.players = config.players
                        }
                    }
                    
                case MPCEventType.gameStart:
                    print("🧪 [CLIENT] Start-Signal empfangen")
                    viewModel.startRound()
                    
                case MPCEventType.questionsRoleAssignment:
                    if let data = payload,
                       let assignment = try? JSONDecoder().decode(QuestionsRolePayload.self, from: data) {
                        print("🧪 [CLIENT] Rolle erhalten: \(assignment.role)")
                        viewModel.myRole = assignment.role
                        viewModel.myPrompt = assignment.prompt
                        viewModel.showQuestionToCurrentPlayer = true
                        let ack = QuestionsRoleAckPayload(playerName: mpc.myPeerId.displayName)
                        mpc.sendToHost(event: MPCEventType.questionsRoleAck, object: ack)
                    }
                    
                case MPCEventType.questionsStateSync:
                    if let data = payload,
                       let roundState = try? JSONDecoder().decode(QuestionsRoundState.self, from: data) {
                        print("🧪 [ANY] State-Sync erhalten. Phase: \(roundState.phase), Antworten: \(roundState.answers.count)")
                        viewModel.applyRoundStateSync(roundState)
                    }
                    
                case MPCEventType.questionsAnswerSubmitted:
                    guard mpc.role == .host else { break }
                    if let data = payload,
                       let answer = try? JSONDecoder().decode(QuestionsAnswer.self, from: data) {
                        print("🧪 [HOST] Remote-Antwort erhalten für ID: \(answer.playerID)")
                        viewModel.registerRemoteAnswer(answer)
                    }
                    
                case MPCEventType.questionsVoteCast:
                    guard mpc.role == .host else { break }
                    if let data = payload,
                       let cast = try? JSONDecoder().decode(QuestionsVoteCastPayload.self, from: data) {
                        viewModel.registerRemoteVote(cast)
                    }
                    
                case MPCEventType.questionsVotingStatus:
                    if let data = payload,
                       let status = try? JSONDecoder().decode(QuestionsVotingStatusPayload.self, from: data) {
                        viewModel.applyVotingStatus(status)
                    }
                    
                case MPCEventType.questionsRoleAck:
                    guard mpc.role == .host else { break }
                    if let data = payload,
                       let ack = try? JSONDecoder().decode(QuestionsRoleAckPayload.self, from: data) {
                        viewModel.registerRoleAck(playerName: ack.playerName)
                    }
                    
                case MPCEventType.questionsVotingResult:
                    if let data = payload,
                       let evaluation = try? JSONDecoder().decode(QuestionsVoteEvaluation.self, from: data) {
                        viewModel.applyVotingResult(evaluation)
                    }
                    
                case MPCEventType.questionsTimerSync:
                    if let data = payload,
                       let sync = try? JSONDecoder().decode(QuestionsTimerSyncPayload.self, from: data) {
                        viewModel.applyTimerSync(sync)
                    }
                    
                case MPCEventType.questionsTimeSyncPing:
                    guard mpc.role == .host else { break }
                    if let data = payload,
                       let ping = try? JSONDecoder().decode(QuestionsTimeSyncPingPayload.self, from: data) {
                        let hostReceiveUptime = ProcessInfo.processInfo.systemUptime
                        let pong = QuestionsTimeSyncPongPayload(
                            clientName: ping.clientName,
                            pingId: ping.pingId,
                            clientSendUptime: ping.clientSendUptime,
                            hostReceiveUptime: hostReceiveUptime,
                            hostSendUptime: ProcessInfo.processInfo.systemUptime
                        )
                        mpc.sendToAll(event: MPCEventType.questionsTimeSyncPong, object: pong)
                    }
                    
                case MPCEventType.questionsTimeSyncPong:
                    if let data = payload,
                       let pong = try? JSONDecoder().decode(QuestionsTimeSyncPongPayload.self, from: data) {
                        viewModel.applyTimeSyncPong(pong)
                    }
                    
                case MPCEventType.questionsRejoinRequest:
                    guard mpc.role == .host else { break }
                    if let data = payload,
                       let request = try? JSONDecoder().decode(QuestionsRejoinRequestPayload.self, from: data) {
                        viewModel.handleRejoinRequest(request)
                    }
                    
                case MPCEventType.questionsRejoinState:
                    guard mpc.role == .peer else { break }
                    if let data = payload,
                       let state = try? JSONDecoder().decode(QuestionsRejoinStatePayload.self, from: data) {
                        viewModel.applyRejoinState(state)
                    }
                    
                case MPCEventType.questionsHostActivity:
                    if let data = payload,
                       let info = try? JSONDecoder().decode(QuestionsHostActivityPayload.self, from: data) {
                        mpc.hostActivity = info.message
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
                    
                case MPCEventType.gameAbort:
                    dismiss()
                    
                default:
                    break
                }
            }
        }
    }
    
    // MARK: - Host Logic
    
    func startMPCGame(viewModel: QuestionsGameViewModel) {
        guard MultipeerManager.shared.role == .host else { return }
        // Ensure peers have the latest player IDs and settings.
        broadcastConfig(viewModel: viewModel)
        sendHostActivity("Host startet die Runde")
        // 1. Send signal to start locally and remotely
        MultipeerManager.shared.sendToAll(event: MPCEventType.gameStart)
        
        // 2. Start local round
        onStartGame()
    }
    
    func broadcastConfig(viewModel: QuestionsGameViewModel) {
        guard MultipeerManager.shared.role == .host else { return }
        let config = QuestionsConfig(
            numberOfLiars: viewModel.numberOfLiars,
            selectedCategory: viewModel.selectedCategory,
            discussionTime: viewModel.discussionTime,
            players: appModel.players
        )
        MultipeerManager.shared.sendToAll(event: MPCEventType.questionsSyncConfig, object: config)
    }

    func sendHostActivity(_ message: String) {
        guard MultipeerManager.shared.role == .host else { return }
        let payload = QuestionsHostActivityPayload(message: message)
        MultipeerManager.shared.sendToAll(event: MPCEventType.questionsHostActivity, object: payload)
    }
}

private struct ReadyStatusPayload: Codable {
    let playerName: String
    let isReady: Bool
}
