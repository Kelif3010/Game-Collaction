import SwiftUI
import Combine

// MARK: - Haupt-ViewModel für Falsche Fährte
@MainActor
final class FFViewModel: ObservableObject {

    // MARK: Spielzustand
    @Published var gamePhase: FFGamePhase = .setup
    @Published var players: [FFPlayer] = []
    @Published var settings: FFSettings = FFSettings()
    @Published var rounds: [FFRound] = []
    @Published var currentRoundIndex: Int = 0

    // MARK: Aktuelle Runde (Convenience)
    var currentRound: FFRound? {
        guard currentRoundIndex < rounds.count else { return nil }
        return rounds[currentRoundIndex]
    }

    var currentRoundNumber: Int { currentRoundIndex + 1 }
    var totalRounds: Int { settings.roundCount.rawValue }
    var isLastRound: Bool { currentRoundIndex >= totalRounds - 1 }

    // MARK: Bluff-Eingabe-Tracking (Single-Device)
    @Published var currentBluffText: String = ""
    @Published var currentInputPlayerIndex: Int = 0

    var currentInputPlayer: FFPlayer? {
        guard let round = currentRound,
              round.currentInputPlayerIndex < players.count else { return nil }
        return players[round.currentInputPlayerIndex]
    }

    var allBluffsSubmitted: Bool {
        guard let round = currentRound else { return false }
        let playerSubmissions = round.submissions.filter { !$0.isAnswer }
        return playerSubmissions.count >= players.count
    }

    // MARK: Timer
    @Published var timeRemaining: Int = 0
    private var timerTask: Task<Void, Never>?

    // MARK: Fragen-Pool
    private var questionPool: [FFQuestion] = []

    // MARK: - Setup

    func startGame() {
        guard players.count >= 2 else { return }

        questionPool = FFQuestionDatabase.questions(for: settings.selectedPacks)
        rounds = []
        currentRoundIndex = 0

        // Runden vorbereiten
        let count = min(settings.roundCount.rawValue, questionPool.count)
        for i in 0..<count {
            let question = questionPool[i]
            rounds.append(FFRound(number: i + 1, question: question))
        }

        GlobalStatsManager.shared.markGameAsPlayed("FalscheFaehrte")
        transitionTo(.bluffing)
    }

    func addPlayer(_ name: String) {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty,
              !players.contains(where: { $0.name.lowercased() == name.lowercased() }),
              players.count < 8 else { return }
        players.append(FFPlayer(name: name.trimmingCharacters(in: .whitespaces)))
    }

    func removePlayer(at offsets: IndexSet) {
        players.remove(atOffsets: offsets)
    }

    func removePlayer(id: UUID) {
        players.removeAll { $0.id == id }
    }

    // MARK: - Bluff-Phase

    func submitBluff(_ text: String) {
        guard var round = currentRound,
              currentRoundIndex < rounds.count else { return }
        let idx = round.currentInputPlayerIndex
        guard idx < players.count else { return }

        let player = players[idx]
        let cleanText = text.trimmingCharacters(in: .whitespaces)
        guard !cleanText.isEmpty else { return }

        // Duplizier-Schutz: Wenn Spieler exakt die echte Antwort eingibt,
        // soll das nicht angezeigt werden (echter Antworttext ist bekannt)
        let submission = FFSubmission(
            playerId: player.id,
            playerName: player.name,
            text: cleanText,
            isAnswer: false
        )
        round.submissions.append(submission)
        round.currentInputPlayerIndex += 1
        rounds[currentRoundIndex] = round
        currentBluffText = ""

        // Alle Spieler haben eingegeben → echte Antwort anhängen + Voting starten
        if round.currentInputPlayerIndex >= players.count {
            appendRealAnswer()
            transitionTo(.voting)
        }
    }

    private func appendRealAnswer() {
        guard var round = currentRound else { return }
        let realAnswer = FFSubmission(
            playerId: UUID(),  // Keine echte Spieler-ID
            playerName: "WAHRHEIT",
            text: round.question.localizedAnswer,
            isAnswer: true
        )
        round.submissions.append(realAnswer)
        round.shuffleDisplayOrder()
        rounds[currentRoundIndex] = round
    }

    // MARK: - Voting-Phase

    func castVote(voterId: UUID, forSubmissionId: UUID) {
        guard var round = currentRound,
              currentRoundIndex < rounds.count else { return }

        // Verhindert Doppelstimmen
        round.votes[voterId] = forSubmissionId

        // Stimme in Submission speichern
        if let subIdx = round.submissions.firstIndex(where: { $0.id == forSubmissionId }) {
            if !round.submissions[subIdx].voterIds.contains(voterId) {
                round.submissions[subIdx].voterIds.append(voterId)
            }
        }
        rounds[currentRoundIndex] = round
    }

    var allVotesCast: Bool {
        guard let round = currentRound else { return false }
        return round.votes.count >= players.count
    }

    func proceedToReveal() {
        awardPoints()
        transitionTo(.reveal)
    }

    // MARK: - Punkte-Vergabe

    private func awardPoints() {
        guard let round = currentRound else { return }

        for (voterId, submissionId) in round.votes {
            guard let voterIdx = players.firstIndex(where: { $0.id == voterId }),
                  let submission = round.submission(for: submissionId) else { continue }

            if submission.isAnswer {
                // Wahrheit erkannt → 2 Punkte
                players[voterIdx].awardTruth()
            }
        }

        // Bluff-Punkte: 1 pro getäuschtem Spieler
        for submission in round.submissions where !submission.isAnswer {
            let bluffCount = submission.bluffSuccessCount
            if bluffCount > 0,
               let blufferIdx = players.firstIndex(where: { $0.id == submission.playerId }) {
                players[blufferIdx].awardBluff(count: bluffCount)
            }
        }

        // Rundenanzahl für alle erhöhen
        for i in players.indices {
            players[i].incrementRound()
        }
    }

    // MARK: - Navigation

    func nextRound() {
        if isLastRound {
            transitionTo(.gameOver)
        } else {
            currentRoundIndex += 1
            transitionTo(.bluffing)
        }
    }

    func restartGame() {
        rounds = []
        currentRoundIndex = 0
        for i in players.indices {
            players[i].score = 0
            players[i].bluffScore = 0
            players[i].truthScore = 0
            players[i].bluffSuccesses = 0
            players[i].roundsPlayed = 0
        }
        startGame()
    }

    func returnToSetup() {
        timerTask?.cancel()
        timerTask = nil
        rounds = []
        currentRoundIndex = 0
        currentBluffText = ""
        transitionTo(.setup)
    }

    // MARK: - Timer

    func startTimer(seconds: Int) {
        timerTask?.cancel()
        timeRemaining = seconds
        timerTask = Task {
            while timeRemaining > 0 && !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if !Task.isCancelled {
                    timeRemaining -= 1
                }
            }
        }
    }

    func stopTimer() {
        timerTask?.cancel()
        timerTask = nil
    }

    // MARK: - Hilfsmethoden

    var sortedPlayers: [FFPlayer] {
        players.sorted { $0.score > $1.score }
    }

    var winner: FFPlayer? { sortedPlayers.first }

    private func transitionTo(_ phase: FFGamePhase) {
        withAnimation(.easeInOut(duration: 0.35)) {
            gamePhase = phase
        }
    }
}
