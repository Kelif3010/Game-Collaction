import SwiftUI

// MARK: - Reveal-Phase: zwei Screens
// Screen 1: Antworten-Auflösung
// Screen 2: Punkte-Zwischenstand (Push-Transition)

struct FFRevealPhaseView: View {
    @Environment(FFViewModel.self) private var viewModel

    @State private var appeared       = false
    @State private var cardsVisible   = false
    @State private var nextEnabled    = false
    @State private var showScores     = false
    @State private var lightHaptic    = false
    @State private var mediumHaptic   = false

    private var round: FFRound? { viewModel.currentRound }

    private var orderedSubmissions: [FFSubmission] {
        guard let round else { return [] }
        return round.displayOrder.compactMap { id in round.submission(for: id) }
    }
    private var mpRevealSubmissions: [FFRevealSubmission] {
        viewModel.mpRevealData?.submissions ?? []
    }

    private var submissionCount: Int {
        viewModel.isMultiplayer
            ? mpRevealSubmissions.count
            : orderedSubmissions.count
    }

    private var isShowingScores: Bool {
        viewModel.isMultiplayer ? viewModel.isShowingRevealScores : showScores
    }

    var body: some View {
        ZStack {
            FFBackground()

            if isShowingScores {
                FFScoreInterludeView(onNext: {
                    viewModel.nextRound()
                })
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))
            } else {
                answersScreen
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading),
                        removal: .move(edge: .leading)
                    ))
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .sensoryFeedback(.impact(weight: .light), trigger: lightHaptic)
        .sensoryFeedback(.impact(weight: .medium), trigger: mediumHaptic)
        .animation(.spring(duration: 0.5, bounce: 0.1), value: isShowingScores)
        .onAppear {
            let isPreview = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
            if isPreview {
                appeared = true
                cardsVisible = true
                nextEnabled = true
                showScores = false
                return
            }
            
            appeared = false
            cardsVisible = false
            nextEnabled = false
            showScores = false
            withAnimation(.spring(duration: 0.5, bounce: 0.2).delay(0.05)) {
                appeared = true
            }
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(0.4))
                withAnimation { cardsVisible = true }
            }
            let enableDelay = 0.4 + Double(submissionCount) * 0.14 + 0.4
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(enableDelay))
                withAnimation(.snappy) { nextEnabled = true }
                lightHaptic.toggle()
            }
        }
    }

    // MARK: - Screen 1: Antworten
    private var answersScreen: some View {
        VStack(spacing: 0) {
            topBar
                .padding(.horizontal, 20)
                .padding(.top, 8)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    questionBanner
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 12)
                        .animation(.spring(duration: 0.5, bounce: 0.2).delay(0.05), value: appeared)

                    if cardsVisible {
                        answersSection
                    }

                    Color.clear.frame(height: 110)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }
        }
        .safeAreaInset(edge: .bottom) {
            revealNextButton
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
                .padding(.top, 12)
                .opacity(appeared ? 1 : 0)
        }
    }

    // MARK: - Top Bar
    private var topBar: some View {
        HStack {
            Button {
                lightHaptic.toggle()
                viewModel.returnToSetup()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white.opacity(0.55))
                    .frame(width: 30, height: 30)
                    .background(Circle().fill(Color.white.opacity(0.07)))
            }

            Spacer()

            VStack(spacing: 2) {
                Text("Runde \(viewModel.currentRoundNumber) / \(viewModel.totalRounds)")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                Text("AUFLÖSUNG")
                    .font(.system(size: 9, weight: .black, design: .monospaced))
                    .tracking(2.5)
                    .foregroundStyle(FFStyle.accentViolet)
            }

            Spacer()
            Color.clear.frame(width: 30, height: 30)
        }
        .frame(height: 44)
    }

    // MARK: - Fragen-Banner
    private var questionBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "questionmark.bubble.fill")
                .font(.system(size: 18))
                .foregroundStyle(FFStyle.primaryGradient)
                .frame(width: 28)

            Text(round?.question.localizedQuestion(languageCode: viewModel.languageCode) ?? "")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.85))
                .lineLimit(3)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(FFStyle.accentViolet.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(FFStyle.accentViolet.opacity(0.25), lineWidth: 1)
                )
        )
    }

    // MARK: - Antworten gestaffelt
    @ViewBuilder
    private var answersSection: some View {
        VStack(spacing: 10) {
            Text("WER HAT WEN VERARSCHT")
                .font(.system(size: 9, weight: .black, design: .monospaced))
                .tracking(2.5)
                .foregroundStyle(.white.opacity(0.25))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 4)

            if viewModel.isMultiplayer {
                // Host und Client nutzen beide mpRevealData
                ForEach(Array(mpRevealSubmissions.enumerated()), id: \.element.id) { idx, sub in
                    mpRevealCard(sub, index: idx)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .animation(.spring(duration: 0.5, bounce: 0.22).delay(Double(idx) * 0.14), value: cardsVisible)
                }
            } else {
                ForEach(Array(orderedSubmissions.enumerated()), id: \.element.id) { idx, sub in
                    revealCard(sub, index: idx)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .animation(.spring(duration: 0.5, bounce: 0.22).delay(Double(idx) * 0.14), value: cardsVisible)
                }
            }
        }
    }

    // MARK: - Karte Single/Host
    private func revealCard(_ submission: FFSubmission, index: Int) -> some View {
        let isAnswer = submission.isAnswer
        let voterNames = submission.voterIds.compactMap { id in
            viewModel.players.first(where: { $0.id == id })?.displayName
        }
        return revealCardContent(
            text: submission.text,
            authorLabel: isAnswer ? "Die echte Antwort" : "Lüge von \(submission.playerName)",
            isAnswer: isAnswer,
            index: index,
            voterNames: voterNames
        )
    }

    // MARK: - Karte MP-Client
    private func mpRevealCard(_ submission: FFRevealSubmission, index: Int) -> some View {
        revealCardContent(
            text: submission.text,
            authorLabel: submission.isAnswer ? "Die echte Antwort" : "Lüge von \(submission.authorName)",
            isAnswer: submission.isAnswer,
            index: index,
            voterNames: submission.voterNames
        )
    }

    // MARK: - Gemeinsame Karten-Logik
    private func revealCardContent(
        text: String,
        authorLabel: String,
        isAnswer: Bool,
        index: Int,
        voterNames: [String]
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(isAnswer ? Color.green.opacity(0.22) : Color.white.opacity(0.07))
                        .frame(width: 34, height: 34)
                    if isAnswer {
                        Image(systemName: "checkmark")
                            .font(.system(size: 13, weight: .black))
                            .foregroundStyle(Color.green)
                    } else {
                        Text(String(UnicodeScalar(65 + index)!))
                            .font(.system(size: 13, weight: .black, design: .rounded))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(text)
                        .font(.system(size: 15, weight: isAnswer ? .black : .semibold, design: .rounded))
                        .foregroundStyle(isAnswer ? Color.green : .white)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(authorLabel)
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .tracking(0.5)
                        .foregroundStyle(isAnswer ? Color.green.opacity(0.65) : .white.opacity(0.32))
                }

                Spacer(minLength: 0)

                if !voterNames.isEmpty {
                    VStack(spacing: 2) {
                        Text(isAnswer ? "+2" : "+\(voterNames.count)")
                            .font(.system(size: 14, weight: .black, design: .rounded))
                            .foregroundStyle(isAnswer ? Color.green : FFStyle.accentGold)
                        Text("×\(voterNames.count)")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundStyle(isAnswer ? Color.green.opacity(0.55) : FFStyle.accentGold.opacity(0.55))
                    }
                }
            }

            if !voterNames.isEmpty {
                FlowLayout(spacing: 5) {
                    ForEach(voterNames, id: \.self) { name in
                        let color: Color = isAnswer ? .green : FFStyle.accentGold
                        Text(name)
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(color.opacity(0.85))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule().fill(color.opacity(0.1))
                                    .overlay(Capsule().stroke(color.opacity(0.25), lineWidth: 1))
                            )
                    }
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(isAnswer ? Color.green.opacity(0.07) : Color.white.opacity(0.035))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(isAnswer ? Color.green.opacity(0.45) : Color.white.opacity(0.07),
                                lineWidth: isAnswer ? 1.5 : 1)
                )
        )
        .shadow(color: isAnswer ? Color.green.opacity(0.18) : .clear, radius: 16, y: 4)
    }

    // MARK: - Button: zu Screen 2 oder Warten
    @ViewBuilder
    private var revealNextButton: some View {
        if viewModel.isMultiplayer && !viewModel.isHost {
            HStack(spacing: 8) {
                ProgressView().tint(.white.opacity(0.4)).scaleEffect(0.75)
                Text("Warte auf den Host…")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.4))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
        } else {
            Button {
                mediumHaptic.toggle()
                if viewModel.isMultiplayer {
                    viewModel.showRevealScores()
                } else {
                    withAnimation(.spring(duration: 0.5, bounce: 0.1)) {
                        showScores = true
                    }
                }
            } label: {
                HStack(spacing: 10) {
                    Text("Punktestand")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 15, weight: .bold))
                }
                .foregroundStyle(nextEnabled ? .black : .white.opacity(0.25))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    Capsule()
                        .fill(nextEnabled
                              ? AnyShapeStyle(FFStyle.primaryGradient)
                              : AnyShapeStyle(Color.white.opacity(0.07)))
                        .shadow(color: nextEnabled ? FFStyle.accentViolet.opacity(0.5) : .clear, radius: 20, y: 6)
                )
            }
            .disabled(!nextEnabled)
            .animation(.snappy, value: nextEnabled)
        }
    }
}

