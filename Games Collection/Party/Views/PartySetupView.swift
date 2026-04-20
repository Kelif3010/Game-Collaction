import SwiftUI

struct PartySetupView: View {
    var manager: PartySessionManager
    @Environment(\.dismiss) var dismiss

    @StateObject private var playerManager = GlobalPlayerManager.shared

    // Auswahl-State
    @State private var selectedPlayerIDs: Set<UUID> = []
    @State private var customPlayers: [PartyPlayer]  = []
    @State private var selectedGames: [PartyGame]    = []   // Reihenfolge = Tap-Reihenfolge

    // Sheet zum Manuell-Hinzufügen
    @State private var showAddPlayer = false

    // Computed
    private var allPlayers: [PartyPlayer] {
        let crew = playerManager.players.map {
            PartyPlayer(id: $0.id, name: $0.name)
        }
        return crew + customPlayers
    }

    private var chosenPlayers: [PartyPlayer] {
        allPlayers.filter { selectedPlayerIDs.contains($0.id) }
    }

    private var minPlayersRequired: Int {
        selectedGames.map(\.minPlayers).max() ?? 2
    }

    private var canStart: Bool {
        chosenPlayers.count >= minPlayersRequired && selectedGames.count >= 2
    }

    private var validationHint: String? {
        guard !canStart else { return nil }
        let missingPlayers = max(0, minPlayersRequired - chosenPlayers.count)
        let missingGames   = max(0, 2 - selectedGames.count)

        if missingGames > 0 && missingPlayers > 0 {
            return "Noch \(missingGames) Spiel\(missingGames == 1 ? "" : "e") und \(missingPlayers) Spieler auswählen"
        } else if missingGames > 0 {
            return "Noch \(missingGames) Spiel\(missingGames == 1 ? "" : "e") auswählen"
        } else if missingPlayers > 0 {
            if let demanding = selectedGames.max(by: { $0.minPlayers < $1.minPlayers }),
               demanding.minPlayers > chosenPlayers.count {
                return "\(demanding.displayName) braucht mind. \(demanding.minPlayers) Spieler"
            }
            return "Noch \(missingPlayers) Spieler auswählen"
        }
        return nil
    }

