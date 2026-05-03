import SwiftUI
import SFSafeSymbols

struct GroupSelectionView: View {
    @Environment(AppViewModel.self) private var appModel
    private let playerManager = GlobalPlayerManager.shared
    var onContinue: () -> Void

    // BB-08: State für Crew-Import Sheet
    @State private var showCrewImport = false

    private let selectableGroupCounts = [2, 3, 4]

    private var hasDuplicateNames: Bool {
        let names = appModel.activeGroups.map { $0.displayName.trimmingCharacters(in: .whitespaces).lowercased() }
        return names.count != Set(names).count
    }

    var body: some View {
        ZStack {
            BetBuddyBackgroundView(intensity: 0.4)

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    ScreenHeader(title: "Gruppen", showBack: true)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Wie viele Gruppen spielen?")
                            .font(.headline)
                            .foregroundStyle(BetBuddyTheme.textChampagne)

                        HStack(spacing: 10) {
                            ForEach(selectableGroupCounts, id: \.self) { count in
                                groupCountButton(
                                    count: count,
                                    isSelected: appModel.selectedGroupCount == count
                                )
                            }
                        }

                        Text("Jede Gruppe kann aus 2 bis 4 Spielern bestehen.")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(BetBuddyTheme.textSilver)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.black.opacity(0.28))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(BetBuddyTheme.accentGold.opacity(0.12), lineWidth: 1)
                            )
                    )

                    if !appModel.activeGroups.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(alignment: .center) {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("Teams einrichten")
                                        .foregroundStyle(.white)
                                        .font(.headline)

                                    Text("Namen optional, Spieleranzahl pro Team anpassbar")
                                        .foregroundStyle(BetBuddyTheme.textSilver)
                                        .font(.caption)
                                }

                                Spacer()

                                if !playerManager.players.isEmpty {
                                    Button {
                                        HapticsService.impact(.light)
                                        showCrewImport = true
                                    } label: {
                                        Label("Crew", systemSymbol: .person2Fill)
                                            .font(.caption.bold())
                                            .foregroundStyle(BetBuddyTheme.accentGold)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 7)
                                            .background(BetBuddyTheme.accentGold.opacity(0.15), in: Capsule())
                                    }
                                }
                            }

                            ForEach(appModel.activeGroups) { group in
                                TeamSetupCard(group: group) { newName in
                                    appModel.updateName(newName, for: group.color)
                                } onPlayersChange: { names in
                                    appModel.updatePlayerNames(names, for: group.color)
                                }
                            }
                        }
                    }

                    if hasDuplicateNames {
                        HStack(spacing: 8) {
                            Image(systemSymbol: .exclamationmarkTriangleFill)
                                .font(.caption.bold())
                                .foregroundStyle(BetBuddyTheme.accentGold)
                            Text("Zwei Gruppen haben denselben Namen")
                                .font(.caption.bold())
                                .foregroundStyle(BetBuddyTheme.accentGold)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(BetBuddyTheme.accentGold.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(BetBuddyTheme.accentGold.opacity(0.3), lineWidth: 1)
                                )
                        )
                        .transition(.opacity.combined(with: .move(edge: .top)))
                        .animation(.easeInOut(duration: 0.2), value: hasDuplicateNames)
                    }

                    Spacer(minLength: 10)

                    PrimaryButton(title: "Weiter") {
                        HapticsService.impact(.medium)
                        onContinue()
                    }
                }
                .padding(Theme.padding)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .toolbar(.hidden, for: .navigationBar)
        // BB-08: Crew-Import Sheet
        .sheet(isPresented: $showCrewImport) {
            CrewImportSheet(
                players: playerManager.players,
                groupCount: appModel.selectedGroupCount
            ) { selectedNames in
                for (index, name) in selectedNames.prefix(appModel.activeGroups.count).enumerated() {
                    let group = appModel.activeGroups[index]
                    appModel.updateName(name, for: group.color)
                }
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(28)
        }
    }

    private func groupCountButton(count: Int, isSelected: Bool) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                appModel.setGroupCount(count)
            }
            HapticsService.impact(.light)
        } label: {
            VStack(spacing: 6) {
                Text("\(count)")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                Text("Gruppen")
                    .font(.caption.weight(.bold))
            }
            .foregroundStyle(isSelected ? BetBuddyTheme.textOnLight : BetBuddyTheme.textChampagne)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? BetBuddyTheme.goldGradient : LinearGradient(colors: [Color.white.opacity(0.08), Color.white.opacity(0.04)], startPoint: .top, endPoint: .bottom))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color.white.opacity(0.35) : BetBuddyTheme.accentGold.opacity(0.14), lineWidth: 1)
            )
        }
    }
}

private struct TeamSetupCard: View {
    let group: GroupInfo
    let onNameChange: (String) -> Void
    let onPlayersChange: ([String]) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(group.color.gradient)
                    .frame(width: 5, height: 38)

                VStack(alignment: .leading, spacing: 2) {
                    Text(group.displayName)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(BetBuddyTheme.textChampagne)
                        .lineLimit(1)

                    Text("\(group.playerSlotCount) Spieler")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(group.color.accent)
                }

                Spacer()

