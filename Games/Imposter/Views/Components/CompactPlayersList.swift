//
//  CompactPlayersList.swift
//  Imposter
//
//  Created by Ken on 22.09.25.
//

import SwiftUI

struct CompactPlayersList: View {
    let players: [Player]
    let onRemovePlayer: (Int) -> Void
    
    @State private var showingAllPlayers = false
    @Environment(\.colorScheme) var colorScheme
    
    private let maxVisiblePlayers = 6 // Maximal sichtbare Spieler ohne "Mehr anzeigen"
    
    var body: some View {
        VStack(spacing: 15) {
            if players.isEmpty {
                // Leer-Zustand
                InfoCard(text: "Mindestens 4 Spieler erforderlich", icon: "info.circle")
            } else {
                // Spieler-Übersicht Karte
                PlayerSummaryCard(playerCount: players.count)
                
                // Kompakte Spielerliste oder "Alle verwalten" Button
                if players.count <= maxVisiblePlayers {
                    // Alle Spieler direkt anzeigen (bis 6 Spieler)
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 120), spacing: 8)
                    ], spacing: 8) {
                        ForEach(Array(players.enumerated()), id: \.element.id) { index, player in
                            CompactPlayerCard(
                                player: player,
                                onRemove: { onRemovePlayer(index) }
                            )
                        }
                    }
                } else {
                    // Viele Spieler: Erste paar + "Alle verwalten"
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 120), spacing: 8)
                    ], spacing: 8) {
                        ForEach(Array(players.prefix(4).enumerated()), id: \.element.id) { index, player in
                            CompactPlayerCard(
                                player: player,
                                onRemove: { onRemovePlayer(index) }
                            )
                        }
                        
                        // "Weitere X Spieler" Button
                        Button(action: { showingAllPlayers = true }) {
                            VStack(spacing: 6) {
                                Image(systemName: "person.3.fill")
                                    .font(.title3)
                                    .foregroundColor(.blue)
                                
                                Text("+ \(players.count - 4)")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.blue)
                                
                                Text("weitere")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.blue.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.blue.opacity(0.3), lineWidth: 1.5)
                                            .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [5]))
                                    )
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                // Status-Info
                if players.count < 4 {
                    InfoCard(text: "Noch \(4 - players.count) Spieler benötigt", icon: "info.circle")
                }
            }
        }
        .sheet(isPresented: $showingAllPlayers) {
            AllPlayersManagementSheet(
                players: players,
                onRemovePlayer: onRemovePlayer
            )
        }
    }
}

// MARK: - Player Summary Card
struct PlayerSummaryCard: View {
    let playerCount: Int
    @Environment(\.colorScheme) var colorScheme
    
    var summaryText: String {
        switch playerCount {
        case 0: return "Keine Spieler"
        case 1: return "1 Spieler"
        default: return "\(playerCount) Spieler"
        }
    }
    
    var statusColor: Color {
        if playerCount < 4 { return .orange }
        else { return .green }
    }
    
    var statusIcon: String {
        if playerCount < 4 { return "exclamationmark.triangle.fill" }
        else { return "checkmark.circle.fill" }
    }
    
    var body: some View {
        HStack {
            Image(systemName: statusIcon)
                .font(.title2)
                .foregroundColor(statusColor)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(summaryText)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(playerCount >= 4 ? "Bereit zum Spielen" : "Weitere Spieler benötigt")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Spieler-Icons Vorschau (erste 5)
            HStack(spacing: -8) {
                ForEach(0..<min(playerCount, 5), id: \.self) { _ in
                    Circle()
                        .frame(width: 24, height: 24)
                        .foregroundColor(.blue.opacity(0.7))
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.caption2)
                                .foregroundColor(.white)
                        )
                }
                
                if playerCount > 5 {
                    Circle()
                        .frame(width: 24, height: 24)
                        .foregroundColor(.gray.opacity(0.5))
                        .overlay(
                            Text("+\(playerCount - 5)")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        )
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color(.systemGray6) : Color.white)
                .shadow(color: .black.opacity(colorScheme == .dark ? 0.2 : 0.1), radius: 3, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(statusColor.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Compact Player Card
struct CompactPlayerCard: View {
    let player: Player
    let onRemove: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 8) {
            Text(String(player.name.prefix(2)))
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 20, height: 20)
                .background(Circle().fill(Color.blue))
            
            Text(player.name)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(1)
                .foregroundColor(.primary)
            
            Spacer(minLength: 0)
            
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.caption2)
                    .foregroundColor(.red)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
        )
    }
}

// MARK: - All Players Management Sheet
struct AllPlayersManagementSheet: View {
    let players: [Player]
    let onRemovePlayer: (Int) -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 25) {
                        // Header
                        VStack(spacing: 10) {
                            Image(systemName: "person.3.circle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.blue)
                            
                            Text("ALLE SPIELER")
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        .padding(.top, 20)
                        
                        // Spieler Grid
                        LazyVGrid(columns: [
                            GridItem(.adaptive(minimum: 140), spacing: 12)
                        ], spacing: 12) {
                            ForEach(Array(players.enumerated()), id: \.element.id) { index, player in
                                ModernPlayerCard(player: player) {
                                    onRemovePlayer(index)
                                }
                            }
                        }
                        
                        Spacer(minLength: 50)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationTitle("Spieler verwalten")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fertig") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

#Preview {
    let players = [
        Player(name: "Alice"),
        Player(name: "Bob"),
        Player(name: "Charlie"),
        Player(name: "David"),
        Player(name: "Eve"),
        Player(name: "Frank"),
        Player(name: "Grace"),
        Player(name: "Henry")
    ]
    
    return ScrollView {
        CompactPlayersList(players: players) { index in
            print("Remove player at \(index)")
        }
        .padding(20)
    }
    .background(
        LinearGradient(
            colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
}
