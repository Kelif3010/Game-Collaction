import Foundation

/// Central configuration for fairness-aware imposter selection.
/// Encapsulates hard constraints and soft weighting parameters.
struct FairnessPolicy {
    // MARK: - Hard constraints
    /// Maximum times a player can be imposter in a row.
    var maxConsecutive: Int = 2
    /// Minimum number of full rounds a player must wait after being imposter.
    var minCooldownRounds: Int = 1
    
    // MARK: - Recency windows
    /// Window (in rounds) where recent imposters are penalized more strongly.
    var recentWindow: Int = 5
    /// Window (in rounds) for penalizing recently paired imposters (team diversity).
    var pairRecentWindow: Int = 5
    
    // MARK: - Soft weighting parameters
    /// Frequency penalty: higher reduces weight for players often chosen as imposter.
    var alphaFrequencyPenalty: Double = 0.4
    /// Distance/recency bonus per round since last imposter.
    var betaDistanceBonus: Double = 0.1
    /// Base pair/team penalty multiplier.
    var gammaPairPenalty: Double = 1.0
    /// Exponential decay for pair penalties per round since last pairing.
    var pairPenaltyDecay: Double = 0.7
    
    // MARK: - New player integration
    /// Hard cooldown rounds after a player joins; during this time they cannot be imposter.
    var newPlayerHardCooldownRounds: Int = 1
    /// Soft penalty rounds after hard cooldown; player can be picked but with lower weight.
    var newPlayerSoftPenaltyRounds: Int = 3
    /// Weight factor applied during soft penalty period (0 < factor <= 1).
    var newPlayerPenaltyFactor: Double = 0.3
    
    // MARK: - Weight jitter (anti-pattern)
    /// Random jitter range (+/-) applied to effective weights to avoid deterministic patterns.
    var jitterPercent: Double = 0.05 // 5%
    
    /// Default policy with balanced parameters.
    static let `default` = FairnessPolicy()
    
    /// Custom initializer
    init(
        maxConsecutive: Int = 2,
        minCooldownRounds: Int = 1,
        recentWindow: Int = 5,
        pairRecentWindow: Int = 5,
        alphaFrequencyPenalty: Double = 0.4,
        betaDistanceBonus: Double = 0.1,
        gammaPairPenalty: Double = 1.0,
        pairPenaltyDecay: Double = 0.7,
        newPlayerHardCooldownRounds: Int = 1,
        newPlayerSoftPenaltyRounds: Int = 3,
        newPlayerPenaltyFactor: Double = 0.3,
        jitterPercent: Double = 0.05
    ) {
        self.maxConsecutive = maxConsecutive
        self.minCooldownRounds = minCooldownRounds
        self.recentWindow = recentWindow
        self.pairRecentWindow = pairRecentWindow
        self.alphaFrequencyPenalty = alphaFrequencyPenalty
        self.betaDistanceBonus = betaDistanceBonus
        self.gammaPairPenalty = gammaPairPenalty
        self.pairPenaltyDecay = pairPenaltyDecay
        self.newPlayerHardCooldownRounds = newPlayerHardCooldownRounds
        self.newPlayerSoftPenaltyRounds = newPlayerSoftPenaltyRounds
        self.newPlayerPenaltyFactor = newPlayerPenaltyFactor
        self.jitterPercent = jitterPercent
    }
}
