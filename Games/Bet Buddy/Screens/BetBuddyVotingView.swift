import SwiftUI

struct BetBuddyVotingView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appModel: AppViewModel

    var onClose: () -> Void
    var onConfirm: () -> Void

    @State private var didNavigateToGame = false

    // NEU: Berechnet, ob überhaupt schon Stimmen abgegeben wurden
    private var hasVotes: Bool {
        appModel.voteCounters.values.reduce(0, +) > 0
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                
                header
                    .padding(.bottom, 20)

                Spacer()

                VStack(spacing: 24) {
                    if appModel.currentChallenge.inputType == .alphabet {
                        LetterFlipView(
                            value: leadingScore,
                            color: leaderColor
                        )
                    } else {
                        FlipCounterView(
                            value: leadingScore,
                            color: leaderColor
                        )
                    }

                    questionText

                    voteGrid
                }

                Spacer()

                HoldToConfirmButton(
                    title: "Halten zum Bestätigen",
                    duration: 1.0,
                    action: {
                        appModel.lockVotes()
                    },
                    // FIX: Button ist deaktiviert, wenn gesperrt ODER keine Stimmen da sind
                    disabled: appModel.votesLocked || !hasVotes
                )
                .padding(.top, 20)
                .padding(.bottom, 10)
            }
            .padding(Theme.padding)
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            appModel.resetVotes()
            didNavigateToGame = false
        }
        .onChange(of: appModel.votesLocked) { _, locked in
            if locked && !didNavigateToGame {
                didNavigateToGame = true
                onConfirm()
            }
        }
    }
    
    private var header: some View {
        HStack {
            Color.clear.frame(width: 36, height: 36)
            Spacer()
            Text("Bet Buddy").foregroundStyle(.white).font(.headline)
            Spacer()
            Button {
                appModel.stopTimer()
                onClose()
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.headline.bold())
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private var questionText: some View {
        Text(appModel.currentChallenge.text)
            .foregroundStyle(.white)
            .font(.headline.weight(.semibold))
            .multilineTextAlignment(.center)
            .padding(.top, 8)
    }

    private var voteGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
            ForEach(appModel.activeGroups) { group in
                GroupVoteCard(
                    group: group,
                    onIncrement: { appModel.incrementVote(for: group) },
                    onDecrement: { appModel.decrementVote(for: group) },
                    locked: appModel.votesLocked,
                    isLeader: leaderGroup?.id == group.id,
                    showLeader: leadingScore > 0
                )
            }
        }
    }

    private var leaderGroup: GroupInfo? {
        let sorted = appModel.activeGroups.sorted { lhs, rhs in
            appModel.voteCounters[lhs.id, default: 0] > appModel.voteCounters[rhs.id, default: 0]
        }
        return sorted.first
    }

    private var leadingScore: Int {
        guard let leader = leaderGroup else { return 0 }
        return appModel.voteCounters[leader.id, default: 0]
    }

    private var leaderColor: Color {
        leaderGroup?.color.primary ?? .white
    }
}
