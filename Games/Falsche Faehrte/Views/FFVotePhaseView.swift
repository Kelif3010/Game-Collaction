import SwiftUI

// MARK: - Vote-Phase: Alle wählen gleichzeitig (oder reihum) was die Wahrheit ist
struct FFVotePhaseView: View {
    @Environment(FFViewModel.self) private var viewModel

    @State private var appeared = false
    @State private var currentVoterIndex = 0
    @State private var selectedSubmissionId: UUID? = nil
    @State private var showVoterTransition = false
    @State private var lightHaptic = false
    @State private var mediumHaptic = false

    // Multiplayer-State
    @State private var mpSelectedId: String? = nil

    private var round: FFRound? { viewModel.currentRound }
    private var currentVoter: FFPlayer? {
        guard currentVoterIndex < viewModel.players.count else { return nil }
        return viewModel.players[currentVoterIndex]
    }

    private var orderedSubmissions: [FFSubmission] {
        guard let round else { return [] }
        return round.displayOrder.compactMap { id in round.submission(for: id) }
    }

    private var allVoted: Bool { currentVoterIndex >= viewModel.players.count }

    var body: some View {
        ZStack {
            FFBackground()

            if viewModel.isMultiplayer && viewModel.hasVoted {
                // Multiplayer: Warte-Bildschirm nach Vote
                mpVoteWaitingView
            } else if showVoterTransition {
                voterTransitionOverlay
            } else {
                VStack(spacing: 0) {
                    voteHeader
                        .padding(.horizontal, 20)
                        .padding(.top, 12)

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 20) {
                            questionBanner
                                .opacity(appeared ? 1 : 0)
                                .offset(y: appeared ? 0 : 16)

                            if !viewModel.isMultiplayer {
                                voterBadge
                                    .opacity(appeared ? 1 : 0)
                                    .offset(y: appeared ? 0 : 12)
                            }

                            if viewModel.isMultiplayer {
                                mpAnswersStack
                                    .opacity(appeared ? 1 : 0)
                                    .offset(y: appeared ? 0 : 16)
                            } else {
                                answersStack
                                    .opacity(appeared ? 1 : 0)
                                    .offset(y: appeared ? 0 : 16)
                            }

                            Color.clear.frame(height: 110)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    }
                }

                // Floating Confirm-Button
                VStack {
                    Spacer()
                    if viewModel.isMultiplayer {
                        mpConfirmButton
                            .padding(.bottom, 36)
                            .opacity(appeared ? 1 : 0)
                    } else {
                        confirmButton
                            .padding(.bottom, 36)
                            .opacity(appeared ? 1 : 0)
                    }
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .sensoryFeedback(.impact(weight: .light), trigger: lightHaptic)
        .sensoryFeedback(.impact(weight: .medium), trigger: mediumHaptic)
        .onAppear {
            currentVoterIndex = 0
            selectedSubmissionId = nil
            mpSelectedId = nil
            withAnimation(.spring(duration: 0.5, bounce: 0.15).delay(0.05)) {
                appeared = true
            }
        }
    }

    // MARK: - Header
    private var voteHeader: some View {
        HStack {
            Button {
                lightHaptic.toggle()
                viewModel.returnToSetup()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(.ultraThinMaterial))
            }

            Spacer()

            VStack(spacing: 2) {
                Text("Runde \(viewModel.currentRoundNumber) / \(viewModel.totalRounds)")
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                Text("Abstimmung")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(FFStyle.textMuted)
            }

            Spacer()
            Circle().fill(Color.clear).frame(width: 36, height: 36)
        }
    }

    // MARK: - Fragen-Banner (kompakt)
    private var questionBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "questionmark.bubble.fill")
                .font(.system(size: 22))
                .foregroundStyle(FFStyle.primaryGradient)

            Text(round?.question.localizedQuestion(languageCode: viewModel.languageCode) ?? "")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .lineLimit(3)
                .lineSpacing(2)

