//
//  VotingView.swift
//  Imposter
//
//  Created by Ken on 23.09.25.
//

import SwiftUI
import MultipeerConnectivity

struct VotingView: View {
    @ObservedObject var gameSettings: GameSettings
    @StateObject private var votingManager: VotingManager
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var gameLogic: GameLogic
    
    // Multiplayer State
    @State private var hasVotedMultiplayer = false
    @State private var isLockingAnimationActive = false
    
    private var isMultiplayer: Bool {
        MultipeerManager.shared.role != .unknown
    }

    private var votingProgress: ImposterVotingStatusPayload? {
        gameSettings.multiplayerVotingProgress
    }

    private var votesReceivedCount: Int {
        votingProgress?.votesReceived ?? 0
    }

    private var totalVotersCount: Int {
        if let progressTotal = votingProgress?.totalVoters {
            return progressTotal
        }
        return gameSettings.players.filter { !$0.isEliminated }.count
    }
    
    init(gameSettings: GameSettings) {
        self.gameSettings = gameSettings
        self._votingManager = StateObject(wrappedValue: VotingManager(gameSettings: gameSettings))
    }
    
    var body: some View {
        NavigationView {
            contentView
                .navigationTitle("")
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarBackButtonHidden(true)
                .toolbar {
                    votingToolbar
                }
        }
        .onAppear {
            if !votingManager.isVotingActive && !votingManager.showResults {
                votingManager.startVoting()
            }
            
            if isMultiplayer {
                hasVotedMultiplayer = false
            }
        }
        .onChange(of: votingManager.selectedPlayers) { _, _ in
            if isMultiplayer && !hasVotedMultiplayer && !votingManager.showResults && gameSettings.multiplayerVotingSelection == nil {
                sendMultiplayerVotePreview()
            }
        }
        .onChange(of: gameSettings.multiplayerVotingSelection) { _, selection in
            guard isMultiplayer, let selection else { return }
            guard MultipeerManager.shared.role == .host else { return }
            resolveMultiplayerSelection(selection)
        }
        .onChange(of: gameSettings.multiplayerVotingResult) { _, result in
            guard isMultiplayer, let result else { return }
            applyMultiplayerResult(result)
        }
        .onChange(of: gameSettings.gamePhase) { _, newPhase in
            if isMultiplayer && newPhase == .cardReveal {
                dismiss()
            }
        }
        .onDisappear {
            // Timer-Status wiederherstellen wenn Voting-View geschlossen wird
            if !votingManager.showResults {
                votingManager.restoreTimerState()
            }
            if isMultiplayer {
                gameSettings.shouldPresentVoting = false
            }
        }
    }

    @ViewBuilder
    private var contentView: some View {
        ZStack {
            // Hintergrund
            LinearGradient(
                colors: [Color.red.opacity(0.15), Color.orange.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            votingBody
        }
    }

    @ViewBuilder
    private var votingBody: some View {
        if isLockingAnimationActive {
            VStack(spacing: 20) {
                LottieView(
                    filename: "Lock Unlock Icon",
                    loopMode: .playOnce,
                    isPlaying: true
                )
                .frame(width: 180, height: 180)
                
                Text("STIMME VERRIEGELT")
                    .font(.system(size: 18, weight: .black, design: .monospaced))
                    .foregroundColor(.orange)
                    .tracking(2)
            }
            .transition(.scale.combined(with: .opacity))
        } else if votingManager.isSpyShootoutActive, let shooter = votingManager.shooter {
            SpyShootoutView(
                shooter: shooter,
                gameSettings: gameSettings,
                onHit: { _ in
                    // Spion trifft Geheimagent -> Spione gewinnen
                    Task { @MainActor in
                        StatsService.shared.recordSpyWinWordGuess(spyName: shooter.name, isFast: false) // Zählt als "besonderer" Sieg
                        let citizenNames = gameSettings.players.filter { !$0.isImposter && $0.roleType?.team == .citizen }.map { $0.name }
                        StatsService.shared.recordLoss(playerNames: citizenNames, asImposter: false)
                    }
                    votingManager.isSpyShootoutActive = false
                    votingManager.playersWon = false // Spione haben gestohlen!
                    votingManager.gameEnded = true
                    votingManager.showResults = true
                    gameSettings.markRoundCompleted()
                },
                onMiss: { _ in
                    // Spion verfehlt -> Bürger gewinnen (Bestätigung)
                    Task { @MainActor in
                        let spyNames = gameSettings.players.filter { $0.isImposter }.map { $0.name }
                        let citizenNames = gameSettings.players.filter { !$0.isImposter }.map { $0.name }
                        StatsService.shared.recordCitizenWin(citizenNames: citizenNames, isFast: false)
                        StatsService.shared.recordLoss(playerNames: spyNames, asImposter: true)
                    }
                    votingManager.isSpyShootoutActive = false
                    votingManager.playersWon = true
                    votingManager.gameEnded = true
                    votingManager.showResults = true
                    gameSettings.markRoundCompleted()
                }
            )
        } else if votingManager.showResults {
            VotingResultsView(
                votingManager: votingManager,
                gameSettings: gameSettings,
                onNewGame: {
                    dismiss()
                },
                onContinueToGameplay: {
                    dismiss()
                }
            )
        } else if isMultiplayer && hasVotedMultiplayer {
            // Multiplayer Warte-Screen
            MultiplayerVotingWaitView(
                votesReceived: votesReceivedCount,
                totalVoters: totalVotersCount
            )
        } else {
            VotingActiveView(
                votingManager: votingManager,
                gameSettings: gameSettings,
                isMultiplayer: isMultiplayer,
                maxSelections: isMultiplayer ? 1 : votingManager.remainingSpies,
                onVoteSubmitted: {
                    withAnimation {
                        isLockingAnimationActive = true
                    }
                    
                    // Sound & Haptik
                    SoundManager.shared.playSound(named: "computer-processing-sound-effects-short-click-select-01-122134")
                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                    
                    // Kurze Verzögerung für die Animation (1.5 Sekunden)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation {
                            isLockingAnimationActive = false
                            if isMultiplayer {
                                submitMultiplayerVote()
                            } else {
                                let _ = votingManager.executeVote()
                                votingManager.finishVoting()
                            }
                        }
                    }
                }
            )
        }
    }

