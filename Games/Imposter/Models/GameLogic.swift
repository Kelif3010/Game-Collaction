//
//  GameLogic.swift
//  Imposter
//
//  Created by Ken on 22.09.25.
//

import Foundation
import MultipeerConnectivity
import AsyncAlgorithms
import OrderedCollections

@MainActor
@Observable
class GameLogic {
    var gameSettings: GameSettings
    var startFailureMessage: String?
    private let rolesModeViewModel = ImposterRolesModeViewModel()

    // Timer state — accessed from ImposterGameState extension
    var gameTimerTask: Task<Void, Never>?
    var lastTickUptime: TimeInterval?
    var lastTimerSyncUptime: TimeInterval?
    var preciseTimeRemaining: TimeInterval?
    var scheduledStartTask: Task<Void, Never>?
    var lastRemotePauseState: Bool?
    var lastClientPingUptime: TimeInterval?

    let timerTickInterval: TimeInterval = 0.25
    let timerSyncInterval: TimeInterval = 1.2
    let softSyncThreshold: TimeInterval = 0.7
    let softSyncFactor: TimeInterval = 0.25
    let clientPingSyncInterval: TimeInterval = 10.0

    // Voting state — accessed from ImposterVotingLogic extension
    var multiplayerVotePreview: OrderedDictionary<String, String> = [:]

    // Rematch state — private to this file
    private var rematchOfferId: UUID?
    private var rematchResponses: OrderedDictionary<String, Bool> = [:]

    // Multiplayer role assignment — private to this file
    private var roleAssignmentId: UUID?
    private var pendingRoleAcks: OrderedSet<String> = []
    private var pendingAckContinuation: CheckedContinuation<Void, Never>?
    private var playerIdByName: [String: UUID] = [:]
    private var mpcHandler: ImposterMPCHandler?

    init(gameSettings: GameSettings) {
        self.gameSettings = gameSettings
    }

    isolated deinit {
        gameTimerTask?.cancel()
        gameTimerTask = nil
        scheduledStartTask?.cancel()
        scheduledStartTask = nil
    }

    // MARK: - Game Start

    @MainActor
    @discardableResult
    func startGame() async -> Bool {
        startFailureMessage = nil
        stopGameTimer()

        if !gameSettings.randomSpyCount {
            let cap = maxAllowedImposters(for: gameSettings.players.count)
            gameSettings.numberOfImposters = min(max(1, gameSettings.numberOfImposters), cap)
        }

        gameSettings.resetGame()
        HintService.shared.resetState()

        let animations = ["Fingerprint biometric scan", "Android Fingerprint"]
        gameSettings.currentCardBackAnimation = animations.randomElement() ?? "Fingerprint biometric scan"

        guard let roundCategory = gameSettings.chooseRoundCategory(),
              !roundCategory.words.isEmpty,
              gameSettings.players.count >= 4 else {
            return false
        }

        guard let gameWords = selectWordsForGameMode(from: roundCategory) else { return false }

        distributeRoles(playersCount: gameSettings.players.count)

        if gameSettings.gameMode == .roles {
            guard rolesModeViewModel.canGenerateRoles else {
                startFailureMessage = "Rollen-Modus benötigt Apple Intelligence."
                return false
            }

            do {
                let roles = try await rolesModeViewModel.generateLocationRoles(
                    for: gameWords.primary,
                    playerCount: gameSettings.players.count
                )
                for index in gameSettings.players.indices {
                    gameSettings.players[index].role = roles[index]
                }
            } catch {
                startFailureMessage = error.localizedDescription
                return false
            }
        }

        await assignWordsToPlayers(gameWords: gameWords)

        gameSettings.gamePhase = .cardReveal
        gameSettings.currentPlayerIndex = 0
        gameSettings.timeRemaining = gameSettings.timeLimit
        return true
    }

