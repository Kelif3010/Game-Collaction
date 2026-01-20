import Foundation

public struct QuestionsVoteEvaluation: Codable, Hashable {
    public let selected: Set<UUID>
    public let liars: Set<UUID>
    public let correct: Set<UUID>
    public let incorrect: Set<UUID>
    public let citizensWon: Bool

    public init(selected: Set<UUID>, liars: Set<UUID>) {
        self.selected = selected
        self.liars = liars
        self.correct = selected.intersection(liars)
        self.incorrect = selected.subtracting(liars)
        self.citizensWon = selected == liars
    }
}

public enum QuestionsVotingOutcome: String, Codable, Hashable {
    case citizensWin
    case liarsWin
}

public extension QuestionsVoteEvaluation {
    var outcome: QuestionsVotingOutcome {
        citizensWon ? .citizensWin : .liarsWin
    }
}
