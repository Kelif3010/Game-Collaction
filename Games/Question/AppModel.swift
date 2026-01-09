import Foundation
import SwiftUI
import Combine

class AppModel: ObservableObject {
    @Published var players: [Player] = []
    @Published var selectedQuestionsCategory: QuestionsCategory?
    @Published var numberOfImposters: Int = 1
    
    // WICHTIG: Hier speichern wir den Fairness-Zustand
    @Published var fairnessState = FairnessState()
    
    // Scoreboard
    @Published var scores: [UUID: Int] = [:]
    
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
        self.players = (1...4).map { Player(name: defaultPlayerName(for: $0)) }
        self.selectedQuestionsCategory = QuestionsDefaults.all.first
    }

    func defaultPlayerName(for index: Int) -> String {
        let format = localizedString("Spieler %d")
        return String(format: format, index)
    }

    private func localizedString(_ key: String) -> String {
        let code: String
        let defaults = UserDefaults.standard
        if defaults.object(forKey: "useSystemLanguage") == nil || defaults.bool(forKey: "useSystemLanguage") {
            var preferred = "de"
            for identifier in Locale.preferredLanguages {
                if identifier.hasPrefix("de") {
                    preferred = "de"
                    break
                }
                if identifier.hasPrefix("en") {
                    preferred = "en"
                    break
                }
            }
            code = preferred
        } else {
            code = defaults.string(forKey: "selectedLanguageCode") ?? "de"
        }

        if let path = Bundle.main.path(forResource: code, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            return bundle.localizedString(forKey: key, value: key, table: nil)
        }
        return NSLocalizedString(key, comment: "")
    }
    
    func pickFairSpies() -> Set<UUID> {
        return []
    }
    
    // MARK: - Scoring
    func addPoints(to playerIDs: Set<UUID>, amount: Int) {
        for id in playerIDs {
            scores[id, default: 0] += amount
        }
    }
    
    func resetScores() {
        scores.removeAll()
    }
    
    func getScore(for playerID: UUID) -> Int {
        scores[playerID] ?? 0
    }
}
