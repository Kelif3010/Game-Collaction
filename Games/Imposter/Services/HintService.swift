//
//  HintService.swift
//  Imposter
//
//  Created by Ken on 23.09.25.
//

import Foundation
import Combine

/// Intelligentes Hinweise-System mit echten und falschen Hinweisen sowie Challenges
@MainActor
class HintService: ObservableObject {
    static let shared = HintService()
    
    @Published var activeHints: [GameHint] = []
    @Published var hintHistory: [GameHint] = []
    
    private let aiService = AIService.shared
    private let settings = SettingsService.shared
    private let voiceService = VoiceService.shared
    private let moderatorLog = ModeratorLog.shared
    
    // Hinweis-Konfiguration
    private let hintInterval: TimeInterval = 45.0 // Hinweise alle 45 Sekunden
    private let hintProbability: Double = 0.5 // 50% Chance pro Intervall
    
    private var hintTimer: Timer?
    private var currentWord: String = ""
    private var currentCategory: Category?
    private var currentPlayers: [String] = []
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Startet das Hinweise-System für ein Wort
    func startHints(for word: String, category: Category, players: [Player]) {
        currentWord = word
        currentCategory = category
        // Nur aktive (nicht eliminierte) Spieler berücksichtigen
        currentPlayers = players.filter { !$0.isEliminated }.map { $0.name }
        
        guard settings.enableHints else {
            return
        }
        
        // Ersten Hinweis sofort generieren (Start-Bonus)
        Task {
            await generateHint()
        }
        
        // Timer für weitere Hinweise starten
        startHintTimer()
    }
    
    /// Stoppt das Hinweise-System
    func stopHints() {
        hintTimer?.invalidate()
        hintTimer = nil
        activeHints.removeAll()
        currentWord = ""
        currentCategory = nil
        currentPlayers = []
    }

    /// Vollständiger Reset nach einem Spiel
    func resetState() {
        stopHints()
        hintHistory.removeAll()
    }
    
    /// Generiert manuell einen Hinweis
    func generateManualHint() async {
        await generateHint()
    }
    
    // MARK: - Private Methods
    
