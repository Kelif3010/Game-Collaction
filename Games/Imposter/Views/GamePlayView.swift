//
//  GamePlayView.swift
//  Imposter
//
//  Created by Ken on 22.09.25.
//

import SwiftUI

struct GamePlayView: View {
    @EnvironmentObject var gameSettings: GameSettings
    @EnvironmentObject var gameLogic: GameLogic
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentCard: GameCard?
    // Steuert den Sicherheits-Screen für die Weitergabe
    @State private var isShowingHandover = true
    
    @State private var showStartingPlayerAnnouncement = false
    @State private var startingPlayer: Player?
    
    // KI-Services
    @StateObject private var hintService = HintService.shared
    
    var body: some View {
        ZStack {
            // Globaler Hintergrund
            ImposterStyle.backgroundGradient
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                ImposterGameHeaderView()
                    .padding(.bottom, 10)
                
                if gameSettings.gamePhase == .cardReveal {
                    // PHASE 1: KARTEN VERTEILEN
                    cardRevealContent
                } else if gameSettings.gamePhase == .playing {
                    // PHASE 2: SPIEL LÄUFT
                    playingContent
                } else if gameSettings.gamePhase == .finished {
                    // PHASE 3: ZEIT ABGELAUFEN (Spione gewinnen)
                    TimeOutResultView()
                        .transition(.opacity)
                }
                
                Spacer()
                
                // Footer (Beenden)
                GameFooterView()
            }
        }
        .onAppear {
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
        .onChange(of: gameSettings.gamePhase) { _, newPhase in
            if newPhase == .finished {
                gameLogic.stopGameTimer()
            } else if newPhase == .cardReveal {
                showStartingPlayerAnnouncement = false
                gameSettings.isTimerPaused = true
                prepareNextCard()
            }
        }
    }
    
    // MARK: - Phase 1: Card Reveal Views
    
    @ViewBuilder
    private var cardRevealContent: some View {
        if isShowingHandover {
            // SICHERHEITS-SCREEN: Handy weitergeben
            SecureHandoverView(
                playerName: gameLogic.currentPlayer?.name ?? "Spieler",
                onReady: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isShowingHandover = false
                    }
                }
            )
            .transition(.opacity)
        } else if let card = currentCard {
            // DIE EIGENTLICHE KARTE (Wird erst angezeigt, wenn Handover bestätigt)
            VStack {
                Spacer()
                SpyCardView(
                    card: card,
                    gameSettings: gameSettings,
                    onCardTap: {
                        gameLogic.markCurrentPlayerCardSeen()
                    },
                    onCardDismissed: {
                        handleCardDismissed()
                    }
                )
                .id(card.id) // Wichtig: Erzwingt Neu-Render bei Kartenwechsel
                Spacer()
            }
            .transition(.scale(scale: 0.95).combined(with: .opacity))
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
        
        if gameSettings.gamePhase == .setup {
            Task { @MainActor in
                await gameLogic.startGame()
                prepareNextCard()
            }
        } else {
            prepareNextCard()
        }
    }
    
    private func prepareNextCard() {
        guard let player = gameLogic.currentPlayer,
              let category = gameSettings.roundCategory ?? gameSettings.selectedCategory else {
            return
        }
        
        // Karte laden, aber erst den Handover-Screen zeigen
        currentCard = GameCard(player: player, category: category)
        isShowingHandover = true
    }
    
    private func handleCardDismissed() {
        gameLogic.nextPlayer()
        
        if gameSettings.gamePhase == .cardReveal {
            // Nächster Spieler ist dran -> Handover Screen wieder aktivieren
            prepareNextCard()
        } else {
            // Alle fertig -> Startspieler wählen
            startingPlayer = gameSettings.players.randomElement()
            gameSettings.isTimerPaused = true
            withAnimation {
                showStartingPlayerAnnouncement = true
            }
        }
    }
    
    private func beginRoundAfterAnnouncement() {
        withAnimation {
            showStartingPlayerAnnouncement = false
        }
        gameSettings.isTimerPaused = false
    }
}

// MARK: - Secure Handover View (Der neue Sicherheits-Screen)
struct SecureHandoverView: View {
    let playerName: String
    let onReady: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Großes animiertes Icon
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 180, height: 180)
                
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    .frame(width: 180, height: 180)
                
                Image(systemName: "iphone.gen3")
                    .font(.system(size: 70))
                    .foregroundColor(.white)
                    .shadow(color: .white.opacity(0.5), radius: 20)
                
                Image(systemName: "arrow.right")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(.orange)
                    .offset(x: 50, y: 0)
            }
            
            VStack(spacing: 12) {
                Text(LocalizedStringKey("Gib das Handy an"))
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.7))
                
                Text(playerName)
                    .font(.system(size: 42, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .shadow(color: .black.opacity(0.5), radius: 10)
            }
            
            Spacer()
            
            ImposterPrimaryButton(title: "Ich bin \(playerName)") {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                onReady()
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial) // Weichzeichner über dem Hintergrund
    }
}

