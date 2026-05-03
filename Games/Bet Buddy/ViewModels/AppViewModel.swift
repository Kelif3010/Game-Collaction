import SwiftUI
import Observation
import DequeModule
import OrderedCollections

// MARK: - Highlights & Statistik (Persistent)

struct HighlightRecord: Codable, Identifiable {
    var id: String { teamName } // Für ForEach
    let teamName: String
    var value: Int // Punkte, Anzahl oder Zeit
    let colorHex: String
}

struct GameHighlights: Codable {
    var maxWin: HighlightRecord?
    var maxLoss: HighlightRecord?
    var currentStreak: HighlightRecord?
    var bestStreak: HighlightRecord?
    var fastestWin: HighlightRecord?
    
    var totalWins: [String: Int] = [:]

    // BB-09: Kategorie-Statistiken
    var categoryPlayCount: [String: Int] = [:]

    // NEU: Die ewige Punktetabelle (Name -> Datensatz)
    var allTimeScores: [String: HighlightRecord] = [:]
    
    var mostWinsLeader: HighlightRecord? {
        guard let max = totalWins.max(by: { $0.value < $1.value }) else { return nil }
        return HighlightRecord(teamName: max.key, value: max.value, colorHex: "#FFD700")
    }
}

@MainActor
@Observable
final class AppViewModel {
    static let maxGroupCount = 4

    struct VoteEntry: Equatable {
        let groupId: UUID
        let amount: Int
    }

    // MARK: - Properties
    var selectedGroupCount: Int {
        didSet {
            syncGroups(to: selectedGroupCount)
            UserDefaults.standard.set(selectedGroupCount, forKey: "betbuddy.groupCount")
        }
    }

    private(set) var groups: [GroupInfo]
    private(set) var selectedCategories: OrderedSet<CategoryType> {
        didSet {
            refreshChallenge()
            if let data = try? JSONEncoder().encode(selectedCategories) {
                UserDefaults.standard.set(data, forKey: "betbuddy.selectedCategories")
            }
        }
    }
    private(set) var currentChallenge: Challenge
    
    var timerSelection: Int {
        didSet { UserDefaults.standard.set(timerSelection, forKey: "betbuddy.timerSelection") }
    }
    var isTimerEnabled: Bool {
        didSet { UserDefaults.standard.set(isTimerEnabled, forKey: "betbuddy.isTimerEnabled") }
    }
    var isHintsEnabled: Bool {
        didSet { UserDefaults.standard.set(isHintsEnabled, forKey: "betbuddy.isHintsEnabled") }
    }
    var isPartyMode: Bool {
        didSet { UserDefaults.standard.set(isPartyMode, forKey: "betbuddy.isPartyMode") }
    }
    var isPenaltyEnabled: Bool {
        didSet { UserDefaults.standard.set(isPenaltyEnabled, forKey: "betbuddy.isPenaltyEnabled") }
    }
    var penaltyLevel: PenaltyLevel {
        didSet {
            if let data = try? JSONEncoder().encode(penaltyLevel) {
                UserDefaults.standard.set(data, forKey: "betbuddy.penaltyLevel")
            }
        }
    }

    var timerRemaining: Int = 0
    var votesLocked: Bool = false
    var voteCounters: [UUID: Int] = [:]
    private(set) var voteHistory: Deque<VoteEntry> = []
    
    // Session Scores (nur für das aktuelle Spiel / ResultView)
    private(set) var scores: [UUID: Int] = [:] {
        didSet {
            guard !isInitializing else { return }
            saveSessionScores()
        }
    }
    private var isInitializing = true
    
    var highlights = GameHighlights()

    private var playedChallengeIDs: Set<UUID> = []
    private var lastChallengeCategory: CategoryType?
    let timerOptions: [Int] = [15, 30, 45, 60, 90, 120, 180]

    // BB-14: Dependency Injection für Testbarkeit
    private let challengeService: any ChallengeProviding
    private var nameStore = GroupNamePersistence()
    private var timerTask: Task<Void, Never>?
    
    private let statsStorageKey = "BetBuddy_GlobalStats_V1"

