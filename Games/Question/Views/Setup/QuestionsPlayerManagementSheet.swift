import SwiftUI

struct QuestionsPlayerManagementSheet: View {
    @ObservedObject var appModel: AppModel
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var playerManager = GlobalPlayerManager.shared

    @State private var newPlayerName = ""
    @FocusState private var isInputFocused: Bool
    @State private var showCrewPlayers = false

    private let accent = QuestionsTheme.accentGreen

    private var trimmed: String {
        newPlayerName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canAdd: Bool {
        !trimmed.isEmpty && !appModel.players.contains(where: { $0.name == trimmed })
    }

    private var crewNotSelected: [GlobalPlayer] {
        playerManager.players.filter { crew in
            !appModel.players.contains(where: { $0.name == crew.name })
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                QuestionsStyle.backgroundGradient.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        newPlayerSection
                        if !appModel.players.isEmpty {
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
            sectionLabel("AUSGEWÄHLT (\(appModel.players.count))", color: accent)

            VStack(spacing: 8) {
                ForEach(appModel.players) { player in
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
                                appModel.players.removeAll { $0.id == player.id }
                            }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(QuestionsStyle.mutedText)
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
                                appModel.players.append(QuestionPlayer(name: player.name))
                            }
                        } label: {
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(Color.white.opacity(0.06))
                                        .frame(width: 38, height: 38)
                                    Text(String(player.name.prefix(1)).uppercased())
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundStyle(QuestionsStyle.mutedText)
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

    private func sectionLabel(_ text: String, color: Color = QuestionsStyle.mutedText) -> some View {
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
            appModel.players.append(QuestionPlayer(name: trimmed))
        }
        GlobalPlayerManager.shared.addPlayer(name: trimmed)
        newPlayerName = ""
        isInputFocused = true
    }
}
