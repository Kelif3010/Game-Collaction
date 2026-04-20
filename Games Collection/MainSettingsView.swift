import SwiftUI

struct MainSettingsView: View {
    @Environment(\.dismiss) var dismiss

    @AppStorage("selectedLanguageCode") private var selectedLanguageCode = "de"
    @AppStorage("useSystemLanguage")    private var useSystemLanguage    = true
    @AppStorage("isHapticsEnabled")     private var isHapticsEnabled     = true
    @AppStorage("myPlayerName")         private var myPlayerName         = ""

    @ObservedObject private var playerManager = GlobalPlayerManager.shared

    @State private var showAddPlayer  = false
    @State private var showResetAlert = false

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background — identisch mit Rest der App
                LinearGradient(
                    colors: [.black, Color.indigo.opacity(0.5), Color.purple.opacity(0.4)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) {

                        // ── ID Card ──────────────────────────────────────
                        GamerIDCard(name: $myPlayerName)
                            .padding(.top, 8)

                        // ── Crew ──────────────────────────────────────────
                        SettingsSection(label: "Deine Crew") {
                            crewRow
                        }

                        // ── Einstellungen ─────────────────────────────────
                        SettingsSection(label: "Einstellungen") {
                            VStack(spacing: 0) {
                                ToggleRow(
                                    icon: "iphone.radiowaves.left.and.right",
                                    accentColor: isHapticsEnabled ? .green : .gray,
                                    title: "Haptik",
                                    isOn: Binding(
                                        get: { isHapticsEnabled },
                                        set: {
                                            isHapticsEnabled = $0
                                            if $0 { UIImpactFeedbackGenerator(style: .medium).impactOccurred() }
                                        }
                                    ),
                                    hasDivider: true
                                )

                                ToggleRow(
                                    icon: SoundManager.shared.isSoundEnabled
                                        ? "speaker.wave.2.fill" : "speaker.slash.fill",
                                    accentColor: SoundManager.shared.isSoundEnabled ? .blue : .gray,
                                    title: "Sound",
                                    isOn: Binding(
                                        get: { SoundManager.shared.isSoundEnabled },
                                        set: { SoundManager.shared.isSoundEnabled = $0 }
                                    ),
                                    hasDivider: true
                                )

                                NavigationLink(destination: LanguageSelectionView()) {
                                    NavRow(
                                        icon: "globe",
                                        accentColor: .orange,
                                        title: "Sprache",
                                        value: useSystemLanguage
                                            ? "System"
                                            : (selectedLanguageCode == "de" ? "Deutsch" : "English"),
                                        hasDivider: true
                                    )
                                }

                                NavigationLink(destination: AppIconPickerView()) {
                                    NavRow(
                                        icon: "app.badge",
                                        accentColor: .purple,
                                        title: "App Icon",
                                        value: "Ändern",
                                        hasDivider: false
                                    )
                                }
                            }
                        }

                        // ── Community ─────────────────────────────────────
                        SettingsSection(label: "Community") {
                            VStack(spacing: 0) {
                                if let url = URL(string: "https://www.youtube.com/@elfiandken") {
                                    Link(destination: url) {
                                        NavRow(
                                            icon: "play.rectangle.fill",
                                            accentColor: .red,
                                            title: "YouTube",
                                            value: "@elfiandken",
                                            hasDivider: true
                                        )
                                    }
                                }

                                if let url = URL(string: "https://www.instagram.com/elfiandken/") {
                                    Link(destination: url) {
                                        NavRow(
                                            icon: "camera.fill",
                                            accentColor: .pink,
                                            title: "Instagram",
                                            value: "@elfiandken",
                                            hasDivider: true
                                        )
                                    }
                                }

                                if let url = URL(string: "mailto:elfiandken@icloud.com") {
                                    Link(destination: url) {
                                        NavRow(
                                            icon: "envelope.fill",
                                            accentColor: .cyan,
                                            title: "Feedback",
                                            value: "Schreib uns",
                                            hasDivider: false
                                        )
                                    }
                                }
                            }
                        }

                        // ── Footer ────────────────────────────────────────
                        VStack(spacing: 16) {
                            Button(role: .destructive) {
                                showResetAlert = true
                            } label: {
                                Text("Alle Daten löschen")
                                    .font(.subheadline)
                                    .foregroundStyle(.red.opacity(0.6))
                            }

                            VStack(spacing: 3) {
                                Text("KELIF")
                                    .font(.system(size: 10, weight: .black, design: .rounded))
                                    .tracking(5)
                                    .foregroundStyle(.white.opacity(0.18))
                                Text("Version \(appVersion)")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.white.opacity(0.12))
                            }
                        }
                        .padding(.top, 4)

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Einstellungen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fertig") { dismiss() }
                        .foregroundStyle(.white)
                }
            }
            // ── Sheets & Alerts ───────────────────────────────────────────
            .sheet(isPresented: $showAddPlayer) {
                AddPlayerSheet { name in
                    playerManager.addPlayer(name: name)
                }
                .presentationDetents([.height(260)])
                .presentationCornerRadius(28)
                .presentationBackground(.ultraThinMaterial)
            }
            .alert("Einstellungen zurücksetzen?", isPresented: $showResetAlert) {
                Button("Abbrechen", role: .cancel) { }
                Button("Zurücksetzen", role: .destructive) {
                    AppLifecycleManager.shared.factoryReset()
                    dismiss()
                }
            } message: {
                Text("Löscht alle Spieler, Highscores und Einstellungen. Kann nicht rückgängig gemacht werden.")
            }
        }
    }

    // MARK: - Crew Row

    private var crewRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 18) {
                ForEach(playerManager.players) { player in
                    PlayerBubble(player: player) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            playerManager.removePlayer(id: player.id)
                        }
                    }
                }

                // Add Button
                Button { showAddPlayer = true } label: {
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(.white.opacity(0.05))
                                .frame(width: 64, height: 64)
                                .overlay(
                                    Circle()
                                        .strokeBorder(
                                            style: StrokeStyle(lineWidth: 1.5, dash: [4, 3])
                                        )
                                        .foregroundStyle(.white.opacity(0.2))
                                )

                            Image(systemName: "plus")
                                .font(.system(size: 22, weight: .light))
                                .foregroundStyle(.white.opacity(0.45))
                        }

                        Text("Hinzufügen")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.white.opacity(0.3))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
}

