//
//  WordGuessing.swift
//  Imposter
//
//  Created by Ken on 23.09.25.
//

import Foundation
import Combine

/// Verwaltet das "Wort erraten" Feature für Spione
class WordGuessingManager: ObservableObject {
    @Published var guessResult: WordGuessResult?
    
    private let gameSettings: GameSettings
    
    init(gameSettings: GameSettings) {
        self.gameSettings = gameSettings
    }
    
    /// Bestätigt dass das richtige Wort erraten wurde
    @MainActor
    func confirmCorrectGuess() -> WordGuessResult {
        // Runde sauber beenden: Timer pausieren, Phase setzen und Hilfsdienste stoppen
        gameSettings.isTimerPaused = true
        gameSettings.markRoundCompleted()
        HintService.shared.stopHints()
        VoiceService.shared.stopSpeaking()
        
        let result = WordGuessResult(
            wasCorrect: true,
            correctWord: getCurrentWord(),
            spyWon: true,
            gameEnded: true
        )
        
        // --- Stats Integration ---
        // Finde den Namen des Spions (der aktuelle Spieler, oder einer der Spione)
        // Annahme: Derjenige, der das Handy hält und "raten" drückt, ist der Spion.
        // Wir nehmen den ersten gefundenen Spion als Stellvertreter oder alle Spione, falls Team.
        // Im aktuellen UI-Flow gibt es keine explizite Auswahl "WER" rät. Wir vergeben Punkte an alle Spione.
        let spyNames = gameSettings.players.filter { $0.isImposter }.map { $0.name }
        let isFast = Double(gameSettings.timeRemaining) > (Double(gameSettings.timeLimit) / 2.0)
        
        for name in spyNames {
            StatsService.shared.recordSpyWinWordGuess(spyName: name, isFast: isFast)
        }
        
        // Verlierer (Bürger) registrieren
        let citizenNames = gameSettings.players.filter { !$0.isImposter }.map { $0.name }
        StatsService.shared.recordLoss(playerNames: citizenNames, asImposter: false)
        // -------------------------
        
        guessResult = result
        return result
    }
    
    /// Gibt das aktuelle Wort zurück (für normale Spieler)
    private func getCurrentWord() -> String {
        // Das echte Wort der normalen Spieler finden
        let normalPlayer = gameSettings.players.first { !$0.isImposter }
        return normalPlayer?.word ?? "Unbekannt"
    }
}

/// Ergebnis einer Wort-Erratung
struct WordGuessResult {
    let wasCorrect: Bool
    let correctWord: String
    let spyWon: Bool
    let gameEnded: Bool
}
