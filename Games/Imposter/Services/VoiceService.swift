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
        // Direkte Ausgabe ohne KI-Rewrite, um Latenz zu vermeiden und Originaltext zu bewahren
        let intro: String
        switch hint.type {
        case .challenge:
            intro = "Achtung, eine Challenge"
        case .fake:
            // Tarnung: Gleiches Intro wie bei echten Hinweisen!
            intro = "Hinweis"
        default:
            intro = "Hinweis"
        }
        
        // Punkt sorgt für natürliche Pause ohne "Komma" zu sagen
        let textToSpeak = "\(intro). \(hint.content)"
        speakWithSystemVoice(textToSpeak)
    }
    
    /// Spricht eine Mission-Beschreibung vor
    func speakMission(_ mission: String) async {
        let missionText = "Mission: \(mission)"
        // Hier lassen wir KI-Rewrite zu, falls gewünscht, aber meist ist der Text schon gut
        speakWithSystemVoice(missionText)
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
    
    /// Aktualisiert die Sprachparameter (Rate, Pitch)
    func updateSettings(rate: Float, pitch: Float) {
        voiceSettings.speechRate = rate
        voiceSettings.pitchMultiplier = pitch
    }
    
    /// Gibt die aktuellen Sprachparameter zurück
    func getCurrentSettings() -> (rate: Float, pitch: Float) {
        return (voiceSettings.speechRate, voiceSettings.pitchMultiplier)
    }
    
    // MARK: - Private Methods
    
    private func speakWithAI(_ text: String) async {
        // Legacy Methode, wird aktuell kaum genutzt um Latenz zu sparen.
        speakWithSystemVoice(text)
    }
    
    private func speakWithSystemVoice(_ text: String) {
        stopSpeaking()
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = voiceSettings.selectedVoice
        
        // Werte direkt übernehmen
        utterance.rate = voiceSettings.speechRate
        utterance.pitchMultiplier = voiceSettings.pitchMultiplier
        utterance.volume = voiceSettings.volume
        
        // Pausen für flüssigeren Fluss minimiert
        utterance.preUtteranceDelay = 0.02
        utterance.postUtteranceDelay = 0.02
        
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
            
            // Priorisiere Siri Stimmen (klingen oft am besten)
            if id.contains("siri") { s += 200 }
            if name.contains("siri") { s += 200 }
            
            // Priorisiere Premium/Enhanced
            if v.quality == .premium { s += 100 }
            if v.quality == .enhanced { s += 80 }
            
            // Bekannte gute deutsche Stimmen
            if name.contains("viktor") { s += 50 } // Oft sehr natürlich
            if name.contains("anna") { s += 40 }
            
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
