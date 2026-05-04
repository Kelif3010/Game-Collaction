import Foundation

// MARK: - MPC Event Types
// Global definition of event types used across different games
public enum MPCEventType {
    // Global Lobby Events
    static let lobbyUpdate = "LOBBY_UPDATE"
    static let lobbyStateSync = "LOBBY_STATE_SYNC"
    static let lobbyDisconnected = "LOBBY_DISCONNECTED"
    static let playerReadyUpdate = "PLAYER_READY_UPDATE"
    static let gameStart = "GAME_START"
    static let gameAbort = "GAME_ABORT"
    
    // Imposter Specific Events
    static let imposterRoleAssignment = "IMPOSTER_ROLE_ASSIGNMENT" // Payload: ImposterRolePayload
    static let imposterRoleAck = "IMPOSTER_ROLE_ACK" // Payload: ImposterRoleAckPayload
    static let imposterRejoinRequest = "IMPOSTER_REJOIN_REQUEST" // Payload: ImposterRejoinRequestPayload
    static let imposterRejoinState = "IMPOSTER_REJOIN_STATE" // Payload: ImposterRejoinStatePayload
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

    // Rematch Events
    static let imposterRematchOffer = "IMPOSTER_REMATCH_OFFER" // Payload: ImposterRematchOfferPayload
    static let imposterRematchResponse = "IMPOSTER_REMATCH_RESPONSE" // Payload: ImposterRematchResponsePayload

    // Falsche Fährte Events – Host → Alle
    static let ffGameConfig     = "FF_GAME_CONFIG"      // FFGameConfigPayload
    static let ffBluffsReady    = "FF_BLUFFS_READY"     // FFBluffsReadyPayload
    static let ffReveal         = "FF_REVEAL"            // FFRevealPayload
    static let ffRevealScores   = "FF_REVEAL_SCORES"     // FFRevealScoresPayload
    static let ffNextRound      = "FF_NEXT_ROUND"        // FFNextRoundPayload
    static let ffGameOver       = "FF_GAME_OVER"         // FFGameOverPayload
    static let ffBluffingStatus = "FF_BLUFFING_STATUS"   // FFBluffingStatusPayload
    static let ffVotingStatus   = "FF_VOTING_STATUS"     // FFVotingStatusPayload

    // Falsche Fährte Events – Client → Host
    static let ffBluffSubmit    = "FF_BLUFF_SUBMITTED"   // FFBluffSubmitPayload
    static let ffVoteCast       = "FF_VOTE_CAST_FF"      // FFVoteCastPayload (FF-spezifisch)

    // Questions Specific Events
    static let questionsSyncConfig = "QUESTIONS_SYNC_CONFIG" // Payload: QuestionsConfig
    static let questionsRoleAssignment = "QUESTIONS_ROLE_ASSIGNMENT" // Payload: QuestionsRolePayload
    static let questionsRoleAck = "QUESTIONS_ROLE_ACK" // Payload: QuestionsRoleAckPayload
    static let questionsStateSync = "QUESTIONS_STATE_SYNC" // Payload: QuestionsRoundState
    static let questionsAnswerSubmitted = "QUESTIONS_ANSWER_SUBMITTED" // Payload: QuestionsAnswer
    static let questionsVoteCast = "QUESTIONS_VOTE_CAST" // Payload: QuestionsVoteCastPayload
    static let questionsVotingStatus = "QUESTIONS_VOTING_STATUS" // Payload: QuestionsVotingStatusPayload
    static let questionsVotingResult = "QUESTIONS_VOTING_RESULT" // Payload: QuestionsVoteEvaluation
    static let questionsTimerSync = "QUESTIONS_TIMER_SYNC" // Payload: QuestionsTimerSyncPayload
    static let questionsTimeSyncPing = "QUESTIONS_TIME_SYNC_PING" // Payload: QuestionsTimeSyncPingPayload
    static let questionsTimeSyncPong = "QUESTIONS_TIME_SYNC_PONG" // Payload: QuestionsTimeSyncPongPayload
    static let questionsRejoinRequest = "QUESTIONS_REJOIN_REQUEST" // Payload: QuestionsRejoinRequestPayload
    static let questionsRejoinState = "QUESTIONS_REJOIN_STATE" // Payload: QuestionsRejoinStatePayload
    static let questionsHostActivity = "QUESTIONS_HOST_ACTIVITY" // Payload: QuestionsHostActivityPayload
}
