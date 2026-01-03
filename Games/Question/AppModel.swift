import Foundation
import SwiftUI
import Combine

class AppModel: ObservableObject {
    @Published var players: [Player] = []
    @Published var selectedQuestionsCategory: QuestionsCategory?
    @Published var numberOfImposters: Int = 1
    
    // WICHTIG: Hier speichern wir den Fairness-Zustand
    @Published var fairnessState = FairnessState()
    
    // HIER WAR DAS PROBLEM: Wir müssen die Regeln explizit setzen!
    @Published var fairnessPolicy = FairnessPolicy(
        maxConsecutive: 2,                    // Max 2x hintereinander Spion
        minCooldownRounds: 1,                 // 1 Runde Pause nach Spion
        recentWindow: 3,                      // 3 Runden "Gedächtnis"
        alphaFrequencyPenalty: 0.6,           // Wer oft dran war, kommt seltener dran
        betaDistanceBonus: 0.2,               // Wer lange nicht dran war, kommt eher dran
        newPlayerHardCooldownRounds: 0,       // WICHTIG: 0, damit man SOFORT Spion sein kann
        newPlayerSoftPenaltyRounds: 2,
        newPlayerPenaltyFactor: 0.4
    )
    
    init() {
        // Test-Spieler
        self.players = [
            Player(name: "Spieler 1"),
            Player(name: "Spieler 2"),
            Player(name: "Spieler 3"),
            Player(name: "Spieler 4")
        ]
        self.selectedQuestionsCategory = QuestionsDefaults.all.first
    }
    
    func pickFairSpies() -> Set<UUID> {
        return []
    }
}
