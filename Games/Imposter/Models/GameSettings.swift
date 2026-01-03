//
//  GameSettings.swift
//  Imposter
//
//  Created by Ken on 22.09.25.
//

import Foundation
import Combine

class GameSettings: ObservableObject {
    @Published var players: [Player] = []
    @Published var numberOfImposters: Int = 1
    @Published var selectedCategory: Category?
    @Published var selectedCategoryIds: Set<UUID> = []
    @Published var isMixAllCategories: Bool = false
    @Published private(set) var roundCategory: Category?
    @Published var timeLimit: Int = 300 // 5 Minuten in Sekunden
    @Published var gameMode: ImposterGameMode = .classic
    @Published var categories: [Category] = Category.defaultCategories
    
    @Published var fairnessPolicy: FairnessPolicy = FairnessPolicy(
        maxConsecutive: 2,                    // Max 2x hintereinander Spion
        minCooldownRounds: 1,                 // 1 Runde Pause nach Spion
        recentWindow: 3,                      // 3 Runden "recent" Penalty
        alphaFrequencyPenalty: 0.6,           // Stärkere Häufigkeits-Penalty
        betaDistanceBonus: 0.2,               // Stärkerer Bonus für lange Pause
        newPlayerHardCooldownRounds: 0,       // Keine Hard-Cooldown für neue Spieler
        newPlayerSoftPenaltyRounds: 2,        // 2 Runden Soft-Penalty für neue Spieler
        newPlayerPenaltyFactor: 0.4           // 40% Gewichtung für neue Spieler
    )
    @Published var fairnessState: FairnessState = FairnessState()
    
    // Spielername-Manager
    @Published var savedPlayersManager = SavedPlayersManager()
    
    // Spiel-Optionen für Imposter/Spione
    @Published var spyCanSeeCategory: Bool = false
    @Published var spiesCanSeeEachOther: Bool = false
    @Published var randomSpyCount: Bool = false  // Zufällige Spion-Anzahl ab 5 Spielern
    @Published var showSpyHints: Bool = false    // Hinweise für Imposter anzeigen
    
    // Spielzustand
    @Published var currentPlayerIndex: Int = 0
    @Published var gamePhase: ImposterGamePhase = .setup
    @Published var timeRemaining: Int = 300
    @Published var isTimerPaused: Bool = false
    
    /// Signal an übergeordnete Views, bis ins Hauptmenü zurückzunavigieren
    @Published var requestExitToMain: Bool = false
    
    private let customCategoryStore = CustomCategoryStore.shared
    private var customCategories: [Category] = []
    private var hasRecordedRoundCompletion = false

    init() {
        let storedCustomCategories = customCategoryStore.loadCategories().map { category in
            var customCategory = category
            customCategory.isCustom = true
            return customCategory
        }
        customCategories = storedCustomCategories
        categories = Category.defaultCategories + storedCustomCategories
    }

    var selectedCategories: [Category] {
        categories.filter { selectedCategoryIds.contains($0.id) }
    }

    var hasSelectedCategories: Bool {
        isMixAllCategories || !selectedCategoryIds.isEmpty || selectedCategory != nil
    }

    var categorySelectionDisplayName: String {
        if isMixAllCategories {
            return "Mix (Alle)"
        }
        let count = selectedCategoryIds.count
        if count == 1, let id = selectedCategoryIds.first,
           let category = categories.first(where: { $0.id == id }) {
            return category.name
        }
        if count > 1 {
            return "Mix (\(count))"
        }
        if let selectedCategory {
            return selectedCategory.name
        }
        return "0 ausgewählt"
    }

    var isRolesCategorySelected: Bool {
        guard !isMixAllCategories else { return false }
        if selectedCategoryIds.count == 1, let id = selectedCategoryIds.first,
           let category = categories.first(where: { $0.id == id }) {
            return category.name.lowercased() == "orte"
        }
        if selectedCategoryIds.isEmpty, let selectedCategory {
            return selectedCategory.name.lowercased() == "orte"
        }
        return false
    }

    func chooseRoundCategory() -> Category? {
        let pool: [Category]
        if isMixAllCategories {
            pool = categories
        } else if !selectedCategoryIds.isEmpty {
            pool = selectedCategories
        } else if let selectedCategory {
            pool = [selectedCategory]
        } else {
            pool = []
        }
        let chosen = pool.randomElement()
        roundCategory = chosen
        return chosen
    }
    
    func addPlayer(name: String) {
        let player = Player(name: name)
        players.append(player)
        // Initialize fairness stats for a newly joined player
        let round = fairnessState.currentRound
        fairnessState.updateStats(for: player.id) { s in
            s.joinRound = round
            // Apply hard cooldown for new players so they cannot be imposters immediately
            s.cooldownUntilRound = round + fairnessPolicy.newPlayerHardCooldownRounds
        }
    }
    
    func removePlayer(at index: Int) {
        if index < players.count {
            players.remove(at: index)
        }
    }
    
    func addCustomCategory(_ category: Category) {
        var custom = category
        custom.isCustom = true
        customCategories.append(custom)
        persistCustomCategories()
    }
    
