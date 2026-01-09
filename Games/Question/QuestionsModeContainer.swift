import SwiftUI
import Combine

struct QuestionsModeContainer: View {
    // Shared app settings
    @ObservedObject var appModel: AppModel

    // Engine for Questions mode
    @StateObject private var engine = QuestionsEngine()

    // Setup state
    @State private var selectedCategory: QuestionsCategory? = nil
    @State private var numberOfSpies: Int = 1
    @State private var discussionTime: TimeInterval = 180

    // UI State & Navigation
    @Environment(\.dismiss) var dismiss
    @State private var showAbortConfirmation = false
    @State private var showEmptyCategoryAlert = false

    // Collecting phase state
    @State private var showQuestionToCurrentPlayer: Bool = false
    @State private var answerText: String = ""
    @FocusState private var isAnswerFocused: Bool

    // Voting results state
    @State private var isRevealVoteActive = false
    @State private var voteCounts: [UUID: Int] = [:] // Changed from Set to Dictionary
    @State private var revealEvaluation: QuestionsVoteEvaluation? = nil
    @State private var lastRevealEvaluation: QuestionsVoteEvaluation? = nil
    @State private var foundRevealSpies: Set<UUID> = []
    @State private var revealShakeTrigger: CGFloat = 0
    @State private var showSpyDetailsList = false
    @State private var spyScrollTarget: UUID? = nil
    
    // Timer State
    @State private var timeRemaining: TimeInterval = 0
    @State private var timerActive = false
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    // Input Timer State
    @State private var inputStartTime: Date? = nil
    
    // Reveal Animation State
    @State private var revealStage: Int = 0
    
    // Sudden Death State
    @State private var isSuddenDeathActive = false
    @State private var suddenDeathCandidates: [UUID] = []
    @State private var suddenDeathHighlightIndex: Int = 0
    @State private var suddenDeathTimer: Timer?
    
    // Berechnete Variablen
    private var playerCount: Int { appModel.players.count }
    
    private var maxVotes: Int {
        playerCount * engine.config.numberOfSpies
    }
    
    private var currentTotalVotes: Int {
        voteCounts.values.reduce(0, +)
    }

