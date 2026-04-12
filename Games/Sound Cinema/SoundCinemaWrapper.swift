import SwiftUI

struct SoundCinemaWrapper: View {
    @StateObject private var viewModel = SoundCinemaViewModel()

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
    }
}
