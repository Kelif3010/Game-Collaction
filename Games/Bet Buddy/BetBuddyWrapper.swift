import SwiftUI

struct BetBuddyWrapper: View {
    // 1. Hier erstellen wir das Herzstück (ViewModel)
    @StateObject private var gameModel = AppViewModel()

    var body: some View {
        // 2. Wir geben es direkt an die RootView weiter (Absturzsicher!)
        BetBuddyRootView(viewModel: gameModel)
    }
}
