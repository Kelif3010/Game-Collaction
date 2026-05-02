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

        // MARK: Host empfängt Lüge eines Clients
        case MPCEventType.ffBluffSubmit:
            guard vm.isHost, let d = event.payload,
                  let payload = try? decoder.decode(FFBluffSubmitPayload.self, from: d) else { return }
            vm.hostCollectBluff(payload)

        // MARK: Host empfängt Vote eines Clients
        case MPCEventType.ffVoteCast:
            guard vm.isHost, let d = event.payload,
                  let payload = try? decoder.decode(FFVoteCastPayload.self, from: d) else { return }
            vm.hostCollectVote(payload)

        // MARK: Client empfängt anonyme Lügen-Liste (Voting beginnt)
        case MPCEventType.ffBluffsReady:
            guard !vm.isHost, let d = event.payload,
                  let payload = try? decoder.decode(FFBluffsReadyPayload.self, from: d) else { return }
            vm.clientReceiveBluffs(payload)

        // MARK: Client empfängt Lügen-Fortschritt
        case MPCEventType.ffBluffingStatus:
            guard let d = event.payload,
                  let payload = try? decoder.decode(FFBluffingStatusPayload.self, from: d) else { return }
            vm.bluffSubmittedCount = payload.submittedCount
            vm.totalMultiplayerPlayers = payload.totalPlayers

        // MARK: Client empfängt Voting-Fortschritt
        case MPCEventType.ffVotingStatus:
            guard let d = event.payload,
                  let payload = try? decoder.decode(FFVotingStatusPayload.self, from: d) else { return }
            vm.voteCount = payload.votedCount
            vm.totalMultiplayerPlayers = payload.totalPlayers

        // MARK: Client empfängt Auflösung
        case MPCEventType.ffReveal:
            guard !vm.isHost, let d = event.payload,
                  let payload = try? decoder.decode(FFRevealPayload.self, from: d) else { return }
            vm.clientReceiveReveal(payload)

        // MARK: Client empfängt synchronen Wechsel zum Punktestand
        case MPCEventType.ffRevealScores:
            guard !vm.isHost, let d = event.payload,
                  let payload = try? decoder.decode(FFRevealScoresPayload.self, from: d) else { return }
            vm.clientShowRevealScores(payload)

        // MARK: Client empfängt nächste Runde
        case MPCEventType.ffNextRound:
            guard !vm.isHost, let d = event.payload,
                  let payload = try? decoder.decode(FFNextRoundPayload.self, from: d) else { return }
            vm.clientHandleNextRound(payload)

        // MARK: Client empfängt Spielende
        case MPCEventType.ffGameOver:
            guard !vm.isHost, let d = event.payload,
                  let payload = try? decoder.decode(FFGameOverPayload.self, from: d) else { return }
            vm.clientReceiveGameOver(payload)

        // MARK: Spiel abgebrochen (Host hat verlassen)
        case MPCEventType.gameAbort:
            vm.returnToSetup()

        default:
            break
        }
    }
}