    @MainActor
    func startMultiplayerGameAsHost() async -> Bool {
        guard gameSettings.gameMode == .classic || gameSettings.gameMode == .twoWords else { return false }
        guard let category = gameSettings.chooseRoundCategory() else { return false }

        let mpc = MultipeerManager.shared
        let allPeers = mpc.lobbyPeers

        playerIdByName.removeAll()
        playerIdByName[mpc.myPeerId.displayName] = mpc.playerId

        let newPlayers = allPeers.map { Player(name: $0) }
        gameSettings.players = newPlayers
        gameSettings.resetGame()
        gameSettings.roundCategory = category
        gameSettings.gamePhase = .cardReveal
        gameSettings.timeRemaining = gameSettings.timeLimit
        gameSettings.isTimerPaused = true
        gameSettings.isWaitingForOtherPlayers = false
        gameSettings.revealProgress = RevealProgress(ready: 0, total: allPeers.count)
        gameSettings.multiplayerVotes.removeAll()
        gameSettings.multiplayerVotingProgress = nil
        gameSettings.multiplayerVotingSelection = nil
        gameSettings.multiplayerVotingResult = nil
        gameSettings.multiplayerWordGuessResult = nil
        gameSettings.multiplayerRematchOffer = nil
        gameSettings.multiplayerRematchWaiting = false
        gameSettings.shouldPresentVoting = false

        guard gameSettings.gameMode != .twoWords || category.words.count >= 2 else { return false }
        let shuffledWords = category.words.shuffled()
        guard let secretWord = shuffledWords.first else { return false }
        let secondaryWord = gameSettings.gameMode == .twoWords && shuffledWords.count >= 2 ? shuffledWords[1] : nil
        let showCategoryForSpies = gameSettings.shouldSpySeeCategory
        let showHintsForSpies = gameSettings.showSpyHints

        let totalPlayers = allPeers.count
        var impostersCount = gameSettings.numberOfImposters
        if gameSettings.randomSpyCount {
            let maxSpies = gameSettings.maxAllowedImpostersCap
            impostersCount = Int.random(in: 1...max(1, maxSpies))
        }
        impostersCount = min(impostersCount, max(0, totalPlayers - 1))
        gameSettings.numberOfImposters = impostersCount

        let assignmentId = UUID()
        roleAssignmentId = assignmentId
        pendingRoleAcks = OrderedSet(allPeers.filter { $0 != mpc.myPeerId.displayName })

        var indices = Array(0..<totalPlayers)
        indices.shuffle()
        let imposterIndices = Set(indices.prefix(impostersCount))
        var citizenWordByIndex: [Int: String] = [:]
        let citizenIndices = indices
            .filter { !imposterIndices.contains($0) }
            .shuffled()
        for (offset, citizenIndex) in citizenIndices.enumerated() {
            if let secondaryWord {
                citizenWordByIndex[citizenIndex] = offset.isMultiple(of: 2) ? secretWord : secondaryWord
            } else {
                citizenWordByIndex[citizenIndex] = secretWord
            }
        }

        var assignments: [(peer: MCPeerID, payload: ImposterRolePayload)] = []
        for (index, playerName) in allPeers.enumerated() {
            let isImposter = imposterIndices.contains(index)
            var assignedWord: String
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
                    showHints: showHintsForSpies && secondaryWord == nil,
                    otherSpyNames: visibleSpyNames
                )
                if showHintsForSpies, secondaryWord != nil {
                    let neutralHint = "Hinweis: Es sind zwei unterschiedliche Begriffe im Spiel."
                    assignedWord = assignedWord.isEmpty ? neutralHint : "\(assignedWord)\n\n\(neutralHint)"
                }
            } else {
                assignedWord = citizenWordByIndex[index] ?? secretWord
            }

            let assignedRole: RoleType = isImposter ? .saboteur : .secretAgent

            let payload = ImposterRolePayload(
                role: assignedRole,
                word: assignedWord,
                categoryName: category.name,
                isImposter: isImposter,
                assignmentId: assignmentId
            )

            gameSettings.players[index].isImposter = isImposter
            gameSettings.players[index].word = assignedWord
            gameSettings.players[index].roleType = nil
            gameSettings.players[index].role = nil
            gameSettings.players[index].hasSeenCard = false