                Image(systemSymbol: .person3Fill)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(group.color.primary)
            }

            GroupNameField(group: group, onChange: onNameChange)

            PlayerNamesSection(group: group, onChange: onPlayersChange)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.32))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(group.color.primary.opacity(0.18), lineWidth: 1)
                )
        )
    }
}

// MARK: - Spielernamen Section
private struct PlayerNamesSection: View {
    let group: GroupInfo
    let onChange: ([String]) -> Void

    @State private var players: [String] = []
    @FocusState private var focusedField: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Spieler")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(BetBuddyTheme.textChampagne)

                Spacer()

                if players.count < GroupInfo.maxPlayerCount {
                    Button {
                        HapticsService.impact(.light)
                        players.append("")
                        onChange(players)
                    } label: {
                        Label("Hinzufügen", systemSymbol: .plusCircleFill)
                            .font(.caption.bold())
                            .foregroundStyle(group.color.accent)
                    }
                }
            }

            VStack(spacing: 8) {
                ForEach(players.indices, id: \.self) { index in
                    playerField(index: index)
                }
            }
        }
        .onAppear(perform: syncPlayers)
        .onChange(of: group.playerNames) { _, _ in syncPlayers() }
    }

    private func playerField(index: Int) -> some View {
        HStack(spacing: 8) {
            Text("\(index + 1)")
                .font(.caption.bold())
                .foregroundStyle(group.color.accent)
                .frame(width: 26, height: 26)
                .background(group.color.primary.opacity(0.12), in: Circle())

            TextField("Spieler \(index + 1)", text: binding(for: index))
                .textInputAutocapitalization(.words)
                .disableAutocorrection(true)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(BetBuddyTheme.textChampagne)
                .focused($focusedField, equals: index)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.black.opacity(0.28))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(
                                    focusedField == index
                                        ? group.color.primary.opacity(0.55)
                                        : Color.white.opacity(0.08),
                                    lineWidth: focusedField == index ? 1.5 : 1
                                )
                        )
                )

            if players.count > GroupInfo.minPlayerCount {
                Button {
                    HapticsService.impact(.light)
                    players.remove(at: index)
                    onChange(players)
                } label: {
                    Image(systemSymbol: .minusCircleFill)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(BetBuddyTheme.textSilver.opacity(0.75))
                        .frame(width: 30, height: 30)
                }
            }
        }
    }

    private func binding(for index: Int) -> Binding<String> {
        Binding {
            players.indices.contains(index) ? players[index] : ""
        } set: { newValue in
            guard players.indices.contains(index) else { return }
            players[index] = newValue
            onChange(players)
        }
    }

    private func syncPlayers() {
        let existing = group.playerNames.map { $0 ?? "" }
        players = Array(existing.prefix(GroupInfo.maxPlayerCount))
        while players.count < GroupInfo.minPlayerCount {
            players.append("")
        }
    }
}

// MARK: - Crew Import Sheet (BB-08)
private struct CrewImportSheet: View {
    let players: [GlobalPlayer]
    let groupCount: Int
    let onImport: ([String]) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selected: [String] = []

    var body: some View {
        ZStack {
            BetBuddyBackgroundView(intensity: 0.5)

            VStack(spacing: 0) {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemSymbol: .xmark)
                            .font(.headline.bold())
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                    }
                    Spacer()
                    Text("Crew laden")
                        .font(.headline.bold())
                        .foregroundStyle(.white)
                    Spacer()
                    Color.clear.frame(width: 44, height: 44)
                }
                .padding(.horizontal)
                .padding(.top, 20)

                Text("Wähle bis zu \(groupCount) Spieler als Gruppenname")
                    .font(.subheadline)
                    .foregroundStyle(BetBuddyTheme.textSilver)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
                    .padding(.horizontal)

                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(players) { player in
                            let isSelected = selected.contains(player.name)
                            Button {
                                HapticsService.impact(.light)
                                if isSelected {
                                    selected.removeAll { $0 == player.name }
                                } else if selected.count < groupCount {
                                    selected.append(player.name)
                                }
                            } label: {
                                HStack {
                                    Text(player.name)
                                        .font(.body.weight(.semibold))
                                        .foregroundStyle(.white)
                                    Spacer()
                                    if isSelected {
                                        Image(systemSymbol: .checkmarkCircleFill)
                                            .foregroundStyle(BetBuddyTheme.accentGold)
                                    } else {
                                        Image(systemSymbol: .circle)
                                            .foregroundStyle(BetBuddyTheme.textSilver)
                                    }
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(isSelected ? BetBuddyTheme.accentGold.opacity(0.15) : Color.white.opacity(0.06))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(isSelected ? BetBuddyTheme.accentGold.opacity(0.4) : Color.clear, lineWidth: 1)
                                )
                            }
                        }
                    }
                    .padding()
                }

                Button {
                    onImport(selected)
                    dismiss()
                } label: {
                    Text(selected.isEmpty ? "Auswählen" : "\(selected.count) übernehmen")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(selected.isEmpty ? BetBuddyTheme.textSilver : .black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(selected.isEmpty ? Color.white.opacity(0.1) : BetBuddyTheme.accentGold)
                        .clipShape(Capsule())
                }
                .disabled(selected.isEmpty)
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
        }
    }
}