    @ToolbarContentBuilder
    private var votingToolbar: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            VStack(spacing: 2) {
                Text("Abstimmung")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.red, .orange],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: .red.opacity(0.2), radius: 2, y: 1)

                if isMultiplayer {
                    Text("\(votesReceivedCount)/\(totalVotersCount) Stimmen")
                        .font(.caption2.bold())
                        .foregroundColor(.white.opacity(0.6))
                }
            }
        }

        // MARK: - Punkt 1: Schließen Button (X) oben rechts
        if !votingManager.showResults {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.gray)
                        .font(.title2)
                }
            }
        }
    }
    
    // MARK: - Multiplayer Logic
    
    private func submitMultiplayerVote() {
        let myName = MultipeerManager.shared.myPeerId.displayName
        
        // Hole die Namen der gewählten Spieler (IDs -> Namen mappen)
        let selectedIDs = votingManager.selectedPlayers
        let selectedNames = gameSettings.players
            .filter { selectedIDs.contains($0.id) }
            .map { $0.name }

        guard let selectedName = selectedNames.first else { return }
        
        let payload = ImposterVoteCastPayload(voterName: myName, votedFor: [selectedName])
        
        if MultipeerManager.shared.role == .host {
            gameLogic.handleMultiplayerVoteCast(payload)
        } else {
            MultipeerManager.shared.sendToHost(event: MPCEventType.imposterVoteCast, object: payload)
        }
        
        withAnimation {
            hasVotedMultiplayer = true
        }
    }

    private func sendMultiplayerVotePreview() {
        let myName = MultipeerManager.shared.myPeerId.displayName
        let selectedIDs = votingManager.selectedPlayers
        let selectedName = gameSettings.players
            .first(where: { selectedIDs.contains($0.id) })?
            .name

        let payload = ImposterVotePreviewPayload(voterName: myName, selectedName: selectedName)

        if MultipeerManager.shared.role == .host {
            gameLogic.handleMultiplayerVotePreview(payload)
        } else {
            MultipeerManager.shared.sendToHost(event: MPCEventType.imposterVotePreview, object: payload)
        }
    }

    private func resolveMultiplayerSelection(_ selection: [String]) {
        let selectedIDs = gameSettings.players
            .filter { selection.contains($0.name) }
            .map { $0.id }
        votingManager.selectedPlayers = Set(selectedIDs)
        let _ = votingManager.executeVote()
        votingManager.finishVoting()
        hasVotedMultiplayer = false

        let identifiedSpies = gameSettings.players
            .filter { ($0.isImposter || $0.roleType?.team == .imposter) && $0.isEliminated }
            .map { $0.name }
        let revealedSpies: [String]? = votingManager.gameEnded
            ? gameSettings.players
                .filter { $0.isImposter || $0.roleType?.team == .imposter }
                .map { $0.name }
            : nil

        let payload = ImposterVotingResultPayload(
            selectedPlayers: selection,
            identifiedSpies: identifiedSpies,
            revealedSpies: revealedSpies,
            gameEnded: votingManager.gameEnded,
            playersWon: votingManager.playersWon
        )

        gameSettings.multiplayerVotingResult = payload
        gameSettings.multiplayerVotingSelection = nil
        gameSettings.multiplayerVotingProgress = nil
        gameSettings.multiplayerVoteTally = [:]

        MultipeerManager.shared.sendToAll(event: MPCEventType.imposterVotingResult, object: payload)
    }

    private func applyMultiplayerResult(_ result: ImposterVotingResultPayload) {
        let selectedIDs = gameSettings.players
            .filter { result.selectedPlayers.contains($0.name) }
            .map { $0.id }
        votingManager.selectedPlayers = Set(selectedIDs)

        let identifiedNames = Set(result.identifiedSpies)
        let revealedNames = Set(result.revealedSpies ?? [])

        for index in gameSettings.players.indices {
            let name = gameSettings.players[index].name
            if identifiedNames.contains(name) {
                gameSettings.players[index].isImposter = true
                gameSettings.players[index].isEliminated = true
            }
            if revealedNames.contains(name) {
                gameSettings.players[index].isImposter = true
            }
        }

        let identifiedIDs = Set(gameSettings.players
            .filter { identifiedNames.contains($0.name) }
            .map { $0.id }
        )
        votingManager.foundSpies = identifiedIDs
        votingManager.gameEnded = result.gameEnded
        votingManager.playersWon = result.playersWon
        votingManager.lastRescueMessage = nil
        votingManager.isSpyShootoutActive = false
        votingManager.finishVoting()

        hasVotedMultiplayer = false
        gameSettings.multiplayerVotingProgress = nil
        gameSettings.multiplayerVoteTally = [:]
        gameSettings.multiplayerVotingSelection = nil
        gameSettings.multiplayerVotingResult = nil
    }
}

