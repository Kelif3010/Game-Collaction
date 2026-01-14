//
//  VotingResultsView.swift
//  Imposter
//
//  Created by Ken on 23.09.25.
//

import SwiftUI
import MultipeerConnectivity

// MARK: - Glitch Effect
struct GlitchModifier: ViewModifier {
    let intensity: Double
    let active: Bool
    
    @State private var offset1: CGFloat = 0
    @State private var offset2: CGFloat = 0
    @State private var sliceHeight: CGFloat = 0
    @State private var sliceOffset: CGFloat = 0
    
    func body(content: Content) -> some View {
        ZStack {
            if active {
                content
                    .foregroundColor(.red)
                    .offset(x: offset1)
                    .opacity(0.7)
                    .blendMode(.screen)
                
                content
                    .foregroundColor(.blue)
                    .offset(x: offset2)
                    .opacity(0.7)
                    .blendMode(.overlay)
                
                content
                    .mask(
                        Rectangle()
                            .padding(.top, sliceOffset)
                            .padding(.bottom, 100 - sliceOffset - sliceHeight)
                    )
                    .offset(x: offset1 * 2)
            }
            content
        }
        .onAppear {
            if active {
                startGlitchLoop()
            }
        }
    }
    
    func startGlitchLoop() {
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            if Int.random(in: 0...10) > 7 {
                withAnimation(.linear(duration: 0.05)) {
                    offset1 = CGFloat.random(in: -5...5) * intensity
                    offset2 = CGFloat.random(in: -5...5) * intensity
                    sliceHeight = CGFloat.random(in: 5...20)
                    sliceOffset = CGFloat.random(in: 0...100)
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    offset1 = 0
                    offset2 = 0
                }
            }
        }
    }
}

extension View {
    func glitchEffect(intensity: Double = 1.0, active: Bool = true) -> some View {
        modifier(GlitchModifier(intensity: intensity, active: active))
    }
}

// MARK: - Main View
struct VotingResultsView: View {
    @ObservedObject var votingManager: VotingManager
    let gameSettings: GameSettings
    let onNewGame: () -> Void
    let onContinueToGameplay: () -> Void
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var gameLogic: GameLogic
    
    @State private var showContent = false
    @State private var showStamp = false
    @State private var showPoints = false
    
    // Derived States
    private var isMultiplayer: Bool {
        MultipeerManager.shared.role != .unknown
    }

    private var localPlayerIsSpy: Bool {
        guard isMultiplayer else { return false } // In Single Device we assume Neutral/Spectator perspective unless customized
        let myName = MultipeerManager.shared.myPeerId.displayName
        if let player = gameSettings.players.first(where: { $0.name == myName }) {
            return player.isImposter || player.roleType?.team == .imposter
        }
        return false
    }
    
    // Game Outcome Logic
    private var isRescue: Bool { votingManager.lastRescueMessage != nil }
    private var spiesWon: Bool { votingManager.gameEnded && !votingManager.playersWon }
    private var citizensWon: Bool { votingManager.gameEnded && votingManager.playersWon }
    private var isRoundContinue: Bool { !votingManager.gameEnded && !isRescue }
    
    // THEME ENGINE
    struct ResultTheme {
        let title: String
        let subtitle: String
        let stampText: String
        let icon: String
        let primaryColor: Color
        let secondaryColor: Color
        let isGlitchy: Bool
        let isVictory: Bool // Emotional victory for the viewer
    }
    