            Spacer()
        }
        .padding(14)
        .ffCard(isPrimary: true)
    }

    // MARK: - Aktueller Wähler
    private var voterBadge: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(FFStyle.accentViolet.opacity(0.2))
                    .frame(width: 40, height: 40)
                Text(String(currentVoter?.displayName.prefix(1).uppercased() ?? "?"))
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(FFStyle.accentViolet)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(currentVoter?.displayName ?? "")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                Text("Welche Antwort ist die Wahrheit?")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(FFStyle.textMuted)
            }

            Spacer()

            Text("\(currentVoterIndex + 1)/\(viewModel.players.count)")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundStyle(FFStyle.textMuted)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Capsule().fill(Color.white.opacity(0.08)))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .ffCard()
    }

    // MARK: - Antworten (Single-Device)
    private var answersStack: some View {
        VStack(spacing: 10) {
            ForEach(Array(orderedSubmissions.enumerated()), id: \.element.id) { idx, submission in
                FFVoteAnswerCard(
                    index: idx,
                    text: submission.text,
                    isSelected: selectedSubmissionId == submission.id,
                    isOwnEntry: submission.playerId == currentVoter?.id
                ) {
                    lightHaptic.toggle()
                    withAnimation(.snappy) {
                        selectedSubmissionId = selectedSubmissionId == submission.id ? nil : submission.id
                    }
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : CGFloat(idx * 8))
                .animation(.spring(duration: 0.45, bounce: 0.15).delay(Double(idx) * 0.06), value: appeared)
                .accessibilityLabel("Antwort \(String(UnicodeScalar(65 + idx)!)): \(submission.text)")
                .accessibilityAddTraits(selectedSubmissionId == submission.id ? .isSelected : [])
            }
        }
    }

    // MARK: - Bestätigen-Button
    private var confirmButton: some View {
        let hasVoted = selectedSubmissionId != nil

        return Button {
            guard hasVoted, let voteId = selectedSubmissionId,
                  let voter = currentVoter else { return }
            mediumHaptic.toggle()

            viewModel.castVote(voterId: voter.id, forSubmissionId: voteId)

            let nextIdx = currentVoterIndex + 1
            if nextIdx >= viewModel.players.count {
                // Alle haben abgestimmt → Auflösung
                viewModel.proceedToReveal()
            } else {
                // Nächster Spieler → kurze Übergangs-Animation
                withAnimation(.easeInOut(duration: 0.2)) {
                    showVoterTransition = true
                }
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(1.2))
                    currentVoterIndex = nextIdx
                    selectedSubmissionId = nil
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showVoterTransition = false
                    }
                }
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: hasVoted ? "checkmark.circle.fill" : "circle.dashed")
                    .font(.system(size: 16, weight: .bold))
                Text(hasVoted ? "Stimme abgeben" : "Bitte wählen…")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
            }
            .foregroundStyle(hasVoted ? .black : .white.opacity(0.4))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                Capsule()
                    .fill(hasVoted
                          ? AnyShapeStyle(FFStyle.primaryGradient)
                          : AnyShapeStyle(Color.white.opacity(0.08)))
                    .shadow(color: hasVoted ? FFStyle.accentViolet.opacity(0.5) : .clear, radius: 16, y: 6)
            )
        }
        .disabled(!hasVoted)
        .animation(.snappy, value: hasVoted)
        .padding(.horizontal, 24)
    }

    // MARK: - Multiplayer: Antworten-Liste (anonyme Submissions vom Host)

    private var mpAnswersStack: some View {
        VStack(spacing: 10) {
            Text("WELCHE IST DIE WAHRHEIT?")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(FFStyle.textMuted)
                .tracking(1.5)
                .frame(maxWidth: .infinity, alignment: .leading)

            ForEach(Array(viewModel.mpSubmissions.enumerated()), id: \.element.id) { idx, submission in
                let isOwnBluff = submission.text == viewModel.myBluffText
                FFVoteAnswerCard(
                    index: idx,
                    text: submission.text,
                    isSelected: mpSelectedId == submission.id,
                    isOwnEntry: isOwnBluff
                ) {
                    lightHaptic.toggle()
                    withAnimation(.snappy) {
                        mpSelectedId = mpSelectedId == submission.id ? nil : submission.id
                    }
                }
                .opacity(isOwnBluff ? 0.4 : (appeared ? 1 : 0))
                .offset(y: appeared ? 0 : CGFloat(idx * 8))
                .animation(.spring(duration: 0.45, bounce: 0.15).delay(Double(idx) * 0.06), value: appeared)
                .accessibilityLabel("Antwort \(String(UnicodeScalar(65 + idx)!)): \(submission.text)")
                .accessibilityAddTraits(mpSelectedId == submission.id ? .isSelected : [])
            }
        }
    }

    // MARK: - Multiplayer: Vote-Button

    private var mpConfirmButton: some View {
        let hasVoted = mpSelectedId != nil

        return Button {
            guard hasVoted, let id = mpSelectedId else { return }
            mediumHaptic.toggle()
            viewModel.castVoteMultiplayer(submissionId: id)
        } label: {
            HStack(spacing: 10) {
                Image(systemName: hasVoted ? "checkmark.circle.fill" : "circle.dashed")
                    .font(.system(size: 16, weight: .bold))
                Text(hasVoted ? "Stimme abgeben" : "Bitte wählen…")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
            }
            .foregroundStyle(hasVoted ? .black : .white.opacity(0.4))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                Capsule()
                    .fill(hasVoted
                          ? AnyShapeStyle(FFStyle.primaryGradient)
                          : AnyShapeStyle(Color.white.opacity(0.08)))
                    .shadow(color: hasVoted ? FFStyle.accentViolet.opacity(0.5) : .clear, radius: 16, y: 6)
            )
        }
        .disabled(!hasVoted)
        .animation(.snappy, value: hasVoted)
        .padding(.horizontal, 24)
    }

    // MARK: - Multiplayer: Warte-Bildschirm nach Vote

    private var mpVoteWaitingView: some View {
        let voted = viewModel.voteCount
        let total = viewModel.totalMultiplayerPlayers

        return VStack(spacing: 28) {
            Spacer()

            ZStack {
                Circle()
                    .fill(FFStyle.accentViolet.opacity(0.12))
                    .frame(width: 90, height: 90)
                Image(systemName: "checkmark.bubble.fill")
                    .font(.system(size: 38))
                    .foregroundStyle(FFStyle.primaryGradient)
            }

            VStack(spacing: 8) {
                Text("Stimme abgegeben!")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                Text("Warte auf die Auflösung...")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(FFStyle.textMuted)
            }

            VStack(spacing: 10) {
                Text("\(voted) / \(total)")
                    .font(.system(size: 32, weight: .heavy, design: .monospaced))
                    .foregroundStyle(FFStyle.accentViolet)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.08))
                            .frame(height: 6)
                        Capsule()
                            .fill(FFStyle.primaryGradient)
                            .frame(width: total > 0 ? geo.size.width * CGFloat(voted) / CGFloat(total) : 0, height: 6)
                            .animation(.smooth(duration: 0.5), value: voted)
                    }
                }
                .frame(height: 6)
                .padding(.horizontal, 40)

                Text("haben abgestimmt")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(FFStyle.textSubtle)
            }
            .padding(20)
            .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 18))
            .padding(.horizontal, 40)

            Spacer()
        }
    }

    // MARK: - Wähler-Übergabe Overlay
    private var voterTransitionOverlay: some View {
        let nextIdx = currentVoterIndex + 1
        let nextPlayer = nextIdx < viewModel.players.count ? viewModel.players[nextIdx] : nil

        return ZStack {
            Color.black.opacity(0.85).ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(FFStyle.primaryGradient)

                Text("Gerät weitergeben an")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(FFStyle.textMuted)

                Text(nextPlayer?.displayName ?? "")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                Text("Schirm abdecken, bis du dran bist!")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(FFStyle.textSubtle)
                    .multilineTextAlignment(.center)
            }
            .padding(32)
        }
        .transition(.opacity)
    }
}

