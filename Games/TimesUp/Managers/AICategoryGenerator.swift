//
//  AICategoryGenerator.swift
//  TimesUp
//
//  Created by Ken on 23.09.25.
//

import Foundation
import FoundationModels
import Combine

@MainActor
class AICategoryGenerator: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isAIAvailable = false
    
    // Apple Foundation Models
    private let model = SystemLanguageModel.default
    private var session: LanguageModelSession?
    
    // Fallback Mock-Daten
    private let mockData = MockAIData()
    
    init() {
        checkAIAvailability()
    }
    
    private func checkAIAvailability() {
        switch model.availability {
        case .available:
            isAIAvailable = true
            session = LanguageModelSession(
                model: model,
                instructions: createAIInstructions()
            )
            print("🤖 DEBUG: Apple Intelligence verfügbar - echte KI wird verwendet")
        case .unavailable(.deviceNotEligible):
            isAIAvailable = false
            print("⚠️ DEBUG: Apple Intelligence nicht verfügbar - Gerät nicht kompatibel - verwende Mock-Daten")
        case .unavailable(.appleIntelligenceNotEnabled):
            isAIAvailable = false
            print("⚠️ DEBUG: Apple Intelligence nicht verfügbar - nicht aktiviert in Einstellungen - verwende Mock-Daten")
        case .unavailable(.modelNotReady):
            isAIAvailable = false
            print("⚠️ DEBUG: Apple Intelligence nicht verfügbar - Modell noch nicht bereit - verwende Mock-Daten")
        case .unavailable(let other):
            isAIAvailable = false
            print("⚠️ DEBUG: Apple Intelligence nicht verfügbar - Unbekannter Grund: \(other) - verwende Mock-Daten")
        }
    }
    
    private func createAIInstructions() -> Instructions {
        return Instructions {
            "Du erstellst Time's Up Kategorien mit deutschen Begriffen."
            "Begriffe: bekannt, erratbar, ohne Umlaute."
            "Erstelle exakt die angeforderte Anzahl."
        }
    }
    
    // MARK: - Public Methods
    
    /// Generiert eine neue Kategorie mit Begriffen basierend auf einem Thema
    func generateCategory(for theme: String, difficulty: CategoryDifficulty = .medium) async throws -> GeneratedCategory {
        isLoading = true
        errorMessage = nil
        
        defer {
            isLoading = false
        }
        
        do {
            if isAIAvailable, let session = session {
                print("🤖 DEBUG: Generiere Kategorie '\(theme)' mit ECHTER Apple KI (Schwierigkeit: \(difficulty.rawValue), \(difficulty.wordCount) Begriffe)")
                let rawTerms = try await generateWithAI(theme: theme, difficulty: difficulty, session: session)
                var result = finalizeCategory(name: theme, originalRequest: theme, desiredCount: difficulty.wordCount, rawTerms: rawTerms, allowFillers: false)
                
                if shouldFallbackToMock(result: result, desiredCount: difficulty.wordCount) {
                    print("⚠️ DEBUG: KI Ergebnis zu schwach (unique \(result.terms.count)/\(difficulty.wordCount)) -> nutze Mock-Daten")
                    let mockTerms = try await mockData.generateTerms(for: theme, difficulty: difficulty)
                    result = finalizeCategory(name: theme, originalRequest: theme, desiredCount: difficulty.wordCount, rawTerms: mockTerms, allowFillers: true)
                }
                
                return GeneratedCategory(name: theme, terms: result.terms)
            } else {
                print("⚠️ DEBUG: Generiere Kategorie '\(theme)' mit MOCK-DATEN (Schwierigkeit: \(difficulty.rawValue), \(difficulty.wordCount) Begriffe)")
                let rawTerms = try await mockData.generateTerms(for: theme, difficulty: difficulty)
                let result = finalizeCategory(name: theme, originalRequest: theme, desiredCount: difficulty.wordCount, rawTerms: rawTerms, allowFillers: true)
                return GeneratedCategory(name: theme, terms: result.terms)
            }
        } catch {
            // Prüfe ob es ein Context Window Fehler ist
            if error.localizedDescription.contains("context window") ||
               error.localizedDescription.contains("Exceeded model context") {
                print("📏 DEBUG: Context Window Size überschritten für '\(theme)' - verwende Mock-Daten als Fallback")
                print("📏 DEBUG: Grund: \(error.localizedDescription)")
                
                // Automatischer Fallback auf Mock-Daten
                let terms = try await mockData.generateTerms(for: theme, difficulty: difficulty)
                let result = finalizeCategory(name: theme, originalRequest: theme, desiredCount: difficulty.wordCount, rawTerms: terms, allowFillers: true)
                return GeneratedCategory(name: theme, terms: result.terms)
            } else {
                print("❌ DEBUG: Fehler beim Generieren der Kategorie '\(theme)': \(error.localizedDescription)")
                errorMessage = "Fehler beim Generieren der Kategorie: \(error.localizedDescription)"
                throw error
            }
        }
    }
    
    private func generateWithAI(theme: String, difficulty: CategoryDifficulty, session: LanguageModelSession) async throws -> [Term] {
        let wordCount = difficulty.wordCount
        print("🤖 DEBUG: Erstelle Prompt für Apple KI - Thema: '\(theme)', Schwierigkeit: \(difficulty.rawValue), Ziel: \(wordCount) Begriffe")
        
        // Prompt mit klaren Vorgaben für eindeutige Begriffe
        let topics = theme
            .components(separatedBy: CharacterSet(charactersIn: "&/+,"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        let topicLine: String
        if topics.count > 1 {
            topicLine = "Themen: " + topics.joined(separator: ", ")
        } else {
            topicLine = "Thema: \(theme)"
        }
        
        let prompt = Prompt {
            topicLine
            "Erstelle \(wordCount) eindeutige Begriffe, die zu diesen Themen passen."
            "Jeder Begriff darf nur einmal vorkommen und soll als einzelnes Wort oder kurze Wortgruppe geliefert werden."
            "Keine Nummerierung, keine Duplikate, keine Erklärungen – nur die Begriffe."
        }
        
        print("🤖 DEBUG: Sende Prompt an Apple KI...")
        let response = try await session.respond(
            to: prompt,
            generating: AICategoryResponse.self
        )
        
        let terms = response.content.terms.map { Term(text: $0) }
        print("🤖 DEBUG: Apple KI erfolgreich - \(terms.count) Begriffe generiert")
        print("🤖 DEBUG: Erste 5 Begriffe: \(terms.prefix(5).map { $0.text })")
        
        return terms
    }
    
    private func finalizeCategory(name: String, originalRequest theme: String, desiredCount: Int, rawTerms: [Term], allowFillers: Bool) -> SanitizedTermsResult {
        var sanitized: [Term] = []
        var seen = Set<String>()
        var duplicatesRemoved = 0
        var emptyEntries = 0
        
        for term in rawTerms {
            let cleaned = term.text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !cleaned.isEmpty else {
                emptyEntries += 1
                continue
            }
            let key = cleaned.lowercased()
            guard !seen.contains(key) else {
                duplicatesRemoved += 1
                continue
            }
            seen.insert(key)
            sanitized.append(Term(text: cleaned))
        }
        
        var fillerCount = 0
        if sanitized.count < desiredCount && allowFillers {
            let fillers = mockData.fallbackTerms(for: theme, avoiding: seen, count: desiredCount - sanitized.count)
            fillerCount = fillers.count
            sanitized.append(contentsOf: fillers.map { Term(text: $0) })
        }
        
        if sanitized.count > desiredCount {
            sanitized = Array(sanitized.prefix(desiredCount))
        }
        
        let preview = sanitized.prefix(10).map { $0.text }
        print("🧠 DEBUG: Final Kategorie '\(name)' – Soll: \(desiredCount) | Ergebnis: \(sanitized.count) | Doppelte entfernt: \(duplicatesRemoved) | Leer verworfen: \(emptyEntries) | Filler ergänzt: \(fillerCount)")
        print("🧠 DEBUG: Beispielbegriffe: \(preview)")
        
        return SanitizedTermsResult(
            terms: sanitized,
            duplicatesRemoved: duplicatesRemoved,
            emptyEntries: emptyEntries,
            fillerCount: fillerCount,
            sourceCount: rawTerms.count
        )
    }
    
    private func shouldFallbackToMock(result: SanitizedTermsResult, desiredCount: Int) -> Bool {
        guard desiredCount > 0 else { return false }
        let uniqueRatio = Double(result.terms.count) / Double(desiredCount)
        let duplicateRatio = result.sourceCount > 0 ? Double(result.duplicatesRemoved) / Double(result.sourceCount) : 0
        return uniqueRatio < 0.8 || duplicateRatio > 0.4
    }
    
    /// Generiert eine Kategorie basierend auf mehreren Themen (kombiniert alle Themen)
    func generateMultipleCategories(themes: [String], difficulty: CategoryDifficulty = .medium) async throws -> [GeneratedCategory] {
        // Kombiniere alle Themen zu einem einzigen Thema
        let combinedTheme = themes.joined(separator: " & ")
        print("🔄 DEBUG: Batch-Generierung - Kombiniere Themen: \(themes) zu '\(combinedTheme)'")
        
        do {
            let category = try await generateCategory(for: combinedTheme, difficulty: difficulty)
            print("🔄 DEBUG: Batch-Generierung erfolgreich - 1 Kategorie mit \(category.terms.count) Begriffen erstellt")
            return [category]
        } catch {
            print("❌ DEBUG: Batch-Generierung fehlgeschlagen: \(error.localizedDescription)")
            throw error
        }
    }
}

// MARK: - AI Response Types

@Generable(description: "Eine Kategorie mit Begriffen für das Time's Up Spiel")
struct AICategoryResponse {
    @Guide(description: "Liste der Begriffe für die Kategorie")
    var terms: [String]
}

// MARK: - Supporting Types

enum CategoryDifficulty: String, CaseIterable {
    case easy = "Einfach"
    case medium = "Mittel"
    case hard = "Schwer"
    
    var description: String {
        switch self {
        case .easy:
            return "Einfache, bekannte Begriffe"
        case .medium:
            return "Mittlere Schwierigkeit, gemischte Begriffe"
        case .hard:
            return "Schwierige, spezielle Begriffe"
        }
    }
    
    var wordCount: Int {
        switch self {
        case .easy:
            return 70
        case .medium:
            return 85
        case .hard:
            return 100
        }
    }
}

struct GeneratedCategory {
    let name: String
    let terms: [Term]
}

struct AIResponse: Codable {
    let categoryName: String
    let terms: [String]
}

enum AIGenerationError: LocalizedError {
    case invalidResponseFormat
    case parsingError(Error)
    case networkError(Error)
    case mockDataError
    
    var errorDescription: String? {
        switch self {
        case .invalidResponseFormat:
            return "Die KI-Antwort hat ein ungültiges Format"
        case .parsingError(let error):
            return "Fehler beim Verarbeiten der KI-Antwort: \(error.localizedDescription)"
        case .networkError(let error):
            return "Netzwerkfehler: \(error.localizedDescription)"
        case .mockDataError:
            return "Fehler beim Generieren der Mock-Daten"
        }
    }
}

// MARK: - Mock AI Data
class MockAIData {
    private let termDatabase: [String: [String]] = [
        "Tiere": [
            "Löwe", "Elefant", "Giraffe", "Pinguin", "Delfin", "Tiger", "Bär", "Wolf", "Fuchs", "Hase",
            "Schmetterling", "Biene", "Ameise", "Spinne", "Frosch", "Schlange", "Krokodil", "Papagei", "Eule", "Adler",
            "Hai", "Wal", "Robbe", "Panda", "Koala", "Känguru", "Zebra", "Nashorn", "Hippo", "Gorilla"
        ],
        "Filme": [
            "Titanic", "Star Wars", "Harry Potter", "Der Herr der Ringe", "Batman", "Superman", "Spiderman", "Iron Man",
            "Avengers", "Frozen", "Toy Story", "Shrek", "Lion King", "Aladdin", "Mulan", "Cinderella", "Snow White",
            "Pirates of the Caribbean", "Indiana Jones", "Jurassic Park", "Terminator", "Matrix", "Inception", "Interstellar"
        ],
        "Musik": [
            "Beatles", "Queen", "Michael Jackson", "Madonna", "Elvis Presley", "ABBA", "U2", "Coldplay", "Adele", "Taylor Swift",
            "Gitarre", "Klavier", "Schlagzeug", "Violine", "Trompete", "Saxophon", "Flöte", "Harfe", "Bass", "Keyboard"
        ],
        "Sport": [
            "Fußball", "Basketball", "Tennis", "Golf", "Schwimmen", "Laufen", "Boxen", "Karate", "Yoga", "Volleyball",
            "Hockey", "Baseball", "Cricket", "Rugby", "Skifahren", "Snowboard", "Surfen", "Klettern", "Reiten", "Tanzen"
        ],
        "Essen": [
            "Pizza", "Hamburger", "Pasta", "Sushi", "Döner", "Currywurst", "Bratwurst", "Schnitzel", "Salat", "Suppe",
            "Eis", "Kuchen", "Schokolade", "Apfel", "Banane", "Erdbeere", "Tomate", "Kartoffel", "Reis", "Brot"
        ],
        "Reisen": [
            "Paris", "London", "New York", "Tokyo", "Rom", "Barcelona", "Amsterdam", "Berlin", "München", "Hamburg",
            "Flugzeug", "Zug", "Auto", "Fahrrad", "Schiff", "Bus", "Taxi", "Hotel", "Strand", "Berg"
        ],
        "Wissenschaft": [
            "Einstein", "Newton", "Darwin", "Galileo", "Tesla", "Edison", "Marie Curie", "DNA", "Atom", "Gravitation",
            "Teleskop", "Mikroskop", "Labor", "Experiment", "Hypothese", "Theorie", "Forschung", "Entdeckung", "Erfindung", "Innovation"
        ],
        "Geschichte": [
            "Napoleon", "Caesar", "Cleopatra", "Leonardo da Vinci", "Shakespeare", "Mozart", "Beethoven", "Picasso", "Van Gogh", "Michelangelo",
            "Pyramiden", "Kolosseum", "Akropolis", "Schloss", "Burg", "Kathedrale", "Museum", "Bibliothek", "Universität", "Schule"
        ],
        "Technologie": [
            "Computer", "Smartphone", "Internet", "Wifi", "Bluetooth", "GPS", "Kamera", "Fernseher", "Radio", "Lautsprecher",
            "Roboter", "Künstliche Intelligenz", "Virtual Reality", "Augmented Reality", "Blockchain", "Kryptowährung", "App", "Software", "Hardware", "Chip"
        ],
        "Kunst": [
            "Mona Lisa", "Sternennacht", "Guernica", "Die Geburt der Venus", "Der Schrei", "Mona Lisa", "David", "Venus von Milo", "Sphinx", "Freiheitsstatue",
            "Pinsel", "Leinwand", "Farbe", "Skulptur", "Gemälde", "Zeichnung", "Kunstgalerie", "Museum", "Ausstellung", "Künstler"
        ]
    ]
    
    func generateTerms(for theme: String, difficulty: CategoryDifficulty) async throws -> [Term] {
        // Simuliere Verarbeitungszeit
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 Sekunde
        
        let baseTerms = resolveTermPool(for: theme)
        let termPool = baseTerms.isEmpty ? generateGenericTerms(for: theme) : baseTerms
        let wordCount = difficulty.wordCount
        let selectedTerms = Array(termPool.shuffled().prefix(wordCount))
        
        guard !selectedTerms.isEmpty else {
            throw AIGenerationError.mockDataError
        }
        
        return selectedTerms.map { Term(text: $0) }
    }
    
    private func generateGenericTerms(for theme: String) -> [String] {
        // Fallback für unbekannte Themen
        let genericTerms = [
            "\(theme) 1", "\(theme) 2", "\(theme) 3", "\(theme) 4", "\(theme) 5",
            "\(theme) A", "\(theme) B", "\(theme) C", "\(theme) D", "\(theme) E",
            "\(theme) Alpha", "\(theme) Beta", "\(theme) Gamma", "\(theme) Delta", "\(theme) Epsilon"
        ]
        return genericTerms
    }
    
    func fallbackTerms(for theme: String, avoiding existing: Set<String>, count: Int) -> [String] {
        guard count > 0 else { return [] }
        var results: [String] = []
        var seen = existing
        let candidates = resolveTermPool(for: theme)
        let baseFallback = (candidates.isEmpty ? generateGenericTerms(for: theme) : candidates).shuffled()
        
        for term in baseFallback {
            let key = term.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            guard !seen.contains(key) else { continue }
            seen.insert(key)
            results.append(term)
            if results.count == count { return results }
        }
        
        var fallbackIndex = 1
        while results.count < count {
            let candidate = "\(theme) Bonus \(fallbackIndex)"
            fallbackIndex += 1
            let key = candidate.lowercased()
            guard !seen.contains(key) else { continue }
            seen.insert(key)
            results.append(candidate)
        }
        
        return results
    }
    
    private func resolveTermPool(for theme: String) -> [String] {
        var visited = Set<String>()
        return resolveTermPool(for: theme, visited: &visited)
    }
    
    private func resolveTermPool(for theme: String, visited: inout Set<String>) -> [String] {
        let normalized = theme.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return [] }
        let lower = normalized.lowercased()
        
        if visited.contains(lower) { return [] }
        visited.insert(lower)
        
        if let exact = termDatabase.first(where: { $0.key.lowercased() == lower }) {
            return exact.value
        }
        
        // Split by common separators (&, /, +, comma)
        let separators = CharacterSet(charactersIn: "&/+,")
        let components = normalized.components(separatedBy: separators)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && $0.lowercased() != lower }
        
        if !components.isEmpty {
            return components.flatMap { resolveTermPool(for: $0, visited: &visited) }
        }
        
        // Fuzzy contains (z.B. "Tierwelt" -> "Tiere")
        if let fuzzy = termDatabase.first(where: { lower.contains($0.key.lowercased()) || $0.key.lowercased().contains(lower) }) {
            return fuzzy.value
        }
        
        return []
    }
}

private struct SanitizedTermsResult {
    let terms: [Term]
    let duplicatesRemoved: Int
    let emptyEntries: Int
    let fillerCount: Int
    let sourceCount: Int
}
