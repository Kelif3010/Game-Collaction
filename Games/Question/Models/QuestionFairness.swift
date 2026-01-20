import Foundation

/// Statistiken pro Spieler für die Fairness-Berechnung.
struct QuestionPlayerFairnessStats: Codable, Equatable {
    var timesLiar: Int = 0
    var currentStreak: Int = 0
    var lastPickedRound: Int = -1
    var cooldownUntilRound: Int = 0
    var joinRound: Int = 0
}

struct QuestionPairKey: Hashable, Codable {
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

/// Speichert die Regeln für die faire Auswahl der Lügner.
struct QuestionFairnessPolicy: Codable {
    var maxConsecutive: Int = 2
    var minCooldownRounds: Int = 1
    var recentWindow: Int = 3
    var alphaFrequencyPenalty: Double = 0.6
    var betaDistanceBonus: Double = 0.2
    var newPlayerHardCooldownRounds: Int = 0
    var newPlayerSoftPenaltyRounds: Int = 2
    var newPlayerPenaltyFactor: Double = 0.4
}

/// Globaler Fairness-Status für das Question-Spiel.
final class QuestionFairnessState: Codable {
    var currentRound: Int = 0
    private(set) var perPlayer: [UUID: QuestionPlayerFairnessStats] = [:]
    private(set) var pairLastRound: [QuestionPairKey: Int] = [:]
    
    init() {}
    
    func stats(for id: UUID) -> QuestionPlayerFairnessStats {
        perPlayer[id] ?? QuestionPlayerFairnessStats()
    }
    
    func updateStats(for id: UUID, _ mutate: (inout QuestionPlayerFairnessStats) -> Void) {
        var s = perPlayer[id] ?? QuestionPlayerFairnessStats()
        mutate(&s)
        perPlayer[id] = s
    }
    
    func recordLiars(_ ids: [UUID]) {
        for id in ids {
            updateStats(for: id) { s in
                s.timesLiar += 1
                s.currentStreak += 1
                s.lastPickedRound = currentRound
            }
        }
        for i in 0..<ids.count {
            for j in (i+1)..<ids.count {
                let key = QuestionPairKey(ids[i], ids[j])
                pairLastRound[key] = currentRound
            }
        }
    }
    
    func advanceRound() {
        currentRound += 1
    }
}
