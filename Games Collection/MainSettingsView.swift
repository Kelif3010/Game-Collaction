import SwiftUI

struct MainSettingsView: View {
    @Environment(\.dismiss) var dismiss
    
    // Global Language Settings
    @AppStorage("selectedLanguageCode") private var selectedLanguageCode = "de"
    @AppStorage("useSystemLanguage") private var useSystemLanguage = true
    
    // Globaler Spieler-Manager
    @StateObject private var playerManager = GlobalPlayerManager.shared
    @State private var newPlayerName = ""
    @State private var showResetAlert = false
    
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
                
                // MARK: - Spieler (NEU)
                Section(header: Text(LocalizedStringKey("Meine Freunde"))) {
                    ForEach(playerManager.players, id: \.id) { player in
                        HStack {
                            Circle()
                                .fill(Color(hex: player.avatarColorHex))
                                .frame(width: 24, height: 24)
                                .overlay(Text(String(player.name.prefix(1))).font(.caption2).foregroundColor(.white))
                            Text(player.name)
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            let player = playerManager.players[index]
                            playerManager.removePlayer(id: player.id)
                        }
                    }
                    
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(.green)
                        TextField(LocalizedStringKey("Neuen Spieler hinzufügen"), text: $newPlayerName)
                            .onSubmit {
                                addPlayer()
                            }
                        if !newPlayerName.isEmpty {
                            Button(LocalizedStringKey("Hinzufügen")) {
                                addPlayer()
                            }
                        }
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
                
                // MARK: - Erweitert / Reset (NEU)
                Section(header: Text(LocalizedStringKey("Erweitert"))) {
                    Button(role: .destructive) {
                        showResetAlert = true
                    } label: {
                        Label(LocalizedStringKey("Alle Einstellungen zurücksetzen"), systemImage: "trash")
                    }
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
            .alert(LocalizedStringKey("Einstellungen zurücksetzen?"), isPresented: $showResetAlert) {
                Button(LocalizedStringKey("Abbrechen"), role: .cancel) { }
                Button(LocalizedStringKey("Zurücksetzen"), role: .destructive) {
                    AppLifecycleManager.shared.factoryReset()
                    dismiss()
                }
            } message: {
                Text(LocalizedStringKey("Dies löscht alle gespeicherten Daten (Spieler, Highscores, Einstellungen). Diese Aktion kann nicht rückgängig gemacht werden."))
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
    
    private func addPlayer() {
        guard !newPlayerName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        withAnimation {
            playerManager.addPlayer(name: newPlayerName)
            newPlayerName = ""
        }
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
                        useSystemLanguage = false
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
                        useSystemLanguage = false
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

// Helper for Hex Color
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    MainSettingsView()
}