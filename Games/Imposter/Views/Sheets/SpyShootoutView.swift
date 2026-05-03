//
//  SpyShootoutView.swift
//  Imposter
//
//  Created by Ken on 06.01.2026.
//

import SwiftUI
import Pow

struct SpyShootoutView: View {
    let shooter: Player
    let gameSettings: GameSettings
    let onHit: (Player) -> Void
    let onMiss: (Player) -> Void
    
    @State private var selectedTarget: Player?
    @State private var isConfirming = false
    
    // Filtert alle möglichen Ziele (alle außer dem Schützen und anderen Bösen)
    private var targets: [Player] {
        gameSettings.players.filter { player in
            // Schütze kann sich nicht selbst erschießen
            if player.id == shooter.id { return false }
            // Optional: Schütze kann keine bekannten Mit-Spione erschießen (wenn er sie kennt)
            if player.isImposter { return false }
            // Böse Rollen auch ausschließen? Normalerweise ja, man schießt auf Bürger.
            if player.roleType?.team == .imposter { return false }
            return true
        }
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // Hintergrund-Pulsieren
            Circle()
                .fill(Color.red.opacity(0.2))
                .scaleEffect(isConfirming ? 1.5 : 1.0)
                .animation(.easeInOut(duration: 1).repeatForever(), value: isConfirming)
            
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Text("LETZTE CHANCE")
                        .font(.system(size: 16, weight: .black, design: .monospaced))
                        .foregroundStyle(.red)
                        .tracking(4)
                    
                    Text("\(shooter.name), nimm das Handy!")
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                    
                    Text("Finde den Geheimagenten, um den Sieg zu stehlen.")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 40)
                
                Spacer()
                
                // Ziele Grid
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        ForEach(targets) { target in
                            TargetButton(
                                player: target,
                                isSelected: selectedTarget?.id == target.id
                            ) {
                                withAnimation(.spring()) {
                                    selectedTarget = target
                                    isConfirming = true
                                }
                            }
                        }
                    }
                    .padding(20)
                }
                
                Spacer()
                
                // Trigger
                if let target = selectedTarget {
                    VStack(spacing: 10) {
                        LottieView(
                            filename: "Radar animation",
                            loopMode: .loop,
                            isPlaying: true,
                            animationSpeed: 0.85
                        )
                        .frame(width: 96, height: 96)
                        .opacity(0.25)

                        Text("Ziel erfasst: \(target.name)")
                            .font(.caption.bold())
                            .foregroundStyle(.red)
                        
                        Button(action: {
                            handleShot(at: target)
                        }) {
                            HStack {
                                Image(systemName: "scope")
                                Text("SCHIESSEN")
                            }
                            .font(.title3.weight(.black))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .background(Color.red)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: .red.opacity(0.5), radius: 20)
                        }
                        .padding(.horizontal, 40)
                    }
                    .transition(.movingParts.vanish.combined(with: .opacity))
                    .padding(.bottom, 40)
                }
            }
        }
    }
    
    private func handleShot(at target: Player) {
        if target.roleType == .secretAgent {
            // Treffer auf Geheimagent!
            // ABER: Hat der Leibwächter ihn geschützt?
            if target.isProtected {
                // Schuss geblockt -> Bürger gewinnen (als wäre es ein Miss)
                // Wir könnten hier onMiss aufrufen, oder einen speziellen "Blocked"-Callback.
                // onMiss führt zum Sieg der Bürger, das passt.
                onMiss(target) 
            } else {
                // Tödlicher Treffer -> Spione gewinnen
                onHit(target)
            }
        } else {
            // Daneben -> Bürger gewinnen
            onMiss(target)
        }
    }
}

private struct TargetButton: View {
    let player: Player
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.red : Color.white.opacity(0.1))
                        .frame(width: 80, height: 80)
                    
                    if isSelected {
                        Image(systemName: "scope")
                            .font(.system(size: 40))
                            .foregroundStyle(.white)
                    } else {
                        Text(String(player.name.prefix(1)).uppercased())
                            .font(.title.bold())
                            .foregroundStyle(.white)
                    }
                }
                
                Text(player.name)
                    .font(.headline)
                    .foregroundStyle(isSelected ? .red : .white)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.red : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
