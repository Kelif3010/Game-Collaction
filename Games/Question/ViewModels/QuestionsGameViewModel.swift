import SwiftUI
import Combine

/// Adapter view model for the TV board, backed by the current Questions engine + app model.
final class QuestionsGameViewModel: ObservableObject {
    let appModel: AppModel
    let engine: QuestionsEngine

    @Published var selectedCategory: QuestionsCategory? = nil
    @Published var discussionTime: TimeInterval = 0
    @Published var timeRemaining: TimeInterval = 0
    @Published var isRevealVoteActive = false
    @Published var voteCounts: [UUID: Int] = [:]
    @Published var revealEvaluation: QuestionsVoteEvaluation? = nil
    @Published var lastRevealEvaluation: QuestionsVoteEvaluation? = nil

    private var cancellables = Set<AnyCancellable>()

    init(appModel: AppModel, engine: QuestionsEngine) {
        self.appModel = appModel
        self.engine = engine

        // Forward changes so the TV board redraws on engine/app updates.
        engine.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)

        appModel.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }

    var currentPhase: QuestionsPhase { engine.phase }
    var currentRound: QuestionsRoundState? { engine.round }
    var playerCount: Int { appModel.players.count }
    var currentLiarIDs: Set<UUID> { engine.currentLiarIDs }

    // Keep legacy naming used by TV board (spies -> liars).
    var currentSpyIDs: Set<UUID> { engine.currentLiarIDs }

    var answersInOrder: [QuestionsAnswer] {
        guard let answersDict = engine.round?.answers else { return [] }
        return appModel.players.compactMap { answersDict[$0.id] }
    }

    func currentPlayer() -> QuestionPlayer? {
        engine.currentPlayer()
    }

    func playerName(for id: UUID) -> String {
        appModel.players.first(where: { $0.id == id })?.name ?? "Unbekannt"
    }

    func timeString(from time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
