import SwiftUI

extension GameSetupView {
    var canStartGame: Bool {
        return gameSettings.players.count >= 4 && gameSettings.hasSelectedCategories && gameSettings.numberOfImposters < gameSettings.players.count
    }

    var startButtonHintText: String {
        var missingItems: [String] = []
        let minPlayers = 4
        if gameSettings.players.count < minPlayers {
            let needed = minPlayers - gameSettings.players.count
            missingItems.append("Noch \(needed) Spieler benötigt")
        }
        
        if !gameSettings.hasSelectedCategories {
            missingItems.append("Kategorie")
        }
        
        if gameSettings.numberOfImposters >= gameSettings.players.count && gameSettings.players.count > 0 {
            missingItems.append("Zu viele Spione für die Spieleranzahl")
        }
        return missingItems.isEmpty ? "Alle Einstellungen vollständig" : missingItems.joined(separator: " • ")
    }

    func startGame() {
        guard canStartGame else {
            alertMessage = "Bitte stelle sicher, dass mindestens 4 Spieler vorhanden sind und eine Kategorie ausgewählt wurde."
            showingAlert = true
            return
        }

        gameLogic.gameSettings = gameSettings
        
        Task { @MainActor in
            await gameLogic.startGame()
            route = .game
        }
    }

    func timeString(from seconds: Int) -> String {
        let minutes = seconds / 60
        return minutes == 1 ? "1 Minute" : "\(minutes) Minuten"
    }

    var activeSpyOptionsCount: Int {
        var count = 0
        if gameSettings.spyCanSeeCategory { count += 1 }
        if gameSettings.spiesCanSeeEachOther && gameSettings.numberOfImposters >= 2 { count += 1 }
        if gameSettings.randomSpyCount { count += 1 }
        if gameSettings.showSpyHints { count += 1 }
        return count
    }

    var categoryDisplayName: String {
        return gameSettings.categorySelectionDisplayName
    }
}