    var body: some View {
        ZStack {
            // Hintergrund
            LinearGradient(
                colors: [.black, Color.indigo.opacity(0.55), Color.purple.opacity(0.4)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {

                    // ── Header ─────────────────────────────────────────
                    header

                    // ── Spieler ────────────────────────────────────────
                    playerSection

                    // ── Spiele ─────────────────────────────────────────
                    gameSection

                    // ── Start ──────────────────────────────────────────
                    startButton

                    Spacer(minLength: 40)
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }
        }
        .sheet(isPresented: $showAddPlayer) {
            AddPartyPlayerSheet { name, addToCrew in
                if addToCrew {
                    // Dauerhaft in GlobalPlayerManager speichern (iCloud-Sync)
                    playerManager.addPlayer(name: name)
                    // Spieler finden und selektieren (funktioniert auch bei Duplikaten)
                    if let existing = playerManager.players.first(where: {
                        $0.name.lowercased() == name.lowercased()
                    }) {
                        selectedPlayerIDs.insert(existing.id)
                    }
                } else {
                    // Nur für diese Party – temporär
                    let p = PartyPlayer(name: name)
                    customPlayers.append(p)
                    selectedPlayerIDs.insert(p.id)
                }
            }
            .presentationDetents([.height(370)])
            .presentationCornerRadius(28)
            .presentationBackground(.ultraThinMaterial)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.6))
                    .frame(width: 36, height: 36)
                    .background(.white.opacity(0.08), in: Circle())
            }

            Spacer()

            VStack(spacing: 3) {
                Text("Party starten")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("Mehrere Spiele · Gesamtwertung")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.45))
            }

            Spacer()

            // Balance für Symmetrie
            Color.clear.frame(width: 36, height: 36)
        }
        .padding(.top, 8)
    }

    // MARK: - Spieler Section

    private var playerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SetupSectionLabel(
                title: "Spieler",
                badge: chosenPlayers.count >= 2 ? "\(chosenPlayers.count) ausgewählt" : "mind. 2"
            )

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(allPlayers) { player in
                        let isSelected = selectedPlayerIDs.contains(player.id)
                        Button {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                                if isSelected {
                                    selectedPlayerIDs.remove(player.id)
                                } else {
                                    selectedPlayerIDs.insert(player.id)
                                }
                            }
                        } label: {
                            PartyPlayerChip(player: player, isSelected: isSelected)
                        }
                    }

                    // Hinzufügen-Button
                    Button { showAddPlayer = true } label: {
                        VStack(spacing: 7) {
                            ZStack {
                                Circle()
                                    .fill(.white.opacity(0.06))
                                    .frame(width: 58, height: 58)
                                    .overlay(
                                        Circle()
                                            .strokeBorder(
                                                style: StrokeStyle(lineWidth: 1.5, dash: [4, 3])
                                            )
                                            .foregroundStyle(.white.opacity(0.2))
                                    )
                                Image(systemName: "plus")
                                    .font(.system(size: 20, weight: .light))
                                    .foregroundStyle(.white.opacity(0.4))
                            }
                            Text("Neu")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(.white.opacity(0.3))
                        }
                    }
                }
                .padding(.horizontal, 2)
                .padding(.vertical, 4)
            }
        }
    }

    // MARK: - Spiele Section

    private var gameSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SetupSectionLabel(
                title: "Spiele",
                badge: selectedGames.count >= 2
                    ? "\(selectedGames.count) Spiele"
                    : "mind. 2 wählen"
            )

            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                spacing: 12
            ) {
                ForEach(PartyGame.allCases) { game in
                    let order = selectedGames.firstIndex(of: game).map { $0 + 1 }
                    let isSelected = order != nil

                    Button {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                            if isSelected {
                                selectedGames.removeAll { $0 == game }
                            } else {
                                selectedGames.append(game)
                            }
                        }
                    } label: {
                        PartyGameSelectionCard(game: game, order: order, isSelected: isSelected)
                    }
                }
            }

            if selectedGames.count >= 2 {
                reorderSection
                    .padding(.top, 4)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
    }

    // MARK: - Reorder Section

    private var reorderSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.35))
                Text("Reihenfolge per Drag anpassen")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.35))
            }

            List {
                ForEach(selectedGames, id: \.self) { game in
                    HStack(spacing: 12) {
                        // Reihenfolge-Badge
                        if let idx = selectedGames.firstIndex(of: game) {
                            Text("\(idx + 1)")
                                .font(.system(size: 11, weight: .black))
                                .foregroundStyle(.black)
                                .frame(width: 20, height: 20)
                                .background(
                                    Color(red: 1.0, green: 0.83, blue: 0.15),
                                    in: Circle()
                                )
                        }

                        // Spiel-Icon
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(game.gradient)
                                .frame(width: 32, height: 32)
                            Image(systemName: game.icon)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.white)
                        }

                        // Spiel-Name
                        Text(game.displayName)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)

                        Spacer()
                    }
                    .padding(.vertical, 5)
                    .listRowBackground(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.white.opacity(0.07))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(.white.opacity(0.08), lineWidth: 1)
                            )
                            .padding(.vertical, 3)
                    )
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 3, leading: 0, bottom: 3, trailing: 0))
                }
                .onMove { from, to in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        selectedGames.move(fromOffsets: from, toOffset: to)
                    }
                }
            }
            .listStyle(.plain)
            .scrollDisabled(true)
            .scrollContentBackground(.hidden)
            .environment(\.editMode, .constant(.active))
            .frame(height: CGFloat(selectedGames.count) * 54)
        }
    }

    // MARK: - Start Button

    private var startButton: some View {
        VStack(spacing: 8) {
            Button {
                manager.startSession(players: chosenPlayers, games: selectedGames)
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.black.opacity(0.7))

                    Text(canStart
                         ? "Los geht's · \(selectedGames.count) Spiele · \(chosenPlayers.count) Spieler"
                         : "Spieler & Spiele auswählen")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(canStart ? .black : .white.opacity(0.3))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    canStart
                    ? AnyShapeStyle(LinearGradient(
                        colors: [
                            Color(red: 1.0, green: 0.83, blue: 0.15),
                            Color(red: 1.0, green: 0.65, blue: 0.05)
                        ],
                        startPoint: .leading, endPoint: .trailing
                    ))
                    : AnyShapeStyle(Color.white.opacity(0.06)),
                    in: RoundedRectangle(cornerRadius: 18)
                )
            }
            .disabled(!canStart)

            if let hint = validationHint {
                Text(hint)
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.38))
                    .multilineTextAlignment(.center)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: canStart)
        .animation(.easeInOut(duration: 0.2), value: validationHint)
    }
}

// MARK: - Subcomponents

private struct SetupSectionLabel: View {
    let title: String
    let badge: String

    var body: some View {
        HStack(spacing: 8) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .tracking(1.5)
                .foregroundStyle(.white.opacity(0.4))

            Text(badge)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white.opacity(0.6))
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(.white.opacity(0.08), in: Capsule())
        }
    }
}

