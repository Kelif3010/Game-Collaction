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
            print("💡 Hinweise deaktiviert – kein Start")
            return
        }
        
        print("💡 Hinweise-System gestartet für: \(word) (\(category.name))")
        
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
        
        print("💡 Hinweise-System gestoppt")
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
            print("💡 Fehler beim Generieren des Hinweises: \(error)")
        }
    }
    
    private func createHint(word: String, category: Category, isTrue: Bool) async throws -> GameHint {
        if aiService.isAvailable {
            if let hint = await aiService.generateAIHint(word: word, category: category, mustBeTrue: isTrue) {
                print("🧠 Hint-Quelle: KI (AIService)")
                return hint
            } else {
                print("🧪 Hint-Quelle: Fallback (KI lieferte kein valides JSON)")
            }
        } else {
            print("🧪 Hint-Quelle: Fallback (KI nicht verfügbar)")
        }
        return createFallbackHint(word: word, category: category, isTrue: isTrue)
    }
    
    private func createHintPrompt(word: String, category: Category, isTrue: Bool) -> String {
        let truthStr = isTrue ? "true" : "false"
        return """
        Du bist der Moderator eines Spion-Spiels. Analysiere das Zielwort inhaltlich (Bedeutung, Wortart, Silben, typische Buchstabenfolgen, Reime, deutsche Morphologie) und antworte ausschließlich mit EINEM JSON-Objekt. KEINE Einleitung, KEIN Markdown, KEINE Codeblöcke, KEIN Zusatztext.
        SCHEMA: {"content":"...","isTrue":true|false,"type":"general|letter|length|category|rhyme|type"}

        word=\(word)
        category=\(category.name)
        mustBeTrue=\(truthStr)
        Spielregeln:
        - Wenn mustBeTrue=true, muss der Hinweis faktisch korrekt sein. Wenn false, dann subtil und plausibel falsch (keine triviale Negation, kein offensichtlicher Unsinn).
        - type=letter: content enthält genau EINEN Buchstaben (Großbuchstabe) mit kurzem Kontext.
        - type=length: content erwähnt die exakte Länge des Wortes (Zahl) oder eine präzise Aussage dazu.
        - type=category: content erwähnt die Kategorie explizit und passend.
        - type=rhyme: content nennt ein kurzes deutsches Reimwort oder beschreibt die Reimform glaubwürdig.
        - type=type: content benennt die Wortart (Substantiv/Verb/Adjektiv) konsistent mit dem Wort.
        - Maximal 2 Sätze, deutsch, geheimnisvoll, keine Namen von Spielern.
        - Antworte NUR mit dem JSON-Objekt im SCHEMA oben.
        """
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
        
        print("💡 Hinweis aktiviert: \(hint.content) (Echt: \(hint.isTrue))")
    }
    
    // MARK: - Helper Methods
    
    /// Versucht, aus einem beliebigen Text das erste balancierte JSON-Objekt ({}-Block) zu extrahieren
    private func extractFirstJSONObject(from text: String) -> Data? {
        let chars = Array(text)
        var i = 0
        var inString = false
        var escape = false
        var started = false
        var braceCount = 0
        var startIndex: Int? = nil
        while i < chars.count {
            let c = chars[i]
            if inString {
                if escape {
                    escape = false
                } else if c == "\\" {
                    escape = true
                } else if c == "\"" {
                    inString = false
                }
            } else {
                if c == "\"" { inString = true }
                else if c == "{" {
                    if !started {
                        started = true
                        startIndex = i
                    }
                    braceCount += 1
                } else if c == "}" {
                    if started { braceCount -= 1 }
                    if started && braceCount == 0 {
                        let s = startIndex ?? 0
                        let substring = String(chars[s...i])
                        return substring.data(using: .utf8)
                    }
                }
            }
            i += 1
        }
        return nil
    }
    
    private func generateRhyme(_ word: String) -> String {
        // Vereinfachte Reim-Generierung
        let endings = ["-at", "-en", "-er", "-ig", "-lich"]
        return word + endings.randomElement()!
    }
    
    private func getWordType(_ word: String) -> String {
        // Vereinfachte Wort-Typ-Erkennung
        if word.hasSuffix("ung") { return "Substantiv" }
        if word.hasSuffix("en") { return "Verb" }
        if word.hasSuffix("ig") { return "Adjektiv" }
        return "Substantiv"
    }
    
    private func getRandomLetter(from word: String? = nil) -> String {
        let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        return String(letters.randomElement()!)
    }
    
    private func getRandomCategory() -> String {
        let categories = ["Tier", "Pflanze", "Gegenstand", "Beruf", "Ort"]
        return categories.randomElement()!
    }
    
    private func getRandomWordType() -> String {
        let types = ["Substantiv", "Verb", "Adjektiv", "Nomen"]
        return types.randomElement()!
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
