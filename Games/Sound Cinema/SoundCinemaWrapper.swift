import SwiftUI

struct SoundCinemaWrapper: View {
    var partyContext: PartyGameLaunchContext? = nil

    @StateObject private var viewModel = SoundCinemaViewModel()
    @State private var configured = false

    var body: some View {
        Group {
            switch viewModel.phase {
            case .setup:
                SoundCinemaSetupView()
            case .playing, .voting, .eliminated:
                SoundCinemaGameView()
            case .gameOver:
                SoundCinemaGameOverView()
            }
        }
        .environmentObject(viewModel)
        .onAppear {
            guard !configured,
                  let names = partyContext?.playerNames,
                  names.count >= 2 else { return }
            configured = true
            // Im Party-Modus Setup überspringen und direkt starten.
            // Standard-Einstellungen werden verwendet (Party-Pack, 8s Timer, 3 Leben).
            viewModel.configure(with: SoundCinemaSettings(playerNames: names))
        }
    }
}