// MARK: - Wiederverwendbare Antwort-Karte (Single-Device + Multiplayer)
private struct FFVoteAnswerCard: View {
    let index: Int
    let text: String
    let isSelected: Bool
    let isOwnEntry: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(isSelected ? FFStyle.accentViolet.opacity(0.25) : Color.white.opacity(0.08))
                        .frame(width: 36, height: 36)
                    Text(String(UnicodeScalar(65 + index)!))
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .foregroundStyle(isSelected ? FFStyle.accentViolet : FFStyle.textMuted)
                }

                Text(text)
                    .font(.system(size: 15, weight: isSelected ? .bold : .semibold))
                    .foregroundStyle(isSelected ? .white : Color.white.opacity(0.85))
                    .lineLimit(3)
                    .lineSpacing(2)

                Spacer()

                if isOwnEntry {
                    Image(systemName: "hand.raised.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(FFStyle.textSubtle)
                } else if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(FFStyle.accentViolet)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isSelected ? FFStyle.accentViolet.opacity(0.1) : Color.white.opacity(0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(
                        isSelected ? FFStyle.accentViolet.opacity(0.55) : Color.white.opacity(0.07),
                        lineWidth: isSelected ? 1.5 : 1
                    )
            )
        }
        .disabled(isOwnEntry)
    }
}

#Preview {
    FFVotePhaseView()
        .environment(FFViewModel.preview)
}
