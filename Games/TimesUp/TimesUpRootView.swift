import SwiftUI

struct TimesUpRootView: View {
    @ObservedObject var categoryManager: CategoryManager
    
    var body: some View {
        MainMenuView(categoryManager: categoryManager)
    }
}

#Preview {
    // KORRIGIERT: Preview zeigt TimesUpRootView an, nicht ContentView mit falschen Parametern
    TimesUpRootView(categoryManager: CategoryManager())
}
