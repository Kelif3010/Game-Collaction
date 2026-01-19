import SwiftUI
import Combine
import MultipeerConnectivity
import Foundation

class QuestionsGameViewModel: ObservableObject {
    // MARK: - Dependencies
    let appModel: AppModel
    @Published var engine = QuestionsEngine()
    
    // MARK: - Game Settings (Setup)
    @Published var selectedCategory: QuestionsCategory? = nil
    @Published var numberOfSpies: Int = 1
    @Published var discussionTime: TimeInterval = 180
    
    // MARK: - Multiplayer Specific
    @Published var myRole: QuestionsRole? = nil
    @Published var myPrompt: String? = nil
    
    // MARK: - Phase State: Collecting
    @Published var showQuestionToCurrentPlayer: Bool = false
    @Published var answerText: String = ""
    @Published var inputStartTime: Date? = nil
    @Published var currentInputDuration: TimeInterval = 0
    
    // MARK: - Phase State: Voting & Reveal
    @Published var isRevealVoteActive = false
    @Published var myVotes: [UUID: Int] = [:]
    @Published var voteCounts: [UUID: Int] = [:]
    @Published var revealEvaluation: QuestionsVoteEvaluation? = nil
    @Published var lastRevealEvaluation: QuestionsVoteEvaluation? = nil
    @Published var foundRevealSpies: Set<UUID> = []
    @Published var revealShakeTrigger: CGFloat = 0
    @Published var showSpyDetailsList = false
    @Published var spyScrollTarget: UUID? = nil
    
    // MARK: - Phase State: Sudden Death
    @Published var isSuddenDeathActive = false
    @Published var suddenDeathCandidates: [UUID] = []
    @Published var suddenDeathHighlightIndex: Int = 0
    
    // MARK: - Timer State
    @Published var timeRemaining: TimeInterval = 0
    @Published var timerActive = false
    private var timerCancellable: AnyCancellable?
    private var engineCancellable: AnyCancellable?
    @Published var hostClockOffset: TimeInterval = 0
    var hostClockOffsetRTT: TimeInterval = .greatestFiniteMagnitude
    private var lastTimerSyncUptime: TimeInterval?
    private var didRequestTimeSync = false
    private let timerSyncInterval: TimeInterval = 2.0
    private var didSendRejoinRequest = false

    private var votesByVoter: [UUID: [UUID: Int]] = [:]
    
    // MARK: - Alerts
    @Published var showEmptyCategoryAlert = false
    
    // MARK: - Computed Properties
    var playerCount: Int { appModel.players.count }
    var maxVotes: Int { playerCount * engine.config.numberOfSpies }
    var maxVotesPerPlayer: Int { max(1, engine.config.numberOfSpies) }
    var currentTotalVotes: Int { voteCounts.values.reduce(0, +) }
    var myTotalVotes: Int { myVotes.values.reduce(0, +) }
    
    var currentRound: QuestionsRoundState? { engine.round }
    var currentPhase: QuestionsPhase { engine.phase }
    
    var answersInOrder: [QuestionsAnswer] {
        guard let answersDict = engine.round?.answers else { return [] }
        return appModel.players.compactMap { answersDict[$0.id] }
    }
    
