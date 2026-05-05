import SwiftUI

struct TimesUpGameView: View {
    @ObservedObject var gameManager: GameManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingEndGame = false
    
    var body: some View {
        NavigationStack {
            VStack {
                switch gameManager.gameState.phase {
                case .setup:
                    SetupPhaseView(gameManager: gameManager)
                case .playing:
                    // Runde 4 = Zeichnen, andere Runden = normale Spielansicht
                    if gameManager.gameState.currentRound == .round4 {
                        DrawingView(gameManager: gameManager)
                    } else {
                        PlayingPhaseView(gameManager: gameManager)
                    }
                case .slotReward:
                    if let rewardTeam = gameManager.slotRewardTeam() {
                        SlotRewardFullView(gameManager: gameManager, team: rewardTeam)
                    } else {
                        SetupPhaseView(gameManager: gameManager)
                    }
                case .roundEnd:
                    RoundEndView(gameManager: gameManager)
                case .gameEnd:
                    GameEndView(gameManager: gameManager)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Beenden", action: showEndGameConfirmation)
                    .foregroundStyle(.red)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    TeamBadgeBar(gameManager: gameManager)
                }
                
                ToolbarItem(placement: .principal) {
                    Text(gameManager.gameState.currentRound.shortDescription)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
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
            gameManager.cleanup()
        }
        .overlay(alignment: .topTrailing) {
            if !gameManager.scoreBursts.isEmpty {
                ScoreBurstBar(gameManager: gameManager)
                    .padding(.top, 64)
                    .padding(.trailing, 8)
                    .clipped()
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private func showEndGameConfirmation() {
        showingEndGame = true
    }

    private func endGame() {
        gameManager.cleanup()
        dismiss()
    }
}

#Preview {
    @Previewable @State var gameManager = GameManager()
    
    // Teams für Preview hinzufügen
    gameManager.gameState.settings.teams = [
        Team(name: "Ken"),
        Team(name: "Elif")
    ]
    
    return TimesUpGameView(gameManager: gameManager)
}
