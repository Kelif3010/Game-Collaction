import SwiftUI
import Combine
#if canImport(UIKit)
import UIKit
#endif

struct PlayerManagementSheet: View {
    @EnvironmentObject var gameSettings: GameSettings
    @Environment(\.dismiss) private var dismiss

    @AppStorage("myPlayerName") private var myPlayerName = ""
    @State private var newPlayerName = ""
    @FocusState private var isInputFocused: Bool
    
    // Combined list of all known players (Saved + Global) excluding those already in game
    private var availablePlayers: [String] {
        let activeNames = Set(gameSettings.players.map { $0.name })
        let savedNames = Set(gameSettings.savedPlayersManager.savedPlayerNames)
        let globalNames = Set(GlobalPlayerManager.shared.getAllNames())
        
        let allCandidates = savedNames.union(globalNames)
        return allCandidates.subtracting(activeNames).sorted()
    }

    var body: some View {
        ZStack {
            ImposterStyle.backgroundGradient.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                ImposterSheetHeader(title: "The Draft Room") {
                    dismiss()
                }
                .padding(.horizontal, ImposterStyle.padding)
                .padding(.top, 16)
                .padding(.bottom, 20)

                ScrollView {
                    VStack(spacing: 24) {
                        
                        // 1. ACTIVE SQUAD (Roster)
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Aktives Squad")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                Spacer()
                                Text("\(gameSettings.players.count)")
                                    .font(.caption.weight(.bold))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Capsule().fill(ImposterStyle.primaryGradient))
                                    .foregroundStyle(.black)
                            }
                            .padding(.horizontal, ImposterStyle.padding)

                            if gameSettings.players.isEmpty {
                                EmptySquadPlaceholder()
                                    .padding(.horizontal, ImposterStyle.padding)
                            } else {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 16) {
                                        ForEach(gameSettings.players) { player in
                                            SquadAvatar(name: player.name) {
                                                removePlayer(player)
                                            }
                                        }
                                    }
                                    .padding(.horizontal, ImposterStyle.padding)
                                    .padding(.vertical, 8) // Space for shadow/scale
                                }
                            }
                        }

                        // 2. SMART INPUT
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Neuer Rekrut")
                                .font(.subheadline)
                                .foregroundStyle(ImposterStyle.mutedText)
                                .padding(.horizontal, ImposterStyle.padding)

                            HStack(spacing: 12) {
                                TextField("Namen eingeben...", text: $newPlayerName)
                                    .textFieldStyle(.plain)
                                    .font(.body)
                                    .foregroundStyle(.white)
                                    .padding(16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(ImposterStyle.containerBackground)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(ImposterStyle.cardStroke, lineWidth: 1)
                                            )
                                    )
                                    .submitLabel(.done)
                                    .focused($isInputFocused)
                                    .onSubmit {
                                        addNewPlayer()
                                    }

                                Button(action: addNewPlayer) {
                                    Image(systemName: "plus")
                                        .font(.title3.bold())
                                        .foregroundStyle(.black)
                                        .frame(width: 52, height: 52)
                                        .background(
                                            Circle()
                                                .fill(newPlayerName.trimmingCharacters(in: .whitespaces).isEmpty ? AnyShapeStyle(Color.gray) : AnyShapeStyle(ImposterStyle.primaryGradient))
                                        )
                                }
                                .disabled(newPlayerName.trimmingCharacters(in: .whitespaces).isEmpty)
                            }
                            .padding(.horizontal, ImposterStyle.padding)
                        }

                        // 3. THE BANK (Quick Pick)
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Die Bank")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                Spacer()
                                if !availablePlayers.isEmpty {
                                    Image(systemName: "archivebox.fill")
                                        .foregroundStyle(ImposterStyle.mutedText)
                                }
                            }
                            .padding(.horizontal, ImposterStyle.padding)

                            if availablePlayers.isEmpty {
                                Text("Keine weiteren Spieler verfügbar.")
                                    .font(.caption)
                                    .foregroundStyle(ImposterStyle.mutedText)
                                    .padding(.horizontal, ImposterStyle.padding)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            } else {
                                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 12)], spacing: 12) {
                                    ForEach(availablePlayers, id: \.self) { name in
                                        BankChip(name: name) {
                                            addExistingPlayer(name: name)
                                        }
                                    }
                                }
                                .padding(.horizontal, ImposterStyle.padding)
                            }
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .onAppear {
            if !myPlayerName.isEmpty {
                // Automatisch hinzufügen, wenn noch nicht vorhanden
                if !gameSettings.players.contains(where: { $0.name == myPlayerName }) {
                    gameSettings.addPlayer(name: myPlayerName)
                }
            }
        }
    }

    // MARK: - Logic

    private func playHaptic() {
        #if canImport(UIKit)
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        #endif
    }

    private func addNewPlayer() {
        let trimmed = newPlayerName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        // Prevent duplicates
        if !gameSettings.players.contains(where: { $0.name == trimmed }) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                gameSettings.addPlayer(name: trimmed)
            }
            playHaptic()
            
            // Auto-save to persistence
            if !gameSettings.savedPlayersManager.playerExists(trimmed) {
                gameSettings.savedPlayersManager.addPlayer(trimmed)
            }
        }
        
        newPlayerName = ""
        isInputFocused = true
    }

    private func addExistingPlayer(name: String) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            gameSettings.addPlayer(name: name)
        }
        playHaptic()
    }

    private func removePlayer(_ player: Player) {
        if let index = gameSettings.players.firstIndex(where: { $0.id == player.id }) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                gameSettings.removePlayer(at: index)
            }
            playHaptic()
        }
    }
}

