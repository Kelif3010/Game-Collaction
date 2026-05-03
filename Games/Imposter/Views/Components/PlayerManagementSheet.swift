import SwiftUI

struct PlayerManagementSheet: View {
    @Environment(GameSettings.self) var gameSettings
    @Environment(\.dismiss) private var dismiss
    private let playerManager = GlobalPlayerManager.shared

    @State private var newPlayerName = ""
    @FocusState private var isInputFocused: Bool
    @State private var showCrewPlayers = false

    private let accent = Color(red: 1.0, green: 0.41, blue: 0.23)

    private var trimmed: String {
        newPlayerName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canAdd: Bool {
        !trimmed.isEmpty && !gameSettings.players.contains(where: { $0.name == trimmed })
    }

    private var crewNotSelected: [GlobalPlayer] {
        playerManager.players.filter { crew in
            !gameSettings.players.contains(where: { $0.name == crew.name })
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ImposterStyle.backgroundGradient.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        newPlayerSection
                        if !gameSettings.players.isEmpty {
                            selectedPlayersSection
                        }
                        if !crewNotSelected.isEmpty {
                            crewSection
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Spieler")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") { dismiss() }
                        .font(.headline)
                        .foregroundStyle(accent)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(28)
        .presentationBackground(.clear)
    }

    // MARK: - Neuer Spieler

    private var newPlayerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("NEUER SPIELER")

            HStack(spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "person.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(accent.opacity(0.7))
                    TextField("Name eingeben…", text: $newPlayerName)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white)
                        .tint(accent)
                        .focused($isInputFocused)
                        .submitLabel(.done)
                        .onSubmit { addCurrentName() }
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.words)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 11)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.06))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    isInputFocused ? accent.opacity(0.5) : Color.white.opacity(0.08),
                                    lineWidth: 1
                                )
                        )
                )

                Button { addCurrentName() } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(canAdd ? .black : .gray)
                        .frame(width: 46, height: 46)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(canAdd ? accent : Color.white.opacity(0.06))
                        )
                }
                .disabled(!canAdd)
            }
        }
    }

    // MARK: - Ausgewählte Spieler

    private var selectedPlayersSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("AUSGEWÄHLT (\(gameSettings.players.count))", color: accent)

            VStack(spacing: 8) {
                ForEach(gameSettings.players) { player in
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(accent.opacity(0.15))
                                .frame(width: 38, height: 38)
                            Text(String(player.name.prefix(1)).uppercased())
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(accent)
                        }
                        Text(player.name)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)
                        Spacer()
                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            withAnimation(.spring(response: 0.3)) {
                                if let index = gameSettings.players.firstIndex(where: { $0.id == player.id }) {
                                    gameSettings.removePlayer(at: index)
                                }
                            }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(ImposterStyle.mutedText)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(accent.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(accent.opacity(0.35), lineWidth: 1)
                            )
                    )
                }
            }
        }
    }

    // MARK: - Deine Crew

    private var crewSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                sectionLabel("DEINE CREW")
                Spacer()
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) {
                        showCrewPlayers.toggle()
                    }
                } label: {
                    Text(showCrewPlayers ? "Ausblenden" : "Einblenden")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(accent)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Capsule().fill(accent.opacity(0.12)))
                }
                .buttonStyle(.plain)
            }

            if showCrewPlayers {
                VStack(spacing: 8) {
                    ForEach(crewNotSelected) { player in
                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            withAnimation(.spring(response: 0.3)) {
                                gameSettings.addPlayer(name: player.name)
                            }
                        } label: {
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(Color.white.opacity(0.06))
                                        .frame(width: 38, height: 38)
                                    Text(String(player.name.prefix(1)).uppercased())
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundStyle(ImposterStyle.mutedText)
                                }
                                Text(player.name)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(.white)
                                Spacer()
                                Image(systemName: "plus.circle")
                                    .font(.title3)
                                    .foregroundStyle(accent)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 11)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.white.opacity(0.04))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(Color.white.opacity(0.07), lineWidth: 1)
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func sectionLabel(_ text: String, color: Color = ImposterStyle.mutedText) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .bold, design: .monospaced))
            .foregroundStyle(color)
            .tracking(1.5)
    }

    private func addCurrentName() {
        guard canAdd else {
            newPlayerName = ""
            return
        }
        withAnimation(.spring(response: 0.3)) {
            gameSettings.addPlayer(name: trimmed)
        }
        GlobalPlayerManager.shared.addPlayer(name: trimmed)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        newPlayerName = ""
        isInputFocused = true
    }
}

// Simple button style for scaling effect (kept for compatibility)
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    let settings = GameSettings()
    settings.players = [
        Player(name: "Alice"),
        Player(name: "Bob"),
        Player(name: "Charlie")
    ]
    return PlayerManagementSheet()
        .environment(settings)
}
