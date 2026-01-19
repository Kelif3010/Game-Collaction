import SwiftUI

struct QuestionsPlayerManagementSheet: View {
    @ObservedObject var appModel: AppModel
    @Environment(\.dismiss) var dismiss
    @AppStorage("myPlayerName") private var myPlayerName = ""
    @State private var newPlayerName = ""
    @FocusState private var isInputFocused: Bool
    private let minimumPlayers = 3

    private var playerCount: Int { appModel.players.count }
    private var isReadyToPlay: Bool { playerCount >= minimumPlayers }
    private var missingPlayers: Int { max(0, minimumPlayers - playerCount) }
    private var trimmedNewPlayerName: String {
        newPlayerName.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    private var canAddPlayer: Bool { !trimmedNewPlayerName.isEmpty }

    var body: some View {
        ZStack {
            QuestionsStyle.backgroundGradient.ignoresSafeArea()
            
            VStack(spacing: 0) {
                QuestionsSheetHeader(title: "Spieler verwalten") {
                    dismiss()
                }
                .padding(.horizontal, QuestionsStyle.padding)
                
                ScrollView {
                    VStack(spacing: 16) {
                        QuestionsDeckStatusCard(
                            playerCount: playerCount,
                            minimumPlayers: minimumPlayers,
                            isReady: isReadyToPlay,
                            missingPlayers: missingPlayers
                        )
                        
                        QuestionsAddPlayerCard(
                            newPlayerName: $newPlayerName,
                            isInputFocused: $isInputFocused,
                            canAddPlayer: canAddPlayer,
                            onSubmit: addPlayer
                        )
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("\(playerCount) Spieler")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(QuestionsStyle.mutedText)
                            
                            LazyVStack(spacing: 12) {
                                if appModel.players.isEmpty {
                                    QuestionsEmptyDeckCard()
                                } else {
                                    ForEach(Array(appModel.players.enumerated()), id: \.element.id) { index, player in
                                        QuestionsPlayerDeckCard(
                                            player: player,
                                            index: index,
                                            canMoveUp: index > 0,
                                            canMoveDown: index < appModel.players.count - 1,
                                            onMoveUp: { movePlayerUp(from: index) },
                                            onMoveDown: { movePlayerDown(from: index) },
                                            onRemove: { removePlayer(player) }
                                        )
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, QuestionsStyle.padding)
                    .padding(.bottom, 24)
                }
            }
        }
        .onAppear {
            if !myPlayerName.isEmpty {
                // Automatisch hinzufügen, wenn noch nicht vorhanden
                if !appModel.players.contains(where: { $0.name == myPlayerName }) {
                    appModel.players.append(Player(name: myPlayerName))
                }
            }
        }
    }
    
    private func addPlayer() {
        guard canAddPlayer else { return }
        let name = trimmedNewPlayerName
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            _ = appModel.players.append(Player(name: name))
        }
        newPlayerName = ""
        isInputFocused = true
    }
    
    private func removePlayer(_ player: Player) {
        guard let index = appModel.players.firstIndex(where: { $0.id == player.id }) else { return }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            _ = appModel.players.remove(at: index)
        }
    }
    
    private func movePlayerUp(from index: Int) {
        guard index > 0 else { return }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            _ = appModel.players.swapAt(index, index - 1)
        }
    }
    
    private func movePlayerDown(from index: Int) {
        guard index < appModel.players.count - 1 else { return }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            _ = appModel.players.swapAt(index, index + 1)
        }
    }
}

private struct QuestionsDeckStatusCard: View {
    let playerCount: Int
    let minimumPlayers: Int
    let isReady: Bool
    let missingPlayers: Int
    
    private var progress: Double {
        guard minimumPlayers > 0 else { return 1 }
        return min(1, Double(playerCount) / Double(minimumPlayers))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("\(playerCount)")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(.white)
                Text("Spieler")
                    .font(.headline)
                    .foregroundStyle(QuestionsStyle.mutedText)
                Spacer()
                Text(isReady ? "Bereit" : "In Vorbereitung")
                    .font(.footnote.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(isReady ? Color.green.opacity(0.25) : Color.white.opacity(0.08))
                    )
                    .foregroundStyle(isReady ? Color.green : QuestionsStyle.mutedText)
            }
            
