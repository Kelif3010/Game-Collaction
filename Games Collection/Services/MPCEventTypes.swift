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
    static let imposterRevealProgress = "IMPOSTER_REVEAL_PROGRESS" // Payload: ImposterRevealProgressPayload
    static let imposterHostActivity = "IMPOSTER_HOST_ACTIVITY" // Payload: ImposterHostActivityPayload
}