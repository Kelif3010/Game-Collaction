//
//  GameLogic.swift
//  Imposter
//
//  Created by Ken on 22.09.25.
//

import Foundation
import Combine
import MultipeerConnectivity

class GameLogic: ObservableObject {
    @Published var gameSettings: GameSettings
    private var gameTimer: Timer?
    private var lastTickUptime: TimeInterval?
    private var lastTimerSyncUptime: TimeInterval?
    private var preciseTimeRemaining: TimeInterval?
    private var scheduledStartWorkItem: DispatchWorkItem?
    private var lastRemotePauseState: Bool?
    private var multiplayerVotePreview: [String: String] = [:]
    private var rematchOfferId: UUID?
    private var rematchResponses: [String: Bool] = [:]
    private var roleAssignmentId: UUID?
    private var pendingRoleAcks: Set<String> = []
    private var playerIdByName: [String: UUID] = [:]
    private let timerTickInterval: TimeInterval = 0.25
    private let timerSyncInterval: TimeInterval = 1.2
    private let softSyncThreshold: TimeInterval = 0.7
    private let softSyncFactor: TimeInterval = 0.25

    // Periodische Uhren-Synchronisation für Clients (verhindert Drift über Zeit)
    private var lastClientPingUptime: TimeInterval?
    private let clientPingSyncInterval: TimeInterval = 10.0  // Alle 10 Sekunden synchronisieren
    
    init(gameSettings: GameSettings) {
        self.gameSettings = gameSettings
    }

    deinit {
        gameTimer?.invalidate()
        gameTimer = nil
        scheduledStartWorkItem?.cancel()
        scheduledStartWorkItem = nil
    }
    
    /// Startet das Spiel und weist Begriffe und Imposter zu
    @MainActor
    /// Returns `true` if the game started successfully, `false` if setup failed.
    /// Callers must show an alert when `false` is returned.
    @discardableResult
    func startGame() async -> Bool {
        stopGameTimer()

        // 1. Grundeinstellungen validieren
        if !gameSettings.randomSpyCount {
            let cap = maxAllowedImposters(for: gameSettings.players.count)
            gameSettings.numberOfImposters = min(max(1, gameSettings.numberOfImposters), cap)
        }

        // Spiel zurücksetzen
        gameSettings.resetGame()
        HintService.shared.resetState()

        // Animation für diese Runde zufällig wählen
        let animations = ["Fingerprint biometric scan", "Android Fingerprint"]
        gameSettings.currentCardBackAnimation = animations.randomElement() ?? "Fingerprint biometric scan"

        guard let roundCategory = gameSettings.chooseRoundCategory(),
              !roundCategory.words.isEmpty,
              gameSettings.players.count >= 4 else {
            return false
        }

        // 2. Begriffe wählen
        guard let gameWords = selectWordsForGameMode(from: roundCategory) else { return false }

        // 3. Rollen verteilen (Core Logic)
        distributeRoles(playersCount: gameSettings.players.count)

        // 4. Texte generieren und zuweisen
        await assignWordsToPlayers(gameWords: gameWords)

        // 5. Spielzustand setzen
        gameSettings.gamePhase = .cardReveal
        gameSettings.currentPlayerIndex = 0
        gameSettings.timeRemaining = gameSettings.timeLimit
        return true
    }

