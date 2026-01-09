//
//  GameLogic.swift
//  Imposter
//
//  Created by Ken on 22.09.25.
//

import Foundation
import Combine

class GameLogic: ObservableObject {
    @Published var gameSettings: GameSettings
    private var gameTimer: Timer?
    
    init(gameSettings: GameSettings) {
        self.gameSettings = gameSettings
    }

    deinit {
        gameTimer?.invalidate()
        gameTimer = nil
    }
    
    /// Startet das Spiel und weist Begriffe und Imposter zu
    @MainActor
    func startGame() async {
        stopGameTimer()
        
        // 1. Grundeinstellungen validieren
        if !gameSettings.randomSpyCount {
            let cap = maxAllowedImposters(for: gameSettings.players.count)
            gameSettings.numberOfImposters = min(max(1, gameSettings.numberOfImposters), cap)
        }
        
        // Spiel zurücksetzen
        gameSettings.resetGame()
        HintService.shared.resetState()

        guard let roundCategory = gameSettings.chooseRoundCategory(),
              !roundCategory.words.isEmpty,
              gameSettings.players.count >= 4 else {
            return
        }
        
        // 2. Begriffe wählen
        let gameWords = selectWordsForGameMode(from: roundCategory)
        
        // 3. Rollen verteilen (Core Logic)
        distributeRoles(playersCount: gameSettings.players.count)
        
        // 4. Texte generieren und zuweisen
        await assignWordsToPlayers(gameWords: gameWords)
        
        // 5. Spielzustand setzen
        gameSettings.gamePhase = .cardReveal
        gameSettings.currentPlayerIndex = 0
        gameSettings.timeRemaining = gameSettings.timeLimit
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
                let twin1 = availableIds.randomElement()!
                availableIds.remove(twin1)
                let twin2 = availableIds.randomElement()!
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
    private func selectWordsForGameMode(from category: Category) -> GameWords {
        switch gameSettings.gameMode {
        case .classic:
            let word = category.words.randomElement()!
            return GameWords(primary: word, secondary: nil)
            
        case .twoWords:
            // Zwei verschiedene Begriffe aus derselben Kategorie
            let shuffledWords = category.words.shuffled()
            let primary = shuffledWords[0]
            let secondary = shuffledWords.count > 1 ? shuffledWords[1] : primary
            return GameWords(primary: primary, secondary: secondary)
            
        case .roles:
            let word = category.words.randomElement()!
            return GameWords(primary: word, secondary: nil)
        case .questions:
            let word = category.words.randomElement()!
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
    }
    
    /// Geht zum nächsten Spieler über
    func nextPlayer() {
        if gameSettings.currentPlayerIndex < gameSettings.players.count - 1 {
            gameSettings.currentPlayerIndex += 1
        } else {
            gameSettings.gamePhase = .playing
            startTimer()
        }
    }
    
    /// Startet den Timer
    private func startTimer() {
        if allPlayersSeenCards {
            startGameTimer()
            gameSettings.isTimerPaused = false
            
            if gameSettings.gameMode != .twoWords,
               let category = gameSettings.roundCategory,
               let normalPlayer = gameSettings.players.first(where: { !$0.isImposter }) {
                HintService.shared.startHints(for: normalPlayer.word, category: category, players: gameSettings.players)
            }
        } else {
            gameSettings.isTimerPaused = true
        }
    }

    private func startGameTimer() {
        guard gameTimer == nil else { return }
        gameTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if !self.gameSettings.isTimerPaused && self.gameSettings.timeRemaining > 0 {
                self.gameSettings.timeRemaining -= 1
            }
            if self.gameSettings.timeRemaining <= 0 {
                self.gameSettings.gamePhase = .finished
                self.gameSettings.markRoundCompleted()
                self.stopGameTimer()
                
                Task { @MainActor in
                    let spies = self.gameSettings.players.filter { $0.isImposter }
                    let citizens = self.gameSettings.players.filter { !$0.isImposter }
                    
                    for spy in spies {
                        StatsService.shared.recordSpyWinTimeOut(spyName: spy.name)
                    }
                    StatsService.shared.recordLoss(playerNames: citizens.map { $0.name }, asImposter: false)
                }
            }
        }
    }

    func stopGameTimer() {
        gameTimer?.invalidate()
        gameTimer = nil
        HintService.shared.stopHints()
        VoiceService.shared.stopSpeaking()
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
