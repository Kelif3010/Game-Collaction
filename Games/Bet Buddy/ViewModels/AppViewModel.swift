import SwiftUI
import Combine

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
    
    // NEU: Die ewige Punktetabelle (Name -> Datensatz)
    var allTimeScores: [String: HighlightRecord] = [:]
    
    var mostWinsLeader: HighlightRecord? {
        guard let max = totalWins.max(by: { $0.value < $1.value }) else { return nil }
        return HighlightRecord(teamName: max.key, value: max.value, colorHex: "#FFD700")
    }
}

@MainActor
final class AppViewModel: ObservableObject {
    struct VoteEntry: Equatable {
        let groupId: UUID
        let amount: Int
    }

    // MARK: - Properties
    @Published var selectedGroupCount: Int {
        didSet { syncGroups(to: selectedGroupCount) }
    }

    @Published private(set) var groups: [GroupInfo]
    @Published private(set) var selectedCategories: Set<CategoryType> {
        didSet { refreshChallenge() }
    }
    @Published private(set) var currentChallenge: Challenge
    
    @Published var timerSelection: Int
    @Published var isTimerEnabled: Bool
    @Published var isHintsEnabled: Bool = false
    @Published var isPartyMode: Bool = false
    @Published var isPenaltyEnabled: Bool = false
    @Published var penaltyLevel: PenaltyLevel = .normal

    @Published var timerRemaining: Int = 0
    @Published var votesLocked: Bool = false
    @Published var voteCounters: [UUID: Int] = [:]
    @Published private(set) var voteHistory: [VoteEntry] = []
    
    // Session Scores (nur für das aktuelle Spiel / ResultView)
    @Published private(set) var scores: [UUID: Int] = [:]
    
    @Published var highlights = GameHighlights()

    private var playedChallengeIDs: Set<UUID> = []
    let timerOptions: [Int] = [15, 30, 45, 60, 90, 120, 180]

    private let challengeService = ChallengeService()
    private var nameStore = GroupNamePersistence()
    private var timer: Timer?
    
    private let statsStorageKey = "BetBuddy_GlobalStats_V1"

    // MARK: - Init
    init() {
        let initialGroupCount = 2
        let initialCategories: Set<CategoryType> = [.classic]
        let initialTimer = 60
        let store = GroupNamePersistence()

        selectedGroupCount = initialGroupCount
        selectedCategories = initialCategories
        timerSelection = initialTimer
        isTimerEnabled = true
        isHintsEnabled = false
        isPartyMode = false
        isPenaltyEnabled = false
        penaltyLevel = .normal
        playedChallengeIDs = []

        let colors = Array(GroupColor.allCases.prefix(initialGroupCount))
        groups = colors.map { GroupInfo(color: $0, customName: store.loadName(for: $0)) }
        
        let service = ChallengeService()
        let startResult = service.randomChallenge(for: initialCategories, excluding: [])
        currentChallenge = startResult.challenge
        playedChallengeIDs.insert(startResult.challenge.id)
        
        timerRemaining = isTimerEnabled ? initialTimer : 0
        votesLocked = false
        voteCounters = Dictionary(uniqueKeysWithValues: groups.map { ($0.id, 0) })
        voteHistory = []
        scores = Dictionary(uniqueKeysWithValues: groups.map { ($0.id, 0) })
        
        loadStats()
    }

    var activeGroups: [GroupInfo] { Array(groups.prefix(selectedGroupCount)) }
    
    // FIX: Zeigt "Mix" an, wenn mehr als 1 Kategorie gewählt ist
    var selectedCategoriesDisplay: String {
        if selectedCategories.count > 1 {
            return "Mix"
        }
        return selectedCategories.first?.title ?? "Keine"
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
        selectedGroupCount = max(2, min(count, GroupColor.allCases.count))
    }

    func updateName(_ name: String, for color: GroupColor) {
        nameStore.save(name: name, for: color)
        groups = groups.map { group in
            guard group.color == color else { return group }
            return GroupInfo(id: group.id, color: color, customName: name, score: group.score)
        }
    }

    func refreshChallenge() {
        let result = challengeService.randomChallenge(
            for: selectedCategories,
            excluding: playedChallengeIDs
        )
        currentChallenge = result.challenge
        
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
        playedChallengeIDs.removeAll()
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
                selectedCategories.remove(category)
            }
        } else {
            selectedCategories.insert(category)
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
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if self.timerRemaining > 0 {
                    self.timerRemaining -= 1
                } else {
                    self.lockVotes()
                }
            }
        }
    }

    func lockVotes() {
        votesLocked = true
        stopTimer()
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func syncGroups(to count: Int) {
        let safeCount = max(2, min(count, GroupColor.allCases.count))
        var updated: [GroupInfo] = []

        for (index, color) in GroupColor.allCases.enumerated() {
            guard index < safeCount else { break }
            if let existing = groups.first(where: { $0.color == color }) {
                updated.append(existing)
            } else {
                let name = nameStore.loadName(for: color)
                updated.append(GroupInfo(color: color, customName: name))
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
}