// MARK: - Aktive Abstimmung
struct VotingActiveView: View {
    @ObservedObject var votingManager: VotingManager
    let gameSettings: GameSettings
    let isMultiplayer: Bool
    let maxSelections: Int
    let onVoteSubmitted: () -> Void
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.black,
                    Color.red.opacity(0.1),
                    Color.black
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                
                // Fixierter Header Bereich
                VStack(spacing: 6) {
                    Text(isMultiplayer ? "Wen verdächtigst du?" : "Wer ist der Imposter?")
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white)
                    
                    Text(isMultiplayer 
                         ? "Deine Stimme bleibt geheim, bis alle gewählt haben."
                         : "Besprecht in der Gruppe und stimmt für die Eliminierung von genau einem Spieler ab.")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 20)
                }
                .padding(.top, 20)
                .padding(.bottom, 20)
                .background(Color.black.opacity(0.01))
                
                // Scrollbarer Bereich
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 16),
                        GridItem(.flexible(), spacing: 16)
                    ], spacing: 16) {
                        // Im Multiplayer kann man sich selbst nicht wählen (optional, hier erlaubt)
                        ForEach(gameSettings.players.filter { !votingManager.foundSpies.contains($0.id) }) { player in
                            let voteCount = isMultiplayer ? (gameSettings.multiplayerVoteTally[player.name] ?? 0) : 0
                            VotingPlayerCard(
                                player: player,
                                votingManager: votingManager,
                                gameSettings: gameSettings,
                                maxSelections: maxSelections,
                                voteCount: voteCount,
                                showVoteCount: isMultiplayer
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 120)
                }
            }
        }
        // Button bleibt unten fixiert
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 10) {
                Button {
                    onVoteSubmitted()
                } label: {
                    Text(isMultiplayer ? "Meine Stimme abgeben" : "Abstimmen")
                        .font(.headline)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .foregroundColor(.white)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.red, Color.red.opacity(0.85)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .shadow(color: .red.opacity(0.4), radius: 10, y: 5)
                        )
                }
                .disabled(!votingManager.canVote)
                .opacity(votingManager.canVote ? 1.0 : 0.6)
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
            .padding(.top, 8)
            .background(
                LinearGradient(colors: [.black.opacity(0), .black.opacity(0.8), .black], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
            )
        }
    }
}

// MARK: - Multiplayer Warte Screen
struct MultiplayerVotingWaitView: View {
    let votesReceived: Int
    let totalVoters: Int
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 8)
                    .frame(width: 140, height: 140)
                
                Circle()
                    .trim(from: 0, to: totalVoters > 0 ? CGFloat(votesReceived) / CGFloat(totalVoters) : 0)
                    .stroke(Color.red, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 140, height: 140)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(), value: votesReceived)
                
                VStack {
                    Text("\(votesReceived)/\(totalVoters)")
                        .font(.system(size: 36, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                    Text("STIMMEN")
                        .font(.caption.bold())
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            
            Text("Stimme akzeptiert")
                .font(.title2.bold())
                .foregroundColor(.white)
            
            Text("Warte auf das Ergebnis der Gruppe...")
                .font(.body)
                .foregroundColor(.white.opacity(0.6))
            
            Spacer()
        }
        .background(Color.black.opacity(0.8))
    }
}

