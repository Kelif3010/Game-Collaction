import Foundation

/// Per-player fairness statistics persisted across rounds.
struct PlayerFairnessStats: Codable, Equatable {
    /// How many times this player has been an imposter in total.
    var timesImposter: Int = 0
    /// Current consecutive imposter streak.
    var currentStreak: Int = 0
    /// The round index when this player was last an imposter. Use -1 if never.
    var lastPickedRound: Int = -1
    /// Hard cooldown: until which round (exclusive) this player is not eligible.
    var cooldownUntilRound: Int = 0
    /// The round when the player joined the lobby/session.
    var joinRound: Int = 0
}

/// An unordered pair key for pair-history maps (A,B) == (B,A).
struct PairKey: Hashable, Codable {
    let a: UUID
    let b: UUID
    
    init(_ x: UUID, _ y: UUID) {
        if x.uuidString < y.uuidString {
            self.a = x; self.b = y
        } else {
            self.a = y; self.b = x
        }
    }
}

/// Global fairness state across rounds.
/// Stores per-player stats and last-round information for imposter pairs.
final class FairnessState: Codable {
    /// Current round index (increments after each completed round).
    var currentRound: Int = 0
    /// Per-player stats keyed by Player.id
    private(set) var perPlayer: [UUID: PlayerFairnessStats] = [:]
    /// Last round when a pair was imposters together.
    private(set) var pairLastRound: [PairKey: Int] = [:]
    
    init() {}
    
    /// Access or create stats for a given player id.
    func stats(for id: UUID) -> PlayerFairnessStats {
        perPlayer[id] ?? PlayerFairnessStats()
    }
    
    /// Mutate stats for a given player id.
    func updateStats(for id: UUID, _ mutate: (inout PlayerFairnessStats) -> Void) {
        var s = perPlayer[id] ?? PlayerFairnessStats()
        mutate(&s)
        perPlayer[id] = s
    }
    
    /// Record that a set of imposters were chosen in this round.
    func recordImposters(_ ids: [UUID]) {
        // Update per-player stats
        for id in ids {
            updateStats(for: id) { s in
                s.timesImposter += 1
                s.currentStreak += 1
                s.lastPickedRound = currentRound
                // Apply hard cooldown: set externally based on policy after selection if desired
            }
        }
        // Reset streaks for non-imposters is done by caller (requires full player list)
        // Record pairs
        for i in 0..<ids.count {
            for j in (i+1)..<ids.count {
                let key = PairKey(ids[i], ids[j])
                pairLastRound[key] = currentRound
            }
        }
    }
    
    /// Advance to next round (should be called once per completed round).
    func advanceRound() {
        currentRound += 1
    }
}