    func removeCategory(_ category: Category) {
        guard category.isCustom else { return }
        customCategories.removeAll { $0.id == category.id }
        persistCustomCategories()
        categories.removeAll { $0.id == category.id }
        selectedCategoryIds.remove(category.id)
        if selectedCategory?.id == category.id {
            selectedCategory = nil
        }
        if roundCategory?.id == category.id {
            roundCategory = nil
        }
    }
    
    func updateCategory(_ category: Category) {
        guard category.isCustom else { return }
        if let index = customCategories.firstIndex(where: { $0.id == category.id }) {
            var updated = category
            updated.isCustom = true
            customCategories[index] = updated
            persistCustomCategories()
        }
    }
    
    func resetGame() {
        currentPlayerIndex = 0
        gamePhase = .setup
        timeRemaining = timeLimit
        isTimerPaused = false
        roundCategory = nil
        hasRecordedRoundCompletion = false
        
        // Reset player states
        for i in players.indices {
            players[i].hasSeenCard = false
            players[i].isImposter = false
            players[i].word = ""
            players[i].isEliminated = false
            players[i].role = nil
        }
        
        // Fairness state wird NICHT zurückgesetzt, damit Statistiken erhalten bleiben
        // fairnessState = FairnessState() // ENTFERNT: Statistiken sollen zwischen Spielen erhalten bleiben
    }

    /// Stellt sicher, dass Fairness-Runden nur einmal pro Spiel erhöht werden.
    func markRoundCompleted() {
        guard !hasRecordedRoundCompletion else { return }
        fairnessState.advanceRound()
        hasRecordedRoundCompletion = true
    }

    private func persistCustomCategories() {
        customCategoryStore.saveCategories(customCategories)
        var currentSelectionIds = selectedCategoryIds
        if currentSelectionIds.isEmpty, let selectedCategory {
            currentSelectionIds.insert(selectedCategory.id)
        }
        categories = Category.defaultCategories + customCategories
        let validIds = Set(categories.map { $0.id })
        selectedCategoryIds = currentSelectionIds.intersection(validIds)
        if selectedCategoryIds.count == 1, let selection = selectedCategoryIds.first {
            selectedCategory = categories.first(where: { $0.id == selection })
        } else {
            selectedCategory = nil
        }
        if let roundCategory, !validIds.contains(roundCategory.id) {
            self.roundCategory = nil
        }
    }
    
    /// Prüft, ob Spione die Kategorie sehen sollen
    var shouldSpySeeCategory: Bool {
        return spyCanSeeCategory
    }
    
    /// Prüft, ob Spione sich gegenseitig sehen sollen (nur bei 2+ Spionen)
    var shouldSpiesSeeEachOther: Bool {
        return numberOfImposters >= 2 && spiesCanSeeEachOther
    }
    
    /// Gibt die Namen aller Spione zurück (für Spy-to-Spy Anzeige)
    var spyNames: [String] {
        return players.filter { $0.isImposter }.map { $0.name }
    }
    
    /// Maximale erlaubte Zahl an Spionen nach Regelwerk (<= 50%, Sonderfall 4 Spieler -> 1)
    var maxAllowedImpostersCap: Int {
        let n = players.count
        if n <= 1 { return 0 }
        if n == 4 { return 1 }
        let half = max(1, n / 2) // floor(n/2)
        return min(half, max(1, n - 1))
    }
    
    func clampNumberOfImpostersToCap() {
        numberOfImposters = min(max(1, numberOfImposters), maxAllowedImpostersCap)
    }
}

enum ImposterGameMode: String, CaseIterable, Codable {
    case classic = "Klassisch"
    case twoWords = "Zwei-Begriffe"
    case roles = "Rollen Modus"
    case questions = "Fragen Modus"
    
    var displayName: String {
        return self.rawValue
    }
    
    var description: String {
        switch self {
        case .classic:
            return "Klassisches Spion-Spiel mit einem Begriff"
        case .twoWords:
            return "Spieler werden in zwei Gruppen mit verschiedenen Begriffen aufgeteilt"
        case .roles:
            return "Jeder Spieler erhält eine KI-generierte Rolle basierend auf dem Ort (nur mit Kategorie 'Orte')"
        case .questions:
            return "Fragen-basierter Modus (Platzhalter – Logik folgt)"
        }
    }
    
    var icon: String {
        switch self {
        case .classic:
            return "star.fill"
        case .twoWords:
            return "doc.on.doc.fill"
        case .roles:
            return "theatermasks.fill"
        case .questions:
            return "questionmark.circle.fill"
        }
    }
}

// MARK: - Custom Category Persistence
final class CustomCategoryStore {
    static let shared = CustomCategoryStore()
    private let defaults = UserDefaults.standard
    private let key = "custom.categories.v1"
    private init() {}

    func loadCategories() -> [Category] {
        guard let data = defaults.data(forKey: key) else { return [] }
        return (try? JSONDecoder().decode([Category].self, from: data)) ?? []
    }

    func saveCategories(_ categories: [Category]) {
        guard let data = try? JSONEncoder().encode(categories) else { return }
        defaults.set(data, forKey: key)
    }
}

enum ImposterGamePhase {
    case setup
    case cardReveal
    case playing
    case finished
}
