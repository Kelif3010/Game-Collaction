import Foundation

public struct QuestionsVoteEvaluation: Codable, Hashable {
    public let selected: Set<UUID>
    public let imposters: Set<UUID>
    public let correct: Set<UUID>
    public let incorrect: Set<UUID>
    public let citizensWon: Bool

    public init(selected: Set<UUID>, imposters: Set<UUID>) {
        self.selected = selected
        self.imposters = imposters
        self.correct = selected.intersection(imposters)
        self.incorrect = selected.subtracting(imposters)
        self.citizensWon = selected == imposters
    }
}

public enum QuestionsVotingOutcome: String, Codable, Hashable {
    case citizensWin
    case impostersWin
}

public extension QuestionsVoteEvaluation {
    var outcome: QuestionsVotingOutcome {
        citizensWon ? .citizensWin : .impostersWin
    }
}
