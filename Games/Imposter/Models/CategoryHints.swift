//
//  CategoryHints.swift
//  Imposter
//
//  Created by Ken on 23.09.25.
//

import Foundation

enum SpyHintSource: String, Codable, Hashable {
    case curated
    case ai
    case categoryFallback
    case universalFallback
}

enum SpyHintStrength: String, Codable, Hashable {
    case weak
    case medium
    case strong
}

struct SpyHintCandidate: Hashable, Codable {
    let content: String
    let source: SpyHintSource
    let strength: SpyHintStrength
}

/// Verwaltet Hinweise für Spione zu verschiedenen Kategorien und Begriffen
struct CategoryHints {
    
    /// Sammlung aller verfügbaren Hinweise, organisiert nach Kategorie und Begriff
    static let hintsDatabase: [String: [String: [String]]] = [
        
        // MARK: - Tiere
        "Tiere": [
            "Hund": ["Wirkt oft loyal und aufmerksam", "Kann schnell fuer Unruhe sorgen", "Passt gut in vertraute Naehe"],
            "Katze": ["Wirkt ruhig, bis es ploetzlich anders ist", "Haelt gern eigene Regeln ein", "Passt zu stiller Beobachtung"],
            "Elefant": ["Wirkt schwer zu uebersehen", "Steht oft fuer Ruhe und Kraft", "Passt zu grosser Gelassenheit"],
            "Löwe": ["Wirkt stolz und gefaehrlich", "Passt zu Macht und Respekt", "Hat etwas Koenigliches im Auftreten"],
            "Pinguin": ["Wirkt ungewoehnlich elegant und unbeholfen zugleich", "Passt zu Kaelte und Gemeinschaft", "Bewegt sich eher auffaellig"],
            "Delfin": ["Wirkt verspielt und aufmerksam", "Passt zu Wasser und Bewegung", "Hat etwas Freundliches und Kluges"],
            "Känguru": ["Wirkt energiegeladen und sprunghaft", "Passt zu weiter Landschaft", "Bewegt sich eher ungewoehnlich"],
            "Giraffe": ["Wirkt ruhig und auffaellig zugleich", "Hat eine sehr elegante Wirkung", "Passt zu weiter Aussicht"]
        ],
        
        // MARK: - Essen
        "Essen & Trinken": [
            "Pizza": ["Erinnert an geteilte Abende", "Passt zu Hunger und Geselligkeit", "Wirkt selten wie feines Besteck"],
            "Burger": ["Passt zu schnellem Hunger", "Wirkt eher handfest als elegant", "Erinnert an lockere Treffen"],
            "Pasta": ["Passt zu Komfort und Sattwerden", "Wirkt oft wie ein einfaches Lieblingsessen", "Erinnert an warme Teller"],
            "Sushi": ["Wirkt eher fein und ruhig", "Passt zu kleinen Portionen", "Erinnert an Meer und Sorgfalt"],
            "Schokolade": ["Passt zu Belohnung und Versuchung", "Wirkt eher gemuetlich als gesund", "Erinnert an kleine Pausen"]
        ],
        
        // MARK: - Berufe
        "Berufe": [
            "Arzt": ["Wirkt vertrauenswuerdig und ernst", "Passt zu Verantwortung unter Druck", "Menschen hoffen dort auf Hilfe"],
            "Lehrer": ["Passt zu Geduld und Erklaerungen", "Hat oft mit Gruppen zu tun", "Kann streng oder sehr hilfreich wirken"],
            "Polizist": ["Passt zu Regeln und Kontrolle", "Wirkt offiziell und aufmerksam", "Taucht oft auf, wenn etwas nicht stimmt"],
            "Feuerwehrmann": ["Passt zu Gefahr und schnellem Handeln", "Wirkt mutig und praktisch", "Kommt oft, wenn andere weggehen"],
            "Koch": ["Passt zu Hitze und Timing", "Arbeitet oft hinter den Kulissen", "Macht aus Zutaten etwas Fertiges"],
            "Pilot": ["Passt zu Verantwortung und Technik", "Hat oft grosse Distanzen im Blick", "Wirkt ruhig, obwohl viel passiert"],
            "Bäcker": ["Passt zu fruehem Alltag", "Erinnert an Waerme und Handwerk", "Macht etwas, das viele morgens wollen"],
            "Mechaniker": ["Passt zu Oel und Geduld", "Findet Probleme, die andere nur hoeren", "Arbeitet oft mit den Haenden"]
        ]
    ]