    private func startHintTimer() {
        hintTimer?.invalidate()
        hintTimer = Timer.scheduledTimer(withTimeInterval: hintInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.checkForHint()
            }
        }
    }
    
    private func checkForHint() async {
        guard settings.enableHints,
              !currentWord.isEmpty,
              Double.random(in: 0...1) < hintProbability else {
            return
        }
        
        await generateHint()
    }
    
    private func generateHint() async {
        guard settings.enableHints,
              !currentWord.isEmpty,
              let category = currentCategory else { return }
        
        do {
            let hint = try await createHint(word: currentWord, category: category)
            await activateHint(hint)
            
            // Moderator-Log
            moderatorLog.logDebug(
                "Game-Content generiert",
                metadata: [
                    "word": currentWord,
                    "type": hint.type.rawValue,
                    "content": hint.content
                ]
            )
            
        } catch {
            print("Error generating hint: \(error)")
        }
    }
    
    private func createHint(word: String, category: Category) async throws -> GameHint {
        if aiService.isAvailable {
            // Nutze die neue, vielseitige KI-Methode
            if let content = await aiService.generateGameContent(word: word, category: category) {
                // Sicherheitscheck: Wort darf nicht im Hinweis vorkommen!
                let safeContent = sanitizeContent(content.content, forbiddenWord: word)
                let safeGameContent = GameContent(type: content.type, content: safeContent, category: content.category, isTrue: content.isTrue)
                return mapGameContentToHint(safeGameContent, word: word, category: category)
            }
        }
        // Fallback wenn KI nicht verfügbar
        return createFallbackContent(word: word, category: category)
    }
    
    private func sanitizeContent(_ text: String, forbiddenWord: String) -> String {
        let pattern = "\\b\(NSRegularExpression.escapedPattern(for: forbiddenWord))\\b"
        // Ersetze das Wort (case-insensitive) durch "Es" oder "Das Gesuchte"
        // Einfache Variante: Wir ersetzen es durch "Es"
        // Um Groß/Kleinschreibung zu beachten, nutzen wir Regex
        if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
            let range = NSRange(location: 0, length: text.utf16.count)
            return regex.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: "Es")
        }
        return text.replacingOccurrences(of: forbiddenWord, with: "Es", options: .caseInsensitive)
    }
    
    private func mapGameContentToHint(_ content: GameContent, word: String, category: Category) -> GameHint {
        var hintType: HintType
        var finalContent = content.content
        
        switch content.type {
        case .hint: 
            hintType = .general
        case .fakeHint: 
            hintType = .fake
        case .challenge: 
            hintType = .challenge
            // Spielername voranstellen für Challenges
            if let randomPlayer = currentPlayers.randomElement() {
                // Punkt statt Komma für saubere Sprachausgabe
                finalContent = "\(randomPlayer). \(finalContent.prefix(1).lowercased() + finalContent.dropFirst())"
            }
        }
        
        return GameHint(
            content: finalContent,
            type: hintType,
            isTrue: content.isTrue,
            word: word,
            category: category
        )
    }
    
    private func createFallbackContent(word: String, category: Category) -> GameHint {
        let rand = Int.random(in: 1...100)
        
        if rand <= 40 { // 40% Challenge (Interaktivität)
            var challenge = getFallbackChallenge(category: category)
            // Spielername voranstellen
            if let randomPlayer = currentPlayers.randomElement() {
                // "Challenge: " Prefix entfernen falls vorhanden, um sauber zu formatieren
                challenge = challenge.replacingOccurrences(of: "Challenge: ", with: "")
                // Punkt für Sprachausgabe
                challenge = "\(randomPlayer). \(challenge.prefix(1).lowercased() + challenge.dropFirst())"
            }
            return GameHint(content: challenge, type: .challenge, isTrue: true, word: word, category: category)
        } else if rand <= 70 { // 30% Fake Hint
            let fake = getFalseFallbackHints(for: word, category: category).randomElement() ?? "Es ist sehr schwer."
            // Auch Fallbacks müssen gesäubert werden (zur Sicherheit)
            let safeFake = sanitizeContent(fake, forbiddenWord: word)
            return GameHint(content: safeFake, type: .fake, isTrue: false, word: word, category: category)
        } else { // 30% True Hint
            let hint = getTrueFallbackHints(for: word, category: category).randomElement() ?? "Es passt zur Kategorie."
            let safeHint = sanitizeContent(hint, forbiddenWord: word)
            return GameHint(content: safeHint, type: .general, isTrue: true, word: word, category: category)
        }
    }
    
    private func getFallbackChallenge(category: Category) -> String {
        let cat = category.name.lowercased()
        let questions: [String]
        
        if cat.contains("essen") {
            questions = ["Nenne eine Zutat davon!", "Isst man es warm oder kalt?", "Ist es süß oder salzig?", "Wann isst man es typischerweise?"]
        } else if cat.contains("ort") {
            questions = ["Ist es drinnen oder draußen?", "Was zieht man dort an?", "Wie kommt man dorthin?", "Ist es dort laut oder leise?"]
        } else if cat.contains("tier") {
            questions = ["Welche Farbe hat es?", "Was frisst es?", "Wo lebt es?", "Ist es gefährlich?"]
        } else {
            questions = ["Beschreibe die Form!", "Welche Farbe hat es?", "Wie schwer ist es etwa?", "Wofür benutzt man es?"]
        }
        
        return "Challenge: " + (questions.randomElement() ?? "Beschreibe es mit einem Wort!")
    }
    
    // --- Legacy Fallback Logic (übernommen und gekürzt) ---
    private func getTrueFallbackHints(for word: String, category: Category) -> [String] {
        let firstLetter = String(word.prefix(1)).uppercased()
        return [
            "Es beginnt mit '\(firstLetter)'",
            "Es hat \(word.count) Buchstaben",
            "Es ist ein typisches Beispiel für \(category.name)",
            "Man kennt es aus dem Alltag",
            "Der Name klingt deutsch"
        ]
    }
    
    private func getFalseFallbackHints(for word: String, category: Category) -> [String] {
        let cat = category.name.lowercased()
        // PLAUSIBLE LÜGEN STATT UNSINN
        if cat.contains("essen") {
            return ["Es schmeckt sehr metallisch", "Man isst es nur gefroren", "Es ist giftig wenn roh", "Es ist blau", "Es ist flüssig wie Wasser"]
        } else if cat.contains("ort") {
            return ["Es liegt immer unter Wasser", "Man braucht einen Raumanzug", "Es ist dort -50 Grad kalt", "Es gibt dort keinen Sauerstoff"]
        } else if cat.contains("tier") {
            return ["Es hat sechs Beine", "Es kann Feuer speien", "Es lebt 1000 Jahre", "Es ist durchsichtig"]
        }
        return ["Es ist unsichtbar", "Es wiegt 10 Tonnen", "Es leuchtet im Dunkeln", "Es besteht aus Glas"]
    }
    
    private func activateHint(_ hint: GameHint) async {
        guard settings.enableHints else { return }
        
        activeHints.append(hint)
        hintHistory.append(hint)
        
        // Hinweis vorlesen
        await voiceService.speakHint(hint)
        
        // Hinweis nach 45 Sekunden entfernen (etwas länger sichtbar lassen)
        DispatchQueue.main.asyncAfter(deadline: .now() + 45) {
            self.activeHints.removeAll { $0.id == hint.id }
        }
    }
}

// MARK: - Game Hint Model

struct GameHint: Identifiable, Codable {
    let id: UUID
    let content: String
    let type: HintType
    let isTrue: Bool
    let word: String
    let category: Category
    let timestamp: Date

    init(content: String, type: HintType, isTrue: Bool, word: String, category: Category) {
        self.id = UUID()
        self.content = content
        self.type = type
        self.isTrue = isTrue
        self.word = word
        self.category = category
        self.timestamp = Date()
    }
}

enum HintType: String, CaseIterable, Codable {
    case general = "general"
    case fake = "fake"
    case challenge = "challenge"
    // Legacy / Specific types (optional, mapped to general usually)
    case letter = "letter"
    case length = "length"
    case category = "category"
    case rhyme = "rhyme"
    case type = "type"
    
    var displayName: String {
        switch self {
        case .general: return "Hinweis"
        case .fake: return "Hinweis" // Tarnung: Muss aussehen wie ein echter Hinweis!
        case .challenge: return "Challenge"
        case .letter: return "Buchstabe"
        case .length: return "Länge"
        case .category: return "Kategorie"
        case .rhyme: return "Reim"
        case .type: return "Wortart"
        }
    }
    
    var icon: String {
        switch self {
        case .general: return "lightbulb.fill"
        case .fake: return "lightbulb.fill" // Tarnung: Gleiches Icon wie echt!
        case .challenge: return "star.circle.fill"
        case .letter: return "textformat.abc"
        case .length: return "ruler"
        case .category: return "folder.fill"
        case .rhyme: return "music.note"
        case .type: return "textformat"
        }
    }
}