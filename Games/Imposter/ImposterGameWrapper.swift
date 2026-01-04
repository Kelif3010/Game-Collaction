import SwiftUI

struct ImposterGameWrapper: View {
    @StateObject private var gameSettings = GameSettings()
    
    var body: some View {
        GameSetupView()
            .environmentObject(gameSettings)
    }
}