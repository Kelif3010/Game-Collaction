//
//  VotingResultsView.swift
//  Imposter
//
//  Created by Ken on 23.09.25.
//

import SwiftUI

struct VotingResultsView: View {
    @ObservedObject var votingManager: VotingManager
    let gameSettings: GameSettings
    let onNewGame: () -> Void
    let onContinueToGameplay: () -> Void
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var gameLogic: GameLogic
    
    private var lastVoteResult: VotingRoundResult {
        votingManager.lastRoundResult ?? VotingRoundResult(
            selectedPlayers: [],
            correctGuesses: [],
            incorrectGuesses: [],
            gameEnded: votingManager.gameEnded,
            playersWon: votingManager.playersWon
        )
    }
    
    private var winner: Player? {
        votingManager.foundSpies.first.flatMap { spyId in
            gameSettings.players.first(where: { $0.id == spyId })
        }
    }
    
    @State private var showContent = false
    @State private var laserOffset: CGFloat = -100
    @State private var fogOpacity: Double = 0
    @State private var pulseScale: CGFloat = 1.0
    @State private var textGlow: Double = 0
    
    private var imposterNames: [String] {
        gameSettings.players.filter { $0.isImposter }.map { $0.name }
    }
    
    private var imposterCount: Int { imposterNames.count }
    
