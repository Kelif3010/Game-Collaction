import SwiftUI
import Combine

struct PlayerManagementSheet: View {
    @EnvironmentObject var gameSettings: GameSettings
    @Environment(\.dismiss) private var dismiss

    @State private var selectedTab = 0
    @State private var newPlayerName = ""
    @State private var selectedPlayers: Set<String> = []
    @State private var showingAlert = false
    @State private var alertMessage = ""

    let onRequestExpand: (() -> Void)?

    init(onRequestExpand: (() -> Void)? = nil) {
        self.onRequestExpand = onRequestExpand
    }

    var body: some View {
        ZStack {
            ImposterStyle.backgroundGradient.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    ImposterSheetHeader(title: "Spieler verwalten") {
                        dismiss()
                    }

                    ImposterSegmentedControl(
                        titles: ["Hinzufügen", "Gespeicherte"],
                        selectedIndex: $selectedTab
                    ) { index in
                        if index == 1 {
                            onRequestExpand?()
                        }
                    }

                    if selectedTab == 0 {
                        AddPlayersTab(
                            newPlayerName: $newPlayerName,
                            onAddPlayer: addPlayer
                        )
                        .environmentObject(gameSettings)
                    } else {
                        SavedPlayersTab(
                            selectedPlayers: $selectedPlayers,
                            onApplySelected: applySelectedPlayers,
                            onRequestExpand: onRequestExpand,
                            onSwitchBack: { selectedTab = 0 }
                        )
                        .environmentObject(gameSettings)
                    }
                }
                .padding(.horizontal, ImposterStyle.padding)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            loadCurrentPlayers()
        }
        .alert("Fehler", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }

    // MARK: - Helper Functions

    private func addPlayer() {
        let name = newPlayerName.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !name.isEmpty else {
            alertMessage = "Bitte geben Sie einen Namen ein."
            showingAlert = true
            return
        }

        if gameSettings.players.contains(where: { $0.name == name }) {
            alertMessage = "Ein Spieler mit diesem Namen ist bereits im Spiel."
            showingAlert = true
            return
        }

        gameSettings.addPlayer(name: name)

        if !gameSettings.savedPlayersManager.playerExists(name) {
            gameSettings.savedPlayersManager.addPlayer(name)
        }

        newPlayerName = ""
    }

    private func applySelectedPlayers() {
        gameSettings.players.removeAll()

        for playerName in selectedPlayers.sorted() {
            gameSettings.addPlayer(name: playerName)
        }
    }

    private func loadCurrentPlayers() {
        selectedPlayers = Set(gameSettings.players.map { $0.name })
    }
}

private struct ImposterCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 12) {
            content
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: ImposterStyle.containerCornerRadius, style: .continuous)
                .fill(ImposterStyle.containerBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: ImposterStyle.containerCornerRadius, style: .continuous)
                .stroke(ImposterStyle.cardStroke, lineWidth: 1)
        )
    }
}

private struct AddPlayersTab: View {
    @EnvironmentObject var gameSettings: GameSettings
    @Binding var newPlayerName: String
    let onAddPlayer: () -> Void
    @FocusState private var nameFieldFocused: Bool