    var isAnswerValid: Bool {
        !answerText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var canRevealNow: Bool {
        if !isRevealVoteActive { return !answersInOrder.isEmpty }
        if revealEvaluation == nil {
            return !voteCounts.isEmpty && voteCounts.values.reduce(0, +) > 0
        }
        return true
    }
    
    var slowestTime: TimeInterval {
        answersInOrder.map(\.timeTaken).max() ?? 0
    }
    
    var currentLeaders: Set<UUID> {
        guard !voteCounts.isEmpty else { return [] }
        let maxVotes = voteCounts.values.max() ?? 0
        guard maxVotes > 0 else { return [] }
        return Set(voteCounts.filter { $0.value == maxVotes }.map { $0.key })
    }
    
    var currentSpyIDs: Set<UUID> { engine.currentSpyIDs }

    private var pendingRoleAcks: Set<String> = []
    
    // MARK: - Initialization
    init(appModel: AppModel) {
        self.appModel = appModel
        engineCancellable = engine.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
        setupDefaults()
    }
    
    func setupDefaults() {
        if selectedCategory == nil {
            selectedCategory = appModel.selectedQuestionsCategory ?? QuestionsDefaults.all.first
        }
        numberOfSpies = min(max(1, appModel.numberOfImposters), max(0, playerCount > 1 ? playerCount - 1 : 0))
    }
    
    // MARK: - Game Lifecycle Logic
    
    func startRound() {
        resetRevealState(clearLast: true)
        guard let category = selectedCategory else { return }
        guard !category.promptPairs.isEmpty else {
            showEmptyCategoryAlert = true
            return
        }
        
        // Update AppModel
        appModel.selectedQuestionsCategory = category
        appModel.numberOfImposters = numberOfSpies
        
        // Configure Engine
        engine.configure(
            players: appModel.players,
            numberOfSpies: numberOfSpies,
            category: category,
            fairnessPolicy: appModel.fairnessPolicy,
            fairnessState: appModel.fairnessState
        )
        engine.startNewRound(roundIndex: 0)
        
        // Reset UI State
        showQuestionToCurrentPlayer = false
        answerText = ""
        
        // Timer Reset
        timeRemaining = discussionTime
        timerActive = false
        lastTimerSyncUptime = nil
        startTimer()
        
        // Host schickt RoundState an alle Teilnehmer
        if MultipeerManager.shared.role == .host {
            distributeRolesToPeers()
        }
    }
    
    func distributeRolesToPeers() {
        guard MultipeerManager.shared.role == .host, let round = engine.round else { return }
        
        let allPlayers = appModel.players
        let pair = round.promptPair
        pendingRoleAcks = Set(allPlayers.map { $0.name })
        pendingRoleAcks.remove(MultipeerManager.shared.myPeerId.displayName)
        
        for player in allPlayers {
            let role = engine.role(for: player.id)
            let prompt = (role == .spy) ? pair.spyQuestion : pair.citizenQuestion
            
            if player.name == MultipeerManager.shared.myPeerId.displayName {
                // Selbst setzen
                self.myRole = role
                self.myPrompt = prompt
                pendingRoleAcks.remove(player.name)
            } else if let peerID = MultipeerManager.shared.getPeer(byName: player.name) {
                // An Peer senden
                let payload = QuestionsRolePayload(role: role, prompt: prompt)
                MultipeerManager.shared.sendToPeer(event: MPCEventType.questionsRoleAssignment, object: payload, to: peerID)
            }
        }

        finalizeRoleDistributionIfReady()
    }

    func registerRoleAck(playerName: String) {
        guard MultipeerManager.shared.role == .host else { return }
        pendingRoleAcks.remove(playerName)
        finalizeRoleDistributionIfReady()
    }
    
    private func finalizeRoleDistributionIfReady() {
        guard MultipeerManager.shared.role == .host else { return }
        guard pendingRoleAcks.isEmpty else { return }
        syncStateToAll()
    }
    
    func startDiscussion() {
        if MultipeerManager.shared.role == .peer { return }
        engine.showOverview()
        timerActive = true
    }
    
    // MARK: - Collecting Logic
    
    func revealQuestionForCurrentPlayer() {
        showQuestionToCurrentPlayer = true
        answerText = ""
        inputStartTime = Date()
        currentInputDuration = 0
        startTimer() // Ensure timer is running for UI updates
    }
    
    func submitCurrentAnswer() {
        guard isAnswerValid else { return }
        
        let timeTaken = inputStartTime != nil ? Date().timeIntervalSince(inputStartTime!) : 0
        let myName = MultipeerManager.shared.myPeerId.displayName
        let myID = appModel.players.first(where: { $0.name == myName })?.id ?? UUID()
        
        print("🧪 [\(MultipeerManager.shared.role)] Sende Antwort für \(myName) (ID: \(myID))")
        
        let accepted = engine.submitAnswer(for: myID, text: answerText, timeTaken: timeTaken)
        
        if accepted {
            if MultipeerManager.shared.role == .peer {
                if let answer = engine.round?.answers[myID] {
                    print("🧪 [CLIENT] Antwort lokal gespeichert. Sende an Host...")
                    MultipeerManager.shared.sendToHost(event: MPCEventType.questionsAnswerSubmitted, object: answer)
                }
            }
            
            showQuestionToCurrentPlayer = false
            answerText = ""
            inputStartTime = nil
            
            if MultipeerManager.shared.role == .host {
                print("🧪 [HOST] Eigene Antwort gespeichert. Veranlasse Sync...")
                syncStateToAll()
            }
        }
    }
    
    // MARK: - MPC Sync
    
    func syncStateToAll() {
        guard MultipeerManager.shared.role == .host else { return }
        if let round = engine.round {
            print("🧪 [HOST] Sende State-Update an alle (Phase: \(round.phase), Antworten: \(round.answers.count)/\(appModel.players.count))")
            MultipeerManager.shared.sendToAll(event: MPCEventType.questionsStateSync, object: round)
        }
    }
    
    func registerRemoteAnswer(_ answer: QuestionsAnswer) {
        guard MultipeerManager.shared.role == .host else { return }
        print("🧪 [HOST] Remote-Antwort empfangen von Spieler-ID: \(answer.playerID)")
        engine.addExternalAnswer(answer)
        syncStateToAll()
    }
    
    func applyRoundStateSync(_ roundState: QuestionsRoundState) {
        engine.syncRoundState(roundState)
        if roundState.phase == .overview || roundState.phase == .voting {
            timerActive = discussionTime > 0
            startTimer()
            requestTimeSyncSamplesIfNeeded()
        } else {
            timerActive = false
            lastTimerSyncUptime = nil
            didRequestTimeSync = false
        }
    }

    func sendRejoinRequestIfNeeded() {
        guard MultipeerManager.shared.role == .peer else { return }
        guard !didSendRejoinRequest else { return }
        guard let playerID = localPlayerID() else { return }
        let payload = QuestionsRejoinRequestPayload(
            playerName: MultipeerManager.shared.myPeerId.displayName,
            playerID: playerID
        )
        MultipeerManager.shared.sendToHost(event: MPCEventType.questionsRejoinRequest, object: payload)
        didSendRejoinRequest = true
    }
    
    func resetRejoinRequestState() {
        didSendRejoinRequest = false
    }
    
    func handleRejoinRequest(_ request: QuestionsRejoinRequestPayload) {
        guard MultipeerManager.shared.role == .host else { return }
        guard let peer = MultipeerManager.shared.getPeer(byName: request.playerName) else { return }
        
        let config = QuestionsConfig(
            numberOfSpies: numberOfSpies,
            selectedCategory: selectedCategory,
            discussionTime: discussionTime,
            players: appModel.players
        )
        
        let roundState = engine.round
        let rolePayload: QuestionsRolePayload?
        if let roundState, let player = appModel.players.first(where: { $0.id == request.playerID }) {
            let role = engine.role(for: player.id)
            let prompt = role == .spy ? roundState.promptPair.spyQuestion : roundState.promptPair.citizenQuestion
            rolePayload = QuestionsRolePayload(role: role, prompt: prompt)
        } else {
            rolePayload = nil
        }
        
        let votingStatus: QuestionsVotingStatusPayload? = isRevealVoteActive
            ? QuestionsVotingStatusPayload(isActive: true, resetVotes: false, voteCounts: voteCounts)
            : nil
        
        let evaluation = revealEvaluation ?? lastRevealEvaluation
        
        let timerSync: QuestionsTimerSyncPayload?
        if (engine.phase == .overview || engine.phase == .voting), discussionTime > 0 {
            timerSync = QuestionsTimerSyncPayload(
                timeRemaining: timeRemaining,
                isTimerPaused: !timerActive,
                hostUptime: ProcessInfo.processInfo.systemUptime
            )
        } else {
            timerSync = nil
        }
        
        let payload = QuestionsRejoinStatePayload(
            config: config,
            roundState: roundState,
            role: rolePayload,
            votingStatus: votingStatus,
            evaluation: evaluation,
            timerSync: timerSync
        )
        MultipeerManager.shared.sendToPeer(event: MPCEventType.questionsRejoinState, object: payload, to: peer)
    }
    
    func applyRejoinState(_ payload: QuestionsRejoinStatePayload) {
        selectedCategory = payload.config.selectedCategory
        numberOfSpies = payload.config.numberOfSpies
        discussionTime = payload.config.discussionTime
        if !payload.config.players.isEmpty {
            appModel.players = payload.config.players
        }
        
        if let roundState = payload.roundState {
            applyRoundStateSync(roundState)
        }
        
        if let role = payload.role {
            myRole = role.role
            myPrompt = role.prompt
            showQuestionToCurrentPlayer = true
        }
        
        if let status = payload.votingStatus {
            applyVotingStatus(status)
        } else {
            isRevealVoteActive = false
            myVotes.removeAll()
            voteCounts.removeAll()
        }
        
        if let evaluation = payload.evaluation {
            applyVotingResult(evaluation)
        }
        
        if let sync = payload.timerSync {
            applyTimerSync(sync)
        }
    }
    
    // MARK: - Voting Logic
    
    func incrementVote(for playerID: UUID) {
        guard isRevealVoteActive, revealEvaluation == nil else { return }
        let role = MultipeerManager.shared.role
        
        if role == .unknown {
            if currentTotalVotes < maxVotes {
                let current = voteCounts[playerID] ?? 0
                voteCounts[playerID] = current + 1
            }
            return
        }
        
        guard myTotalVotes < maxVotesPerPlayer else { return }
        let current = myVotes[playerID] ?? 0
        myVotes[playerID] = current + 1
        submitMyVotes()
    }
    
    func decrementVote(for playerID: UUID) {
        let role = MultipeerManager.shared.role
        if role == .unknown {
            let current = voteCounts[playerID] ?? 0
            if current > 0 {
                voteCounts[playerID] = current - 1
            }
            return
        }
        
        let current = myVotes[playerID] ?? 0
        guard current > 0 else { return }
        let updated = current - 1
        if updated == 0 {
            myVotes.removeValue(forKey: playerID)
        } else {
            myVotes[playerID] = updated
        }
        submitMyVotes()
    }
    
    func canIncrementVote() -> Bool {
        let role = MultipeerManager.shared.role
        if role == .unknown {
            return currentTotalVotes < maxVotes
        }
        return myTotalVotes < maxVotesPerPlayer
    }
    
    func voteCountForDisplay(playerID: UUID) -> Int {
        let role = MultipeerManager.shared.role
        if role == .peer {
            return myVotes[playerID] ?? 0
        }
        return voteCounts[playerID] ?? 0
    }
    
    func applyVotingStatus(_ status: QuestionsVotingStatusPayload) {
        isRevealVoteActive = status.isActive
        voteCounts = status.voteCounts
        if status.resetVotes {
            myVotes.removeAll()
            revealEvaluation = nil
        }
    }
    
    func registerRemoteVote(_ payload: QuestionsVoteCastPayload) {
        guard MultipeerManager.shared.role == .host else { return }
        storeVotes(payload.votes, for: payload.voterID)
        broadcastVotingStatus(resetVotes: false)
    }
    
    private func submitMyVotes() {
        guard MultipeerManager.shared.role != .unknown else { return }
        guard let voterID = localPlayerID() else { return }
        
        let cleanedVotes = myVotes.filter { $0.value > 0 }
        if cleanedVotes.count != myVotes.count {
            myVotes = cleanedVotes
        }
        
        if MultipeerManager.shared.role == .host {
            storeVotes(myVotes, for: voterID)
            broadcastVotingStatus(resetVotes: false)
        } else if MultipeerManager.shared.role == .peer {
            let payload = QuestionsVoteCastPayload(voterID: voterID, votes: myVotes)
            MultipeerManager.shared.sendToHost(event: MPCEventType.questionsVoteCast, object: payload)
        }
    }
    
    private func storeVotes(_ votes: [UUID: Int], for voterID: UUID) {
        let cleanedVotes = votes.filter { $0.value > 0 }
        if cleanedVotes.isEmpty {
            votesByVoter.removeValue(forKey: voterID)
        } else {
            votesByVoter[voterID] = cleanedVotes
        }
        rebuildVoteCounts()
    }
    
    private func rebuildVoteCounts() {
        var counts: [UUID: Int] = [:]
        for votes in votesByVoter.values {
            for (targetID, count) in votes {
                counts[targetID, default: 0] += count
            }
        }
        voteCounts = counts
    }
    
    private func broadcastVotingStatus(resetVotes: Bool) {
        guard MultipeerManager.shared.role == .host else { return }
        let status = QuestionsVotingStatusPayload(
            isActive: isRevealVoteActive,
            resetVotes: resetVotes,
            voteCounts: voteCounts
        )
        MultipeerManager.shared.sendToAll(event: MPCEventType.questionsVotingStatus, object: status)
    }
    
    func handleRevealAction() {
        if MultipeerManager.shared.role == .peer { return }
        if !isRevealVoteActive {
            // Step 1: Switch to Voting Mode
            guard !answersInOrder.isEmpty else { return }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                beginVotingPhase()
            }
            
            // Special Case: No Spies (Edge Case)
            if engine.currentSpyIDs.isEmpty {
                let evaluation = QuestionsVoteEvaluation(selected: [], imposters: engine.currentSpyIDs)
                revealEvaluation = evaluation
                lastRevealEvaluation = evaluation
                broadcastVotingResult(evaluation)
                engine.finishRound()
                appModel.fairnessState.advanceRound()
            }
            
        } else if revealEvaluation == nil {
            // Step 2: Confirm Vote
            let suspects = currentLeaders
            guard !suspects.isEmpty else { return }
            
            // SUDDEN DEATH CHECK
            if suspects.count > 1 {
                startSuddenDeathAnimation(candidates: Array(suspects))
                return
            }
            
            evaluateVotes(suspects: suspects)
            
        } else {
            // Step 3: Finish Round
            if lastRevealEvaluation == nil { lastRevealEvaluation = revealEvaluation }
            engine.finishRound()
            appModel.fairnessState.advanceRound()
            resetRevealState()
        }
    }
    