    private var normalWords: [String] {
        let words = Set(gameSettings.players.filter { !$0.isImposter }.map { $0.word }.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })
        return Array(words)
    }
    
    private var secretWordsTitle: String {
        normalWords.count <= 1 ? "Geheimwort" : "Geheimwörter"
    }
    
    private var eliminatedSpiesThisRound: [Player] {
        let selected = votingManager.selectedPlayers
        return gameSettings.players.filter { selected.contains($0.id) && $0.isImposter }
    }
    
    var body: some View {
        ZStack {
            // Düsterer Hintergrund mit Nebel-Effekt
            LinearGradient(
                colors: [
                    Color.black,
                    (winner?.isImposter ?? false) ? Color.green.opacity(0.1) : Color.red.opacity(0.1),
                    Color.black
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Laser-Effekt
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.clear,
                            (winner?.isImposter ?? false) ? Color.green.opacity(0.8) : Color.red.opacity(0.8),
                            (winner?.isImposter ?? false) ? Color.green.opacity(0.3) : Color.red.opacity(0.3),
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 2)
                .offset(x: laserOffset)
                .animation(
                    Animation.linear(duration: 2.0)
                        .repeatForever(autoreverses: false),
                    value: laserOffset
                )
            
            VStack(spacing: 25) {
                // Ergebnis-Header mit Animation
                VStack(spacing: 15) {
                    ZStack {
                        // Pulsierender Ring
                        Circle()
                            .stroke(
                                (winner?.isImposter ?? false) ? Color.green.opacity(0.6) : Color.red.opacity(0.6),
                                lineWidth: 3
                            )
                            .frame(width: 120, height: 120)
                            .scaleEffect(pulseScale)
                            .animation(
                                Animation.easeInOut(duration: 1.5)
                                    .repeatForever(autoreverses: true),
                                value: pulseScale
                            )
                        
                        Image(systemName: (winner?.isImposter ?? false) ? "checkmark" : "xmark")
                            .font(.system(size: 50))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .shadow(color: (winner?.isImposter ?? false) ? .green.opacity(0.8) : .red.opacity(0.8), radius: 10)
                    }
                    .scaleEffect(showContent ? 1.0 : 0.6)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : -50)
                    .animation(.spring(response: 0.5, dampingFraction: 0.65).delay(0.1), value: showContent)
                    
                    VStack(spacing: 8) {
                        Text(getResultTitle())
                            .font(.title2)
                            .fontWeight(.black)
                            .foregroundColor(getResultColor())
                            .shadow(color: (votingManager.playersWon ? Color.green.opacity(textGlow) : Color.red.opacity(textGlow)), radius: 20)
                            .multilineTextAlignment(.center)
                            .lineLimit(3)
                            .minimumScaleFactor(0.9)
                            .opacity(showContent ? 1 : 0)
                            .animation(.easeOut(duration: 0.8).delay(0.2), value: showContent)
                        
                        Text(getResultSubtitle())
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .lineLimit(3)
                            .minimumScaleFactor(0.9)
                            .opacity(showContent ? 1 : 0)
                            .animation(.easeOut(duration: 0.8).delay(0.4), value: showContent)
                        
                        if !votingManager.playersWon {
                            // Geheimwort / -wörter (boxed style similar to WordGuessingView)
                        }
                    }
                }
                
                // Kompakte Spieler-Übersicht
                if votingManager.gameEnded && votingManager.playersWon {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 8) {
                        ForEach(gameSettings.players.filter { $0.isImposter }) { player in
                            ImposterResultCard(player: player)
                        }
                    }
                    .opacity(showContent ? 1 : 0)
                    .animation(.easeOut(duration: 0.8).delay(0.6), value: showContent)
                } else if !votingManager.gameEnded && !lastVoteResult.correctGuesses.isEmpty {
                    // Zeige nur die in dieser Runde eliminierten Spione
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        ForEach(eliminatedSpiesThisRound) { player in
                            ImposterResultCard(player: player)
                        }
                    }
                    .opacity(showContent ? 1 : 0)
                    .animation(.easeOut(duration: 0.8).delay(0.6), value: showContent)
                } else {
                    // Fälle wie: Spielende durch Imposter-Sieg oder falsche Wahl
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        ForEach(gameSettings.players.filter { $0.isImposter }) { player in
                            ImposterResultCard(player: player)
                        }
                    }
                    .opacity(showContent ? 1 : 0)
                    .animation(.easeOut(duration: 0.8).delay(0.6), value: showContent)
                }
                
                // Action Buttons
                VStack(spacing: 15) {
                    if !votingManager.gameEnded && votingManager.remainingSpies > 0 {
                        Button(action: {
                            print("➡️ [Continue] Tapped – preparing next round…")
                            logState(context: "before-continue")
                            // Bewahre bereits gefundene Spione und die dieser Runde eliminierten
                            let previouslyFound = votingManager.foundSpies
                            let eliminatedIDs = Set(eliminatedSpiesThisRound.map { $0.id })

                            // Reset für die nächste Runde
                            votingManager.resetForNextRound()

                            // Stelle die kumulative Menge wieder her: bereits gefundene + neu eliminierte
                            votingManager.foundSpies = previouslyFound.union(eliminatedIDs)

                            // Timer wiederherstellen und zurück ins Gameplay
                            votingManager.restoreTimerState()
                            logState(context: "after-continue-reset")
                            print("✅ [Continue] Next round prepared. Navigating back to gameplay…")
                            onContinueToGameplay()
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "play.circle.fill")
                                    .font(.title2)
                                Text("WEITERSPIELEN")
                                    .font(.headline)
                                    .fontWeight(.bold)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 30)
                            .padding(.vertical, 15)
                            .background(
                                RoundedRectangle(cornerRadius: 25)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.green, Color.green.opacity(0.8)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .shadow(color: .green.opacity(0.5), radius: 15)
                            )
                        }
                        .scaleEffect(showContent ? 1 : 0.8)
                        .opacity(showContent ? 1 : 0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.8), value: showContent)
                    }
                    
                    if votingManager.gameEnded || gameSettings.gamePhase == .finished {
                        Button(action: {
                            print("🔁 [NewGame] Restarting game from VotingResultsView…")
                            logState(context: "before-new-game")
                            Task { @MainActor in
                                await gameLogic.restartGame()
                                print("✅ [NewGame] Game restarted.")
                                onNewGame()
                            }
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.title2)
                                Text("NEUE MISSION")
                                    .font(.headline)
                                    .fontWeight(.bold)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 30)
                            .padding(.vertical, 15)
                            .background(
                                RoundedRectangle(cornerRadius: 25)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.blue, Color.blue.opacity(0.8)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .shadow(color: .blue.opacity(0.5), radius: 15)
                            )
                        }
                        .scaleEffect(showContent ? 1 : 0.8)
                        .opacity(showContent ? 1 : 0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(1.0), value: showContent)
                    }

                    Button(action: {
                        print("🛑 [Exit] Exiting to main menu from VotingResultsView…")
                        // Signal GamePlayView to exit to main and dismiss this sheet
                        gameSettings.requestExitToMain = true
                        dismiss()
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "xmark")
                                .font(.title2)
                            Text("BEENDEN")
                                .font(.headline)
                                .fontWeight(.bold)
                        }
                        .foregroundColor(.white.opacity(0.9))
                        .padding(.horizontal, 30)
                        .padding(.vertical, 15)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(Color.black.opacity(0.5))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 25)
                                        .stroke(Color.white.opacity(0.25), lineWidth: 1)
                                )
                                .shadow(color: .black.opacity(0.4), radius: 10)
                        )
                    }
                    .scaleEffect(showContent ? 1 : 0.8)
                    .opacity(showContent ? 1 : 0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(1.1), value: showContent)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 30)
        }
        .background(
            GeometryReader { proxy in
                Color.clear
                    .onAppear {
                        logState(context: "onAppear")
                        withAnimation {
                            showContent = true
                            laserOffset = proxy.size.width + 100
                            fogOpacity = 0.3
                            pulseScale = 1.2
                        }
                        withAnimation(
                            Animation.easeInOut(duration: 2.0)
                                .repeatForever(autoreverses: true)
                        ) {
                            textGlow = 1.0
                        }
                    }
            }
        )
        .onChange(of: votingManager.selectedPlayers) { _, newValue in
            let names = gameSettings.players.filter { newValue.contains($0.id) }.map { $0.name }
            print("🟡 [Change] selectedPlayers -> ids=\(Array(newValue)) | names=\(names)")
        }
        .onChange(of: votingManager.foundSpies) { _, newValue in
            let names = gameSettings.players.filter { newValue.contains($0.id) }.map { $0.name }
            print("🟢 [Change] foundSpies -> ids=\(Array(newValue)) | names=\(names) | remaining=\(votingManager.remainingSpies)")
        }
        .onChange(of: votingManager.gameEnded) { _, ended in
            print("🔴 [Change] gameEnded -> \(ended)")
            logState(context: "onChange-gameEnded")
        }
    }
    
    // MARK: - Debug Helpers
    private func logState(context: String) {
        print("\n===== 📊 VotingResultsView DEBUG [\(context)] =====")
        print("gameEnded=\(votingManager.gameEnded) | playersWon=\(votingManager.playersWon)")
        print("totalSpies=\(votingManager.totalSpies) | foundSpies=\(votingManager.foundSpies.count) | remainingSpies=\(votingManager.remainingSpies)")
        let foundNames = gameSettings.players.filter { votingManager.foundSpies.contains($0.id) }.map { $0.name }
        print("foundSpies(names)=\(foundNames)")
        let selectedNames = gameSettings.players.filter { votingManager.selectedPlayers.contains($0.id) }.map { $0.name }
        print("selectedPlayers=\(Array(votingManager.selectedPlayers)) | names=\(selectedNames)")
        let eliminatedNames = eliminatedSpiesThisRound.map { $0.name }
        print("eliminatedSpiesThisRound(names)=\(eliminatedNames)")
        let correctNames = lastVoteResult.correctGuesses.compactMap { id in gameSettings.players.first(where: { $0.id == id })?.name }
        let incorrectNames = lastVoteResult.incorrectGuesses.compactMap { id in gameSettings.players.first(where: { $0.id == id })?.name }
        print("lastVoteResult.correct=\(lastVoteResult.correctGuesses.count) [\(correctNames)] | incorrect=\(lastVoteResult.incorrectGuesses.count) [\(incorrectNames)] | gameEnded=\(lastVoteResult.gameEnded) | playersWon=\(lastVoteResult.playersWon)")
        print("-- Players --")
        for p in gameSettings.players {
            print("  • \(p.name) | isImposter=\(p.isImposter) | isEliminated=\(p.isEliminated) | id=\(p.id)")
        }
        print("===== END DEBUG =====\n")
    }
    
    // MARK: - Helper Functions
    private func getResultIcon() -> String {
        if votingManager.gameEnded {
            return votingManager.playersWon ? "crown.fill" : "skull.fill"
        } else {
            return lastVoteResult.correctGuesses.isEmpty ? "xmark" : "checkmark"
        }
    }
    
    private func getResultColor() -> Color {
        if votingManager.gameEnded {
            return votingManager.playersWon ? .green : .red
        } else {
            return lastVoteResult.correctGuesses.isEmpty ? .red : .green
        }
    }
    
    private func getResultTitle() -> String {
        if votingManager.gameEnded {
            if votingManager.playersWon {
                return "🎉 Alle Spione gefangen!"
            } else {
                return "💀 Spiel vorbei!"
            }
        } else {
            if lastVoteResult.correctGuesses.isEmpty {
                return "❌ Falsch gewählt!"
            } else if lastVoteResult.correctGuesses.count == 1 {
                return "✅ Ihr habt einen Spion eliminiert!"
            } else {
                return "✅ Ihr habt Spione eliminiert!"
            }
        }
    }
    
    private func getResultSubtitle() -> String {
        if votingManager.gameEnded {
            if votingManager.playersWon {
                return "Perfekt! Ihr habt alle \(votingManager.totalSpies) Spione entlarvt!"
            } else {
                return "Falsch gewählt – die Spione gewinnen!"
            }
        } else {
            let remaining = votingManager.remainingSpies
            if lastVoteResult.correctGuesses.isEmpty {
                return "Das waren keine Spione. Spiel beendet."
            } else {
                return "Es sind noch \(remaining) Spion\(remaining == 1 ? "" : "e") versteckt!"
            }
        }
    }
}

