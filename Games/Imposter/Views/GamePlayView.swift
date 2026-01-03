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
    @State private var showingNextCardPreparation = false
    @State private var showStartingPlayerAnnouncement = false
    @State private var startingPlayer: Player?
    
    // KI-Services
    @StateObject private var hintService = HintService.shared
    
    var body: some View {
        ZStack {
            // Hintergrund-Gradient
            LinearGradient(
                colors: [Color.black.opacity(0.8), Color.gray.opacity(0.6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header mit Spielinformationen
                ImposterGameHeaderView()
                
                Spacer()
                
                if gameSettings.gamePhase == .cardReveal {
                    // Karten-Aufdeckungsphase
                    if let card = currentCard {
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
                        .id(card.id) // Erzwingt neue View-Instanz bei Kartenwechsel
                    } else {
                        // Laden...
                        ProgressView("Spiel wird vorbereitet...")
                            .foregroundColor(.white)
                            .font(.headline)
                    }
                } else if gameSettings.gamePhase == .playing {
                    // Aktive Spielphase
                    if showStartingPlayerAnnouncement {
                        StartingPlayerAnnouncementView(player: startingPlayer) {
                            beginRoundAfterAnnouncement()
                        }
                    } else {
                        ZStack {
                            GameTimerView()
                            // KI-Overlays
                            VStack {
                                Spacer()
                                HStack {
                                    Spacer()
                                    HintOverlay(hintService: hintService)
                                }
                            }
                        }
                    }
                }
                
                Spacer()
                
                // Footer mit Fortschritt und Kontrollen
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
                print("[GamePlayView] gamePhase changed to .finished")
                gameLogic.stopGameTimer()
            } else if newPhase == .cardReveal {
                showStartingPlayerAnnouncement = false
                gameSettings.isTimerPaused = true
                loadCurrentCard()
            }
        }
        .onChange(of: gameSettings.currentPlayerIndex) { _, _ in
            if gameSettings.gamePhase == .cardReveal {
                loadCurrentCard()
            }
        }
    }
    
    // MARK: - Game Management
    
    private func startGame() {
        print("🎮 GamePlayView.startGame() aufgerufen")
        print("📊 gamePhase: \(gameSettings.gamePhase)")
        print("👥 Spieler: \(gameSettings.players.map { "\($0.name) (\($0.isImposter ? "Spion" : "Normal"))" })")
        
        // Timer stoppen falls er läuft
        gameLogic.stopGameTimer()
        
        // Prüfen ob das Spiel bereits gestartet wurde (Spione bereits ausgewählt)
        if gameSettings.gamePhase == .setup {
            print("🔄 Spiel noch nicht gestartet, rufe gameLogic.startGame() auf")
            Task { @MainActor in
                await gameLogic.startGame()
                showingNextCardPreparation = false
                loadCurrentCard()
            }
        } else {
            print("✅ Spiel bereits gestartet, überspringe gameLogic.startGame()")
            showingNextCardPreparation = false
            loadCurrentCard()
        }
    }
    
    private func loadCurrentCard() {
        guard let player = gameLogic.currentPlayer,
              let category = gameSettings.roundCategory ?? gameSettings.selectedCategory else {
            return
        }
        
        currentCard = GameCard(player: player, category: category)
    }
    
    private func handleCardDismissed() {
        gameLogic.nextPlayer()
        
        if gameSettings.gamePhase == .cardReveal {
            // Noch mehr Spieler warten - direkt zur nächsten Karte
            showingNextCardPreparation = false
            // Neue Karte direkt laden (kein nil nötig, da .id(card.id) die View neu erstellt)
            loadCurrentCard()
        } else {
            // Alle Karten wurden gezeigt – Startspieler bestimmen und ankündigen
            startingPlayer = gameSettings.players.randomElement()
            gameSettings.isTimerPaused = true
            showStartingPlayerAnnouncement = true
        }
    }
    
    private func showCurrentCard() {
        showingNextCardPreparation = false
        loadCurrentCard()
    }
    
    private func beginRoundAfterAnnouncement() {
        showStartingPlayerAnnouncement = false
        gameSettings.isTimerPaused = false
    }
}

// MARK: - Game Header View
struct ImposterGameHeaderView: View {
    @EnvironmentObject var gameSettings: GameSettings
    
    var spyCountText: String {
        let count = gameSettings.numberOfImposters
        if count == 1 {
            return "\(count) Spion"
        } else {
            return "\(count) Spione"
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                // Spion-Anzahl (links, rot) nur anzeigen, wenn keine zufällige Anzahl aktiv ist
                if !gameSettings.randomSpyCount {
                    HStack(spacing: 8) {
                        Image(systemName: "eye.slash.fill")
                            .font(.title2)
                            .foregroundColor(.red)
                        Text(spyCountText)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.red)
                    }
                }
                
                Spacer()
                
                // Rechte Seite bleibt leer (keine Kategorie mehr)
            }
            
            // Fortschrittsbalken
            if gameSettings.gamePhase == .cardReveal {
                ProgressView(
                    value: Double(gameSettings.currentPlayerIndex),
                    total: Double(gameSettings.players.count)
                )
                .progressViewStyle(LinearProgressViewStyle(tint: .orange))
                .scaleEffect(x: 1, y: 2, anchor: .center)
                
                Text("Spieler \(gameSettings.currentPlayerIndex + 1) von \(gameSettings.players.count)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }
}

// MARK: - Next Player Preparation View
struct NextPlayerPreparationView: View {
    let nextPlayer: Player?
    let onContinue: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            VStack(spacing: 15) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 5)
                
                if let player = nextPlayer {
                    Text("Nächster Spieler:")
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text(player.name)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.5), radius: 5)
                } else {
                    Text("Alle Spieler haben ihre Karten gesehen!")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .shadow(color: .black.opacity(0.5), radius: 5)
                }
            }
            
            Button("Bereit? Antippen!") {
                onContinue()
            }
            .font(.title2)
            .fontWeight(.semibold)
            .foregroundColor(.black)
            .padding(.horizontal, 30)
            .padding(.vertical, 15)
            .background(Color.white)
            .cornerRadius(25)
            .shadow(color: .black.opacity(0.3), radius: 5)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Starting Player Announcement View
