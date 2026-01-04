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
                Section(header: Text(LocalizedStringKey("Allgemein"))) {
                    NavigationLink(destination: LanguageSelectionView()) {
                        HStack {
                            Label(LocalizedStringKey("Sprache"), systemImage: "globe")
                            Spacer()
                            Text(currentLanguageName)
                                .foregroundStyle(.secondary)
                        }
                    }
                    NavigationLink(destination: Text("App Icons hier")) {
                        Label(LocalizedStringKey("App Icon"), systemImage: "app.badge")
                    }
                }
                
                // MARK: - Community
                Section(header: Text(LocalizedStringKey("Community"))) {
                    // YouTube Link
                    Link(destination: URL(string: "https://www.youtube.com/@elfiandken")!) {
                        Label {
                            Text(LocalizedStringKey("Elfiandken"))
                                .foregroundStyle(.primary)
                        } icon: {
                            Image("Youtube")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)  // YouTube Rot
                        }
                    }
                    
                    // Instagram Link
                    Link(destination: URL(string: "https://www.instagram.com/elfiandken/")!) {
                        Label {
                            Text(LocalizedStringKey("Elfiandken"))
                                .foregroundStyle(.primary)
                        } icon: {
                            Image("Instagram")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24) // Insta Purple
                        }
                    }
                }
                
                // MARK: - Support & Info
                Section(header: Text(LocalizedStringKey("Support & Info"))) {
                    NavigationLink(destination: Text(LocalizedStringKey("Über uns Text"))) {
                        Label(LocalizedStringKey("Über uns"), systemImage: "info.circle")
                    }
                    
                    Link(destination: URL(string: "mailto:elfiandken@icloud.com")!) {
                        Label(LocalizedStringKey("Feedback senden"), systemImage: "envelope")
                            .foregroundStyle(.primary)
                    }
                    
                    Toggle(LocalizedStringKey("Benachrichtigungen"), isOn: .constant(true))
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
            .navigationTitle(LocalizedStringKey("Einstellungen"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(LocalizedStringKey("Fertig")) {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
    
    private var currentLanguageName: LocalizedStringKey {
        if useSystemLanguage {
            return LocalizedStringKey("System")
        }
        return selectedLanguageCode == "de" ? LocalizedStringKey("Deutsch") : LocalizedStringKey("English")
    }
}

private struct LanguageSelectionView: View {
    @AppStorage("selectedLanguageCode") private var selectedLanguageCode = "de"
    @AppStorage("useSystemLanguage") private var useSystemLanguage = true
    
    var body: some View {
        List {
            Section {
                Toggle(LocalizedStringKey("Systemsprache verwenden"), isOn: $useSystemLanguage)
            }
            
            if !useSystemLanguage {
                Section(header: Text(LocalizedStringKey("Wähle eine Sprache"))) {
                    Button {
                        selectedLanguageCode = "de"
                    } label: {
                        HStack {
                            Text(LocalizedStringKey("Deutsch"))
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
                            Text(LocalizedStringKey("English"))
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
        .navigationTitle(LocalizedStringKey("Sprache"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    MainSettingsView()
}
