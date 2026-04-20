import SwiftUI

struct ImposterGameWrapper: View {
    var partyContext: PartyGameLaunchContext? = nil

    @StateObject private var gameSettings = GameSettings()

    var body: some View {
        GameSetupView()
            .environmentObject(gameSettings)
            .onAppear {
                guard let names = partyContext?.playerNames, !names.isEmpty else { return }
                // Party-Spieler vorladen – überschreibt gespeicherte Spieler,
                // ohne sie in UserDefaults zu persistieren (savePlayers() nicht aufgerufen).
                gameSettings.players = names.map { Player(name: $0) }
            }
    }
}