// MARK: - Game Header View
struct ImposterGameHeaderView: View {
    @EnvironmentObject var gameSettings: GameSettings
    
    var body: some View {
        VStack(spacing: 16) {
            // Oberste Zeile: Spione Info & Fortschritt
            HStack {
                if !gameSettings.randomSpyCount {
                    HStack(spacing: 6) {
                        Image(systemName: "eye.slash.fill")
                            .font(.subheadline)
                            .foregroundColor(.red)
                        Text("\(gameSettings.numberOfImposters) \(gameSettings.numberOfImposters == 1 ? "Spion" : "Spione")")
                            .font(.subheadline.bold())
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.red.opacity(0.15))
                    .clipShape(Capsule())
                }
                
                Spacer()
                
                // Rundenstatus (wenn Karten verteilt werden)
                if gameSettings.gamePhase == .cardReveal {
                    Text("\(gameSettings.currentPlayerIndex + 1) / \(gameSettings.players.count)")
                        .font(.subheadline.monospacedDigit())
                        .foregroundColor(.white.opacity(0.5))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            
            // Progress Bar (nur beim Verteilen)
            if gameSettings.gamePhase == .cardReveal {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 4)
                        
                        let progress = Double(gameSettings.currentPlayerIndex) / Double(max(1, gameSettings.players.count))
                        Capsule()
                            .fill(ImposterStyle.primaryGradient)
                            .frame(width: geo.size.width * progress, height: 4)
                            .animation(.spring(), value: progress)
                    }
                }
                .frame(height: 4)
                .padding(.horizontal, 20)
            }
        }
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
            
            ImposterPrimaryButton(title: "Los geht's") {
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
    
    var body: some View {
        VStack(spacing: 30) {
            
            // Timer Display
            VStack(spacing: 15) {
                Text(timeString)
                    .font(.system(size: 80, weight: .bold, design: .monospaced))
                    .foregroundColor(gameSettings.timeRemaining <= 60 ? .red : .white)
                    .shadow(color: gameSettings.timeRemaining <= 60 ? .red.opacity(0.5) : .blue.opacity(0.3), radius: 20)
                    .contentTransition(.numericText())
                
                // Status Badge
                HStack(spacing: 8) {
                    Circle()
                        .fill(gameSettings.isTimerPaused ? Color.orange : Color.green)
                        .frame(width: 8, height: 8)
                    
                    Text(gameSettings.isTimerPaused ? LocalizedStringKey("Pausiert") : LocalizedStringKey("Diskussion läuft"))
                        .font(.caption.bold())
                        .foregroundColor(.white.opacity(0.8))
                        .textCase(.uppercase)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.1))
                .clipShape(Capsule())
            }
            .padding(.top, 40)
            .onTapGesture {
                withAnimation {
                    gameSettings.isTimerPaused.toggle()
                }
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            }
            
            Spacer()
            
            // Action Grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                
                // 1. Abstimmen
                GameActionButton(
                    title: "Abstimmen",
                    icon: "hand.point.up.left.fill",
                    isEnabled: true
                )
                .onTapGesture { showVotingView = true }
                
                // 2. Wort erraten (für Imposter)
                GameActionButton(
                    title: "Wort lösen",
                    icon: "lightbulb.max.fill",
                    isEnabled: true
                )
                .onTapGesture { showWordGuessConfirm = true }
                
                // 3. Pause/Play (Groß über beide Spalten)
                Button {
                    withAnimation { gameSettings.isTimerPaused.toggle() }
                } label: {
                    HStack {
                        Image(systemName: gameSettings.isTimerPaused ? "play.fill" : "pause.fill")
                        Text(gameSettings.isTimerPaused ? LocalizedStringKey("Fortsetzen") : LocalizedStringKey("Pausieren"))
                    }
                    .font(.headline.weight(.bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white.opacity(0.15))
                    )
                }
                .gridCellColumns(2) // Spannt über 2 Spalten
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
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
    
    private var timeString: String {
        let minutes = gameSettings.timeRemaining / 60
        let seconds = gameSettings.timeRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - Game Footer View
struct GameFooterView: View {
    @EnvironmentObject var gameSettings: GameSettings
    @Environment(\.dismiss) private var dismiss
    @State private var showExitConfirmation = false
    
    var body: some View {
        Button {
            showExitConfirmation = true
        } label: {
            Text(LocalizedStringKey("Spiel beenden"))
                .font(.caption.bold())
                .foregroundColor(.red.opacity(0.8))
                .padding(10)
        }
        .padding(.bottom, 10)
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