    private var trimmedName: String {
        newPlayerName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canAddPlayer: Bool {
        !trimmedName.isEmpty
    }

    private var playerCount: Int {
        gameSettings.players.count
    }

    var body: some View {
        VStack(spacing: 16) {
            ImposterCard {
                HStack(spacing: 12) {
                    ImposterIconBadge(systemName: "person.badge.plus", tint: .orange)
                    Text("Spieler hinzufügen")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Spacer()
                }

                HStack(spacing: 12) {
                    TextField("Name eingeben", text: $newPlayerName)
                        .textFieldStyle(.plain)
                        .foregroundStyle(.white)
                        .disableAutocorrection(true)
                        .textInputAutocapitalization(.words)
                        .submitLabel(.done)
                        .focused($nameFieldFocused)
                        .onSubmit {
                            addAndRefocus()
                        }

                    Button(action: addAndRefocus) {
                        ImposterIconBadge(systemName: "plus", tint: .green)
                    }
                    .disabled(!canAddPlayer)
                    .opacity(canAddPlayer ? 1.0 : 0.5)
                }
                .imposterRowStyle()

                Text("Enter drücken oder + zum Hinzufügen")
                    .font(.caption)
                    .foregroundStyle(ImposterStyle.mutedText)
            }

            ImposterCard {
                HStack(spacing: 12) {
                    ImposterIconBadge(systemName: "person.3.fill", tint: .orange)
                    Text("Spieler im Spiel")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Spacer()
                    statusView
                }

                if gameSettings.players.isEmpty {
                    HStack(spacing: 12) {
                        ImposterIconBadge(systemName: "person.3.sequence", tint: .gray)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Noch keine Spieler hinzugefügt")
                                .font(.headline)
                                .foregroundStyle(.white)
                            Text("Mindestens 4 Spieler erforderlich")
                                .font(.caption)
                                .foregroundStyle(ImposterStyle.mutedText)
                        }
                        Spacer()
                    }
                    .imposterRowStyle()
                } else {
                    ForEach(Array(gameSettings.players.enumerated()), id: \.element.id) { index, player in
                        HStack(spacing: 12) {
                            Text("\(index + 1)")
                                .font(.headline)
                                .foregroundStyle(ImposterStyle.mutedText)
                                .frame(width: 24, alignment: .leading)
                            Text(player.name)
                                .font(.headline)
                                .foregroundStyle(.white)
                            Spacer()
                            Button {
                                gameSettings.removePlayer(at: index)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.red)
                                    .font(.headline)
                            }
                            .buttonStyle(.plain)
                        }
                        .imposterRowStyle()
                    }

                    if gameSettings.players.count > 1 {
                        Button {
                            gameSettings.players.removeAll()
                        } label: {
                            HStack(spacing: 12) {
                                ImposterIconBadge(systemName: "trash", tint: .red)
                                Text("Alle entfernen")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                Spacer()
                            }
                            .imposterRowStyle()
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var statusView: some View {
        if playerCount >= 4 {
            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text("Bereit")
                    .foregroundStyle(.green)
            }
            .font(.caption.weight(.semibold))
        } else {
            HStack(spacing: 4) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                Text("Noch \(max(0, 4 - playerCount)) benötigt")
                    .foregroundStyle(.orange)
            }
            .font(.caption.weight(.semibold))
        }
    }

    private func addAndRefocus() {
        onAddPlayer()
        DispatchQueue.main.async {
            nameFieldFocused = true
        }
    }
}

private struct SavedPlayersTab: View {
    @EnvironmentObject var gameSettings: GameSettings
    @Binding var selectedPlayers: Set<String>
    let onApplySelected: () -> Void
    let onRequestExpand: (() -> Void)?
    let onSwitchBack: () -> Void

    private var savedPlayers: [String] {
        gameSettings.savedPlayersManager.savedPlayerNames
    }

    private var applyTitle: String {
        selectedPlayers.isEmpty ? "Auswahl übernehmen" : "\(selectedPlayers.count) Spieler übernehmen"
    }

    var body: some View {
        VStack(spacing: 16) {
            ImposterCard {
                HStack(spacing: 12) {
                    ImposterIconBadge(systemName: "tray.full", tint: .orange)
                    Text("Gespeicherte Spieler")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Spacer()
                    Text("\(savedPlayers.count)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(ImposterStyle.mutedText)
                }

                if savedPlayers.isEmpty {
                    HStack(spacing: 12) {
                        ImposterIconBadge(systemName: "person.crop.circle.badge.xmark", tint: .gray)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Keine gespeicherten Spieler")
                                .font(.headline)
                                .foregroundStyle(.white)
                            Text("Füge zuerst Spieler hinzu.")
                                .font(.caption)
                                .foregroundStyle(ImposterStyle.mutedText)
                        }
                        Spacer()
                    }
                    .imposterRowStyle()
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(savedPlayers, id: \.self) { playerName in
                            SavedPlayerRow(
                                name: playerName,
                                isSelected: selectedPlayers.contains(playerName),
                                onToggle: { togglePlayerSelection(playerName) },
                                onDelete: { removePlayer(playerName) }
                            )
                        }
                    }
                }
            }

            ImposterPrimaryButton(
                title: applyTitle,
                action: {
                    onApplySelected()
                    onSwitchBack()
                },
                isDisabled: selectedPlayers.isEmpty
            )
        }
    }

    private func togglePlayerSelection(_ playerName: String) {
        if selectedPlayers.contains(playerName) {
            selectedPlayers.remove(playerName)
        } else {
            selectedPlayers.insert(playerName)
            onRequestExpand?()
        }
    }

    private func removePlayer(_ playerName: String) {
        withAnimation {
            selectedPlayers.remove(playerName)
            gameSettings.savedPlayersManager.removePlayer(playerName)
            gameSettings.objectWillChange.send()
        }
    }
}

private struct SavedPlayerRow: View {
    let name: String
    let isSelected: Bool
    let onToggle: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            ImposterIconBadge(systemName: "person.fill", tint: .orange)
            Text(name)
                .font(.headline)
                .foregroundStyle(.white)
                .lineLimit(1)

            Spacer()

            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.headline)
                .foregroundStyle(isSelected ? .green : .white.opacity(0.3))

            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.red)
                    .font(.headline)
            }
            .buttonStyle(.plain)
        }
        .imposterRowStyle()
        .contentShape(Rectangle())
        .onTapGesture {
            onToggle()
        }
    }
}

#Preview {
    let settings = GameSettings()
    settings.players = [
        Player(name: "Alice"),
        Player(name: "Bob")
    ]
    settings.savedPlayersManager.addPlayer("Max")
    settings.savedPlayersManager.addPlayer("Anna")

    return PlayerManagementSheet()
        .environmentObject(settings)
}
