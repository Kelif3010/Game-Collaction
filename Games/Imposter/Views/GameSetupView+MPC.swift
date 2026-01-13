import SwiftUI
import MultipeerConnectivity

extension GameSetupView {

    // MARK: - MPC Host Logic
    
    func startMPCGame() {
        guard gameSettings.gameMode == .classic else { return }
        guard let category = gameSettings.chooseRoundCategory() else { return }
        
        // 1. Setup Data
        let mpc = MultipeerManager.shared
        let allPeers = mpc.lobbyPeers // Includes Host + Clients (Names)

        let newPlayers = allPeers.map { Player(name: $0) }
        gameSettings.players = newPlayers
        gameSettings.resetGame()
        gameSettings.roundCategory = category
        gameSettings.gamePhase = .cardReveal // Start in Reveal Phase, not Playing!
        gameSettings.timeRemaining = gameSettings.timeLimit
        gameSettings.isTimerPaused = true
        gameSettings.isWaitingForOtherPlayers = false // Reset waiting state
        gameSettings.revealProgress = (0, allPeers.count)
        
        // Use GameLogic's role distribution logic
        // We need to temporarily simulate players in GameSettings to use existing logic or replicate it.
        // Replicating is safer to avoid messing with UI state too much.
        
        let words = category.words
        let secretWord = words.randomElement() ?? "Fehler"
        let showCategoryForSpies = gameSettings.shouldSpySeeCategory
        let showHintsForSpies = gameSettings.showSpyHints
        
        // Config
        let totalPlayers = allPeers.count
        var impostersCount = gameSettings.numberOfImposters
        if gameSettings.randomSpyCount {
            let maxSpies = gameSettings.maxAllowedImpostersCap
            impostersCount = Int.random(in: 1...max(1, maxSpies))
        }
        // Safety cap
        impostersCount = min(impostersCount, max(0, totalPlayers - 1))
        
        // Indices for Imposters
        var indices = Array(0..<totalPlayers)
        indices.shuffle()
        let imposterIndices = Set(indices.prefix(impostersCount))
        
        // Distribute
        for (index, playerName) in allPeers.enumerated() {
            let isImposter = imposterIndices.contains(index)
            let assignedWord: String
            if isImposter {
                let otherSpyNames = allPeers.enumerated()
                    .filter { imposterIndices.contains($0.offset) && $0.offset != index }
                    .map { $0.element }
                let visibleSpyNames = gameSettings.shouldSpiesSeeEachOther ? otherSpyNames : []
                assignedWord = HintsManager.createSpyCardText(
                    word: secretWord,
                    categoryName: category.name,
                    categoryEmoji: category.emoji,
                    showCategory: showCategoryForSpies,
                    showHints: showHintsForSpies,
                    otherSpyNames: visibleSpyNames
                )
            } else {
                assignedWord = secretWord
            }
            
            // Simple Role Mapping for now
            // Standard Imposter = Saboteur (internal ID), Standard Citizen = SecretAgent
            let assignedRole: RoleType = isImposter ? .saboteur : .secretAgent 
            
            let payload = ImposterRolePayload(
                role: assignedRole, 
                word: assignedWord, 
                categoryName: category.name,
                isImposter: isImposter
            )
            
            gameSettings.players[index].isImposter = isImposter
            gameSettings.players[index].word = assignedWord
            gameSettings.players[index].roleType = nil
            gameSettings.players[index].role = nil
            gameSettings.players[index].hasSeenCard = false

            if playerName == mpc.myPeerId.displayName {
                // For Host, we set the current player index to self so the card view works if needed
                gameSettings.currentPlayerIndex = index
            } else {
                // Send to Client
                if let peerID = mpc.getPeer(byName: playerName) {
                    mpc.sendToPeer(event: MPCEventType.imposterRoleAssignment, object: payload, to: peerID)
                }
            }
        }
        
        // 2. Send Config Sync (Optional, but good for timer/mode display on clients)
        let config = gameSettings.toMPCConfig()
        mpc.sendToAll(event: MPCEventType.imposterSyncConfig, object: config)
        
        // 3. Navigate Host (BUT DO NOT START GAME YET)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.route = .game
        }
    }
    
    // MARK: - MPC Client Listener
    func setupMPCListeners(gameSettings: GameSettings, route: Binding<SetupRoute?>) {
        let mpc = MultipeerManager.shared
        
        mpc.onEventReceived = { event, payload in
            DispatchQueue.main.async {
                switch event {
                case MPCEventType.imposterSyncConfig:
                    if let data = payload,
                       let config = try? JSONDecoder().decode(ImposterGameConfig.self, from: data) {
                        print("MPC Client: Applying Config")
                        gameSettings.applyMPCConfig(config)
                        gameSettings.timeRemaining = gameSettings.timeLimit
                    }
                    
                case MPCEventType.imposterRoleAssignment:
                    if let data = payload,
                       let roleInfo = try? JSONDecoder().decode(ImposterRolePayload.self, from: data) {
                        print("MPC Client: Role Received - \(roleInfo.role)")
                        
                        // Populate local player info
                        let myName = mpc.myPeerId.displayName
                        
                        // Ensure players list is synced (should be via Lobby Update, but safety check)
                        if gameSettings.players.isEmpty {
                            gameSettings.players = mpc.lobbyPeers.map { Player(name: $0) }
                        }
                        
                        // Find self
                        if let myIndex = gameSettings.players.firstIndex(where: { $0.name == myName }) {
                            gameSettings.players[myIndex].word = roleInfo.word
                            gameSettings.players[myIndex].isImposter = roleInfo.isImposter
                            gameSettings.players[myIndex].roleType = nil
                            gameSettings.players[myIndex].role = nil
                            gameSettings.players[myIndex].hasSeenCard = false // RESET SEEN STATE
                            gameSettings.currentPlayerIndex = myIndex // For card view
                            gameSettings.isWaitingForOtherPlayers = false // Reset waiting state
                            gameSettings.gamePhase = .cardReveal // Explicitly set phase
                            
                            // Set Category (Placeholder category for display)
                            if let realCat = gameSettings.categories.first(where: { $0.name == roleInfo.categoryName }) {
                                gameSettings.roundCategory = realCat
                            } else {
                                var dummy = Category(name: roleInfo.categoryName, words: [])
                                dummy.isCustom = true
                                gameSettings.roundCategory = dummy
                            }
                        }
                        
                        // Navigate to Game View
                        route.wrappedValue = .game
                    }
                    
                case MPCEventType.gameStart:
                    print("MPC Client: Game Start Signal")
                    gameSettings.gamePhase = .playing
                    gameSettings.isTimerPaused = true
                    gameSettings.timeRemaining = gameSettings.timeLimit
                    gameSettings.isWaitingForOtherPlayers = false // Stop waiting
                    // Route should already be set, but ensure it
                    if route.wrappedValue != .game {
                        route.wrappedValue = .game
                    }
                    
                case MPCEventType.imposterRevealProgress:
                     if let data = payload,
                        let progress = try? JSONDecoder().decode(ImposterRevealProgressPayload.self, from: data) {
                         gameSettings.revealProgress = (progress.readyCount, progress.totalCount)
                     }
                    
                case MPCEventType.imposterTimerSync:
                    if let data = payload,
                       let sync = try? JSONDecoder().decode(ImposterGameStateSync.self, from: data) {
                        // Apply sync
                        gameSettings.timeRemaining = sync.timeRemaining
                        gameSettings.isTimerPaused = sync.isTimerPaused
                        gameSettings.gamePhase = sync.gamePhase
                        if mpc.role != .peer {
                            gameSettings.currentPlayerIndex = sync.currentPlayerIndex
                        }
                        gameSettings.startingPlayerName = sync.startingPlayerName
                    }

                case MPCEventType.imposterHostActivity:
                    if let data = payload,
                       let info = try? JSONDecoder().decode(ImposterHostActivityPayload.self, from: data) {
                        mpc.hostActivity = info.message
                    }
                    
                case "PLAYER_READY_UPDATE":
                    if let data = payload,
                       let info = try? JSONDecoder().decode(ReadyStatusPayload.self, from: data) {
                        if info.isReady {
                            mpc.readyPlayers.insert(info.playerName)
                        } else {
                            mpc.readyPlayers.remove(info.playerName)
                        }
                        if mpc.role == .host {
                            let validPlayers = Set(mpc.lobbyPeers)
                            mpc.readyPlayers = mpc.readyPlayers.intersection(validPlayers)
                            mpc.sendToAll(event: "LOBBY_STATE_SYNC", object: Array(mpc.readyPlayers))
                        }
                    }
                    
                case "LOBBY_STATE_SYNC":
                    if let data = payload,
                       let list = try? JSONDecoder().decode([String].self, from: data) {
                        mpc.readyPlayers = Set(list)
                    }

                case MPCEventType.imposterCardSeen:
                    guard mpc.role == .host else { break }
                    if let data = payload,
                       let seen = try? JSONDecoder().decode(ImposterCardSeenPayload.self, from: data) {
                        
                        // 1. Mark player as ready
                        if let index = gameSettings.players.firstIndex(where: { $0.name == seen.playerName }) {
                            gameSettings.players[index].hasSeenCard = true
                        }
                        
                        // 2. Calculate Progress
                        let readyCount = gameSettings.players.filter { $0.hasSeenCard }.count
                        let totalCount = gameSettings.players.count
                        
                        // 3. Broadcast Progress
                        let progressPayload = ImposterRevealProgressPayload(readyCount: readyCount, totalCount: totalCount)
                        mpc.sendToAll(event: MPCEventType.imposterRevealProgress, object: progressPayload)
                        
                        // Update Host UI
                        gameSettings.revealProgress = (readyCount, totalCount)
                        
                        // 4. Check Start Condition
                        // IMPORTANT: Host Logic to start game when everyone is ready
                        if readyCount == totalCount {
                            // Delay slightly to let everyone see "5/5"
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                mpc.sendToAll(event: MPCEventType.gameStart)
                                gameSettings.gamePhase = .playing
                                gameSettings.isTimerPaused = true
                                gameSettings.isWaitingForOtherPlayers = false
                            }
                        }
                    }
                    
                case MPCEventType.imposterGameOver:
                    print("MPC Client: Game Over")
                    gameSettings.gamePhase = .finished
                    
                case MPCEventType.gameAbort:
                    print("MPC Client: Game Aborted")
                    route.wrappedValue = nil
                    
                default:
                    break
                }
            }
        }
    }
}

private struct ReadyStatusPayload: Codable {
    let playerName: String
    let isReady: Bool
}