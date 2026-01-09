import Foundation
import Combine

// MARK: - QuestionsEngine

final class QuestionsEngine: ObservableObject {
    // Publicly observed state
    @Published private(set) var config: QuestionsConfig
    @Published private(set) var phase: QuestionsPhase = .setup
    @Published private(set) var round: QuestionsRoundState?

    // Players (injected)
    private(set) var players: [Player] = []
    private var spies: Set<UUID> = [] // player ids
    private var fairnessState: FairnessState?
    private var fairnessPolicy: FairnessPolicy?
    // Expose current spy IDs as read-only for consumers like voting UI
    var currentSpyIDs: Set<UUID> { spies }

    // Internals
    private var cancellables = Set<AnyCancellable>()
    private var usedPromptIndices: Set<Int> = []

    init(config: QuestionsConfig = QuestionsConfig()) {
        self.config = config
    }

    // MARK: Configuration

    func configure(
        players: [Player],
        numberOfSpies: Int,
        category: QuestionsCategory,
        fairnessPolicy: FairnessPolicy? = nil,
        fairnessState: FairnessState? = nil
    ) {
        self.players = players
        self.config.numberOfSpies = max(0, min(numberOfSpies, max(0, players.count - 1)))
        self.config.selectedCategory = category
        self.fairnessPolicy = fairnessPolicy
        self.fairnessState = fairnessState
        self.phase = .setup
        usedPromptIndices.removeAll()
    }

    // Randomly assign spies for this mode (separate from base game, if desired)
    func assignSpiesRandomly(seed: UInt64? = nil) {
        guard players.count > 0 else { return }
        spies.removeAll()
        let spyCount = min(config.numberOfSpies, max(0, players.count - 1))
        guard spyCount > 0 else { return }
        
        if let fairnessState, let fairnessPolicy {
            var rng: any RandomNumberGeneratorLike = SystemRNGAdapter()
            let picked = ImposterPicker.pickImposters(
                players: players.map { $0.id },
                count: spyCount,
                policy: fairnessPolicy,
                state: fairnessState,
                rng: &rng,
                weightMultipliers: AITuner.shared.suggestWeightMultipliers(
                    players: players.map { $0.id },
                    policy: fairnessPolicy,
                    state: fairnessState
                )
            )
            spies = Set(picked)
            let round = fairnessState.currentRound
            fairnessState.recordImposters(picked)
            for id in picked {
                fairnessState.updateStats(for: id) { s in
                    s.cooldownUntilRound = round + fairnessPolicy.minCooldownRounds
                }
            }
            let pickedSet = Set(picked)
            for id in players.map({ $0.id }) where !pickedSet.contains(id) {
                fairnessState.updateStats(for: id) { s in
                    if s.currentStreak > 0 { s.currentStreak = 0 }
                }
            }
        } else {
            var rng = seed.map { SeededGenerator(seed: $0) } ?? SeededGenerator()
            spies = Set(players.shuffled(using: &rng).prefix(spyCount).map { $0.id })
        }
    }

    // MARK: Round Lifecycle

    func startNewRound(roundIndex: Int = 0) {
        guard let category = config.selectedCategory else { return }
        assignSpiesRandomly()
        guard category.promptPairs.isEmpty == false else { return }

        // pick an unused prompt pair if possible
        let availableIndices = category.promptPairs.indices.filter { !usedPromptIndices.contains($0) }
        let pickIndex = availableIndices.randomElement() ?? category.promptPairs.indices.randomElement()!
        usedPromptIndices.insert(pickIndex)
        let pair = category.promptPairs[pickIndex]

        self.round = QuestionsRoundState(roundIndex: roundIndex, promptPair: pair, phase: .collecting, currentPlayerIndex: 0, answers: [:], votes: [:])
        self.phase = .collecting
    }

    func currentPlayer() -> Player? {
        guard let r = round else { return nil }
        guard players.indices.contains(r.currentPlayerIndex) else { return nil }
        return players[r.currentPlayerIndex]
    }

    func role(for playerID: UUID) -> QuestionsRole {
        spies.contains(playerID) ? .spy : .citizen
    }

    // Player submits an answer; returns true if accepted
    @discardableResult
    func submitAnswer(text: String, timeTaken: TimeInterval = 0) -> Bool {
        guard var r = round else { return false }
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        guard players.indices.contains(r.currentPlayerIndex) else { return false }
        let player = players[r.currentPlayerIndex]
        let answer = QuestionsAnswer(playerID: player.id, role: role(for: player.id), text: text, timeTaken: timeTaken)
        r.answers[player.id] = answer
        r.currentPlayerIndex += 1
        round = r

        // if all players answered, reveal phase
        if r.currentPlayerIndex >= players.count {
            revealCitizenQuestion()
        }
        return true
    }

    func revealCitizenQuestion() {
        guard var r = round else { return }
        r.phase = .revealed
        round = r
        phase = .revealed
    }

    func showOverview() {
        guard var r = round else { return }
        r.phase = .overview
        round = r
        phase = .overview
    }

    func startVoting() {
        guard var r = round else { return }
        r.phase = .voting
        r.currentPlayerIndex = 0
        r.votes = [:]
        round = r
        phase = .voting
    }

    // Current player casts a vote for a target player; returns true if accepted
    @discardableResult
    func castVote(targetID: UUID) -> Bool {
        guard var r = round else { return false }
        guard players.indices.contains(r.currentPlayerIndex) else { return false }
        let voter = players[r.currentPlayerIndex]
        // Prevent voting for self if desired; allow for now
        r.votes[voter.id] = targetID
        r.currentPlayerIndex += 1
        round = r
        // If all players voted, finish round
        if r.currentPlayerIndex >= players.count {
            finishRound()
        }
        return true
    }

    func voteTally() -> [(playerID: UUID, count: Int)] {
        guard let r = round else { return [] }
        var counts: [UUID: Int] = [:]
        for (_, target) in r.votes { counts[target, default: 0] += 1 }
        return players.map { ($0.id, counts[$0.id] ?? 0) }
            .sorted { lhs, rhs in lhs.count == rhs.count ? (playerName(for: lhs.playerID) < playerName(for: rhs.playerID)) : (lhs.count > rhs.count) }
    }

    private func playerName(for id: UUID) -> String {
        players.first(where: { $0.id == id })?.name ?? ""
    }

    func finishRound() {
        guard var r = round else { return }
        r.phase = .finished
        round = r
        phase = .finished
    }
}

// MARK: - Utility RNG

// A simple, deterministic RNG for testability
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64 = UInt64(Date().timeIntervalSince1970)) { self.state = seed &* 6364136223846793005 &+ 1 }
    mutating func next() -> UInt64 {
        state = state &* 2862933555777941757 &+ 3037000493
        return state
    }
}
