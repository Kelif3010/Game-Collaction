//
//  VoteResult.swift
//  Imposter
//
//  Created by Ken on 23.09.25.
//

import Foundation

/// Struktur für Abstimmungsergebnisse
struct VoteResult: Identifiable {
    let id = UUID()
    let playerId: UUID
    let playerName: String
    let voteCount: Int
    let isImposter: Bool
    
    /// Prozentsatz der erhaltenen Stimmen
    func votePercentage(totalVotes: Int) -> Double {
        guard totalVotes > 0 else { return 0.0 }
        return (Double(voteCount) / Double(totalVotes)) * 100
    }
}

/// Voting-Zustand und -Logik
@Observable
class VotingManager {
    var selectedPlayers: Set<UUID> = []
    var isVotingActive = false
    var showResults = false
    var lastRoundResult: VotingRoundResult?

    var totalVotes: Int {
        selectedPlayers.count
    }

    var votingRound = 1
    var foundSpies: Set<UUID> = []
    var gameEnded = false
    var playersWon = false
    var jesterWon = false
    var lastRescueMessage: String?

    // Shootout (Geheimagenten-Jagd)
    var isSpyShootoutActive = false
    var shooter: Player?
    
    private let gameSettings: GameSettings
    private var wasTimerPausedBefore = false

    init(gameSettings: GameSettings) {
        self.gameSettings = gameSettings
    }
    
    /// Startet die Abstimmungsphase
    func startVoting() {
        // Sync VM state from truth in gameSettings: rebuild foundSpies from eliminated imposters
        let eliminatedImposters = gameSettings.players.filter { ($0.isImposter || $0.roleType?.team == .imposter) && $0.isEliminated }.map { $0.id }
        let eliminatedSet = Set(eliminatedImposters)
        foundSpies = eliminatedSet
        // Ensure no eliminated player remains in selection
        selectedPlayers.subtract(eliminatedSet)
        // Timer pausieren und Status merken
        wasTimerPausedBefore = gameSettings.isTimerPaused
        gameSettings.isTimerPaused = true
        
        selectedPlayers.removeAll()
        isVotingActive = true
        showResults = false
        isSpyShootoutActive = false
        shooter = nil
        lastRoundResult = nil
        lastRescueMessage = nil
        jesterWon = false // Reset
    }
    
    /// Wählt einen Spieler aus/ab
    func togglePlayerSelection(_ playerID: UUID, maxSelections: Int? = nil) {
        guard isVotingActive else {
            return
        }
        // Block eliminated players from being selected
        if let p = gameSettings.players.first(where: { $0.id == playerID }), p.isEliminated {
            return
        }
        if selectedPlayers.contains(playerID) {
            selectedPlayers.remove(playerID)
        } else {
            if let maxSelections {
                if maxSelections <= 1 {
                    selectedPlayers = [playerID]
                    return
                }
                if selectedPlayers.count >= maxSelections {
                    return
                }
            } else if !canSelectMore {
                return
            }
            selectedPlayers.insert(playerID)
        }
    }
    
    /// Überprüft ob Spieler ausgewählt werden können
    var canSelectMore: Bool {
        let remainingSpies = totalSpies - foundSpies.count
        return selectedPlayers.count < remainingSpies
    }
    
    /// Überprüft ob Abstimmung möglich ist
    var canVote: Bool {
        return !selectedPlayers.isEmpty
    }
    
