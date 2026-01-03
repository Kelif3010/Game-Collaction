import SwiftUI
import Combine

@MainActor
final class AppViewModel: ObservableObject {
    struct VoteEntry: Equatable {
        let groupId: UUID
        let amount: Int
    }

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
    @Published var timerRemaining: Int = 0
    @Published var votesLocked: Bool = false
    @Published var voteCounters: [UUID: Int] = [:]
    @Published private(set) var voteHistory: [VoteEntry] = []
    @Published private(set) var scores: [UUID: Int] = [:]
    @Published var penaltyLevel: PenaltyLevel = .normal

    private var playedChallengeIDs: Set<UUID> = []
    let timerOptions: [Int] = [15, 30, 45, 60, 90, 120, 180]

    private let challengeService = ChallengeService()
    private var nameStore = GroupNamePersistence()
    private var timer: Timer?

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
    }

    var activeGroups: [GroupInfo] { Array(groups.prefix(selectedGroupCount)) }
    
    var selectedCategoriesDisplay: String {
        selectedCategories.map { $0.title }.sorted().joined(separator: ", ")
    }

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
            print("Alle Fragen durchgespielt! Zyklus startet neu.")
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

    func toggleCategory(_ category: CategoryType) {
        if selectedCategories.contains(category) {
            if selectedCategories.count > 1 {
                selectedCategories.remove(category)
            }
        } else {
            selectedCategories.insert(category)
        }
    }

    func awardScore(to group: GroupInfo, amount: Int) {
        guard amount > 0 else { return }
        scores[group.id, default: 0] += amount
    }

    func deductScore(for group: GroupInfo, amount: Int) {
        guard amount > 0 else { return }
        let current = scores[group.id, default: 0]
        scores[group.id] = max(0, current - amount)
    }

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
        
        // FIX: MainActor Isolation
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
