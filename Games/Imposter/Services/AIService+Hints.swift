import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

extension AIService {
    /// Erzeugt einen KI-Hinweis für das gegebene Wort und die Kategorie. Gibt nil zurück, wenn keine valide KI-Antwort geliefert wird.
    @MainActor
    func generateAIHint(word: String, category: Category, mustBeTrue: Bool) async -> GameHint? {
        #if canImport(FoundationModels)
        guard isAvailable, let session = self.session else { return nil }
        let truthStr = mustBeTrue ? "true" : "false"
        let basePrompt = """
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
        do {
            let response = try await session.respond(to: basePrompt)
            let text = response.content
            if let hint = decodeHint(from: text, word: word, category: category) { return hint }
            // Retry mit strengerem Prompt
            let strictPrompt = """
            Antworte ausschließlich mit EINEM JSON-Objekt ohne jeglichen Zusatztext.
            SCHEMA: {"content":"...","isTrue":true|false,"type":"general|letter|length|category|rhyme|type"}
            word=\(word)
            category=\(category.name)
            mustBeTrue=\(mustBeTrue)
            Regeln:
            - Kurz, deutsch, max. 2 Sätze.
            - Plausibel und subtil bei mustBeTrue=false.
            - KEIN Markdown, KEINE Erklärungen, NUR JSON.
            """
            let retry = try await session.respond(to: strictPrompt)
            let retryText = retry.content
            if let hint = decodeHint(from: retryText, word: word, category: category) { return hint }
        } catch {
            print("💡 KI-Hint-Fehler: \(error)")
        }
        return nil
        #else
        return nil
        #endif
    }

    private func decodeHint(from text: String, word: String, category: Category) -> GameHint? {
        // Versuch 1: Direktes JSON
        if let dto = try? JSONDecoder().decode(AIHintDTO.self, from: Data(text.utf8)) {
            return mapDTO(dto, word: word, category: category)
        }
        // Versuch 2: Extrahiertes JSON
        if let json = extractFirstJSONObject(from: text),
           let dto = try? JSONDecoder().decode(AIHintDTO.self, from: json) {
            return mapDTO(dto, word: word, category: category)
        }
        return nil
    }

    private func mapDTO(_ dto: AIHintDTO, word: String, category: Category) -> GameHint {
        let hintType = HintType(rawValue: dto.type) ?? .general
        return GameHint(content: dto.content, type: hintType, isTrue: dto.isTrue, word: word, category: category)
    }

    /// Extrahiert das erste balancierte JSON-Objekt aus Freitext
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
                if escape { escape = false }
                else if c == "\\" { escape = true }
                else if c == "\"" { inString = false }
            } else {
                if c == "\"" { inString = true }
                else if c == "{" {
                    if !started { started = true; startIndex = i }
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
    
    // MARK: - Spy Hint Generation
    
    /// Generiert strategische, zweideutige Hinweise für Spione
    @MainActor
    func generateSpyHints(for word: String, categoryName: String, count: Int = 4) async -> [String] {
        #if canImport(FoundationModels)
        guard isAvailable, let session = session else {
            print("🧪 Spy-Hinweise: KI nicht verfügbar, verwende Fallback")
            return generateFallbackSpyHints(for: word, categoryName: categoryName, count: count)
        }
        
        isResponding = true
        defer { isResponding = false }
        
        do {
            // VERBESSERTER PROMPT FÜR MEHR STRATEGIE / WENIGER VERRAT
            let prompt = """
            Du bist ein strategischer Assistent für den "Spion" in einem Wortspiel.
            Wort: "\(word)"
            Kategorie: "\(categoryName)"
            
            Deine Aufgabe: Generiere \(count) kurze Hinweise, die der Spion sagen kann, ohne aufzufliegen.
            
            OBERSTE REGEL: "STRATEGISCHE ZWEIDEUTIGKEIT"
            Der Hinweis muss auf das Wort "\(word)" zutreffen, ABER er muss auch auf viele andere Wörter in der Kategorie "\(categoryName)" passen.
            Wenn der Hinweis nur auf "\(word)" passt, ist er SCHLECHT und VERBOTEN.
            
            BEISPIELE FÜR GUTE HINWEISE (VAGE):
            - Wort "Tennis" (Sport): "Macht man draußen im Sommer" (Passt auch auf Fußball, Schwimmen, Golf).
            - Wort "Hund" (Tier): "Braucht viel Aufmerksamkeit" (Passt auch auf Katze, Baby, Pferd).
            - Wort "Pizza" (Essen): "Isst man oft in Gesellschaft" (Passt auf fast alles).
            - Wort "Arzt" (Beruf): "Arbeitet mit Menschen" (Passt auf Lehrer, Verkäufer).
            
            BEISPIELE FÜR SCHLECHTE HINWEISE (ZU OFFENSICHTLICH - VERBOTEN!):
            - Bei "Tennis": "Gelber Filzball", "Schläger" (Verrät es sofort -> Spion verliert).
            - Bei "Hund": "Bellt", "Gassi gehen", "Treuer Begleiter" (Verrät es sofort).
            - Bei "Pizza": "Italien", "Rund", "Salami" (Verrät es sofort).
            
            FORMATIERUNG:
            - Kurz (1-4 Wörter).
            - Auf Deutsch.
            - Antworte NUR mit einem JSON-Array: ["Hinweis 1", "Hinweis 2", "Hinweis 3", "Hinweis 4"]
            KEINE Einleitung, KEIN Markdown, KEINE Codeblöcke, NUR das JSON-Array.
            """
            
            let response = try await session.respond(to: prompt)
            let text = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Versuch 1: Direktes JSON-Array parsen
            if let hints = parseHintsArray(from: text) {
                print("🧠 Spy-Hinweise generiert: \(hints.count) Hinweise für '\(word)'")
                return hints
            }
            
            // Versuch 2: JSON-Array aus Text extrahieren
            if let jsonData = extractJSONArray(from: text),
               let hints = try? JSONDecoder().decode([String].self, from: jsonData) {
                print("🧠 Spy-Hinweise generiert (extrahiert): \(hints.count) Hinweise für '\(word)'")
                return hints
            }
            
            print("⚠️ Konnte Spy-Hinweise nicht parsen, verwende Fallback")
            print("📝 KI-Antwort war: \(text.prefix(200))...")
            
        } catch {
            print("💡 Fehler beim Generieren von Spy-Hinweisen: \(error)")
        }
        
        return generateFallbackSpyHints(for: word, categoryName: categoryName, count: count)
        #else
        print("🧪 Spy-Hinweise: FoundationModels nicht verfügbar, verwende Fallback")
        return generateFallbackSpyHints(for: word, categoryName: categoryName, count: count)
        #endif
    }
    
    /// Generiert mehrere Hinweise für mehrere Wörter (Batch-Operation)
    @MainActor
    func generateSpyHintsBatch(
        for words: [String],
        categoryName: String,
        hintsPerWord: Int = 4,
        progressCallback: ((Int, Int) -> Void)? = nil
    ) async -> [String: [String]] {
        #if canImport(FoundationModels)
        var results: [String: [String]] = [:]
        let total = words.count
        
        for (index, word) in words.enumerated() {
            progressCallback?(index + 1, total)
            let hints = await generateSpyHints(for: word, categoryName: categoryName, count: hintsPerWord)
            results[word] = hints
            
            // Kleine Pause zwischen Anfragen, um Rate-Limiting zu vermeiden
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 Sekunden
        }
        
        return results
        #else
        var results: [String: [String]] = [:]
        for word in words {
            results[word] = generateFallbackSpyHints(for: word, categoryName: categoryName, count: hintsPerWord)
        }
        return results
        #endif
    }
    
    // MARK: - Private Helper Methods
    
    private func parseHintsArray(from text: String) -> [String]? {
        // Versuch direktes JSON-Array zu parsen
        if let data = text.data(using: .utf8),
           let hints = try? JSONDecoder().decode([String].self, from: data) {
            return hints.filter { !$0.isEmpty }
        }
        return nil
    }
    
    private func extractJSONArray(from text: String) -> Data? {
        // Suche nach [ ... ] Pattern
        let chars = Array(text)
        var i = 0
        var inString = false
        var escape = false
        var started = false
        var bracketCount = 0
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
                if c == "\"" {
                    inString = true
                } else if c == "[" {
                    if !started {
                        started = true
                        startIndex = i
                    }
                    bracketCount += 1
                } else if c == "]" {
                    if started {
                        bracketCount -= 1
                        if bracketCount == 0 {
                            let s = startIndex ?? 0
                            let substring = String(chars[s...i])
                            return substring.data(using: .utf8)
                        }
                    }
                }
            }
            i += 1
        }
        return nil
    }
    
    private func generateFallbackSpyHints(for word: String, categoryName: String, count: Int) -> [String] {
        let firstLetter = String(word.prefix(1)).uppercased()
        let wordLength = word.count
        let categoryLower = categoryName.lowercased()
        let wordLower = word.lowercased()
        
        var hints: [String] = []
        
        // Kategorie-spezifische, nicht zu offensichtliche Hinweise (Fallback)
        if categoryLower.contains("tier") {
            // Vermeide zu offensichtliche Geräusche/Verhalten
            if wordLower.contains("hund") {
                // Hier auch Fallback leicht angepasst, um weniger verräterisch zu sein
                hints = ["Lebt bei Menschen", "Vier Beine", "Mag Bewegung", "Soziales Wesen"]
            } else if wordLower.contains("katze") {
                hints = ["Lebt bei Menschen", "Eigenwillig", "Vier Beine", "Aktiv"]
            } else if wordLower.contains("elefant") {
                hints = ["Sehr groß", "Grau", "Afrika oder Asien", "Dickhäuter"]
            } else if wordLower.contains("löwe") {
                hints = ["Raubtier", "Afrika", "Großkatze", "Rudeltier"]
            } else {
                hints = ["Lebt in der Natur", "Wildtier", "Tierwelt", "Hat Augen"]
            }
        } else if categoryLower.contains("beruf") || categoryLower.contains("job") {
            if wordLower.contains("arzt") {
                hints = ["Hilft Menschen", "Lange Ausbildung", "Verantwortungsvoll", "Arbeitet drinnen"]
            } else {
                hints = ["Arbeitet mit Menschen", "Beruf", "Arbeitsplatz", "Tätigkeit"]
            }
        } else if categoryLower.contains("essen") || categoryLower.contains("nahrung") {
            if wordLower.contains("pizza") {
                hints = ["Beliebtes Gericht", "Warm serviert", "Meistens rund", "Teigware"]
            } else {
                hints = ["Macht satt", "Küche", "Geschmack", "Lebensmittel"]
            }
        } else if categoryLower.contains("ort") || categoryLower.contains("stadt") {
            hints = ["Besuchbar", "Adresse", "Öffnungszeiten", "Standort"]
        } else if categoryLower.contains("fahrzeug") || categoryLower.contains("auto") {
             hints = ["Transportmittel", "Technik", "Bewegung", "Reisen"]
        } else {
            // Generische, nicht zu offensichtliche Hinweise
            hints = ["Beginnt mit '\(firstLetter)'", "\(wordLength) Buchstaben", "Passt zur Kategorie"]
        }
        
        // Falls nicht genug Hinweise, füge generische hinzu
        while hints.count < count {
            hints.append("Typisch für \(categoryName)")
        }
        
        return Array(hints.prefix(count))
    }
    
    // MARK: - Role Generation for Roles Mode
    
    /// Generiert eine passende Rolle für einen Spieler basierend auf einem Ort
    @MainActor
    func generateRole(for location: String, playerName: String? = nil) async -> String? {
        #if canImport(FoundationModels)
        guard isAvailable, let session = session else {
            print("🧪 Rollen-Generierung: KI nicht verfügbar, verwende Fallback")
            return generateFallbackRole(for: location)
        }
        
        isResponding = true
        defer { isResponding = false }
        
        do {
            let prompt = """
            Du bist der Moderator eines Spion-Spiels im Rollen-Modus. Generiere eine REALISTISCHE und TYPISCHE Rolle für eine Person, die sich am Ort "\(location)" aufhält.
            
            WICHTIGE REGELN:
            - Die Rolle muss SEHR TYPISCH und REALISTISCH für diesen spezifischen Ort sein
            - Nur eine Rolle, die man wirklich regelmäßig an diesem Ort findet
            - KEINE abstrakten, ungewöhnlichen oder kreativen Rollen
            - KEINE Rollen, die nur selten oder nie an diesem Ort vorkommen
            - Sehr kurz: 1-2 Wörter, maximal 3 Wörter
            - Auf Deutsch
            
            Denke konkret: Wer ist wirklich täglich/regelmäßig an diesem Ort?
            - Bei "Park": Spaziergänger, Jogger, Hundebesitzer, Gärtner
            - Bei "Schule": Schüler, Lehrer, Hausmeister, Sekretärin
            - Bei "Krankenhaus": Arzt, Krankenpfleger, Patient, Rezeptionist
            - Bei "Supermarkt": Kassierer, Kunde, Filialleiter
            
            Antworte ausschließlich mit der Rolle als einfachen Text, KEINE Anführungszeichen, KEINE Erklärungen, NUR die Rolle.
            
            Ort: \(location)
            """
            
            let response = try await session.respond(to: prompt)
            let role = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "\"", with: "")
                .replacingOccurrences(of: "'", with: "")
            
            if !role.isEmpty && role.count < 50 { // Maximal 50 Zeichen für eine Rolle
                print("🧠 Rolle generiert: '\(role)' für Ort '\(location)'")
                return role
            }
            
            print("⚠️ Konnte Rolle nicht generieren, verwende Fallback")
            print("📝 KI-Antwort war: \(role.prefix(100))...")
            
        } catch {
            print("💡 Fehler beim Generieren der Rolle: \(error)")
        }
        
        return generateFallbackRole(for: location)
        #else
        return generateFallbackRole(for: location)
        #endif
    }
    
    /// Generiert mehrere verschiedene Rollen für einen Ort (für mehrere Spieler)
    @MainActor
    func generateRoles(for location: String, count: Int) async -> [String] {
        #if canImport(FoundationModels)
        guard isAvailable, let session = session else {
            print("🧪 Rollen-Generierung: KI nicht verfügbar, verwende Fallback")
            return generateFallbackRoles(for: location, count: count)
        }
        
        isResponding = true
        defer { isResponding = false }
        
        do {
            let prompt = """
            Du bist der Moderator eines Spion-Spiels im Rollen-Modus. Generiere \(count) verschiedene, REALISTISCHE und TYPISCHE Rollen für Personen, die sich am Ort "\(location)" aufhalten.
            
            WICHTIGE REGELN:
            - Die Rollen müssen SEHR TYPISCH und REALISTISCH für diesen spezifischen Ort sein
            - Nur Rollen, die man wirklich regelmäßig an diesem Ort findet
            - KEINE abstrakten, ungewöhnlichen oder kreativen Rollen
            - KEINE Rollen, die nur selten oder nie an diesem Ort vorkommen
            - Sehr kurz: 1-2 Wörter, maximal 3 Wörter
            - Auf Deutsch
            - Alle unterschiedlich (keine Duplikate)
            
            Denke konkret: Wer ist wirklich täglich/regelmäßig an diesem Ort?
            - Bei "Park": Spaziergänger, Jogger, Hundebesitzer, Spielplatz-Aufsicht, Gärtner
            - Bei "Schule": Schüler, Lehrer, Hausmeister, Sekretärin, Direktor
            - Bei "Krankenhaus": Arzt, Krankenpfleger, Patient, Rezeptionist
            - Bei "Supermarkt": Kassierer, Kunde, Filialleiter, Bäcker
            
            Antworte ausschließlich mit einem JSON-Array im Format:
            ["Rolle 1", "Rolle 2", "Rolle 3", "Rolle 4"]
            
            KEINE Einleitung, KEIN Markdown, KEINE Codeblöcke, NUR das JSON-Array.
            
            Ort: \(location)
            Anzahl Rollen: \(count)
            """
            
            let response = try await session.respond(to: prompt)
            let text = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Versuch 1: Direktes JSON-Array parsen
            if let roles = parseHintsArray(from: text) {
                print("🧠 Rollen generiert: \(roles.count) Rollen für Ort '\(location)'")
                return Array(roles.prefix(count))
            }
            
            // Versuch 2: JSON-Array aus Text extrahieren
            if let jsonData = extractJSONArray(from: text),
               let roles = try? JSONDecoder().decode([String].self, from: jsonData) {
                print("🧠 Rollen generiert (extrahiert): \(roles.count) Rollen für Ort '\(location)'")
                return Array(roles.prefix(count))
            }
            
            print("⚠️ Konnte Rollen nicht parsen, verwende Fallback")
            print("📝 KI-Antwort war: \(text.prefix(200))...")
            
        } catch {
            print("💡 Fehler beim Generieren der Rollen: \(error)")
        }
        
        return generateFallbackRoles(for: location, count: count)
        #else
        return generateFallbackRoles(for: location, count: count)
        #endif
    }
    
    private func generateFallbackRole(for location: String) -> String? {
        let locationLower = location.lowercased()
        
        // Fallback-Rollen basierend auf Ort
        if locationLower.contains("schule") {
            return ["Schüler", "Lehrer", "Direktor", "Hausmeister"].randomElement()
        } else if locationLower.contains("krankenhaus") || locationLower.contains("klinik") {
            return ["Arzt", "Krankenpfleger", "Patient"].randomElement()
        } else if locationLower.contains("restaurant") || locationLower.contains("café") {
            return ["Kellner", "Koch", "Gast"].randomElement()
        } else if locationLower.contains("supermarkt") || locationLower.contains("markt") {
            return ["Kassierer", "Kunde", "Lagerist"].randomElement()
        } else if locationLower.contains("kino") {
            return ["Zuschauer", "Vorführer", "Kassierer"].randomElement()
        } else if locationLower.contains("bibliothek") {
            return ["Leser", "Bibliothekar", "Student"].randomElement()
        } else if locationLower.contains("park") {
            return ["Spaziergänger", "Jogger", "Spieler"].randomElement()
        } else {
            return "Besucher"
        }
    }
    
    private func generateFallbackRoles(for location: String, count: Int) -> [String] {
        let locationLower = location.lowercased()
        var roles: [String] = []
        
        // Fallback-Rollen basierend auf Ort - nur sehr typische Rollen
        if locationLower.contains("schule") {
            roles = ["Schüler", "Lehrer", "Direktor", "Hausmeister", "Reinigungskraft", "Sekretärin"]
        } else if locationLower.contains("krankenhaus") || locationLower.contains("klinik") {
            roles = ["Arzt", "Krankenpfleger", "Patient", "Rezeptionist", "Chirurg", "Sanitäter"]
        } else if locationLower.contains("restaurant") || locationLower.contains("café") {
            roles = ["Kellner", "Koch", "Gast", "Rezeptionist", "Barkeeper"]
        } else if locationLower.contains("supermarkt") || locationLower.contains("markt") {
            roles = ["Kassierer", "Kunde", "Lagerist", "Filialleiter", "Bäcker"]
        } else if locationLower.contains("kino") {
            roles = ["Zuschauer", "Vorführer", "Kassierer", "Platzanweiser"]
        } else if locationLower.contains("bibliothek") {
            roles = ["Leser", "Bibliothekar", "Student", "Besucher"]
        } else if locationLower.contains("park") {
            roles = ["Spaziergänger", "Jogger", "Hundebesitzer", "Gärtner", "Spielplatz-Aufsicht"]
        } else if locationLower.contains("schwimmbad") || locationLower.contains("bad") {
            roles = ["Schwimmer", "Bademeister", "Besucher", "Rettungsschwimmer"]
        } else if locationLower.contains("bahnhof") {
            roles = ["Reisender", "Schaffner", "Kiosk-Verkäufer", "Reinigungskraft"]
        } else if locationLower.contains("flughafen") {
            roles = ["Passagier", "Check-in-Mitarbeiter", "Sicherheitsmitarbeiter", "Pilot"]
        } else if locationLower.contains("museum") {
            roles = ["Besucher", "Museumsführer", "Aufsicht", "Kustos"]
        } else if locationLower.contains("stadion") {
            roles = ["Zuschauer", "Spieler", "Trainer", "Stadion-Mitarbeiter"]
        } else if locationLower.contains("theater") {
            roles = ["Zuschauer", "Schauspieler", "Kassierer", "Platzanweiser"]
        } else if locationLower.contains("zoo") {
            roles = ["Besucher", "Tierpfleger", "Zoo-Führer", "Kassierer"]
        } else if locationLower.contains("apotheke") {
            roles = ["Kunde", "Apotheker", "Praktikant", "Reinigungskraft"]
        } else if locationLower.contains("bäckerei") {
            roles = ["Kunde", "Bäcker", "Verkäufer", "Konditor"]
        } else if locationLower.contains("tankstelle") {
            roles = ["Kunde", "Tankstellen-Mitarbeiter", "Kassierer"]
        } else if locationLower.contains("post") {
            roles = ["Kunde", "Postmitarbeiter", "Paketbote", "Kassierer"]
        } else if locationLower.contains("bank") {
            roles = ["Kunde", "Bankangestellter", "Berater", "Sicherheitsmitarbeiter"]
        } else {
            // Generische Rollen für unbekannte Orte - sehr konservativ
            roles = ["Besucher", "Mitarbeiter", "Kunde"]
        }
        
        // Mische und nimm die benötigte Anzahl
        return Array(roles.shuffled().prefix(count))
    }
}
