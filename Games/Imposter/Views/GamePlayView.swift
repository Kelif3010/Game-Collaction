//
//  GamePlayView.swift
//  Imposter
//
//  Created by Ken on 22.09.25.
//

import SwiftUI
import MultipeerConnectivity

struct GamePlayView: View {
    @EnvironmentObject var gameSettings: GameSettings
    @EnvironmentObject var gameLogic: GameLogic
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentCard: GameCard?
    @State private var hasRevealedOwnCard = false
    
    @State private var showStartingPlayerAnnouncement = false
    @State private var startingPlayer: Player?
    
    // KI-Services
    @StateObject private var hintService = HintService.shared

    private var isMultiplayerActive: Bool {
        MultipeerManager.shared.role != .unknown
    }

    private var isHostOrLocal: Bool {
        let role = MultipeerManager.shared.role
        return role == .host || role == .unknown
    }
    
    var body: some View {
        ZStack {
            // Globaler Hintergrund
            ImposterStyle.backgroundGradient
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header (nur anzeigen wenn nicht im Vollbild-Lademodus)
                if !gameSettings.isWaitingForOtherPlayers {
                    ImposterGameHeaderView()
                        .padding(.bottom, 10)
                }
                
                mainContent
                
                Spacer()
                
                // Footer (Beenden) - Nur anzeigen wenn Spiel läuft
                if !gameSettings.isWaitingForOtherPlayers && gameSettings.gamePhase == .playing {
                    GameFooterView()
                }
            }
        }
        .onAppear {
            if isMultiplayerActive {
                hasRevealedOwnCard = false
                gameSettings.isWaitingForOtherPlayers = false
            }
            startGame()
        }
        .onDisappear {
            gameLogic.stopGameTimer()
        }
        .navigationBarHidden(true)
        .onChange(of: gameSettings.requestExitToMain) { _, newValue in
            if newValue {
                dismiss()
            }
        }
        .onChange(of: gameSettings.requestExitToSetup) { _, newValue in
            if newValue {
                gameSettings.requestExitToSetup = false
                dismiss()
            }
        }
        .onChange(of: gameSettings.startingPlayerName) { _, newName in
            if let newName = newName {
                startingPlayer = gameSettings.players.first(where: { $0.name == newName })
            }
        }
        .onChange(of: gameSettings.gamePhase) { _, newPhase in
            if newPhase == .finished {
                gameLogic.stopGameTimer()
            } else if newPhase == .cardReveal && !isMultiplayerActive {
                showStartingPlayerAnnouncement = false
                gameSettings.isTimerPaused = true
                prepareNextCard()
            }
        }
        .onChange(of: gameSettings.players) { oldPlayers, newPlayers in
            guard isMultiplayerActive else { return }
            guard !hasRevealedOwnCard else { return }
            let myName = MultipeerManager.shared.myPeerId.displayName
            let oldSelf = oldPlayers.first(where: { $0.name == myName })
            let newSelf = newPlayers.first(where: { $0.name == myName })
            
            // Check if Role actually changed, preventing flicker
            let shouldRefresh = currentCard == nil
                || oldSelf?.word != newSelf?.word
                || oldSelf?.isImposter != newSelf?.isImposter
            
            if shouldRefresh {
                currentCard = nil // Reset Card
                prepareMultiplayerCardIfNeeded()
            }
        }
        .onChange(of: gameSettings.roundCategory) { _, _ in
            if isMultiplayerActive {
                prepareMultiplayerCardIfNeeded()
            }
        }
        .onChange(of: gameSettings.currentPlayerIndex) { _, _ in
            if isMultiplayerActive && !hasRevealedOwnCard {
                currentCard = nil
                prepareMultiplayerCardIfNeeded()
            }
        }
    }

    @ViewBuilder
    private var mainContent: some View {
        ZStack {
            if isMultiplayerActive {
                if gameSettings.gamePhase == .finished {
                    TimeOutResultView()
                        .transition(.opacity)
                } else if gameSettings.isWaitingForOtherPlayers {
                    // NEU: Warte-Screen
                    MultiplayerWaitingView()
                        .transition(.opacity)
                } else if !hasRevealedOwnCard {
                    cardRevealContent
                        .transition(.opacity)
                } else {
                    playingContent
                }
            } else {
                switch gameSettings.gamePhase {
                case .cardReveal:
                    cardRevealContent
                case .playing:
                    playingContent
                case .finished:
                    TimeOutResultView()
                        .transition(.opacity)
                default:
                    EmptyView()
                }
            }
        }
    }
    
    // MARK: - Phase 1: Card Reveal Views
    
    @ViewBuilder
    private var cardRevealContent: some View {
        if let card = currentCard {
            // ZStack Hintergrund sicherstellen, damit nichts durchscheint
            ZStack {
                ImposterStyle.backgroundGradient.ignoresSafeArea()
                
                VStack {
                    Spacer()
                    SpyCardView(
                        card: card,
                        gameSettings: gameSettings,
                        onCardTap: {
                            if !isMultiplayerActive {
                                gameLogic.markCurrentPlayerCardSeen()
                            }
                        },
                        onCardDismissed: {
                            handleCardDismissed()
                        }
                    )
                    .id(card.id) 
                    Spacer()
                }
                .transition(.scale(scale: 0.95).combined(with: .opacity))
            }
        } else {
            // Ladezustand
            ProgressView()
                .tint(.white)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    // MARK: - Phase 2: Playing Views
    
    @ViewBuilder
    private var playingContent: some View {
        if showStartingPlayerAnnouncement {
            StartingPlayerAnnouncementView(player: startingPlayer) {
                beginRoundAfterAnnouncement()
            }
        } else {
            ZStack {
                // Haupt-Timer und Buttons
                GameTimerView()
                
                // KI-Hinweise Overlay (unten rechts schwebend)
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        HintOverlay(hintService: hintService)
                    }
                }
                .padding(.bottom, 20)
            }
        }
    }
    
    // MARK: - Logic
    
    private func startGame() {
        gameLogic.stopGameTimer()

        if isMultiplayerActive {
            prepareMultiplayerCardIfNeeded()
            return
        }

        if gameSettings.gamePhase == .setup {
            Task { @MainActor in
                await gameLogic.startGame()
                prepareNextCard()
            }
        } else {
            prepareNextCard()
        }
    }

    private func prepareMultiplayerCardIfNeeded() {
        guard !hasRevealedOwnCard else { return }
        guard let player = gameLogic.currentPlayer else { return }
        let myName = MultipeerManager.shared.myPeerId.displayName
        guard player.name == myName else { return }
        
        if currentCard?.player.name != player.name {
            currentCard = nil
        }
        if currentCard == nil {
            prepareNextCard()
        }
    }

    private func markMultiplayerCardSeen() {
        let myName = MultipeerManager.shared.myPeerId.displayName
        
        // Mark self ready locally FIRST
        if let myIndex = gameSettings.players.firstIndex(where: { $0.name == myName }) {
            gameSettings.players[myIndex].hasSeenCard = true
        }
        
        // Show Waiting Screen
        withAnimation {
            gameSettings.isWaitingForOtherPlayers = true
        }

        // Send to Host Logic (even if Host)
        let payload = ImposterCardSeenPayload(playerName: myName)
        if MultipeerManager.shared.role == .host {
             // Host Logic simulation for self
             MultipeerManager.shared.onEventReceived?(MPCEventType.imposterCardSeen, try? JSONEncoder().encode(payload))
        } else {
             MultipeerManager.shared.sendToHost(event: MPCEventType.imposterCardSeen, object: payload)
        }
    }
    
    private func prepareNextCard() {
        guard let player = gameLogic.currentPlayer,
              let category = gameSettings.roundCategory ?? gameSettings.selectedCategory else {
            return
        }
        
        // Karte laden
        currentCard = GameCard(player: player, category: category)
    }
    
    private func handleCardDismissed() {
        if isMultiplayerActive {
            hasRevealedOwnCard = true
            markMultiplayerCardSeen()
            // We do NOT start timer here anymore. We wait for MPC GameStart signal.
            return
        }

        // PRE-CHECK: Ist das der letzte Spieler?
        let isLastPlayer = gameSettings.currentPlayerIndex >= gameSettings.players.count - 1
        
        if isLastPlayer {
            // 1. Logik für Startspieler jetzt schon ausführen
            if MultipeerManager.shared.role == .host || MultipeerManager.shared.role == .unknown {
                let picked = gameSettings.players.randomElement()
                startingPlayer = picked
                gameSettings.startingPlayerName = picked?.name
                gameLogic.broadcastGameState()
            }
            
            // 2. View-Status setzen
            gameSettings.isTimerPaused = true
            showStartingPlayerAnnouncement = true
        }

        // 3. Phase weiterschalten (Das ändert gamePhase auf .playing)
        gameLogic.nextPlayer()
        
        if gameSettings.gamePhase == .cardReveal {
            // Nächster Spieler ist dran -> Handover Screen wieder aktivieren
            prepareNextCard()
        } 
    }
    
    private func beginRoundAfterAnnouncement() {
        withAnimation {
            showStartingPlayerAnnouncement = false
        }
        gameSettings.isTimerPaused = false
    }
}