// MARK: - Components

private struct SquadAvatar: View {
    let name: String
    let onTap: () -> Void

    var initials: String {
        let components = name.components(separatedBy: " ")
        if let first = components.first?.prefix(1), let last = components.last?.prefix(1), components.count > 1 {
            return "\(first)\(last)"
        }
        return String(name.prefix(2)).uppercased()
    }

    // Random pastel-ish color based on name hash
    var avatarColor: Color {
        let colors: [Color] = [.orange, .blue, .green, .purple, .pink, .teal, .indigo]
        let index = abs(name.hashValue) % colors.count
        return colors[index]
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(avatarColor.gradient)
                        .shadow(color: avatarColor.opacity(0.5), radius: 5, x: 0, y: 3)
                    
                    Text(initials)
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                    
                    // X Badge on Hover/State (Visual hint that tapping removes)
                    Image(systemName: "xmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.white)
                        .background(Circle().fill(.red))
                        .offset(x: 20, y: -20)
                }
                .frame(width: 64, height: 64)

                Text(name)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .frame(width: 70)
            }
        }
        .buttonStyle(.plain)
    }
}

private struct BankChip: View {
    let name: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: "plus")
                    .font(.caption.bold())
                Text(name)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(ImposterStyle.containerBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(ImposterStyle.cardStroke, lineWidth: 1)
            )
            .foregroundStyle(.white)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

private struct EmptySquadPlaceholder: View {
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "person.3.sequence.fill")
                .font(.largeTitle)
                .foregroundStyle(ImposterStyle.mutedText.opacity(0.5))
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Das Squad ist leer")
                    .font(.headline)
                    .foregroundStyle(.white)
                Text("Wähle Spieler aus der Bank oder erstelle neue.")
                    .font(.caption)
                    .foregroundStyle(ImposterStyle.mutedText)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .stroke(style: StrokeStyle(lineWidth: 2, dash: [5]))
                .foregroundStyle(ImposterStyle.mutedText.opacity(0.3))
        )
    }
}

// Simple button style for scaling effect
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
    settings.savedPlayersManager.addPlayer("Max")
    settings.savedPlayersManager.addPlayer("Anna")
    
    return PlayerManagementSheet()
        .environmentObject(settings)
}