    @MainActor
    func startMultiplayerGameAsHost() async -> Bool {
        guard gameSettings.gameMode == .classic else { return false }
        guard let category = gameSettings.chooseRoundCategory() else { return false }

        // 1. Setup Data
        let mpc = MultipeerManager.shared
        let allPeers = mpc.lobbyPeers // Includes Host + Clients (Names)

        playerIdByName.removeAll()
        playerIdByName[mpc.myPeerId.displayName] = mpc.playerId

        let newPlayers = allPeers.map { Player(name: $0) }
        gameSettings.players = newPlayers
        gameSettings.resetGame()
        gameSettings.roundCategory = category
        gameSettings.gamePhase = .cardReveal // Start in Reveal Phase, not Playing!
        gameSettings.timeRemaining = gameSettings.timeLimit
        gameSettings.isTimerPaused = true
        gameSettings.isWaitingForOtherPlayers = false // Reset waiting state
        gameSettings.revealProgress = (0, allPeers.count)
        gameSettings.multiplayerVotes.removeAll()
        gameSettings.multiplayerVotingProgress = nil
        gameSettings.multiplayerVotingSelection = nil
        gameSettings.multiplayerVotingResult = nil
        gameSettings.multiplayerWordGuessResult = nil
        gameSettings.multiplayerRematchOffer = nil
        gameSettings.multiplayerRematchWaiting = false
        gameSettings.shouldPresentVoting = false

        // Use GameLogic's role distribution logic
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
        gameSettings.numberOfImposters = impostersCount

        let assignmentId = UUID()
        roleAssignmentId = assignmentId
        pendingRoleAcks = Set(allPeers.filter { $0 != mpc.myPeerId.displayName })

        // Indices for Imposters
        var indices = Array(0..<totalPlayers)
        indices.shuffle()
        let imposterIndices = Set(indices.prefix(impostersCount))

        // Distribute
        var assignments: [(peer: MCPeerID, payload: ImposterRolePayload)] = []
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
                // For Host, we set the current player index to self so the card view works if needed
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

        // 2. Send Config Sync (Optional, but good for timer/mode display on clients)
        let config = gameSettings.toMPCConfig()
        mpc.sendToAll(event: MPCEventType.imposterSyncConfig, object: config)

        // 3. Warte kurz auf Role-ACKs, damit Reveal nicht zu frueh kommt
        if !pendingRoleAcks.isEmpty {
            let timeout: TimeInterval = 2.5
            let deadline = Date().timeIntervalSinceReferenceDate + timeout
            while !pendingRoleAcks.isEmpty && Date().timeIntervalSinceReferenceDate < deadline {
                try? await Task.sleep(nanoseconds: 150_000_000)
            }
            if !pendingRoleAcks.isEmpty {
                print("⚠️ MPC: Role-ACK Timeout fuer: \(pendingRoleAcks)")
            }
        }

        pendingRoleAcks.removeAll()
        roleAssignmentId = nil

        // 4. Start Reveal Phase for everyone (BUT DO NOT START GAME YET)
        mpc.sendToAll(event: MPCEventType.imposterRevealStart)

        return true
    }

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
    
    // MARK: - Role Distribution Logic
    
    /// Verteilt Spione und Sonderrollen fair auf die Spieler
    private func distributeRoles(playersCount: Int) {
        // IDs aller Spieler
        let playerIds = gameSettings.players.map { $0.id }
        var availableIds = Set(playerIds)
        
        // A. Spione wählen (Pflicht)
        let imposters = selectRandomImposters() // Nutzt bestehende Fairness-Logik
        
        // Markiere Spione im Settings-Array
        for i in gameSettings.players.indices {
            if imposters.contains(gameSettings.players[i].id) {
                gameSettings.players[i].isImposter = true
                availableIds.remove(gameSettings.players[i].id)
            }
        }
        
        // B. Sonderrollen verteilen (Optional)
        // Wir mischen die aktiven Rollen, um Zufälligkeit bei Knappheit zu garantieren
        let activeRoles = gameSettings.activeRoles.shuffled()
        
        for role in activeRoles {
            // Validierung: Passt die Rolle noch rein?
            if !canAssignRole(role, availableCount: availableIds.count, totalPlayers: playersCount) {
                continue
            }
            
            // Spezialfall: Zwillinge brauchen 2 Spieler
            if role == .twins {
                guard availableIds.count >= 2 else { continue }
                guard let twin1 = availableIds.randomElement() else { continue }
                availableIds.remove(twin1)
                guard let twin2 = availableIds.randomElement() else { continue }
                availableIds.remove(twin2)
                
                assignRole(role, to: twin1)
                assignRole(role, to: twin2)
            } else {
                // Einzelne Rolle
                guard let playerId = availableIds.randomElement() else { break }
                availableIds.remove(playerId)
                
                // Für Verräter/Saboteur/Maulwurf: Müssen wir sicherstellen, dass wir nicht zu viele Böse haben?
                // Hier vertrauen wir auf canAssignRole
                assignRole(role, to: playerId)
            }
        }
    }
    