// MARK: - Multiplayer Waiting View
struct MultiplayerWaitingView: View {
    @EnvironmentObject var gameSettings: GameSettings
    
    var body: some View {
        ZStack {
            ImposterStyle.backgroundGradient.ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Animated Loading Circle
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 8)
                        .frame(width: 120, height: 120)
                    
                    Circle()
                        .trim(from: 0, to: 0.75)
                        .stroke(Color.blue, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(Double(Int(Date().timeIntervalSince1970 * 100) % 360)))
                        .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: Date())
                }
                
                VStack(spacing: 10) {
                    Text("WARTE AUF SPIELER")
                        .font(.headline)
                        .fontWeight(.bold)
                        .tracking(2)
                        .foregroundColor(.white)
                    
                    if let progress = gameSettings.revealProgress {
                        Text("\(progress.ready) / \(progress.total) BEREIT")
                            .font(.system(size: 32, weight: .black, design: .monospaced))
                            .foregroundColor(.blue)
                    } else {
                        Text("Synchronisiere...")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                
                Text("Das Spiel startet automatisch,\nsobald alle ihre Rolle gesehen haben.")
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.horizontal, 40)
            }
        }
    }
}

// MARK: - Game Header View (Modern HUD)
struct ImposterGameHeaderView: View {
    @EnvironmentObject var gameSettings: GameSettings

