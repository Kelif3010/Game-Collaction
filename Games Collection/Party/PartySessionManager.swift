import SwiftUI
import Observation

@Observable
final class PartySessionManager {

    var session: PartySession?
    var showBridge = false

    private let sessionKey = "PartySession_Active_V1"

    // MARK: - Init & Persistenz

    init() {
        loadPersistedSession()
    }

    private func persistSession() {
        guard let session else {
            UserDefaults.standard.removeObject(forKey: sessionKey)
            return
        }
        if let data = try? JSONEncoder().encode(session) {
            UserDefaults.standard.set(data, forKey: sessionKey)
        }
    }

    private func loadPersistedSession() {
        guard
            let data    = UserDefaults.standard.data(forKey: sessionKey),
            let saved   = try? JSONDecoder().decode(PartySession.self, from: data),
            saved.state != .complete
        else {
            UserDefaults.standard.removeObject(forKey: sessionKey)
            return
        }
        session    = saved
        showBridge = saved.state == .enteringResults
    }

    // MARK: - Session starten

    func startSession(players: [PartyPlayer], games: [PartyGame]) {
        session    = PartySession(players: players, games: games)
        showBridge = false
        persistSession()
    }

    // MARK: - Nach Game-Dismiss

    func gameDismissed() {
        guard session != nil else { return }
        session?.state = .enteringResults
        showBridge = true
        persistSession()
    }

    // MARK: - Ergebnis eintragen

    func recordResult(winnerIDs: [UUID]) {
        guard var s = session, let current = s.currentGame else { return }

        let result = PartyGameResult(
            game: current,
            winnerIDs: winnerIDs,
            allPlayerIDs: s.players.map { $0.id }
        )
        s.results.append(result)

        // Punkte auf die Spieler anwenden
        for idx in s.players.indices {
            let pid = s.players[idx].id
            s.players[idx].totalScore += result.pointsEarned[pid] ?? 1
        }

        if s.isLastGame {
            s.state = .complete
        } else {
            s.currentGameIndex += 1
            s.state = .playing
        }

        session    = s
        showBridge = false
        persistSession()
    }

    // MARK: - Session beenden

    func endSession() {
        session    = nil
        showBridge = false
        persistSession()
    }

    // MARK: - Computed Helpers

    var currentGame: PartyGame? { session?.currentGame }

    var leaderboard: [PartyPlayer] { session?.sortedPlayers ?? [] }

    var progressText: String {
        guard let s = session else { return "" }
        return "Spiel \(s.gamesPlayed + 1) von \(s.gamesTotal)"
    }
}
