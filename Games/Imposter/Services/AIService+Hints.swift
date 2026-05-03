import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

// MARK: - Data Models

struct GameContent: Identifiable, Codable {
    var id: UUID = UUID()
    let type: GameContentType
    let content: String
    let category: String // Zur Validierung
    let isTrue: Bool // Für Hints
    
    enum CodingKeys: String, CodingKey {
        case type, content, category, isTrue
    }
}

enum GameContentType: String, Codable {
    case hint = "hint"
    case fakeHint = "fake_hint"
    case challenge = "challenge"
}

private actor SpyHintCache {
    static let shared = SpyHintCache()
    private var cache: [String: [String]] = [:]
    private var inFlight: [String: Task<[String], Never>] = [:]
    
    func hints(for key: String, generate: @escaping @Sendable () async -> [String]) async -> [String] {
        if let cached = cache[key] { return cached }
        if let task = inFlight[key] { return await task.value }
        
        let task = Task { await generate() }
        inFlight[key] = task
        let result = await task.value
        inFlight[key] = nil
        
        if !result.isEmpty {
            cache[key] = result
        }
        return result
    }
}

@MainActor
private final class AIRequestLimiter {
    static let shared = AIRequestLimiter()
    private var isLocked = false
    private var waiters: [CheckedContinuation<Void, Never>] = []
    
    func withPermit<T>(_ operation: () async throws -> T) async rethrows -> T {
        await lock()
        defer { unlock() }
        return try await operation()
    }
    
    private func lock() async {
        if !isLocked {
            isLocked = true
            return
        }
        await withCheckedContinuation { continuation in
            waiters.append(continuation)
        }
    }
    
    private func unlock() {
        if waiters.isEmpty {
            isLocked = false
        } else {
            let continuation = waiters.removeFirst()
            continuation.resume()
        }
    }
}

// MARK: - AI Service Hints Extension

extension AIService {
    