private struct PartyPlayerChip: View {
    let player: PartyPlayer
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 7) {
            ZStack {
                Circle()
                    .fill(player.avatarGradient)
                    .frame(width: 58, height: 58)
                    .shadow(
                        color: isSelected ? .white.opacity(0.2) : .clear,
                        radius: 6
                    )
                    .overlay(
                        Circle()
                            .strokeBorder(
                                isSelected
                                ? Color(red: 1.0, green: 0.83, blue: 0.15)
                                : Color.clear,
                                lineWidth: 2.5
                            )
                    )

                Text(player.initial)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                if isSelected {
                    Circle()
                        .fill(Color(red: 1.0, green: 0.83, blue: 0.15))
                        .frame(width: 18, height: 18)
                        .overlay(
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .black))
                                .foregroundStyle(.black)
                        )
                        .offset(x: 19, y: -19)
                        .transition(.scale.combined(with: .opacity))
                }
            }

            Text(player.name)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(isSelected ? .white : .white.opacity(0.55))
                .lineLimit(1)
                .frame(width: 62)
        }
    }
}

private struct PartyGameSelectionCard: View {
    let game: PartyGame
    let order: Int?
    let isSelected: Bool

    var body: some View {
        ZStack(alignment: .topTrailing) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(game.gradient)
                        .frame(width: 40, height: 40)
                    Image(systemName: game.icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                }

                Text(game.displayName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(isSelected ? .white : .white.opacity(0.55))
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? .white.opacity(0.1) : .white.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(
                                isSelected
                                ? Color(red: 1.0, green: 0.83, blue: 0.15).opacity(0.6)
                                : Color.white.opacity(0.07),
                                lineWidth: 1.5
                            )
                    )
            )

            // Reihenfolge-Badge
            if let order {
                Text("\(order)")
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(.black)
                    .frame(width: 20, height: 20)
                    .background(
                        Color(red: 1.0, green: 0.83, blue: 0.15),
                        in: Circle()
                    )
                    .offset(x: 8, y: -8)
                    .transition(.scale.combined(with: .opacity))
            }
        }
    }
}

// MARK: - Add Player Sheet

private struct AddPartyPlayerSheet: View {
    /// name, addToCrew
    let onAdd: (String, Bool) -> Void
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @FocusState private var focused: Bool

    private var trimmed: String { name.trimmingCharacters(in: .whitespaces) }
    private var isValid: Bool  { !trimmed.isEmpty }

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(.white.opacity(0.2))
                .frame(width: 36, height: 4)
                .padding(.top, 14)
                .padding(.bottom, 22)

            VStack(spacing: 5) {
                Text("Spieler hinzufügen")
                    .font(.system(size: 21, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("Wer spielt noch mit?")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.45))
            }
            .padding(.bottom, 22)

            // Name-Eingabe
            TextField("Name...", text: $name)
                .font(.system(size: 19, weight: .medium, design: .rounded))
                .foregroundStyle(.white)
                .tint(.cyan)
                .focused($focused)
                .submitLabel(.done)
                .onSubmit { confirm(addToCrew: false) }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(.white.opacity(0.12), lineWidth: 1)
                )
                .padding(.horizontal, 24)

            // Buttons
            VStack(spacing: 10) {
                // Primär: dauerhaft zur Crew
                Button { confirm(addToCrew: true) } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Zur Crew hinzufügen")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(isValid ? .black : .white.opacity(0.25))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        isValid
                        ? AnyShapeStyle(LinearGradient(
                            colors: [Color(red: 1.0, green: 0.83, blue: 0.15),
                                     Color(red: 1.0, green: 0.65, blue: 0.05)],
                            startPoint: .leading, endPoint: .trailing
                        ))
                        : AnyShapeStyle(Color.white.opacity(0.06)),
                        in: RoundedRectangle(cornerRadius: 14)
                    )
                }
                .disabled(!isValid)

                // Sekundär: nur für diese Party
                Button { confirm(addToCrew: false) } label: {
                    Text("Nur für diese Party")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(isValid ? .white.opacity(0.55) : .white.opacity(0.2))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(.white.opacity(0.1), lineWidth: 1)
                        )
                }
                .disabled(!isValid)
            }
            .animation(.easeInOut(duration: 0.15), value: isValid)
            .padding(.horizontal, 24)
            .padding(.top, 14)

            Spacer()
        }
        .onAppear { focused = true }
    }

    private func confirm(addToCrew: Bool) {
        guard isValid else { return }
        onAdd(trimmed, addToCrew)
        dismiss()
    }
}
