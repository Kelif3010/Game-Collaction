import SwiftUI

struct QuestionsModeContainer: View {
    // Shared app settings
    @ObservedObject var appModel: AppModel

    // Engine for Questions mode
    @StateObject private var engine = QuestionsEngine()

    // Setup state
    @State private var selectedCategory: QuestionsCategory? = nil
    @State private var numberOfSpies: Int = 1

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
    @State private var selectedSuspects: Set<UUID> = []
    @State private var revealEvaluation: QuestionsVoteEvaluation? = nil
    @State private var lastRevealEvaluation: QuestionsVoteEvaluation? = nil
    @State private var foundRevealSpies: Set<UUID> = []
    @State private var revealShakeTrigger: CGFloat = 0
    @State private var showSpyDetailsList = false
    @State private var spyScrollTarget: UUID? = nil
    
    // Berechnete Variablen
    private var playerCount: Int { appModel.players.count }

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
            Text(engine.phase == .setup ? "Fragen — Setup" : "Finde den Lügner")
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
                                VStack(spacing: 16) {
                                    QuestionsFlipCard(title: player.name)
                                        .onTapGesture { revealQuestionForCurrentPlayer() }
                                    Text("Gerät jetzt nur von \(player.name) benutzen. Tippe, um deine Frage zu sehen.")
                                        .font(.body)
                                        .foregroundColor(.white.opacity(0.85))
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 16)
                                    Button("Karte anzeigen") { revealQuestionForCurrentPlayer() }
                                        .buttonStyle(QuestionsPrimaryButtonStyle())
                                }
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
    }

    private func submitCurrentAnswer() {
        guard isAnswerValid else { return }
        let accepted = engine.submitAnswer(text: answerText)
        if accepted {
            showQuestionToCurrentPlayer = false
            answerText = ""
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
                Button("Runde starten") { engine.showOverview() }
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
                if let round = engine.round {
                    Text(round.promptPair.citizenQuestion)
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
                                    let isSelected = selectedSuspects.contains(playerID)
                                    
                                    let showSelectionBox = isRevealVoteActive && evaluation == nil && !foundRevealSpies.contains(playerID)
                                    
                                    let showGreenCheck = evaluation?.correct.contains(playerID) == true || foundRevealSpies.contains(playerID)
                                    let revealRoundOver = evaluation.map { $0.citizensWon || !$0.incorrect.isEmpty } ?? false
                                    let highlightAsSpy = revealRoundOver && engine.currentSpyIDs.contains(playerID)
                                    
                                    QuestionsAnswerRevealCard(
                                        playerName: name,
                                        answer: answer,
                                        isSelected: isSelected,
                                        showSelectionBox: showSelectionBox,
                                        selectionEnabled: showSelectionBox,
                                        showGreenCheck: showGreenCheck,
                                        showRedX: highlightAsSpy,
                                        shakeTrigger: highlightAsSpy ? revealShakeTrigger : 0,
                                        isFullWidth: showSpyDetailsList,
                                        spyQuestion: spyQuestion(for: playerID)
                                    ) { handleRevealCardTap(playerID: playerID, selectionEnabled: showSelectionBox) }
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
            return !selectedSuspects.isEmpty
        }
        return true
    }
    private var revealButtonTitle: String {
        if !isRevealVoteActive { return "Lügner aufdecken" }
        if revealEvaluation == nil { return "Aufdecken" }
        return "Runde abschließen"
    }
    private var revealStatusMessage: String? {
        if !isRevealVoteActive { return !answersInOrder.isEmpty ? "Markiere die verdächtigen Spieler, um sie aufzudecken." : nil }
        if let evaluation = revealEvaluation {
            if evaluation.citizensWon { return "Treffer! Alle Lügner wurden enttarnt." }
            if !evaluation.incorrect.isEmpty { return "Daneben! Die Lügner bleiben verborgen." }
            return "Richtiger Treffer – es sind noch Lügner übrig."
        }
        if engine.currentSpyIDs.isEmpty { return "Keine Spione in dieser Runde." }
        
        let needed = max(1, engine.currentSpyIDs.count - foundRevealSpies.count)
        let current = selectedSuspects.count
        if current == 0 {
            return "Wähle \(needed) Verdächtige(n)."
        } else if current < needed {
            return "Wähle noch \(needed - current) Verdächtige."
        } else {
            return "Bereit zum Aufdecken!"
        }
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
    
    private func handleRevealAction() {
        if !isRevealVoteActive {
            guard !answersInOrder.isEmpty else { return }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                isRevealVoteActive = true
                selectedSuspects.removeAll()
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
            guard !selectedSuspects.isEmpty else { return }
            let evaluation = QuestionsVoteEvaluation(selected: selectedSuspects, imposters: engine.currentSpyIDs)
            revealEvaluation = evaluation
            lastRevealEvaluation = evaluation
            
            if !evaluation.incorrect.isEmpty {
                withAnimation(.easeInOut(duration: 0.5)) { revealShakeTrigger += 1 }
                engine.finishRound()
                appModel.fairnessState.advanceRound()
                return
            }
            
            foundRevealSpies.formUnion(evaluation.correct)
            if foundRevealSpies.count == engine.currentSpyIDs.count {
                let finalEval = QuestionsVoteEvaluation(selected: foundRevealSpies, imposters: engine.currentSpyIDs)
                revealEvaluation = finalEval
                lastRevealEvaluation = finalEval
                engine.finishRound()
                appModel.fairnessState.advanceRound()
                return
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                selectedSuspects.removeAll()
                revealEvaluation = nil
                isRevealVoteActive = true
            }
        } else {
            if lastRevealEvaluation == nil { lastRevealEvaluation = revealEvaluation }
            engine.finishRound()
            appModel.fairnessState.advanceRound()
            resetRevealState()
        }
    }
    
    // HIER DIE ANPASSUNG: Klick öffnet Liste
    private func handleRevealCardTap(playerID: UUID, selectionEnabled: Bool) {
        if selectionEnabled {
            guard isRevealVoteActive, revealEvaluation == nil else { return }
            if foundRevealSpies.contains(playerID) { return }
            
            if selectedSuspects.contains(playerID) {
                selectedSuspects.remove(playerID)
            } else {
                let limit = max(1, engine.currentSpyIDs.count - foundRevealSpies.count)
                if selectedSuspects.count < limit {
                    selectedSuspects.insert(playerID)
                } else if limit == 1 {
                    selectedSuspects.removeAll()
                    selectedSuspects.insert(playerID)
                }
            }
            return
        }
        
        // HIER: Keine Einschränkung mehr auf Spione. Jeder Klick toggelt die Listen-Ansicht.
        if showSpyDetailsList {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) { showSpyDetailsList = false }
            spyScrollTarget = nil
        } else {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.85)) { showSpyDetailsList = true }
            spyScrollTarget = playerID
        }
    }
    
    private func resetRevealState(clearLast: Bool = false) {
        isRevealVoteActive = false; selectedSuspects.removeAll(); revealEvaluation = nil; revealShakeTrigger = 0; showSpyDetailsList = false; spyScrollTarget = nil; foundRevealSpies.removeAll()
        if clearLast { lastRevealEvaluation = nil }
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
        
        let title = (evaluation?.citizensWon ?? false) ? "Bewohner haben gewonnen" : (evaluation != nil ? "Spione haben gewonnen" : "Runde beendet")
        let subtitle = (evaluation?.citizensWon ?? false) ? "Alle Lügner wurden enttarnt." : (evaluation != nil ? "Die Lügner bleiben im Verborgenen." : "Starte eine neue Runde.")
        
        let spyQuestionText = engine.round?.promptPair.spyQuestion ?? "Unbekannt"

        return ZStack(alignment: .bottom) {
            brandGradient.ignoresSafeArea()
            
            VStack(spacing: 24) {
                Spacer().frame(height: 80)
                
                VStack(spacing: 8) {
                    Text(title)
                        .font(.system(size: 28, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    Text(subtitle)
                        .font(.body)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
                
                VStack(spacing: 8) {
                    Text("Frage der Spione:")
                        .font(.caption.weight(.bold))
                        .textCase(.uppercase)
                        .foregroundStyle(.white.opacity(0.6))
                    
                    Text(spyQuestionText)
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
                                    
                                    Text(p.name)
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
        }
    }
}
