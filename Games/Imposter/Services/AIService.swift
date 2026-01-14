//
//  AIService.swift
//  Imposter
//
//  Created by Ken on 23.09.25.
//

import Foundation
import Combine
#if canImport(FoundationModels)
import FoundationModels
#endif
import AVFoundation

/// Zentrale KI-Service für alle AI-Features
@MainActor
class AIService: ObservableObject {
    static let shared = AIService()
    
    @Published var isAvailable = false
    @Published var isResponding = false
    
    // Text-to-Speech
    private let synthesizer = AVSpeechSynthesizer()
    
    var session: Any?
    private let fallbackService = FallbackAIService()
    private let settings = SettingsService.shared
    
    private init() {
        checkAvailability()
    }
    
    /// Prüft ob Apple Intelligence verfügbar ist
    private func checkAvailability() {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            let model = SystemLanguageModel.default
            
            switch model.availability {
            case .available:
                isAvailable = true
                setupSession()
            case .unavailable:
                isAvailable = false
            }
            return
        }
        #endif
        isAvailable = false
    }
    
    /// Erstellt eine neue KI-Session
    #if canImport(FoundationModels)
    @available(iOS 26.0, *)
    private func setupSession() {
        let instructions = """
        Du bist ein intelligenter Moderator für ein Spion-Spiel.
        Deine Aufgabe ist es, Hinweise, Rollen und Moderations-Logs zu liefern,
        die das Spiel interessanter und fairer machen.

        Wichtige Regeln:
        - Antworte immer auf Deutsch
        - Sei kreativ aber fair
        - Halte Antworten kurz und prägnant
        - Verwende einen spannenden, geheimnisvollen Ton
        """
        session = LanguageModelSession(instructions: instructions)
    }
    #endif
    
    /// Generiert Mission-Flavor für Imposter
    func generateMissionFlavor(for player: Player, category: Category) async -> String {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            guard isAvailable, let session = session as? LanguageModelSession else {
                return fallbackService.generateMissionFlavor(for: player, category: category)
            }
            
            isResponding = true
            defer { isResponding = false }
            
            do {
                let prompt = """
                Generiere eine kurze, spannende Mission-Beschreibung für \(player.name) 
                in der Kategorie "\(category.name)". 
                Maximal 2 Sätze, geheimnisvoller Ton.
                """
                
                let response = try await session.respond(to: prompt)
                return response.content
            } catch {
                return fallbackService.generateMissionFlavor(for: player, category: category)
            }
        }
        #endif
        return fallbackService.generateMissionFlavor(for: player, category: category)
    }
    
    /// Generiert Moderator-Log Erklärung
    func generateModeratorLog(for selection: ImposterSelection) async -> String {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            guard isAvailable, let session = session as? LanguageModelSession else {
                return fallbackService.generateModeratorLog(for: selection)
            }
            
            isResponding = true
            defer { isResponding = false }
            
            do {
                let prompt = createModeratorLogPrompt(selection: selection)
                let response = try await session.respond(to: prompt)
                return response.content
            } catch {
                return fallbackService.generateModeratorLog(for: selection)
            }
        }
        #endif
        return fallbackService.generateModeratorLog(for: selection)
    }
    
    /// Finds a German Siri (female) voice if available, otherwise falls back to any German voice
    private func germanSiriVoice() -> AVSpeechSynthesisVoice? {
        let voices = AVSpeechSynthesisVoice.speechVoices()
        if let v = voices.first(where: { voice in
            voice.language == "de-DE" && voice.name.localizedCaseInsensitiveContains("Siri") && voice.quality == .enhanced
        }) {
            return v
        }
        if let v = voices.first(where: { voice in
            voice.language == "de-DE" && voice.name.localizedCaseInsensitiveContains("Siri")
        }) {
            return v
        }
        if let v = voices.first(where: { $0.language == "de-DE" && $0.quality == .enhanced }) {
            return v
        }
        if let v = voices.first(where: { $0.language == "de-DE" }) {
            return v
        }
        return nil
    }
    
    /// Speaks the given text using a German Siri (female) voice where available
    func speak(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try AVAudioSession.sharedInstance().setActive(true, options: [])
        } catch {
            // Error ignored
        }
        utterance.voice = germanSiriVoice()
        utterance.rate = 0.48
        utterance.pitchMultiplier = 1.03
        utterance.volume = 0.95
        utterance.preUtteranceDelay = 0.10
        utterance.postUtteranceDelay = 0.05
        if #available(iOS 17.0, macOS 14.0, *) {
            utterance.prefersAssistiveTechnologySettings = false
        }

        synthesizer.speak(utterance)
    }
    
    private func createModeratorLogPrompt(selection: ImposterSelection) -> String {
        return """
        Erkläre die Imposter-Auswahl in einem kurzen Moderator-Log:
        
        Ausgewählte Imposter: \(selection.selectedImposters.map { $0.name }.joined(separator: ", "))
        Fairness-Score: \(selection.fairnessScore)
        Cooldown-Status: \(selection.cooldownStatus)
        Grund: \(selection.reason)
        
        Maximal 2 Sätze, technischer Ton.
        """
    }
}

