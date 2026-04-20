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
        NavigationStack {
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
                .animation(.spring(response: 0.45, dampingFraction: 0.85), value: votingManager.showResults)
                .animation(.spring(response: 0.45, dampingFraction: 0.85), value: isLockingAnimationActive)
                .animation(.spring(response: 0.45, dampingFraction: 0.85), value: votingManager.isSpyShootoutActive)
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
                    .foregroundStyle(.orange)
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
            .transition(.asymmetric(
                insertion: .move(edge: .bottom).combined(with: .opacity),
                removal: .opacity
            ))
        } else if isMultiplayer && hasVotedMultiplayer {
            // Multiplayer Warte-Screen
            MultiplayerVotingWaitView(
                votesReceived: votesReceivedCount,
                totalVoters: totalVotersCount
            )
            .transition(.opacity)
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
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    
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
            VStack(spacing: 4) {
                Text("ABSTIMMUNG")
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .tracking(2)
                    .foregroundStyle(ImposterStyle.spyRed)

                if isMultiplayer {
                    Text("\(votesReceivedCount)/\(totalVotersCount) STIMMEN")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
        }

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

// MARK: - Aktive Abstimmung (Spy-Theme)
struct VotingActiveView: View {
    @ObservedObject var votingManager: VotingManager
    let gameSettings: GameSettings
    let isMultiplayer: Bool
    let maxSelections: Int
    let onVoteSubmitted: () -> Void

    var body: some View {
        ZStack {
            // Background
            Color.black.ignoresSafeArea()

            // Subtle red gradient
            RadialGradient(
                colors: [ImposterStyle.spyRed.opacity(0.1), Color.black],
                center: .top,
                startRadius: 100,
                endRadius: 500
            )
            .ignoresSafeArea()

            // Scanlines
            ScanlineOverlay(lineSpacing: 4, opacity: 0.025)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                VStack(spacing: 10) {
                    // Title with badge
                    HStack {
                        Spacer()
                        ClassifiedBadge(text: "ABSTIMMUNG", color: ImposterStyle.spyRed)
                        Spacer()
                    }

                    Text(isMultiplayer ? "WEN VERDÄCHTIGST DU?" : "WER IST DER AGENT?")
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .tracking(1)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)

                    Text(isMultiplayer
                         ? "Deine Stimme bleibt geheim bis alle gewählt haben."
                         : "Wählt gemeinsam einen Verdächtigen zur Eliminierung.")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.5))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                }
                .padding(.top, 16)
                .padding(.bottom, 20)

                // Player Grid
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 14),
                        GridItem(.flexible(), spacing: 14)
                    ], spacing: 14) {
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
        // Bottom Button
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 0) {
                SpyActionButton(
                    title: isMultiplayer ? "STIMME ABGEBEN" : "ABSTIMMEN",
                    subtitle: votingManager.canVote ? "Auswahl bestätigen" : "Wähle einen Verdächtigen",
                    icon: "checkmark.seal.fill",
                    style: .primary,
                    isEnabled: votingManager.canVote,
                    action: { onVoteSubmitted() }
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
            }
            .padding(.top, 12)
            .background(
                LinearGradient(colors: [.black.opacity(0), .black.opacity(0.95), .black], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
            )
        }
    }
}

// MARK: - Multiplayer Warte Screen (Spy-Theme)
struct MultiplayerVotingWaitView: View {
    let votesReceived: Int
    let totalVoters: Int

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // Scanlines
            ScanlineOverlay(lineSpacing: 4, opacity: 0.03)
                .ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                // Status Badge
                ClassifiedBadge(text: "ÜBERTRAGUNG", color: ImposterStyle.terminalAmber)

                // Progress Ring
                ZStack {
                    // Outer ring
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 6)
                        .frame(width: 140, height: 140)

                    // Progress
                    Circle()
                        .trim(from: 0, to: totalVoters > 0 ? CGFloat(votesReceived) / CGFloat(totalVoters) : 0)
                        .stroke(ImposterStyle.spyRed, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .frame(width: 140, height: 140)
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(), value: votesReceived)

                    // Inner content
                    VStack(spacing: 4) {
                        Text("\(votesReceived)/\(totalVoters)")
                            .font(.system(size: 32, weight: .bold, design: .monospaced))
                            .foregroundStyle(.white)

                        Text("STIMMEN")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .tracking(2)
                            .foregroundStyle(.white.opacity(0.4))
                    }
                }

                // Text
                VStack(spacing: 12) {
                    Text("STIMME REGISTRIERT")
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .tracking(2)
                        .foregroundStyle(.white)

                    Text("Warte auf Ergebnis der Gruppe...")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.5))
                }

                Spacer()

                // Animated dots
                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(ImposterStyle.spyRed.opacity(0.6))
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.bottom, 40)
            }
        }
    }
}

// MARK: - Spieler-Karte für Abstimmung (Spy-Theme)
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
        if maxSelections <= 1 { return true }
        return votingManager.selectedPlayers.count < maxSelections
    }

    private var accentColor: Color {
        if isSpyAlreadyFound { return .green }
        if isSelected { return ImposterStyle.spyRed }
        return Color.white.opacity(0.4)
    }

    private var backgroundColor: Color {
        if isSelected { return ImposterStyle.spyRed.opacity(0.15) }
        if isSpyAlreadyFound { return Color.green.opacity(0.1) }
        return Color.white.opacity(0.05)
    }

    var body: some View {
        Button(action: {
            if canBeSelected {
                ImposterHapticsManager.shared.playHeavyThud()
                withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                    votingManager.togglePlayerSelection(player.id, maxSelections: maxSelections)
                }
            }
        }) {
            ZStack(alignment: .topTrailing) {
                VStack(spacing: 0) {
                    // Header strip
                    HStack {
                        Text("VERDÄCHTIG")
                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                            .tracking(1)
                            .foregroundStyle(isSelected ? ImposterStyle.spyRed : .white.opacity(0.3))

                        Spacer()

                        if isSelected {
                            Image(systemName: "target")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(ImposterStyle.spyRed)
                        } else if isSpyAlreadyFound {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(.green)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(accentColor.opacity(0.1))

                    // Content
                    VStack(spacing: 10) {
                        // Avatar
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(accentColor.opacity(0.15))
                                .frame(width: 56, height: 56)

                            if isSpyAlreadyFound {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundStyle(.green)
                            } else {
                                Text(String(player.name.prefix(1)).uppercased())
                                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                                    .foregroundStyle(.white)
                            }
                        }

                        // Name
                        Text(player.name)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .padding(.vertical, 14)
                    .padding(.horizontal, 12)
                }
                .frame(maxWidth: .infinity, minHeight: 130)
                .background(backgroundColor)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(accentColor.opacity(isSelected ? 0.6 : 0.2), lineWidth: isSelected ? 2 : 1)
                )
                .scaleEffect(isPressed ? 0.97 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: isPressed)

                // Vote count badge
                if showVoteCount && voteCount > 0 {
                    Text("\(voteCount)")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)
                        .padding(6)
                        .background(
                            Circle()
                                .fill(ImposterStyle.spyRed)
                        )
                        .padding(8)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!canBeSelected)
        .opacity(canBeSelected ? 1 : 0.5)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
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
