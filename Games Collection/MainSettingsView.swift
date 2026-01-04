import SwiftUI

struct MainSettingsView: View {
    @Environment(\.dismiss) var dismiss
    
    // Global Language Settings
    @AppStorage("selectedLanguageCode") private var selectedLanguageCode = "de"
    @AppStorage("useSystemLanguage") private var useSystemLanguage = true
    
    var body: some View {
        NavigationStack {
            List {
                // MARK: - Allgemein
                Section(header: Text("Allgemein")) {
                    NavigationLink(destination: LanguageSelectionView()) {
                        HStack {
                            Label("Sprache", systemImage: "globe")
                            Spacer()
                            Text(currentLanguageName)
                                .foregroundStyle(.secondary)
                        }
                    }
                    NavigationLink(destination: Text("App Icons hier")) {
                        Label("App Icon", systemImage: "app.badge")
                    }
                }
                
                // MARK: - Community
                Section(header: Text("Community")) {
                    // YouTube Link
                    Link(destination: URL(string: "https://www.youtube.com/@elfiandken")!) {
                        Label {
                            Text("YouTube")
                                .foregroundStyle(.primary)
                        } icon: {
                            Image(systemName: "play.rectangle.fill")
                                .foregroundStyle(.red) // YouTube Rot
                        }
                    }
                    
                    // Instagram Link
                    Link(destination: URL(string: "https://www.instagram.com/elfiandken/")!) {
                        Label {
                            Text("Instagram")
                                .foregroundStyle(.primary)
                        } icon: {
                            Image(systemName: "camera.fill")
                                .foregroundStyle(.purple) // Insta Purple
                        }
                    }
                }
                
                // MARK: - Support & Info
                Section(header: Text("Support & Info")) {
                    NavigationLink(destination: Text("Über uns Text")) {
                        Label("Über uns", systemImage: "info.circle")
                    }
                    Button("Feedback senden") {
                        // Action für Feedback
                    }
                    Toggle("Benachrichtigungen", isOn: .constant(true))
                }
                
                // MARK: - Branding Footer
                Section {
                    VStack(alignment: .center, spacing: 6) {
                        Text("Made with ❤️ by KELIF")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        
                        Text("KELIF Studios")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Text("Version 1.0.0")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("Einstellungen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fertig") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
    
    private var currentLanguageName: String {
        if useSystemLanguage {
            return "System"
        }
        return selectedLanguageCode == "de" ? "Deutsch" : "English"
    }
}

private struct LanguageSelectionView: View {
    @AppStorage("selectedLanguageCode") private var selectedLanguageCode = "de"
    @AppStorage("useSystemLanguage") private var useSystemLanguage = true
    
    var body: some View {
        List {
            Section {
                Toggle("Systemsprache verwenden", isOn: $useSystemLanguage)
            }
            
            if !useSystemLanguage {
                Section(header: Text("Wähle eine Sprache")) {
                    Button {
                        selectedLanguageCode = "de"
                    } label: {
                        HStack {
                            Text("Deutsch")
                            Spacer()
                            if selectedLanguageCode == "de" {
                                Image(systemName: "checkmark").foregroundColor(.blue)
                            }
                        }
                    }
                    .foregroundColor(.primary)
                    
                    Button {
                        selectedLanguageCode = "en"
                    } label: {
                        HStack {
                            Text("English")
                            Spacer()
                            if selectedLanguageCode == "en" {
                                Image(systemName: "checkmark").foregroundColor(.blue)
                            }
                        }
                    }
                    .foregroundColor(.primary)
                }
            }
        }
        .navigationTitle("Sprache")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    MainSettingsView()
}