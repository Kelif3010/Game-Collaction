import Foundation

/// Spezialisierter Zufallsgenerator für das Question-Spiel.
final class QuestionLiarPicker {
    
    private struct WeightedCandidate {
        let id: UUID
        let effectiveWeight: Double
    }

    static func pickLiars(
        players: [UUID],
        count: Int,
        policy: QuestionFairnessPolicy,
        state: QuestionFairnessState
    ) -> [UUID] {
        guard count > 0, !players.isEmpty else { return [] }
        let desired = min(count, max(0, players.count - 1))
        if desired == 0 { return [] }
        
        var chosen: [UUID] = []
        let round = state.currentRound
        
        // Berechnung der Gewichte
        func computeWeight(for id: UUID) -> Double {
            let s = state.stats(for: id)
            var w = 1.0
            
            // Frequenz-Strafe (wer oft Lügner war, wird es seltener)
            w /= (1.0 + policy.alphaFrequencyPenalty * Double(max(0, s.timesLiar)))
            
            // Abstands-Bonus (wer lange nicht dran war, wird es eher)
            if s.lastPickedRound >= 0 {
                let d = max(0, round - s.lastPickedRound)
                w *= (1.0 + policy.betaDistanceBonus * Double(d))
            } else {
                w *= 1.15
            }
            
            // Cooldown Prüfung
            if s.cooldownUntilRound > round { w = 0 }
            if s.currentStreak >= policy.maxConsecutive { w = 0 }
            
            return max(w, 0.0001)
        }
        
        var pool = players
        while chosen.count < desired && !pool.isEmpty {
            let weighted = pool.map { id in
                WeightedCandidate(id: id, effectiveWeight: computeWeight(for: id))
            }.filter { $0.effectiveWeight > 0 }
            
            guard !weighted.isEmpty else { break }
            
            let total = weighted.reduce(0.0) { $0 + $1.effectiveWeight }
            var threshold = Double.random(in: 0...total)
            
            for candidate in weighted {
                if threshold <= candidate.effectiveWeight {
                    chosen.append(candidate.id)
                    pool.removeAll { $0 == candidate.id }
                    break
                }
                threshold -= candidate.effectiveWeight
            }
        }
        
        return chosen
    }
}
