//
//  WordGuessingView.swift
//  Imposter
//
//  Created by Ken on 23.09.25.
//

import SwiftUI

struct WordGuessingView: View {
    @ObservedObject var gameSettings: GameSettings
    @StateObject private var wordGuessingManager: WordGuessingManager
    @EnvironmentObject var gameLogic: GameLogic
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    private let startWithImmediateWinFlag: Bool
    
    init(gameSettings: GameSettings, startWithImmediateWin: Bool = false) {
        self.gameSettings = gameSettings
        self.startWithImmediateWinFlag = startWithImmediateWin
        let manager = WordGuessingManager(gameSettings: gameSettings)
        self._wordGuessingManager = StateObject(wrappedValue: manager)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Hintergrund
                LinearGradient(
                    colors: [Color.orange.opacity(0.15), Color.yellow.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                if let result = wordGuessingManager.guessResult {
                    WordGuessResultView(
                        result: result,
                        spies: gameSettings.players.filter { $0.isImposter },
                        canStartNewMission: gameSettings.gamePhase == .finished || result.gameEnded,
                        onNewGame: {
                            // Option A: Starte direkt eine neue Runde und schließe diese Ansicht
                            Task { @MainActor in
                                await gameLogic.restartGame()
                            }
                        },
                        onExitToMain: {
                            // Signalisiere der GamePlayView, dass bis ins Hauptmenü navigiert werden soll
                            gameSettings.requestExitToMain = true
                        }
                    )
                } else {
                    WordGuessingActiveView(wordGuessingManager: wordGuessingManager, gameSettings: gameSettings)
                }
            }
            .navigationTitle("💡 Wort erraten")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarBackButtonHidden(true)
        }
        .task {
            // Sicherstellen, dass das Ergebnis gesetzt wird, wenn sofortiger Sieg bestätigt wurde
            if startWithImmediateWinFlag && wordGuessingManager.guessResult == nil {
                await MainActor.run {
                    print("[WordGuessingView] startWithImmediateWinFlag true, setting guessResult")
                    _ = wordGuessingManager.confirmCorrectGuess()
                }
            }
        }
        .onDisappear {
            print("[WordGuessingView] disappeared. guessResult=\(wordGuessingManager.guessResult != nil), gamePhase=\(gameSettings.gamePhase), requestExitToMain=\(gameSettings.requestExitToMain)")
        }
    }
}



// MARK: - Ergebnis-Anzeige
struct WordGuessResultView: View {
    let result: WordGuessResult
    let spies: [Player]
    let canStartNewMission: Bool
    let onNewGame: () -> Void
    let onExitToMain: () -> Void
    @State private var showContent = false
    @State private var laserOffset: CGFloat = -100
    @State private var fogOpacity: Double = 0
    @State private var pulseScale: CGFloat = 1.0
    @State private var textGlow: Double = 0
    
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                // Düsterer Hintergrund mit Nebel-Effekt
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
                
                // Roter Laser-Effekt
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.clear,
                                Color.red.opacity(0.8),
                                Color.red.opacity(0.3),
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
                
                // Nebel-Effekt
                ForEach(0..<5, id: \.self) { index in
                    Circle()
                        .fill(Color.red.opacity(0.05))
                        .frame(width: CGFloat.random(in: 100...300))
                        .position(
                            x: CGFloat.random(in: 0...proxy.size.width),
                            y: CGFloat.random(in: 0...proxy.size.height)
                        )
                        .opacity(fogOpacity)
                        .animation(
                            Animation.easeInOut(duration: Double.random(in: 3...6))
                                .repeatForever(autoreverses: true),
                            value: fogOpacity
                        )
                }
                
                ScrollView {
                    VStack(spacing: 30) {
                        // Spion-Symbol mit Animation
                        ZStack {
                            // Pulsierender Ring
                            Circle()
                                .stroke(
                                    Color.red.opacity(0.6),
                                    lineWidth: 3
                                )
                                .frame(width: 140, height: 140)
                                .scaleEffect(pulseScale)
                                .animation(
                                    Animation.easeInOut(duration: 1.5)
                                        .repeatForever(autoreverses: true),
                                    value: pulseScale
                                )
                            
                            // Spion-Symbol
                            Image(systemName: "eye.trianglebadge.exclamationmark.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.red)
                                .shadow(color: .red.opacity(0.8), radius: 10)
                        }
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : -50)
                        .animation(.easeOut(duration: 0.8), value: showContent)
                        
                        // Titel mit Glow-Effekt
                        VStack(spacing: 8) {
                            Text("MISSION ACCOMPLISHED")
                                .font(.title)
                                .fontWeight(.black)
                                .foregroundColor(.red)
                                .shadow(color: .red.opacity(textGlow), radius: 20)
                                .opacity(showContent ? 1 : 0)
                                .animation(.easeOut(duration: 0.8).delay(0.2), value: showContent)
                            
                            Text("Der Spion hat das Wort erraten")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.8))
                                .opacity(showContent ? 1 : 0)
                                .animation(.easeOut(duration: 0.8).delay(0.4), value: showContent)
                        }
                        