    private func assignRole(_ role: RoleType, to playerId: UUID) {
        if let index = gameSettings.players.firstIndex(where: { $0.id == playerId }) {
            gameSettings.players[index].roleType = role
        }
    }
    
    /// Prüft ob eine Rolle noch vergeben werden darf
    private func canAssignRole(_ role: RoleType, availableCount: Int, totalPlayers: Int) -> Bool {
        // Harte Limits
        if availableCount <= 0 { return false }
        
        // Spezifische Regeln
        switch role {
        case .twins:
            return availableCount >= 2
        case .secretAgent:
            // Geheimagent sollte nicht existieren, wenn es nur 3 Spieler gibt (zu mächtig)
            return totalPlayers >= 5
        case .saboteur, .mole:
            // Böse Rollen brauchen genug Bürger als Gegengewicht
            // Max 1/3 der Spieler sollten "böse" Sonderrollen haben (plus Spion)
            let currentEvil = gameSettings.players.filter { $0.isImposter || $0.roleType?.team == .imposter }.count
            return Double(currentEvil + 1) <= Double(totalPlayers) / 2.5
        default:
            return true
        }
    }

    /// Weist allen Spielern Begriffe und Texte zu
    @MainActor
    private func assignWordsToPlayers(gameWords: GameWords) async {
        guard let roundCategory = gameSettings.roundCategory else { return }
        let allPlayers = gameSettings.players
        
        for i in gameSettings.players.indices {
            let player = gameSettings.players[i]
            
            // Text generieren
            let text: String
            
            if player.isImposter {
                // Klassischer Spion (oder falls Rolle nil ist)
                if gameSettings.showSpyHints {
                    let otherSpies = gameSettings.players
                        .filter { $0.isImposter && $0.id != player.id }
                        .map { $0.name }
                    
                    text = await HintsManager.createSpyCardTextWithAI(
                        word: gameWords.primary,
                        categoryName: roundCategory.name,
                        category: roundCategory,
                        categoryEmoji: roundCategory.emoji,
                        showCategory: gameSettings.shouldSpySeeCategory,
                        showHints: true,
                        otherSpyNames: gameSettings.shouldSpiesSeeEachOther ? otherSpies : []
                    )
                } else {
                    // Standard Spion Text ohne KI Hints (aber mit Kategorie Option)
                    let otherSpies = gameSettings.players
                        .filter { $0.isImposter && $0.id != player.id }
                        .map { $0.name }
                    
                    text = HintsManager.createSpyCardText(
                        word: gameWords.primary,
                        categoryName: roundCategory.name,
                        categoryEmoji: roundCategory.emoji,
                        showCategory: gameSettings.shouldSpySeeCategory,
                        showHints: false,
                        otherSpyNames: gameSettings.shouldSpiesSeeEachOther ? otherSpies : []
                    )
                }
            } else if let role = player.roleType {
                // Sonderrolle
                text = HintsManager.createRoleCardText(
                    role: role,
                    word: gameWords.primary,
                    category: roundCategory,
                    allPlayers: allPlayers,
                    currentPlayer: player
                )
            } else {
                // Normaler Bürger
                text = gameWords.primary
            }
            
            gameSettings.players[i].word = text
            gameSettings.players[i].hasSeenCard = false
        }
    }
    
    // MARK: - Helper Methods
    