    private static let categoryFallbackHints: [String: [String]] = [
        "Tiere": [
            "Es passt zu Instinkt und Bewegung",
            "Es wirkt lebendig und schwer ganz zu kontrollieren",
            "Man verbindet es mit einer bestimmten Umgebung",
            "Es kann Naehe oder Respekt ausloesen"
        ],
        "Länder": [
            "Es hat eigene Geschichten und Gewohnheiten",
            "Man kann dort vieles wiedererkennen",
            "Es klingt nach Reise und Herkunft",
            "Es hat mehr als nur einen bekannten Ort"
        ],
        "Berufe": [
            "Es verlangt bestimmte Faehigkeiten",
            "Menschen verlassen sich darauf",
            "Es kann ruhig oder sehr stressig sein",
            "Man erkennt es oft an typischen Situationen"
        ],
        "Früchte": [
            "Es erinnert an Frische und Farbe",
            "Es passt zu etwas Natuerlichem und Essbarem",
            "Man verbindet es oft mit Geschmack",
            "Es kann klein wirken und trotzdem auffallen"
        ],
        "Gemüse": [
            "Es passt zu Kueche und Alltag",
            "Es wirkt eher praktisch als festlich",
            "Man verbindet es mit Frische",
            "Es landet oft neben anderen Zutaten"
        ],
        "Städte": [
            "Es klingt nach Menschen und Bewegung",
            "Man kann dort viel entdecken",
            "Es hat einen eigenen Rhythmus",
            "Es ist mehr als nur ein Punkt auf der Karte"
        ],
        "Sportarten": [
            "Es braucht Konzentration und Koerpergefuehl",
            "Es kann schnell sehr laut werden",
            "Regeln machen dort den Unterschied",
            "Man merkt oft sofort, wer geuebt ist"
        ],
        "Fahrzeuge": [
            "Es passt zu Bewegung und Ziel",
            "Man benutzt es, um irgendwohin zu kommen",
            "Es wirkt praktisch, manchmal auch auffaellig",
            "Es veraendert, wie schnell man vorankommt"
        ],
        "Berühmtheiten": [
            "Viele kennen mehr das Bild als die Person",
            "Es klingt nach Buehne und Aufmerksamkeit",
            "Meinungen darueber koennen stark auseinandergehen",
            "Es hat mit Wiedererkennung zu tun"
        ],
        "Marken": [
            "Man erkennt es oft schon am Stil",
            "Es steht fuer ein bestimmtes Gefuehl",
            "Es taucht im Alltag schneller auf als gedacht",
            "Menschen verbinden damit Erwartungen"
        ],
        "FSK 18": [
            "Es passt eher zu spaeten Stunden",
            "Es wirkt nicht ganz harmlos",
            "Man spricht darueber oft vorsichtig",
            "Es kann fuer Diskussionen sorgen"
        ],
        "Essen & Trinken": [
            "Es erinnert an Geschmack und Stimmung",
            "Man teilt es manchmal mit anderen",
            "Es kann schlicht oder besonders wirken",
            "Es passt zu Hunger, Lust oder Gewohnheit"
        ],
        "Superkräfte": [
            "Es wuerde eine Situation sofort veraendern",
            "Man wuerde es wahrscheinlich verstecken",
            "Es klingt nach Wunsch und Risiko",
            "Es waere nuetzlich, aber nicht immer bequem"
        ],
        "Körper & Gesundheit": [
            "Es gehoert zu Alltag und Koerpergefuehl",
            "Man merkt es oft erst, wenn etwas nicht stimmt",
            "Es kann privat oder sehr sichtbar sein",
            "Es wirkt vertraut, aber nicht immer angenehm"
        ],
        "Orte": [
            "Man verhaelt sich dort anders als zuhause",
            "Es hat eine bestimmte Stimmung",
            "Menschen gehen aus einem Grund dorthin",
            "Es kann vertraut oder unangenehm wirken"
        ],
        "Filme & Serien": [
            "Es lebt von Stimmung und Erinnerung",
            "Viele kennen es aus gemeinsamen Abenden",
            "Es hat Figuren, Szenen oder Konflikte",
            "Man kann darueber reden, ohne alles zu verraten"
        ],
        "Alltagsgegenstände": [
            "Es taucht oft nebenbei im Alltag auf",
            "Man benutzt es meist ohne viel nachzudenken",
            "Es liegt schnell herum oder wird gesucht",
            "Es wirkt praktisch, bis es fehlt"
        ],
        "Events & Anlässe": [
            "Es bringt Menschen in eine bestimmte Stimmung",
            "Man bereitet sich oft darauf vor",
            "Es hat typische Regeln oder Erwartungen",
            "Danach bleiben oft Geschichten uebrig"
        ],
        "Schule & Uni": [
            "Es erinnert an Lernen und Organisation",
            "Man verbindet es mit Druck oder Routine",
            "Es hat oft mit Gruppen und Regeln zu tun",
            "Es kann peinlich, wichtig oder langweilig wirken"
        ]
    ]

