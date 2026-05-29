//
//  WordGuessing.swift
//  Imposter
//
//  Created by Ken on 23.09.25.
//

import Foundation

/// Verwaltet das "Wort erraten" Feature für Spione
@Observable
class WordGuessingManager {
    var guessResult: WordGuessResult?
    
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
            correctWord: getCurrentWordsDisplay(),
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
    
    /// Gibt die aktuellen Bürger-Begriffe zurück. Im Zwei-Begriffe-Modus können das zwei Wörter sein.
    private func getCurrentWordsDisplay() -> String {
        let words = gameSettings.players
            .filter { !$0.isImposter && $0.roleType?.team != .imposter && $0.roleType != .confused }
            .map { player in
                player.word.components(separatedBy: "\n\n").first ?? player.word
            }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .reduce(into: [String]()) { uniqueWords, word in
                if !uniqueWords.contains(word) {
                    uniqueWords.append(word)
                }
            }

        return words.isEmpty ? "Unbekannt" : words.joined(separator: " / ")
    }
}

/// Ergebnis einer Wort-Erratung
struct WordGuessResult {
    let wasCorrect: Bool
    let correctWord: String
    let spyWon: Bool
    let gameEnded: Bool
}
