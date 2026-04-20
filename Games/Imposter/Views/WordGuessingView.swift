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
    private let startWithImmediateWinFlag: Bool

    private var canControlSession: Bool {
        let role = MultipeerManager.shared.role
        return role == .host || role == .unknown
    }
    
    init(gameSettings: GameSettings, startWithImmediateWin: Bool = false) {
        self.gameSettings = gameSettings
        self.startWithImmediateWinFlag = startWithImmediateWin
        let manager = WordGuessingManager(gameSettings: gameSettings)
        self._wordGuessingManager = StateObject(wrappedValue: manager)
    }
    
    var body: some View {
        ZStack {
            ImposterStyle.backgroundGradient.ignoresSafeArea()
            
            // Subtle Grid Background
            VStack(spacing: 0) {
                ForEach(0..<20) { _ in
                    Rectangle()
                        .fill(Color.white.opacity(0.02))
                        .frame(height: 1)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                }
            }
            .ignoresSafeArea()
            
            if let result = wordGuessingManager.guessResult {
                WordGuessResultView(
                    result: result,
                    spies: gameSettings.players.filter { $0.isImposter },
                    onNewGame: {
                        if MultipeerManager.shared.role == .host {
                            gameLogic.startMultiplayerRematchOffer()
                        } else {
                            Task { @MainActor in
                                await gameLogic.restartGame()
                            }
                        }
                    },
                    onExitToMain: {
                        dismiss()
                        // Kurze Verzögerung, damit die WordGuessingView Dismissal-Animation beginnen kann
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            gameSettings.markRoundCompleted()
                            gameSettings.resetGame()
                            gameSettings.requestExitToSetup = true
                            if MultipeerManager.shared.role != .unknown {
                                MultipeerManager.shared.stop()
                            }
                        }
                    },
                    showActions: canControlSession && !gameSettings.multiplayerRematchWaiting
                )
            } else {
                WordGuessingActiveView(wordGuessingManager: wordGuessingManager)
            }
        }
        .task {
            if startWithImmediateWinFlag && wordGuessingManager.guessResult == nil {
                _ = wordGuessingManager.confirmCorrectGuess()
            }
        }
    }
}

// MARK: - Aktive Eingabe ("Terminal" Style)
struct WordGuessingActiveView: View {
    @ObservedObject var wordGuessingManager: WordGuessingManager
    @Environment(\.dismiss) var dismiss
    @State private var showContent = false
    @State private var scanLineY: CGFloat = -100

    var body: some View {
        VStack(spacing: 0) {
            // Terminal Header
            HStack {
                Text("TERMINAL_ACCESS // ID: \(Int.random(in: 1000...9999))")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(.orange.opacity(0.8))
                Spacer()
                Circle()
                    .fill(Color.red)
                    .frame(width: 8, height: 8)
                    .opacity(showContent ? 1 : 0)
                    .animation(.easeInOut(duration: 0.5).repeatForever(), value: showContent)
            }
            .padding(.horizontal, 25)
            .padding(.top, 20)
            
            Spacer()
            
            // Scanner Animation
            ZStack {
                Circle()
                    .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                    .frame(width: 220, height: 220)
                
                Circle()
                    .stroke(Color.orange.opacity(0.1), style: StrokeStyle(lineWidth: 10, dash: [5, 10]))
                    .frame(width: 180, height: 180)
                    .rotationEffect(.degrees(showContent ? 360 : 0))
                    .animation(.linear(duration: 20).repeatForever(autoreverses: false), value: showContent)
                
                Image(systemName: "touchid")
                    .font(.system(size: 80, weight: .thin))
                    .foregroundStyle(.orange)
                    .opacity(0.8)
                
                // Scan Line
                Rectangle()
                    .fill(
                        LinearGradient(colors: [.clear, .orange.opacity(0.5), .clear], startPoint: .top, endPoint: .bottom)
                    )
                    .frame(width: 200, height: 4)
                    .offset(y: scanLineY)
            }
            .frame(height: 250)
            
            VStack(spacing: 20) {
                Text(NSLocalizedString("VERIFIZIERUNG ERFORDERLICH", comment: ""))
                    .font(.system(size: 18, weight: .black, design: .monospaced))
                    .foregroundStyle(.orange)
                    .tracking(2)
                
                Text(NSLocalizedString("Hat der Spion das korrekte Passwort genannt?", comment: ""))
                    .font(.headline)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundStyle(.yellow)
                        Text(NSLocalizedString("WARNUNG", comment: ""))
                            .font(.caption.bold())
                            .foregroundStyle(.yellow)
                    }
                    Text(NSLocalizedString("Eine Bestätigung beendet die Mission sofort.", comment: ""))
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }
                .padding(.horizontal, 40)
            }
            .offset(y: showContent ? 0 : 20)
            .opacity(showContent ? 1 : 0)
            
            Spacer()
            
