import SwiftUI

struct MainSettingsView: View {
    @Environment(\.dismiss) var dismiss
    
    // Global Language Settings
    @AppStorage("selectedLanguageCode") private var selectedLanguageCode = "de"
    @AppStorage("useSystemLanguage") private var useSystemLanguage = true
    
    // Global Haptics Setting
    @AppStorage("isHapticsEnabled") private var isHapticsEnabled = true
    
    // Globaler Spieler-Manager
    @StateObject private var playerManager = GlobalPlayerManager.shared
    @ObservedObject private var displayManager = ExternalDisplayManager.shared
    @State private var newPlayerName = ""
    @State private var isAddingPlayer = false
    @State private var showResetAlert = false
    @State private var showStats = false
    
    // Eigener Name (NEU)
    @AppStorage("myPlayerName") private var myPlayerName = ""
    
    // Sound Helper
    var isSoundEnabled: Bool {
        get { SoundManager.shared.isSoundEnabled }
        nonmutating set { SoundManager.shared.isSoundEnabled = newValue }
    }
    
    // Grid Layout Definition
    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    // App Version (automatisch aus Bundle)
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 1. Background (Consistent with GameRecommender)
                LinearGradient(
                    colors: [Color.black, Color.indigo.opacity(0.5), Color.purple.opacity(0.4)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        
                        // MARK: - Header / ID Card
                        GamerIDCard(name: $myPlayerName)
                            .padding(.top)
                        
                        // MARK: - Crew Carousel
                        VStack(alignment: .leading, spacing: 12) {
                            Text(LocalizedStringKey("Deine Crew"))
                                .font(.headline)
                                .foregroundStyle(.white.opacity(0.8))
                                .padding(.horizontal)
                            
                            CrewCarousel(
                                players: playerManager.players,
                                newName: $newPlayerName,
                                isAdding: $isAddingPlayer,
                                onAdd: addPlayer,
                                onDelete: deletePlayer
                            )
                        }
                        
                        // MARK: - Bento Grid (Settings & Links)
                        VStack(alignment: .leading, spacing: 12) {
                            Text(LocalizedStringKey("Dashboard"))
                                .font(.headline)
                                .foregroundStyle(.white.opacity(0.8))
                                .padding(.horizontal)
                            
                            LazyVGrid(columns: columns, spacing: 16) {
                                // 1. Stats (Wide)
                                Button {
                                    showStats = true
                                } label: {
                                    DashboardCard(
                                        icon: "chart.bar.xaxis",
                                        title: LocalizedStringKey("Statistik & Recap"),
                                        subtitle: LocalizedStringKey("Deine Highlights"),
                                        color: .blue
                                    )
                                }
                                .gridCellColumns(2) // Spans full width
                                
                                // 2. Language
                                NavigationLink(destination: LanguageSelectionView()) {
                                    DashboardCard(
                                        icon: "globe",
                                        title: LocalizedStringKey("Sprache"),
                                        subtitle: currentLanguageName,
                                        color: .orange
                                    )
                                }
                                
                                // 3. Haptics (Global)
                                Button {
                                    withAnimation {
                                        isHapticsEnabled.toggle()
                                        if isHapticsEnabled {
                                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                        }
                                    }
                                } label: {
                                    DashboardCard(
                                        icon: "iphone.radiowaves.left.and.right",
                                        title: LocalizedStringKey("Haptik"),
                                        subtitle: isHapticsEnabled ? LocalizedStringKey("Vibrationen an") : LocalizedStringKey("Vibrationen aus"),
                                        color: isHapticsEnabled ? .green : .gray
                                    )
                                }

                                // AirPlay Status
                                DashboardCard(
                                    icon: "airplayvideo",
                                    title: LocalizedStringKey("AirPlay TV"),
                                    subtitle: displayManager.isExternalDisplayConnected ? LocalizedStringKey("Verbunden") : LocalizedStringKey("Bereit"),
                                    color: displayManager.isExternalDisplayConnected ? .green : .blue
                                )
                                
                                // 4. Sound (Global)
                                Button {
                                    withAnimation {
                                        isSoundEnabled = !isSoundEnabled
                                    }
                                } label: {
                                    DashboardCard(
                                        icon: isSoundEnabled ? "speaker.wave.3.fill" : "speaker.slash.fill",
                                        title: LocalizedStringKey("Sound"),
                                        subtitle: isSoundEnabled ? LocalizedStringKey("Effekte an") : LocalizedStringKey("Effekte aus"),
                                        color: isSoundEnabled ? .blue : .gray
                                    )
                                }
                                
                                // 4. App Icon (Placeholder)
                                NavigationLink(destination: AppIconPickerView()) {
                                    DashboardCard(
                                        icon: "app.badge",
                                        title: LocalizedStringKey("App Icon"),
                                        subtitle: LocalizedStringKey("Customize"),
                                        color: .purple
                                    )
                                }
                                
                                // 4. Community (YouTube)
                                if let youtubeURL = URL(string: "https://www.youtube.com/@elfiandken") {
                                    Link(destination: youtubeURL) {
                                        DashboardCard(
                                            imageName: "Youtube",
                                            title: LocalizedStringKey("YouTube"),
                                            subtitle: LocalizedStringKey("@elfiandken"),
                                            color: .red
                                        )
                                    }
                                }

                                // 5. Community (Insta)
                                if let instagramURL = URL(string: "https://www.instagram.com/elfiandken/") {
                                    Link(destination: instagramURL) {
                                        DashboardCard(
                                            imageName: "Instagram",
                                            title: LocalizedStringKey("Instagram"),
                                            subtitle: LocalizedStringKey("Follow us"),
                                            color: .pink
                                        )
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // MARK: - Support & Danger Zone
                        VStack(spacing: 16) {
                            // Support Link
                            if let mailURL = URL(string: "mailto:elfiandken@icloud.com") {
                                Link(destination: mailURL) {
                                    HStack {
                                        Image(systemName: "envelope.fill")
                                        Text(LocalizedStringKey("Feedback senden"))
                                    }
                                    .font(.subheadline.bold())
                                    .foregroundStyle(.white)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(12)
                                }
                            }

                            // Reset
                            Button(role: .destructive) {
                                showResetAlert = true
                            } label: {
                                Text(LocalizedStringKey("Alle Daten löschen"))
                                    .font(.caption)
                                    .foregroundStyle(.red.opacity(0.8))
                            }
                            .padding(.top, 8)
                            
                            // Footer Info
                            VStack(spacing: 4) {
                                Text("Made with ❤️ by KELIF")
                                Text("Version \(appVersion)")
                            }
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.3))
                        }
                        .padding(.horizontal)
                        .padding(.top, 20)
                        
                        Spacer(minLength: 50)
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
                    .foregroundStyle(.white)
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
            .sheet(isPresented: $showStats) {
                GlobalRecapView()
            }
        }
    }
    
    // MARK: - Logic
    
    private var currentLanguageName: LocalizedStringKey {
        if useSystemLanguage {
            return LocalizedStringKey("System")
        }
        return selectedLanguageCode == "de" ? LocalizedStringKey("Deutsch") : LocalizedStringKey("English")
    }
    
    private func addPlayer() {
        guard !newPlayerName.trimmingCharacters(in: .whitespaces).isEmpty else {
            isAddingPlayer = false
            return
        }
        withAnimation {
            playerManager.addPlayer(name: newPlayerName)
            newPlayerName = ""
            isAddingPlayer = false
        }
    }
    
    private func deletePlayer(id: UUID) {
        withAnimation {
            playerManager.removePlayer(id: id)
        }
    }
}

// MARK: - Subviews

struct GamerIDCard: View {
    @Binding var name: String
    
    var body: some View {
        HStack(spacing: 20) {
            // Avatar Placeholder
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 70, height: 70)
                    .shadow(color: .blue.opacity(0.5), radius: 10)
                
                Image(systemName: "person.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(LocalizedStringKey("HALLO"))
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.white.opacity(0.6))
                
                TextField("Dein Name", text: $name)
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .accentColor(.cyan)
                    .submitLabel(.done)
                
                Rectangle()
                    .fill(Color.white.opacity(0.3))
                    .frame(height: 1)
            }
        }
        .padding(24)
        .background(Color.white.opacity(0.05))
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .padding(.horizontal)
    }
}

