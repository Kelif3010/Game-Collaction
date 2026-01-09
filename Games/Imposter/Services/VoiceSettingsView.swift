import SwiftUI
import AVFoundation

struct VoiceSettingsView: View {
    @ObservedObject private var voiceService = VoiceService.shared
    @State private var selectedIdentifier: String? = VoiceService.shared.preferredVoiceIdentifier()
    @State private var isSpeaking = false
    
    // Lokale State-Variablen für Slider
    @State private var speechRate: Float = 0.52
    @State private var pitchMultiplier: Float = 1.0
    
    // Gruppierte Stimmen
    private var groupedVoices: [String: [AVSpeechSynthesisVoice]] {
        let all = voiceService.availableVoices()
        let german = all.filter { $0.language.lowercased().hasPrefix("de") }
        
        var groups: [String: [AVSpeechSynthesisVoice]] = [
            "Premium & Siri": [],
            "Erweitert": [],
            "Standard": [],
            "Andere Sprachen": []
        ]
        
        for voice in german {
            // Klassifizierung
            let isSiri = voice.identifier.lowercased().contains("siri")
            let isPremium = voice.quality == .premium
            let isEnhanced = voice.quality == .enhanced
            
            if isPremium || isSiri {
                groups["Premium & Siri"]?.append(voice)
            } else if isEnhanced {
                groups["Erweitert"]?.append(voice)
            } else {
                groups["Standard"]?.append(voice)
            }
        }
        
        // Andere Sprachen nur anzeigen wenn nötig, sonst leer lassen um UI sauber zu halten
        // groups["Andere Sprachen"] = all.filter { !$0.language.lowercased().hasPrefix("de") }
        return groups
    }
    
    private let sectionOrder = ["Premium & Siri", "Erweitert", "Standard"]

    var body: some View {
        ZStack {
            ImposterStyle.backgroundGradient.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 25) {
                    // Header
                    HStack {
                        Spacer()
                        Text("STIMME KONFIGURIEREN")
                            .font(.headline.bold())
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.top, 20)
                    
                    // Anleitung Warnung wenn keine guten Stimmen da sind
                    if (groupedVoices["Premium & Siri"]?.isEmpty ?? true) && (groupedVoices["Erweitert"]?.isEmpty ?? true) {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.yellow)
                                Text("Verbessere die Sprachqualität")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                            
                            Text("Für einen natürlichen Klang (weniger Roboter) lade bitte 'Erweiterte' oder 'Premium' Stimmen in den iOS Einstellungen herunter:")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                                .fixedSize(horizontal: false, vertical: true)
                            
                            Text("Einstellungen > Bedienungshilfen > Gesprochene Inhalte > Stimmen > Deutsch")
                                .font(.caption.bold())
                                .padding(10)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(8)
                            
                            Text("Hinweis: Die Stimmen 'Siri 1-5' sind von Apple leider für Apps gesperrt. Nutze 'Anna Premium' oder 'Petra Premium' für beste Ergebnisse.")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.5))
                                .padding(.top, 4)
                        }
                        .padding()
                        .background(Color.orange.opacity(0.2))
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.orange.opacity(0.3), lineWidth: 1))
                        .padding(.horizontal)
                    }
                    
                    // Parameter Slider
                    VStack(spacing: 20) {
                        SectionHeader(title: "Feinabstimmung", icon: "slider.horizontal.3")
                        
                        VStack(spacing: 8) {
                            HStack {
                                Text("Geschwindigkeit")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                                Spacer()
                                Text(String(format: "%.2f", speechRate))
                                    .font(.caption.bold())
                                    .foregroundColor(.white)
                            }
                            // Standard ist 0.5. Range erweitert für mehr Kontrolle.
                            Slider(value: $speechRate, in: 0.25...0.75)
                                .tint(.orange)
                        }
                        
                        VStack(spacing: 8) {
                            HStack {
                                Text("Tonhöhe")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                                Spacer()
                                Text(String(format: "%.2f", pitchMultiplier))
                                    .font(.caption.bold())
                                    .foregroundColor(.white)
                            }
                            Slider(value: $pitchMultiplier, in: 0.5...1.5)
                                .tint(.orange)
                        }
                    }
                    .padding(20)
                    .background(Color.black.opacity(0.2))
                    .cornerRadius(16)
                    .padding(.horizontal)
                    
                    // Stimmen Auswahl
                    LazyVStack(spacing: 20, pinnedViews: []) {
                        ForEach(sectionOrder, id: \.self) { sectionTitle in
                            if let voices = groupedVoices[sectionTitle], !voices.isEmpty {
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack {
                                        Text(sectionTitle.uppercased())
                                            .font(.caption.bold())
                                            .foregroundColor(.white.opacity(0.5))
                                            .padding(.leading, 5)
                                        Spacer()
                                    }
                                    
                                    ForEach(voices, id: \.identifier) { voice in
                                        VoiceSelectionRow(
                                            voice: voice,
                                            isSelected: selectedIdentifier == voice.identifier,
                                            onTap: {
                                                selectedIdentifier = voice.identifier
                                                voiceService.setPreferredVoice(identifier: voice.identifier)
                                                testSpeak()
                                            }
                                        )
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                    }
                    
                    // Test Button
                    Button(action: testSpeak) {
                        HStack {
                            Image(systemName: isSpeaking ? "speaker.wave.3.fill" : "play.fill")
                            Text(isSpeaking ? "WIRD ABGESPIELT..." : "STIMME TESTEN")
                        }
                        .font(.headline.bold())
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.orange)
                        .cornerRadius(12)
                    }
                    .padding(20)
                    .disabled(isSpeaking)
                }
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            selectedIdentifier = voiceService.preferredVoiceIdentifier()
            // Lade aktuelle Einstellungen
            let settings = voiceService.getCurrentSettings()
            self.speechRate = settings.rate
            self.pitchMultiplier = settings.pitch
        }
    }
    
    private func testSpeak() {
        // Update Service settings before speaking
        VoiceService.shared.updateSettings(rate: speechRate, pitch: pitchMultiplier)
        
        Task { @MainActor in
            isSpeaking = true
            await voiceService.speak("Das ist ein Test. Ich bin der Spion.")
            isSpeaking = false
        }
    }
}

struct VoiceSelectionRow: View {
    let voice: AVSpeechSynthesisVoice
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(voice.name)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    HStack(spacing: 6) {
                        if voice.quality == .premium {
                            Badge(text: "PREMIUM", color: .purple)
                        } else if voice.identifier.lowercased().contains("siri") {
                             Badge(text: "SIRI", color: .blue)
                        } else if voice.quality == .enhanced {
                            Badge(text: "ENHANCED", color: .green)
                        } else {
                             Badge(text: "STANDARD", color: .gray)
                        }
                        
                        Text(voice.language)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.orange)
                        .font(.title2)
                } else {
                    Image(systemName: "circle")
                        .foregroundColor(.white.opacity(0.1))
                        .font(.title2)
                }
            }
            .padding()
            .background(Color.white.opacity(isSelected ? 0.1 : 0.05))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.orange : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct Badge: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.system(size: 8, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.6))
            .cornerRadius(4)
    }
}