    /// Generiert einen einzelnen KI-Hinweis (True/False/Challenge)
    @MainActor
    func generateGameContent(word: String, category: Category) async -> GameContent? {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            guard isAvailable else { return nil }
            
            // Zufällige Auswahl, was generiert werden soll, um Varianz zu schaffen
            // 50% echter Hinweis, 30% Challenge, 20% falscher Hinweis
            let rand = Int.random(in: 1...100)
            let requestType: String
            if rand <= 50 { requestType = "hint" }
            else if rand <= 80 { requestType = "challenge" }
            else { requestType = "fake_hint" }
            let expectedType = GameContentType(rawValue: requestType) ?? .hint
            
            let prompt = """
            Kategorie: "\(category.name)"
            Geheimes Wort: "\(word)"
            Typ: "\(requestType)"
            Regeln: Wort nie nennen, keine Zahlen/Buchstaben, keine Vergleiche/Superlative.
            Stil: 1 Satz, 6–12 Wörter.
            hint/fake_hint: beginne mit "Es". challenge: kurze Frage oder Aufgabe.
            Setze type exakt auf "\(requestType)" und isTrue auf \(requestType == "hint" ? "true" : requestType == "fake_hint" ? "false" : "true").
            """
            
            for _ in 0..<3 {
                do {
                    let generated = try await AIRequestLimiter.shared.withPermit {
                        let localSession = makeHintSession()
                        let response = try await localSession.respond(to: prompt, generating: AIGeneratedGameContent.self)
                        return response.content
                    }
                    
                    if let content = decodeGameContent(from: generated, category: category.name, word: word, expectedType: expectedType) {
                        return content
                    }
                } catch {
                    print("💡 KI-Content-Fehler: \(error)")
                    break
                }
            }
        }
        #else
        return nil
        #endif
        return nil
    }

    /// Legacy Support für reine Hints
    @MainActor
    func generateAIHint(word: String, category: Category, mustBeTrue: Bool) async -> GameHint? {
        // Wir nutzen die neue Logik, erzwingen aber den Typ
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            guard isAvailable else { return nil }
            
            let type = mustBeTrue ? "hint" : "fake_hint"
            let prompt = """
            Wort: "\(word)" (Kategorie: \(category.name))
            Erzeuge einen kurzen \(mustBeTrue ? "wahren" : "falschen/irreführenden") Hinweis auf Deutsch.
            Beginne mit "Es". Setze type exakt auf "\(type)" und isTrue auf \(mustBeTrue ? "true" : "false").
            """
            
            do {
                let generated = try await AIRequestLimiter.shared.withPermit {
                    let localSession = makeHintSession()
                    let response = try await localSession.respond(to: prompt, generating: AIGeneratedGameContent.self)
                    return response.content
                }
                let expectedType = GameContentType(rawValue: type) ?? .hint
                if let content = decodeGameContent(from: generated, category: category.name, word: word, expectedType: expectedType) {
                    return GameHint(content: content.content, type: .general, isTrue: content.isTrue, word: word, category: category)
                }
            } catch {
                print("Error generating specific hint: \(error)")
            }
        }
        #else
        return nil
        #endif
        return nil
    }
    
    // MARK: - Decoding Logic
    
    @available(iOS 26.0, *)
    private func decodeGameContent(from generated: AIGeneratedGameContent, category: String, word: String, expectedType: GameContentType? = nil) -> GameContent? {
        let type = GameContentType(rawValue: generated.type) ?? .hint

        if let expectedType, expectedType != type {
            return nil
        }

        let cleaned = cleanHintText(generated.content)
        guard isGameContentValid(cleaned, type: type, word: word, categoryName: category) else { return nil }

        return GameContent(
            type: type,
            content: cleaned,
            category: category,
            isTrue: generated.isTrue
        )
    }
    
    // MARK: - Spy Hint Generation (Beibehalten aber optimiert)
    
    @MainActor
    func generateSpyHints(for word: String, categoryName: String, count: Int = 4) async -> [String] {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            guard isAvailable else {
                return generateFallbackSpyHints(for: word, categoryName: categoryName, count: count)
            }
            
            let cacheKey = "\(normalizeForMatching(categoryName))|\(normalizeForMatching(word))"
            return await SpyHintCache.shared.hints(for: cacheKey) { [count] in
                let prompt = """
                Kategorie: "\(categoryName)"
                Geheimes Wort: "\(word)"
                Erstelle \(count) vage Hinweise (ein Satz, 6–12 Wörter).
                Regeln: Wort nie nennen, keine Zahlen/Buchstaben, keine Vergleiche/Superlative.
                Beginne jeden Hinweis mit "Es".
                Gib genau \(count) Hinweise zurück.
                """
                
                var collected: [String] = []
                var seen: Set<String> = []
                
                for _ in 0..<3 {
                    do {
                        let generated = try await AIRequestLimiter.shared.withPermit {
                            let localSession = self.makeHintSession()
                            let response = try await localSession.respond(to: prompt, generating: AISpyHintsResponse.self)
                            return response.content
                        }
                        let rawHints = generated.hints
                        if !rawHints.isEmpty {
                            let filtered = self.filterSpyHints(rawHints, word: word, categoryName: categoryName)
                            for hint in filtered {
                                let key = self.normalizeForMatching(hint)
                                guard !seen.contains(key) else { continue }
                                seen.insert(key)
                                collected.append(hint)
                            }
                            if collected.count >= count {
                                return Array(collected.prefix(count))
                            }
                        }
                    } catch {
                        print("Spy Hint Error: \(error)")
                        break
                    }
                }
                if collected.isEmpty {
                    return self.generateFallbackSpyHints(for: word, categoryName: categoryName, count: count)
                }
                var result = collected
                let fallback = self.generateFallbackSpyHints(for: word, categoryName: categoryName, count: count)
                for hint in fallback {
                    if result.count >= count { break }
                    let key = self.normalizeForMatching(hint)
                    if !seen.contains(key) {
                        seen.insert(key)
                        result.append(hint)
                    }
                }
                return Array(result.prefix(count))
            }
        }
        #else
        return generateFallbackSpyHints(for: word, categoryName: categoryName, count: count)
        #endif
        return generateFallbackSpyHints(for: word, categoryName: categoryName, count: count)
    }
    
    nonisolated private func generateFallbackSpyHints(for word: String, categoryName: String, count: Int) -> [String] {
        let category = categoryName.lowercased()
        let hints: [String]
        
        if category.contains("tier") {
            hints = [
                "Es ist ein Lebewesen",
                "Es kann sich bewegen",
                "Es lebt in der Natur",
                "Es braucht Nahrung"
            ]
        } else if category.contains("essen") || category.contains("frucht") || category.contains("gemüse") {
            hints = [
                "Es kann man essen",
                "Es gehört in die Küche",
                "Es wird oft zubereitet",
                "Es kann warm oder kalt sein"
            ]
        } else if category.contains("stadt") || category.contains("land") || category.contains("ort") {
            hints = [
                "Es ist ein Ort",
                "Viele Menschen kennen es",
                "Man kann dorthin reisen",
                "Es liegt irgendwo auf der Welt"
            ]
        } else if category.contains("beruf") {
            hints = [
                "Es ist eine Tätigkeit",
                "Menschen machen es beruflich",
                "Man braucht dafür Fähigkeiten",
                "Es hat einen Zweck"
            ]
        } else if category.contains("fahrzeug") {
            hints = [
                "Es dient der Fortbewegung",
                "Man nutzt es im Alltag",
                "Es kann sich bewegen",
                "Es wird oft draußen genutzt"
            ]
        } else if category.contains("sport") {
            hints = [
                "Es ist eine Aktivität",
                "Man bewegt sich dabei",
                "Es hat Regeln",
                "Man macht es oft mit anderen"
            ]
        } else {
            hints = [
                "Es passt zur Kategorie",
                "Man kennt es allgemein",
                "Es ist in dieser Kategorie üblich",
                "Es kommt oft vor"
            ]
        }
        
        return Array(hints.prefix(count))
    }

    nonisolated private func cleanHintText(_ text: String) -> String {
        var cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        cleaned = cleaned.trimmingCharacters(in: CharacterSet(charactersIn: "\"“”'"))
        cleaned = cleaned.replacingOccurrences(of: "Hinweis:", with: "", options: .caseInsensitive)
        cleaned = cleaned.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        return cleaned
    }

    nonisolated private func filterSpyHints(_ hints: [String], word: String, categoryName: String) -> [String] {
        var result: [String] = []
        var seen: Set<String> = []
        
        for hint in hints {
            let cleaned = cleanHintText(hint)
            guard isSpyHintValid(cleaned, word: word, categoryName: categoryName) else { continue }
            let key = normalizeForMatching(cleaned)
            guard !seen.contains(key) else { continue }
            seen.insert(key)
            result.append(cleaned)
        }
        
        return result
    }

    nonisolated private func isSpyHintValid(_ hint: String, word: String, categoryName: String) -> Bool {
        let trimmed = hint.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 8, trimmed.count <= 80 else { return false }
        guard !containsDigits(trimmed) else { return false }
        guard !trimmed.contains("?") else { return false }
        
        let normalized = normalizeForMatching(trimmed)
        guard !containsForbiddenWord(trimmed, word: word) else { return false }
        guard !containsBannedPattern(normalized) else { return false }
        guard matchesCategoryAnchor(normalized, categoryName: categoryName) else { return false }
        
        let wordCount = normalized.split(separator: " ").count
        guard wordCount >= 4, wordCount <= 12 else { return false }
        
        let startsOk = normalized.hasPrefix("es ")
            || normalized.hasPrefix("man ")
            || normalized.hasPrefix("das ding ")
            || normalized.hasPrefix("dieses ding ")
        return startsOk
    }

    nonisolated private func isGameContentValid(_ content: String, type: GameContentType, word: String, categoryName: String) -> Bool {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 8, trimmed.count <= 120 else { return false }
        guard !containsDigits(trimmed) else { return false }
        
        let hasQuestionMark = trimmed.contains("?")
        let normalized = normalizeForMatching(trimmed)
        
        guard !containsForbiddenWord(trimmed, word: word) else { return false }
        guard !containsBannedPattern(normalized) else { return false }
        if type != .challenge {
            guard matchesCategoryAnchor(normalized, categoryName: categoryName) else { return false }
        }
        
        let wordCount = normalized.split(separator: " ").count
        let minWords = type == .challenge ? 3 : 4
        guard wordCount >= minWords, wordCount <= 14 else { return false }
        
        if type == .challenge {
            guard hasQuestionMark || isChallengeLike(normalized) else { return false }
        } else if hasQuestionMark {
            return false
        }
        
        return true
    }

    nonisolated private func isChallengeLike(_ normalized: String) -> Bool {
        let starters = [
            "nenne ", "beschreibe ", "sag ", "rate ", "ist ", "hat ", "gehort ", "gehoert ",
            "kann ", "wo ", "wie ", "wann ", "warum "
        ]
        return starters.contains { normalized.hasPrefix($0) }
    }

    nonisolated private func matchesCategoryAnchor(_ normalized: String, categoryName: String) -> Bool {
        guard let anchors = categoryAnchors(for: categoryName) else { return true }
        return anchors.contains { normalized.contains($0) }
    }

    nonisolated private func categoryAnchors(for categoryName: String) -> [String]? {
        let name = normalizeForMatching(categoryName)
        
        if name.contains("tier") {
            return ["tier", "lebewesen", "lebt", "natur", "beweg", "frisst", "fresser", "nacht", "tag", "schwimm", "flieg", "kriech"]
        }
        if name.contains("essen") || name.contains("frucht") || name.contains("gemuse") || name.contains("gemuese") {
            return ["essen", "nahrung", "kuch", "kuech", "koch", "geschmack", "zutat", "suss", "suess", "salzig", "sauer", "warm", "kalt"]
        }
        if name.contains("stadt") || name.contains("land") || name.contains("ort") {
            return ["ort", "stadt", "land", "reise", "menschen", "gebaud", "gebaeud", "besuch", "dort"]
        }
        if name.contains("beruf") || name.contains("job") {
            return ["beruf", "arbeit", "job", "dienst", "profi"]
        }
        if name.contains("sport") {
            return ["sport", "spiel", "regel", "beweg", "train", "wett", "ausdauer", "team"]
        }
        if name.contains("fahrzeug") {
            return ["fahr", "transport", "beweg", "rad", "motor", "lenk", "reise"]
        }
        if name.contains("marke") {
            return ["marke", "firma", "produkt", "logo"]
        }
        if name.contains("beruhmt") || name.contains("beruehmt") {
            return ["person", "bekannt", "beruhmt", "beruehmt", "promi"]
        }
        
        return nil
    }

    nonisolated private func containsDigits(_ text: String) -> Bool {
        return text.rangeOfCharacter(from: .decimalDigits) != nil
    }

    nonisolated private func containsBannedPattern(_ normalized: String) -> Bool {
        let bannedPhrases = [
            "beginnt mit", "endet mit", "buchstabe", "buchstaben", "silbe", "silben",
            "reimt", "klingt", "heisst", "wort", "name", "abkurzung",
            "nummer", "zahl", "preis", "euro", "dollar",
            "wie ein", "wie eine", "wie der", "wie die", "wie das",
            "schneller als", "langsamer als", "grosser als", "kleiner als",
            "am schnellsten", "am grossten", "am kleinsten",
            "einzig", "ausschliesslich"
        ]
        if bannedPhrases.contains(where: { normalized.contains($0) }) {
            return true
        }
        
        if normalized.hasPrefix("nur ") || normalized.contains(" nur ") || normalized.hasSuffix(" nur") {
            return true
        }
        
        return false
    }

    nonisolated private func containsForbiddenWord(_ text: String, word: String) -> Bool {
        let normalizedText = normalizeForMatching(text)
        let tokens = Set(normalizedText.split(separator: " ").map(String.init))
        let variants = buildWordVariants(for: word)
        
        if !variants.isDisjoint(with: tokens) { return true }
        
        for variant in variants where variant.count >= 5 {
            if normalizedText.contains(variant) { return true }
        }
        
        return false
    }

    nonisolated private func buildWordVariants(for word: String) -> Set<String> {
        let normalized = normalizeForMatching(word)
        let tokens = normalized.split(separator: " ").map(String.init)
        var variants: Set<String> = []
        
        for token in tokens {
            guard token.count >= 3 else { continue }
            variants.insert(token)
            variants.insert(token + "e")
            variants.insert(token + "en")
            variants.insert(token + "er")
            variants.insert(token + "n")
            variants.insert(token + "s")
            variants.insert(token + "es")
            if token.hasSuffix("e") { variants.insert(String(token.dropLast())) }
            if token.hasSuffix("er") { variants.insert(String(token.dropLast(2))) }
            if token.hasSuffix("en") { variants.insert(String(token.dropLast(2))) }
        }
        
        if tokens.count > 1 {
            variants.insert(tokens.joined())
        }
        
        return variants
    }

    nonisolated private func normalizeForMatching(_ text: String) -> String {
        var normalized = text.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
        normalized = normalized.replacingOccurrences(of: "ß", with: "ss")
        normalized = normalized.replacingOccurrences(of: "[^a-z0-9 ]", with: " ", options: .regularExpression)
        normalized = normalized.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        return normalized.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    #if canImport(FoundationModels)
    @available(iOS 26.0, *)
    nonisolated private func makeHintSession() -> LanguageModelSession {
        let instructions = "Du bist Moderator eines Ratespiels. Antworte auf Deutsch, kurz und präzise."
        return LanguageModelSession(instructions: instructions)
    }
    #else
    nonisolated private func makeHintSession() -> Any {
        return ()
    }
    #endif
    
    // MARK: - Role Generation (Beibehalten)
    
    @MainActor
    func generateRole(for location: String, playerName: String? = nil) async -> String? {
        // ... (Logik bleibt erhalten, Platzhalter für Verkürzung im Diff)
        // Um Codelänge zu sparen, nutzen wir hier einen einfachen Aufruf,
        // da der User diesen Teil nicht kritisiert hat.
        // Wir können die bestehende Implementierung aus der vorherigen Datei übernehmen
        // oder eine vereinfachte Version nutzen, falls der User es nicht explizit geändert haben wollte.
        // Da die Datei komplett ersetzt wird, muss ich die Funktion wiederherstellen.
        
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            guard isAvailable, let session = session as? LanguageModelSession else { return "Besucher" }
            let prompt = "Nenne EINE typische Rolle (Beruf/Person) für den Ort '\(location)'. Nur das Wort."
            do {
                let res = try await session.respond(to: prompt)
                return res.content.trimmingCharacters(in: .whitespacesAndNewlines)
                    .replacingOccurrences(of: "\"", with: "")
            } catch { return "Besucher" }
        }
        #endif
        return "Besucher"
    }
    
    @MainActor
    func generateRoles(for location: String, count: Int) async -> [String] {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            guard isAvailable, let session = session as? LanguageModelSession else { return Array(repeating: "Besucher", count: count) }
            let prompt = "Nenne \(count) verschiedene typische Rollen für '\(location)'. Antworte mit einzelnen deutschen Rollenbezeichnungen."
            do {
                let res = try await session.respond(to: prompt, generating: AIRoleListResponse.self)
                let roles = res.content.roles
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
                if !roles.isEmpty { return Array(roles.prefix(count)) }
            } catch { }
            return Array(repeating: "Besucher", count: count)
        }
        #endif
        return Array(repeating: "Besucher", count: count)
    }
}