    /// Wählt Begriffe basierend auf dem aktuellen Spielmodus
    private func selectWordsForGameMode(from category: Category) -> GameWords? {
        guard !category.words.isEmpty else { return nil }
        switch gameSettings.gameMode {
        case .classic:
            guard let word = category.words.randomElement() else { return nil }
            return GameWords(primary: word, secondary: nil)

        case .twoWords:
            // Zwei verschiedene Begriffe aus derselben Kategorie
            let shuffledWords = category.words.shuffled()
            let primary = shuffledWords[0]
            let secondary = shuffledWords.count > 1 ? shuffledWords[1] : primary
            return GameWords(primary: primary, secondary: secondary)

        case .roles:
            guard let word = category.words.randomElement() else { return nil }
            return GameWords(primary: word, secondary: nil)
        case .questions:
            guard let word = category.words.randomElement() else { return nil }
            return GameWords(primary: word, secondary: nil)
        }
    }
    
    /// Ermittelt die maximale zulässige Anzahl an Spionen gemäß Regeln
    private func maxAllowedImposters(for playersCount: Int) -> Int {
        if playersCount <= 1 { return 0 }
        if playersCount == 4 { return 1 }
        // Max 50% der Spieler, aber nie >= playersCount
        let cap = max(1, playersCount / 2) // floor
        return min(cap, playersCount - 1)
    }
    
    /// Wählt zufällig Imposter aus den Spielern aus
    private func selectRandomImposters() -> Set<UUID> {
        let players = gameSettings.players
        let playerIds = players.map { $0.id }
        _ = playerIds.shuffled()
        
        if gameSettings.randomSpyCount {
            let capForUI = maxAllowedImposters(for: players.count)
            if gameSettings.numberOfImposters > capForUI {
                gameSettings.numberOfImposters = capForUI
            }
        }
        
        let cap = maxAllowedImposters(for: players.count)
        let imposterCount: Int
        if gameSettings.randomSpyCount && players.count >= 5 {
            let upperBound = max(1, cap)
            imposterCount = Int.random(in: 1...upperBound)
            DispatchQueue.main.async { [weak gameSettings] in
                gameSettings?.numberOfImposters = imposterCount
            }
        } else {
            let requested = max(1, gameSettings.numberOfImposters)
            imposterCount = min(requested, cap)
        }
        
        if imposterCount <= 0 || players.isEmpty {
            return []
        }
        
        // Use fairness-aware picker
        var rng: any RandomNumberGeneratorLike = SystemRNGAdapter()
        let multipliers = AITuner.shared.suggestWeightMultipliers(
            players: playerIds,
            policy: gameSettings.fairnessPolicy,
            state: gameSettings.fairnessState
        )
        
        ModeratorLog.shared.logDebug(
            AIService.shared.isAvailable ? "Spion-Verteilung: KI verfügbar" : "Spion-Verteilung: Fallback aktiv",
            metadata: [
                "players": String(gameSettings.players.count),
                "requestedImposters": String(gameSettings.numberOfImposters)
            ]
        )
        
        let picked = ImposterPicker.pickImposters(
            players: playerIds,
            count: imposterCount,
            policy: gameSettings.fairnessPolicy,
            state: gameSettings.fairnessState,
            rng: &rng,
            weightMultipliers: multipliers
        )
        
        let round = gameSettings.fairnessState.currentRound
        let pickedSet = Set(picked)
        
        gameSettings.fairnessState.recordImposters(picked)
        
        for id in picked {
            gameSettings.fairnessState.updateStats(for: id) { s in
                s.cooldownUntilRound = round + gameSettings.fairnessPolicy.minCooldownRounds
            }
        }
        
        for id in playerIds where !pickedSet.contains(id) {
            gameSettings.fairnessState.updateStats(for: id) { s in
                if s.currentStreak > 0 { s.currentStreak = 0 }
            }
        }
        
        return Set(picked)
    }
    
    // MARK: - Game Flow Control
    
    /// Markiert den aktuellen Spieler als "Karte gesehen"
    func markCurrentPlayerCardSeen() {
        if gameSettings.currentPlayerIndex < gameSettings.players.count {
            gameSettings.players[gameSettings.currentPlayerIndex].hasSeenCard = true
        }
        
        if MultipeerManager.shared.role == .host {
            broadcastGameState()
        }
    }
    
