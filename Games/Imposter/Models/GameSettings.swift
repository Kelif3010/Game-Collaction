//
//  GameSettings.swift
//  Imposter
//
//  Created by Ken on 22.09.25.
//

import Foundation

@Observable
class GameSettings {
    var players: [Player] = []
    var numberOfImposters: Int {
        didSet { UserDefaults.standard.set(numberOfImposters, forKey: "imposter.numberOfImposters") }
    }
    var selectedCategory: Category?
    var selectedCategoryIds: Set<UUID> = []
    var isMixAllCategories: Bool = false
    var roundCategory: Category?
    var timeLimit: Int {
        didSet { UserDefaults.standard.set(timeLimit, forKey: "imposter.timeLimit") }
    }
    var gameMode: ImposterGameMode {
        didSet { UserDefaults.standard.set(gameMode.rawValue, forKey: "imposter.gameMode") }
    }
    var categories: [Category] = Category.defaultCategories

    var fairnessPolicy: FairnessPolicy = FairnessPolicy(
        maxConsecutive: 2,
        minCooldownRounds: 1,
        recentWindow: 3,
        alphaFrequencyPenalty: 0.6,
        betaDistanceBonus: 0.2,
        newPlayerHardCooldownRounds: 0,
        newPlayerSoftPenaltyRounds: 2,
        newPlayerPenaltyFactor: 0.4
    )
    var fairnessState: FairnessState = FairnessState()

    // Spielername-Manager
    var savedPlayersManager = SavedPlayersManager()

    // Spiel-Optionen für Imposter/Spione
    var spyCanSeeCategory: Bool {
        didSet { UserDefaults.standard.set(spyCanSeeCategory, forKey: "imposter.spyCanSeeCategory") }
    }
    var spiesCanSeeEachOther: Bool {
        didSet { UserDefaults.standard.set(spiesCanSeeEachOther, forKey: "imposter.spiesCanSeeEachOther") }
    }
    var randomSpyCount: Bool {
        didSet { UserDefaults.standard.set(randomSpyCount, forKey: "imposter.randomSpyCount") }
    }
    var showSpyHints: Bool {
        didSet { UserDefaults.standard.set(showSpyHints, forKey: "imposter.showSpyHints") }
    }
    var activeRoles: Set<RoleType> = [] {
        didSet {
            if let data = try? JSONEncoder().encode(activeRoles) {
                UserDefaults.standard.set(data, forKey: "imposter.activeRoles")
            }
        }
    }

    // Spielzustand
    var currentPlayerIndex: Int = 0
    var gamePhase: ImposterGamePhase = .setup
    var timeRemaining: Int = 300
    var isTimerPaused: Bool = false
    var startingPlayerName: String? = nil
    private var lastRoundCategoryId: UUID? = nil
    private var lastStartingPlayerId: UUID? = nil
    var currentCardBackAnimation: String = "Fingerprint biometric scan"
    var multiplayerStartAtHostUptime: TimeInterval? = nil
    var hostClockOffset: TimeInterval = 0
    var hostClockOffsetRTT: TimeInterval = .greatestFiniteMagnitude

    // Multiplayer Sync State
    var revealProgress: RevealProgress? = nil
    var isWaitingForOtherPlayers: Bool = false

    // Multiplayer Voting State
    var shouldPresentVoting: Bool = false
    var multiplayerVotingProgress: ImposterVotingStatusPayload? = nil
    var multiplayerVotingSelection: [String]? = nil
    var multiplayerVotingResult: ImposterVotingResultPayload? = nil
    var multiplayerWordGuessResult: ImposterWordGuessResultPayload? = nil
    var multiplayerRematchOffer: ImposterRematchOfferPayload? = nil
    var multiplayerRematchWaiting: Bool = false
    var multiplayerVoteTally: [String: Int] = [:]

    // Multiplayer Voting State (Host Only)
    var multiplayerVotes: [String: [String]] = [:]

    /// Signal an übergeordnete Views, bis ins Hauptmenü zurückzunavigieren
    var requestExitToMain: Bool = false

    /// Signal an übergeordnete Views, das laufende Spiel zu beenden und zum Setup zurückzukehren
    var requestExitToSetup: Bool = false

    /// Signal, um alle offenen Sheets (z.B. Lobby) zu schließen (wichtig für Rejoin)
    var shouldDismissSheets: Bool = false
    
