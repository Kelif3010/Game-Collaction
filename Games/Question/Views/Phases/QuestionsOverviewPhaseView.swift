import SwiftUI

struct QuestionsOverviewPhaseView: View {
    @ObservedObject var viewModel: QuestionsGameViewModel
    @ObservedObject private var mpc = MultipeerManager.shared
    @AppStorage("question.hint.overview") private var overviewHintSeen = false
    
    private var revealGridColumns: [GridItem] {
        viewModel.showLiarDetailsList ? [GridItem(.flexible())] : [GridItem(.flexible()), GridItem(.flexible())]
    }
    
    var body: some View {
        ZStack {
            QuestionsBackgroundView(stressLevel: viewModel.isRevealVoteActive ? 0.7 : 0.5)
                .ignoresSafeArea()
            VStack(spacing: 20) {
                Color.clear.frame(height: 80)
                
                // Timer Display
                if viewModel.discussionTime > 0 {
                    HStack(spacing: 8) {
                        Image(systemName: "timer")
                        Text(viewModel.timeString(from: viewModel.timeRemaining))
                            .font(.system(.title3, design: .monospaced).weight(.bold))
                    }
                    .foregroundColor(viewModel.timeRemaining < 30 ? .red : .white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .scaleEffect(viewModel.timeRemaining < 10 && viewModel.timeRemaining > 0 && Int(viewModel.timeRemaining) % 2 == 0 ? 1.1 : 1.0)
                    .animation(.default, value: viewModel.timeRemaining)
                }
                
                if let round = viewModel.currentRound {
                    Text(LocalizedStringKey(round.promptPair.citizenQuestion))
                        .font(.title3.weight(.bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                
                if viewModel.answersInOrder.isEmpty {
                    Text("Es wurden noch keine Antworten erfasst.")
                        .font(.subheadline).foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center).padding(.horizontal, 24)
                    Spacer()
                } else {
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVGrid(columns: revealGridColumns, spacing: viewModel.showLiarDetailsList ? 18 : 12) {
                                ForEach(viewModel.answersInOrder, id: \.id) { answer in
                                    let playerID = answer.playerID
                                    let name = viewModel.playerName(for: playerID)
                                    let evaluation = viewModel.revealEvaluation
                                    
                                    // Voting Logic
                                    let voteCount = viewModel.voteCountForDisplay(playerID: playerID)
                                    let showSelectionBox = viewModel.isRevealVoteActive && evaluation == nil && !viewModel.foundRevealLiars.contains(playerID)
                                    
                                    let showGreenCheck = evaluation?.correct.contains(playerID) == true || viewModel.foundRevealLiars.contains(playerID)
                                    let revealRoundOver = evaluation.map { $0.citizensWon || !$0.incorrect.isEmpty } ?? false
                                    let liars = evaluation?.liars ?? viewModel.currentLiarIDs
                                    let highlightAsLiar = revealRoundOver && liars.contains(playerID)
                                    let isSlowest = answer.timeTaken > 0 && answer.timeTaken == viewModel.slowestTime
                                    
                                    QuestionsAnswerRevealCard(
                                        playerName: name,
                                        answer: answer,
                                        isSelected: voteCount > 0,
                                        showSelectionBox: showSelectionBox,
                                        selectionEnabled: showSelectionBox,
                                        showGreenCheck: showGreenCheck,
                                        showRedX: highlightAsLiar,
                                        shakeTrigger: highlightAsLiar ? viewModel.revealShakeTrigger : 0,
                                        isFullWidth: viewModel.showLiarDetailsList,
                                        liarQuestion: nil, // Always nil during overview
                                        isSlowest: isSlowest,
                                        voteCount: voteCount,
                                        canIncrement: viewModel.canIncrementVote(),
                                        onIncrement: { viewModel.incrementVote(for: playerID) },
                                        onDecrement: { viewModel.decrementVote(for: playerID) }
                                    ) { viewModel.handleRevealCardTap(playerID: playerID) }
                                    .id(playerID)
                                }
                            }
                            .padding(.horizontal, 20).padding(.top, 4)
                            Color.clear.frame(height: 140)
                        }
                        .frame(maxHeight: .infinity, alignment: .top)
                        .onChange(of: viewModel.liarScrollTarget) { oldValue, target in
                            guard let target else { return }
                            DispatchQueue.main.async {
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) { proxy.scrollTo(target, anchor: .top) }
                            }
                        }
                    }
                }
            }
            .padding(.bottom, viewModel.isRevealVoteActive ? 110 : 30)
            VStack { Spacer(); revealActionBar }
            if !overviewHintSeen {
                VStack {
                    QuestionsHintBanner(
                        text: "Vergleicht die Aussagen. Markiert dann eure Verdächtigen.",
                        actionTitle: "Verstanden",
                        onDismiss: { overviewHintSeen = true }
                    )
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                    Spacer()
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: overviewHintSeen)
    }
    
    private var revealActionBar: some View {
        let isHostOrLocal = mpc.role == .host || mpc.role == .unknown
        
        return Group {
            if !viewModel.answersInOrder.isEmpty || viewModel.isRevealVoteActive {
                VStack(spacing: 10) {
                    if let message = revealStatusMessage {
                        Text(message)
                            .font(.footnote)
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                    }
                    if isHostOrLocal {
                        Button(action: {
                            viewModel.handleRevealAction()
                            if mpc.role == .host {
                                viewModel.syncStateToAll()
                            }
                        }) {
                            Text(revealButtonTitle).font(.headline).frame(maxWidth: .infinity).padding(.vertical, 14)
                                .background(viewModel.canRevealNow ? Color.white.opacity(0.85) : Color.white.opacity(0.25))
                                .foregroundColor(viewModel.canRevealNow ? QuestionsTheme.textAccent : .white.opacity(0.8))
                                .cornerRadius(26)
                        }
                        .disabled(!viewModel.canRevealNow)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 18)
                .padding(.bottom, 24)
            }
        }
    }
    
    private var revealButtonTitle: LocalizedStringKey {
        if !viewModel.isRevealVoteActive { return "Lügner entlarven" }
        if viewModel.revealEvaluation == nil { return "Überprüfen" }
        return "Runde abschließen"
    }
    
    private var revealStatusMessage: LocalizedStringKey? {
        if !viewModel.isRevealVoteActive { return !viewModel.answersInOrder.isEmpty ? "Analysiert die Aussagen und markiert Verdächtige." : nil }
        if let evaluation = viewModel.revealEvaluation {
            if evaluation.citizensWon { return "Lüge identifiziert! Der Lügner wurde überführt." }
            if !evaluation.incorrect.isEmpty { return "Falscher Verdacht! Der Lügner bleibt unentdeckt." }
            return "Teilerfolg – es gibt noch weitere Lügner."
        }
        if viewModel.currentLiarIDs.isEmpty { return "Keine Abweichungen in dieser Runde." }
        
        // Voting Phase Status
        if viewModel.currentTotalVotes < viewModel.maxVotes {
            let remaining = viewModel.maxVotes - viewModel.currentTotalVotes
            return "Vergebt noch \(remaining) Stimmen (\(viewModel.currentTotalVotes)/\(viewModel.maxVotes))."
        }
        
        let leadingIDs = viewModel.currentLeaders
        if leadingIDs.isEmpty {
            return "Bereit zum Aufdecken."
        } else if leadingIDs.count == 1, let leaderID = leadingIDs.first {
             let name = viewModel.playerName(for: leaderID)
             return "Hauptverdächtiger: \(name)"
        } else {
            return "Gleichstand zwischen \(leadingIDs.count) Spielern."
        }
    }
}