    private func beginVotingPhase() {
        isRevealVoteActive = true
        myVotes.removeAll()
        voteCounts.removeAll()
        votesByVoter.removeAll()
        revealEvaluation = nil
        revealShakeTrigger = 0
        broadcastVotingStatus(resetVotes: true)
    }
    
    private func evaluateVotes(suspects: Set<UUID>) {
        let evaluation = QuestionsVoteEvaluation(selected: suspects, imposters: engine.currentSpyIDs)
        revealEvaluation = evaluation
        lastRevealEvaluation = evaluation
        
        if !evaluation.incorrect.isEmpty {
            // Spies Win (Wrong guess)
            if !engine.currentSpyIDs.isEmpty {
                appModel.addPoints(to: engine.currentSpyIDs, amount: 3)
            }
            withAnimation(.easeInOut(duration: 0.5)) { revealShakeTrigger += 1 }
            broadcastVotingResult(evaluation)
            engine.finishRound()
            appModel.fairnessState.advanceRound()
            return
        }
        
        foundRevealSpies.formUnion(evaluation.correct)
        if foundRevealSpies.count == engine.currentSpyIDs.count {
            // Citizens Win (All spies found)
            if !engine.currentSpyIDs.isEmpty {
                let allIDs = Set(appModel.players.map { $0.id })
                let citizenIDs = allIDs.subtracting(engine.currentSpyIDs)
                appModel.addPoints(to: citizenIDs, amount: 1)
            }
            
            let finalEval = QuestionsVoteEvaluation(selected: foundRevealSpies, imposters: engine.currentSpyIDs)
            revealEvaluation = finalEval
            lastRevealEvaluation = finalEval
            broadcastVotingResult(finalEval)
            engine.finishRound()
            appModel.fairnessState.advanceRound()
            return
        }
        
        // Partial Find / Spies Win Survived
        if !engine.currentSpyIDs.isEmpty {
            appModel.addPoints(to: engine.currentSpyIDs, amount: 3)
        }
        broadcastVotingResult(evaluation)
        engine.finishRound()
        appModel.fairnessState.advanceRound()
    }

