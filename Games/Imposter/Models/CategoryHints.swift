//
//  CategoryHints.swift
//  Imposter
//
//  Created by Ken on 23.09.25.
//

import Foundation

/// Verwaltet Hinweise für Spione zu verschiedenen Kategorien und Begriffen
struct CategoryHints {
    
    /// Sammlung aller verfügbaren Hinweise, organisiert nach Kategorie und Begriff
    static let hintsDatabase: [String: [String: [String]]] = [
        
        // MARK: - Tiere
        "Tiere": [
            "Hund": ["Bellt", "Wau Wau", "Gassi gehen", "Knochen"],
            "Katze": ["Miau", "Schnurrt", "Krallen", "Mäuse jagen"],
            "Elefant": ["Rüssel", "Grau", "Dickhäuter", "Afrika"],
            "Löwe": ["König der Tiere", "Mähne", "Brüllt", "Safari"],
            "Pinguin": ["Schwarz-weiß", "Watschelt", "Antarktis", "Frack"],
            "Delfin": ["Intelligent", "Springt", "Ozean", "Flipper"],
            "Känguru": ["Hüpft", "Beutel", "Australien", "Boxen"],
            "Giraffe": ["Langer Hals", "Flecken", "Hoch", "Afrika"]
        ],
        
        // MARK: - Essen & Trinken
        "Essen & Trinken": [
            "Pizza": ["Italien", "Käse", "Rund", "Stücke"],
            "Burger": ["Brötchen", "Patty", "Fast Food", "McDonald's"],
            "Pasta": ["Italien", "Nudeln", "Sauce", "Spaghetti"],
            "Sushi": ["Japan", "Roher Fisch", "Reis", "Stäbchen"],
            "Kaffee": ["Bohnen", "Wach", "Braun", "Espresso"],
            "Bier": ["Alkohol", "Hopfen", "Kalt", "Oktoberfest"],
            "Wein": ["Trauben", "Rot/Weiß", "Korken", "Frankreich"],
            "Schokolade": ["Süß", "Kakao", "Braun", "Naschen"]
        ],
        
        // MARK: - Berufe
        "Berufe": [
            "Arzt": ["Heilt", "Weißer Kittel", "Stethoskop", "Krankenhaus"],
            "Lehrer": ["Unterrichtet", "Schule", "Tafel", "Schüler"],
            "Polizist": ["Uniform", "Gesetz", "Verhaftet", "Sirene"],
            "Feuerwehrmann": ["Löscht", "Rot", "Leiter", "Sirene"],
            "Koch": ["Küche", "Kocht", "Mütze", "Restaurant"],
            "Pilot": ["Fliegt", "Flugzeug", "Cockpit", "Himmel"],
            "Bäcker": ["Brot", "Früh aufstehen", "Ofen", "Brötchen"],
            "Mechaniker": ["Repariert", "Autos", "Werkzeug", "Öl"]
        ],
        
        // MARK: - Hobbys
        "Hobbys": [
            "Lesen": ["Bücher", "Still", "Wissen", "Bibliothek"],
            "Kochen": ["Küche", "Rezepte", "Herd", "Lecker"],
            "Sport": ["Bewegung", "Schweiß", "Fitness", "Wettkampf"],
            "Musik": ["Instrumente", "Hören", "Konzert", "Melodie"],
            "Malen": ["Pinsel", "Farben", "Kunst", "Kreativ"],
            "Gärtnern": ["Pflanzen", "Erde", "Wasser", "Grün"],
            "Fotografieren": ["Kamera", "Bilder", "Blitz", "Moment"],
            "Tanzen": ["Rhythmus", "Bewegung", "Musik", "Schritte"]
        ],
        
        // MARK: - Gegenstände
        "Gegenstände": [
            "Stuhl": ["Sitzt", "4 Beine", "Lehne", "Möbel"],
            "Tisch": ["Platte", "4 Beine", "Essen", "Möbel"],
            "Handy": ["Telefoniert", "Apps", "Touchscreen", "Klingelt"],
            "Auto": ["Fährt", "4 Räder", "Benzin", "Straße"],
            "Buch": ["Lesen", "Seiten", "Geschichte", "Bibliothek"],
            "Schlüssel": ["Schließt auf", "Metall", "Bund", "Tür"],
            "Brille": ["Sehen", "Gläser", "Nase", "Optiker"],
            "Uhr": ["Zeit", "Tick-Tock", "Zeiger", "Handgelenk"]
        ]
    ]
    
