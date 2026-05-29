import SwiftUI

struct TimesUpGameView: View {
    @ObservedObject var viewModel: TimesUpGameViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingEndGame = false
    
    var body: some View {
        NavigationStack {
            VStack {
                switch viewModel.gameState.phase {
                case .setup:
                    SetupPhaseView(viewModel: viewModel)
                case .playing:
                    // Runde 4 = Zeichnen, andere Runden = normale Spielansicht
                    if viewModel.gameState.currentRound == .round4 {
                        DrawingView(viewModel: viewModel)
                    } else {
                        PlayingPhaseView(viewModel: viewModel)
                    }
                case .slotReward:
                    if let rewardTeam = viewModel.slotRewardTeam() {
                        SlotRewardFullView(viewModel: viewModel, team: rewardTeam)
                    } else {
                        SetupPhaseView(viewModel: viewModel)
                    }
                case .roundEnd:
                    RoundEndView(viewModel: viewModel)
                case .gameEnd:
                    GameEndView(viewModel: viewModel)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: showEndGameConfirmation) {
                        Image(systemName: "xmark")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(
                                Circle()
                                    .fill(Color.black.opacity(0.35))
                            )
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
                            )
                    }
                    .accessibilityLabel("Spiel beenden")
                }
            }
            .alert("Spiel beenden?", isPresented: $showingEndGame) {
                Button("Abbrechen", role: .cancel) { }
                Button("Beenden", role: .destructive, action: endGame)
            } message: {
                Text("Möchtest du das aktuelle Spiel wirklich beenden?")
            }
        }
        .onDisappear {
            viewModel.cleanup()
        }
        .overlay(alignment: .topTrailing) {
            if !viewModel.scoreBursts.isEmpty {
                ScoreBurstBar(viewModel: viewModel)
                    .padding(.top, 64)
                    .padding(.trailing, 8)
                    .clipped()
            }
        }
    }

    private func showEndGameConfirmation() {
        showingEndGame = true
    }

    private func endGame() {
        viewModel.cleanup()
        dismiss()
    }
}

#Preview {
    @Previewable @State var viewModel = TimesUpGameViewModel()
    
    // Teams für Preview hinzufügen
    viewModel.gameState.settings.teams = [
        Team(name: "Ken"),
        Team(name: "Elif")
    ]
    
    return TimesUpGameView(viewModel: viewModel)
}