    /// Führt die Abstimmung durch und berechnet Ergebnisse
    func executeVote() -> VotingRoundResult {
        guard isVotingActive else {
            return VotingRoundResult(
                selectedPlayers: [],
                correctGuesses: [],
                incorrectGuesses: [],
                gameEnded: false,
                playersWon: false
            )
        }
        guard !selectedPlayers.isEmpty else {
            return VotingRoundResult(
                selectedPlayers: [],
                correctGuesses: [],
                incorrectGuesses: [],
                gameEnded: false,
                playersWon: false
            )
        }
        
        var correctGuesses: [UUID] = []
        var incorrectGuesses: [UUID] = []
        var rescuedPlayers: [String] = []
        jesterWon = false // Reset for safety
        
        // Prüfen welche Auswahl korrekt war
        for playerID in selectedPlayers {
            if let index = gameSettings.players.firstIndex(where: { $0.id == playerID }) {
                let player = gameSettings.players[index]
                
                // 1. Check: Narr (Jester) Win Condition
                if player.roleType == .fool {
                    if player.isProtected {
                         rescuedPlayers.append(player.name)
                         // Narr wird gerettet -> Gewinnt NICHT
                    } else {
                        // Narr wurde gevotet und nicht geschützt -> Narr gewinnt!
                        jesterWon = true
                        gameSettings.players[index].isEliminated = true
                        // Zählt technisch als "incorrect guess" für die Bürger, aber Spiel endet sofort
                        incorrectGuesses.append(playerID) 
                    }
                }
                // 2. Check: Spion (oder Böses Team)
                else if (player.isImposter || player.roleType?.team == .imposter) && !foundSpies.contains(playerID) {
                    // Spion gefunden (Leibwächter schützt Spione NICHT vor dem Voting)
                    correctGuesses.append(playerID)
                    foundSpies.insert(playerID)
                    gameSettings.players[index].isEliminated = true
                } else {
                    // 3. Check: Unschuldiger Bürger/Andere Rolle
                    // PRÜFUNG: Hat der Leibwächter ihn geschützt?
                    if player.isProtected {
                        // GERETTET!
                        rescuedPlayers.append(player.name)
                        // Er zählt NICHT als incorrectGuess für das Spielende, aber er wurde auch nicht eliminiert.
                    } else {
                        // Nicht gerettet -> Fehler -> Spione gewinnen
                        incorrectGuesses.append(playerID)
                    }
                }
            }
        }
        
        // Spiel-Ende-Logik
        // Spiel endet, wenn ein Ungeschützter falsch gevotet wurde ODER alle Spione gefunden sind ODER der Narr gewonnen hat.
        let gameEnded = !incorrectGuesses.isEmpty || foundSpies.count == totalSpies || jesterWon
        // Bürger gewinnen nur, wenn keine Fehler gemacht wurden, alle Spione weg sind UND der Narr NICHT gewonnen hat.
        let playersWon = incorrectGuesses.isEmpty && foundSpies.count == totalSpies && !jesterWon
        
        self.gameEnded = gameEnded
        self.playersWon = playersWon
        
        // Leibwächter-Nachricht setzen
        if !rescuedPlayers.isEmpty {
            let names = rescuedPlayers.joined(separator: ", ")
            lastRescueMessage = "Der Leibwächter hat \(names) vor dem Ausscheiden bewahrt!"
        }
        
        // --- Shootout Check ---
        // Wenn die Bürger gewinnen UND ein Geheimagent im Spiel ist, startet der Shootout.
        if playersWon && gameSettings.activeRoles.contains(.secretAgent) {
            // Finde den Spion, der gerade eliminiert wurde (oder einen der Spione)
            if let shooterID = correctGuesses.last ?? foundSpies.first,
               let shooterPlayer = gameSettings.players.first(where: { $0.id == shooterID }) {
                startShootout(shooter: shooterPlayer)
            }
        } else if gameEnded {
            // --- Stats Integration (Nur wenn kein Shootout, sonst passiert das dort) ---
            Task { @MainActor in
                let spyNames = gameSettings.players.filter { $0.isImposter || $0.roleType?.team == .imposter }.map { $0.name }
                let citizenNames = gameSettings.players.filter { !$0.isImposter && $0.roleType?.team != .imposter }.map { $0.name }
                
                if jesterWon {
                    // Narr gewinnt -> Alle anderen verlieren
                    _ = gameSettings.players.filter { $0.roleType == .fool }.map { $0.name }
                    let losers = spyNames + citizenNames
                    StatsService.shared.recordLoss(playerNames: losers, asImposter: false) // Zählt als Niederlage
                    // TODO: Record Jester Win explicitly if needed in StatsSJa ervice
                } else if playersWon {
                    let isFast = (Double(gameSettings.timeRemaining) > (Double(gameSettings.timeLimit) / 2.0)) || votingRound == 1
                    StatsService.shared.recordCitizenWin(citizenNames: citizenNames, isFast: isFast)
                    StatsService.shared.recordLoss(playerNames: spyNames, asImposter: true)
                } else {
                    StatsService.shared.recordSpyWinByWrongVoting(spyNames: spyNames)
                    StatsService.shared.recordLoss(playerNames: citizenNames, asImposter: false)
                }
            }
        }
        // -------------------------
        
        let result = VotingRoundResult(
            selectedPlayers: Array(selectedPlayers),
            correctGuesses: correctGuesses,
            incorrectGuesses: incorrectGuesses,
            gameEnded: gameEnded,
            playersWon: playersWon
        )
        lastRoundResult = result
        return result
    }
    
    func startShootout(shooter: Player) {
        self.shooter = shooter
        self.isSpyShootoutActive = true
    }
    
    /// Beendet die Abstimmung und zeigt Ergebnisse
    func finishVoting() {
        isVotingActive = false
        // Wenn Shootout aktiv ist, zeigen wir NICHT die normalen Results, sondern gehen in den Shootout Screen
        if !isSpyShootoutActive {
            showResults = true
            if gameEnded {
                gameSettings.markRoundCompleted()
            }
        }
    }
    
    /// Setzt die Abstimmung zurück für nächste Runde
    func resetForNextRound() {
        selectedPlayers.removeAll()
        isVotingActive = false
        showResults = false
        votingRound += 1
        lastRoundResult = nil
        jesterWon = false
    }
    
    /// Setzt die gesamte Abstimmung zurück
    func resetVoting() {
        selectedPlayers.removeAll()
        foundSpies.removeAll()
        isVotingActive = false
        showResults = false
        gameEnded = false
        playersWon = false
        votingRound = 1
        lastRoundResult = nil
        jesterWon = false
    }
    
    /// Setzt Timer-Status zurück
    func restoreTimerState() {
        if !wasTimerPausedBefore {
            gameSettings.isTimerPaused = false
        }
    }
    
    /// Gesamtanzahl der Spione
    var totalSpies: Int {
        let knownSpies = gameSettings.players.filter { $0.isImposter || $0.roleType?.team == .imposter }.count
        if MultipeerManager.shared.role != .unknown {
            let configured = max(1, gameSettings.numberOfImposters)
            return max(configured, knownSpies)
        }
        return knownSpies
    }
    
    /// Verbleibende Spione
    var remainingSpies: Int {
        return totalSpies - foundSpies.count
    }
    
    /// Überprüft ob alle Spione gefunden wurden
    var allSpiesFound: Bool {
        return foundSpies.count == totalSpies
    }
}

/// Ergebnis einer Voting-Runde
struct VotingRoundResult {
    let selectedPlayers: [UUID]
    let correctGuesses: [UUID]
    let incorrectGuesses: [UUID]
    let gameEnded: Bool
    let playersWon: Bool
}
