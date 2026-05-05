import SwiftUI
import Combine

@MainActor
final class AppRouter: ObservableObject {
    @Published var isBetBuddyPresented = false
    @Published var isTimesUpPresented = false
    @Published var isQuestionGamePresented = false
    @Published var isImposterPresented = false
    @Published var isSoundCinemaPresented = false
    @Published var isFalscheFaehrtePresented = false
    @Published var isPartyPresented = false
    @Published var showSettings = false
    @Published var showRecommender = false

    func openGame(for action: QuickActionType) {
        isBetBuddyPresented = false
        isTimesUpPresented = false
        isQuestionGamePresented = false
        isImposterPresented = false
        isSoundCinemaPresented = false
        isFalscheFaehrtePresented = false

        switch action {
        case .betBuddy:
            GlobalStatsManager.shared.markGameAsPlayed(action.gameId)
            isBetBuddyPresented = true
        case .timesUp:
            GlobalStatsManager.shared.markGameAsPlayed(action.gameId)
            isTimesUpPresented = true
        case .question:
            GlobalStatsManager.shared.markGameAsPlayed(action.gameId)
            isQuestionGamePresented = true
        case .imposter:
            GlobalStatsManager.shared.markGameAsPlayed(action.gameId)
            isImposterPresented = true
        case .soundCinema:
            GlobalStatsManager.shared.markGameAsPlayed(action.gameId)
            isSoundCinemaPresented = true
        case .falscheFaehrte:
            isFalscheFaehrtePresented = true
        }
    }
}