struct CrewCarousel: View {
    let players: [GlobalPlayer]
    @Binding var newName: String
    @Binding var isAdding: Bool
    let onAdd: () -> Void
    let onDelete: (UUID) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 15) {
                // Existing Players
                ForEach(players) { player in
                    Menu {
                        Button(role: .destructive) {
                            onDelete(player.id)
                        } label: {
                            Label(LocalizedStringKey("Löschen"), systemImage: "trash")
                        }
                    } label: {
                        VStack {
                            Circle()
                                .fill(Color(hex: player.avatarColorHex) ?? .gray)
                                .frame(width: 60, height: 60)
                                .overlay(
                                    Text(String(player.name.prefix(1)))
                                        .font(.title3.bold())
                                        .foregroundStyle(.white)
                                )
                                .shadow(radius: 3)
                            
                            Text(player.name)
                                .font(.caption)
                                .foregroundStyle(.white)
                                .lineLimit(1)
                                .frame(width: 70)
                        }
                    }
                }
                
                // Add Button
                VStack {
                    if isAdding {
                        VStack {
                            TextField("", text: $newName)
                                .multilineTextAlignment(.center)
                                .foregroundStyle(.black) // Input color
                                .padding(8)
                                .background(Color.white)
                                .clipShape(Circle())
                                .frame(width: 60, height: 60)
                                .onSubmit { onAdd() }
                            
                            Text(LocalizedStringKey("Enter..."))
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.7))
                        }
                    } else {
                        Button {
                            withAnimation { isAdding = true }
                        } label: {
                            VStack {
                                Circle()
                                    .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [5]))
                                    .foregroundStyle(.white.opacity(0.5))
                                    .frame(width: 60, height: 60)
                                    .overlay(
                                        Image(systemName: "plus")
                                            .font(.title2)
                                            .foregroundStyle(.white.opacity(0.5))
                                    )
                                
                                Text(LocalizedStringKey("Neu"))
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.5))
                            }
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

struct DashboardCard: View {
    var icon: String? = nil
    var imageName: String? = nil
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey
    let color: Color
    
    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 8) {
                if let imageName = imageName {
                    Image(imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                } else if let icon = icon {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundStyle(color)
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.white)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
            Spacer()
        }
        .padding()
        .frame(height: 110)
        .background(Color.white.opacity(0.1))
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - Helper Views

private struct LanguageSelectionView: View {
    @AppStorage("selectedLanguageCode") private var selectedLanguageCode = "de"
    @AppStorage("useSystemLanguage") private var useSystemLanguage = true
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
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
                                    Image(systemName: "checkmark").foregroundStyle(.blue)
                                }
                            }
                        }
                        
                        Button {
                            useSystemLanguage = false
                            selectedLanguageCode = "en"
                        } label: {
                            HStack {
                                Text(LocalizedStringKey("English"))
                                Spacer()
                                if selectedLanguageCode == "en" {
                                    Image(systemName: "checkmark").foregroundStyle(.blue)
                                }
                            }
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle(LocalizedStringKey("Sprache"))
    }
}

#Preview {
    MainSettingsView()
}
