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

    private func debugDumpState(_ context: String) {
        print("\n===== 🧭 VotingManager DEBUG [\(context)] =====")
        print("isVotingActive=\(isVotingActive) | showResults=\(showResults) | votingRound=\(votingRound)")
        print("gameEnded=\(gameEnded) | playersWon=\(playersWon)")
        print("totalSpies=\(totalSpies) | foundSpies=\(foundSpies.count) | remainingSpies=\(remainingSpies)")
        print("selectedPlayers(ids)=\(Array(selectedPlayers))")
        if let gs = Optional(gameSettings) {
            let selectedNames = gs.players.filter { selectedPlayers.contains($0.id) }.map { $0.name }
            let foundNames = gs.players.filter { foundSpies.contains($0.id) }.map { $0.name }
            print("selectedPlayers(names)=\(selectedNames)")
            print("foundSpies(names)=\(foundNames)")
            print("-- Players --")
            for p in gs.players {
                print("  • \(p.name) | isImposter=\(p.isImposter) | isEliminated=\(p.isEliminated) | id=\(p.id)")
            }
        }
        print("===== END VM DEBUG =====\n")
    }
    
    init(gameSettings: GameSettings) {
        self.gameSettings = gameSettings
    }
    
    /// Startet die Abstimmungsphase
    func startVoting() {
        print("🚦 VotingManager.startVoting()")
        debugDumpState("before-startVoting")
        // Sync VM state from truth in gameSettings: rebuild foundSpies from eliminated imposters
        let eliminatedImposters = gameSettings.players.filter { $0.isImposter && $0.isEliminated }.map { $0.id }
        let eliminatedSet = Set(eliminatedImposters)
        if !eliminatedSet.isEmpty {
            print("🔗 Sync: Rebuilding foundSpies from eliminated imposters in GameSettings → ids=\(eliminatedImposters)")
        }
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
        debugDumpState("after-startVoting")
    }
    
    /// Wählt einen Spieler aus/ab
    func togglePlayerSelection(_ playerID: UUID) {
        guard isVotingActive else {
            print("⚠️ togglePlayerSelection ignored: voting not active")
            return
        }
        // Block eliminated players from being selected
        if let p = gameSettings.players.first(where: { $0.id == playerID }), p.isEliminated {
            print("🚫 togglePlayerSelection blocked: \(p.name) is eliminated")
            return
        }
        if selectedPlayers.contains(playerID) {
            selectedPlayers.remove(playerID)
            print("➖ Deselected: \(playerID)")
        } else {
            selectedPlayers.insert(playerID)
            print("➕ Selected: \(playerID)")
        }
        debugDumpState("after-togglePlayerSelection")
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
            print("⚠️ executeVote ignored: voting not active")
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
        print("🗳️ VotingManager.executeVote()")
        debugDumpState("before-executeVote")
        
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
        
        print("📌 executeVote result: correct=\(correctGuesses.count), incorrect=\(incorrectGuesses.count), gameEnded=\(gameEnded), playersWon=\(playersWon)")
        let correctNames = correctGuesses.compactMap { id in gameSettings.players.first(where: { $0.id == id })?.name }
        let incorrectNames = incorrectGuesses.compactMap { id in gameSettings.players.first(where: { $0.id == id })?.name }
        print("   correct(names)=\(correctNames) | incorrect(names)=\(incorrectNames)")
        debugDumpState("after-executeVote")
        
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
        print("🏁 VotingManager.finishVoting()")
        debugDumpState("before-finishVoting")
        isVotingActive = false
        showResults = true
        if gameEnded {
            gameSettings.markRoundCompleted()
        }
        debugDumpState("after-finishVoting")
    }
    
    /// Setzt die Abstimmung zurück für nächste Runde
    func resetForNextRound() {
        print("🔄 VotingManager.resetForNextRound()")
        debugDumpState("before-resetForNextRound")
        selectedPlayers.removeAll()
        isVotingActive = false
        showResults = false
        votingRound += 1
        lastRoundResult = nil
        debugDumpState("after-resetForNextRound")
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
        print("🧹 VotingManager.resetVoting()")
        debugDumpState("after-resetVoting")
    }
    
    /// Setzt Timer-Status zurück
    func restoreTimerState() {
        print("⏱️ VotingManager.restoreTimerState() wasTimerPausedBefore=\(wasTimerPausedBefore)")
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
