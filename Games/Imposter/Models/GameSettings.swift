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
    @Published var numberOfImposters: Int {
        didSet { UserDefaults.standard.set(numberOfImposters, forKey: "imposter.numberOfImposters") }
    }
    @Published var selectedCategory: Category?
    @Published var selectedCategoryIds: Set<UUID> = []
    @Published var isMixAllCategories: Bool = false
    @Published var roundCategory: Category?
    @Published var timeLimit: Int {
        didSet { UserDefaults.standard.set(timeLimit, forKey: "imposter.timeLimit") }
    }
    @Published var gameMode: ImposterGameMode {
        didSet {
            if let data = try? JSONEncoder().encode(gameMode) {
                UserDefaults.standard.set(data, forKey: "imposter.gameMode")
            }
        }
    }
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
    @Published var spyCanSeeCategory: Bool {
        didSet { UserDefaults.standard.set(spyCanSeeCategory, forKey: "imposter.spyCanSeeCategory") }
    }
    @Published var spiesCanSeeEachOther: Bool {
        didSet { UserDefaults.standard.set(spiesCanSeeEachOther, forKey: "imposter.spiesCanSeeEachOther") }
    }
    @Published var randomSpyCount: Bool {
        didSet { UserDefaults.standard.set(randomSpyCount, forKey: "imposter.randomSpyCount") }
    }
    @Published var showSpyHints: Bool {
        didSet { UserDefaults.standard.set(showSpyHints, forKey: "imposter.showSpyHints") }
    }
    @Published var activeRoles: Set<RoleType> = []
    
    // Spielzustand
    @Published var currentPlayerIndex: Int = 0
    @Published var gamePhase: ImposterGamePhase = .setup
    @Published var timeRemaining: Int = 300
    @Published var isTimerPaused: Bool = false
    @Published var startingPlayerName: String? = nil
    
    // Multiplayer Sync State
    @Published var revealProgress: (ready: Int, total: Int)? = nil
    @Published var isWaitingForOtherPlayers: Bool = false
    
    /// Signal an übergeordnete Views, bis ins Hauptmenü zurückzunavigieren
    @Published var requestExitToMain: Bool = false
    
    /// Signal an übergeordnete Views, das laufende Spiel zu beenden und zum Setup zurückzukehren
    @Published var requestExitToSetup: Bool = false
    
    private let customCategoryStore = CustomCategoryStore.shared
    private var customCategories: [Category] = []
    private var hasRecordedRoundCompletion = false

    init() {
        let defaults = UserDefaults.standard
        
        // Load Settings
        self.numberOfImposters = defaults.integer(forKey: "imposter.numberOfImposters") > 0 ? defaults.integer(forKey: "imposter.numberOfImposters") : 1
        self.timeLimit = defaults.integer(forKey: "imposter.timeLimit") > 0 ? defaults.integer(forKey: "imposter.timeLimit") : 300
        
        if let data = defaults.data(forKey: "imposter.gameMode"),
           let mode = try? JSONDecoder().decode(ImposterGameMode.self, from: data) {
            self.gameMode = mode
        } else {
            self.gameMode = .classic
        }
        
        self.spyCanSeeCategory = defaults.bool(forKey: "imposter.spyCanSeeCategory")
        self.spiesCanSeeEachOther = defaults.bool(forKey: "imposter.spiesCanSeeEachOther")
        self.randomSpyCount = defaults.bool(forKey: "imposter.randomSpyCount")
        self.showSpyHints = defaults.bool(forKey: "imposter.showSpyHints")

        let storedCustomCategories = customCategoryStore.loadCategories().map { category in
            var customCategory = category
            customCategory.isCustom = true
            return customCategory
        }
        customCategories = storedCustomCategories
        rebuildCategories()
        
        // Factory Reset Listener
        NotificationCenter.default.addObserver(forName: Notification.Name("AppDidReset"), object: nil, queue: .main) { [weak self] _ in
            self?.resetSettingsToDefaults()
        }
    }
    
    private func resetSettingsToDefaults() {
        numberOfImposters = 1
        timeLimit = 300
        gameMode = .classic
        spyCanSeeCategory = false
        spiesCanSeeEachOther = false
        randomSpyCount = false
        showSpyHints = false
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
            return (category.sourceName ?? category.name).lowercased() == "orte"
        }
        if selectedCategoryIds.isEmpty, let selectedCategory {
            return (selectedCategory.sourceName ?? selectedCategory.name).lowercased() == "orte"
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
        let sourceName = category.sourceName
        customCategories.removeAll {
            $0.id == category.id || (sourceName != nil && $0.sourceName == sourceName)
        }
        persistCustomCategories()
    }
    
    func updateCategory(_ category: Category) {
        var updated = category
        if !updated.isCustom {
            updated.isCustom = true
            updated.sourceName = updated.sourceName ?? updated.name
        }

        if let index = customCategories.firstIndex(where: { $0.id == updated.id }) {
            customCategories[index] = updated
        } else if let sourceName = updated.sourceName,
                  let index = customCategories.firstIndex(where: { $0.sourceName == sourceName }) {
            customCategories[index] = updated
        } else {
            customCategories.append(updated)
        }
        persistCustomCategories()
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
        rebuildCategories()
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

    private func rebuildCategories() {
        let overrides = Set(customCategories.compactMap { $0.sourceName })
        let filteredDefaults = Category.defaultCategories.filter { category in
            let key = category.sourceName ?? category.name
            return !overrides.contains(key)
        }
        categories = filteredDefaults + customCategories
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
        if n < 2 { return 0 } // Mindestens 2 Spieler
        if n == 2 { return 1 } // TEST: Bei 2 Spielern 1 Spion erlauben
        if n == 4 { return 1 }
        let half = max(1, n / 2) // floor(n/2)
        return min(half, max(1, n - 1))
    }
    
    func clampNumberOfImpostersToCap() {
        numberOfImposters = min(max(1, numberOfImposters), maxAllowedImpostersCap)
    }
    
    // MARK: - MPC Helpers
    func toMPCConfig() -> ImposterGameConfig {
        return ImposterGameConfig(
            numberOfImposters: numberOfImposters,
            timeLimit: timeLimit,
            gameMode: gameMode,
            spyCanSeeCategory: spyCanSeeCategory,
            spiesCanSeeEachOther: spiesCanSeeEachOther,
            randomSpyCount: randomSpyCount,
            showSpyHints: showSpyHints,
            activeRoles: activeRoles,
            selectedCategoryIds: selectedCategoryIds,
            isMixAllCategories: isMixAllCategories
        )
    }
    
    func applyMPCConfig(_ config: ImposterGameConfig) {
        self.numberOfImposters = config.numberOfImposters
        self.timeLimit = config.timeLimit
        self.gameMode = config.gameMode
        self.spyCanSeeCategory = config.spyCanSeeCategory
        self.spiesCanSeeEachOther = config.spiesCanSeeEachOther
        self.randomSpyCount = config.randomSpyCount
        self.showSpyHints = config.showSpyHints
        self.activeRoles = config.activeRoles
        self.selectedCategoryIds = config.selectedCategoryIds
        self.isMixAllCategories = config.isMixAllCategories
        if selectedCategoryIds.count == 1, let id = selectedCategoryIds.first,
           let category = categories.first(where: { $0.id == id }) {
            selectedCategory = category
        } else {
            selectedCategory = nil
        }
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

enum ImposterGamePhase: String, Codable {
    case setup
    case cardReveal
    case playing
    case finished
}
