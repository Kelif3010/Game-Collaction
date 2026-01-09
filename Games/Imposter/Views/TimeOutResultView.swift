//
//  TimeOutResultView.swift
//  Imposter
//
//  Created by Ken on 06.01.2026.
//

import SwiftUI

struct TimeOutResultView: View {
    @EnvironmentObject var gameSettings: GameSettings
    @EnvironmentObject var gameLogic: GameLogic
    @Environment(\.dismiss) var dismiss
    
    @State private var showContent = false
    @State private var showStamp = false
    @State private var radarRotation = 0.0
    @State private var showPoints = false
    
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
                    
                    AngularGradient(gradient: Gradient(colors: [.clear, .red.opacity(0.1), .clear]), center: .center)
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
                    // Status Icon
                    Image(systemName: "hourglass.bottomhalf.filled")
                        .font(.system(size: 80))
                        .foregroundColor(.red.opacity(0.3))
                        .blur(radius: 10)
                        .scaleEffect(showContent ? 1 : 0.8)
                    
                    Image(systemName: "hourglass.bottomhalf.filled")
                        .font(.system(size: 80))
                        .foregroundColor(.red)
                        .shadow(color: .red.opacity(0.5), radius: 20)
                        .scaleEffect(showContent ? 1 : 0.8)
                    
                    // Stamp Effect
                    if showStamp {
                        Text("ZEIT ABGELAUFEN")
                            .font(.system(size: 36, weight: .black, design: .rounded))
                            .foregroundColor(.red)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.red, lineWidth: 6)
                            )
                            .background(Color.black.opacity(0.01))
                            .rotationEffect(.degrees(-8))
                            .scaleEffect(1.2)
                            .transition(.scale.combined(with: .opacity))
                    }
                    
                    // XP Animation
                    if showPoints {
                        VStack(spacing: 0) {
                            Text("+10 XP")
                                .font(.system(size: 24, weight: .black))
                                .foregroundColor(.red)
                                .shadow(color: .red.opacity(0.5), radius: 2)
                            
                            Text("TEAM SPION")
                                .font(.caption.bold())
                                .foregroundColor(.red.opacity(0.8))
                                .padding(.top, 2)
                        }
                        .offset(y: -100)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .frame(height: 200)
                .padding(.bottom, 20)
                
                // Narrative Text
                VStack(spacing: 12) {
                    Text("Spione gewinnen")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                        .tracking(1)
                    
                    Text("Die Zeit ist abgelaufen. Die Spione konnten ihre Identität bis zum Schluss geheim halten.")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 40)
                }
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)
                
                Spacer()
                
                // Revealed Spies
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "eye.slash.fill")
                            .foregroundColor(.red)
                        Text("ENTTARNTE SPIONE")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(.horizontal, 30)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(gameSettings.players.filter { $0.isImposter }) { player in
                                ImposterResultCard(player: player, isRevealed: true, isVictory: true)
                                    .frame(width: 150)
                            }
                        }
                        .padding(.horizontal, 30)
                    }
                }
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 30)
                
                Spacer()
                
                // Action Buttons
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
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                radarRotation = 360
            }
            
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2)) {
                showContent = true
            }
            
            withAnimation(.spring(response: 0.4, dampingFraction: 0.5).delay(0.8)) {
                showStamp = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                    showPoints = true
                }
            }
        }
    }
}