    /// Geht zum nächsten Spieler über
    func nextPlayer() {
        if gameSettings.currentPlayerIndex < gameSettings.players.count - 1 {
            gameSettings.currentPlayerIndex += 1
        } else {
            gameSettings.gamePhase = .playing
            // Timer initialisieren, aber PAUSIERT starten, damit der "Startspieler"-Screen angezeigt werden kann
            gameSettings.isTimerPaused = true
            startGameTimer()
            
            // Falls wir im "Klassisch"-Modus sind, können wir Hinweise vorbereiten, aber noch nicht abspielen
            if gameSettings.gameMode != .twoWords,
               let _ = gameSettings.roundCategory,
               let _ = gameSettings.players.first(where: { !$0.isImposter }) {
                // Hinweise laden, aber erst starten, wenn Timer läuft (wird in gameTimer Logik oder unpause geregelt)
                // Hier machen wir nichts, HintService horcht oft auf Timer.
            }
        }
        
        if MultipeerManager.shared.role == .host {
            broadcastGameState()
        }
    }

    private func startGameTimer() {
        guard gameTimer == nil else { return }
        lastTickUptime = ProcessInfo.processInfo.systemUptime
        if preciseTimeRemaining == nil {
            preciseTimeRemaining = Double(gameSettings.timeRemaining)
        }
        lastTimerSyncUptime = nil
        gameTimer = Timer.scheduledTimer(withTimeInterval: timerTickInterval, repeats: true) { [weak self] _ in
            self?.handleTimerTick()
        }
    }

    private func handleTimerTick() {
        let now = ProcessInfo.processInfo.systemUptime
        guard let lastTickUptime else {
            self.lastTickUptime = now
            return
        }

        if gameSettings.isTimerPaused {
            self.lastTickUptime = now
            return
        }

        let delta = max(0, now - lastTickUptime)
        self.lastTickUptime = now

        let previousDisplay = gameSettings.timeRemaining
        let baseRemaining = preciseTimeRemaining ?? Double(previousDisplay)
        let updatedRemaining = max(0, baseRemaining - delta)
        preciseTimeRemaining = updatedRemaining

        let display = max(0, Int(ceil(updatedRemaining)))
        if display != previousDisplay {
            gameSettings.timeRemaining = display
            ImposterHapticsManager.shared.playTimerTick(secondsRemaining: display)
        }

        if MultipeerManager.shared.role == .host {
            maybeSyncTimer(now: now)
        } else if MultipeerManager.shared.role == .peer {
            // Clients: Periodisch Ping senden um Uhren-Drift zu korrigieren
            maybeClientPing(now: now)
        }

        if updatedRemaining <= 0, gameSettings.gamePhase != .finished {
            gameSettings.gamePhase = .finished
            gameSettings.markRoundCompleted()
            stopGameTimer()

            // MPC Sync Final
            if MultipeerManager.shared.role == .host {
                broadcastGameState()
                MultipeerManager.shared.sendToAll(event: MPCEventType.imposterGameOver)
            }

            Task { @MainActor in
                let spies = self.gameSettings.players.filter { $0.isImposter || $0.roleType?.team == .imposter }
                let citizens = self.gameSettings.players.filter { !$0.isImposter && $0.roleType?.team != .imposter }

                for spy in spies {
                    StatsService.shared.recordSpyWinTimeOut(spyName: spy.name)
                    GlobalStatsManager.shared.recordWin(for: spy.name) // NEU: Global Stats
                }

                // Bürger verlieren bei Timeout
                for citizen in citizens {
                    GlobalStatsManager.shared.recordLoss(for: citizen.name) // NEU: Global Stats
                }

                StatsService.shared.recordLoss(playerNames: citizens.map { $0.name }, asImposter: false)
            }
        }
    }

    private func maybeSyncTimer(now: TimeInterval) {
        guard !gameSettings.isTimerPaused else { return }
        if let lastSync = lastTimerSyncUptime, (now - lastSync) < timerSyncInterval {
            return
        }
        lastTimerSyncUptime = now
        broadcastGameState()
    }

