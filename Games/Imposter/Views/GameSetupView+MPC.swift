import SwiftUI
import MultipeerConnectivity
import Foundation

extension GameSetupView {

    // MARK: - MPC Host Logic
    
    func startMPCGame() {
        guard gameSettings.gameMode == .classic else { return }
        Task { @MainActor in
            let didStart = await gameLogic.startMultiplayerGameAsHost()
            if didStart {
                self.route = .game
            }
        }
    }
    
    // MARK: - MPC Client Listener
    func setupMPCListeners(gameSettings: GameSettings, route: Binding<SetupRoute?>) {
        gameLogic.activateMPCHandler(gameSettings: gameSettings) { newRoute in
            route.wrappedValue = newRoute
        }
    }
}