    // MARK: - Init
    init(challengeService: any ChallengeProviding = ChallengeService()) {
        self.challengeService = challengeService
        let defaults = UserDefaults.standard
        
        // Load Settings or use Defaults
        let savedGroupCount = defaults.integer(forKey: "betbuddy.groupCount")
        let initialGroupCount = savedGroupCount > 0 ? min(max(savedGroupCount, 2), Self.maxGroupCount) : 2
        
        var initialCategories: OrderedSet<CategoryType> = [.classic]
        if let data = defaults.data(forKey: "betbuddy.selectedCategories"),
           let decoded = try? JSONDecoder().decode(OrderedSet<CategoryType>.self, from: data),
           !decoded.isEmpty {
            initialCategories = decoded
        } else if let data = defaults.data(forKey: "betbuddy.selectedCategories"),
                  let decoded = try? JSONDecoder().decode([CategoryType].self, from: data),
                  !decoded.isEmpty {
            initialCategories = OrderedSet(decoded)
        } else if let data = defaults.data(forKey: "betbuddy.selectedCategories"),
                  let decoded = try? JSONDecoder().decode(Set<CategoryType>.self, from: data),
                  !decoded.isEmpty {
            initialCategories = OrderedSet(decoded)
        }

        let initialTimer = defaults.integer(forKey: "betbuddy.timerSelection") > 0 ? defaults.integer(forKey: "betbuddy.timerSelection") : 60
        let initialTimerEnabled = defaults.object(forKey: "betbuddy.isTimerEnabled") != nil ? defaults.bool(forKey: "betbuddy.isTimerEnabled") : true
        let initialHints = defaults.bool(forKey: "betbuddy.isHintsEnabled")
        let initialParty = defaults.bool(forKey: "betbuddy.isPartyMode")
        let initialPenalty = defaults.bool(forKey: "betbuddy.isPenaltyEnabled")
        
        var initialPenaltyLevel: PenaltyLevel = .normal
        if let pData = defaults.data(forKey: "betbuddy.penaltyLevel"),
           let pDecoded = try? JSONDecoder().decode(PenaltyLevel.self, from: pData) {
            initialPenaltyLevel = pDecoded
        }

        let store = GroupNamePersistence()

        selectedGroupCount = initialGroupCount
        selectedCategories = initialCategories
        timerSelection = initialTimer
        isTimerEnabled = initialTimerEnabled
        isHintsEnabled = initialHints
        isPartyMode = initialParty
        isPenaltyEnabled = initialPenalty
        penaltyLevel = initialPenaltyLevel
        
        playedChallengeIDs = []

        let colors = Array(GroupColor.allCases.prefix(initialGroupCount))
        groups = colors.map {
            GroupInfo(
                color: $0,
                customName: store.loadName(for: $0),
                playerNames: store.loadPlayerNames(for: $0)
            )
        }
        
        let startResult = challengeService.randomChallenge(
            for: Set(initialCategories),
            excluding: [],
            avoiding: nil
        )
        currentChallenge = startResult.challenge
        playedChallengeIDs.insert(startResult.challenge.id)
        lastChallengeCategory = startResult.challenge.category
        
        timerRemaining = isTimerEnabled ? initialTimer : 0
        votesLocked = false
        voteCounters = Dictionary(uniqueKeysWithValues: groups.map { ($0.id, 0) })
        voteHistory = []
        scores = Dictionary(uniqueKeysWithValues: groups.map { ($0.id, 0) })
        
        loadStats()
        loadSessionScores()   // BB-01: gespeicherte Session-Scores wiederherstellen
        isInitializing = false

        // Listen for Factory Reset
        NotificationCenter.default.addObserver(forName: Notification.Name("AppDidReset"), object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.resetToDefaults()
            }
        }
    }
    
    private func resetToDefaults() {
        // Hard Reset Logic called by AppLifecycleManager (via Notification or similar if needed)
        // For now, AppLifecycleManager clears UserDefaults, so restarting the app handles it.
        // But if we want live update:
        selectedGroupCount = 2
        selectedCategories = [.classic]
        timerSelection = 60
        isTimerEnabled = true
        isHintsEnabled = false
        isPartyMode = false
        isPenaltyEnabled = false
        penaltyLevel = .normal
        // Reset Scores
        resetGlobalStats()
        resetSessionScores()
    }

    var activeGroups: [GroupInfo] { Array(groups.prefix(selectedGroupCount)) }

    // BB-04: Gleichstand-Erkennung
    var isDrawResult: Bool {
        let values = voteCounters.values.filter { $0 > 0 }
        guard let max = values.max(), max > 0 else { return false }
        return values.filter { $0 == max }.count > 1
    }

    // FIX: Zeigt "Mix" an, wenn mehr als 1 Kategorie gewählt ist
    var selectedCategoriesDisplay: String {
        if selectedCategories.count > 1 {
            return "Mix"
        }
        return selectedCategories.first?.title ?? "Keine"
    }

    var availableCategories: [CategoryType] {
        CategoryType.allCases
    }

    // Für ResultView (Session based)
    var leaderboard: [LeaderboardEntry] {
        activeGroups
            .map { group in
                LeaderboardEntry(
                    groupId: group.id,
                    name: group.displayName,
                    color: group.color,
                    score: scores[group.id, default: 0]
                )
            }
            .sorted { lhs, rhs in
                lhs.score == rhs.score ? lhs.name < rhs.name : lhs.score > rhs.score
            }
    }
    
    // NEU: Für Home-Rangliste (All Time / Name based)
    var allTimeLeaderboard: [HighlightRecord] {
        highlights.allTimeScores.values.sorted { $0.value > $1.value }
    }

    // MARK: - Methods

    func setGroupCount(_ count: Int) {
        selectedGroupCount = max(2, min(count, Self.maxGroupCount))
    }

    func updateName(_ name: String, for color: GroupColor) {
        nameStore.save(name: name, for: color)
        groups = groups.map { group in
            guard group.color == color else { return group }
            return GroupInfo(
                id: group.id, color: color, customName: name,
                playerNames: group.playerNames,
                activePlayerIndex: group.activePlayerIndex, score: group.score
            )
        }
    }

    func updatePlayerNames(player1: String, player2: String, for color: GroupColor) {
        updatePlayerNames([player1, player2], for: color)
    }

    func updatePlayerNames(_ names: [String], for color: GroupColor) {
        nameStore.savePlayerNames(names, for: color)
        groups = groups.map { group in
            guard group.color == color else { return group }
            return GroupInfo(
                id: group.id, color: color, customName: group.customName,
                playerNames: names.map { Optional($0) },
                activePlayerIndex: group.activePlayerIndex, score: group.score
            )
        }
    }

    func randomizeStartingPlayers() {
        groups = groups.map { group in
            var updated = group
            updated.activePlayerIndex = Int.random(in: 0..<updated.playerSlotCount)
            return updated
        }
    }

    func rotateActivePlayers() {
        groups = groups.map { group in
            var updated = group
            updated.activePlayerIndex = (updated.activePlayerIndex + 1) % updated.playerSlotCount
            return updated
        }
    }

    func refreshChallenge() {
        let result = challengeService.randomChallenge(
            for: Set(selectedCategories),
            excluding: playedChallengeIDs,
            avoiding: lastChallengeCategory
        )
        currentChallenge = result.challenge
        lastChallengeCategory = result.challenge.category

        // BB-09: Kategorie-Spielzähler erhöhen
        let categoryKey = result.challenge.category.rawValue
        highlights.categoryPlayCount[categoryKey, default: 0] += 1
        saveStats()

        if result.didReset {
            playedChallengeIDs.removeAll()
            playedChallengeIDs.insert(result.challenge.id)
        } else {
            playedChallengeIDs.insert(result.challenge.id)
        }
    }

    func resetVotes() {
        voteCounters = Dictionary(uniqueKeysWithValues: activeGroups.map { ($0.id, 0) })
        votesLocked = false
        timerRemaining = isTimerEnabled ? timerSelection : 0
        stopTimer()
        voteHistory = []
    }
    
    // Setzt nur die Session zurück (Punkte auf 0), behält aber die ewige Statistik
    func resetSessionScores() {
        resetVotes()
        scores = Dictionary(uniqueKeysWithValues: groups.map { ($0.id, 0) })
        UserDefaults.standard.removeObject(forKey: "betbuddy.sessionScores")
        playedChallengeIDs.removeAll()
        lastChallengeCategory = nil
        refreshChallenge()
    }
    
    // Löscht die komplette "Hall of Fame" und ewige Rangliste
    func resetGlobalStats() {
        highlights = GameHighlights()
        saveStats()
    }

    func toggleCategory(_ category: CategoryType) {
        if selectedCategories.contains(category) {
            if selectedCategories.count > 1 {
                _ = selectedCategories.remove(category)
            }
        } else {
            selectedCategories.append(category)
        }
    }

    // MARK: - Scoring & Persistence

    private func saveStats() {
        if let data = try? JSONEncoder().encode(highlights) {
            UserDefaults.standard.set(data, forKey: statsStorageKey)
        }
    }
    
    private func loadStats() {
        if let data = UserDefaults.standard.data(forKey: statsStorageKey),
           let decoded = try? JSONDecoder().decode(GameHighlights.self, from: data) {
            highlights = decoded
        } else {
            highlights = GameHighlights()
        }
    }
    
    private func getHex(for color: GroupColor) -> String {
        switch color {
        case .red: return "#FF3B30"
        case .blue: return "#007AFF"
        case .green: return "#34C759"
        case .yellow: return "#FFCC00"
        case .purple: return "#AF52DE"
        case .orange: return "#FF9500"
        case .pink: return "#FF2D55"
        case .teal: return "#30B0C7"
        }
    }

    func awardScore(to group: GroupInfo, amount: Int, timeRemaining: Int? = nil) {
        guard amount > 0 else { return }
        
        // 1. Session Score aktualisieren (UUID basiert)
        scores[group.id, default: 0] += amount
        
        let name = group.displayName
        let colorHex = getHex(for: group.color)
        
        // 2. Ewige Tabelle aktualisieren (Namens-basiert)
        // Wenn der Name existiert, addiere Punkte. Wenn nicht, erstelle neu.
        if var existing = highlights.allTimeScores[name] {
            existing.value += amount
            highlights.allTimeScores[name] = existing
        } else {
            highlights.allTimeScores[name] = HighlightRecord(teamName: name, value: amount, colorHex: colorHex)
        }
        
        // 3. Highlights prüfen
        if let currentMax = highlights.maxWin {
            if amount > currentMax.value {
                highlights.maxWin = HighlightRecord(teamName: name, value: amount, colorHex: colorHex)
            }
        } else {
            highlights.maxWin = HighlightRecord(teamName: name, value: amount, colorHex: colorHex)
        }
        
        highlights.totalWins[name, default: 0] += 1
        
        if let time = timeRemaining, isTimerEnabled {
            if let currentFastest = highlights.fastestWin {
                if time > currentFastest.value {
                    highlights.fastestWin = HighlightRecord(teamName: name, value: time, colorHex: colorHex)
                }
            } else {
                highlights.fastestWin = HighlightRecord(teamName: name, value: time, colorHex: colorHex)
            }
        }
        saveStats()
    }

    func deductScore(for group: GroupInfo, amount: Int) {
        guard amount > 0 else { return }
        
        // 1. Session Score (nicht unter 0)
        let current = scores[group.id, default: 0]
        scores[group.id] = max(0, current - amount)
        
        let name = group.displayName
        let colorHex = getHex(for: group.color)
        
        // 2. Ewige Tabelle: Punkte abziehen (hier erlauben wir auch negative Werte im All-Time, oder stoppen bei 0?)
        // Üblicherweise zählt eine Rangliste eher Erfolge. Wenn du Abzüge auch langzeit willst:
        /*
        if var existing = highlights.allTimeScores[name] {
            existing.value = max(0, existing.value - amount) // Nicht unter 0
            highlights.allTimeScores[name] = existing
        }
        */
        
        // 3. Highlights (Pechvogel)
        if let currentMax = highlights.maxLoss {
            if amount > currentMax.value {
                highlights.maxLoss = HighlightRecord(teamName: name, value: amount, colorHex: colorHex)
            }
        } else {
            highlights.maxLoss = HighlightRecord(teamName: name, value: amount, colorHex: colorHex)
        }
        saveStats()
    }
    
    func updatePlayStreak(for groupId: UUID) {
        guard let group = groups.first(where: { $0.id == groupId }) else { return }
        let name = group.displayName
        let colorHex = getHex(for: group.color)
        
        if var current = highlights.currentStreak {
            if current.teamName == name {
                current.value += 1
                highlights.currentStreak = current
            } else {
                highlights.currentStreak = HighlightRecord(teamName: name, value: 1, colorHex: colorHex)
            }
        } else {
            highlights.currentStreak = HighlightRecord(teamName: name, value: 1, colorHex: colorHex)
        }
        
        if let current = highlights.currentStreak,
           let best = highlights.bestStreak {
            if current.value > best.value {
                highlights.bestStreak = current
            }
        } else if let current = highlights.currentStreak {
            highlights.bestStreak = current
        }
        saveStats()
    }

    // MARK: - Voting & Timer (Unverändert)
    func incrementVote(for group: GroupInfo) {
        guard !votesLocked else { return }
        let current = voteCounters[group.id, default: 0]
        let otherMax = voteCounters.filter { $0.key != group.id }.map(\.value).max() ?? 0
        let proposed = current + 1
        let target = max(proposed, otherMax + 1)
        let addedAmount = target - current
        guard addedAmount > 0 else { return }
        voteCounters[group.id] = target
        voteHistory.append(VoteEntry(groupId: group.id, amount: addedAmount))
    }

    func decrementVote(for group: GroupInfo) {
        guard !votesLocked else { return }
        guard let last = voteHistory.last, last.groupId == group.id else { return }
        voteHistory.removeLast()
        let current = voteCounters[group.id, default: 0]
        voteCounters[group.id] = max(0, current - last.amount)
    }

    func startTimer() {
        guard isTimerEnabled else {
            timerRemaining = 0
            votesLocked = false
            stopTimer()
            return
        }
        timerRemaining = timerSelection
        votesLocked = false
        stopTimer()
        guard timerSelection > 0 else { return }
        
        timerTask = Task { @MainActor [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }

                if self.timerRemaining > 1 {
                    self.timerRemaining -= 1
                } else {
                    self.timerRemaining = 0
                    self.lockVotes()
                    return
                }
            }
        }
    }

    func lockVotes() {
        votesLocked = true
        stopTimer()
    }

    func stopTimer() {
        timerTask?.cancel()
        timerTask = nil
    }

    private func syncGroups(to count: Int) {
        let safeCount = max(2, min(count, Self.maxGroupCount))
        var updated: [GroupInfo] = []

        for (index, color) in GroupColor.allCases.enumerated() {
            guard index < safeCount else { break }
            if let existing = groups.first(where: { $0.color == color }) {
                updated.append(existing)
            } else {
                updated.append(GroupInfo(
                    color: color,
                    customName: nameStore.loadName(for: color),
                    playerNames: nameStore.loadPlayerNames(for: color)
                ))
            }
        }
        groups = updated
        resetVotes()
        syncScores()
    }

    private func syncScores() {
        var newScores: [UUID: Int] = [:]
        for group in groups {
            newScores[group.id] = scores[group.id, default: 0]
        }
        scores = newScores
    }

    // MARK: - Session Score Persistence (BB-01 Fix)

    private func saveSessionScores() {
        // Speichern nach GroupColor.rawValue (stabil über App-Neustarts)
        var colorKeyed: [String: Int] = [:]
        for group in groups {
            colorKeyed[group.color.rawValue] = scores[group.id, default: 0]
        }
        if let data = try? JSONEncoder().encode(colorKeyed) {
            UserDefaults.standard.set(data, forKey: "betbuddy.sessionScores")
        }
    }

    private func loadSessionScores() {
        guard let data = UserDefaults.standard.data(forKey: "betbuddy.sessionScores"),
              let colorKeyed = try? JSONDecoder().decode([String: Int].self, from: data)
        else { return }
        for group in groups {
            if let saved = colorKeyed[group.color.rawValue] {
                scores[group.id] = saved
            }
        }
    }
}
