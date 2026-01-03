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
        print("🎮 GameLogic.startGame() aufgerufen")
        print("📊 Spieleranzahl: \(gameSettings.players.count)")
        print("📂 Kategorie-Auswahl: \(gameSettings.categorySelectionDisplayName)")
        print("🎯 Anzahl Spione: \(gameSettings.numberOfImposters)")

        stopGameTimer()
        
        // Manuelle Einstellung an Obergrenze anpassen, falls Zufall AUS ist
        if !gameSettings.randomSpyCount {
            let cap = maxAllowedImposters(for: gameSettings.players.count)
            gameSettings.numberOfImposters = min(max(1, gameSettings.numberOfImposters), cap)
        }
        
        // Spiel zurücksetzen bevor neue Spione ausgewählt werden
        gameSettings.resetGame()
        print("🔄 Spiel zurückgesetzt")
        HintService.shared.resetState()

        guard let roundCategory = gameSettings.chooseRoundCategory(),
              !roundCategory.words.isEmpty,
              gameSettings.players.count >= 4 else {
            print("❌ Guard-Fehler: selection=\(gameSettings.categorySelectionDisplayName), roundCategory=\(gameSettings.roundCategory?.name ?? "nil"), players.count=\(gameSettings.players.count)")
            return
        }
        
        print("✅ Guard erfolgreich, starte Spiel (Runden-Kategorie: \(roundCategory.name))")

        // Begriffe basierend auf Spielmodus wählen
        let gameWords = selectWordsForGameMode(from: roundCategory)
        print("📝 Begriffe ausgewählt: primary=\(gameWords.primary), secondary=\(gameWords.secondary ?? "nil")")
        
        // Imposter zufällig auswählen
        let imposters = selectRandomImposters()
        print("🕵️ Ausgewählte Spione: \(imposters.count) - IDs: \(imposters)")
        
        // Begriffe zuweisen (mit KI-Unterstützung für Hinweise)
        await assignWordsToPlayers(gameWords: gameWords, imposters: imposters)
        print("🎯 Begriffe zugewiesen")
        
        // Spielzustand setzen
        gameSettings.gamePhase = .cardReveal
        gameSettings.currentPlayerIndex = 0
        gameSettings.timeRemaining = gameSettings.timeLimit
        print("🎮 Spielzustand gesetzt: phase=\(gameSettings.gamePhase), currentPlayer=\(gameSettings.currentPlayerIndex)")
    }
    
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
    /// - Regel: Niemals mehr als 50% der Spieler (floor(n/2))
    /// - Sonderfall: Bei 4 Spielern maximal 1 Spion
    private func maxAllowedImposters(for playersCount: Int) -> Int {
        if playersCount <= 1 { return 0 }
        if playersCount == 4 { return 1 }
        // Max 50% der Spieler, aber nie >= playersCount
        let cap = max(1, playersCount / 2) // floor
        return min(cap, playersCount - 1)
    }
    
    /// Wählt zufällig Imposter aus den Spielern aus
    private func selectRandomImposters() -> Set<UUID> {
        print("🕵️ selectRandomImposters() aufgerufen")
        let players = gameSettings.players
        let playerIds = players.map { $0.id }
        _ = playerIds.shuffled()
        print("👥 Spieler-IDs: \(playerIds)")
        print("🎲 randomSpyCount: \(gameSettings.randomSpyCount), players.count: \(players.count)")
        
        // Wenn Zufall aktiv ist, erzwinge, dass die manuelle Einstellung nicht über der Obergrenze liegt
        // (UI sollte die manuelle Steuerung deaktivieren; hier nur als Sicherheitsnetz)
        if gameSettings.randomSpyCount {
            let capForUI = maxAllowedImposters(for: players.count)
            if gameSettings.numberOfImposters > capForUI {
                gameSettings.numberOfImposters = capForUI
            }
        }
        
        // Determine imposter count with rules:
        // - Random only if option enabled AND players >= 5
        // - Never exceed 50% of players (floor(n/2)), with special case: 4 players -> max 1
        let cap = maxAllowedImposters(for: players.count)
        let imposterCount: Int
        if gameSettings.randomSpyCount && players.count >= 5 {
            let upperBound = max(1, cap)
            imposterCount = Int.random(in: 1...upperBound)
            print("🎲 Zufällige Spion-Anzahl: \(imposterCount) (upperBound: \(upperBound), cap: \(cap))")
            DispatchQueue.main.async { [weak gameSettings] in
                gameSettings?.numberOfImposters = imposterCount
            }
        } else {
            // Fixed: clamp requested to valid range [1, cap]
            let requested = max(1, gameSettings.numberOfImposters)
            imposterCount = min(requested, cap)
            print("📊 Feste Spion-Anzahl: \(imposterCount) (requested: \(gameSettings.numberOfImposters), cap: \(cap))")
        }
        
        if imposterCount <= 0 || players.isEmpty { 
            print("❌ Keine Spione möglich: imposterCount=\(imposterCount), players.isEmpty=\(players.isEmpty)")
            return [] 
        }
        
        // Use fairness-aware picker
        print("🎯 Rufe ImposterPicker.pickImposters auf...")
        var rng: any RandomNumberGeneratorLike = SystemRNGAdapter()
        // KI-Tuner: Multiplikatoren berechnen (optional)
        let multipliers = AITuner.shared.suggestWeightMultipliers(
            players: playerIds,
            policy: gameSettings.fairnessPolicy,
            state: gameSettings.fairnessState
        )
        
        // Debug-Quelle der Multiplikatoren eindeutig in der Konsole markieren
        if AIService.shared.isAvailable {
            print("🧠 Quelle Multiplikatoren: On-Device KI verfügbar (derzeit heuristische Berechnung)")
        } else {
            print("🧪 Quelle Multiplikatoren: Fallback (KI nicht verfügbar)")
        }
        // Optional: auch in Moderator-Log schreiben
        ModeratorLog.shared.logDebug(
            AIService.shared.isAvailable ? "Spion-Verteilung: KI verfügbar (Heuristik aktiv)" : "Spion-Verteilung: Fallback aktiv",
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
        print("🎯 ImposterPicker Ergebnis: \(picked.count) Spione ausgewählt - \(picked)")
        
        // Update fairness state: set cooldowns for picked, reset streaks for others, record pairs
        let round = gameSettings.fairnessState.currentRound
        let pickedSet = Set(picked)
        print("📊 Fairness Round: \(round)")
        
        // Record pairs and per-player increments
        gameSettings.fairnessState.recordImposters(picked)
        print("📝 Fairness State aktualisiert")
        
        // Apply hard cooldowns for picked
        for id in picked {
            gameSettings.fairnessState.updateStats(for: id) { s in
                s.cooldownUntilRound = round + gameSettings.fairnessPolicy.minCooldownRounds
            }
        }
        
        // Reset streaks for non-picked players that had a streak
        for id in playerIds where !pickedSet.contains(id) {
            gameSettings.fairnessState.updateStats(for: id) { s in
                if s.currentStreak > 0 { s.currentStreak = 0 }
            }
        }
        
        print("✅ selectRandomImposters() abgeschlossen: \(pickedSet.count) Spione")
        return Set(picked)
    }
    
    /// Weist allen Spielern Begriffe zu (Imposter bekommen "SPION" oder Kategorieinfo)
    @MainActor
    private func assignWordsToPlayers(gameWords: GameWords, imposters: Set<UUID>) async {
        print("🎯 assignWordsToPlayers() aufgerufen mit \(imposters.count) Spionen")
        // Normale Spieler (ohne Spione) sammeln
        var normalPlayers: [Int] = []
        
        guard let roundCategory = gameSettings.roundCategory else {
            print("❌ Keine Kategorie ausgewählt")
            return
        }
        
        for i in gameSettings.players.indices {
            let playerId = gameSettings.players[i].id
            let playerName = gameSettings.players[i].name
            
            if imposters.contains(playerId) {
                print("🕵️ \(playerName) ist ein Spion!")
                gameSettings.players[i].isImposter = true
                
                // Spion-Wort abhängig von Einstellungen
                let categoryName = roundCategory.name
                let categoryEmoji = roundCategory.emoji
                let actualWord = gameWords.primary // Das echte Wort für Hinweise
                
                // Andere Spion-Namen sammeln (für Mitspione-Anzeige)
                let otherSpyNames = gameSettings.players.compactMap { player in
                    if imposters.contains(player.id) && player.id != playerId {
                        return player.name
                    }
                    return nil
                }
                
                // Für Spione wird NUR der inhaltliche Text (Kategorie optional, Hinweise optional, Mitspione optional) in den Karten-Text geschrieben.
                // Wichtig: KEIN Titel ("Du bist der Spion") mehr im Text – die UI rendert "IMPOSTER" mittig, Kategorie oben, Mitspione unten.
                // So vermeiden wir jegliche Duplikate zwischen Daten und UI.
                // Nutze KI-Version wenn Hinweise aktiviert sind, sonst normale Version
                let spyText: String
                if gameSettings.showSpyHints {
                    // Nutze KI-Version für automatische Hinweis-Generierung
                    spyText = await HintsManager.createSpyCardTextWithAI(
                        word: actualWord,
                        categoryName: categoryName,
                        category: roundCategory,
                        categoryEmoji: categoryEmoji,
                        showCategory: gameSettings.shouldSpySeeCategory,
                        showHints: gameSettings.showSpyHints,
                        otherSpyNames: gameSettings.shouldSpiesSeeEachOther ? otherSpyNames : []
                    )
                } else {
                    // Normale Version ohne Hinweise
                    spyText = HintsManager.createSpyCardText(
                        word: actualWord,
                        categoryName: categoryName,
                        categoryEmoji: categoryEmoji,
                        showCategory: gameSettings.shouldSpySeeCategory,
                        showHints: false,
                        otherSpyNames: gameSettings.shouldSpiesSeeEachOther ? otherSpyNames : []
                    )
                }
                
                let trimmedSpyText = spyText.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmedSpyText.isEmpty {
                    gameSettings.players[i].word = "Du bist der Spion. Bleib undercover und finde das geheime Wort."
                } else {
                    gameSettings.players[i].word = trimmedSpyText
                }
            } else {
                gameSettings.players[i].isImposter = false
                normalPlayers.append(i)
            }
            
            gameSettings.players[i].hasSeenCard = false
        }
        
        // Begriffe an normale Spieler zuweisen
        await assignWordsToNormalPlayers(normalPlayers: normalPlayers, gameWords: gameWords)
    }
    
    /// Weist normalen Spielern (ohne Spione) Begriffe basierend auf Spielmodus zu
    @MainActor
    private func assignWordsToNormalPlayers(normalPlayers: [Int], gameWords: GameWords) async {
        switch gameSettings.gameMode {
        case .classic:
            // Alle normalen Spieler bekommen denselben Begriff
            for playerIndex in normalPlayers {
                gameSettings.players[playerIndex].word = gameWords.primary
            }
            
        case .twoWords:
            // Normale Spieler in zwei Gruppen aufteilen
            let shuffledPlayers = normalPlayers.shuffled()
            let groupSize = shuffledPlayers.count / 2
            
            // Gruppe A: Erster Begriff
            for i in 0..<groupSize {
                let playerIndex = shuffledPlayers[i]
                gameSettings.players[playerIndex].word = gameWords.primary
            }
            
            // Gruppe B: Zweiter Begriff (oder erster falls nur einer vorhanden)
            for i in groupSize..<shuffledPlayers.count {
                let playerIndex = shuffledPlayers[i]
                gameSettings.players[playerIndex].word = gameWords.secondary ?? gameWords.primary
            }
            
        case .roles:
            // Im Rollen-Modus: Ort zuweisen und Rollen mit KI generieren
            await assignRolesToPlayers(normalPlayers: normalPlayers, location: gameWords.primary)
        case .questions:
            for playerIndex in normalPlayers {
                gameSettings.players[playerIndex].word = gameWords.primary
            }
        }
    }
    
    /// Weist normalen Spielern im Rollen-Modus Rollen zu
    /// - Parameters:
    ///   - normalPlayers: Indizes der normalen Spieler (nicht Imposter)
    ///   - location: Der Ort, an dem das Spiel stattfindet
    @MainActor
    private func assignRolesToPlayers(normalPlayers: [Int], location: String) async {
        print("🎭 Rollen-Modus: Weise Rollen für \(normalPlayers.count) Spieler am Ort '\(location)' zu")
        
        // Alle Spieler bekommen den Ort als Wort
        for playerIndex in normalPlayers {
            gameSettings.players[playerIndex].word = location
        }
        
        // Generiere verschiedene Rollen für alle Spieler
        let aiService = AIService.shared
        let roles = await aiService.generateRoles(for: location, count: normalPlayers.count)
        
        // Weise jedem Spieler eine Rolle zu
        for (index, playerIndex) in normalPlayers.enumerated() {
            if index < roles.count {
                gameSettings.players[playerIndex].role = roles[index]
                print("🎭 Spieler '\(gameSettings.players[playerIndex].name)' bekommt Rolle: '\(roles[index])'")
            } else {
                // Fallback: Generiere einzelne Rolle falls nicht genug generiert wurden
                if let role = await aiService.generateRole(for: location, playerName: gameSettings.players[playerIndex].name) {
                    gameSettings.players[playerIndex].role = role
                    print("🎭 Spieler '\(gameSettings.players[playerIndex].name)' bekommt Rolle (einzeln generiert): '\(role)'")
                } else {
                    gameSettings.players[playerIndex].role = "Besucher"
                    print("🎭 Spieler '\(gameSettings.players[playerIndex].name)' bekommt Fallback-Rolle: 'Besucher'")
                }
            }
        }
    }
    
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
            // Alle Spieler haben ihre Karten gesehen
            gameSettings.gamePhase = .playing
            startTimer()
        }
    }
    
    /// Startet den Timer
    private func startTimer() {
        // Timer läuft zentral in GameLogic
        // WICHTIG: Timer nur starten wenn alle Karten gesehen wurden
        if allPlayersSeenCards {
            startGameTimer()
            gameSettings.isTimerPaused = false
            print("⏰ Timer gestartet - alle Karten wurden gesehen")
            
            // Hinweise-System starten
            if gameSettings.gameMode != .twoWords,
               let category = gameSettings.roundCategory,
               let normalPlayer = gameSettings.players.first(where: { !$0.isImposter }) {
                HintService.shared.startHints(for: normalPlayer.word, category: category)
            }
        } else {
            gameSettings.isTimerPaused = true
            print("⏸️ Timer pausiert - noch nicht alle Karten gesehen")
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
            }
        }
    }

    func stopGameTimer() {
        gameTimer?.invalidate()
        gameTimer = nil
        HintService.shared.stopHints()
        VoiceService.shared.stopSpeaking()
    }
    
    /// Gibt den aktuellen Spieler zurück
    var currentPlayer: Player? {
        guard gameSettings.currentPlayerIndex < gameSettings.players.count else {
            return nil
        }
        return gameSettings.players[gameSettings.currentPlayerIndex]
    }
    
    /// Prüft, ob alle Spieler ihre Karten gesehen haben
    var allPlayersSeenCards: Bool {
        return gameSettings.players.allSatisfy { $0.hasSeenCard }
    }
    
    /// Gibt die Anzahl der noch wartenden Spieler zurück
    var remainingPlayersCount: Int {
        return gameSettings.players.count - gameSettings.currentPlayerIndex - 1
    }
    
    
    // MARK: - Neues Spiel (Option A)
    /// Startet sofort einen komplett neuen Durchlauf.
    /// Verwendung (Option A):
    /// 1) "Neues Spiel"-Button schließt die aktuelle Ansicht (dismiss)
    /// 2) Direkt danach `gameLogic.restartGame()` aufrufen
    ///
    /// WICHTIG: Timer wird pausiert und Spiel wird zurückgesetzt
    func restartGame() async {
        print("🔁 GameLogic.restartGame() aufgerufen")
        
        // Timer stoppen und pausieren
        stopGameTimer()
        gameSettings.isTimerPaused = true
        gameSettings.markRoundCompleted()
        
        // Spiel zurücksetzen (aber Fairness-Statistiken behalten)
        gameSettings.currentPlayerIndex = 0
        gameSettings.gamePhase = .setup
        gameSettings.timeRemaining = gameSettings.timeLimit
        
        // Player states zurücksetzen
        for i in gameSettings.players.indices {
            gameSettings.players[i].hasSeenCard = false
            gameSettings.players[i].isImposter = false
            gameSettings.players[i].word = ""
            gameSettings.players[i].isEliminated = false
        }
        
        // Hinweise-System stoppen
        Task { @MainActor in
            HintService.shared.stopHints()
        }
        
        // Neues Spiel starten (mit neuen Spionen)
        await startGame()
    }
}