    private var isMultiplayerActive: Bool {
        MultipeerManager.shared.role != .unknown
    }
    
    var body: some View {
        HStack {
            // Links: Bedrohungs-Level (Spione)
            if !gameSettings.randomSpyCount {
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(Color.red.opacity(0.2))
                            .frame(width: 32, height: 32)
                        Image(systemName: "eye.slash.fill")
                            .font(.caption.bold())
                            .foregroundColor(.red)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(gameSettings.numberOfImposters)")
                            .font(.system(size: 14, weight: .black))
                            .foregroundColor(.white)
                        Text(gameSettings.numberOfImposters == 1 ? "SPION" : "SPIONE")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color.white.opacity(0.1), lineWidth: 1))
            }
            
            Spacer() 
            
            // Rechts: Fortschritt (Runde)
            if gameSettings.gamePhase == .cardReveal && !isMultiplayerActive {
                HStack(spacing: 8) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(gameSettings.currentPlayerIndex + 1)/\(gameSettings.players.count)")
                            .font(.system(size: 14, weight: .black, design: .monospaced))
                            .foregroundColor(.white)
                        Text("VERTEILT")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.1), lineWidth: 3)
                            .frame(width: 24, height: 24)
                        
                        let progress = Double(gameSettings.currentPlayerIndex + 1) / Double(max(1, gameSettings.players.count))
                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(Color.blue, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                            .frame(width: 24, height: 24)
                            .rotationEffect(.degrees(-90))
                            .animation(.spring(), value: progress)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color.white.opacity(0.1), lineWidth: 1))
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }
}