            // Actions
            VStack(spacing: 16) {
                Button(action: {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    _ = wordGuessingManager.confirmCorrectGuess()
                }) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text(NSLocalizedString("ZUGRIFF BESTÄTIGEN", comment: ""))
                    }
                    .font(.headline.bold())
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color.orange)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .orange.opacity(0.4), radius: 10, x: 0, y: 5)
                }
                
                Button(NSLocalizedString("ABBRECHEN", comment: "")) {
                    dismiss()
                }
                .font(.subheadline.bold())
                .foregroundStyle(.white.opacity(0.4))
                .padding(.top, 5)
            }
            .padding(.horizontal, 25)
            .padding(.bottom, 40)
            .offset(y: showContent ? 0 : 30)
            .opacity(showContent ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                showContent = true
            }
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: true)) {
                scanLineY = 100
            }
        }
    }
}

// MARK: - Ergebnis Anzeige
struct WordGuessResultView: View {
    let result: WordGuessResult
    let spies: [Player]
    let onNewGame: () -> Void
    let onExitToMain: () -> Void
    let showActions: Bool
    
    @EnvironmentObject var gameSettings: GameSettings
    @EnvironmentObject var gameLogic: GameLogic

    @State private var showContent = false
    @State private var revealedText: String = ""
    @State private var glitchEffect = false
    @State private var showPoints = false // Animation State for Points
    @State private var glitchTimer: Timer?

    init(
        result: WordGuessResult,
        spies: [Player],
        onNewGame: @escaping () -> Void,
        onExitToMain: @escaping () -> Void,
        showActions: Bool = true
    ) {
        self.result = result
        self.spies = spies
        self.onNewGame = onNewGame
        self.onExitToMain = onExitToMain
        self.showActions = showActions
    }

    private var waitingMessage: String {
        if MultipeerManager.shared.role == .host {
            return "Warte auf Antworten..."
        }
        return "Warte auf den Host..."
    }
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Status Header
            VStack(spacing: 8) {
                Text(NSLocalizedString("MISSION STATUS", comment: ""))
                    .font(.caption.bold())
                    .tracking(4)
                    .foregroundStyle(.white.opacity(0.5))
                
                Text(NSLocalizedString("KOMPROMITTIERT", comment: ""))
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundStyle(.red)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(Color.red.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.red.opacity(0.3), lineWidth: 1))
            }
            .scaleEffect(showContent ? 1 : 0.9)
            .opacity(showContent ? 1 : 0)
            
            // Spy Icon
            // ... (spy icon code)
            
            // Revealed Word Box
            VStack(spacing: 12) {
                Text(NSLocalizedString("GEHEIMWORT ENTSCHLÜSSELT", comment: ""))
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.red)
                
                HStack(spacing: 0) {
                    Text(revealedText)
                        .font(.system(size: 40, weight: .black, design: .monospaced))
                        .foregroundStyle(.white)
                        .transition(.opacity)
                    
                    // Blinking cursor
                    Rectangle()
                        .fill(Color.red)
                        .frame(width: 12, height: 40)
                        .opacity(revealedText == result.correctWord ? 0 : 1)
                        .animation(.easeInOut(duration: 0.5).repeatForever(), value: revealedText)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 100)
                .background(Color.black.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.1), lineWidth: 1))
                .padding(.horizontal, 25)
            }
            .offset(y: showContent ? 0 : 20)
            .opacity(showContent ? 1 : 0)
            
            Spacer()
            
            // Actions
            if showActions {
                VStack(spacing: 16) {
                    ImposterPrimaryButton(title: NSLocalizedString("NEUE MISSION", comment: "")) {
                        onNewGame()
                    }
                    
                    Button(NSLocalizedString("SPIEL BEENDEN", comment: "")) {
                        onExitToMain()
                    }
                    .font(.caption.bold())
                    .foregroundStyle(.white.opacity(0.4))
                }
                .padding(.horizontal, 25)
                .padding(.bottom, 100)
                .opacity(showContent ? 1 : 0)
            } else {
                Text(waitingMessage)
                    .font(.caption.bold())
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(.bottom, 100)
                    .opacity(showContent ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2)) {
                showContent = true
            }
            
            // Reveal text animation
            revealText(target: result.correctWord)
            
            // Glitch effect loop
            glitchTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { _ in
                withAnimation(.spring(response: 0.1, dampingFraction: 0.1)) {
                    glitchEffect = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    glitchEffect = false
                }
            }
            
            // XP Animation Delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                    showPoints = true
                }
            }
        }
        .alert("Neue Runde?", isPresented: Binding(
            get: { gameSettings.multiplayerRematchOffer != nil },
            set: { newValue in
                if !newValue {
                    gameSettings.multiplayerRematchOffer = nil
                }
            }
        )) {
            Button("Nein", role: .destructive) {
                gameLogic.sendRematchResponse(wantsRematch: false)
            }
            Button("Ja") {
                gameLogic.sendRematchResponse(wantsRematch: true)
            }
        } message: {
            Text("Der Host möchte eine neue Runde starten.")
        }
        .onDisappear {
            glitchTimer?.invalidate()
            glitchTimer = nil
        }
    }

    private func revealText(target: String) {
        let chars = Array(target)
        var currentIndex = 0
        
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            if currentIndex < chars.count {
                revealedText += String(chars[currentIndex])
                UISelectionFeedbackGenerator().selectionChanged()
                currentIndex += 1
            } else {
                timer.invalidate()
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            }
        }
    }
}
