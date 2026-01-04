//
//  HintService.swift
//  Imposter
//
//  Created by Ken on 23.09.25.
//

import Foundation
import Combine

/// Intelligentes Hinweise-System mit echten und falschen Hinweisen
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
    private let hintProbability: Double = 0.4 // 40% Chance pro Intervall
    private let trueHintProbability: Double = 0.6 // 60% echte Hinweise, 40% falsche
    
    private var hintTimer: Timer?
    private var currentWord: String = ""
    private var currentCategory: Category?
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Startet das Hinweise-System für ein Wort
    func startHints(for word: String, category: Category) {
        currentWord = word
        currentCategory = category
        
        guard settings.enableHints else {
            return
        }
        
        // Ersten Hinweis sofort generieren
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
        
        let isTrueHint = Double.random(in: 0...1) < trueHintProbability
        
        do {
            let hint = try await createHint(
                word: currentWord,
                category: category,
                isTrue: isTrueHint
            )
            
            await activateHint(hint)
            
            // Moderator-Log
            moderatorLog.logDebug(
                "Hinweis generiert",
                metadata: [
                    "word": currentWord,
                    "isTrue": String(isTrueHint),
                    "type": hint.type.rawValue
                ]
            )
            
        } catch {
            // Error ignored
        }
    }
    
    private func createHint(word: String, category: Category, isTrue: Bool) async throws -> GameHint {
        if aiService.isAvailable {
            if let hint = await aiService.generateAIHint(word: word, category: category, mustBeTrue: isTrue) {
                return hint
            }
        }
        return createFallbackHint(word: word, category: category, isTrue: isTrue)
    }
    
    private func createFallbackHint(word: String, category: Category, isTrue: Bool) -> GameHint {
        let fallbackHints = isTrue ? getTrueFallbackHints(for: word, category: category) : getFalseFallbackHints(for: word, category: category)
        let randomHint = fallbackHints.randomElement() ?? "Das Wort beginnt mit einem Buchstaben."
        
        return GameHint(
            content: randomHint,
            type: .general,
            isTrue: isTrue,
            word: word,
            category: category
        )
    }
    
    private func getTrueFallbackHints(for word: String, category: Category) -> [String] {
        let firstLetter = String(word.prefix(1)).uppercased()
        let wordLength = word.count
        let cat = category.name.lowercased()
        
        switch cat {
        case "tier", "tiere":
            return [
                "Beginnt mit '\(firstLetter)'",
                "Hat \(wordLength) Buchstaben",
                "Lebt nicht im Wasser",
                "Ist meist langsam unterwegs",
                "Gilt als eher eklig",
                "Ist oft nachtaktiv"
            ]
        case "beruf", "berufe":
            return [
                "Beginnt mit '\(firstLetter)'",
                "Hat \(wordLength) Buchstaben",
                "Arbeitet oft mit Hitze",
                "Nutzt viele Geräte gleichzeitig",
                "Der Arbeitsplatz kann hektisch sein",
                "Bereitet anderen etwas zu"
            ]
        case "gegenstand", "objekt", "objekte":
            return [
                "Beginnt mit '\(firstLetter)'",
                "Hat \(wordLength) Buchstaben",
                "Wird häufig im Alltag benutzt",
                "Besteht oft aus mehreren Teilen",
                "Kann in der Küche vorkommen",
                "Ist leicht zu reinigen"
            ]
        case "ort", "orte":
            return [
                "Beginnt mit '\(firstLetter)'",
                "Hat \(wordLength) Buchstaben",
                "Dort sind oft viele Menschen",
                "Man hört dort häufig Geräusche",
                "Hat feste Öffnungszeiten",
                "Man kann dort etwas kaufen oder erledigen"
            ]
        default:
            return [
                "Beginnt mit '\(firstLetter)'",
                "Hat \(wordLength) Buchstaben",
                "Passt zur Kategorie \(category.name)",
                "Reimt sich auf '\(generateRhyme(word))'",
                "Enthält den Buchstaben '\(getRandomLetter(from: word))'",
                "Ist im Alltag bekannt"
            ]
        }
    }
    
    private func getFalseFallbackHints(for word: String, category: Category) -> [String] {
        let cat = category.name.lowercased()
        switch cat {
        case "tier", "tiere":
            return [
                "Ist sehr schnell",
                "Ist groß und kann fliegen",
                "Lebt nur im Wasser",
                "Jagt in Rudeln",
                "Hat ein dickes Fell",
                "Ist ein gefährlicher Räuber"
            ]
        case "beruf", "berufe":
            return [
                "Erfordert ein langes Studium",
                "Rettet regelmäßig Menschenleben",
                "Arbeitet ausschließlich im Freien",
                "Trägt immer Uniform",
                "Bedient schwere Baumaschinen",
                "Fliegt ein Verkehrsflugzeug"
            ]
        case "gegenstand", "objekt", "objekte":
            return [
                "Ist mehrere Meter groß",
                "Wird nur einmal im Jahr benutzt",
                "Besteht aus purem Gold",
                "Ist extrem selten",
                "Kann von selbst laufen",
                "Ist ausschließlich unter Wasser nutzbar"
            ]
        case "ort", "orte":
            return [
                "Liegt unter der Erde",
                "Ist nur per Flugzeug erreichbar",
                "Darf nur nachts betreten werden",
                "Ist streng geheim",
                "Wechselt jeden Tag den Standort",
                "Existiert nur im Winter"
            ]
        default:
            return [
                "Ist extrem selten",
                "Ist riesig und kann fliegen",
                "Besteht komplett aus Eis",
                "Nur mit Genehmigung betretbar",
                "Nur im Labor zu finden",
                "Wird ausschließlich von Robotern verwendet"
            ]
        }
    }
    
    private func activateHint(_ hint: GameHint) async {
        guard settings.enableHints else { return }
        
        activeHints.append(hint)
        hintHistory.append(hint)
        
        // Hinweis vorlesen
        await voiceService.speakHint(hint)
        
        // Hinweis nach 30 Sekunden entfernen
        DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
            self.activeHints.removeAll { $0.id == hint.id }
        }
    }
    
    // MARK: - Helper Methods
    
    private func generateRhyme(_ word: String) -> String {
        let endings = ["-at", "-en", "-er", "-ig", "-lich"]
        return word + endings.randomElement()!
    }
    
    private func getRandomLetter(from word: String? = nil) -> String {
        let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        return String(letters.randomElement()!)
    }
}