    private var currentTheme: ResultTheme {
        // SCENARIO 1: RETTUNG (Immer positiv)
        if isRescue {
            return ResultTheme(
                title: "RETTUNG ERFOLGREICH",
                subtitle: votingManager.lastRescueMessage ?? "Der Leibwächter hat eingegriffen.",
                stampText: "GESCHÜTZT",
                icon: "shield.lefthalf.filled",
                primaryColor: .green,
                secondaryColor: .blue,
                isGlitchy: false,
                isVictory: true
            )
        }
        
        // SCENARIO 2: RUNDE GEHT WEITER (Spion gefunden)
        if isRoundContinue {
            return ResultTheme(
                title: "ZIEL NEUTRALISIERT",
                subtitle: "Ein Spion wurde entfernt. Bleibt wachsam.",
                stampText: "TREFFER",
                icon: "scope",
                primaryColor: .orange,
                secondaryColor: .red,
                isGlitchy: false,
                isVictory: true
            )
        }
        
        // SCENARIO 3: SPIONE GEWINNEN
        if spiesWon {
            if isMultiplayer && localPlayerIsSpy {
                // Ich bin Spion -> MEIN SIEG
                return ResultTheme(
                    title: "MISSION ERFOLGREICH",
                    subtitle: "Hervorragende Arbeit, Agent. Das System gehört uns.",
                    stampText: "DOMINANZ",
                    icon: "lock.open.fill",
                    primaryColor: .red, // Sieger-Rot (Satt)
                    secondaryColor: .purple,
                    isGlitchy: false,
                    isVictory: true
                )
            } else if isMultiplayer {
                // Ich bin Bürger -> NIEDERLAGE / GLITCH
                return ResultTheme(
                    title: "SYSTEM ZERSTÖRT",
                    subtitle: "Kritischer Fehler. Die Spione haben die Kontrolle übernommen.",
                    stampText: "VERSAGT",
                    icon: "exclamationmark.triangle.fill",
                    primaryColor: .red, // Alarm-Rot
                    secondaryColor: .black,
                    isGlitchy: true,
                    isVictory: false
                )
            } else {
                // Single Device -> Neutral "Spione haben gewonnen" aber cool
                return ResultTheme(
                    title: "SABOTAGE ERFOLGREICH",
                    subtitle: "Team Spion hat das Spiel für sich entschieden.",
                    stampText: "SIEG: SPIONE",
                    icon: "eye.slash.fill",
                    primaryColor: .red,
                    secondaryColor: .orange,
                    isGlitchy: true, // Glitch passt gut zu "Spionen"
                    isVictory: false // Neutral
                )
            }
        }
        
        // SCENARIO 4: BÜRGER GEWINNEN
        if citizensWon {
            if isMultiplayer && localPlayerIsSpy {
                // Ich bin Spion -> NIEDERLAGE / GEFASST
                return ResultTheme(
                    title: "MISSION GESCHEITERT",
                    subtitle: "Deine Tarnung ist aufgeflogen. Zugriff verweigert.",
                    stampText: "ENTTARNT",
                    icon: "hand.raised.fill",
                    primaryColor: .red,
                    secondaryColor: .gray,
                    isGlitchy: true,
                    isVictory: false
                )
            } else {
                // Ich bin Bürger (oder Single Device) -> SIEG
                return ResultTheme(
                    title: "BEDROHUNG ELIMINIERT",
                    subtitle: "Alle Spione wurden identifiziert. Das System ist sicher.",
                    stampText: "ERFOLG",
                    icon: "shield.checkered",
                    primaryColor: .green,
                    secondaryColor: .mint,
                    isGlitchy: false,
                    isVictory: true
                )
            }
        }
        
        // Fallback
        return ResultTheme(title: "?", subtitle: "?", stampText: "?", icon: "questionmark", primaryColor: .gray, secondaryColor: .white, isGlitchy: false, isVictory: false)
    }

    private var frozenIdentifiedSpies: [Player] {
        // Logic to show who was found/is imposter
        if votingManager.gameEnded {
            return gameSettings.players.filter { $0.isImposter || $0.roleType?.team == .imposter }
        }
        let selected = votingManager.selectedPlayers
        return gameSettings.players.filter { selected.contains($0.id) && ($0.isImposter || $0.roleType?.team == .imposter) }
    }

