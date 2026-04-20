import SwiftUI

struct GroupSelectionView: View {
    @EnvironmentObject private var appModel: AppViewModel
    @ObservedObject private var playerManager = GlobalPlayerManager.shared
    var onContinue: () -> Void

    // BB-08: State für Crew-Import Sheet
    @State private var showCrewImport = false

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

                    // BB-07: Alle 8 GroupColors unterstützt
                    VStack(spacing: 12) {
                        ForEach(2...GroupColor.allCases.count, id: \.self) { count in
                            GroupCountRow(
                                count: count,
                                isSelected: appModel.selectedGroupCount == count,
                                action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        appModel.setGroupCount(count)
                                    }
                                    HapticsService.impact(.light)
                                }
                            )
                        }
                    }

                    if !appModel.activeGroups.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Gruppennamen")
                                    .foregroundStyle(.white)
                                    .font(.headline)

                                Spacer()

                                // BB-08: Aus Crew laden Button
                                if !playerManager.players.isEmpty {
                                    Button {
                                        HapticsService.impact(.light)
                                        showCrewImport = true
                                    } label: {
                                        HStack(spacing: 6) {
                                            Image(systemName: "person.2.fill")
                                                .font(.caption.bold())
                                            Text("Crew laden")
                                                .font(.caption.bold())
                                        }
                                        .foregroundStyle(BetBuddyTheme.accentGold)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(BetBuddyTheme.accentGold.opacity(0.15))
                                        .clipShape(Capsule())
                                    }
                                }
                            }

                            ForEach(appModel.activeGroups) { group in
                                VStack(spacing: 8) {
                                    GroupNameField(group: group) { newName in
                                        appModel.updateName(newName, for: group.color)
                                    }
                                    PlayerNamesSection(group: group) { p1, p2 in
                                        appModel.updatePlayerNames(player1: p1, player2: p2, for: group.color)
                                    }
                                }
                            }
                        }
                        .padding(.top, 4)
                    }

                    if hasDuplicateNames {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
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
}

// MARK: - Spielernamen Section
private struct PlayerNamesSection: View {
    let group: GroupInfo
    let onChange: (String, String) -> Void

    @State private var player1: String = ""
    @State private var player2: String = ""
    @FocusState private var focusedField: Int?

    var body: some View {
        VStack(spacing: 6) {
            playerField(
                placeholder: "Spieler 1",
                text: $player1,
                tag: 1
            )
            playerField(
                placeholder: "Spieler 2",
                text: $player2,
                tag: 2
            )
        }
        .padding(.leading, 20)
        .onAppear {
            player1 = group.player1Name ?? ""
            player2 = group.player2Name ?? ""
        }
        .onChange(of: group.player1Name) { _, v in player1 = v ?? "" }
        .onChange(of: group.player2Name) { _, v in player2 = v ?? "" }
    }

    private func playerField(placeholder: String, text: Binding<String>, tag: Int) -> some View {
        HStack(spacing: 8) {
            // Verbindungslinie zum Team
            RoundedRectangle(cornerRadius: 1)
                .fill(group.color.primary.opacity(0.3))
                .frame(width: 2, height: 36)

            TextField(placeholder, text: text)
                .textInputAutocapitalization(.words)
                .disableAutocorrection(true)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(BetBuddyTheme.textChampagne)
                .focused($focusedField, equals: tag)
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.black.opacity(0.3))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(
                                    focusedField == tag
                                        ? group.color.primary.opacity(0.5)
                                        : group.color.primary.opacity(0.08),
                                    lineWidth: focusedField == tag ? 1.5 : 1
                                )
                        )
                )
                .onChange(of: text.wrappedValue) { _, _ in
                    onChange(player1, player2)
                }
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
                        Image(systemName: "xmark")
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
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(BetBuddyTheme.accentGold)
                                    } else {
                                        Image(systemName: "circle")
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