// MARK: - Section Container

private struct SettingsSection<Content: View>: View {
    let label: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(label.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .tracking(1.5)
                .foregroundStyle(.white.opacity(0.38))
                .padding(.horizontal, 4)

            content
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .strokeBorder(.white.opacity(0.08), lineWidth: 1)
                        )
                )
                .clipShape(RoundedRectangle(cornerRadius: 20))
        }
    }
}

// MARK: - Row Components

private struct ToggleRow: View {
    let icon: String
    let accentColor: Color
    let title: String
    @Binding var isOn: Bool
    let hasDivider: Bool

    var body: some View {
        HStack(spacing: 14) {
            IconBadge(icon: icon, color: accentColor)

            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.white)

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(accentColor)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .overlay(alignment: .bottom) {
            if hasDivider {
                Rectangle()
                    .fill(.white.opacity(0.07))
                    .frame(height: 0.5)
                    .padding(.leading, 62)
            }
        }
    }
}

private struct NavRow: View {
    let icon: String
    let accentColor: Color
    let title: String
    let value: String
    let hasDivider: Bool

    var body: some View {
        HStack(spacing: 14) {
            IconBadge(icon: icon, color: accentColor)

            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.white)

            Spacer()

            Text(value)
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.38))

            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white.opacity(0.2))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .contentShape(Rectangle())
        .overlay(alignment: .bottom) {
            if hasDivider {
                Rectangle()
                    .fill(.white.opacity(0.07))
                    .frame(height: 0.5)
                    .padding(.leading, 62)
            }
        }
    }
}

private struct IconBadge: View {
    let icon: String
    let color: Color

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 9)
                .fill(color.opacity(0.18))
                .frame(width: 34, height: 34)
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(color)
        }
    }
}

// MARK: - Player Bubble

struct PlayerBubble: View {
    let player: GlobalPlayer
    let onDelete: () -> Void

    private static let palettes: [[Color]] = [
        [.blue, .cyan],
        [.purple, .indigo],
        [.orange, .pink],
        [.green, .teal],
        [.red, .orange],
        [.indigo, .blue],
        [.pink, .purple],
        [.teal, .green],
    ]