    // MARK: - Body (Der Traffic Controller)
    var body: some View {
        ZStack(alignment: .top) {
            
            // LAYER 1: INHALT (Wechselt je nach Phase)
            Group {
                switch engine.phase {
                case .setup:
                    QuestionsSetupView(
                        appModel: appModel,
                        selectedCategory: $selectedCategory,
                        numberOfSpies: $numberOfSpies,
                        discussionTime: $discussionTime,
                        onStartGame: startRound
                    )
                    .padding(.top, 0)
                    
                case .collecting:
                    collectingView
                        .padding(.top, 0)
                case .revealed:
                    revealedView
                        .padding(.top, 0)
                case .overview, .voting:
                    overviewView
                        .padding(.top, 0)
                case .finished:
                    questionsResultOverlay
                }
            }
            
            // LAYER 2: HEADER (Immer sichtbar, außer im Setup)
            if engine.phase != .setup {
                customHeader
            }
            
            // LAYER 3: SUDDEN DEATH OVERLAY
            if isSuddenDeathActive {
                ZStack {
                    Color.black.opacity(0.95).ignoresSafeArea()
                    
                    VStack(spacing: 40) {
                        Text("SUDDEN DEATH")
                            .font(.system(size: 40, weight: .black, design: .rounded))
                            .foregroundStyle(Color.red)
                            .shadow(color: .red, radius: 10)
                        
                        Text("Das Schicksal entscheidet...")
                            .font(.headline)
                            .foregroundStyle(.white.opacity(0.7))
                        
                        Spacer()
                        
                        if suddenDeathCandidates.count == 2 {
                            // COIN FLIP MODE
                            let c1 = suddenDeathCandidates[0]
                            let c2 = suddenDeathCandidates[1]
                            // Random winner was determined by shuffle at start (index 0 is winner)
                            // Wait, if shuffle is random, index 0 is random. So let's say index 0 is the winner.
                            // Front (0 deg) = c1. Back (180 deg) = c2.
                            // To make c1 win, end at 360*N + 0.
                            // To make c2 win, end at 360*N + 180.
                            // Let's pick a random boolean here for the visual flip to match logic?
                            // Actually, simpler: Let's pick the winner NOW.
                            let winnerIndex = Int.random(in: 0...1)
                            let winnerID = suddenDeathCandidates[winnerIndex]
                            let rotation = Double(5 * 360) + (winnerIndex == 0 ? 0.0 : 180.0)
                            
                            Coin3D(
                                frontText: playerName(for: c1),
                                backText: playerName(for: c2),
                                finalRotation: rotation,
                                onFinish: { resolveSuddenDeath(winnerID: winnerID) }
                            )
                        } else if !suddenDeathCandidates.isEmpty {
                            // ROULETTE MODE
                            let currentID = suddenDeathCandidates[suddenDeathHighlightIndex]
                            Text(playerName(for: currentID))
                                .font(.system(size: 50, weight: .heavy, design: .rounded))
                                .foregroundStyle(.white)
                                .scaleEffect(1.2)
                                .transition(.identity) // Snappy switch
                                .id(currentID) // Force redraw for animation
                        }
                        
                        Spacer()
                    }
                    .padding()
                }
                .transition(.opacity)
                .zIndex(100)
            }
        }
        .ignoresSafeArea(edges: .top)
        .navigationBarHidden(true)
        .alert("Spiel abbrechen?", isPresented: $showAbortConfirmation) {
            Button("Abbrechen", role: .cancel) { }
            Button("Ja", role: .destructive) { dismiss() }
        } message: { Text("Bist du dir sicher das du abbrechen willst?") }
        .alert("Kategorie ohne Fragen", isPresented: $showEmptyCategoryAlert) {
            Button("OK", role: .cancel) { }
        } message: { Text("Diese Kategorie enthält keine Fragen.") }
        .onAppear(perform: setupDefaults)
        .onReceive(timer) { _ in
            guard timerActive && timeRemaining > 0 else { return }
            if engine.phase == .overview || engine.phase == .voting {
                timeRemaining -= 1
            }
        }
    }
    
    // MARK: - Logic Helpers
    private func setupDefaults() {
        if selectedCategory == nil {
            selectedCategory = appModel.selectedQuestionsCategory ?? QuestionsDefaults.all.first
        }
        numberOfSpies = min(max(1, appModel.numberOfImposters), max(0, playerCount > 1 ? playerCount - 1 : 0))
    }

    private func startRound() {
        resetRevealState(clearLast: true)
        guard let category = selectedCategory else { return }
        guard !category.promptPairs.isEmpty else {
            showEmptyCategoryAlert = true
            return
        }
        appModel.selectedQuestionsCategory = category
        appModel.numberOfImposters = numberOfSpies
        
        engine.configure(
            players: appModel.players,
            numberOfSpies: numberOfSpies,
            category: category,
            fairnessPolicy: appModel.fairnessPolicy,
            fairnessState: appModel.fairnessState
        )
        engine.startNewRound(roundIndex: 0)
        showQuestionToCurrentPlayer = false
        answerText = ""
        
        // Timer Reset
        timeRemaining = discussionTime
        timerActive = false
    }
    
    private var headerContentColor: Color {
        engine.phase == .setup ? .white : .white
    }
    
    private var customHeader: some View {
        HStack {
            Button(action: { showAbortConfirmation = true }) {
                Image(systemName: "chevron.left")
                    .font(.title3.weight(.bold))
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Color.black.opacity(0.3))
                    .clipShape(Circle())
            }
            Spacer()
        }
        .overlay(
            Text(LocalizedStringKey(engine.phase == .setup ? "Fragen — Setup" : "Finde den Lügner"))
                .font(.headline.weight(.bold))
                .foregroundColor(.white)
        )
        .padding(.horizontal, 16)
        .padding(.top, 50)
    }
    
    private var brandGradient: LinearGradient { QuestionsTheme.gradient }
}

// MARK: - Extension: Game Phases UI

extension QuestionsModeContainer {
    
