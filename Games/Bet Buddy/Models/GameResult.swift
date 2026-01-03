import Foundation

struct GameResult: Hashable {
    enum Outcome: String, Hashable {
        case win
        case lose
    }

    let outcome: Outcome
    let finalScore: Int
    let challengeText: String
    // NEU: Damit wir wissen, ob wir A, B, C oder 1, 2, 3 anzeigen sollen
    let inputType: ChallengeInputType
    let leaderboard: [LeaderboardEntry]
}
