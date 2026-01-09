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
    
    /// Erstellt den Text für eine spezielle Rollenkarte
    /// - Parameters:
    ///   - role: Die Rolle des Spielers
    ///   - word: Das echte Wort der Runde
    ///   - category: Die Kategorie der Runde
    ///   - allPlayers: Alle Spieler (um Informationen über andere Rollen zu finden)
    ///   - currentPlayer: Der Spieler, für den die Karte erstellt wird
    /// - Returns: Formatierter Text für die Karte
    static func createRoleCardText(
        role: RoleType,
        word: String,
        category: Category,
        allPlayers: [Player],
        currentPlayer: Player
    ) -> String {
        var components: [String] = []
        
        // 1. Das Wort (oder ein falsches Wort für Pechvogel)
        if role == .confused {
            // Pechvogel bekommt ein zufälliges anderes Wort aus der Kategorie
            var otherWords = category.words.filter { $0 != word }
            if otherWords.isEmpty {
                // Fallback: Sollte nicht passieren, aber sicher ist sicher
                components.append(word)
            } else {
                let fakeWord = otherWords.randomElement()!
                components.append(fakeWord)
            }
        } else {
            // Alle anderen sehen das echte Wort
            components.append(word)
        }
        
        // 2. Rollen-Spezifische Zusatzinfos
        switch role {
        case .secretAgent:
            // Sieht den Spion (und Saboteur/Maulwurf/Hacker als "Böse")
            let badGuys = allPlayers.filter { $0.isImposter || $0.roleType == .saboteur || $0.roleType == .mole || $0.roleType == .hacker }
                .filter { $0.id != currentPlayer.id } // Sich selbst nicht anzeigen
                .map { $0.name }
            
            if !badGuys.isEmpty {
                if badGuys.count == 1 {
                    components.append("Verdächtige Person: \(badGuys[0])")
                } else {
                    components.append("Verdächtige Personen: \(badGuys.joined(separator: ", "))")
                }
            } else {
                components.append("Keine Verdächtigen gefunden.")
            }
            
        case .twins:
            // Sieht den anderen Zwilling
            let otherTwin = allPlayers.first { $0.roleType == .twins && $0.id != currentPlayer.id }
            if let twin = otherTwin {
                components.append("Dein Zwilling: \(twin.name)")
            }
            
        case .saboteur:
            // Sieht den Spion
            let spies = allPlayers.filter { $0.isImposter }.map { $0.name }
            if !spies.isEmpty {
                components.append("Der Spion: \(spies.joined(separator: ", "))")
            }
            
        case .hacker:
            // Hacker hat interaktive Auswahl, braucht hier keine statische Zusatzinfo
            break
            
        case .mole:
            // Maulwurf kennt das Wort, erscheint aber böse für den Agenten
            // Keine Zusatzinfo, nur das Wort
            break
            
        case .fool:
            // Narr will rausfliegen
            // Keine Zusatzinfo, nur das Wort
            break
            
        case .bodyguard:
            // Leibwächter schützt den Agenten
            // Keine Zusatzinfo, nur das Wort
            break
            
        case .confused:
            // Pechvogel hat schon sein falsches Wort oben bekommen
            break
        }
        
        return components.joined(separator: "\n\n")
    }
}