// MARK: - Karte für gewählte Spieler
struct VotingChoiceCard: View {
    let player: Player
    let wasCorrect: Bool
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 8) {
            // Avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: wasCorrect ?
                                [Color.green, Color.green.opacity(0.7)] :
                                [Color.red, Color.red.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                
                Image(systemName: wasCorrect ? "checkmark" : "xmark")
                    .font(.title2)
                    .foregroundColor(.white)
            }
            
            // Name & Status
            VStack(spacing: 2) {
                Text(player.name)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(wasCorrect ? "SPION!" : "UNSCHULDIG")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(wasCorrect ? .green : .red)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    wasCorrect ?
                        LinearGradient(colors: [Color.green.opacity(0.15), Color.green.opacity(0.1)], startPoint: .top, endPoint: .bottom) :
                        LinearGradient(colors: [Color.red.opacity(0.15), Color.red.opacity(0.1)], startPoint: .top, endPoint: .bottom)
                )
        )
    }
}

// MARK: - Wahrheits-Enthüllungskarte
struct TruthRevealCard: View {
    let player: Player
    
    var body: some View {
        VStack(spacing: 6) {
            // Avatar mit Glow
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: player.isImposter ?
                                [Color.red, Color.red.opacity(0.7)] :
                                [Color.green, Color.green.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)
                    .shadow(
                        color: player.isImposter ? .red.opacity(0.6) : .green.opacity(0.6),
                        radius: 8
                    )
                
                Image(systemName: player.isImposter ? "eye.fill" : "checkmark")
                    .font(.title3)
                    .foregroundColor(.white)
            }
            
            // Name & Rolle
            VStack(spacing: 2) {
                Text(player.name)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text(player.isImposter ? "SPION" : "BÜRGER")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(player.isImposter ? .red : .green)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 6)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(
                    player.isImposter ?
                        Color.red.opacity(0.2) :
                        Color.green.opacity(0.2)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(
                            player.isImposter ? Color.red : Color.green,
                            lineWidth: 1
                        )
                )
        )
    }
}

