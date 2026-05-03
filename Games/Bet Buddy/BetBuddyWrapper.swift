import SwiftUI

struct BetBuddyWrapper: View {
    @State private var gameModel = AppViewModel()

    var body: some View {
        BetBuddyRootView(viewModel: gameModel)
    }
}
