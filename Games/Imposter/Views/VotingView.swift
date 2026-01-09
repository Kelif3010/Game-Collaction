//
//  VotingView.swift
//  Imposter
//
//  Created by Ken on 23.09.25.
//

import SwiftUI

struct VotingView: View {
    @ObservedObject var gameSettings: GameSettings
    @StateObject private var votingManager: VotingManager
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    init(gameSettings: GameSettings) {
        self.gameSettings = gameSettings
        self._votingManager = StateObject(wrappedValue: VotingManager(gameSettings: gameSettings))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Hintergrund
                LinearGradient(
                    colors: [Color.red.opacity(0.15), Color.orange.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                if votingManager.isSpyShootoutActive, let shooter = votingManager.shooter {
                    SpyShootoutView(
                        shooter: shooter,
                        gameSettings: gameSettings,
                        onHit: { target in
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
                        onMiss: { target in
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
                } else {
                    VotingActiveView(
                        votingManager: votingManager,
                        gameSettings: gameSettings
                    )
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                // Titel in der Mitte
                ToolbarItem(placement: .principal) {
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
                }
                
                // MARK: - Punkt 1: Schließen Button (X) oben rechts
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
        .onAppear {
            if !votingManager.isVotingActive && !votingManager.showResults {
                votingManager.startVoting()
            }
        }
        .onDisappear {
            // Timer-Status wiederherstellen wenn Voting-View geschlossen wird
            if !votingManager.showResults {
                votingManager.restoreTimerState()
            }
        }
    }
}

// MARK: - Aktive Abstimmung
struct VotingActiveView: View {
    @ObservedObject var votingManager: VotingManager
    let gameSettings: GameSettings
    
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
            
            // MARK: - Punkt 2: Layout Umbau (VStack statt safeAreaInset für Header)
            VStack(spacing: 0) {
                
                // Fixierter Header Bereich
                VStack(spacing: 6) {
                    Text("Wer ist der Imposter?")
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white)
                    
                    Text("Besprecht in der Gruppe und stimmt für die Eliminierung von genau einem Spieler ab.")
                        .font(.subheadline) // Etwas kleiner für bessere Lesbarkeit
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 20)
                }
                .padding(.top, 20)
                .padding(.bottom, 20)
                // Leichter Hintergrund für den Header, damit er sich abhebt (optional)
                .background(Color.black.opacity(0.01))
                
                // Scrollbarer Bereich beginnt erst HIER
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 16),
                        GridItem(.flexible(), spacing: 16)
                    ], spacing: 16) {
                        ForEach(gameSettings.players.filter { !votingManager.foundSpies.contains($0.id) }) { player in
                            VotingPlayerCard(
                                player: player,
                                votingManager: votingManager,
                                gameSettings: gameSettings
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 120) // Viel Platz unten für den Button
                }
            }
        }
        // Button bleibt unten fixiert ("sticky")
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 10) {
                Button {
                    let _ = votingManager.executeVote()
                    votingManager.finishVoting()
                } label: {
                    Text("Abstimmen")
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
            // Hintergrund für den Button-Bereich, damit man Text darunter nicht durchsieht
            .background(
                LinearGradient(colors: [.black.opacity(0), .black.opacity(0.8), .black], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
            )
        }
    }
}

// MARK: - Spieler-Karte für Abstimmung
struct VotingPlayerCard: View {
    let player: Player
    @ObservedObject var votingManager: VotingManager
    let gameSettings: GameSettings
    @State private var isPressed = false
    
    private var isSelected: Bool {
        votingManager.selectedPlayers.contains(player.id)
    }
    
    private var isSpyAlreadyFound: Bool {
        votingManager.foundSpies.contains(player.id)
    }
    
    private var canBeSelected: Bool {
        return !isSpyAlreadyFound && (isSelected || votingManager.canSelectMore)
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
                withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                    votingManager.togglePlayerSelection(player.id)
                }
            }
        }) {
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
}