// MARK: - Spieler-Karte für Abstimmung
struct VotingPlayerCard: View {
    let player: Player
    @ObservedObject var votingManager: VotingManager
    let gameSettings: GameSettings
    let maxSelections: Int
    let voteCount: Int
    let showVoteCount: Bool
    @State private var isPressed = false
    
    private var isSelected: Bool {
        votingManager.selectedPlayers.contains(player.id)
    }
    
    private var isSpyAlreadyFound: Bool {
        votingManager.foundSpies.contains(player.id)
    }
    
    private var canBeSelected: Bool {
        if isSpyAlreadyFound { return false }
        if isSelected { return true }
        if maxSelections <= 1 {
            return true
        }
        return votingManager.selectedPlayers.count < maxSelections
    }
    
    private var circleGradientColors: [Color] {
        if isSpyAlreadyFound {
            return [Color.green, Color.green.opacity(0.7)]
        } else if isSelected {
            return [Color.red, Color.red.opacity(0.7)]
        } else {
            return [Color.blue.opacity(0.8), Color.blue.opacity(0.6)]
        }
    }

    private var circleShadowColor: Color {
        if isSelected { return .red.opacity(0.5) }
        if isSpyAlreadyFound { return .green.opacity(0.5) }
        return .clear
    }

    private var strokeColor: Color {
        if isSpyAlreadyFound { return .green }
        if isSelected { return .red }
        return Color.white.opacity(0.3)
    }

    private var strokeLineWidth: CGFloat {
        (isSelected || isSpyAlreadyFound) ? 2 : 1
    }

    private var cardShadowColor: Color {
        if isSelected { return Color.red.opacity(0.35) }
        if isSpyAlreadyFound { return Color.green.opacity(0.35) }
        return Color.black.opacity(0.2)
    }

    private var cardShadowRadius: CGFloat { (isSelected || isSpyAlreadyFound) ? 10 : 6 }
    private var cardShadowY: CGFloat { (isSelected || isSpyAlreadyFound) ? 6 : 4 }
    private var circleShadowRadius: CGFloat { (isSelected || isSpyAlreadyFound) ? 8 : 0 }
    private var circleShadowY: CGFloat { (isSelected || isSpyAlreadyFound) ? 4 : 0 }

    @ViewBuilder
    private var avatarView: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: circleGradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 72, height: 72)
                .shadow(color: circleShadowColor, radius: circleShadowRadius, y: circleShadowY)

            if isSpyAlreadyFound {
                Image(systemName: "checkmark")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
            } else {
                Text(String(player.name.prefix(1)).uppercased())
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
        }
    }
    
    var body: some View {
        Button(action: {
            if canBeSelected {
                // Schweres haptisches Feedback für die "schwerwiegende" Entscheidung
                ImposterHapticsManager.shared.playHeavyThud()
                
                withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                    votingManager.togglePlayerSelection(player.id, maxSelections: maxSelections)
                }
            }
        }) {
            ZStack(alignment: .topTrailing) {
                VStack(spacing: 12) {
                    avatarView

                    Text(player.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .padding(16)
                .frame(maxWidth: .infinity, minHeight: 140)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.white.opacity(0.1))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(strokeColor, lineWidth: strokeLineWidth)
                )
                .shadow(color: cardShadowColor, radius: cardShadowRadius, y: cardShadowY)
                .scaleEffect(isPressed ? 0.97 : 1.0)
                .animation(.easeInOut(duration: 0.12), value: isPressed)

                if showVoteCount {
                    Text("\(voteCount)")
                        .font(.caption.bold())
                        .foregroundColor(.white)
                        .padding(6)
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.15))
                        )
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                        .padding(10)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!canBeSelected)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.12)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

#Preview("Voting – Aktiv") {
    let settings = GameSettings()
    settings.players = [
        Player(name: "Ken"),
        Player(name: "Elif"),
        Player(name: "Cagla"),
        Player(name: "Memo")
    ]
    settings.numberOfImposters = 1
    // Hinweis: Hier wird kein VotingManager injected, da er im Init der View erstellt wird,
    // aber für Previews ist das ok.
    return VotingView(gameSettings: settings)
        .environmentObject(GameLogic(gameSettings: settings))
}
