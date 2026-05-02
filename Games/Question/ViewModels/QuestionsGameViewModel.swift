import SwiftUI
import Combine
import MultipeerConnectivity

/// Adapter view model for the Questions engine + app model.
@MainActor
final class QuestionsGameViewModel: ObservableObject {
    let appModel: AppModel
    let engine: QuestionsEngine

    // Setup / Config
    @Published var selectedCategory: QuestionsCategory? = nil
    @Published var numberOfLiars: Int = 1
    @Published var discussionTime: TimeInterval = 180

    // Timer
    @Published var timeRemaining: TimeInterval = 0
    @Published var timerActive: Bool = false

    // Collecting phase
    @Published var showQuestionToCurrentPlayer: Bool = false
    @Published var answerText: String = ""
    @Published var currentInputDuration: TimeInterval = 0

    // Multiplayer role data
    @Published var myRole: QuestionsRole? = nil
    @Published var myPrompt: String? = nil

    // Voting / Reveal
    @Published var isRevealVoteActive = false
    @Published var voteCounts: [UUID: Int] = [:]
    @Published var revealEvaluation: QuestionsVoteEvaluation? = nil
    @Published var lastRevealEvaluation: QuestionsVoteEvaluation? = nil
    @Published var foundRevealLiars: Set<UUID> = []
    @Published var revealShakeTrigger: CGFloat = 0
    @Published var showLiarDetailsList = false
    @Published var liarScrollTarget: UUID? = nil

    // Multiplayer helper state
    @Published var roleAcks: Set<String> = []

    // Peer state override (for MPC sync)
    @Published private var syncedRound: QuestionsRoundState? = nil
    @Published private var syncedPhaseOverride: QuestionsPhase? = nil

    private var inputStartTime: Date? = nil
    private var cancellables = Set<AnyCancellable>()
    private var timerCancellable: AnyCancellable?
    private var mpcHandler: QuestionsMultiplayerHandler?

    init(appModel: AppModel, engine: QuestionsEngine) {
        self.appModel = appModel
        self.engine = engine

        // Forward changes so the UI redraws on engine/app updates.
        engine.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)

