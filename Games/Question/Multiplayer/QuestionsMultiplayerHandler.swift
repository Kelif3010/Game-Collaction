import Foundation
import MultipeerConnectivity

@MainActor
final class QuestionsMultiplayerHandler {
    weak var viewModel: QuestionsGameViewModel?
    var onDismiss: (() -> Void)?
    private var listenerTask: Task<Void, Never>?
    private let decoder = JSONDecoder()

    func activate(viewModel: QuestionsGameViewModel, onDismiss: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onDismiss = onDismiss
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
        viewModel = nil
        onDismiss = nil
    }

    private func handle(_ event: MPCEvent) {
        let mpc = MultipeerManager.shared
        guard let viewModel else { return }

        switch event.type {
        case MPCEventType.questionsSyncConfig:
            if let data = event.payload,
               let config = try? decoder.decode(QuestionsConfig.self, from: data) {
                viewModel.selectedCategory = config.selectedCategory
                viewModel.numberOfLiars = config.numberOfLiars
                viewModel.discussionTime = config.discussionTime
                if !config.players.isEmpty {
                    viewModel.appModel.players = config.players
                }
            }

        case MPCEventType.gameStart:
            viewModel.startRound()

        case MPCEventType.questionsRoleAssignment:
            if let data = event.payload,
               let assignment = try? decoder.decode(QuestionsRolePayload.self, from: data) {
                viewModel.myRole = assignment.role
                viewModel.myPrompt = assignment.prompt
                viewModel.showQuestionToCurrentPlayer = true
                let ack = QuestionsRoleAckPayload(playerName: mpc.myPeerId.displayName)
                mpc.sendToHost(event: MPCEventType.questionsRoleAck, object: ack)
            }

        case MPCEventType.questionsStateSync:
            if let data = event.payload,
               let roundState = try? decoder.decode(QuestionsRoundState.self, from: data) {
                viewModel.applyRoundStateSync(roundState)
            }

        case MPCEventType.questionsAnswerSubmitted:
            guard mpc.role == .host else { return }
            if let data = event.payload,
               let answer = try? decoder.decode(QuestionsAnswer.self, from: data) {
                viewModel.registerRemoteAnswer(answer)
            }

        case MPCEventType.questionsVoteCast:
            guard mpc.role == .host else { return }
            if let data = event.payload,
               let cast = try? decoder.decode(QuestionsVoteCastPayload.self, from: data) {
                viewModel.registerRemoteVote(cast)
            }

        case MPCEventType.questionsVotingStatus:
            if let data = event.payload,
               let status = try? decoder.decode(QuestionsVotingStatusPayload.self, from: data) {
                viewModel.applyVotingStatus(status)
            }

        case MPCEventType.questionsRoleAck:
            guard mpc.role == .host else { return }
            if let data = event.payload,
               let ack = try? decoder.decode(QuestionsRoleAckPayload.self, from: data) {
                viewModel.registerRoleAck(playerName: ack.playerName)
            }

        case MPCEventType.questionsVotingResult:
            if let data = event.payload,
               let evaluation = try? decoder.decode(QuestionsVoteEvaluation.self, from: data) {
                viewModel.applyVotingResult(evaluation)
            }

        case MPCEventType.questionsTimerSync:
            if let data = event.payload,
               let sync = try? decoder.decode(QuestionsTimerSyncPayload.self, from: data) {
                viewModel.applyTimerSync(sync)
            }

        case MPCEventType.questionsTimeSyncPing:
            guard mpc.role == .host else { return }
            if let data = event.payload,
               let ping = try? decoder.decode(QuestionsTimeSyncPingPayload.self, from: data) {
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
            if let data = event.payload,
               let pong = try? decoder.decode(QuestionsTimeSyncPongPayload.self, from: data) {
                viewModel.applyTimeSyncPong(pong)
            }

        case MPCEventType.questionsRejoinRequest:
            guard mpc.role == .host else { return }
            if let data = event.payload,
               let request = try? decoder.decode(QuestionsRejoinRequestPayload.self, from: data) {
                viewModel.handleRejoinRequest(request)
            }

        case MPCEventType.questionsRejoinState:
            guard mpc.role == .peer else { return }
            if let data = event.payload,
               let state = try? decoder.decode(QuestionsRejoinStatePayload.self, from: data) {
                viewModel.applyRejoinState(state)
            }

        case MPCEventType.questionsHostActivity:
            if let data = event.payload,
               let info = try? decoder.decode(QuestionsHostActivityPayload.self, from: data) {
                mpc.hostActivity = info.message
            }

        case MPCEventType.playerReadyUpdate:
            if let data = event.payload,
               let info = try? decoder.decode(ReadyStatusPayload.self, from: data) {
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
            if let data = event.payload,
               let list = try? decoder.decode([String].self, from: data) {
                mpc.readyPlayers = Set(list)
            }

        case MPCEventType.gameAbort:
            onDismiss?()

        default:
            break
        }
    }
}

private struct ReadyStatusPayload: Codable {
    let playerName: String
    let isReady: Bool
}