struct StartingPlayerAnnouncementView: View {
    let player: Player?
    let onContinue: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            VStack(spacing: 15) {
                Image(systemName: "flag.checkered")
                    .font(.system(size: 80))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 5)
                
                if let player = player {
                    Text("Startspieler:")
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.8))
                    Text(player.name)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.5), radius: 5)
                } else {
                    Text("Startspieler wird bestimmt…")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .shadow(color: .black.opacity(0.5), radius: 5)
                }
            }
            
            Button("Los geht’s") {
                onContinue()
            }
            .font(.title2)
            .fontWeight(.semibold)
            .foregroundColor(.black)
            .padding(.horizontal, 30)
            .padding(.vertical, 15)
            .background(Color.white)
            .cornerRadius(25)
            .shadow(color: .black.opacity(0.3), radius: 5)
            
            Text("Der ausgewählte Spieler beginnt die Runde. Danach startet der Timer.")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Game Timer View
struct GameTimerView: View {
    @EnvironmentObject var gameSettings: GameSettings
    @EnvironmentObject var gameLogic: GameLogic
    @State private var showVotingView = false
    @State private var showWordGuessingView = false
    @State private var showWordGuessConfirm = false
    @State private var startWordGuessImmediateWin = false
    @State private var wasTimerPausedBeforeWordGuess = false
    