    private let customCategoryStore = CustomCategoryStore.shared
    private var customCategories: [Category] = []
    private var hasRecordedRoundCompletion = false

    init() {
        let defaults = UserDefaults.standard
        
        // Load Settings
        self.numberOfImposters = defaults.integer(forKey: "imposter.numberOfImposters") > 0 ? defaults.integer(forKey: "imposter.numberOfImposters") : 1
        self.timeLimit = defaults.integer(forKey: "imposter.timeLimit") > 0 ? defaults.integer(forKey: "imposter.timeLimit") : 300
        
        let gameModeKey = "imposter.gameMode"
        if let raw = defaults.string(forKey: gameModeKey) {
            if let mode = ImposterGameMode(rawValue: raw) {
                self.gameMode = mode
            } else {
                self.gameMode = .classic
                defaults.set(ImposterGameMode.classic.rawValue, forKey: gameModeKey)
            }
        } else if let data = defaults.data(forKey: gameModeKey),
                  let mode = try? JSONDecoder().decode(ImposterGameMode.self, from: data) {
            self.gameMode = mode
            defaults.set(mode.rawValue, forKey: gameModeKey)
        } else {
            self.gameMode = .classic
        }
        
        // Load Active Roles
        if let data = defaults.data(forKey: "imposter.activeRoles"),
           let roles = try? JSONDecoder().decode(Set<RoleType>.self, from: data) {
            self.activeRoles = roles
        }
        
        // Load Players
        if let savedNames = defaults.stringArray(forKey: "imposter.lastPlayerNames") {
            self.players = savedNames.map { Player(name: $0) }
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
        Task { @MainActor [weak self] in
            for await _ in NotificationCenter.default.notifications(named: Notification.Name("AppDidReset")) {
                self?.resetSettingsToDefaults()
            }
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
        activeRoles = []
        players = []
        savePlayers()
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
        let filteredPool = pool.count > 1 ? pool.filter { $0.id != lastRoundCategoryId } : pool
        let chosen = filteredPool.randomElement() ?? pool.randomElement()
        lastRoundCategoryId = chosen?.id
        roundCategory = chosen
        return chosen
    }
    
    func addPlayer(name: String) {
        let player = Player(name: name)
        players.append(player)
        savePlayers()
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
            savePlayers()
        }
    }
    
    private func savePlayers() {
        let names = players.map { $0.name }
        UserDefaults.standard.set(names, forKey: "imposter.lastPlayerNames")
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
        startingPlayerName = nil
        gamePhase = .setup
        timeRemaining = timeLimit
        isTimerPaused = false
        roundCategory = nil
        multiplayerStartAtHostUptime = nil
        hostClockOffset = 0
        hostClockOffsetRTT = .greatestFiniteMagnitude
        shouldPresentVoting = false
        multiplayerVotingProgress = nil
        multiplayerVotingSelection = nil
        multiplayerVotingResult = nil
        multiplayerWordGuessResult = nil
        multiplayerRematchOffer = nil
        multiplayerRematchWaiting = false
        multiplayerVoteTally = [:]
        multiplayerVotes.removeAll()
        hasRecordedRoundCompletion = false
        
        // Reset player states
        for i in players.indices {
            players[i].hasSeenCard = false
            players[i].isImposter = false
            players[i].word = ""
            players[i].isEliminated = false
            players[i].role = nil
            players[i].roleType = nil // Reset RoleType (Fix for duplicate roles)
            players[i].isProtected = false // Reset Bodyguard protection
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
    
    func pickStartingPlayer() -> Player? {
        let available = players.count > 1 ? players.filter { $0.id != lastStartingPlayerId } : players
        let picked = available.randomElement() ?? players.randomElement()
        lastStartingPlayerId = picked?.id
        startingPlayerName = picked?.name
        return picked
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

// MARK: - RevealProgress

struct RevealProgress {
    let ready: Int
    let total: Int
}

// MARK: - ImposterGameMode

enum ImposterGameMode: String, CaseIterable, Codable {
    case classic = "Klassisch"
    case twoWords = "Zwei-Begriffe"
    case roles = "Rollen Modus"

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = (try? container.decode(String.self)) ?? ""
        self = ImposterGameMode(rawValue: rawValue) ?? .classic
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
    
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
