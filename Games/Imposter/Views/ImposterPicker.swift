import Foundation

/// Simple protocol so we can inject a deterministic RNG in tests.
protocol RandomNumberGeneratorLike {
    mutating func next() -> UInt64
}

/// Adapter to use SystemRandomNumberGenerator with our protocol.
struct SystemRNGAdapter: RandomNumberGeneratorLike {
    private var rng = SystemRandomNumberGenerator()
    mutating func next() -> UInt64 { rng.next() }
}

/// Candidate with computed weights.
private struct WeightedCandidate {
    let id: UUID
    let baseWeight: Double
    let effectiveWeight: Double
}

final class ImposterPicker {
    struct CandidateDebug: Identifiable {
        let id: UUID
        let baseWeight: Double
        let teamPenalty: Double
        let effectiveWeight: Double
    }

    /// Picks a fairness-aware set of imposters.
    /// - Parameters:
    ///   - players: All player IDs in the round.
    ///   - count: Number of imposters to pick.
    ///   - policy: Fairness policy parameters.
    ///   - state: Mutable fairness state (read for weights; caller updates after selection).
    ///   - rng: Random generator (injectable for tests).
    /// - Returns: Array of selected imposter IDs (may be smaller than count if impossible without violating hard rules).
    static func pickImposters(
        players: [UUID],
        count: Int,
        policy: FairnessPolicy,
        state: FairnessState,
        rng: inout any RandomNumberGeneratorLike,
        weightMultipliers: [UUID: Double] = [:]
    ) -> [UUID] {
        print("🎯 ImposterPicker.pickImposters() aufgerufen")
        print("👥 Spieler: \(players.count), gewünschte Spione: \(count)")
        
        guard count > 0, !players.isEmpty else { 
            print("❌ ImposterPicker: count=\(count), players.isEmpty=\(players.isEmpty)")
            return [] 
        }
        // Never pick all players as imposters, must leave at least one non-imposter
        let desired = min(count, max(0, players.count - 1))
        print("🎯 Gewünschte Spione: \(desired)")
        if desired == 0 { 
            print("❌ ImposterPicker: desired=0")
            return [] 
        }
        
        var chosen: [UUID] = []
        var hardExcluded = Set<UUID>()
        let round = state.currentRound
        
        // Step 1: Compute hard exclusions based on maxConsecutive, cooldown, and new player hard cooldown
        print("🔍 Prüfe hard exclusions...")
        for id in players {
            let s = state.stats(for: id)
            let consecutiveCap = s.currentStreak >= policy.maxConsecutive
            let cooldownCap = s.cooldownUntilRound > round
            let newPlayerHard = (round < s.joinRound + policy.newPlayerHardCooldownRounds)
            print("👤 Spieler \(id): consecutiveCap=\(consecutiveCap), cooldownCap=\(cooldownCap), newPlayerHard=\(newPlayerHard)")
            if consecutiveCap || cooldownCap || newPlayerHard {
                hardExcluded.insert(id)
                print("❌ Spieler \(id) hard excluded")
            }
        }
        print("🚫 Hard excluded: \(hardExcluded.count) Spieler")
        
        // Helper to compute base weight for a player (without team penalty)
        func baseWeight(for id: UUID, ignoreRecentWindow: Bool = false) -> Double {
            let s = state.stats(for: id)
            var w = 1.0
            var debugInfo = "Spieler \(id): "
            
            // Frequency penalty: more times imposter reduces weight
            let freqPenalty = policy.alphaFrequencyPenalty * Double(max(0, s.timesImposter))
            w /= (1.0 + freqPenalty)
            debugInfo += "freq=\(s.timesImposter), streak=\(s.currentStreak), "
            
            // Distance bonus: if last picked long ago, increase chance
            let last = s.lastPickedRound
            if last >= 0 {
                let d = max(0, round - last)
                let distanceBonus = policy.betaDistanceBonus * Double(d)
                w *= (1.0 + distanceBonus)
                debugInfo += "lastRound=\(last), distance=\(d), "
            } else {
                // Never picked before → small bonus to integrate gradually but not dominate
                w *= 1.15
                debugInfo += "neverPicked, "
            }
            
            // Recent window penalty (soft)
            if !ignoreRecentWindow {
                if s.lastPickedRound >= 0, (round - s.lastPickedRound) <= policy.recentWindow {
                    w *= 0.5
                    debugInfo += "recentPenalty, "
                }
            }
            
            // New player soft penalty (only if outside hard cooldown)
            if round < s.joinRound + policy.newPlayerHardCooldownRounds + policy.newPlayerSoftPenaltyRounds {
                if round >= s.joinRound + policy.newPlayerHardCooldownRounds {
                    let newPlayerPenalty = max(0.0, min(1.0, policy.newPlayerPenaltyFactor))
                    w *= newPlayerPenalty
                    debugInfo += "newPlayerPenalty=\(newPlayerPenalty), "
                }
            }
            // KI-Tuning anwenden (Multiplikator)
            if let m = weightMultipliers[id], m > 0 {
                w *= m
                debugInfo += "multiplier=\(String(format: "%.2f", m)), "
            }
            let finalWeight = max(w, 0.0001)
            debugInfo += "finalWeight=\(String(format: "%.3f", finalWeight))"
            print("⚖️ \(debugInfo)")
            
            return finalWeight
        }
        
        // Helper for pair penalty based on already chosen team members
        func teamPenalty(for candidate: UUID, with team: [UUID]) -> Double {
            guard !team.isEmpty else { return 0.0 }
            var penalty = 0.0
            for mate in team {
                let key = PairKey(candidate, mate)
                if let last = state.pairLastRound[key] {
                    let d = max(0, round - last)
                    if d <= policy.pairRecentWindow {
                        penalty += policy.gammaPairPenalty * exp(-policy.pairPenaltyDecay * Double(d))
                    }
                }
            }
            return penalty
        }
        
        // Weighted sampling without replacement function
        func pickOne(
            from pool: [UUID],
            ignoreTeamPenalty: Bool = false,
            ignoreRecentWindowPenalty: Bool = false
        ) -> UUID? {
            var weighted: [WeightedCandidate] = []
            weighted.reserveCapacity(pool.count)
            for id in pool {
                let w = baseWeight(for: id, ignoreRecentWindow: ignoreRecentWindowPenalty)
                let tp = ignoreTeamPenalty ? 0.0 : teamPenalty(for: id, with: chosen)
                var eff = w / (1.0 + tp)
                // Apply jitter if configured
                if policy.jitterPercent > 0 {
                    let j = policy.jitterPercent
                    let r = Double(rng.next() % 10_000) / 10_000.0 // [0, 0.9999]
                    let scale = (1.0 - j) + (2.0 * j) * r
                    eff *= scale
                }
                weighted.append(WeightedCandidate(id: id, baseWeight: w, effectiveWeight: max(eff, 0.0001)))
            }
            
            let total = weighted.reduce(0.0) { $0 + $1.effectiveWeight }
            guard total > 0 else { return pool.randomElement() }
            
            var threshold = Double(rng.next() % UInt64.max) / Double(UInt64.max) * total
            for c in weighted {
                if threshold <= c.effectiveWeight { return c.id }
                threshold -= c.effectiveWeight
            }
            return weighted.last?.id
        }
        
        // Create initial pool of candidates excluding hard-excluded players
        var pool = players.filter { !hardExcluded.contains($0) }
        print("🏊 Initial pool: \(pool.count) Spieler verfügbar")
        
        // Flags to track soft constraint relaxation
        var relaxedPairPenalty = false
        var relaxedRecentWindow = false
        
        // Iteratively pick imposters until desired count or no candidates left
        while chosen.count < desired {
            print("🔄 While-Schleife: chosen=\(chosen.count), desired=\(desired), pool=\(pool.count)")
            if pool.isEmpty {
                // Try progressively relaxing soft constraints
                
                if !relaxedPairPenalty {
                    // Relax pair penalty by ignoring it
                    relaxedPairPenalty = true
                    // Rebuild pool excluding hard-excluded and already chosen
                    pool = players.filter { !hardExcluded.contains($0) && !chosen.contains($0) }
                } else if !relaxedRecentWindow {
                    // Relax recent window penalty by ignoring it
                    relaxedRecentWindow = true
                    pool = players.filter { !hardExcluded.contains($0) && !chosen.contains($0) }
                } else {
                    // As last resort, pick from remaining non-hard excluded players even if pool empty before
                    pool = players.filter { !hardExcluded.contains($0) && !chosen.contains($0) }
                    if pool.isEmpty { break }
                }
            }
            
            // Pick one with relaxed soft penalties as needed
            let next: UUID?
            if relaxedPairPenalty && relaxedRecentWindow {
                // Ignore both penalties
                next = pickOne(from: pool, ignoreTeamPenalty: true, ignoreRecentWindowPenalty: true)
            } else if relaxedPairPenalty {
                // Ignore pair penalty only
                next = pickOne(from: pool, ignoreTeamPenalty: true, ignoreRecentWindowPenalty: false)
            } else if relaxedRecentWindow {
                // Ignore recent window penalty only
                next = pickOne(from: pool, ignoreTeamPenalty: false, ignoreRecentWindowPenalty: true)
            } else {
                // No soft constraint relaxed
                next = pickOne(from: pool, ignoreTeamPenalty: false, ignoreRecentWindowPenalty: false)
            }
            
            guard let picked = next else { break }
            chosen.append(picked)
            pool.removeAll { $0 == picked }
        }
        
        print("✅ ImposterPicker abgeschlossen: \(chosen.count) Spione ausgewählt")
        print("🕵️ Ausgewählte Spione: \(chosen)")
        return chosen
    }