    func applyVotingResult(_ evaluation: QuestionsVoteEvaluation) {
        revealEvaluation = evaluation
        lastRevealEvaluation = evaluation
        foundRevealSpies.formUnion(evaluation.correct)
        isRevealVoteActive = true
    }
    
    private func broadcastVotingResult(_ evaluation: QuestionsVoteEvaluation) {
        guard MultipeerManager.shared.role == .host else { return }
        MultipeerManager.shared.sendToAll(event: MPCEventType.questionsVotingResult, object: evaluation)
    }
    
    // MARK: - Sudden Death Logic
    
    private func startSuddenDeathAnimation(candidates: [UUID]) {
        suddenDeathCandidates = candidates.shuffled()
        isSuddenDeathActive = true
        suddenDeathHighlightIndex = 0
        
        if suddenDeathCandidates.count == 2 {
            // Coin Flip handled in View
            return
        }
        
        // Roulette Logic
        runRoulette()
    }
    
    private func runRoulette() {
        var iteration = 0
        let totalIterations = 20
        var interval: TimeInterval = 0.1
        
        func tick() {
            guard iteration < totalIterations else {
                let winnerID = suddenDeathCandidates[suddenDeathHighlightIndex]
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.resolveSuddenDeath(winnerID: winnerID)
                }
                return
            }
            
            suddenDeathHighlightIndex = (suddenDeathHighlightIndex + 1) % suddenDeathCandidates.count
            
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            
            iteration += 1
            if iteration > 10 { interval *= 1.15 }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + interval) {
                tick()
            }
        }
        
        tick()
    }
    
    func resolveSuddenDeath(winnerID: UUID) {
        withAnimation {
            isSuddenDeathActive = false
            voteCounts = [winnerID: 999] // Force Winner
        }
        handleRevealAction()
    }
    
    // MARK: - Helpers
    
    func handleRevealCardTap(playerID: UUID) {
        if showSpyDetailsList {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) { showSpyDetailsList = false }
            spyScrollTarget = nil
        } else {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.85)) { showSpyDetailsList = true }
            spyScrollTarget = playerID
        }
    }
    
    func resetRevealState(clearLast: Bool = false) {
        isRevealVoteActive = false
        myVotes.removeAll()
        voteCounts.removeAll()
        votesByVoter.removeAll()
        revealEvaluation = nil
        revealShakeTrigger = 0
        showSpyDetailsList = false
        spyScrollTarget = nil
        foundRevealSpies.removeAll()
        if clearLast { lastRevealEvaluation = nil }
        broadcastVotingStatus(resetVotes: true)
    }
    
    func playerName(for id: UUID) -> String {
        appModel.players.first(where: { $0.id == id })?.name ?? "Unbekannt"
    }
    
    private func localPlayerID() -> UUID? {
        let myName = MultipeerManager.shared.myPeerId.displayName
        return appModel.players.first(where: { $0.name == myName })?.id
    }
    
    func role(for playerID: UUID) -> QuestionsRole {
        engine.role(for: playerID)
    }
    
    func currentPlayer() -> Player? {
        engine.currentPlayer()
    }
    
    // MARK: - Timer
    
    private func startTimer() {
        timerCancellable?.cancel()
        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
    }
    
    private func tick() {
        // Input Timer (Collecting Phase)
        if showQuestionToCurrentPlayer {
            currentInputDuration += 1
        }
        
        // Discussion Timer (Overview Phase)
        guard timerActive && timeRemaining > 0 else { return }
        if engine.phase == .overview || engine.phase == .voting {
            timeRemaining -= 1
        }
        if MultipeerManager.shared.role == .host {
            maybeSyncTimer()
        }
    }
    
    func timeString(from time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    func applyTimerSync(_ sync: QuestionsTimerSyncPayload) {
        guard discussionTime > 0 else { return }
        let now = ProcessInfo.processInfo.systemUptime
        let hostUptimeAtClient = sync.hostUptime - hostClockOffset
        let elapsed = max(0, now - hostUptimeAtClient)
        let expectedRemaining = max(0, sync.timeRemaining - (sync.isTimerPaused ? 0 : elapsed))
        let delta = expectedRemaining - timeRemaining
        if abs(delta) > 1 {
            timeRemaining = expectedRemaining
        } else {
            timeRemaining += delta * 0.5
        }
        timerActive = !sync.isTimerPaused
        startTimer()
    }
    
    func requestTimeSyncSamplesIfNeeded() {
        guard MultipeerManager.shared.role == .peer else { return }
        guard !didRequestTimeSync else { return }
        didRequestTimeSync = true
        for idx in 0..<3 {
            let delay = Double(idx) * 0.35
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                self.sendTimeSyncPing()
            }
        }
    }
    
    func applyTimeSyncPong(_ pong: QuestionsTimeSyncPongPayload) {
        let myName = MultipeerManager.shared.myPeerId.displayName
        guard pong.clientName == myName else { return }
        let receiveUptime = ProcessInfo.processInfo.systemUptime
        let outbound = pong.clientSendUptime
        let inbound = receiveUptime
        let hostDelta = pong.hostSendUptime - pong.hostReceiveUptime
        let rtt = max(0, (inbound - outbound) - hostDelta)
        let offset = ((pong.hostReceiveUptime - outbound) + (pong.hostSendUptime - inbound)) / 2
        if rtt < hostClockOffsetRTT {
            hostClockOffsetRTT = rtt
            hostClockOffset = offset
        }
    }
    
    private func sendTimeSyncPing() {
        let payload = QuestionsTimeSyncPingPayload(
            clientName: MultipeerManager.shared.myPeerId.displayName,
            pingId: UUID(),
            clientSendUptime: ProcessInfo.processInfo.systemUptime
        )
        MultipeerManager.shared.sendToHost(event: MPCEventType.questionsTimeSyncPing, object: payload)
    }
    
    private func maybeSyncTimer() {
        guard timerActive, discussionTime > 0 else { return }
        guard engine.phase == .overview || engine.phase == .voting else { return }
        let now = ProcessInfo.processInfo.systemUptime
        if let lastSync = lastTimerSyncUptime, now - lastSync < timerSyncInterval {
            return
        }
        lastTimerSyncUptime = now
        let payload = QuestionsTimerSyncPayload(
            timeRemaining: timeRemaining,
            isTimerPaused: !timerActive,
            hostUptime: now
        )
        MultipeerManager.shared.sendToAll(event: MPCEventType.questionsTimerSync, object: payload)
    }
}