// MARK: - Fallback Service (ohne KI)

class FallbackAIService {
    private let missionFlavors = [
        "Deine Mission erfordert hoechste Diskretion.",
        "Die Zeit draengt - handle schnell und praezise.",
        "Vertraue niemandem, nicht einmal deinen engsten Verbuendeten.",
        "Dein Ziel ist in Reichweite, aber Vorsicht ist geboten.",
        "Die Mission ist kritisch fuer den Erfolg der Operation."
    ]
    private let templateCatalog = MissionTemplateCatalog.load()
    
    func generateMissionFlavor(for player: Player, category: Category) -> String {
        if let template = templateCatalog?.randomTemplate(for: category.name) {
            return renderTemplate(template, player: player, category: category)
        }
        return missionFlavors.randomElement() ?? "Deine Mission beginnt jetzt."
    }
    
    func generateModeratorLog(for selection: ImposterSelection) -> String {
        return "Imposter ausgewählt basierend auf Fairness-Algorithmus. Cooldown und Häufigkeits-Tracking berücksichtigt."
    }

    private func renderTemplate(_ template: String, player: Player, category: Category) -> String {
        return template
            .replacingOccurrences(of: "{player}", with: player.name)
            .replacingOccurrences(of: "{category}", with: category.name)
    }
}

private struct MissionTemplateCatalog: Decodable {
    let categories: [MissionTemplateCategory]

    static func load() -> MissionTemplateCatalog? {
        guard let url = Bundle.main.url(forResource: "MissionTemplates", withExtension: "json") else {
            return nil
        }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(MissionTemplateCatalog.self, from: data)
        } catch {
            print("MissionTemplates.json konnte nicht geladen werden: \(error)")
            return nil
        }
    }

    func randomTemplate(for categoryName: String) -> String? {
        let normalized = normalize(categoryName)
        if let match = categories.first(where: { $0.matches(normalized) }),
           let template = match.texts.randomElement() {
            return template
        }
        if let fallback = categories.first(where: { $0.key == "default" }) {
            return fallback.texts.randomElement()
        }
        return nil
    }

    private func normalize(_ input: String) -> String {
        var normalized = input.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
        normalized = normalized.replacingOccurrences(of: "ß", with: "ss")
        normalized = normalized.replacingOccurrences(of: "[^a-z0-9 ]", with: " ", options: .regularExpression)
        normalized = normalized.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        return normalized.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private struct MissionTemplateCategory: Decodable {
    let key: String
    let aliases: [String]
    let texts: [String]

    func matches(_ normalizedCategory: String) -> Bool {
        if normalizedCategory.contains(key) { return true }
        return aliases.contains(where: { normalizedCategory.contains($0) })
    }
}