// MARK: - Screen 2: Punkte-Zwischenstand
struct FFScoreInterludeView: View {
    @Environment(FFViewModel.self) private var viewModel
    let onNext: () -> Void

    @State private var appeared    = false
    @State private var rowsVisible = false
    @State private var mediumHaptic = false

    private var sorted: [FFPlayer] { viewModel.sortedPlayers }
    private var isLastRound: Bool { viewModel.isLastRound }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            header
                .padding(.horizontal, 20)
                .padding(.top, 8)

            Spacer(minLength: 16)

            // Leaderboard
            VStack(spacing: 8) {
                ForEach(Array(sorted.enumerated()), id: \.element.id) { idx, player in
                    scoreRow(player: player, rank: idx + 1)
                        .opacity(rowsVisible ? 1 : 0)
                        .offset(x: rowsVisible ? 0 : 40)
                        .animation(
                            .spring(duration: 0.45, bounce: 0.2)
                                .delay(Double(idx) * 0.08),
                            value: rowsVisible
                        )
                }
            }
            .padding(.horizontal, 20)

            Spacer()
        }
        .safeAreaInset(edge: .bottom) {
            nextButton
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
                .padding(.top, 12)
                .opacity(appeared ? 1 : 0)
        }
        .sensoryFeedback(.impact(weight: .medium), trigger: mediumHaptic)
        .onAppear {
            withAnimation(.spring(duration: 0.45, bounce: 0.2).delay(0.05)) {
                appeared = true
            }
            withAnimation(.spring(duration: 0.45, bounce: 0.2).delay(0.2)) {
                rowsVisible = true
            }
            mediumHaptic.toggle()
        }
    }

    // MARK: - Header
    private var header: some View {
        VStack(spacing: 6) {
            Text("RUNDE \(viewModel.currentRoundNumber) / \(viewModel.totalRounds)")
                .font(.system(size: 10, weight: .black, design: .monospaced))
                .tracking(3)
                .foregroundStyle(FFStyle.accentViolet)

            Text("Punktestand")
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
        .animation(.spring(duration: 0.5, bounce: 0.2).delay(0.05), value: appeared)
    }

    // MARK: - Zeile
    private func scoreRow(player: FFPlayer, rank: Int) -> some View {
        let isFirst = rank == 1
        let rowColor: Color = isFirst ? FFStyle.accentGold : FFStyle.accentViolet

        return HStack(spacing: 14) {
            // Rang
            ZStack {
                Circle()
                    .fill(rowColor.opacity(0.14))
                    .frame(width: 36, height: 36)
                if isFirst {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(FFStyle.accentGold)
                } else {
                    Text("\(rank)")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundStyle(rowColor.opacity(0.75))
                }
            }

            // Avatar
            ZStack {
                Circle()
                    .fill(rowColor.opacity(0.12))
                    .frame(width: 38, height: 38)
                Text(String(player.displayName.prefix(1).uppercased()))
                    .font(.system(size: 15, weight: .black))
                    .foregroundStyle(rowColor)
            }

            // Name + Mini-Stats
            VStack(alignment: .leading, spacing: 3) {
                Text(player.displayName)
                    .font(.system(size: 15, weight: isFirst ? .black : .bold, design: .rounded))
                    .foregroundStyle(isFirst ? .white : .white.opacity(0.8))

                HStack(spacing: 6) {
                    if player.truthScore > 0 {
                        Label("\(player.truthScore / 2)×", systemImage: "magnifyingglass")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(Color.green.opacity(0.7))
                    }
                    if player.bluffSuccesses > 0 {
                        Label("\(player.bluffSuccesses)×", systemImage: "theatermasks.fill")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(FFStyle.accentGold.opacity(0.7))
                    }
                }
            }

            Spacer()

            // Score
            HStack(alignment: .lastTextBaseline, spacing: 3) {
                Text("\(player.score)")
                    .font(.system(size: 26, weight: .black, design: .rounded))
                    .foregroundStyle(isFirst ? FFStyle.accentGold : .white)
                Text("Pkt")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white.opacity(0.3))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(isFirst
                      ? FFStyle.accentGold.opacity(0.08)
                      : Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(isFirst ? FFStyle.accentGold.opacity(0.3) : Color.white.opacity(0.06),
                                lineWidth: isFirst ? 1.5 : 1)
                )
        )
    }

    // MARK: - Next Button
    @ViewBuilder
    private var nextButton: some View {
        if viewModel.isMultiplayer && !viewModel.isHost {
            HStack(spacing: 8) {
                ProgressView().tint(.white.opacity(0.4)).scaleEffect(0.75)
                Text("Warte auf den Host…")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.4))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
        } else {
            Button {
                mediumHaptic.toggle()
                onNext()
            } label: {
                HStack(spacing: 10) {
                    Text(isLastRound ? "Endergebnis" : "Nächste Runde")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                    Image(systemName: isLastRound ? "trophy.fill" : "arrow.right")
                        .font(.system(size: 15, weight: .bold))
                }
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    Capsule()
                        .fill(FFStyle.primaryGradient)
                        .shadow(color: FFStyle.accentViolet.opacity(0.5), radius: 20, y: 6)
                )
            }
        }
    }
}

// MARK: - Flow Layout für Voter-Chips
private struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        var height: CGFloat = 0
        var x: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > width && x > 0 {
                height += rowHeight + spacing
                x = 0
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        height += rowHeight
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX && x > bounds.minX {
                y += rowHeight + spacing
                x = bounds.minX
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: .unspecified)
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

#Preview {
    FFRevealPhaseView()
        .environment(FFViewModel.preview)
}