    /// Client sendet periodisch Pings an Host um Uhren-Drift zu korrigieren
    private func maybeClientPing(now: TimeInterval) {
        // Nur wenn Spiel läuft (nicht pausiert)
        guard !gameSettings.isTimerPaused else { return }

        // Prüfen ob genug Zeit seit letztem Ping vergangen ist
        if let lastPing = lastClientPingUptime, (now - lastPing) < clientPingSyncInterval {
            return
        }

        lastClientPingUptime = now

        // Ping an Host senden
        let mpc = MultipeerManager.shared
        let ping = ImposterTimeSyncPingPayload(
            clientName: mpc.myPeerId.displayName,
            pingId: UUID(),
            clientSendUptime: now
        )
        mpc.sendToHost(event: MPCEventType.imposterTimeSyncPing, object: ping)
    }

    func stopGameTimer() {
        gameTimer?.invalidate()
        gameTimer = nil
        lastTickUptime = nil
        lastTimerSyncUptime = nil
        lastClientPingUptime = nil  // Reset Client-Ping-Timer
        preciseTimeRemaining = nil
        lastRemotePauseState = nil
        scheduledStartWorkItem?.cancel()
        scheduledStartWorkItem = nil
        HintService.shared.stopHints()
        VoiceService.shared.stopSpeaking()
    }

    func startMultiplayerTimerIfNeeded() {
        guard MultipeerManager.shared.role == .host else { return }
        if gameSettings.timeRemaining <= 0 {
            gameSettings.timeRemaining = gameSettings.timeLimit
        }
        gameSettings.gamePhase = .playing
        scheduleMultiplayerStart(startAtHostUptime: ProcessInfo.processInfo.systemUptime)
    }

    func startMultiplayerVoting() {
        guard MultipeerManager.shared.role == .host else { return }
        gameSettings.multiplayerVotes.removeAll()
        gameSettings.multiplayerVotingSelection = nil
        gameSettings.multiplayerVotingResult = nil
        multiplayerVotePreview.removeAll()
        gameSettings.isTimerPaused = true
        broadcastGameState()

        let eligibleVoters = gameSettings.players.filter { !$0.isEliminated }
        let tally = initialVotingTally(eligibleVoters: eligibleVoters.map { $0.name })
        let status = ImposterVotingStatusPayload(
            votesReceived: 0,
            totalVoters: eligibleVoters.count,
            tally: tally
        )
        gameSettings.multiplayerVotingProgress = status
        gameSettings.multiplayerVoteTally = tally
        gameSettings.shouldPresentVoting = true

        MultipeerManager.shared.sendToAll(event: MPCEventType.imposterStartVoting, object: status)
    }

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

    func handleMultiplayerVotePreview(_ preview: ImposterVotePreviewPayload) {
        guard MultipeerManager.shared.role == .host else { return }
        let eligibleVoters = gameSettings.players.filter { !$0.isEliminated }.map { $0.name }
        let eligibleSet = Set(eligibleVoters)
        guard eligibleSet.contains(preview.voterName) else { return }

        if let selectedName = preview.selectedName, eligibleSet.contains(selectedName) {
            multiplayerVotePreview[preview.voterName] = selectedName
        } else {
            multiplayerVotePreview.removeValue(forKey: preview.voterName)
        }

        updateVotingStatus(eligibleVoters: eligibleVoters)
    }

    func handleMultiplayerVoteCast(_ vote: ImposterVoteCastPayload) {
        guard MultipeerManager.shared.role == .host else { return }
        let eligibleVoters = gameSettings.players.filter { !$0.isEliminated }.map { $0.name }
        guard eligibleVoters.contains(vote.voterName) else { return }

        let eligibleTargets = Set(eligibleVoters)
        guard let selectedTarget = vote.votedFor.first(where: { eligibleTargets.contains($0) }) else { return }

        gameSettings.multiplayerVotes[vote.voterName] = [selectedTarget]
        multiplayerVotePreview[vote.voterName] = selectedTarget

        updateVotingStatus(eligibleVoters: eligibleVoters)

        if gameSettings.multiplayerVotes.count >= eligibleVoters.count {
            finalizeMultiplayerVoting(eligibleVoters: eligibleVoters)
        }
    }

