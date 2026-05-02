import SwiftUI
import Combine
import MultipeerConnectivity

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

    // MARK: - Multiplayer-State

    @Published var isMultiplayer: Bool = false
    @Published var isHost: Bool = false
    @Published var hasSubmittedBluff: Bool = false
    @Published var hasVoted: Bool = false
    @Published var bluffSubmittedCount: Int = 0
    @Published var voteCount: Int = 0
    @Published var totalMultiplayerPlayers: Int = 0
    @Published var myBluffText: String = ""   // eigene Lüge merken (MP)
    @Published var isShowingRevealScores: Bool = false

    // Für Clients: Empfangene anonyme Submissions (Voting-Phase)
    @Published var mpSubmissions: [FFMPCSubmission] = []
    // Für Clients: Empfangene Auflösung (Reveal-Phase)
    @Published var mpRevealData: FFRevealPayload? = nil
    // Für Clients: Game Over Daten
    @Published var mpGameOverData: FFGameOverPayload? = nil

    // Host-interne Puffer
    private var hostCollectedBluffs: [FFBluffSubmitPayload] = []
    private var hostCollectedVotes: [FFVoteCastPayload] = []

    // Event-Handler (aktiviert während des Multiplayer-Spiels)
    private var mpHandler: FFMultiplayerHandler?

    // MARK: - Setup

    func startGame() {
        guard players.count >= 2 else { return }

        questionPool = FFQuestionDatabase.questions(for: settings.selectedPacks)
        rounds = []
        currentRoundIndex = 0

        let count = min(settings.roundCount.rawValue, questionPool.count)
        for i in 0..<count {
            let question = questionPool[i]
            rounds.append(FFRound(number: i + 1, question: question))
        }

        GlobalStatsManager.shared.markGameAsPlayed("FalscheFaehrte")
        transitionTo(.bluffing)
    }

    /// Host: Startet Multiplayer-Spiel mit vorab generierten Fragen-IDs
    func startMultiplayerGameAsHost(questionIds: [String]) {
        rounds = []
        currentRoundIndex = 0

        let orderedQuestions = questionIds.compactMap { id in
            FFQuestionDatabase.all.first { $0.id == id }
        }

        for (i, question) in orderedQuestions.enumerated() {
            rounds.append(FFRound(number: i + 1, question: question))
        }

        totalMultiplayerPlayers = players.count
        GlobalStatsManager.shared.markGameAsPlayed("FalscheFaehrte")
        activateMultiplayerHandler()
        resetMultiplayerRoundState()
        transitionTo(.bluffing)
    }

    /// Client: Startet Multiplayer-Spiel aus empfangener Konfiguration
    func startMultiplayerGameAsClient(config: FFGameConfigPayload) {
        rounds = []
        currentRoundIndex = 0

        let orderedQuestions = config.questionIds.compactMap { id in
            FFQuestionDatabase.all.first { $0.id == id }
        }

        // Spieler aus Lobby übernehmen
        players = config.playerNames.map { FFPlayer(name: $0) }
        settings.showCategoryHint = config.showCategoryHint
        settings.bluffTimer = FFBluffTimer(rawValue: config.bluffTimerSeconds) ?? .forty
        settings.roundCount = FFRoundCount(rawValue: config.roundCount) ?? .eight
        totalMultiplayerPlayers = config.playerNames.count

        for (i, question) in orderedQuestions.enumerated() {
            rounds.append(FFRound(number: i + 1, question: question))
        }

        GlobalStatsManager.shared.markGameAsPlayed("FalscheFaehrte")
        activateMultiplayerHandler()
        resetMultiplayerRoundState()
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

    // MARK: - Bluff-Phase (Single-Device)

    func submitBluff(_ text: String) {
        guard var round = currentRound,
              currentRoundIndex < rounds.count else { return }
        let idx = round.currentInputPlayerIndex
        guard idx < players.count else { return }

        let player = players[idx]
        let cleanText = text.trimmingCharacters(in: .whitespaces)
        guard !cleanText.isEmpty else { return }

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

        if round.currentInputPlayerIndex >= players.count {
            appendRealAnswer()
            transitionTo(.voting)
        }
    }

    private func appendRealAnswer() {
        guard var round = currentRound else { return }
        let realAnswer = FFSubmission(
            playerId: UUID(),
            playerName: "WAHRHEIT",
            text: round.question.localizedAnswer,
            isAnswer: true
        )
        round.submissions.append(realAnswer)
        round.shuffleDisplayOrder()
        rounds[currentRoundIndex] = round
    }

    // MARK: - Multiplayer Bluff-Phase

    /// Client oder Host reicht Lüge ein
    func submitBluffMultiplayer(_ text: String) {
        let cleanText = text.trimmingCharacters(in: .whitespaces)
        guard !cleanText.isEmpty else { return }

        let myName = MultipeerManager.shared.myPeerId.displayName
        let questionId = currentRound?.question.id ?? ""

        let payload = FFBluffSubmitPayload(
            playerName: myName,
            bluffText: cleanText,
            questionId: questionId
        )

        myBluffText = cleanText   // eigene Lüge für Voting-Phase merken
        currentBluffText = ""
        if isHost {
            hostCollectBluff(payload)
        } else {
            MultipeerManager.shared.sendToAll(event: MPCEventType.ffBluffSubmit, object: payload)
        }
        hasSubmittedBluff = true
    }

    func hostCollectBluff(_ payload: FFBluffSubmitPayload) {
        guard isHost else { return }
        // Doppelte Einreichungen verhindern
        guard !hostCollectedBluffs.contains(where: { $0.playerName == payload.playerName }) else { return }

        hostCollectedBluffs.append(payload)
        bluffSubmittedCount = hostCollectedBluffs.count

        let status = FFBluffingStatusPayload(
            submittedCount: hostCollectedBluffs.count,
            totalPlayers: players.count
        )
        MultipeerManager.shared.sendToAll(event: MPCEventType.ffBluffingStatus, object: status)

        if hostCollectedBluffs.count >= players.count {
            hostFinalizeBluffPhase()
        }
    }

    private func hostFinalizeBluffPhase() {
        guard var round = currentRound else { return }

        // Alle gesammelten Lügen der Runde hinzufügen
        for bluff in hostCollectedBluffs {
            let playerId = players.first(where: { $0.name == bluff.playerName })?.id ?? UUID()
            let submission = FFSubmission(
                playerId: playerId,
                playerName: bluff.playerName,
                text: bluff.bluffText,
                isAnswer: false
            )
            round.submissions.append(submission)
        }

        // Echte Antwort anhängen
        let realAnswer = FFSubmission(
            playerId: UUID(),
            playerName: "WAHRHEIT",
            text: round.question.localizedAnswer,
            isAnswer: true
        )
        round.submissions.append(realAnswer)
        round.shuffleDisplayOrder()
        rounds[currentRoundIndex] = round

        // Anonyme Submissions an alle senden
        let anonSubmissions = round.displayOrder.compactMap { id -> FFMPCSubmission? in
            guard let sub = round.submission(for: id) else { return nil }
            return FFMPCSubmission(id: sub.id.uuidString, text: sub.text)
        }

        let payload = FFBluffsReadyPayload(
            submissions: anonSubmissions,
            questionId: round.question.id
        )
        MultipeerManager.shared.sendToAll(event: MPCEventType.ffBluffsReady, object: payload)
        mpSubmissions = anonSubmissions   // Host braucht dieselbe Liste wie Clients

        hostCollectedBluffs = []
        resetVoteState()
        transitionTo(.voting)
    }

    func clientReceiveBluffs(_ payload: FFBluffsReadyPayload) {
        mpSubmissions = payload.submissions
        resetVoteState()
        transitionTo(.voting)
    }

    // MARK: - Multiplayer Voting-Phase

    /// Client oder Host gibt Vote ab
    func castVoteMultiplayer(submissionId: String) {
        let myName = MultipeerManager.shared.myPeerId.displayName
        let questionId = currentRound?.question.id ?? ""

        let payload = FFVoteCastPayload(
            voterName: myName,
            submissionId: submissionId,
            questionId: questionId
        )

        if isHost {
            hostCollectVote(payload)
        } else {
            MultipeerManager.shared.sendToAll(event: MPCEventType.ffVoteCast, object: payload)
        }
        hasVoted = true
    }

    func hostCollectVote(_ payload: FFVoteCastPayload) {
        guard isHost else { return }
        guard !hostCollectedVotes.contains(where: { $0.voterName == payload.voterName }) else { return }

        hostCollectedVotes.append(payload)
        voteCount = hostCollectedVotes.count

        let status = FFVotingStatusPayload(
            votedCount: hostCollectedVotes.count,
            totalPlayers: players.count
        )
        MultipeerManager.shared.sendToAll(event: MPCEventType.ffVotingStatus, object: status)

        if hostCollectedVotes.count >= players.count {
            hostFinalizeVotePhase()
        }
    }

    private func hostFinalizeVotePhase() {
        guard var round = currentRound else { return }

        // Votes in die Runde eintragen
        for vote in hostCollectedVotes {
            guard let submissionUUID = UUID(uuidString: vote.submissionId),
                  let subIdx = round.submissions.firstIndex(where: { $0.id == submissionUUID }) else { continue }

            let voterPlayerId = players.first(where: { $0.name == vote.voterName })?.id ?? UUID()
            round.votes[voterPlayerId] = submissionUUID
            if !round.submissions[subIdx].voterIds.contains(voterPlayerId) {
                round.submissions[subIdx].voterIds.append(voterPlayerId)
            }
        }
        rounds[currentRoundIndex] = round

        // Punkte vergeben
        awardPoints()

        // Reveal-Payload erstellen und senden
        let correctSub = round.submissions.first { $0.isAnswer }
        let revealSubmissions = round.displayOrder.compactMap { id -> FFRevealSubmission? in
            guard let sub = round.submission(for: id) else { return nil }
            let voterNames = sub.voterIds.compactMap { vid in
                players.first(where: { $0.id == vid })?.displayName
            }
            return FFRevealSubmission(
                id: sub.id.uuidString,
                text: sub.text,
                authorName: sub.isAnswer ? "WAHRHEIT" : sub.playerName,
                isAnswer: sub.isAnswer,
                voterNames: voterNames
            )
        }

        let scores = sortedPlayers.map { p in
            FFMPCPlayerScore(
                playerName: p.displayName,
                totalScore: p.score,
                truthsFound: p.truthScore / 2,
                bluffsSuccessful: p.bluffSuccesses
            )
        }

        let revealPayload = FFRevealPayload(
            submissions: revealSubmissions,
            scores: scores,
            correctSubmissionId: correctSub?.id.uuidString ?? "",
            roundIndex: currentRoundIndex
        )
        MultipeerManager.shared.sendToAll(event: MPCEventType.ffReveal, object: revealPayload)
        mpRevealData = revealPayload   // Host speichert eigene Kopie für die Reveal-View
        isShowingRevealScores = false

        hostCollectedVotes = []
        transitionTo(.reveal)
    }

    func clientReceiveReveal(_ payload: FFRevealPayload) {
        mpRevealData = payload
        isShowingRevealScores = false
        // Punkte aus dem Payload in lokale Spieler-Objekte übernehmen
        for score in payload.scores {
            if let idx = players.firstIndex(where: { $0.displayName == score.playerName }) {
                players[idx].score = score.totalScore
                players[idx].truthScore = score.truthsFound * 2
                players[idx].bluffSuccesses = score.bluffsSuccessful
            }
        }
        transitionTo(.reveal)
    }

    func showRevealScores() {
        if isMultiplayer {
            guard isHost else { return }
            let payload = FFRevealScoresPayload(roundIndex: currentRoundIndex)
            MultipeerManager.shared.sendToAll(event: MPCEventType.ffRevealScores, object: payload)
        }
        isShowingRevealScores = true
    }

    func clientShowRevealScores(_ payload: FFRevealScoresPayload) {
        guard payload.roundIndex == currentRoundIndex else { return }
        isShowingRevealScores = true
    }

    // MARK: - Voting-Phase (Single-Device)

    func castVote(voterId: UUID, forSubmissionId: UUID) {
        guard var round = currentRound,
              currentRoundIndex < rounds.count else { return }

        round.votes[voterId] = forSubmissionId

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
                players[voterIdx].awardTruth()
            }
        }

        for submission in round.submissions where !submission.isAnswer {
            let bluffCount = submission.bluffSuccessCount
            if bluffCount > 0,
               let blufferIdx = players.firstIndex(where: { $0.id == submission.playerId }) {
                players[blufferIdx].awardBluff(count: bluffCount)
            }
        }

        for i in players.indices {
            players[i].incrementRound()
        }
    }

    // MARK: - Navigation

    func nextRound() {
        if isMultiplayer && isHost {
            hostNextRound()
        } else if !isMultiplayer {
            if isLastRound {
                transitionTo(.gameOver)
            } else {
                currentRoundIndex += 1
                transitionTo(.bluffing)
            }
        }
        // Client: wartet auf FF_NEXT_ROUND vom Host
    }

    private func hostNextRound() {
        if isLastRound {
            let payload = buildGameOverPayload()
            MultipeerManager.shared.sendToAll(event: MPCEventType.ffGameOver, object: payload)
            mpGameOverData = payload
            transitionTo(.gameOver)
        } else {
            currentRoundIndex += 1
            let nextRoundPayload = FFNextRoundPayload(roundIndex: currentRoundIndex)
            MultipeerManager.shared.sendToAll(event: MPCEventType.ffNextRound, object: nextRoundPayload)
            resetMultiplayerRoundState()
            transitionTo(.bluffing)
        }
    }

    func clientHandleNextRound(_ payload: FFNextRoundPayload) {
        currentRoundIndex = payload.roundIndex
        resetMultiplayerRoundState()
        transitionTo(.bluffing)
    }

    func clientReceiveGameOver(_ payload: FFGameOverPayload) {
        mpGameOverData = payload
        // Endstand aus Payload übernehmen
        for score in payload.finalScores {
            if let idx = players.firstIndex(where: { $0.displayName == score.playerName }) {
                players[idx].score = score.totalScore
            }
        }
        transitionTo(.gameOver)
    }

    private func buildGameOverPayload() -> FFGameOverPayload {
        let scores = sortedPlayers.map { p in
            FFMPCPlayerScore(
                playerName: p.displayName,
                totalScore: p.score,
                truthsFound: p.truthScore / 2,
                bluffsSuccessful: p.bluffSuccesses
            )
        }
        let bestBluffer = players.max(by: { $0.bluffSuccesses < $1.bluffSuccesses })
        let bestDetective = players.max(by: { $0.truthScore < $1.truthScore })

        return FFGameOverPayload(
            finalScores: scores,
            mvpBluffer: (bestBluffer?.bluffSuccesses ?? 0) > 0 ? bestBluffer?.displayName : nil,
            mvpDetective: (bestDetective?.truthScore ?? 0) > 0 ? bestDetective?.displayName : nil
        )
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
        if isMultiplayer {
            // Multiplayer-Neustart: einfach zurück zum Setup
            stopMultiplayer()
            transitionTo(.setup)
        } else {
            startGame()
        }
    }

    func returnToSetup() {
        timerTask?.cancel()
        timerTask = nil
        rounds = []
        currentRoundIndex = 0
        currentBluffText = ""
        players = []

        if isMultiplayer {
            MultipeerManager.shared.sendToAll(event: MPCEventType.gameAbort, object: nil as String?)
            stopMultiplayer()
        }

        transitionTo(.setup)
    }

    // MARK: - Timer

    func startTimer(seconds: Int) {
        timerTask?.cancel()
        timeRemaining = seconds
        timerTask = Task {
            while timeRemaining > 0 && !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
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

    // MARK: - Multiplayer Hilfsemthoden

    private func activateMultiplayerHandler() {
        let handler = FFMultiplayerHandler()
        handler.activate(for: self)
        self.mpHandler = handler
    }

    private func stopMultiplayer() {
        mpHandler?.deactivate()
        mpHandler = nil
        isMultiplayer = false
        isHost = false
        MultipeerManager.shared.stop()
        resetMultiplayerRoundState()
    }

    private func resetMultiplayerRoundState() {
        hasSubmittedBluff = false
        hasVoted = false
        bluffSubmittedCount = 0
        voteCount = 0
        mpSubmissions = []
        mpRevealData = nil
        myBluffText = ""
        isShowingRevealScores = false
        currentBluffText = ""   // verhindert vorausgefüllten Text in Runde 2+
        hostCollectedBluffs = []
        hostCollectedVotes = []
    }

    private func resetVoteState() {
        hasVoted = false
        voteCount = 0
    }
}