                        // Wort-Enthüllung mit dramatischem Effekt
                        VStack(spacing: 15) {
                            Text("Das geheime Wort war:")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                                .opacity(showContent ? 1 : 0)
                                .animation(.easeOut(duration: 0.8).delay(0.6), value: showContent)
                            
                            Text(result.correctWord)
                                .font(.system(size: 36, weight: .black, design: .rounded))
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 15)
                                .background(
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(Color.black.opacity(0.7))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 15)
                                                .stroke(Color.red, lineWidth: 2)
                                        )
                                        .shadow(color: .red.opacity(0.5), radius: 10)
                                )
                                .scaleEffect(showContent ? 1 : 0.5)
                                .opacity(showContent ? 1 : 0)
                                .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.8), value: showContent)
                        }
                        
                        if !spies.isEmpty {
                            VStack(spacing: 8) {
                                Text("Die Spione waren:")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.7))
                                    .opacity(showContent ? 1 : 0)
                                    .animation(.easeOut(duration: 0.8).delay(0.9), value: showContent)
                                
                                ForEach(spies, id: \.id) { spy in
                                    Text(spy.name)
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(.white.opacity(0.08))
                                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                        .opacity(showContent ? 1 : 0)
                                        .animation(.easeOut(duration: 0.8).delay(1.0), value: showContent)
                                }
                            }
                            .padding(.top, 4)
                        }
                        
                        // Action Buttons mit Hover-Effekt
                        VStack(spacing: 15) {
                            if canStartNewMission {
                                Button(action: onNewGame) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "arrow.clockwise")
                                            .font(.title2)
                                        Text("Neue Mission")
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
                                                    colors: [Color.red, Color.red.opacity(0.8)],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                            .shadow(color: .red.opacity(0.5), radius: 10)
                                    )
                                }
                                .scaleEffect(showContent ? 1 : 0.8)
                                .opacity(showContent ? 1 : 0)
                                .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(1.0), value: showContent)
                            } else {
                                Text("Die aktuelle Runde läuft noch. Abschließen, um eine neue Mission zu starten.")
                                    .font(.footnote)
                                    .foregroundColor(.white.opacity(0.7))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 20)
                                    .scaleEffect(showContent ? 1 : 0.95)
                                    .opacity(showContent ? 1 : 0)
                                    .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(1.0), value: showContent)
                            }
                            
                            Button(action: onExitToMain) {
                                HStack(spacing: 12) {
                                    Image(systemName: "xmark")
                                        .font(.title2)
                                    Text("Mission beenden")
                                        .font(.headline)
                                        .fontWeight(.bold)
                                }
                                .foregroundColor(.white.opacity(0.8))
                                .padding(.horizontal, 30)
                                .padding(.vertical, 15)
                                .background(
                                    RoundedRectangle(cornerRadius: 25)
                                        .fill(Color.black.opacity(0.6))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 25)
                                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                        )
                                )
                            }
                            .scaleEffect(showContent ? 1 : 0.8)
                            .opacity(showContent ? 1 : 0)
                            .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(1.2), value: showContent)
                        }
                        .padding(.top, 20)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 40)
                }
            }
            .background(
                Color.clear
                    .onAppear {
                        // Animationen starten
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
            )
        }
    }
}

// MARK: - Aktive Wort-Raten Ansicht
struct WordGuessingActiveView: View {
    @ObservedObject var wordGuessingManager: WordGuessingManager
    @ObservedObject var gameSettings: GameSettings
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            // Hintergrund ähnlich wie in der Ergebnis-Ansicht, aber neutraler
            LinearGradient(
                colors: [
                    Color.black,
                    Color.orange.opacity(0.1),
                    Color.black
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                // Header/Icon
                VStack(spacing: 12) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.yellow)
                        .shadow(color: .yellow.opacity(0.6), radius: 10)

                    Text("WORT RATEN")
                        .font(.title)
                        .fontWeight(.black)
                        .foregroundColor(.white)
                }

                Text("Bestätige hier, wenn der Spion das richtige Wort genannt hat. Oder brich ab, um zur Diskussion zurückzukehren.")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                // Aktionen
                VStack(spacing: 12) {
                    Button(action: {
                        _ = wordGuessingManager.confirmCorrectGuess()
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title2)
                            Text("Richtiges Wort bestätigt")
                                .font(.headline)
                                .fontWeight(.bold)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 22)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.green, Color.green.opacity(0.85)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .shadow(color: .green.opacity(0.4), radius: 10, y: 5)
                        )
                    }

                    Button(action: {
                        dismiss()
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                            Text("Abbrechen")
                                .font(.headline)
                                .fontWeight(.bold)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 22)
                                .fill(Color.black.opacity(0.6))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 22)
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                }
            }
            .padding(.vertical, 40)
        }
    }
}


#Preview {
    let gameSettings = GameSettings()
    gameSettings.players = [
        Player(name: "Max"),
        Player(name: "Anna"),
        Player(name: "Tom")
    ]
    gameSettings.players[0].isImposter = true
    gameSettings.players[1].word = "Hund"
    gameSettings.players[2].word = "Hund"
    gameSettings.selectedCategory = Category.defaultCategories[0]

    return WordGuessingView(gameSettings: gameSettings)
        .environmentObject(GameLogic(gameSettings: gameSettings))
}
