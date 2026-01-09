//
//  RoleActionView.swift
//  Imposter
//
//  Created by Ken on 06.01.2026.
//

import SwiftUI

struct RoleActionView: View {
    let role: RoleType
    let players: [Player]
    let currentPlayer: Player
    let onAction: (Player) -> Void
    
    @State private var selectedPlayer: Player?
    @State private var revealedRole: RoleType?
    @State private var isImposter: Bool?
    
    var body: some View {
        VStack(spacing: 12) {
            
            if let selected = selectedPlayer {
                // Ergebnis anzeigen (mit Titel "Ergebnis" / "Geschützt")
                VStack(spacing: 16) {
                    if role == .hacker {
                        Text("\(selected.name) ist:")
                            .font(.title3)
                            .foregroundColor(.white.opacity(0.8))
                        
                        if let role = revealedRole {
                            VStack(spacing: 8) {
                                Image(systemName: role.icon)
                                    .font(.system(size: 50))
                                    .foregroundColor(.purple)
                                Text(role.rawValue)
                                    .font(.title.bold())
                                    .foregroundColor(.purple)
                            }
                        } else if let isSpy = isImposter, isSpy {
                            VStack(spacing: 8) {
                                Image(systemName: "eye.slash.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(.red)
                                Text("SPION")
                                    .font(.title.bold())
                                    .foregroundColor(.red)
                            }
                        } else {
                            VStack(spacing: 8) {
                                Image(systemName: "person.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(.blue)
                                Text("BÜRGER")
                                    .font(.title.bold())
                                    .foregroundColor(.blue)
                            }
                        }
                    } else if role == .bodyguard {
                        VStack(spacing: 12) {
                            Image(systemName: "shield.checkered")
                                .font(.system(size: 60))
                                .foregroundColor(.green)
                            Text("GESCHÜTZT")
                                .font(.title.bold())
                                .foregroundColor(.green)
                            Text("Du beschützt \(selected.name).")
                                .font(.body)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.white.opacity(0.1))
                .cornerRadius(16)
                .transition(.scale.combined(with: .opacity))
            } else {
                // Titel nur anzeigen, solange noch nicht gewählt wurde
                Text(titleText)
                    .font(.headline)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, 4)

                // Auswahl-Liste
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(players) { player in
                            if player.id != currentPlayer.id {
                                Button {
                                    handleSelection(player)
                                } label: {
                                    VStack(spacing: 8) {
                                        Text(String(player.name.prefix(1)).uppercased())
                                            .font(.title2.bold())
                                            .foregroundColor(.white)
                                            .frame(width: 44, height: 44)
                                            .background(Circle().fill(Color.white.opacity(0.1)))
                                        
                                        Text(player.name)
                                            .font(.caption.bold())
                                            .foregroundColor(.white)
                                            .lineLimit(1)
                                    }
                                    .padding(10)
                                    .frame(maxWidth: .infinity)
                                    .background(Color.white.opacity(0.05))
                                    .cornerRadius(12)
                                }
                            }
                        }
                    }
                    .padding(.bottom, 20)
                }
                .frame(maxHeight: .infinity) // Nutze den gesamten Platz
            }
        }
        .padding(.horizontal)
    }
    
    private var titleText: String {
        switch role {
        case .hacker: return "Wähle einen Spieler zum Hacken:"
        case .bodyguard: return "Wähle jemanden zum Beschützen:"
        default: return ""
        }
    }
    
    private func handleSelection(_ player: Player) {
        withAnimation {
            selectedPlayer = player
            if role == .hacker {
                revealedRole = player.roleType
                isImposter = player.isImposter
            }
            onAction(player)
        }
    }
}