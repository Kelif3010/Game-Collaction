import SwiftUI

struct QuestionsOverviewPhaseView: View {
    @ObservedObject var viewModel: QuestionsGameViewModel
    @Environment(MultipeerManager.self) private var mpc
    @AppStorage("question.hint.overview") private var overviewHintSeen = false

    private var revealGridColumns: [GridItem] {
        viewModel.showLiarDetailsList
            ? [GridItem(.flexible())]
            : [GridItem(.flexible()), GridItem(.flexible())]
    }

    var body: some View {
        ZStack {
            QuestionsBackgroundView(stressLevel: viewModel.isRevealVoteActive ? 0.7 : 0.5)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Color.clear.frame(height: 80)

                // Timer Display
                if viewModel.discussionTime > 0 {
                    timerDisplay
                }

                // Question
                if let round = viewModel.currentRound {
                    questionDisplay(round.promptPair.citizenQuestion)
                }

                // Answers Grid
                if viewModel.answersInOrder.isEmpty {
                    emptyStateView
                } else {
                    answersScrollView
                }
            }
            .padding(.bottom, viewModel.isRevealVoteActive ? 110 : 30)

            // Action Bar
            VStack {
                Spacer()
                revealActionBar
            }

            // Hint Banner
            if !overviewHintSeen {
                hintBanner
            }
        }
        .animation(.easeInOut(duration: 0.2), value: overviewHintSeen)
    }

    // MARK: - Timer Display

    private var timerDisplay: some View {
        HStack(spacing: 12) {
            // Status LED
            Circle()
                .fill(timerLEDColor)
                .frame(width: 8, height: 8)
                .shadow(color: timerLEDColor, radius: 4)

            Text("VERBLEIBEND:")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(QuestionsTheme.textMuted)
                .tracking(2)

            Text(viewModel.timeString(from: viewModel.timeRemaining))
                .font(.system(size: 20, weight: .bold, design: .monospaced))
                .foregroundStyle(timerTextColor)
                .monospacedDigit()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(timerBackground)
        .scaleEffect(viewModel.timeRemaining < 10 && viewModel.timeRemaining > 0 && Int(viewModel.timeRemaining) % 2 == 0 ? 1.05 : 1.0)
        .animation(.easeOut(duration: 0.1), value: viewModel.timeRemaining)
    }

    private var timerLEDColor: Color {
        if viewModel.timeRemaining < 10 {
            return QuestionsTheme.accentDanger
        } else if viewModel.timeRemaining < 30 {
            return QuestionsTheme.accentAmber
        } else {
            return QuestionsTheme.accentGreen
        }
    }

    private var timerTextColor: Color {
        viewModel.timeRemaining < 30 ? QuestionsTheme.accentDanger : QuestionsTheme.textPrimary
    }

    private var timerBackground: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.black.opacity(0.6))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(timerLEDColor.opacity(0.3), lineWidth: 1)
            )
    }

    // MARK: - Question Display

    private func questionDisplay(_ question: String) -> some View {
        VStack(spacing: 8) {
            Text("AKTIVE ABFRAGE")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(QuestionsTheme.accentGreen)
                .tracking(2)

            Text(LocalizedStringKey(question))
                .font(.system(.title3, design: .monospaced).weight(.bold))
                .foregroundStyle(QuestionsTheme.textTypewriter)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 40))
                .foregroundStyle(QuestionsTheme.textMuted)

            Text("KEINE DATEN ERFASST")
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(QuestionsTheme.textMuted)
                .tracking(2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Answers Grid

    private var answersScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVGrid(columns: revealGridColumns, spacing: viewModel.showLiarDetailsList ? 18 : 12) {
                    ForEach(viewModel.answersInOrder, id: \.id) { answer in
                        answerCard(for: answer)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 4)

                Color.clear.frame(height: 140)
            }
            .frame(maxHeight: .infinity, alignment: .top)
            .onChange(of: viewModel.liarScrollTarget) { oldValue, target in
                guard let target else { return }
                DispatchQueue.main.async {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                        proxy.scrollTo(target, anchor: .top)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func answerCard(for answer: QuestionsAnswer) -> some View {
        let playerID = answer.playerID
        let name = viewModel.playerName(for: playerID)
        let evaluation = viewModel.revealEvaluation

        let voteCount = viewModel.voteCountForDisplay(playerID: playerID)
        let showSelectionBox = viewModel.isRevealVoteActive
            && evaluation == nil
            && !viewModel.foundRevealLiars.contains(playerID)

        let showGreenCheck = evaluation?.correct.contains(playerID) == true
            || viewModel.foundRevealLiars.contains(playerID)
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
            liarQuestion: nil,
            isSlowest: isSlowest,
            voteCount: voteCount,
            canIncrement: viewModel.canIncrementVote(),
            onIncrement: { viewModel.incrementVote(for: playerID) },
            onDecrement: { viewModel.decrementVote(for: playerID) }
        ) {
            viewModel.handleRevealCardTap(playerID: playerID)
        }
        .id(playerID)
    }

    // MARK: - Reveal Action Bar

    @ViewBuilder
    private var revealActionBar: some View {
        let isHostOrLocal = mpc.role == .host || mpc.role == .unknown

        if !viewModel.answersInOrder.isEmpty || viewModel.isRevealVoteActive {
            VStack(spacing: 12) {
                // Status Message
                if let message = revealStatusMessage {
                    statusMessageView(message)
                }

                // Action Button (Host only)
                if isHostOrLocal {
                    actionButton
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 18)
            .padding(.bottom, 24)
        }
    }

    private func statusMessageView(_ message: LocalizedStringKey) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(statusLEDColor)
                .frame(width: 6, height: 6)
                .shadow(color: statusLEDColor.opacity(0.5), radius: 3)

            Text(message)
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(QuestionsTheme.textPrimary.opacity(0.9))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    private var statusLEDColor: Color {
        if let evaluation = viewModel.revealEvaluation {
            return evaluation.citizensWon ? QuestionsTheme.accentGreen : QuestionsTheme.accentDanger
        }
        return QuestionsTheme.accentAmber
    }

    private var actionButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            viewModel.handleRevealAction()
            if mpc.role == .host {
                viewModel.syncStateToAll()
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: actionButtonIcon)
                Text(revealButtonTitle)
            }
            .font(.system(.headline, design: .monospaced).weight(.semibold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .foregroundStyle(viewModel.canRevealNow ? QuestionsTheme.textOnDark : QuestionsTheme.textMuted)
            .background(actionButtonBackground)
            .clipShape(Capsule())
            .shadow(
                color: viewModel.canRevealNow ? QuestionsTheme.accentGreen.opacity(0.3) : .clear,
                radius: 10,
                y: 4
            )
        }
        .disabled(!viewModel.canRevealNow)
    }

    private var actionButtonIcon: String {
        if !viewModel.isRevealVoteActive {
            return "eye.fill"
        } else if viewModel.revealEvaluation == nil {
            return "checkmark.shield.fill"
        } else {
            return "arrow.right.circle.fill"
        }
    }

    @ViewBuilder
    private var actionButtonBackground: some View {
        if viewModel.canRevealNow {
            QuestionsStyle.buttonGradient
        } else {
            Color.white.opacity(0.1)
        }
    }

    private var revealButtonTitle: LocalizedStringKey {
        if !viewModel.isRevealVoteActive {
            return "VERHÖR STARTEN"
        } else if viewModel.revealEvaluation == nil {
            return "AUSWERTUNG"
        } else {
            return "ABSCHLIESSEN"
        }
    }

    private var revealStatusMessage: LocalizedStringKey? {
        if !viewModel.isRevealVoteActive {
            return !viewModel.answersInOrder.isEmpty ? "ABGLEICH AUSSTEHEND - VERDÄCHTIGE MARKIEREN" : nil
        }

        if let evaluation = viewModel.revealEvaluation {
            if evaluation.citizensWon {
                return "LÜGE VERIFIZIERT - SUBJEKT ÜBERFÜHRT"
            }
            if !evaluation.incorrect.isEmpty {
                return "FEHLIDENTIFIKATION - LÜGNER AKTIV"
            }
            return "TEILERFOLG - WEITERE LÜGNER VORHANDEN"
        }

        if viewModel.currentLiarIDs.isEmpty {
            return "KEINE ABWEICHUNGEN DETEKTIERT"
        }

        // Voting Phase Status
        if viewModel.currentTotalVotes < viewModel.maxVotes {
            let remaining = viewModel.maxVotes - viewModel.currentTotalVotes
            return "STIMMEN AUSSTEHEND: \(remaining) (\(viewModel.currentTotalVotes)/\(viewModel.maxVotes))"
        }

        let leadingIDs = viewModel.currentLeaders
        if leadingIDs.isEmpty {
            return "BEREIT ZUR AUSWERTUNG"
        } else if leadingIDs.count == 1, let leaderID = leadingIDs.first {
            let name = viewModel.playerName(for: leaderID)
            return "HAUPTVERDÄCHTIGER: \(name)"
        } else {
            return "STIMMENGLEICHSTAND: \(leadingIDs.count) SUBJEKTE"
        }
    }

    // MARK: - Hint Banner

    private var hintBanner: some View {
        VStack {
            systemHintView
            Spacer()
        }
        .transition(.opacity)
    }

    private var systemHintView: some View {
        HStack(spacing: 12) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 16))
                .foregroundStyle(QuestionsTheme.accentGreen)

            Text("PROTOKOLL: Aussagen vergleichen. Verdächtige markieren.")
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(QuestionsTheme.textPrimary)

            Spacer()

            Button {
                UISelectionFeedbackGenerator().selectionChanged()
                overviewHintSeen = true
            } label: {
                Text("OK")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(QuestionsTheme.accentGreen)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .stroke(QuestionsTheme.accentGreen.opacity(0.5), lineWidth: 1)
                    )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(QuestionsTheme.accentGreen.opacity(0.2), lineWidth: 1)
                )
        )
        .padding(.horizontal, 24)
        .padding(.top, 8)
    }
}