    private func finalizeMultiplayerVoting(eligibleVoters: [String]) {
        guard !eligibleVoters.isEmpty else { return }
        let remainingSpies = gameSettings.players
            .filter { ($0.isImposter || $0.roleType?.team == .imposter) && !$0.isEliminated }
            .count
        let selectionCount = min(max(1, remainingSpies), eligibleVoters.count)

        var voteCounts: [String: Int] = [:]
        for name in eligibleVoters {
            voteCounts[name] = 0
        }
        for votes in gameSettings.multiplayerVotes.values {
            for name in votes {
                voteCounts[name, default: 0] += 1
            }
        }

        let selectedNames = selectCandidates(
            from: voteCounts,
            requiredCount: selectionCount
        )
        gameSettings.multiplayerVotingSelection = selectedNames

        gameSettings.multiplayerVotes.removeAll()
        multiplayerVotePreview.removeAll()
    }

    private func updateVotingStatus(eligibleVoters: [String]) {
        let totalVoters = eligibleVoters.count
        let votesReceived = min(gameSettings.multiplayerVotes.count, totalVoters)
        let tally = computeVotingTally(eligibleVoters: eligibleVoters)
        let status = ImposterVotingStatusPayload(
            votesReceived: votesReceived,
            totalVoters: totalVoters,
            tally: tally
        )
        gameSettings.multiplayerVotingProgress = status
        gameSettings.multiplayerVoteTally = tally
        MultipeerManager.shared.sendToAll(event: MPCEventType.imposterVotingStatus, object: status)
    }

    private func computeVotingTally(eligibleVoters: [String]) -> [String: Int] {
        let eligibleSet = Set(eligibleVoters)
        var tally: [String: Int] = [:]
        for name in eligibleVoters {
            tally[name] = 0
        }

        var mergedSelections = multiplayerVotePreview
        for (voter, votes) in gameSettings.multiplayerVotes {
            if let selected = votes.first {
                mergedSelections[voter] = selected
            }
        }

        for (voter, selected) in mergedSelections {
            guard eligibleSet.contains(voter), eligibleSet.contains(selected) else { continue }
            tally[selected, default: 0] += 1
        }

        return tally
    }

    private func initialVotingTally(eligibleVoters: [String]) -> [String: Int] {
        var tally: [String: Int] = [:]
        for name in eligibleVoters {
            tally[name] = 0
        }
        return tally
    }