    static func pickImpostersDebug(
        players: [UUID],
        count: Int,
        policy: FairnessPolicy,
        state: FairnessState,
        rng: inout any RandomNumberGeneratorLike
    ) -> (picked: [UUID], steps: [[CandidateDebug]]) {
        var steps: [[CandidateDebug]] = []
        guard count > 0, !players.isEmpty else { return ([], steps) }
        // Never pick all players as imposters, must leave at least one non-imposter
        let desired = min(count, max(0, players.count - 1))
        if desired == 0 { return ([], steps) }

        var chosen: [UUID] = []
        var hardExcluded = Set<UUID>()
        let round = state.currentRound

        // Step 1: Compute hard exclusions based on maxConsecutive, cooldown, and new player hard cooldown
        for id in players {
            let s = state.stats(for: id)
            let consecutiveCap = s.currentStreak >= policy.maxConsecutive
            let cooldownCap = s.cooldownUntilRound > round
            let newPlayerHard = (round < s.joinRound + policy.newPlayerHardCooldownRounds)
            if consecutiveCap || cooldownCap || newPlayerHard {
                hardExcluded.insert(id)
            }
        }

        // Helper to compute base weight for a player (without team penalty)
        func baseWeight(for id: UUID, ignoreRecentWindow: Bool = false) -> Double {
            let s = state.stats(for: id)
            var w = 1.0
            // Frequency penalty: more times imposter reduces weight
            w /= (1.0 + policy.alphaFrequencyPenalty * Double(max(0, s.timesImposter)))
            // Distance bonus: if last picked long ago, increase chance
            let last = s.lastPickedRound
            if last >= 0 {
                let d = max(0, round - last)
                w *= (1.0 + policy.betaDistanceBonus * Double(d))
            } else {
                // Never picked before → small bonus to integrate gradually but not dominate
                w *= 1.15
            }
            // Recent window penalty (soft)
            if !ignoreRecentWindow {
                if s.lastPickedRound >= 0, (round - s.lastPickedRound) <= policy.recentWindow {
                    w *= 0.5
                }
            }
            // New player soft penalty (only if outside hard cooldown)
            if round < s.joinRound + policy.newPlayerHardCooldownRounds + policy.newPlayerSoftPenaltyRounds {
                if round >= s.joinRound + policy.newPlayerHardCooldownRounds {
                    w *= max(0.0, min(1.0, policy.newPlayerPenaltyFactor))
                }
            }
            // Debug-Variante: kein KI-Tuning anwenden
            return max(w, 0.0001) // avoid zero weights
        }

        // Helper for pair penalty based on already chosen team members
        func teamPenalty(for candidate: UUID, with team: [UUID]) -> Double {
            guard !team.isEmpty else { return 0.0 }
            var penalty = 0.0
            for mate in team {
                let key = PairKey(candidate, mate)
                if let last = state.pairLastRound[key] {
                    let d = max(0, round - last)
                    if d <= policy.pairRecentWindow {
                        penalty += policy.gammaPairPenalty * exp(-policy.pairPenaltyDecay * Double(d))
                    }
                }
            }
            return penalty
        }

        // Weighted sampling without replacement function with debug output
        func pickOneDebug(
            from pool: [UUID],
            ignoreTeamPenalty: Bool = false,
            ignoreRecentWindowPenalty: Bool = false
        ) -> (UUID?, [CandidateDebug]) {
            var weightedDebug: [CandidateDebug] = []
            weightedDebug.reserveCapacity(pool.count)
            for id in pool {
                let w = baseWeight(for: id, ignoreRecentWindow: ignoreRecentWindowPenalty)
                let tp = ignoreTeamPenalty ? 0.0 : teamPenalty(for: id, with: chosen)
                var eff = w / (1.0 + tp)
                // Apply jitter if configured
                if policy.jitterPercent > 0 {
                    let j = policy.jitterPercent
                    let r = Double(rng.next() % 10_000) / 10_000.0 // [0, 0.9999]
                    let scale = (1.0 - j) + (2.0 * j) * r
                    eff *= scale
                }
                weightedDebug.append(CandidateDebug(id: id, baseWeight: w, teamPenalty: tp, effectiveWeight: max(eff, 0.0001)))
            }
            
            let total = weightedDebug.reduce(0.0) { $0 + $1.effectiveWeight }
            if total <= 0 {
                // If total weight zero or less, pick a random candidate if possible
                return (pool.randomElement(), weightedDebug)
            }
            
            var threshold = Double(rng.next() % UInt64.max) / Double(UInt64.max) * total
            for c in weightedDebug {
                if threshold <= c.effectiveWeight { return (c.id, weightedDebug) }
                threshold -= c.effectiveWeight
            }
            return (weightedDebug.last?.id, weightedDebug)
        }

        // Create initial pool of candidates excluding hard-excluded players
        var pool = players.filter { !hardExcluded.contains($0) }

        // Flags to track soft constraint relaxation
        var relaxedPairPenalty = false
        var relaxedRecentWindow = false

        // Iteratively pick imposters until desired count or no candidates left
        while chosen.count < desired {
            if pool.isEmpty {
                // Try progressively relaxing soft constraints
                
                if !relaxedPairPenalty {
                    // Relax pair penalty by ignoring it
                    relaxedPairPenalty = true
                    // Rebuild pool excluding hard-excluded and already chosen
                    pool = players.filter { !hardExcluded.contains($0) && !chosen.contains($0) }
                } else if !relaxedRecentWindow {
                    // Relax recent window penalty by ignoring it
                    relaxedRecentWindow = true
                    pool = players.filter { !hardExcluded.contains($0) && !chosen.contains($0) }
                } else {
                    // As last resort, pick from remaining non-hard excluded players even if pool empty before
                    pool = players.filter { !hardExcluded.contains($0) && !chosen.contains($0) }
                    if pool.isEmpty { break }
                }
            }

            // Pick one with relaxed soft penalties as needed
            let (next, debugCandidates): (UUID?, [CandidateDebug])
            if relaxedPairPenalty && relaxedRecentWindow {
                // Ignore both penalties
                (next, debugCandidates) = pickOneDebug(from: pool, ignoreTeamPenalty: true, ignoreRecentWindowPenalty: true)
            } else if relaxedPairPenalty {
                // Ignore pair penalty only
                (next, debugCandidates) = pickOneDebug(from: pool, ignoreTeamPenalty: true, ignoreRecentWindowPenalty: false)
            } else if relaxedRecentWindow {
                // Ignore recent window penalty only
                (next, debugCandidates) = pickOneDebug(from: pool, ignoreTeamPenalty: false, ignoreRecentWindowPenalty: true)
            } else {
                // No soft constraint relaxed
                (next, debugCandidates) = pickOneDebug(from: pool, ignoreTeamPenalty: false, ignoreRecentWindowPenalty: false)
            }

            steps.append(debugCandidates)
            
            guard let picked = next else { break }
            chosen.append(picked)
            pool.removeAll { $0 == picked }
        }

        return (chosen, steps)
    }
}
