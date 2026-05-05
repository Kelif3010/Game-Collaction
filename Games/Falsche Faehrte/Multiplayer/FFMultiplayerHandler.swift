import Foundation

// MARK: - FF Multiplayer Event-Handler
// Routet eingehende MPC-Events an das FFViewModel
// Wird aktiviert wenn das Spiel startet (nach dem Lobby-Sheet)

@MainActor
final class FFMultiplayerHandler {
    weak var viewModel: FFViewModel?
    private var listenerTask: Task<Void, Never>?
    private let decoder = JSONDecoder()

    func activate(for viewModel: FFViewModel) {
        self.viewModel = viewModel
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
    }

    private func handle(_ event: MPCEvent) {
        guard let vm = viewModel else { return }

        switch event.type {

        case MPCEventType.ffBluffSubmit:
            guard vm.isHost, let d = event.payload else { return }
            decode(FFBluffSubmitPayload.self, from: d, event: event.type) { vm.hostCollectBluff($0) }

        case MPCEventType.ffVoteCast:
            guard vm.isHost, let d = event.payload else { return }
            decode(FFVoteCastPayload.self, from: d, event: event.type) { vm.hostCollectVote($0) }

        case MPCEventType.ffBluffsReady:
            guard !vm.isHost, let d = event.payload else { return }
            decode(FFBluffsReadyPayload.self, from: d, event: event.type) { vm.clientReceiveBluffs($0) }

        case MPCEventType.ffBluffingStatus:
            guard let d = event.payload else { return }
            decode(FFBluffingStatusPayload.self, from: d, event: event.type) {
                vm.bluffSubmittedCount = $0.submittedCount
                vm.totalMultiplayerPlayers = $0.totalPlayers
            }

        case MPCEventType.ffVotingStatus:
            guard let d = event.payload else { return }
            decode(FFVotingStatusPayload.self, from: d, event: event.type) {
                vm.voteCount = $0.votedCount
                vm.totalMultiplayerPlayers = $0.totalPlayers
            }

        case MPCEventType.ffReveal:
            guard !vm.isHost, let d = event.payload else { return }
            decode(FFRevealPayload.self, from: d, event: event.type) { vm.clientReceiveReveal($0) }

        case MPCEventType.ffRevealScores:
            guard !vm.isHost, let d = event.payload else { return }
            decode(FFRevealScoresPayload.self, from: d, event: event.type) { vm.clientShowRevealScores($0) }

        case MPCEventType.ffNextRound:
            guard !vm.isHost, let d = event.payload else { return }
            decode(FFNextRoundPayload.self, from: d, event: event.type) { vm.clientHandleNextRound($0) }

        case MPCEventType.ffGameOver:
            guard !vm.isHost, let d = event.payload else { return }
            decode(FFGameOverPayload.self, from: d, event: event.type) { vm.clientReceiveGameOver($0) }

        case MPCEventType.gameAbort:
            vm.returnToSetup()

        default:
            break
        }
    }

    private func decode<T: Decodable>(
        _ type: T.Type,
        from data: Data,
        event: String,
        handler: (T) -> Void
    ) {
        do {
            handler(try decoder.decode(type, from: data))
        } catch {
            assertionFailure("FF[\(event)] Decode-Fehler: \(error)")
        }
    }
}
