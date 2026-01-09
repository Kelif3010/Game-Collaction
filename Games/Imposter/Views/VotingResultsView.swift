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
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var gameLogic: GameLogic
    
    @State private var showContent = false
    @State private var showStamp = false
    @State private var radarRotation = 0.0
    @State private var showPoints = false // Animation State for Points
    
    private var isVictory: Bool {
        votingManager.playersWon
    }
    
    private var isRescue: Bool {
        return votingManager.lastRescueMessage != nil
    }
    
    private var eliminatedSpies: [Player] {
        let selected = votingManager.selectedPlayers
        return gameSettings.players.filter { selected.contains($0.id) && $0.isImposter }
    }

    var body: some View {
        ZStack {
            ImposterStyle.backgroundGradient.ignoresSafeArea()
            
            // Background Radar Animation
            GeometryReader { geo in
                ZStack {
                    ForEach(0..<3) { i in
                        Circle()
                            .stroke(Color.white.opacity(0.03), lineWidth: 1)
                            .frame(width: geo.size.width * (0.5 + Double(i) * 0.3))
                    }
                    
                    AngularGradient(gradient: Gradient(colors: [.clear, (isVictory || isRescue) ? .green.opacity(0.1) : .red.opacity(0.1), .clear]), center: .center)
                        .rotationEffect(.degrees(radarRotation))
                        .frame(width: geo.size.width * 1.5, height: geo.size.width * 1.5)
                        .blur(radius: 20)
                }
                .position(x: geo.size.width / 2, y: geo.size.height * 0.4)
            }
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Bar
                HStack {
                    Text("MISSION REPORT // \(Date().formatted(date: .numeric, time: .omitted))")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.4))
                        .padding(8)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(4)
                }
                .padding(.top, 20)
                
                Spacer()
                
                // Main Status
                ZStack {
                    if isRescue {
                        // RESCUE UI
                        Image(systemName: "shield.lefthalf.filled")
                            .font(.system(size: 80))
                            .foregroundColor(.green.opacity(0.3))
                            .blur(radius: 10)
                            .scaleEffect(showContent ? 1 : 0.8)
                        
                        Image(systemName: "shield.lefthalf.filled")
                            .font(.system(size: 80))
                            .foregroundColor(.green)
                            .shadow(color: .green.opacity(0.5), radius: 20)
                            .scaleEffect(showContent ? 1 : 0.8)
                        
                        if showStamp {
                            Text("GERETTET")
                                .font(.system(size: 42, weight: .black, design: .rounded))
                                .foregroundColor(.green)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.green, lineWidth: 6)
                                )
                                .background(Color.black.opacity(0.01))
                                .rotationEffect(.degrees(-12))
                                .scaleEffect(1.2)
                                .transition(.scale.combined(with: .opacity))
                        }
                    } else {
                        // STANDARD UI
                        Image(systemName: isVictory ? "shield.checkered" : "exclamationmark.triangle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(isVictory ? .green.opacity(0.3) : .red.opacity(0.3))
                            .blur(radius: 10)
                            .scaleEffect(showContent ? 1 : 0.8)
                        
                        Image(systemName: isVictory ? "shield.checkered" : "exclamationmark.triangle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(isVictory ? .green : .red)
                            .shadow(color: isVictory ? .green.opacity(0.5) : .red.opacity(0.5), radius: 20)
                            .scaleEffect(showContent ? 1 : 0.8)
                        
                        if showStamp {
                            Text(isVictory ? "ERFOLG" : "FEHLSCHLAG")
                                .font(.system(size: 42, weight: .black, design: .rounded))
                                .foregroundColor(isVictory ? .green : .red)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(isVictory ? Color.green : Color.red, lineWidth: 6)
                                )
                                .mask(
                                    Image("grunge_texture") // Fallback to plain if texture missing
                                        .resizable()
                                        .scaledToFill()
                                        .opacity(0.9)
                                )
                                .background(Color.black.opacity(0.01))
                                .rotationEffect(.degrees(-12))
                                .scaleEffect(1.2)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                    
                    // XP Animation
                    if showPoints && !isRescue { // Keine Punkte bei Rettung, Spiel geht weiter
                        VStack(spacing: 0) {
                            Text("+10 XP") 
                                .font(.system(size: 24, weight: .black))
                                .foregroundColor(isVictory ? .green : .red)
                                .shadow(color: isVictory ? .green.opacity(0.5) : .red.opacity(0.5), radius: 2)
                            
                            Text(isVictory ? "TEAM BÜRGER" : "TEAM SPION")
                                .font(.caption.bold())
                                .foregroundColor(isVictory ? .green.opacity(0.8) : .red.opacity(0.8))
                                .padding(.top, 2)
                        }
                        .offset(y: -90)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .frame(height: 200)
                .padding(.bottom, 20)
                
                // Narrative Text
                VStack(spacing: 12) {
                    if isRescue {
                        Text("Einsatz erfolgreich")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                            .tracking(1)
                        
                        Text(votingManager.lastRescueMessage ?? "Der Leibwächter hat eingegriffen.")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                            .padding(.horizontal, 40)
                    } else {
                        Text(isVictory ? "Bedrohung Neutralisiert" : "Sicherheitsbruch")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                            .tracking(1)
                        
                        Text(isVictory ? "Hervorragende Arbeit. Die Spione wurden identifiziert und aus dem System entfernt." : "Die Spione haben unsere Reihen infiltriert. Mission abgebrochen.")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                            .padding(.horizontal, 40)
                    }
                }
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)
                
                Spacer()
                
                // Identified Agents Section (Only show if game ended, not on rescue)
                if !isRescue {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "person.crop.circle.badge.exclamationmark")
                                .foregroundColor(isVictory ? .green : .red)
                            Text("IDENTIFIZIERTE AGENTEN")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .padding(.horizontal, 30)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(gameSettings.players.filter { $0.isImposter }) { player in
                                    ImposterResultCard(player: player, isRevealed: true, isVictory: isVictory)
                                        .frame(width: 150)
                                }
                            }
                            .padding(.horizontal, 30)
                        }
                    }
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 30)
                }
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 16) {
                    if isRescue {
                        ImposterPrimaryButton(title: "WEITERSPIELEN") {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            // Zurück zum Spiel, Timer läuft weiter (wurde pausiert)
                            votingManager.resetForNextRound()
                            votingManager.restoreTimerState()
                            onContinueToGameplay()
                        }
                    } else {
                        if !votingManager.gameEnded && votingManager.remainingSpies > 0 {
                            ImposterPrimaryButton(title: "MISSION FORTSETZEN") {
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                let previouslyFound = votingManager.foundSpies
                                let eliminatedIDs = Set(eliminatedSpies.map { $0.id })
                                votingManager.resetForNextRound()
                                votingManager.foundSpies = previouslyFound.union(eliminatedIDs)
                                votingManager.restoreTimerState()
                                onContinueToGameplay()
                            }
                        }
                        
                        ImposterPrimaryButton(title: "NEUES SPIEL") {
                            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                            Task { @MainActor in
                                await gameLogic.restartGame()
                                onNewGame()
                            }
                        }
                        
                        Button {
                            gameSettings.requestExitToMain = true
                            dismiss()
                        } label: {
                            HStack {
                                Image(systemName: "chevron.left")
                                Text("HAUPTMENÜ")
                            }
                            .font(.caption.bold())
                            .foregroundColor(.white.opacity(0.5))
                            .padding(10)
                        }
                    }
                }
                .padding(.horizontal, 25)
                .padding(.bottom, 20)
                .opacity(showContent ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                radarRotation = 360
            }
            
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2)) {
                showContent = true
            }
            
            withAnimation(.spring(response: 0.4, dampingFraction: 0.5).delay(0.8)) {
                showStamp = true
            }
            
            // XP Animation Delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                    showPoints = true
                }
            }
        }
    }
}

struct ImposterResultCard: View {
    let player: Player
    var isRevealed: Bool
    var isVictory: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(isVictory ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                    .frame(width: 60, height: 60)
                
                Text(String(player.name.prefix(1)).uppercased())
                    .font(.title2.bold())
                    .foregroundColor(isVictory ? .green : .red)
                
                if isVictory {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .background(Circle().fill(.black))
                        .offset(x: 20, y: 20)
                }
            }
            
            VStack(spacing: 4) {
                Text(player.name)
                    .font(.headline)
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text("IMPOSTER")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(isVictory ? .green : .red)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background((isVictory ? Color.green : Color.red).opacity(0.2))
                    .cornerRadius(4)
            }
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.03))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isVictory ? Color.green.opacity(0.2) : Color.red.opacity(0.2), lineWidth: 1)
        )
    }
}
