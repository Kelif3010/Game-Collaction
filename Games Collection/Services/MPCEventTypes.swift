import Foundation

// MARK: - MPC Event Types
// Global definition of event types used across different games
public enum MPCEventType {
    // Global Lobby Events
    static let lobbyUpdate = "LOBBY_UPDATE"
    static let gameStart = "GAME_START"
    static let gameAbort = "GAME_ABORT"
    
    // Imposter Specific Events
    static let imposterRoleAssignment = "IMPOSTER_ROLE_ASSIGNMENT" // Payload: ImposterRolePayload
    static let imposterSyncConfig = "IMPOSTER_SYNC_CONFIG" // Payload: ImposterGameConfig
    static let imposterTimerSync = "IMPOSTER_TIMER_SYNC" // Payload: TimeInterval (or Int)
    static let imposterGameOver = "IMPOSTER_GAME_OVER"
    static let imposterCardSeen = "IMPOSTER_CARD_SEEN" // Payload: ImposterCardSeenPayload
    static let imposterRevealStart = "IMPOSTER_REVEAL_START" // No Payload
    static let imposterRevealProgress = "IMPOSTER_REVEAL_PROGRESS" // Payload: ImposterRevealProgressPayload
    static let imposterHostActivity = "IMPOSTER_HOST_ACTIVITY" // Payload: ImposterHostActivityPayload
    
    // Time Sync Events
    static let imposterTimeSyncPing = "IMPOSTER_TIME_SYNC_PING"
    static let imposterTimeSyncPong = "IMPOSTER_TIME_SYNC_PONG"
    
    // Voting Specific Events
    static let imposterStartVoting = "IMPOSTER_START_VOTING" // Payload: ImposterVotingStatusPayload (optional)
    static let imposterVotePreview = "IMPOSTER_VOTE_PREVIEW" // Payload: ImposterVotePreviewPayload
    static let imposterVoteCast = "IMPOSTER_VOTE_CAST" // Payload: ImposterVoteCastPayload
    static let imposterVotingStatus = "IMPOSTER_VOTING_STATUS" // Payload: ImposterVotingStatusPayload
    static let imposterVotingResult = "IMPOSTER_VOTING_RESULT" // Payload: ImposterVotingResultPayload

    // Word Guess Events
    static let imposterWordGuessConfirmed = "IMPOSTER_WORD_GUESS_CONFIRMED" // Payload: ImposterWordGuessResultPayload
}