    var body: some View {
        let theme = currentTheme
        
        ZStack {
            // Background
            Color.black.ignoresSafeArea()
            
            // Dynamic Background Gradient
            if theme.isGlitchy {
                // Chaos Background
                LinearGradient(colors: [.black, theme.primaryColor.opacity(0.2), .black], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
            } else {
                // Victory/Clean Background
                RadialGradient(colors: [theme.primaryColor.opacity(0.3), .black], center: .center, startRadius: 5, endRadius: 500)
                    .ignoresSafeArea()
            }
            
            VStack(spacing: 0) {
                // Top Bar
                HStack {
                    Text("STATUS // \(theme.isVictory ? "NORMAL" : "KRITISCH")")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(theme.primaryColor.opacity(0.8))
                        .padding(8)
                        .background(theme.primaryColor.opacity(0.1))
                        .overlay(RoundedRectangle(cornerRadius: 4).stroke(theme.primaryColor.opacity(0.3)))
                        .cornerRadius(4)
                }
                .padding(.top, 20)
                
                Spacer()
                
                // Main Icon & Stamp
                ZStack {
                    Image(systemName: theme.icon)
                        .font(.system(size: 100))
                        .foregroundColor(theme.primaryColor.opacity(0.2))
                        .blur(radius: 20)
                        .scaleEffect(showContent ? 1 : 0.8)
                    
                    Image(systemName: theme.icon)
                        .font(.system(size: 90))
                        .foregroundColor(theme.primaryColor)
                        .shadow(color: theme.primaryColor.opacity(0.8), radius: 30)
                        .scaleEffect(showContent ? 1 : 0.8)
                        .glitchEffect(intensity: 2, active: theme.isGlitchy)
                    
                    if showStamp {
                        Text(theme.stampText)
                            .font(.system(size: 48, weight: .black, design: .rounded))
                            .foregroundColor(theme.primaryColor)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(theme.primaryColor, lineWidth: 8)
                            )
                            .background(Color.black.opacity(0.5))
                            .rotationEffect(.degrees(-12))
                            .scaleEffect(1.2)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .frame(height: 240)
                
                // Text Content
                VStack(spacing: 16) {
                    Text(theme.title)
                        .font(.system(size: 28, weight: .black, design: .default))
                        .foregroundColor(.white)
                        .tracking(2)
                        .multilineTextAlignment(.center)
                        .shadow(color: theme.primaryColor.opacity(0.5), radius: 10)
                    
                    Text(theme.subtitle)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 40)
                }
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)
                
                Spacer()
                
                // Agents Revealed Section
                if !frozenIdentifiedSpies.isEmpty && !isRescue {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "eye.trianglebadge.exclamationmark")
                                .foregroundColor(theme.primaryColor)
                            Text("BETEILIGTE AGENTEN")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white.opacity(0.5))
                        }
                        .padding(.horizontal, 30)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(frozenIdentifiedSpies) { player in
                                    ImposterResultCard(
                                        player: player,
                                        isRevealed: true,
                                        isVictory: citizensWon, // Grün wenn Bürger gewinnen, sonst rot
                                        themeColor: theme.primaryColor
                                    )
                                    .frame(width: 140)
                                }
                            }
                            .padding(.horizontal, 30)
                        }
                    }
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 30)
                    .padding(.bottom, 20)
                }
                
                // Buttons
                VStack(spacing: 16) {
                    if isRescue {
                         ImposterPrimaryButton(title: "WEITERSPIELEN") {
                             continueRound()
                         }
                    } else if !votingManager.gameEnded {
                        // Spion gefunden, aber Spiel läuft weiter
                        ImposterPrimaryButton(title: "MISSION FORTSETZEN") {
                            continueRound()
                        }
                    } else {
                        // Spiel Ende
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
            if theme.isVictory {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            } else {
                UINotificationFeedbackGenerator().notificationOccurred(.error)
            }
            
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2)) {
                showContent = true
            }
            
            withAnimation(.spring(response: 0.4, dampingFraction: 0.5).delay(0.8)) {
                showStamp = true
            }
            
            // Stats Tracking (nur einmal ausführen)
            if votingManager.gameEnded && !isRescue {
                recordStats(spiesWon: spiesWon)
            }
        }
    }
    
    private func continueRound() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        if !isRescue {
            let previouslyFound = votingManager.foundSpies
            let eliminatedIDs = Set(frozenIdentifiedSpies.map { $0.id })
            votingManager.resetForNextRound()
            votingManager.foundSpies = previouslyFound.union(eliminatedIDs)
        } else {
            votingManager.resetForNextRound()
        }
        votingManager.restoreTimerState()
        onContinueToGameplay()
    }
    
    private func recordStats(spiesWon: Bool) {
        let imposters = gameSettings.players.filter { $0.isImposter || $0.roleType?.team == .imposter }
        let citizens = gameSettings.players.filter { !$0.isImposter && $0.roleType?.team != .imposter }
        
        if spiesWon {
            for imp in imposters { GlobalStatsManager.shared.recordWin(for: imp.name) }
            for cit in citizens { GlobalStatsManager.shared.recordLoss(for: cit.name) }
        } else {
            for imp in imposters { GlobalStatsManager.shared.recordLoss(for: imp.name) }
            for cit in citizens { GlobalStatsManager.shared.recordWin(for: cit.name) }
        }
    }
}

struct ImposterResultCard: View {
    let player: Player
    var isRevealed: Bool
    var isVictory: Bool
    var themeColor: Color = .white
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(themeColor.opacity(0.1))
                    .frame(width: 50, height: 50)
                
                Text(String(player.name.prefix(1)).uppercased())
                    .font(.title3.bold())
                    .foregroundColor(themeColor)
            }
            
            VStack(spacing: 4) {
                Text(player.name)
                    .font(.headline)
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text(player.roleType?.rawValue.uppercased() ?? "SPION")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(themeColor)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(themeColor.opacity(0.2))
                    .cornerRadius(4)
            }
        }
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(themeColor.opacity(0.3), lineWidth: 1)
        )
    }
}