// MARK: - Starting Player Announcement
struct StartingPlayerAnnouncementView: View {
    let player: Player?
    let onContinue: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(ImposterStyle.primaryGradient.opacity(0.2))
                    .frame(width: 140, height: 140)
                    .blur(radius: 20)
                
                Image(systemName: "flag.checkered")
                    .font(.system(size: 60))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 10) {
                Text(LocalizedStringKey("Startspieler"))
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.7))
                    .textCase(.uppercase)
                    .kerning(2)
                
                Text(player?.name ?? "Zufall")
                    .font(.system(size: 42, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
            }
            
            Text(LocalizedStringKey("Der ausgewählte Spieler beginnt die Runde. Danach startet der Timer."))
                .font(.body)
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
            
            ImposterPrimaryButton(title: "Los geht\'s") {
                onContinue()
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
    }
}

// MARK: - Game Timer View (Playing Phase)
struct GameTimerView: View {
    @EnvironmentObject var gameSettings: GameSettings
    @EnvironmentObject var gameLogic: GameLogic
    
    @State private var showVotingView = false
    @State private var showWordGuessingView = false
    @State private var showWordGuessConfirm = false
    @State private var startWordGuessImmediateWin = false
    @State private var wasTimerPausedBeforeWordGuess = false

    private var isHostOrLocal: Bool {
        let role = MultipeerManager.shared.role
        return role == .host || role == .unknown
    }
    
