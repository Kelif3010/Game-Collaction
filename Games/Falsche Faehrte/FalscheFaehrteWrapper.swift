import SwiftUI

// MARK: - Einstiegspunkt für Falsche Fährte
// Erstellt das ViewModel und routet zwischen den Spielphasen

struct FalscheFaehrteWrapper: View {
    var partyContext: PartyGameLaunchContext? = nil

    @State private var viewModel = FFViewModel()

    var body: some View {
        ZStack {
            FFBackground()

            Group {
                switch viewModel.gamePhase {
                case .setup:
                    FFSetupView()
                case .bluffing:
                    FFBluffPhaseView()
                        .id("ff-bluff-\(viewModel.currentRoundIndex)")
                case .voting:
                    FFVotePhaseView()
                        .id("ff-vote-\(viewModel.currentRoundIndex)")
                case .reveal:
                    FFRevealPhaseView()
                        .id("ff-reveal-\(viewModel.currentRoundIndex)")
                case .gameOver:
                    FFGameOverView()
                }
            }
            .transition(.opacity.combined(with: .scale(scale: 0.97)))
        }
        .environment(viewModel)
        .animation(.easeInOut(duration: 0.3), value: viewModel.gamePhase)
        .preferredColorScheme(.dark)
        .onAppear {
            guard let names = partyContext?.playerNames, !names.isEmpty else { return }
            // Party-Spieler in die FF-Spielerliste vorladen.
            // addPlayer prüft Duplikate und das 8-Spieler-Limit automatisch.
            names.forEach { viewModel.addPlayer($0) }
        }
    }
}

// MARK: - Phasen-Enum (hier definiert, da Wrapper ihn als erstes braucht)
enum FFGamePhase: Equatable {
    case setup
    case bluffing
    case voting
    case reveal
    case gameOver
}
