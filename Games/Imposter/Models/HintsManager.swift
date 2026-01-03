//
//  HintsManager.swift
//  Imposter
//
//  Created by Ken on 23.09.25.
//

import Foundation
import Combine

/// Manager-Klasse für die Verwaltung von Spion-Hinweisen
class HintsManager: ObservableObject {
    
    /// Erstellt einen formatierten Hinweis-Text für Spione basierend auf der Skizze
    /// - Parameters:
    ///   - word: Das Wort der normalen Spieler
    ///   - categoryName: Name der Kategorie
    ///   - categoryEmoji: Emoji der Kategorie
    ///   - showCategory: Ob die Kategorie angezeigt werden soll
    ///   - showHints: Ob Hinweise angezeigt werden sollen
    ///   - otherSpyNames: Namen der anderen Spione (für Mitspione-Anzeige)
    /// - Returns: Formatierter Text für die Spion-Karte
    static func createSpyCardText(
        word: String, 
        categoryName: String,
        categoryEmoji: String,
        showCategory: Bool, 
        showHints: Bool,
        otherSpyNames: [String] = []
    ) -> String {
        var components: [String] = []
        
        // 1. Titel (wie in Skizze)
        // components.append("Du bist der Spion") // removed as per instruction
        
        // 2. Kategorie mit Emoji (wenn aktiviert)
        if showCategory {
            components.append("\(categoryEmoji) \(categoryName)")
        }
        
        // 3. Hinweis (wenn aktiviert und verfügbar)
        if showHints {
            let hints = CategoryHints.getHints(for: word, in: categoryName)
            if !hints.isEmpty {
                let singleHint = hints[0]
                components.append("Hinweis: \(singleHint)")
            }
        }
        
        // 4. Mitspione (wenn vorhanden)
        if !otherSpyNames.isEmpty {
            components.append("Mitspione:")
            
            // Namen in Gruppen von 3 aufteilen (wie in Skizze)
            let chunkedNames = otherSpyNames.chunked(into: 3)
            for chunk in chunkedNames {
                components.append(chunk.joined(separator: ", "))
            }
        }
        
        return components.joined(separator: "\n\n")
    }
    
    /// Erstellt einen formatierten Hinweis-Text für Spione mit KI-Unterstützung
    /// - Parameters:
    ///   - word: Das Wort der normalen Spieler
    ///   - categoryName: Name der Kategorie
    ///   - category: Category-Objekt (für KI-Generierung)
    ///   - categoryEmoji: Emoji der Kategorie
    ///   - showCategory: Ob die Kategorie angezeigt werden soll
    ///   - showHints: Ob Hinweise angezeigt werden sollen
    ///   - otherSpyNames: Namen der anderen Spione (für Mitspione-Anzeige)
    /// - Returns: Formatierter Text für die Spion-Karte
    @MainActor
    static func createSpyCardTextWithAI(
        word: String,
        categoryName: String,
        category: Category,
        categoryEmoji: String,
        showCategory: Bool,
        showHints: Bool,
        otherSpyNames: [String] = []
    ) async -> String {
        var components: [String] = []
        
        // 1. Kategorie mit Emoji (wenn aktiviert)
        if showCategory {
            components.append("\(categoryEmoji) \(categoryName)")
        }
        
        // 2. Hinweis (wenn aktiviert und verfügbar) - mit KI-Unterstützung
        if showHints {
            let hints = await CategoryHints.getHintsWithAI(for: word, in: categoryName, category: category)
            if !hints.isEmpty {
                let singleHint = hints[0]
                components.append("Hinweis: \(singleHint)")
            }
        }
        
        // 3. Mitspione (wenn vorhanden)
        if !otherSpyNames.isEmpty {
            components.append("Mitspione:")
            
            // Namen in Gruppen von 3 aufteilen
            let chunkedNames = otherSpyNames.chunked(into: 3)
            for chunk in chunkedNames {
                components.append(chunk.joined(separator: ", "))
            }
        }
        
        return components.joined(separator: "\n\n")
    }
    
    /// Überprüft ob für ein bestimmtes Wort in einer Kategorie Hinweise verfügbar sind
    /// - Parameters:
    ///   - word: Das zu überprüfende Wort
    ///   - categoryName: Name der Kategorie
    /// - Returns: true wenn Hinweise verfügbar sind
    static func areHintsAvailable(for word: String, in categoryName: String) -> Bool {
        return CategoryHints.hasHints(for: word, in: categoryName)
    }
    
    /// Überprüft ob für ein bestimmtes Wort in einer Kategorie Hinweise verfügbar sind (inkl. KI)
    /// - Parameters:
    ///   - word: Das zu überprüfende Wort
    ///   - categoryName: Name der Kategorie
    ///   - category: Category-Objekt (für KI-Generierung)
    /// - Returns: true wenn Hinweise verfügbar sind oder generiert werden können
    @MainActor
    static func areHintsAvailableWithAI(for word: String, in categoryName: String, category: Category) async -> Bool {
        return await CategoryHints.hasHintsWithAI(for: word, in: categoryName, category: category)
    }
    
    /// Gibt Statistiken über verfügbare Hinweise zurück
    /// - Parameter categoryName: Name der Kategorie
    /// - Returns: Tupel mit (Anzahl Begriffe mit Hinweisen, Gesamte verfügbare Hinweise)
    static func getHintsStats(for categoryName: String) -> (wordsWithHints: Int, totalHints: Int) {
        let wordsWithHints = CategoryHints.getWordsWithHints(for: categoryName)
        let totalHints = wordsWithHints.reduce(0) { count, word in
            count + CategoryHints.getHints(for: word, in: categoryName).count
        }
        
        return (wordsWithHints.count, totalHints)
    }
    
    /// Erstellt eine Vorschau der verfügbaren Hinweise für eine Kategorie
    /// - Parameter categoryName: Name der Kategorie
    /// - Returns: String mit Beispiel-Hinweisen
    static func getHintsPreview(for categoryName: String) -> String {
        let wordsWithHints = CategoryHints.getWordsWithHints(for: categoryName)
        
        if wordsWithHints.isEmpty {
            return "Keine Hinweise verfügbar für diese Kategorie"
        }
        
        // Nimm die ersten 2 Begriffe als Beispiel
        let exampleWords: [String] = Array(wordsWithHints.prefix(2))
        let examples: [String] = exampleWords.compactMap { (word: String) -> String? in
            let hints: [String] = CategoryHints.getHints(for: word, in: categoryName)
            let firstTwoHints: [String] = Array(hints.prefix(2))
            if firstTwoHints.isEmpty { return nil }
            return "\(word): \(firstTwoHints.joined(separator: ", "))"
        }
        
        if examples.isEmpty {
            return "Keine Hinweise verfügbar"
        }
        
        return "Beispiele:\n" + examples.joined(separator: "\n")
    }
}

