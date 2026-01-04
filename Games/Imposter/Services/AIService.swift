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
    
    #if canImport(FoundationModels)
    var session: LanguageModelSession?
    #else
    var session: Any?
    #endif
    private let fallbackService = FallbackAIService()
    private let settings = SettingsService.shared
    
    private init() {
        checkAvailability()
    }
    
    /// Prüft ob Apple Intelligence verfügbar ist
    private func checkAvailability() {
        #if canImport(FoundationModels)
        let model = SystemLanguageModel.default
        
        switch model.availability {
        case .available:
            isAvailable = true
            setupSession()
        case .unavailable:
            isAvailable = false
        }
        #else
        isAvailable = false
        #endif
    }
    
    /// Erstellt eine neue KI-Session
    private func setupSession() {
        #if canImport(FoundationModels)
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
        #endif
    }
    
    /// Generiert Mission-Flavor für Imposter
    func generateMissionFlavor(for player: Player, category: Category) async -> String {
        #if canImport(FoundationModels)
        guard isAvailable, let session = session else {
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
        #else
        return fallbackService.generateMissionFlavor(for: player, category: category)
        #endif
    }
    
    /// Generiert Moderator-Log Erklärung
    func generateModeratorLog(for selection: ImposterSelection) async -> String {
        #if canImport(FoundationModels)
        guard isAvailable, let session = session else {
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
        #else
        return fallbackService.generateModeratorLog(for: selection)
        #endif
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
        "Deine Mission erfordert höchste Diskretion.",
        "Die Zeit drängt - handle schnell und präzise.",
        "Vertraue niemandem, nicht einmal deinen engsten Verbündeten.",
        "Dein Ziel ist in Reichweite, aber Vorsicht ist geboten.",
        "Die Mission ist kritisch für den Erfolg der Operation."
    ]
    
    func generateMissionFlavor(for player: Player, category: Category) -> String {
        return missionFlavors.randomElement() ?? "Deine Mission beginnt jetzt."
    }
    
    func generateModeratorLog(for selection: ImposterSelection) -> String {
        return "Imposter ausgewählt basierend auf Fairness-Algorithmus. Cooldown und Häufigkeits-Tracking berücksichtigt."
    }
}