//
//  VoteResult.swift
//  Imposter
//
//  Created by Ken on 23.09.25.
//

import Foundation
import Combine

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
class VotingManager: ObservableObject {
    @Published var selectedPlayers: Set<UUID> = []  // Ausgewählte Spieler zum Voten
    @Published var isVotingActive = false
    @Published var showResults = false
    @Published var lastRoundResult: VotingRoundResult?
    
    /// Gesamtanzahl abgegebener Stimmen
    var totalVotes: Int {
        selectedPlayers.count
    }
    
    @Published var votingRound = 1
    @Published var foundSpies: Set<UUID> = []  // Bereits gefundene Spione
    @Published var gameEnded = false
    @Published var playersWon = false
    
    private let gameSettings: GameSettings
    private var wasTimerPausedBefore = false

    init(gameSettings: GameSettings) {
        self.gameSettings = gameSettings
    }
    
    /// Startet die Abstimmungsphase
    func startVoting() {
        // Sync VM state from truth in gameSettings: rebuild foundSpies from eliminated imposters
        let eliminatedImposters = gameSettings.players.filter { $0.isImposter && $0.isEliminated }.map { $0.id }
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
        lastRoundResult = nil
    }
    
    /// Wählt einen Spieler aus/ab
    func togglePlayerSelection(_ playerID: UUID) {
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
        
        // Prüfen welche Auswahl korrekt war
        for playerID in selectedPlayers {
            if let index = gameSettings.players.firstIndex(where: { $0.id == playerID }) {
                let player = gameSettings.players[index]
                if player.isImposter && !foundSpies.contains(playerID) {
                    correctGuesses.append(playerID)
                    foundSpies.insert(playerID)
                    // Mark the spy as eliminated so they won't appear in future voting rounds
                    gameSettings.players[index].isEliminated = true
                } else {
                    incorrectGuesses.append(playerID)
                }
            }
        }
        
        // Spiel-Ende-Logik
        // Regel (klassisch): Spiel endet, wenn mindestens ein falscher Tipp abgegeben wurde ODER alle Spione gefunden wurden.
        // Bewohner gewinnen nur, wenn alle Spione gefunden wurden und kein falscher Tipp dabei war.
        let gameEnded = !incorrectGuesses.isEmpty || foundSpies.count == totalSpies
        let playersWon = incorrectGuesses.isEmpty && foundSpies.count == totalSpies
        
        self.gameEnded = gameEnded
        self.playersWon = playersWon
        
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
    
    /// Beendet die Abstimmung und zeigt Ergebnisse
    func finishVoting() {
        isVotingActive = false
        showResults = true
        if gameEnded {
            gameSettings.markRoundCompleted()
        }
    }
    
    /// Setzt die Abstimmung zurück für nächste Runde
    func resetForNextRound() {
        selectedPlayers.removeAll()
        isVotingActive = false
        showResults = false
        votingRound += 1
        lastRoundResult = nil
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
    }
    
    /// Setzt Timer-Status zurück
    func restoreTimerState() {
        if !wasTimerPausedBefore {
            gameSettings.isTimerPaused = false
        }
    }
    
    /// Gesamtanzahl der Spione
    var totalSpies: Int {
        return gameSettings.players.filter { $0.isImposter }.count
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