    private var colors: [Color] {
        let idx = abs(player.name.hashValue) % Self.palettes.count
        return Self.palettes[idx]
    }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: colors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 64, height: 64)
                    .shadow(color: colors[0].opacity(0.45), radius: 8, y: 4)

                Text(String(player.name.prefix(1)).uppercased())
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
            .contextMenu {
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Entfernen", systemImage: "trash")
                }
            }

            Text(player.name)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white.opacity(0.75))
                .lineLimit(1)
                .frame(width: 68)
        }
    }
}

// MARK: - Add Player Sheet

struct AddPlayerSheet: View {
    let onAdd: (String) -> Void
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Handle
            Capsule()
                .fill(.white.opacity(0.2))
                .frame(width: 36, height: 4)
                .padding(.top, 14)
                .padding(.bottom, 28)

            VStack(spacing: 6) {
                Text("Crew-Mitglied")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("Wie heißt die Person?")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.45))
            }
            .padding(.bottom, 28)

            // Input Row
            HStack(spacing: 10) {
                TextField("Name...", text: $name)
                    .font(.system(size: 19, weight: .medium, design: .rounded))
                    .foregroundStyle(.white)
                    .tint(.cyan)
                    .focused($isFocused)
                    .submitLabel(.done)
                    .onSubmit { confirm() }

                if !name.trimmingCharacters(in: .whitespaces).isEmpty {
                    Button { confirm() } label: {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundStyle(.cyan)
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.25, dampingFraction: 0.8), value: name.isEmpty)
            .padding(.horizontal, 20)
            .padding(.vertical, 15)
            .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(.white.opacity(0.12), lineWidth: 1)
            )
            .padding(.horizontal, 24)

            Spacer()
        }
        .onAppear { isFocused = true }
    }

    private func confirm() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        onAdd(trimmed)
        dismiss()
    }
}

// MARK: - Gamer ID Card

struct GamerIDCard: View {
    @Binding var name: String
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 16) {
            // Avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue, .cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                    .shadow(color: .blue.opacity(0.35), radius: 8, y: 4)

                if name.isEmpty {
                    Image(systemName: "person.fill")
                        .font(.title2)
                        .foregroundStyle(.white.opacity(0.8))
                } else {
                    Text(String(name.prefix(1)).uppercased())
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Hallo,")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.45))

                TextField("Dein Name", text: $name)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .tint(.cyan)
                    .focused($isFocused)
                    .submitLabel(.done)
            }

            Spacer()

            if isFocused {
                Button("OK") { isFocused = false }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.cyan)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isFocused)
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .strokeBorder(.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

// MARK: - Language Selection

private struct LanguageSelectionView: View {
    @AppStorage("selectedLanguageCode") private var selectedLanguageCode = "de"
    @AppStorage("useSystemLanguage")    private var useSystemLanguage    = true

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.black, Color.indigo.opacity(0.4)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 16) {
                // System Toggle
                HStack {
                    Text("Systemsprache")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.white)
                    Spacer()
                    Toggle("", isOn: $useSystemLanguage)
                        .labelsHidden()
                        .tint(.blue)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 13)
                .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(.white.opacity(0.08), lineWidth: 1)
                )
                .padding(.horizontal)

                if !useSystemLanguage {
                    VStack(spacing: 0) {
                        LanguageRow(title: "Deutsch", isSelected: selectedLanguageCode == "de") {
                            selectedLanguageCode = "de"
                        }
                        Rectangle()
                            .fill(.white.opacity(0.07))
                            .frame(height: 0.5)
                            .padding(.leading, 16)
                        LanguageRow(title: "English", isSelected: selectedLanguageCode == "en") {
                            selectedLanguageCode = "en"
                        }
                    }
                    .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(.white.opacity(0.08), lineWidth: 1)
                    )
                    .padding(.horizontal)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                Spacer()
            }
            .padding(.top, 20)
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: useSystemLanguage)
        }
        .navigationTitle("Sprache")
    }
}

struct LanguageRow: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.blue)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.25), value: isSelected)
    }
}

#Preview {
    MainSettingsView()
}