    private static let universalFallbackHints = [
        "Es hat eine klare Stimmung",
        "Man kann es mit Alltag verbinden",
        "Es wirkt in Gesprächen schnell vertraut",
        "Es laesst mehrere Antworten offen"
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
        case "tier", "tiere":
            return "Tiere"
        case "land", "laender", "lander":
            return "Länder"
        case "frucht", "fruechte", "fruchte":
            return "Früchte"
        case "gemuse", "gemuese":
            return "Gemüse"
        case "stadt", "staedte", "stadte":
            return "Städte"
        case "sport", "sportart", "sportarten":
            return "Sportarten"
        case "fahrzeug", "fahrzeuge":
            return "Fahrzeuge"
        case "beruehmtheit", "beruehmtheiten", "beruhmtheit", "beruhmtheiten", "promi", "promis":
            return "Berühmtheiten"
        case "marke", "marken":
            return "Marken"
        case "fsk 18", "fsk18":
            return "FSK 18"
        case "superkraft", "superkraefte", "superkrafte":
            return "Superkräfte"
        case "korper & gesundheit", "koerper & gesundheit", "körper & gesundheit", "gesundheit":
            return "Körper & Gesundheit"
        case "ort", "orte":
            return "Orte"
        case "film", "filme", "serie", "serien", "kino", "filme & serien", "filme und serien":
            return "Filme & Serien"
        case "alltagsgegenstand", "alltagsgegenstaende", "alltagsgegenstande", "gegenstand", "gegenstaende", "gegenstande", "objekt", "objekte", "ding", "dinge":
            return "Alltagsgegenstände"
        case "event", "events", "anlass", "anlaesse", "anlasse", "events & anlaesse", "events & anlässe", "events und anlaesse", "events und anlässe":
            return "Events & Anlässe"
        case "schule", "uni", "universitaet", "universität", "schule & uni", "schule und uni", "studium", "campus":
            return "Schule & Uni"
        default:
            return name
        }
    }

    private static func cleanHint(_ hint: String) -> String {
        hint
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
    }

    private static func normalized(_ text: String) -> String {
        var result = text.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
        result = result.replacingOccurrences(of: "ß", with: "ss")
        result = result.replacingOccurrences(of: "[^a-z0-9 ]", with: " ", options: .regularExpression)
        result = result.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func isSafeHint(_ hint: String, word: String) -> Bool {
        let clean = cleanHint(hint)
        guard clean.count >= 8 else { return false }

        let normalizedHint = normalized(clean)
        let normalizedWord = normalized(word)
        guard !normalizedHint.isEmpty, !normalizedWord.isEmpty else { return false }
        guard !normalizedHint.split(separator: " ").contains(Substring(normalizedWord)) else { return false }
        guard !normalizedHint.contains(normalizedWord) else { return false }

        let bannedPhrases = [
            "beginnt mit", "endet mit", "buchstabe", "buchstaben", "reimt",
            "wie ein", "wie eine", "einzig", "nur dieses", "sofort klar",
            "es ist ein tier", "es ist eine frucht", "es ist ein beruf", "es ist ein ort"
        ]
        return !bannedPhrases.contains { normalizedHint.contains($0) }
    }

    private static func candidates(
        from hints: [String],
        source: SpyHintSource,
        strength: SpyHintStrength,
        word: String
    ) -> [SpyHintCandidate] {
        var seen: Set<String> = []
        return hints.compactMap { hint in
            let clean = cleanHint(hint)
            guard isSafeHint(clean, word: word) else { return nil }
            let key = normalized(clean)
            guard !seen.contains(key) else { return nil }
            seen.insert(key)
            return SpyHintCandidate(content: clean, source: source, strength: strength)
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

    static func getFallbackHints(for word: String, in categoryName: String) -> [String] {
        let canonical = canonicalCategoryName(categoryName)
        let hints = categoryFallbackHints[canonical] ?? universalFallbackHints
        return candidates(from: hints, source: .categoryFallback, strength: .weak, word: word).map(\.content)
    }

    static func getBestSpyHintsOffline(for word: String, in categoryName: String) -> [SpyHintCandidate] {
        let curated = candidates(from: getHints(for: word, in: categoryName), source: .curated, strength: .medium, word: word)
        if !curated.isEmpty { return curated }

        let fallback = candidates(
            from: categoryFallbackHints[canonicalCategoryName(categoryName)] ?? [],
            source: .categoryFallback,
            strength: .weak,
            word: word
        )
        if !fallback.isEmpty { return fallback }

        return candidates(from: universalFallbackHints, source: .universalFallback, strength: .weak, word: word)
    }

    @MainActor
    static func getBestSpyHints(for word: String, in categoryName: String, category: Category) async -> [SpyHintCandidate] {
        let curated = candidates(from: getHints(for: word, in: categoryName), source: .curated, strength: .medium, word: word)
        if !curated.isEmpty { return curated }

        let aiService = AIService.shared
        if aiService.isAvailable {
            let aiHints = await aiService.generateSpyHints(for: word, categoryName: categoryName, count: 4)
            let aiCandidates = candidates(from: aiHints, source: .ai, strength: .medium, word: word)
            if !aiCandidates.isEmpty {
                print("🧠 KI-Hinweise für '\(word)' generiert: \(aiCandidates.map(\.content))")
                return aiCandidates
            }
        }

        return getBestSpyHintsOffline(for: word, in: categoryName)
    }

    @MainActor
    static func getBestSpyHint(for word: String, in categoryName: String, category: Category) async -> SpyHintCandidate {
        let hints = await getBestSpyHints(for: word, in: categoryName, category: category)
        return hints.randomElement() ?? SpyHintCandidate(
            content: "Es laesst mehrere Antworten offen",
            source: .universalFallback,
            strength: .weak
        )
    }
    
    /// Gibt Hinweise für einen Begriff zurück, generiert automatisch mit KI falls keine vorhanden
    /// - Parameters:
    ///   - word: Der Begriff
    ///   - categoryName: Name der Kategorie
    ///   - category: Category-Objekt (für KI-Generierung)
    /// - Returns: Array von Hinweisen
    @MainActor
    static func getHintsWithAI(for word: String, in categoryName: String, category: Category) async -> [String] {
        (await getBestSpyHints(for: word, in: categoryName, category: category)).map(\.content)
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
        return !(await getBestSpyHints(for: word, in: categoryName, category: category)).isEmpty
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