            Text(isReady ? "Reihenfolge festlegen und starten." : "Noch \(missingPlayers) Spieler benoetigt.")
                .font(.callout)
                .foregroundStyle(.white.opacity(0.9))
            
            ProgressView(value: progress)
                .tint(Color.white.opacity(0.85))
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: QuestionsStyle.containerCornerRadius, style: .continuous)
                .fill(QuestionsStyle.containerBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: QuestionsStyle.containerCornerRadius, style: .continuous)
                        .fill(QuestionsStyle.primaryGradient.opacity(0.18))
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: QuestionsStyle.containerCornerRadius, style: .continuous)
                .stroke(QuestionsStyle.cardStroke, lineWidth: 1)
        )
    }
}

private struct QuestionsAddPlayerCard: View {
    @Binding var newPlayerName: String
    var isInputFocused: FocusState<Bool>.Binding
    let canAddPlayer: Bool
    let onSubmit: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.badge.plus")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(QuestionsStyle.primaryGradient)
                )
            
            TextField("Neuer Spieler...", text: $newPlayerName)
                .textFieldStyle(.plain)
                .font(.body)
                .foregroundStyle(.white)
                .submitLabel(.done)
                .focused(isInputFocused)
                .onSubmit(onSubmit)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.words)
            
            Button(action: onSubmit) {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(QuestionsStyle.buttonGradient)
                    )
            }
            .buttonStyle(.plain)
            .disabled(!canAddPlayer)
            .opacity(canAddPlayer ? 1 : 0.4)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: QuestionsStyle.containerCornerRadius, style: .continuous)
                .fill(QuestionsStyle.containerBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: QuestionsStyle.containerCornerRadius, style: .continuous)
                .stroke(QuestionsStyle.cardStroke, lineWidth: 1)
        )
    }
}

private struct QuestionsPlayerDeckCard: View {
    let player: Player
    let index: Int
    let canMoveUp: Bool
    let canMoveDown: Bool
    let onMoveUp: () -> Void
    let onMoveDown: () -> Void
    let onRemove: () -> Void
    
    private var initials: String {
        let parts = player.name.split(whereSeparator: { $0 == " " || $0 == "-" })
        let letters = parts.prefix(2).compactMap { $0.first }
        let initials = String(letters)
        return initials.isEmpty ? "?" : initials.uppercased()
    }
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(QuestionsStyle.primaryGradient)
                Text(initials)
                    .font(.headline.bold())
                    .foregroundStyle(.white)
            }
            .frame(width: 44, height: 44)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(player.name)
                    .font(.headline)
                    .foregroundStyle(.white)
                Text("Platz \(index + 1)")
                    .font(.caption)
                    .foregroundStyle(QuestionsStyle.mutedText)
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                Menu {
                    Button("Nach oben", action: onMoveUp)
                        .disabled(!canMoveUp)
                    Button("Nach unten", action: onMoveDown)
                        .disabled(!canMoveDown)
                } label: {
                    Image(systemName: "line.3.horizontal.decrease")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
                
                Button(action: onRemove) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: QuestionsStyle.rowCornerRadius, style: .continuous)
                .fill(QuestionsStyle.rowBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: QuestionsStyle.rowCornerRadius, style: .continuous)
                        .fill(Color.white.opacity(0.02))
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: QuestionsStyle.rowCornerRadius, style: .continuous)
                .stroke(QuestionsStyle.cardStroke, lineWidth: 1)
        )
        .contextMenu {
            Button("Nach oben", action: onMoveUp)
                .disabled(!canMoveUp)
            Button("Nach unten", action: onMoveDown)
                .disabled(!canMoveDown)
            Button("Entfernen", role: .destructive, action: onRemove)
        }
    }
}

private struct QuestionsEmptyDeckCard: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "person.3.fill")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(QuestionsStyle.mutedText)
            Text("Keine Spieler hinzugefuegt.")
                .font(.callout)
                .foregroundStyle(QuestionsStyle.mutedText)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: QuestionsStyle.rowCornerRadius, style: .continuous)
                .fill(QuestionsStyle.rowBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: QuestionsStyle.rowCornerRadius, style: .continuous)
                .stroke(QuestionsStyle.cardStroke, lineWidth: 1)
        )
    }
}
