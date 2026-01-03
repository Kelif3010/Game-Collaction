import Foundation

struct SimulationResult {
    let rounds: Int
    let players: [UUID: String]
    let timesImposter: [UUID: Int]
    let maxConsecutive: Int
    let pairRepeatCount: Int
}

/// A simple Xorshift64* random number generator conforming to RandomNumberGeneratorLike.
/// This RNG is deterministic for a given seed.
private struct Xorshift64Star: RandomNumberGeneratorLike {
    private var state: UInt64

    init(seed: UInt64) {
        // Avoid zero seed which causes degenerate output
        self.state = seed == 0 ? 0xdeadbeefcafebabe : seed
    }

    mutating func next() -> UInt64 {
        var x = state
        x ^= x >> 12
        x ^= x << 25
        x ^= x >> 27
        state = x
        return x &* 2685821657736338717
    }
}

/// Adapter to allow using RandomNumberGeneratorLike with ImposterPicker
private struct RNGAdapter: RandomNumberGeneratorLike {
    private var base: Xorshift64Star

    init(seed: UInt64) {
        self.base = Xorshift64Star(seed: seed)
    }

    mutating func next() -> UInt64 {
        base.next()
    }
}

/// Simulator class providing static method to run fairness simulations quickly without UI.
final class FairnessSimulator {
    /// Runs the fairness simulation with the specified parameters.
    /// - Parameters:
    ///   - playerNames: An array of player names.
    ///   - impostersPerRound: Number of imposters per round.
    ///   - rounds: Number of rounds to simulate.
    ///   - policy: The fairness policy to apply.
    ///   - seed: Optional seed for deterministic RNG.
    /// - Returns: A SimulationResult summarizing the simulation outcomes.
    static func runSimulation(
        playerNames: [String],
        impostersPerRound: Int,
        rounds: Int,
        policy: FairnessPolicy,
        seed: UInt64? = nil
    ) -> SimulationResult {
        // Defensive: Clamp impostersPerRound to valid range
        let impostersCount = max(0, min(impostersPerRound, playerNames.count))
        let totalRounds = max(0, rounds)

        // Create players with fake UUIDs mapped to names
        var players: [UUID: String] = [:]
        for name in playerNames {
            players[UUID()] = name
        }
        let playerIDs = Array(players.keys)

        // Initialize FairnessState and set all joinRounds to 0
        let fairnessState = FairnessState()
        for id in playerIDs {
            fairnessState.updateStats(for: id) { s in
                s.joinRound = 0
            }
        }
            

        // RNG setup: deterministic if seed provided, else random seed from system
        let rngSeed: UInt64 = seed ?? {
            var sysRNG = SystemRandomNumberGenerator()
            return UInt64.random(in: UInt64.min...UInt64.max, using: &sysRNG)
        }()
        var rng: any RandomNumberGeneratorLike = RNGAdapter(seed: rngSeed)

        // Tracking variables
        var timesImposter: [UUID: Int] = [:]
        for id in playerIDs {
            timesImposter[id] = 0
        }
        var maxConsecutive: Int = 0
        var pairRepeatCount = 0

        // Simulation of rounds
        for currentRound in 0..<totalRounds {
            // Pick imposters deterministically for current round
            let picked = ImposterPicker.pickImposters(
                players: playerIDs,
                count: impostersCount,
                policy: policy,
                state: fairnessState,
                rng: &rng
            )

            // Defensive: If picked count differs from impostersCount, skip round
            if picked.count != impostersCount {
                // Still advance round but do not record counts for this invalid pick
                fairnessState.advanceRound()
                continue
            }

            // Record imposters in fairnessState
            fairnessState.recordImposters(picked)

            // Apply hard cooldowns for picked and reset streaks for non-picked
            let round = fairnessState.currentRound
            let pickedSet = Set(picked)
            for id in picked {
                fairnessState.updateStats(for: id) { s in
                    s.cooldownUntilRound = round + policy.minCooldownRounds
                }
            }
            for id in playerIDs where !pickedSet.contains(id) {
                fairnessState.updateStats(for: id) { s in
                    if s.currentStreak > 0 { s.currentStreak = 0 }
                }
            }

            // Update max consecutive streak globally and timesImposter for picked
            for id in picked {
                let stats = fairnessState.stats(for: id)
                maxConsecutive = max(maxConsecutive, stats.currentStreak)
                timesImposter[id, default: 0] += 1
            }

            // Track pair repeats within recent window
            // Only consider pairs if impostersPerRound >= 2
            if impostersCount >= 2 {
                // Generate all pairs from picked imposters (sorted for uniqueness)
                let pickedArray = Array(picked)
                for i in 0..<(pickedArray.count - 1) {
                    for j in (i + 1)..<pickedArray.count {
                        let pairKey = PairKey(pickedArray[i], pickedArray[j])
                        if let lastRoundPicked = fairnessState.pairLastRound[pairKey] {
                            let roundsSince = currentRound - lastRoundPicked
                            if roundsSince <= policy.pairRecentWindow {
                                pairRepeatCount += 1
                            }
                        }
                    }
                }
            }

            // Advance to next round inside fairnessState
            fairnessState.advanceRound()
        }

        return SimulationResult(
            rounds: totalRounds,
            players: players,
            timesImposter: timesImposter,
            maxConsecutive: maxConsecutive,
            pairRepeatCount: pairRepeatCount
        )
    }
}

