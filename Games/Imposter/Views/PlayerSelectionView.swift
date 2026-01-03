//
//  PlayerSelectionView.swift
//  Imposter
//
//  Created by Ken on 22.09.25.
//

import SwiftUI

struct PlayerSelectionView: View {
    @EnvironmentObject var gameSettings: GameSettings
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    @State private var showingAddPlayerSheet = false
    @State private var newPlayerName = ""
    @State private var selectedPlayers: Set<String> = []
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        ZStack {
            // Hintergrund-Gradient
            LinearGradient(
                colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 30) {
                    // Header
                    VStack(spacing: 10) {
                        Image(systemName: "person.2.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        Text("SPIELER AUSWÄHLEN")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        if gameSettings.savedPlayersManager.playerCount > 0 {
                            Text("Wählen Sie mindestens 4 Spieler aus")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        } else {
                            Text("Fügen Sie zuerst Spieler hinzu")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top, 20)
                    
                    if gameSettings.savedPlayersManager.playerCount > 0 {
                        // Gespeicherte Spieler Grid
                        VStack(spacing: 20) {
                            SectionHeader(title: "Gespeicherte Spieler", icon: "person.3.fill")
                            
                            LazyVGrid(columns: [
                                GridItem(.adaptive(minimum: 140), spacing: 12)
                            ], spacing: 12) {
                                ForEach(gameSettings.savedPlayersManager.savedPlayerNames, id: \.self) { playerName in
                                    SavedPlayerCard(
                                        playerName: playerName,
                                        isSelected: selectedPlayers.contains(playerName),
                                        onTap: {
                                            togglePlayerSelection(playerName)
                                        },
                                        onDelete: {
                                            removePlayer(playerName)
                                        }
                                    )
                                }
                            }
                        }
                        
                        // Ausgewählte Spieler Anzeige
                        if !selectedPlayers.isEmpty {
                            VStack(alignment: .leading, spacing: 15) {
                                SectionHeader(title: "Ausgewählte Spieler (\(selectedPlayers.count))", icon: "checkmark.circle.fill")
                                
                                LazyVGrid(columns: [
                                    GridItem(.adaptive(minimum: 120), spacing: 8)
                                ], spacing: 8) {
                                    ForEach(Array(selectedPlayers).sorted(), id: \.self) { playerName in
                                        Text(playerName)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(Color.green)
                                            .cornerRadius(15)
                                    }
                                }
                            }
                        }
                    } else {
                        // Keine Spieler vorhanden
                        InfoCard(
                            text: "Noch keine Spieler gespeichert. Fügen Sie welche hinzu!",
                            icon: "person.badge.plus"
                        )
                    }
                    
                    // Action Buttons
                    VStack(spacing: 15) {
                        // Neuen Spieler hinzufügen
                        Button(action: { showingAddPlayerSheet = true }) {
                            GameActionButton(
                                title: "Neuen Spieler hinzufügen",
                                icon: "person.badge.plus",
                                isEnabled: true
                            )
                        }
                        
                        // Übernehmen (nur wenn genügend Spieler ausgewählt)
                        if selectedPlayers.count >= 4 {
                            Button(action: applySelectedPlayers) {
                                GameActionButton(
                                    title: "Ausgewählte Spieler übernehmen (\(selectedPlayers.count))",
                                    icon: "checkmark.circle.fill",
                                    isEnabled: true
                                )
                            }
                        }
                        
                        // Alle löschen (nur wenn Spieler vorhanden)
                        if gameSettings.savedPlayersManager.playerCount > 0 {
                            Button("Alle Spieler löschen") {
                                gameSettings.savedPlayersManager.clearAllPlayers()
                            }
                            .font(.headline)
                            .foregroundColor(.red)
                        }
                        
                        // Zurück
                        Button("Zurück") {
                            dismiss()
                        }
                        .foregroundColor(.secondary)
                        .font(.headline)
                    }
                    .padding(.bottom, 30)
                }
                .padding(.horizontal, 20)
            }
        }
        .sheet(isPresented: $showingAddPlayerSheet) {
            AddPlayerSheet()
                .environmentObject(gameSettings)
        }
        .alert("Fehler", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .onAppear {
            loadCurrentPlayers()
        }
    }
    
    // MARK: - Helper Functions
    
    private func togglePlayerSelection(_ playerName: String) {
        if selectedPlayers.contains(playerName) {
            selectedPlayers.remove(playerName)
        } else {
            selectedPlayers.insert(playerName)
        }
    }
    
    private func removePlayer(_ playerName: String) {
        selectedPlayers.remove(playerName)
        gameSettings.savedPlayersManager.removePlayer(playerName)
    }
    
    private func applySelectedPlayers() {
        // Aktuelle Spieler leeren
        gameSettings.players.removeAll()
        
        // Ausgewählte Spieler hinzufügen
        for playerName in selectedPlayers.sorted() {
            gameSettings.addPlayer(name: playerName)
        }
        
        dismiss()
    }
    
    private func loadCurrentPlayers() {
        // Bereits ausgewählte Spieler in der Liste markieren
        selectedPlayers = Set(gameSettings.players.map { $0.name })
    }
}

// MARK: - Saved Player Card
struct SavedPlayerCard: View {
    let playerName: String
    let isSelected: Bool
    let onTap: () -> Void
    let onDelete: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: "person.circle.fill")
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .blue)
                
                Text(playerName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
                    .lineLimit(1)
                
                Spacer()
                
                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                        .font(.title3)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.green : (colorScheme == .dark ? Color(.systemGray6) : Color.white))
                    .shadow(color: .black.opacity(colorScheme == .dark ? 0.2 : 0.1), radius: 3, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.green : Color.gray.opacity(colorScheme == .dark ? 0.3 : 0.2), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Add Player Sheet
struct AddPlayerSheet: View {
    @EnvironmentObject var gameSettings: GameSettings
    @Environment(\.dismiss) private var dismiss
    
    @State private var playerName = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    // Header
                    VStack(spacing: 10) {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 50))
                            .foregroundColor(.green)
                        
                        Text("SPIELER HINZUFÜGEN")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                    }
                    .padding(.top, 20)
                    
                    // Name eingeben
                    VStack(alignment: .leading, spacing: 15) {
                        SectionHeader(title: "Spielername", icon: "textformat")
                        
                        TextField("z.B. Max Mustermann", text: $playerName)
                            .textFieldStyle(ModernTextFieldStyle())
                    }
                    
                    Spacer()
                    
                    // Action Buttons
                    VStack(spacing: 15) {
                        Button(action: addPlayer) {
                            GameActionButton(
                                title: "Spieler speichern",
                                icon: "checkmark.circle.fill",
                                isEnabled: !playerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            )
                        }
                        .disabled(playerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        
                        Button("Abbrechen") {
                            dismiss()
                        }
                        .foregroundColor(.secondary)
                        .font(.headline)
                    }
                    .padding(.bottom, 30)
                }
                .padding(.horizontal, 20)
            }
            .navigationBarHidden(true)
        }
        .alert("Fehler", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func addPlayer() {
        let trimmedName = playerName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedName.isEmpty else {
            alertMessage = "Bitte geben Sie einen Namen ein."
            showingAlert = true
            return
        }
        
        if gameSettings.savedPlayersManager.playerExists(trimmedName) {
            alertMessage = "Ein Spieler mit diesem Namen existiert bereits."
            showingAlert = true
            return
        }
        
        gameSettings.savedPlayersManager.addPlayer(trimmedName)
        dismiss()
    }
}

#Preview {
    PlayerSelectionView()
        .environmentObject(GameSettings())
}