    var body: some View {
        VStack(spacing: 40) {
            
            Spacer()
            
            // 1. TIMER & PAUSE CONTROL (Zentrales Element)
            VStack(spacing: 20) {
                // Timer Circle mit Pause-Indikator
                ZStack {
                    // Pulsierender Ring wenn aktiv
                    if !gameSettings.isTimerPaused {
                        Circle()
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            .frame(width: 260, height: 260)
                            .scaleEffect(1.1)
                            .opacity(0.5)
                            .animation(.easeInOut(duration: 1).repeatForever(), value: gameSettings.isTimerPaused)
                    }
                    
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 240, height: 240)
                        .shadow(color: .black.opacity(0.3), radius: 20)
                    
                    VStack(spacing: 4) {
                        Text(timeString)
                            .font(.system(size: 70, weight: .heavy, design: .monospaced))
                            .foregroundStyle(gameSettings.timeRemaining <= 60 ? .red : .white)
                            .contentTransition(.numericText())
                        
                        Text(gameSettings.isTimerPaused ? "PAUSIERT" : "LÄUFT")
                            .font(.caption.bold())
                            .tracking(2)
                            .foregroundStyle(gameSettings.isTimerPaused ? .orange : .green)
                    }
                }
                .onTapGesture {
                    togglePause()
                }
                
                // Kleiner Hinweis
                if isHostOrLocal {
                    Text("Tippen zum Pausieren")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.4))
                }
            }
            
            Spacer()
            
            // 2. ACTION BUTTONS (Vertikal statt Grid)
            VStack(spacing: 16) {
                // Abstimmen Button
                GameControlBtn(
                    title: "Jetzt Abstimmen",
                    subtitle: "Verdächtigen wählen",
                    icon: "hand.point.up.left.fill",
                    color: Color.blue,
                    isEnabled: isHostOrLocal,
                    action: {
                        if isHostOrLocal { showVotingView = true }
                    }
                )
                
                // Wort lösen Button
                GameControlBtn(
                    title: "Wort lösen",
                    subtitle: "Nur für Spione",
                    icon: "lightbulb.max.fill",
                    color: Color.orange,
                    isEnabled: isHostOrLocal,
                    action: {
                        if isHostOrLocal { showWordGuessConfirm = true }
                    }
                )
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 40)
        }
        // Modals
        .sheet(isPresented: $showVotingView) {
            VotingView(gameSettings: gameSettings)
                .environmentObject(gameLogic)
                .interactiveDismissDisabled(true)
        }
        .alert(LocalizedStringKey("Spion enttarnt sich?"), isPresented: $showWordGuessConfirm) {
            Button("Abbrechen", role: .cancel) { }
            Button(LocalizedStringKey("Ja, Wort lösen")) {
                wasTimerPausedBeforeWordGuess = gameSettings.isTimerPaused
                gameSettings.isTimerPaused = true
                startWordGuessImmediateWin = true
                showWordGuessingView = true
            }
        } message: {
            Text(LocalizedStringKey("Willst du als Spion versuchen das Wort zu erraten, um sofort zu gewinnen?"))
        }
        .fullScreenCover(isPresented: $showWordGuessingView) {
            WordGuessingView(gameSettings: gameSettings, startWithImmediateWin: startWordGuessImmediateWin)
                .environmentObject(gameLogic)
                .onDisappear {
                    if !wasTimerPausedBeforeWordGuess {
                        gameSettings.isTimerPaused = false
                    }
                    startWordGuessImmediateWin = false
                }
        }
    }
    
    private func togglePause() {
        guard isHostOrLocal else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        withAnimation {
            gameSettings.isTimerPaused.toggle()
            if MultipeerManager.shared.role == .host {
                gameLogic.broadcastGameState()
            }
        }
    }
    
    private var timeString: String {
        let minutes = gameSettings.timeRemaining / 60
        let seconds = gameSettings.timeRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// Helper Button Component (Umbenannt um Konflikte zu vermeiden)
struct GameControlBtn: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let isEnabled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundStyle(color)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(LocalizedStringKey(title))
                        .font(.headline.bold())
                        .foregroundStyle(.white)
                    
                    if !subtitle.isEmpty {
                        Text(LocalizedStringKey(subtitle))
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundStyle(.white.opacity(0.3))
            }
            .padding(16)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(.white.opacity(0.1), lineWidth: 1)
            )
        }
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.6)
    }
}

// MARK: - Game Footer View (Redesigned Exit Button)
struct GameFooterView: View {
    @EnvironmentObject var gameSettings: GameSettings
    @Environment(\.dismiss) private var dismiss
    @State private var showExitConfirmation = false
    
    var body: some View {
        Button {
            showExitConfirmation = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "xmark")
                    .font(.caption.bold())
                Text(LocalizedStringKey("Spiel verlassen"))
                    .font(.callout.weight(.medium))
            }
            .foregroundColor(.white.opacity(0.7))
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color.black.opacity(0.3))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
        .padding(.bottom, 20)
        .confirmationDialog(
            "Spiel wirklich beenden?",
            isPresented: $showExitConfirmation,
            titleVisibility: .visible
        ) {
            Button("Abbrechen", role: .cancel) { }
            Button("Spiel beenden", role: .destructive) {
                gameSettings.markRoundCompleted()
                gameSettings.resetGame()
                dismiss()
            }
        } message: {
            Text("Der aktuelle Fortschritt geht verloren.")
        }
    }
}

#Preview {
    let settings = GameSettings()
    settings.players = [Player(name: "Demo"), Player(name: "Demo 2")]
    return GamePlayView()
        .environmentObject(settings)
        .environmentObject(GameLogic(gameSettings: settings))
}