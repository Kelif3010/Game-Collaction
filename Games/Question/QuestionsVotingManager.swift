import Foundation
import Combine

public final class QuestionsVotingManager: ObservableObject {
    @Published public private(set) var selected: Set<UUID> = []
    @Published public private(set) var isActive: Bool = false
    @Published public private(set) var hasResults: Bool = false
    @Published public private(set) var evaluation: QuestionsVoteEvaluation? = nil
    
    private let players: [UUID]
    private let imposters: Set<UUID>
    private let requiredSelections: Int
    
    public init(players: [UUID], imposters: Set<UUID>) {
        self.players = players
        self.imposters = imposters
        self.requiredSelections = imposters.count
    }
    
    public func start() {
        isActive = true
        hasResults = false
        selected.removeAll()
        evaluation = nil
    }
    
    public var canSelectMore: Bool {
        selected.count < requiredSelections
    }
    
    public var canConfirm: Bool {
        selected.count == requiredSelections
    }
    
    public func toggle(_ id: UUID) {
        guard isActive, players.contains(id) else { return }
        if selected.contains(id) {
            selected.remove(id)
        } else if canSelectMore {
            selected.insert(id)
        }
    }
    
    @discardableResult
    public func confirm() -> QuestionsVoteEvaluation? {
        guard canConfirm else { return nil }
        let result = QuestionsVoteEvaluation(selected: selected, imposters: imposters)
        evaluation = result
        isActive = false
        hasResults = true
        return result
    }
    
    public func reset() {
        selected.removeAll()
        isActive = false
        hasResults = false
        evaluation = nil
    }
    
    public var resultText: String {
        guard let evaluation = evaluation else { return "" }
        return evaluation.citizensWon ? "Bewohner haben gewonnen" : "Imposter haben gewonnen"
    }
}