            if playerName == mpc.myPeerId.displayName {
                gameSettings.currentPlayerIndex = index
            } else if let peerID = mpc.getPeer(byName: playerName) {
                assignments.append((peer: peerID, payload: payload))
            }
        }

        await withTaskGroup(of: Void.self) { group in
            for assignment in assignments {
                group.addTask { @MainActor in
                    mpc.sendToPeer(
                        event: MPCEventType.imposterRoleAssignment,
                        object: assignment.payload,
                        to: assignment.peer
                    )
                }
            }
        }

        let config = gameSettings.toMPCConfig()
        mpc.sendToAll(event: MPCEventType.imposterSyncConfig, object: config)

        if !pendingRoleAcks.isEmpty {
            await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
                self.pendingAckContinuation = cont
                Task { [weak self] in
                    try? await Task.sleep(for: .seconds(2.5))
                    await MainActor.run { [weak self] in
                        guard let self else { return }
                        if let cont = self.pendingAckContinuation {
                            self.pendingAckContinuation = nil
                            cont.resume()
                        }
                    }
                }
            }
            if !pendingRoleAcks.isEmpty {
                print("⚠️ MPC: Role-ACK Timeout fuer: \(pendingRoleAcks)")
            }
        }

        pendingRoleAcks.removeAll()
        roleAssignmentId = nil

        mpc.sendToAll(event: MPCEventType.imposterRevealStart)

        return true
    }

    // MARK: - Player Identity & Rejoin

    @MainActor
    func registerPlayerIdentity(playerName: String, playerId: UUID) {
        playerIdByName[playerName] = playerId
    }

    @MainActor
    func makeRejoinStatePayload(for playerName: String) -> ImposterRejoinStatePayload? {
        guard gameSettings.gamePhase != .setup else { return nil }
        guard let playerIndex = gameSettings.players.firstIndex(where: { $0.name == playerName }) else { return nil }

        let player = gameSettings.players[playerIndex]
        let categoryName = gameSettings.roundCategory?.name
            ?? gameSettings.selectedCategory?.name
            ?? "Kategorie"

        let role = ImposterRolePayload(
            role: player.isImposter ? .saboteur : .secretAgent,
            word: player.word,
            categoryName: categoryName,
            isImposter: player.isImposter,
            assignmentId: nil
        )

        let now = ProcessInfo.processInfo.systemUptime
        let preciseRemaining = preciseTimeRemaining ?? Double(gameSettings.timeRemaining)
        let sync = ImposterGameStateSync(
            timeRemaining: gameSettings.timeRemaining,
            timeRemainingPrecise: preciseRemaining,
            isTimerPaused: gameSettings.isTimerPaused,
            gamePhase: gameSettings.gamePhase,
            currentPlayerIndex: playerIndex,
            startingPlayerName: gameSettings.startingPlayerName,
            hostUptime: now
        )

        let revealProgress: ImposterRevealProgressPayload?
        if gameSettings.gamePhase == .cardReveal {
            let readyCount = gameSettings.players.filter { $0.hasSeenCard }.count
            let totalCount = gameSettings.players.count
            revealProgress = ImposterRevealProgressPayload(readyCount: readyCount, totalCount: totalCount)
        } else {
            revealProgress = nil
        }

        let config = gameSettings.toMPCConfig()
        return ImposterRejoinStatePayload(
            playerName: playerName,
            playerHasSeenCard: player.hasSeenCard,
            role: role,
            gameState: sync,
            multiplayerStartAtHostUptime: gameSettings.multiplayerStartAtHostUptime,
            revealProgress: revealProgress,
            config: config
        )
    }

    // MARK: - MPC Handler

    func activateMPCHandler(gameSettings: GameSettings, onNavigate: @escaping (SetupRoute?) -> Void) {
        let handler = ImposterMPCHandler()
        handler.activate(gameSettings: gameSettings, gameLogic: self, onNavigate: onNavigate)
        self.mpcHandler = handler
    }

    func deactivateMPCHandler() {
        mpcHandler?.deactivate()
        mpcHandler = nil
    }

    // MARK: - Rematch

    func startMultiplayerRematchOffer() {
        guard MultipeerManager.shared.role == .host else { return }
        let offerId = UUID()
        rematchOfferId = offerId
        rematchResponses.removeAll()
        let myName = MultipeerManager.shared.myPeerId.displayName
        rematchResponses[myName] = true
        gameSettings.multiplayerRematchWaiting = true

        let payload = ImposterRematchOfferPayload(offerId: offerId, hostName: myName)
        MultipeerManager.shared.sendToAll(event: MPCEventType.imposterRematchOffer, object: payload)
        maybeFinalizeRematch()
    }

    func handleMultiplayerRematchResponse(_ response: ImposterRematchResponsePayload) {
        guard MultipeerManager.shared.role == .host else { return }
        guard response.offerId == rematchOfferId else { return }
        rematchResponses[response.playerName] = response.wantsRematch
        maybeFinalizeRematch()
    }

    func sendRematchResponse(wantsRematch: Bool) {
        guard MultipeerManager.shared.role == .peer else { return }
        guard let offer = gameSettings.multiplayerRematchOffer else { return }
        let myName = MultipeerManager.shared.myPeerId.displayName
        let payload = ImposterRematchResponsePayload(
            offerId: offer.offerId,
            playerName: myName,
            wantsRematch: wantsRematch
        )
        MultipeerManager.shared.sendToHost(event: MPCEventType.imposterRematchResponse, object: payload)
        gameSettings.multiplayerRematchOffer = nil
        if !wantsRematch {
            MultipeerManager.shared.stop()
            gameSettings.requestExitToSetup = true
        }
    }

    func handleRematchLobbyUpdate() {
        guard gameSettings.multiplayerRematchWaiting else { return }
        maybeFinalizeRematch()
    }

    private func maybeFinalizeRematch() {
        guard MultipeerManager.shared.role == .host else { return }
        guard rematchOfferId != nil else { return }

        let currentLobby = Set(MultipeerManager.shared.lobbyPeers)
        let allResponded = currentLobby.allSatisfy { rematchResponses[$0] != nil }
        let allWantToContinue = currentLobby.allSatisfy { rematchResponses[$0] == true }

        guard allResponded, allWantToContinue else { return }

        gameSettings.multiplayerRematchWaiting = false
        rematchOfferId = nil
        rematchResponses.removeAll()

        Task { @MainActor in
            _ = await startMultiplayerGameAsHost()
        }
    }

    // MARK: - Role Acknowledgement

    @MainActor
    func handleRoleAck(_ ack: ImposterRoleAckPayload) {
        guard ack.assignmentId == roleAssignmentId else { return }
        pendingRoleAcks.remove(ack.playerName)
        if pendingRoleAcks.isEmpty, let cont = pendingAckContinuation {
            pendingAckContinuation = nil
            cont.resume()
        }
    }
}