        appModel.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)

        selectedCategory = appModel.selectedQuestionsCategory ?? QuestionsDefaults.all.first
        numberOfLiars = max(1, appModel.numberOfLiars)
        timeRemaining = discussionTime

        setupTimers()
    }

    // MARK: - Derived State

    var currentPhase: QuestionsPhase { syncedPhaseOverride ?? engine.phase }
    var currentRound: QuestionsRoundState? { syncedRound ?? engine.round }
    var playerCount: Int { appModel.players.count }
    var currentLiarIDs: Set<UUID> { engine.currentLiarIDs }

    // Keep legacy naming used by TV board (spies -> liars).
    var currentSpyIDs: Set<UUID> { engine.currentLiarIDs }

    var answersInOrder: [QuestionsAnswer] {
        guard let answersDict = currentRound?.answers else { return [] }
        return appModel.players.compactMap { answersDict[$0.id] }
    }

    var maxVotes: Int {
        let liars = engine.config.numberOfLiars > 0 ? engine.config.numberOfLiars : numberOfLiars
        return playerCount * max(0, liars)
    }

    var currentTotalVotes: Int {
        voteCounts.values.reduce(0, +)
    }

    var currentLeaders: Set<UUID> {
        guard !voteCounts.isEmpty else { return [] }
        let maxVotes = voteCounts.values.max() ?? 0
        guard maxVotes > 0 else { return [] }
        return Set(voteCounts.filter { $0.value == maxVotes }.map { $0.key })
    }

    var canRevealNow: Bool {
        if !isRevealVoteActive { return !answersInOrder.isEmpty }
        if revealEvaluation == nil {
            return !voteCounts.isEmpty && currentTotalVotes > 0
        }
        return true
    }

    var slowestTime: TimeInterval {
        answersInOrder.map { $0.timeTaken }.max() ?? 0
    }

    var isAnswerValid: Bool {
        !answerText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func currentPlayer() -> QuestionPlayer? {
        engine.currentPlayer()
    }

    func role(for playerID: UUID) -> QuestionsRole {
        engine.role(for: playerID)
    }

    func playerName(for id: UUID) -> String {
        appModel.players.first(where: { $0.id == id })?.name ?? "Unbekannt"
    }

    func timeString(from time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    func voteCountForDisplay(playerID: UUID) -> Int {
        voteCounts[playerID] ?? 0
    }

    func canIncrementVote() -> Bool {
        currentTotalVotes < maxVotes
    }

    // MARK: - Timer

    private func setupTimers() {
        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                if self.timerActive && self.timeRemaining > 0 {
                    self.timeRemaining -= 1
                }
                if let start = self.inputStartTime {
                    self.currentInputDuration = Date().timeIntervalSince(start)
                } else if self.currentInputDuration != 0 {
                    self.currentInputDuration = 0
                }
            }
    }

    // MARK: - Round Control

    func startRound() {
        resetRevealState(clearLast: true)
        let category = selectedCategory ?? appModel.selectedQuestionsCategory ?? QuestionsDefaults.all.first
        guard let category else { return }
        guard !category.promptPairs.isEmpty else { return }

        appModel.selectedQuestionsCategory = category
        appModel.numberOfLiars = numberOfLiars

        engine.configure(
            players: appModel.players,
            numberOfLiars: numberOfLiars,
            category: category,
            fairnessPolicy: appModel.fairnessPolicy,
            fairnessState: appModel.fairnessState
        )
        engine.startNewRound(roundIndex: 0)

        showQuestionToCurrentPlayer = false
        answerText = ""
        inputStartTime = nil
        currentInputDuration = 0

        timeRemaining = discussionTime
        timerActive = false

        syncedRound = nil
        syncedPhaseOverride = nil
    }

    func revealQuestionForCurrentPlayer() {
        showQuestionToCurrentPlayer = true
        answerText = ""
        inputStartTime = Date()
    }

    func submitCurrentAnswer() {
        guard isAnswerValid else { return }

        let timeTaken = inputStartTime.map { Date().timeIntervalSince($0) } ?? 0
        let mpc = MultipeerManager.shared

        if mpc.role == .peer {
            if let playerID = appModel.players.first(where: { $0.name == mpc.myPeerId.displayName })?.id {
                let role = myRole ?? .citizen
                let answer = QuestionsAnswer(playerID: playerID, role: role, text: answerText, timeTaken: timeTaken)
                mpc.sendToHost(event: MPCEventType.questionsAnswerSubmitted, object: answer)
            }
            showQuestionToCurrentPlayer = false
            answerText = ""
            inputStartTime = nil
            return
        }

        let accepted = engine.submitAnswer(text: answerText, timeTaken: timeTaken)
        if accepted {
            showQuestionToCurrentPlayer = false
            answerText = ""
            inputStartTime = nil
        }
    }

    func startDiscussion() {
        engine.showOverview()
        timerActive = discussionTime > 0
    }

    // MARK: - Voting

    func incrementVote(for playerID: UUID) {
        if currentTotalVotes < maxVotes {
            let current = voteCounts[playerID] ?? 0
            voteCounts[playerID] = current + 1
        }
    }

    func decrementVote(for playerID: UUID) {
        let current = voteCounts[playerID] ?? 0
        if current > 0 {
            voteCounts[playerID] = current - 1
        }
    }

    func handleRevealCardTap(playerID: UUID) {
        if showLiarDetailsList {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) { showLiarDetailsList = false }
            liarScrollTarget = nil
        } else {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.85)) { showLiarDetailsList = true }
            liarScrollTarget = playerID
        }
    }

    func handleRevealAction() {
        if !isRevealVoteActive {
            guard !answersInOrder.isEmpty else { return }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                isRevealVoteActive = true
                voteCounts.removeAll()
                revealEvaluation = nil
                revealShakeTrigger = 0
            }
            if engine.currentLiarIDs.isEmpty {
                let evaluation = QuestionsVoteEvaluation(selected: [], liars: engine.currentLiarIDs)
                revealEvaluation = evaluation
                lastRevealEvaluation = evaluation
                engine.finishRound()
                appModel.fairnessState.advanceRound()
            }
        } else if revealEvaluation == nil {
            let suspects = currentLeaders
            guard !suspects.isEmpty else { return }

            if suspects.count > 1 {
                startSuddenDeathAnimation(candidates: Array(suspects))
                return
            }

            let evaluation = QuestionsVoteEvaluation(selected: suspects, liars: engine.currentLiarIDs)
            revealEvaluation = evaluation
            lastRevealEvaluation = evaluation

            if !evaluation.incorrect.isEmpty {
                if !engine.currentLiarIDs.isEmpty {
                    appModel.addPoints(to: engine.currentLiarIDs, amount: 3)
                }
                withAnimation(.easeInOut(duration: 0.5)) { revealShakeTrigger += 1 }
                engine.finishRound()
                appModel.fairnessState.advanceRound()
                return
            }

            foundRevealLiars.formUnion(evaluation.correct)
            if foundRevealLiars.count == engine.currentLiarIDs.count {
                if !engine.currentLiarIDs.isEmpty {
                    let allIDs = Set(appModel.players.map { $0.id })
                    let citizenIDs = allIDs.subtracting(engine.currentLiarIDs)
                    appModel.addPoints(to: citizenIDs, amount: 1)
                }

                let finalEval = QuestionsVoteEvaluation(selected: foundRevealLiars, liars: engine.currentLiarIDs)
                revealEvaluation = finalEval
                lastRevealEvaluation = finalEval
                engine.finishRound()
                appModel.fairnessState.advanceRound()
                return
            }

            if !engine.currentLiarIDs.isEmpty {
                appModel.addPoints(to: engine.currentLiarIDs, amount: 3)
            }
            engine.finishRound()
            appModel.fairnessState.advanceRound()
        } else {
            if lastRevealEvaluation == nil { lastRevealEvaluation = revealEvaluation }
            engine.finishRound()
            appModel.fairnessState.advanceRound()
            resetRevealState()
        }
    }

    private func startSuddenDeathAnimation(candidates: [UUID]) {
        let suddenDeathCandidates = candidates.shuffled()
        guard suddenDeathCandidates.count >= 2 else { return }

        if suddenDeathCandidates.count == 2 {
            let winnerID = suddenDeathCandidates[Int.random(in: 0...1)]
            Task { @MainActor [weak self] in
                try? await Task.sleep(for: .seconds(1.5))
                self?.resolveSuddenDeath(winnerID: winnerID)
            }
            return
        }

        Task { @MainActor [weak self] in
            var iteration = 0
            let totalIterations = 20
            var interval: TimeInterval = 0.1
            var highlightIndex = 0

            while true {
                guard iteration < totalIterations else {
                    let winnerID = suddenDeathCandidates[highlightIndex]
                    try? await Task.sleep(for: .seconds(0.6))
                    self?.resolveSuddenDeath(winnerID: winnerID)
                    break
                }
                highlightIndex = (highlightIndex + 1) % suddenDeathCandidates.count
                iteration += 1
                if iteration > 10 { interval *= 1.15 }
                try? await Task.sleep(for: .seconds(interval))
            }
        }
    }

    private func resolveSuddenDeath(winnerID: UUID) {
        withAnimation {
            voteCounts = [winnerID: 999]
        }
        handleRevealAction()
    }

    private func resetRevealState(clearLast: Bool = false) {
        isRevealVoteActive = false
        voteCounts.removeAll()
        revealEvaluation = nil
        revealShakeTrigger = 0
        showLiarDetailsList = false
        liarScrollTarget = nil
        foundRevealLiars.removeAll()
        if clearLast { lastRevealEvaluation = nil }
    }

    // MARK: - MPC Handler Lifecycle

    func activateMPCHandler(onDismiss: @escaping () -> Void) {
        let handler = QuestionsMultiplayerHandler()
        handler.activate(viewModel: self, onDismiss: onDismiss)
        mpcHandler = handler
    }

    func deactivateMPCHandler() {
        mpcHandler?.deactivate()
        mpcHandler = nil
    }

    // MARK: - Multiplayer Sync Helpers

    func syncStateToAll() {
        let mpc = MultipeerManager.shared
        guard mpc.role == .host else { return }
        if let round = engine.round {
            mpc.sendToAll(event: MPCEventType.questionsStateSync, object: round)
        }
        let timerSync = QuestionsTimerSyncPayload(
            timeRemaining: timeRemaining,
            isActive: timerActive,
            hostUptime: ProcessInfo.processInfo.systemUptime
        )
        mpc.sendToAll(event: MPCEventType.questionsTimerSync, object: timerSync)

        if let evaluation = revealEvaluation {
            mpc.sendToAll(event: MPCEventType.questionsVotingResult, object: evaluation)
        }

        let status = QuestionsVotingStatusPayload(
            votesReceived: currentTotalVotes,
            totalVotes: maxVotes,
            tally: voteCounts.reduce(into: [String: Int]()) { result, entry in
                result[entry.key.uuidString] = entry.value
            }
        )
        mpc.sendToAll(event: MPCEventType.questionsVotingStatus, object: status)
    }

    func applyRoundStateSync(_ roundState: QuestionsRoundState) {
        syncedRound = roundState
        syncedPhaseOverride = roundState.phase
    }

    func registerRemoteAnswer(_ answer: QuestionsAnswer) {
        guard var round = engine.round else { return }
        round.answers[answer.playerID] = answer
        round.currentPlayerIndex = max(round.currentPlayerIndex, round.answers.count)
        engine.applyRoundState(round)
        if round.answers.count >= appModel.players.count {
            engine.revealCitizenQuestion()
        }
    }

    func registerRemoteVote(_ cast: QuestionsVoteCastPayload) {
        let current = voteCounts[cast.targetId] ?? 0
        let next = max(0, current + cast.delta)
        voteCounts[cast.targetId] = next
    }

    func applyVotingStatus(_ status: QuestionsVotingStatusPayload) {
        if let tally = status.tally {
            var mapped: [UUID: Int] = [:]
            for (key, value) in tally {
                if let id = UUID(uuidString: key) {
                    mapped[id] = value
                }
            }
            voteCounts = mapped
        }
    }

    func registerRoleAck(playerName: String) {
        roleAcks.insert(playerName)
    }

    func applyVotingResult(_ evaluation: QuestionsVoteEvaluation) {
        revealEvaluation = evaluation
        lastRevealEvaluation = evaluation
    }

    func applyTimerSync(_ sync: QuestionsTimerSyncPayload) {
        timeRemaining = sync.timeRemaining
        timerActive = sync.isActive
    }

    func applyTimeSyncPong(_ pong: QuestionsTimeSyncPongPayload) {
        _ = pong
    }

    func handleRejoinRequest(_ request: QuestionsRejoinRequestPayload) {
        let mpc = MultipeerManager.shared
        guard mpc.role == .host else { return }

        let config = QuestionsConfig(
            numberOfLiars: numberOfLiars,
            selectedCategory: selectedCategory,
            discussionTime: discussionTime,
            players: appModel.players
        )
        let payload = QuestionsRejoinStatePayload(
            playerName: request.playerName,
            roundState: engine.round,
            votingEvaluation: revealEvaluation,
            timeRemaining: timeRemaining,
            isTimerActive: timerActive,
            config: config
        )
        if let peer = mpc.getPeer(byName: request.playerName) {
            mpc.sendToPeer(event: MPCEventType.questionsRejoinState, object: payload, to: peer)
        }
    }

    func applyRejoinState(_ state: QuestionsRejoinStatePayload) {
        selectedCategory = state.config.selectedCategory
        numberOfLiars = state.config.numberOfLiars
        discussionTime = state.config.discussionTime
        if !state.config.players.isEmpty {
            appModel.players = state.config.players
        }
        timeRemaining = state.timeRemaining
        timerActive = state.isTimerActive
        if let roundState = state.roundState {
            applyRoundStateSync(roundState)
        }
        if let evaluation = state.votingEvaluation {
            applyVotingResult(evaluation)
        }
    }
}