    var body: some View {
        VStack(spacing: 40) {
            VStack(spacing: 20) {
                Image(systemName: "clock.circle.fill")
                    .font(.system(size: 100))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 10)
                
                Text("SPIEL LÄUFT")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.5), radius: 5)
            }
            
            // Timer Display
            VStack(spacing: 10) {
                Text(timeString)
                    .font(.system(size: 60, weight: .bold, design: .monospaced))
                    .foregroundColor(gameSettings.timeRemaining <= 60 ? .red : .white)
                    .shadow(color: .black.opacity(0.5), radius: 5)
                    .scaleEffect(gameSettings.timeRemaining <= 10 ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.5), value: gameSettings.timeRemaining)
                
                // Timer Kontrollen
                VStack(spacing: 12) {
                    // Pause/Resume Button
                    Button(action: {
                        gameSettings.isTimerPaused.toggle()
                    }) {
                        HStack {
                            Image(systemName: gameSettings.isTimerPaused ? "play.fill" : "pause.fill")
                            Text(gameSettings.isTimerPaused ? "Fortsetzen" : "Pausieren")
                        }
                        .font(.headline)
                        .foregroundColor(.black)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.white)
                        .cornerRadius(20)
                        .shadow(color: .black.opacity(0.3), radius: 5)
                    }
                    
                    // Button-Grid für Abstimmen und Wort erraten
                    HStack(spacing: 12) {
                        // Abstimmen Button
                        Button(action: {
                            showVotingView = true
                        }) {
                            VStack(spacing: 5) {
                                Image(systemName: "hand.point.up.fill")
                                    .font(.title3)
                                Text("Abstimmen")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 15)
                            .padding(.vertical, 12)
                            .background(
                                LinearGradient(
                                    colors: [Color.orange, Color.red],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(15)
                            .shadow(color: .black.opacity(0.3), radius: 3)
                        }
                        
                        // Wort erraten Button
                        Button(action: {
                            showWordGuessConfirm = true
                        }) {
                            VStack(spacing: 5) {
                                Image(systemName: "lightbulb.fill")
                                    .font(.title3)
                                Text("Wort erraten")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 15)
                            .padding(.vertical, 12)
                            .background(
                                LinearGradient(
                                    colors: [Color.yellow, Color.orange],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(15)
                            .shadow(color: .black.opacity(0.3), radius: 3)
                        }
                        
                    }
                }
            }
            
            Text("Diskutieren Sie und finden Sie die Imposter!")
                .font(.title3)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
        }
        .sheet(isPresented: $showVotingView) {
            VotingView(gameSettings: gameSettings)
                .environmentObject(gameLogic)
                .interactiveDismissDisabled(true)
        }
        .alert("Hat der Spion das Wort richtig erraten?", isPresented: $showWordGuessConfirm) {
            Button("Nein", role: .cancel) {
                // Do nothing
            }
            Button("Ja") {
                wasTimerPausedBeforeWordGuess = gameSettings.isTimerPaused
                gameSettings.isTimerPaused = true
                startWordGuessImmediateWin = true
                showWordGuessingView = true
                print("[GameTimerView] Wort erraten -> showWordGuessingView=true, immediateWin=true")
            }
        } message: {
            Text("Bestätige nur, wenn das Wort korrekt genannt wurde.")
        }
        .fullScreenCover(isPresented: $showWordGuessingView, onDismiss: {
            // Dismiss wird jetzt nur noch aus der Result-View ausgelöst
            print("[GameTimerView] WordGuessingView dismissed; gamePhase=\(gameSettings.gamePhase)")
        }) {
            WordGuessingView(gameSettings: gameSettings, startWithImmediateWin: startWordGuessImmediateWin)
                .environmentObject(gameLogic)
                .interactiveDismissDisabled(true)
                .onAppear {
                    print("[GameTimerView] WordGuessingView presented. gamePhase=\(gameSettings.gamePhase)")
                }
                .onDisappear {
                    if !wasTimerPausedBeforeWordGuess {
                        gameSettings.isTimerPaused = false
                    }
                    startWordGuessImmediateWin = false
                    wasTimerPausedBeforeWordGuess = false
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
        VStack(spacing: 15) {
            // Nur Beenden Button
            Button("Spiel beenden") {
                showExitConfirmation = true
            }
            .font(.headline)
            .foregroundColor(.white)
            .padding(.horizontal, 30)
            .padding(.vertical, 12)
            .background(Color.red.opacity(0.8))
            .cornerRadius(20)
            .padding(.bottom, 20)
        }
        .confirmationDialog(
            "Spiel wirklich beenden?",
            isPresented: $showExitConfirmation
        ) {
            Button("Abbrechen", role: .cancel) { }
            Button("Spiel beenden", role: .destructive) {
                gameSettings.markRoundCompleted()
                gameSettings.resetGame()
                dismiss()
            }
        } message: {
            Text("Bist du dir sicher, dass du das Spiel beenden willst?")
        }
    }
}

#Preview {
    let settings = GameSettings()
    settings.players = [
        Player(name: "Alice"),
        Player(name: "Bob"),
        Player(name: "Charlie")
    ]
    settings.selectedCategory = Category.defaultCategories[0]
    settings.numberOfImposters = 1
    let logic = GameLogic(gameSettings: settings)
    
    return GamePlayView()
        .environmentObject(settings)
        .environmentObject(logic)
}