    /// Mappt Kategorienamen auf die in der Hint-Datenbank verwendeten Schlüssel (z.B. "Essen" -> "Essen & Trinken").
    private static func canonicalCategoryName(_ name: String) -> String {
        let normalized = name
            .folding(options: .diacriticInsensitive, locale: .current)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        
        switch normalized {
        case "essen", "essen & trinken", "essen und trinken", "nahrung", "food":
            return "Essen & Trinken"
        case "beruf", "berufe", "job", "jobs":
            return "Berufe"
        case "hobby", "hobbys", "hobbies":
            return "Hobbys"
        case "gegenstand", "gegenstaende", "gegenstande", "objekt", "objekte", "sache", "sachen", "items":
            return "Gegenstände"
        case "tier", "tiere":
            return "Tiere"
        default:
            return name
        }
    }
    
    /// Gibt Hinweise für einen spezifischen Begriff in einer Kategorie zurück
    /// - Parameters:
    ///   - categoryName: Name der Kategorie
    ///   - word: Der Begriff für den Hinweise gesucht werden
    /// - Returns: Array von Hinweisen oder leeres Array wenn keine gefunden
    static func getHints(for word: String, in categoryName: String) -> [String] {
        let canonical = canonicalCategoryName(categoryName)
        return hintsDatabase[canonical]?[word] ?? []
    }
    
    /// Gibt Hinweise für einen Begriff zurück, generiert automatisch mit KI falls keine vorhanden
    /// - Parameters:
    ///   - word: Der Begriff
    ///   - categoryName: Name der Kategorie
    ///   - category: Category-Objekt (für KI-Generierung)
    /// - Returns: Array von Hinweisen
    @MainActor
    static func getHintsWithAI(for word: String, in categoryName: String, category: Category) async -> [String] {
        // Zuerst prüfen ob manuelle Hinweise vorhanden sind
        let canonical = canonicalCategoryName(categoryName)
        if let manualHints = hintsDatabase[canonical]?[word], !manualHints.isEmpty {
            return manualHints
        }
        
        // Falls keine manuellen Hinweise vorhanden, mit KI generieren
        let aiService = AIService.shared
        if aiService.isAvailable {
            let aiHints = await aiService.generateSpyHints(for: word, categoryName: categoryName, count: 4)
            if !aiHints.isEmpty {
                print("🧠 KI-Hinweise für '\(word)' generiert: \(aiHints)")
                return aiHints
            }
        }
        
        // Fallback: Leeres Array
        return []
    }
    
    /// Überprüft ob für einen Begriff Hinweise verfügbar sind
    /// - Parameters:
    ///   - word: Der Begriff
    ///   - categoryName: Name der Kategorie
    /// - Returns: true wenn Hinweise verfügbar sind
    static func hasHints(for word: String, in categoryName: String) -> Bool {
        return !getHints(for: word, in: categoryName).isEmpty
    }
    
    /// Überprüft ob für einen Begriff Hinweise verfügbar sind (inkl. KI-Generierung)
    /// - Parameters:
    ///   - word: Der Begriff
    ///   - categoryName: Name der Kategorie
    ///   - category: Category-Objekt (für KI-Generierung)
    /// - Returns: true wenn Hinweise verfügbar sind oder generiert werden können
    @MainActor
    static func hasHintsWithAI(for word: String, in categoryName: String, category: Category) async -> Bool {
        // Wenn manuelle Hinweise vorhanden, return true
        if hasHints(for: word, in: categoryName) {
            return true
        }
        
        // Prüfe ob KI verfügbar ist
        return AIService.shared.isAvailable
    }
    
    /// Gibt alle verfügbaren Kategorien mit Hinweisen zurück
    static var availableCategories: [String] {
        return Array(hintsDatabase.keys).sorted()
    }
    
    /// Gibt alle Begriffe einer Kategorie mit verfügbaren Hinweisen zurück  
    /// - Parameter categoryName: Name der Kategorie
    /// - Returns: Array von Begriffen die Hinweise haben
    static func getWordsWithHints(for categoryName: String) -> [String] {
        let canonical = canonicalCategoryName(categoryName)
        if let wordsDict = hintsDatabase[canonical] {
            return wordsDict.keys.sorted()
        } else {
            return []
        }
    }
    
    /// Formatiert Hinweise als lesbaren String für die UI
    /// - Parameters:
    ///   - word: Der Begriff
    ///   - categoryName: Name der Kategorie
    ///   - maxHints: Maximale Anzahl von Hinweisen (Standard: 3)
    /// - Returns: Formatierter Hinweis-String
    static func getFormattedHints(for word: String, in categoryName: String, maxHints: Int = 3) -> String {
        let hints = getHints(for: word, in: categoryName)
        let selectedHints = Array(hints.prefix(maxHints))
        
        if selectedHints.isEmpty {
            return "Keine Hinweise verfügbar"
        }
        
        return selectedHints.joined(separator: " • ")
    }
}
