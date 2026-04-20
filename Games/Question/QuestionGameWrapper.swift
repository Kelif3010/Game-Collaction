import SwiftUI

struct QuestionGameWrapper: View {
    var partyContext: PartyGameLaunchContext? = nil

    @StateObject private var appModel = AppModel()

    var body: some View {
        QuestionsModeContainer(appModel: appModel)
            .onAppear {
                guard let names = partyContext?.playerNames, !names.isEmpty else { return }
                // Party-Spieler vorladen – ersetzt gespeicherte Spieler.
                appModel.players = names.map { QuestionPlayer(name: $0) }
            }
    }
}