// MARK: - Neue ImposterResultCard
struct ImposterResultCard: View {
    let player: Player
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.red, Color.red.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 70, height: 70)
                
                if let firstChar = player.name.first {
                    Text(String(firstChar))
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                } else {
                    Image(systemName: "eye.fill")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            
            Text(player.name)
                .font(.headline)
                .foregroundColor(.white)
                .bold()
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 140)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.red, lineWidth: 2)
        )
        .shadow(color: Color.red.opacity(0.35), radius: 10, y: 6)
    }
}

// MARK: - Preview Helpers
private func buildVotingResultsView(impostersCount: Int, playersWin: Bool) -> some View {
    let gameSettings = GameSettings()
    let names = ["Max", "Anna", "Tom", "Lisa", "Sophie", "Ben"]
    gameSettings.players = names.map { Player(name: $0) }

    // Clamp impostersCount to valid range
    let imposters = max(1, min(impostersCount, gameSettings.players.count - 1))
    for i in 0..<imposters { gameSettings.players[i].isImposter = true }

    let votingManager = VotingManager(gameSettings: gameSettings)

    if playersWin {
        // Spieler wählen alle Imposter korrekt
        votingManager.selectedPlayers = Set(gameSettings.players.prefix(imposters).map { $0.id })
    } else {
        // Spieler wählen einen Unschuldigen -> Imposter gewinnen
        if let innocent = gameSettings.players.first(where: { !$0.isImposter }) {
            votingManager.selectedPlayers = [innocent.id]
        }
    }

    _ = votingManager.executeVote()
    votingManager.finishVoting()

    return VotingResultsView(
        votingManager: votingManager,
        gameSettings: gameSettings,
        onNewGame: {},
        onContinueToGameplay: {}
    )
    .environmentObject(GameLogic(gameSettings: gameSettings))
}

struct VotingResultsPreviewConfigurator: View {
    @State private var impostersCount: Int = 1
    @State private var playersWin: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("VotingResults Preview-Konfigurator")
                .font(.headline)

            Stepper("Anzahl Imposter: \(impostersCount)", value: $impostersCount, in: 1...3)
            Toggle("Spieler gewinnen", isOn: $playersWin)
                .toggleStyle(.switch)

            Divider()
                .padding(.vertical, 4)

            // Eingebettete Vorschau
            buildVotingResultsView(impostersCount: impostersCount, playersWin: playersWin)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding()
    }
}

#Preview("Imposter verlieren (Spieler gewinnen)") {
    buildVotingResultsView(impostersCount: 1, playersWin: true)
}

#Preview("Imposter gewinnen (2 Imposter)") {
    buildVotingResultsView(impostersCount: 2, playersWin: false)
}

#Preview("Konfigurierbar: Anzahl Imposter & Ausgang") {
    VotingResultsPreviewConfigurator()
}
