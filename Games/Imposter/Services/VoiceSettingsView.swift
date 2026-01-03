import SwiftUI
import AVFoundation

struct VoiceSettingsView: View {
    @ObservedObject private var voiceService = VoiceService.shared
    @State private var selectedIdentifier: String? = VoiceService.shared.preferredVoiceIdentifier()
    @State private var isSpeaking = false

    private var voices: [AVSpeechSynthesisVoice] {
        let allVoices = voiceService.availableVoices()
        let germanVoices = allVoices.filter { $0.language.hasPrefix("de") }
        let otherVoices = allVoices.filter { !$0.language.hasPrefix("de") }
        return germanVoices + otherVoices
    }

    var body: some View {
        List {
            Section(header: Text("Stimme auswählen")) {
                ForEach(voices, id: \._identifier) { v in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(v.name)
                                .font(.headline)
                            Text(v.language)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        if selectedIdentifier == v.identifier {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedIdentifier = v.identifier
                        voiceService.setPreferredVoice(identifier: v.identifier)
                    }
                }
            }

            Section(header: Text("Aktion")) {
                Button(action: testSpeak) {
                    HStack {
                        Image(systemName: isSpeaking ? "speaker.wave.2.fill" : "speaker.wave.2")
                        Text(isSpeaking ? "Probehören…" : "Probehören")
                    }
                }
                .disabled(isSpeaking)

                Button("Standardstimme verwenden") {
                    selectedIdentifier = nil
                    voiceService.setPreferredVoice(identifier: nil)
                }
            }
        }
        .navigationTitle("Stimmen")
        .onAppear {
            selectedIdentifier = voiceService.preferredVoiceIdentifier()
        }
    }

    private func testSpeak() {
        Task { @MainActor in
            isSpeaking = true
            await voiceService.speak("Dies ist eine Probe der ausgewählten Stimme.")
            isSpeaking = false
        }
    }
}

private extension AVSpeechSynthesisVoice {
    // Stable id for ForEach
    var _identifier: String { identifier }
}

#Preview {
    NavigationView { VoiceSettingsView() }
}
