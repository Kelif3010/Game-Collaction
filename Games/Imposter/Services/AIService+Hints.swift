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

struct GameContentDTO: Codable {
    let type: String
    let content: String
    let isTrue: Bool
}

// MARK: - AI Service Hints Extension

extension AIService {
    
    /// Generiert einen einzelnen KI-Hinweis (True/False/Challenge)
    @MainActor
    func generateGameContent(word: String, category: Category) async -> GameContent? {
        #if canImport(FoundationModels)
        guard isAvailable, let session = self.session else { return nil }
        
        // Zufällige Auswahl, was generiert werden soll, um Varianz zu schaffen
        // 50% echter Hinweis, 30% Challenge, 20% falscher Hinweis
        let rand = Int.random(in: 1...100)
        let requestType: String
        if rand <= 50 { requestType = "hint" }
        else if rand <= 80 { requestType = "challenge" }
        else { requestType = "fake_hint" }
        
        let prompt = """
        Du bist der Moderator eines Spion-Spiels.
        Wort: "\(word)"
        Kategorie: "\(category.name)"
        
        Generiere EINEN Inhalt vom Typ: "\(requestType)".
        
        REGELN:
        1. VERBOTEN: Du darfst das Wort "\(word)" NIEMALS im Text nennen! Umschreibe es mit "Es" oder "Das Ding".
        2. Typ "hint": Ein echter, nützlicher Hinweis zum Wort. Wahr. (z.B. "Es besteht aus Holz").
        3. Typ "fake_hint": Ein subtiler, falscher Hinweis, der den Spion verwirrt, aber plausibel klingt (Lüge!). (z.B. bei Pizza: "Man isst es meistens mit Löffel").
        4. Typ "challenge": Eine kontextbezogene Aufgabe oder Frage an einen Spieler. MUSS zur Kategorie passen!
           - Bei Essen: "Nenne eine Zutat", "Isst man es warm oder kalt?"
           - Bei Ort: "Was zieht man dort an?", "Ist es drinnen oder draußen?"
           - Bei Gegenstand: "Wo kaufst du es?", "Wie schwer ist es?"
        
        Antworte NUR mit diesem JSON:
        {"type": "\(requestType)", "content": "Dein Text hier", "isTrue": true/false}
        
        Wichtig: isTrue ist true für "hint" und "challenge", aber false für "fake_hint".
        """
        
        do {
            let response = try await session.respond(to: prompt)
            let text = response.content
            
            if let content = decodeGameContent(from: text, category: category.name) {
                return content
            }
        } catch {
            print("💡 KI-Content-Fehler: \(error)")
        }
        return nil
        #else
        return nil
        #endif
    }

    /// Legacy Support für reine Hints
    @MainActor
    func generateAIHint(word: String, category: Category, mustBeTrue: Bool) async -> GameHint? {
        // Wir nutzen die neue Logik, erzwingen aber den Typ
        #if canImport(FoundationModels)
        guard isAvailable, let session = self.session else { return nil }
        
        let type = mustBeTrue ? "hint" : "fake_hint"
        let prompt = """
        Wort: "\(word)" (Kategorie: \(category.name))
        Erzeuge einen kurzen \(mustBeTrue ? "wahren" : "falschen/irreführenden") Hinweis auf Deutsch.
        Antworte NUR JSON: {"type": "\(type)", "content": "...", "isTrue": \(mustBeTrue)}
        """
        
        do {
            let response = try await session.respond(to: prompt)
            if let content = decodeGameContent(from: response.content, category: category.name) {
                return GameHint(content: content.content, type: .general, isTrue: content.isTrue, word: word, category: category)
            }
        } catch {
            print("Error generating specific hint: \(error)")
        }
        return nil
        #else
        return nil
        #endif
    }
    
    // MARK: - Decoding Logic
    
    private func decodeGameContent(from text: String, category: String) -> GameContent? {
        guard let data = extractJSON(from: text) else { return nil }
        
        do {
            let dto = try JSONDecoder().decode(GameContentDTO.self, from: data)
            let type = GameContentType(rawValue: dto.type) ?? .hint
            
            return GameContent(
                type: type,
                content: dto.content,
                category: category,
                isTrue: dto.isTrue
            )
        } catch {
            print("JSON Decode Error: \(error)")
            return nil
        }
    }

    private func extractJSON(from text: String) -> Data? {
        guard let start = text.firstIndex(of: "{"),
              let end = text.lastIndex(of: "}") else { return nil }
        let jsonStr = String(text[start...end])
        return jsonStr.data(using: .utf8)
    }
    
    // MARK: - Spy Hint Generation (Beibehalten aber optimiert)
    
    @MainActor
    func generateSpyHints(for word: String, categoryName: String, count: Int = 4) async -> [String] {
        #if canImport(FoundationModels)
        guard isAvailable, let session = session else {
            return generateFallbackSpyHints(for: word, categoryName: categoryName, count: count)
        }
        
        let prompt = """
        Wort: "\(word)" (Kategorie: \(categoryName))
        Generiere \(count) vage, kurze Aussagen auf Deutsch, die auf das Wort zutreffen, aber auch auf viele andere der Kategorie.
        Antworte NUR JSON Array: ["Satz 1", "Satz 2", ...]
        """
        
        do {
            let response = try await session.respond(to: prompt)
            if let data = extractJSONArray(from: response.content),
               let hints = try? JSONDecoder().decode([String].self, from: data) {
                return hints
            }
        } catch {
            print("Spy Hint Error: \(error)")
        }
        return generateFallbackSpyHints(for: word, categoryName: categoryName, count: count)
        #else
        return generateFallbackSpyHints(for: word, categoryName: categoryName, count: count)
        #endif
    }
    
    private func extractJSONArray(from text: String) -> Data? {
        guard let start = text.firstIndex(of: "["),
              let end = text.lastIndex(of: "]") else { return nil }
        let jsonStr = String(text[start...end])
        return jsonStr.data(using: .utf8)
    }
    
    private func generateFallbackSpyHints(for word: String, categoryName: String, count: Int) -> [String] {
        // Einfacher Fallback
        return ["Passt zur Kategorie", "Hat Buchstaben", "Ist bekannt", "Kann man beschreiben"]
    }
    
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
        guard isAvailable, let session = session else { return "Besucher" }
        let prompt = "Nenne EINE typische Rolle (Beruf/Person) für den Ort '\(location)'. Nur das Wort."
        do {
            let res = try await session.respond(to: prompt)
            return res.content.trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "\"", with: "")
        } catch { return "Besucher" }
        #else
        return "Besucher"
        #endif
    }
    
    @MainActor
    func generateRoles(for location: String, count: Int) async -> [String] {
        #if canImport(FoundationModels)
        guard isAvailable, let session = session else { return Array(repeating: "Besucher", count: count) }
        let prompt = "Nenne \(count) verschiedene typische Rollen für '\(location)'. Antworte als JSON Array string."
        do {
             let res = try await session.respond(to: prompt)
             if let data = extractJSONArray(from: res.content),
                let roles = try? JSONDecoder().decode([String].self, from: data) {
                 return roles
             }
        } catch { }
        return Array(repeating: "Besucher", count: count)
        #else
        return Array(repeating: "Besucher", count: count)
        #endif
    }
}

