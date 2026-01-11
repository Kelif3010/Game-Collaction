import Foundation
import SwiftUI
import Combine

class AppModel: ObservableObject {
    @Published var players: [Player] = [] {
        didSet {
            if let data = try? JSONEncoder().encode(players) {
                UserDefaults.standard.set(data, forKey: "question.players")
            }
        }
    }
    @Published var selectedQuestionsCategory: QuestionsCategory? {
        didSet {
            if let id = selectedQuestionsCategory?.id.uuidString {
                UserDefaults.standard.set(id, forKey: "question.selectedCategoryId")
            }
        }
    }
    @Published var numberOfImposters: Int = 1 {
        didSet { UserDefaults.standard.set(numberOfImposters, forKey: "question.numberOfImposters") }
    }
    
    // WICHTIG: Hier speichern wir den Fairness-Zustand
    @Published var fairnessState = FairnessState() {
        didSet {
            if let data = try? JSONEncoder().encode(fairnessState) {
                UserDefaults.standard.set(data, forKey: "question.fairnessState")
            }
        }
    }
    
    // Scoreboard
    @Published var scores: [UUID: Int] = [:] {
        didSet {
            if let data = try? JSONEncoder().encode(scores) {
                UserDefaults.standard.set(data, forKey: "question.scores")
            }
        }
    }
    
    // HIER WAR DAS PROBLEM: Wir müssen die Regeln explizit setzen!
    @Published var fairnessPolicy: FairnessPolicy {
        didSet {
            if let data = try? JSONEncoder().encode(fairnessPolicy) {
                UserDefaults.standard.set(data, forKey: "question.fairnessPolicy")
            }
        }
    }
    
    init() {
        let defaults = UserDefaults.standard
        
        // 1. Players
        if let data = defaults.data(forKey: "question.players"),
           let savedPlayers = try? JSONDecoder().decode([Player].self, from: data),
           !savedPlayers.isEmpty {
            self.players = savedPlayers
        } else {
            // Default players
            self.players = []
            // Helper function logic for default players is below, but we can't call instance method easily before init finishes self.
            // We'll init empty and then populate if needed.
        }
        
        // 2. Category
        let savedCatId = defaults.string(forKey: "question.selectedCategoryId")
        if let savedCatId = savedCatId,
           let found = QuestionsDefaults.all.first(where: { $0.id.uuidString == savedCatId }) {
            self.selectedQuestionsCategory = found
        } else {
            self.selectedQuestionsCategory = QuestionsDefaults.all.first
        }
        
        // 3. Imposters
        let savedImposters = defaults.integer(forKey: "question.numberOfImposters")
        self.numberOfImposters = savedImposters > 0 ? savedImposters : 1
        
        // 4. Fairness State
        if let data = defaults.data(forKey: "question.fairnessState"),
           let state = try? JSONDecoder().decode(FairnessState.self, from: data) {
            self.fairnessState = state
        } else {
            self.fairnessState = FairnessState()
        }
        
        // 5. Fairness Policy
        if let data = defaults.data(forKey: "question.fairnessPolicy"),
           let policy = try? JSONDecoder().decode(FairnessPolicy.self, from: data) {
            self.fairnessPolicy = policy
        } else {
            self.fairnessPolicy = FairnessPolicy(
                maxConsecutive: 2,
                minCooldownRounds: 1,
                recentWindow: 3,
                alphaFrequencyPenalty: 0.6,
                betaDistanceBonus: 0.2,
                newPlayerHardCooldownRounds: 0,
                newPlayerSoftPenaltyRounds: 2,
                newPlayerPenaltyFactor: 0.4
            )
        }
        
        // 6. Scores
        if let data = defaults.data(forKey: "question.scores"),
           let savedScores = try? JSONDecoder().decode([UUID: Int].self, from: data) {
            self.scores = savedScores
        } else {
            self.scores = [:]
        }
        
        // Populate default players if empty
        if self.players.isEmpty {
             self.players = (1...4).map { Player(name: defaultPlayerName(for: $0)) }
        }
        
        // Reset Listener
        NotificationCenter.default.addObserver(forName: Notification.Name("AppDidReset"), object: nil, queue: .main) { [weak self] _ in
            self?.resetToDefaults()
        }
    }
    
    private func resetToDefaults() {
        players = (1...4).map { Player(name: defaultPlayerName(for: $0)) }
        selectedQuestionsCategory = QuestionsDefaults.all.first
        numberOfImposters = 1
        fairnessState = FairnessState()
        scores = [:]
        // Policy reset if needed, but usually static defaults are fine or re-init policy
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
