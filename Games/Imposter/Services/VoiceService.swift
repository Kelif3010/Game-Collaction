//
//  VoiceService.swift
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

/// KI-Voice-Service für Text-to-Speech und Audio-Features
@MainActor
class VoiceService: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    static let shared = VoiceService()
    
    @Published var isSpeaking = false
    @Published var isEnabled = true
    
    private let synthesizer = AVSpeechSynthesizer()
    private let aiService = AIService.shared
    private let preferredVoiceKey = "voice.preferred.identifier"
    
    // Voice-Konfiguration
    private let voiceSettings = VoiceSettings()
    
    private override init() {
        super.init()
        synthesizer.delegate = self
        setupVoice()
    }
    
    // MARK: - Public Methods
    
    /// Spricht einen Text mit KI-generierter Stimme
    func speak(_ text: String, withAI: Bool = false) async {
        guard isEnabled else { return }
        
        if withAI && aiService.isAvailable {
            await speakWithAI(text)
        } else {
            speakWithSystemVoice(text)
        }
    }
    
    /// Spricht einen Hinweis vor
    func speakHint(_ hint: GameHint) async {
        let hintText = "Hinweis: \(hint.content)"
        await speak(hintText, withAI: true)
    }
    
    /// Spricht eine Mission-Beschreibung vor
    func speakMission(_ mission: String) async {
        let missionText = "Mission: \(mission)"
        await speak(missionText, withAI: true)
    }
    
    /// Stoppt das Sprechen
    func stopSpeaking() {
        synthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false
    }
    
    // MARK: - Public Voice Management
    /// Liefert verfügbare Stimmen (de bevorzugt, danach alle)
    func availableVoices() -> [AVSpeechSynthesisVoice] {
        let all = AVSpeechSynthesisVoice.speechVoices()
        let german = all.filter { $0.language.lowercased().hasPrefix("de") }
        if !german.isEmpty { return german + all.filter { !$0.language.lowercased().hasPrefix("de") } }
        return all
    }

    /// Setzt die bevorzugte Stimme per Identifier und speichert die Auswahl
    func setPreferredVoice(identifier: String?) {
        if let id = identifier, let v = AVSpeechSynthesisVoice(identifier: id) {
            voiceSettings.selectedVoice = v
            UserDefaults.standard.set(id, forKey: preferredVoiceKey)
        } else {
            voiceSettings.selectedVoice = pickBestGermanVoice()
            UserDefaults.standard.removeObject(forKey: preferredVoiceKey)
        }
    }

    /// Aktuell gewählte Stimme (Identifier) oder nil
    func preferredVoiceIdentifier() -> String? {
        return voiceSettings.selectedVoice?.identifier
    }
    
    // MARK: - Private Methods
    
    private func speakWithAI(_ text: String) async {
        #if canImport(FoundationModels)
        do {
            // KI generiert eine natürlichere Version des Textes
            let prompt = """
            Formuliere diesen Text für eine Spion-Spiel-Moderatorin um. 
            Verwende einen geheimnisvollen, spannenden Ton. Maximal 2 Sätze.
            
            Original: \(text)
            """
            if let response = try await aiService.session?.respond(to: prompt) {
                let content = response.content
                speakWithSystemVoice(content)
            } else {
                speakWithSystemVoice(text)
            }
        } catch {
            print("🎤 KI-Voice-Fehler: \(error)")
            speakWithSystemVoice(text)
        }
        #else
        speakWithSystemVoice(text)
        #endif
    }
    
    private func speakWithSystemVoice(_ text: String) {
        stopSpeaking()
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = voiceSettings.selectedVoice
        // Natürlichere Parameter: etwas langsamer, leichte Prosodie
        utterance.rate = max(0.42, min(0.52, voiceSettings.speechRate))
        utterance.pitchMultiplier = max(0.95, min(1.1, voiceSettings.pitchMultiplier))
        utterance.volume = voiceSettings.volume
        utterance.preUtteranceDelay = 0.05
        utterance.postUtteranceDelay = 0.03
        
        synthesizer.speak(utterance)
    }
    
    private func setupVoice() {
        // Deutsche Stimme bevorzugen – versuche hochwertige/"Siri"-Stimmen zuerst
        if let storedId = UserDefaults.standard.string(forKey: preferredVoiceKey),
           let v = AVSpeechSynthesisVoice(identifier: storedId) {
            voiceSettings.selectedVoice = v
        } else {
            voiceSettings.selectedVoice = pickBestGermanVoice()
        }
        
        // Optional: Audio-Session für bessere Sprachqualität konfigurieren
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("🎤 AudioSession-Setup fehlgeschlagen: \(error)")
        }
    }

    private func pickBestGermanVoice() -> AVSpeechSynthesisVoice? {
        let all = AVSpeechSynthesisVoice.speechVoices()
        let german = all.filter { $0.language.lowercased().hasPrefix("de") }

        func score(_ v: AVSpeechSynthesisVoice) -> Int {
            let id = v.identifier.lowercased()
            let name = v.name.lowercased()
            var s = 0
            if id.contains("siri") || name.contains("siri") { s += 100 }
            if id.contains("premium") || name.contains("premium") { s += 80 }
            if id.contains("enhanced") || name.contains("enhanced") { s += 60 }
            // Prefer female voices for a moderator vibe (heuristic, may vary by device)
            if name.contains("anna") || name.contains("marlene") || name.contains("helena") { s += 20 }
            return s
        }

        if let best = german.max(by: { score($0) < score($1) }) {
            return best
        }

        // Fallback: any German voice
        if let v = german.first { return v }
        // Fallback: English US
        if let en = AVSpeechSynthesisVoice(language: "en-US") { return en }
        return AVSpeechSynthesisVoice(language: "de-DE")
    }
    
    // MARK: - AVSpeechSynthesizerDelegate methods
    
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = true
        }
    }
    
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
        }
    }
    
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
        }
    }
}

// MARK: - Voice Settings

class VoiceSettings: ObservableObject {
    @Published var selectedVoice: AVSpeechSynthesisVoice?
    @Published var speechRate: Float = 0.5
    @Published var pitchMultiplier: Float = 1.0
    @Published var volume: Float = 0.8
    
    init() {
        // Standard-Einstellungen
    }
}
