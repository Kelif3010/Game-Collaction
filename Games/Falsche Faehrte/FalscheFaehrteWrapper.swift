import SwiftUI

// MARK: - Einstiegspunkt für Falsche Fährte
// Erstellt das ViewModel und routet zwischen den Spielphasen

struct FalscheFaehrteWrapper: View {
    @StateObject private var viewModel = FFViewModel()

    var body: some View {
        ZStack {
            FFBackground()

            Group {
                switch viewModel.gamePhase {
                case .setup:
                    FFSetupView()
                case .bluffing:
                    FFBluffPhaseView()
                case .voting:
                    FFVotePhaseView()
                case .reveal:
                    FFRevealPhaseView()
                case .gameOver:
                    FFGameOverView()
                }
            }
            .transition(.opacity.combined(with: .scale(scale: 0.97)))
        }
        .environmentObject(viewModel)
        .animation(.easeInOut(duration: 0.3), value: viewModel.gamePhase)
        .preferredColorScheme(.dark)
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
