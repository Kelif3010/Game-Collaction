//
//  TimeOutResultView.swift
//  Imposter
//
//  Created by Ken on 06.01.2026.
//

import SwiftUI
import MultipeerConnectivity

struct TimeOutResultView: View {
    @EnvironmentObject var gameSettings: GameSettings
    @EnvironmentObject var gameLogic: GameLogic
    @Environment(\.dismiss) var dismiss
    
    @State private var showContent = false
    @State private var showStamp = false
    
    // Logic Reuse
    private var isMultiplayer: Bool {
        MultipeerManager.shared.role != .unknown
    }

    private var localPlayerIsSpy: Bool {
        guard isMultiplayer else { return false }
        let myName = MultipeerManager.shared.myPeerId.displayName
        if let player = gameSettings.players.first(where: { $0.name == myName }) {
            return player.isImposter || player.roleType?.team == .imposter
        }
        return false
    }
    
    // Theme Config (Time Out is ALWAYS Spy Win)
    private var theme: ResultTheme {
        if isMultiplayer && !localPlayerIsSpy {
            // Citizen perspective: FAILURE
            return ResultTheme(
                title: "ZEIT ABGELAUFEN",
                subtitle: "Die Spione konnten nicht rechtzeitig identifiziert werden. Das System ist gefallen.",
                stampText: "VERSAGT",
                icon: "hourglass.bottomhalf.filled",
                color: .red,
                isGlitchy: true
            )
        } else {
            // Spy perspective (or Shared): VICTORY
            return ResultTheme(
                title: "MISSION ERFOLGREICH",
                subtitle: "Die Zeit hat für uns gespielt. Perfekte Tarnung.",
                stampText: "GEWONNEN",
                icon: "hourglass.tophalf.filled", // Or something cooler
                color: .red,
                isGlitchy: false
            )
        }
    }
    
    struct ResultTheme {
        let title: String
        let subtitle: String
        let stampText: String
        let icon: String
        let color: Color
        let isGlitchy: Bool
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // BG
            if theme.isGlitchy {
                LinearGradient(colors: [.black, theme.color.opacity(0.2), .black], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
            } else {
                RadialGradient(colors: [theme.color.opacity(0.3), .black], center: .center, startRadius: 5, endRadius: 500)
                    .ignoresSafeArea()
            }
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("STATUS // TIMEOUT")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(theme.color.opacity(0.8))
                        .padding(8)
                        .background(theme.color.opacity(0.1))
                        .cornerRadius(4)
                }
                .padding(.top, 20)
                
                Spacer()
                
                // Icon Area
                ZStack {
                    Image(systemName: theme.icon)
                        .font(.system(size: 100))
                        .foregroundColor(theme.color.opacity(0.2))
                        .blur(radius: 20)
                    
                    Image(systemName: theme.icon)
                        .font(.system(size: 90))
                        .foregroundColor(theme.color)
                        .shadow(color: theme.color.opacity(0.8), radius: 30)
                        .glitchEffect(intensity: 2.0, active: theme.isGlitchy)
                    
                    if showStamp {
                        Text(theme.stampText)
                            .font(.system(size: 42, weight: .black, design: .rounded))
                            .foregroundColor(theme.color)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(theme.color, lineWidth: 8)
                            )
                            .background(Color.black.opacity(0.6))
                            .rotationEffect(.degrees(-8))
                            .scaleEffect(1.2)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .frame(height: 240)
                
                // Text
                VStack(spacing: 16) {
                    Text(theme.title)
                        .font(.system(size: 28, weight: .black))
                        .foregroundColor(.white)
                        .tracking(1)
                        .shadow(color: theme.color.opacity(0.5), radius: 10)
                    
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
                
                // Revealed Spies
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "eye.slash.fill")
                            .foregroundColor(theme.color)
                        Text("ENTTARNTE SPIONE")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(.horizontal, 30)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(gameSettings.players.filter { $0.isImposter || $0.roleType?.team == .imposter }) { player in
                                ImposterResultCard(
                                    player: player,
                                    isRevealed: true,
                                    isVictory: true, // Spione haben gewonnen
                                    themeColor: theme.color
                                )
                                .frame(width: 140)
                            }
                        }
                        .padding(.horizontal, 30)
                    }
                }
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 30)
                .padding(.bottom, 30)
                
                // Buttons
                VStack(spacing: 16) {
                    ImposterPrimaryButton(title: "NEUES SPIEL") {
                        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                        Task { @MainActor in
                            await gameLogic.restartGame()
                        }
                    }
                    
                    Button {
                        gameSettings.requestExitToMain = true
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
                .padding(.horizontal, 25)
                .padding(.bottom, 20)
                .opacity(showContent ? 1 : 0)
            }
        }
        .onAppear {
            if isMultiplayer && !localPlayerIsSpy {
                UINotificationFeedbackGenerator().notificationOccurred(.error)
            } else {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
            
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2)) {
                showContent = true
            }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.5).delay(0.8)) {
                showStamp = true
            }
        }
    }
}