    private func selectCandidates(from voteCounts: [String: Int], requiredCount: Int) -> [String] {
        guard requiredCount > 0 else { return [] }
        let grouped = Dictionary(grouping: voteCounts.keys) { voteCounts[$0, default: 0] }
        let sortedCounts = grouped.keys.sorted(by: >)
        var selected: [String] = []

        for count in sortedCounts {
            guard var names = grouped[count] else { continue }
            names.shuffle()
            for name in names where selected.count < requiredCount {
                selected.append(name)
            }
            if selected.count >= requiredCount {
                break
            }
        }

        return selected
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

    @MainActor
    func handleRoleAck(_ ack: ImposterRoleAckPayload) {
        guard ack.assignmentId == roleAssignmentId else { return }
        pendingRoleAcks.remove(ack.playerName)
    }

    func applyRemoteTimerSync(_ sync: ImposterGameStateSync, hostClockOffset: TimeInterval) {
        let now = ProcessInfo.processInfo.systemUptime
        let hostUptimeAtClient = sync.hostUptime - hostClockOffset
        let elapsed = max(0, now - hostUptimeAtClient)
        let baseRemaining = max(0, sync.timeRemainingPrecise)
        let expectedRemaining = max(0, baseRemaining - (sync.isTimerPaused ? 0 : elapsed))
        let pauseChanged = lastRemotePauseState == nil || lastRemotePauseState != sync.isTimerPaused
        lastRemotePauseState = sync.isTimerPaused
        gameSettings.isTimerPaused = sync.isTimerPaused

        if pauseChanged {
            // Hard sync on pause/resume to avoid visible lag.
            preciseTimeRemaining = expectedRemaining
        } else {
            let currentRemaining = preciseTimeRemaining ?? Double(gameSettings.timeRemaining)
            let delta = expectedRemaining - currentRemaining
            if abs(delta) >= softSyncThreshold {
                preciseTimeRemaining = expectedRemaining
            } else {
                preciseTimeRemaining = currentRemaining + delta * softSyncFactor
            }
        }

        let display = max(0, Int(ceil(preciseTimeRemaining ?? expectedRemaining)))
        if gameSettings.timeRemaining != display {
            gameSettings.timeRemaining = display
        }

        lastTickUptime = now
        if gameTimer == nil {
            startGameTimer()
        }
    }

    func scheduleMultiplayerStart(startAtHostUptime: TimeInterval) {
        scheduledStartWorkItem?.cancel()
        scheduledStartWorkItem = nil

        if gameSettings.timeRemaining <= 0 {
            gameSettings.timeRemaining = gameSettings.timeLimit
        }

        preciseTimeRemaining = Double(gameSettings.timeRemaining)
        gameSettings.isTimerPaused = true

        if gameTimer == nil {
            startGameTimer()
        }

        let now = ProcessInfo.processInfo.systemUptime
        let startAtClientUptime = startAtHostUptime - gameSettings.hostClockOffset
        let delay = max(0, startAtClientUptime - now)

        let workItem = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.gameSettings.multiplayerStartAtHostUptime = nil
            self.gameSettings.isTimerPaused = false
            self.lastTickUptime = ProcessInfo.processInfo.systemUptime
            if MultipeerManager.shared.role == .host {
                self.broadcastGameState()
            }
        }

        scheduledStartWorkItem = workItem
        if delay == 0 {
            workItem.perform()
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
        }
    }
    
    // MARK: - MPC Broadcast
    
    func broadcastGameState() {
        guard MultipeerManager.shared.role == .host else { return }
        let now = ProcessInfo.processInfo.systemUptime
        let preciseRemaining = preciseTimeRemaining ?? Double(gameSettings.timeRemaining)
        let sync = ImposterGameStateSync(
            timeRemaining: gameSettings.timeRemaining,
            timeRemainingPrecise: preciseRemaining,
            isTimerPaused: gameSettings.isTimerPaused,
            gamePhase: gameSettings.gamePhase,
            currentPlayerIndex: gameSettings.currentPlayerIndex,
            startingPlayerName: gameSettings.startingPlayerName,
            hostUptime: now
        )
        
        MultipeerManager.shared.sendToAll(event: MPCEventType.imposterTimerSync, object: sync)
    }
    
    var currentPlayer: Player? {
        guard gameSettings.currentPlayerIndex < gameSettings.players.count else { return nil }
        return gameSettings.players[gameSettings.currentPlayerIndex]
    }
    
    var allPlayersSeenCards: Bool {
        return gameSettings.players.allSatisfy { $0.hasSeenCard }
    }
    
    var remainingPlayersCount: Int {
        return gameSettings.players.count - gameSettings.currentPlayerIndex - 1
    }
    
    func restartGame() async {
        stopGameTimer()
        gameSettings.isTimerPaused = true
        gameSettings.markRoundCompleted()
        
        gameSettings.currentPlayerIndex = 0
        gameSettings.gamePhase = .setup
        gameSettings.timeRemaining = gameSettings.timeLimit
        gameSettings.multiplayerStartAtHostUptime = nil
        
        for i in gameSettings.players.indices {
            gameSettings.players[i].hasSeenCard = false
            gameSettings.players[i].isImposter = false
            gameSettings.players[i].word = ""
            gameSettings.players[i].isEliminated = false
            gameSettings.players[i].roleType = nil // Reset RoleType too!
        }
        
        Task { @MainActor in
            HintService.shared.stopHints()
        }
        
        await startGame()
    }
}