    // Phase: Collecting (Fragen beantworten)
    var collectingView: some View {
        ZStack {
            brandGradient.ignoresSafeArea()
            VStack(spacing: 20) {
                Color.clear.frame(height: 110)
                Spacer(minLength: 0)

                Group {
                    if let round = engine.round, let player = engine.currentPlayer() {
                        let pair = round.promptPair
                        VStack(spacing: 22) {
                            Text("Spieler \(round.currentPlayerIndex + 1) von \(playerCount)")
                                .font(.system(size: 22, weight: .heavy, design: .rounded))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)

                            if !showQuestionToCurrentPlayer {
                                QuestionsSecureRevealButton(playerName: player.name) {
                                    revealQuestionForCurrentPlayer()
                                }
                                .padding(.top, 20)
                            } else {
                                let role = engine.role(for: player.id)
                                let question = role == .spy ? pair.spyQuestion : pair.citizenQuestion
                                VStack(spacing: 18) {
                                    QuestionsPromptBoard(question: question)
                                    QuestionsAnswerBoard(text: $answerText, focus: $isAnswerFocused)
                                    Button(action: submitCurrentAnswer) { Text("Antwort speichern").font(.headline) }
                                        .buttonStyle(QuestionsPrimaryButtonStyle(disabled: !isAnswerValid))
                                        .disabled(!isAnswerValid)
                                }
                            }
                        }
                        .frame(maxWidth: 520)
                        .padding(.horizontal, 24)
                    } else {
                        ProgressView("Runde wird vorbereitet…").tint(.white)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(.bottom, 32)
        }
        .onTapGesture { isAnswerFocused = false }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: showQuestionToCurrentPlayer)
    }

    private func revealQuestionForCurrentPlayer() {
        showQuestionToCurrentPlayer = true
        answerText = ""
        inputStartTime = Date()
    }

    private func submitCurrentAnswer() {
        guard isAnswerValid else { return }
        
        let timeTaken = inputStartTime != nil ? Date().timeIntervalSince(inputStartTime!) : 0
        let accepted = engine.submitAnswer(text: answerText, timeTaken: timeTaken)
        
        if accepted {
            showQuestionToCurrentPlayer = false
            answerText = ""
            inputStartTime = nil
        }
    }
    
    private var isAnswerValid: Bool {
        !answerText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // Phase: Revealed (Zwischenstand)
    var revealedView: some View {
        ZStack {
            brandGradient.ignoresSafeArea()
            VStack(spacing: 24) {
                Color.clear.frame(height: 110)
                Spacer(minLength: 0)
                if let round = engine.round {
                    QuestionsPromptBoard(question: round.promptPair.citizenQuestion)
                        .padding(.horizontal, 24)
                }
                Text("Los geht’s! Gleich seht ihr alle Antworten – danach diskutiert ihr die Frage oben.")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                Button("Runde starten") { 
                    engine.showOverview()
                    timerActive = true
                }
                    .buttonStyle(QuestionsPrimaryButtonStyle())
                    .padding(.horizontal, 40)
                Spacer(minLength: 0)
            }
            .padding(.bottom, 32)
        }
    }
    
    // Phase: Overview & Voting
    var overviewView: some View {
        ZStack {
            brandGradient.ignoresSafeArea()
            VStack(spacing: 20) {
                Color.clear.frame(height: 80)
                
                // Timer Display
                if discussionTime > 0 {
                    HStack(spacing: 8) {
                        Image(systemName: "timer")
                        Text(timeString(from: timeRemaining))
                            .font(.system(.title3, design: .monospaced).weight(.bold))
                    }
                    .foregroundColor(timeRemaining < 30 ? .red : .white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .scaleEffect(timeRemaining < 10 && timeRemaining > 0 && Int(timeRemaining) % 2 == 0 ? 1.1 : 1.0)
                    .animation(.default, value: timeRemaining)
                }
                
                if let round = engine.round {
                    Text(LocalizedStringKey(round.promptPair.citizenQuestion))
                        .font(.title3.weight(.bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                if answersInOrder.isEmpty {
                    Text("Es wurden noch keine Antworten erfasst.")
                        .font(.subheadline).foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center).padding(.horizontal, 24)
                    Spacer()
                } else {
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVGrid(columns: revealGridColumns, spacing: showSpyDetailsList ? 18 : 12) {
                                ForEach(answersInOrder, id: \.id) { answer in
                                    let playerID = answer.playerID
                                    let name = playerName(for: playerID)
                                    let evaluation = revealEvaluation
                                    
                                    // Voting Logic
                                    let voteCount = voteCounts[playerID] ?? 0
                                    let showSelectionBox = isRevealVoteActive && evaluation == nil && !foundRevealSpies.contains(playerID)
                                    
                                    let showGreenCheck = evaluation?.correct.contains(playerID) == true || foundRevealSpies.contains(playerID)
                                    let revealRoundOver = evaluation.map { $0.citizensWon || !$0.incorrect.isEmpty } ?? false
                                    let highlightAsSpy = revealRoundOver && engine.currentSpyIDs.contains(playerID)
                                    
                                    QuestionsAnswerRevealCard(
                                        playerName: name,
                                        answer: answer,
                                        isSelected: false,
                                        showSelectionBox: showSelectionBox,
                                        selectionEnabled: showSelectionBox,
                                        showGreenCheck: showGreenCheck,
                                        showRedX: highlightAsSpy,
                                        shakeTrigger: highlightAsSpy ? revealShakeTrigger : 0,
                                        isFullWidth: showSpyDetailsList,
                                        spyQuestion: spyQuestion(for: playerID),
                                        voteCount: voteCount,
                                        canIncrement: currentTotalVotes < maxVotes,
                                        onIncrement: { incrementVote(for: playerID) },
                                        onDecrement: { decrementVote(for: playerID) }
                                    ) { handleRevealCardTap(playerID: playerID) }
                                    .id(playerID)
                                }
                            }
                            .padding(.horizontal, 20).padding(.top, 4)
                            Color.clear.frame(height: 140)
                        }
                        .frame(maxHeight: .infinity, alignment: .top)
                        .onChange(of: spyScrollTarget) { oldValue, target in
                            guard let target else { return }
                            DispatchQueue.main.async {
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) { proxy.scrollTo(target, anchor: .top) }
                            }
                        }
                    }
                }
            }
            .padding(.bottom, isRevealVoteActive ? 110 : 30)
            VStack { Spacer(); revealActionBar }
        }
    }
    
    // Helpers for Overview/Voting
    private var answersInOrder: [QuestionsAnswer] {
        guard let answersDict = engine.round?.answers else { return [] }
        return appModel.players.compactMap { answersDict[$0.id] }
    }
    private var revealGridColumns: [GridItem] {
        showSpyDetailsList ? [GridItem(.flexible())] : [GridItem(.flexible()), GridItem(.flexible())]
    }
    private var canRevealNow: Bool {
        if !isRevealVoteActive { return !answersInOrder.isEmpty }
        if revealEvaluation == nil {
            // Can reveal if at least one vote is cast
            return !voteCounts.isEmpty && voteCounts.values.reduce(0, +) > 0
        }
        return true
    }
    
    private var revealButtonTitle: LocalizedStringKey {
        if !isRevealVoteActive { return "Lügner aufdecken" }
        if revealEvaluation == nil { return "Aufdecken" }
        return "Runde abschließen"
    }
    
    private var revealStatusMessage: LocalizedStringKey? {
        if !isRevealVoteActive { return !answersInOrder.isEmpty ? "Diskutiert und verteilt dann die Stimmen." : nil }
        if let evaluation = revealEvaluation {
            if evaluation.citizensWon { return "Treffer! Alle Lügner wurden enttarnt." }
            if !evaluation.incorrect.isEmpty { return "Daneben! Die Lügner bleiben verborgen." }
            return "Richtiger Treffer – es sind noch Lügner übrig."
        }
        if engine.currentSpyIDs.isEmpty { return "Keine Spione in dieser Runde." }
        
        // Voting Phase Status
        if currentTotalVotes < maxVotes {
            let remaining = maxVotes - currentTotalVotes
            return "Vergebt noch \(remaining) Stimmen (\(currentTotalVotes)/\(maxVotes))."
        }
        
        let leadingIDs = currentLeaders
        if leadingIDs.isEmpty {
            return "Bereit zum Aufdecken."
        } else if leadingIDs.count == 1, let leaderID = leadingIDs.first {
             let name = playerName(for: leaderID)
             return "Hauptverdächtiger: \(name)"
        } else {
            return "Gleichstand zwischen \(leadingIDs.count) Spielern."
        }
    }
    
    private var currentLeaders: Set<UUID> {
        guard !voteCounts.isEmpty else { return [] }
        let maxVotes = voteCounts.values.max() ?? 0
        guard maxVotes > 0 else { return [] }
        return Set(voteCounts.filter { $0.value == maxVotes }.map { $0.key })
    }
    
    private var revealActionBar: some View {
        Group {
            if !answersInOrder.isEmpty || isRevealVoteActive {
                VStack(spacing: 10) {
                    if let message = revealStatusMessage {
                        Text(message).font(.footnote).foregroundColor(.white.opacity(0.9)).multilineTextAlignment(.center).frame(maxWidth: .infinity)
                    }
                    Button(action: handleRevealAction) {
                        Text(revealButtonTitle).font(.headline).frame(maxWidth: .infinity).padding(.vertical, 14)
                            .background(canRevealNow ? Color.white.opacity(0.85) : Color.white.opacity(0.25))
                            .foregroundColor(canRevealNow ? QuestionsTheme.textAccent : .white.opacity(0.8))
                            .cornerRadius(26)
                    }.disabled(!canRevealNow)
                }.padding(.horizontal, 24).padding(.vertical, 18).padding(.bottom, 24)
            }
        }
    }
    
    private func incrementVote(for playerID: UUID) {
        if currentTotalVotes < maxVotes {
            let current = voteCounts[playerID] ?? 0
            voteCounts[playerID] = current + 1
        }
    }
    
    private func decrementVote(for playerID: UUID) {
        let current = voteCounts[playerID] ?? 0
        if current > 0 {
            voteCounts[playerID] = current - 1
        }
    }
    
    private func handleRevealAction() {
        if !isRevealVoteActive {
            guard !answersInOrder.isEmpty else { return }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                isRevealVoteActive = true
                voteCounts.removeAll()
                revealEvaluation = nil
                revealShakeTrigger = 0
            }
            if engine.currentSpyIDs.isEmpty {
                let evaluation = QuestionsVoteEvaluation(selected: [], imposters: engine.currentSpyIDs)
                revealEvaluation = evaluation
                lastRevealEvaluation = evaluation
                engine.finishRound()
                appModel.fairnessState.advanceRound()
            }
        } else if revealEvaluation == nil {
            // Determine selected suspects based on MAX votes
            let suspects = currentLeaders
            guard !suspects.isEmpty else { return }
            
            // SUDDEN DEATH CHECK
            if suspects.count > 1 {
                startSuddenDeathAnimation(candidates: Array(suspects))
                return
            }
            
            let evaluation = QuestionsVoteEvaluation(selected: suspects, imposters: engine.currentSpyIDs)
            revealEvaluation = evaluation
            lastRevealEvaluation = evaluation
            
            if !evaluation.incorrect.isEmpty {
                // Spies Win (Wrong guess)
                if !engine.currentSpyIDs.isEmpty {
                    appModel.addPoints(to: engine.currentSpyIDs, amount: 3)
                }
                withAnimation(.easeInOut(duration: 0.5)) { revealShakeTrigger += 1 }
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
                engine.finishRound()
                appModel.fairnessState.advanceRound()
                return
            }
            
            // Spies Win (Survived / Partial find ends round)
            if !engine.currentSpyIDs.isEmpty {
                appModel.addPoints(to: engine.currentSpyIDs, amount: 3)
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
        suddenDeathCandidates = candidates.shuffled() // Shuffle for randomness
        isSuddenDeathActive = true
        suddenDeathHighlightIndex = 0
        
        // If 2 candidates, we use Coin Flip (visual handled in View)
        if suddenDeathCandidates.count == 2 {
            return
        }
        
        // Roulette Logic for 3+
        var iteration = 0
        let totalIterations = 20 // How many ticks before stop
        var interval: TimeInterval = 0.1
        
        func tick() {
            guard iteration < totalIterations else {
                // Finish
                let winnerID = suddenDeathCandidates[suddenDeathHighlightIndex]
                
                // Final Impact
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    resolveSuddenDeath(winnerID: winnerID)
                }
                return
            }
            
            // Update UI
            suddenDeathHighlightIndex = (suddenDeathHighlightIndex + 1) % suddenDeathCandidates.count
            
            // Haptic
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            
            // Schedule next tick (slowing down)
            iteration += 1
            if iteration > 10 { interval *= 1.15 } // Slow down curve
            
            DispatchQueue.main.asyncAfter(deadline: .now() + interval) {
                tick()
            }
        }
        
        tick()
    }
    
    private func resolveSuddenDeath(winnerID: UUID) {
        withAnimation {
            isSuddenDeathActive = false
            // Force the vote result
            voteCounts = [winnerID: 999] 
        }
        // Proceed with reveal
        handleRevealAction()
    }
    
    private func handleRevealCardTap(playerID: UUID) {
        if showSpyDetailsList {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) { showSpyDetailsList = false }
            spyScrollTarget = nil
        } else {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.85)) { showSpyDetailsList = true }
            spyScrollTarget = playerID
        }
    }
    
    private func resetRevealState(clearLast: Bool = false) {
        isRevealVoteActive = false; voteCounts.removeAll(); revealEvaluation = nil; revealShakeTrigger = 0; showSpyDetailsList = false; spyScrollTarget = nil; foundRevealSpies.removeAll()
        if clearLast { lastRevealEvaluation = nil }
    }
    
    private func timeString(from time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func playerName(for id: UUID) -> String { appModel.players.first(where: { $0.id == id })?.name ?? "Unbekannt" }
    
    // HIER DIE ANPASSUNG: Immer nil während des Spiels
    private func spyQuestion(for id: UUID) -> String? {
        // Die Spion-Frage soll während der Voting/Overview-Phase NIE angezeigt werden.
        // Nur am Ende im ResultOverlay.
        return nil
    }
    
    // Phase: Result Overlay
    var questionsResultOverlay: some View {
        let evaluation = lastRevealEvaluation
        let spies = appModel.players.filter { engine.currentSpyIDs.contains($0.id) }
        
        let spyQuestionText = engine.round?.promptPair.spyQuestion ?? "Unbekannt"
        
        // Data for animation
        let suspectID = evaluation?.selected.first // Assuming single selection for drama, or handle multiple
        let suspectName = suspectID != nil ? playerName(for: suspectID!) : "Niemand"
        let isSpy = suspectID != nil && engine.currentSpyIDs.contains(suspectID!)
        let citizensWon = evaluation?.citizensWon ?? false
        
        return ZStack {
            QuestionsStyle.backgroundGradient.ignoresSafeArea()
            
            if revealStage == 0 {
                Text("Das Urteil...")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
                    .transition(.opacity)
            }
            
            if revealStage >= 1 {
                VStack(spacing: 20) {
                    Text("Hauptverdächtiger:")
                        .font(.headline)
                        .foregroundStyle(QuestionsStyle.mutedText)
                        .textCase(.uppercase)
                    
                    Text(LocalizedStringKey(suspectName))
                        .font(.system(size: 46, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                        .scaleEffect(revealStage >= 1 ? 1.0 : 0.5)
                        .animation(.spring(response: 0.6), value: revealStage)
                }
                .padding(.bottom, 50)
            }
            
            if revealStage >= 2 {
                // STAMP
                ZStack {
                    if let _ = suspectID {
                        Text(isSpy ? "SPION" : "BÜRGER")
                            .font(.system(size: 60, weight: .black, design: .rounded))
                            .foregroundColor(isSpy ? .red : .green)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(isSpy ? Color.red : Color.green, lineWidth: 8)
                            )
                            .rotationEffect(.degrees(-15))
                            .scaleEffect(revealStage == 2 ? 1.2 : 1.0) // Bounce effect needs specific state trigger
                            .opacity(revealStage >= 2 ? 1.0 : 0.0)
                    } else {
                        Text("Kein Ergebnis")
                            .font(.title.bold())
                            .foregroundStyle(.white)
                    }
                }
                .transition(.scale.combined(with: .opacity))
            }
            
            if revealStage >= 3 {
                VStack(spacing: 24) {
                    Spacer().frame(height: 180) // Push content down below the stamp
                    
                    VStack(spacing: 8) {
                        Text(citizensWon ? "Bewohner haben gewonnen" : "Spione haben gewonnen")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                        Text(citizensWon ? "Alle Lügner wurden enttarnt." : "Die Lügner bleiben im Verborgenen.")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)
                    
                    VStack(spacing: 8) {
                        Text("Frage der Spione:")
                            .font(.caption.weight(.bold))
                            .textCase(.uppercase)
                            .foregroundStyle(.white.opacity(0.6))
                        
                        Text(LocalizedStringKey(spyQuestionText))
                            .font(.title3.weight(.bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                            .padding(.vertical, 12)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(.white.opacity(0.15), lineWidth: 1)
                            )
                    }
                    .padding(.horizontal, 24)
                    
                    if !spies.isEmpty {
                        VStack(spacing: 12) {
                            Text("Tatsächliche Lügner")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.9))
                            
                            VStack(spacing: 8) {
                                ForEach(spies, id: \.id) { p in
                                    HStack {
                                        Image(systemName: "person.fill.questionmark")
                                            .font(.title3)
                                            .foregroundColor(.white)
                                            .frame(width: 30)
                                        
                                        Text(LocalizedStringKey(p.name))
                                            .font(.title3.weight(.semibold))
                                            .foregroundColor(.white)
                                        
                                        Spacer()
                                        
                                        Text("SPION")
                                            .font(.caption.bold())
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.red.opacity(0.8))
                                            .foregroundColor(.white)
                                            .clipShape(Capsule())
                                    }
                                    .padding(12)
                                    .background(
                                        LinearGradient(
                                            colors: [Color.red.opacity(0.3), Color.red.opacity(0.1)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(Color.red.opacity(0.4), lineWidth: 1)
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                    
                    // Scoreboard
                    QuestionsScoreboardView(appModel: appModel)
                    
                    Spacer()
                    
                    VStack(spacing: 12) {
                        Button { startRound() } label: {
                            Text("Neue Runde")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.white)
                                .foregroundColor(QuestionsTheme.textAccent)
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                        }
                        Button { dismiss() } label: {
                            Text("Zurück")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.white.opacity(0.18))
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 26)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .onAppear {
            startRevealAnimation()
        }
    }
    
    private func startRevealAnimation() {
        revealStage = 0
        
        // Sequence
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation { revealStage = 1 } // Show Name
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            // Impact Haptic
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error) // Heavy impact feel
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) { revealStage = 2 } // Show Stamp
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeOut(duration: 0.5)) { revealStage = 3 } // Show Details
        }
    }
}

// MARK: - Internal Scoreboard View
struct QuestionsScoreboardView: View {
    @ObservedObject var appModel: AppModel
    
    var sortedPlayers: [(player: Player, score: Int)] {
        appModel.players.map { ($0, appModel.getScore(for: $0.id)) }
            .sorted { $0.score > $1.score }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Rangliste")
                .font(.headline)
                .foregroundStyle(QuestionsStyle.mutedText)
                .textCase(.uppercase)
                .kerning(1)
            
            VStack(spacing: 8) {
                ForEach(Array(sortedPlayers.enumerated()), id: \.element.player.id) { index, entry in
                    HStack {
                        // Rank
                        Text("\(index + 1).")
                            .font(.headline.monospacedDigit())
                            .foregroundStyle(QuestionsStyle.mutedText)
                            .frame(width: 30, alignment: .leading)
                        
                        // Name
                        Text(entry.player.name)
                            .font(.headline)
                            .foregroundStyle(.white)
                        
                        Spacer()
                        
                        // Score
                        Text("\(entry.score) Pkt")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(entry.score > 0 ? QuestionsTheme.accent : .white.opacity(0.5))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 20)
    }
}