// MARK: - Game Hint Model (Rest bleibt gleich)
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

    private enum CodingKeys: String, CodingKey {
        case id, content, type, isTrue, word, category, timestamp
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.content = try container.decode(String.self, forKey: .content)
        self.type = try container.decode(HintType.self, forKey: .type)
        self.isTrue = try container.decode(Bool.self, forKey: .isTrue)
        self.word = try container.decode(String.self, forKey: .word)
        self.category = try container.decode(Category.self, forKey: .category)
        self.timestamp = try container.decodeIfPresent(Date.self, forKey: .timestamp) ?? Date()
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(content, forKey: .content)
        try container.encode(type, forKey: .type)
        try container.encode(isTrue, forKey: .isTrue)
        try container.encode(word, forKey: .word)
        try container.encode(category, forKey: .category)
        try container.encode(timestamp, forKey: .timestamp)
    }
}

enum HintType: String, CaseIterable, Codable {
    case general = "general"
    case letter = "letter"
    case length = "length"
    case category = "category"
    case rhyme = "rhyme"
    case type = "type"
    
    var displayName: String {
        switch self {
        case .general: return "Allgemein"
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
        case .letter: return "textformat.abc"
        case .length: return "ruler"
        case .category: return "folder.fill"
        case .rhyme: return "music.note"
        case .type: return "textformat"
        }
    }
}