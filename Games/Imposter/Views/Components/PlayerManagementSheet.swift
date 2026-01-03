//
//  PlayerManagementSheet.swift
//  Imposter
//
//  Created by Ken on 22.09.25.
//

import SwiftUI
import Combine

struct PlayerManagementSheet: View {
    @EnvironmentObject var gameSettings: GameSettings
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    @State private var selectedTab = 0
    @State private var newPlayerName = ""
    @State private var selectedPlayers: Set<String> = []
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    let onRequestExpand: (() -> Void)?
    
    init(onRequestExpand: (() -> Void)? = nil) {
        self.onRequestExpand = onRequestExpand
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Hintergrund-Gradient
                LinearGradient(
                    colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Tab-Auswahl (nur 2 Tabs)
                    Picker("Tab", selection: $selectedTab) {
                        Text("Hinzufügen").tag(0)
                        Text("Gespeicherte").tag(1)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal, 20)
                    .padding(.top, 5)
                    
                    // Tab-Inhalt
                    TabView(selection: $selectedTab) {
                        // Tab 0: Spieler hinzufügen mit Live-Liste
                        AddPlayersWithListTabView(
                            newPlayerName: $newPlayerName,
                            onAddPlayer: addPlayer,
                            showingAlert: $showingAlert,
                            alertMessage: $alertMessage
                        )
                        .environmentObject(gameSettings)
                        .tag(0)
                        
                        // Tab 1: Aus gespeicherten wählen
                        SavedPlayersTabView(
                            selectedPlayers: $selectedPlayers,
                            selectedTab: $selectedTab,
                            onApplySelected: applySelectedPlayers,
                            onRequestExpand: handleSavedPlayersRequestExpand
                        )
                        .environmentObject(gameSettings)
                        .tag(1)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
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
            .toolbarBackground(.clear, for: .navigationBar)
            .toolbarBackgroundVisibility(.visible, for: .navigationBar)
        }
        .onAppear {
            loadCurrentPlayers()
        }
        .alert("Fehler", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
    
    // MARK: - Helper Functions
    
    private func addPlayer() {
        let name = newPlayerName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !name.isEmpty else {
            alertMessage = "Bitte geben Sie einen Namen ein."
            showingAlert = true
            return
        }
        
        if gameSettings.players.contains(where: { $0.name == name }) {
            alertMessage = "Ein Spieler mit diesem Namen ist bereits im Spiel."
            showingAlert = true
            return
        }
        
        gameSettings.addPlayer(name: name)
        
        // Auch zu gespeicherten Spielern hinzufügen falls noch nicht vorhanden
        if !gameSettings.savedPlayersManager.playerExists(name) {
            gameSettings.savedPlayersManager.addPlayer(name)
        }
        
        newPlayerName = ""
    }
    
    private func applySelectedPlayers() {
        // Aktuelle Spieler leeren
        gameSettings.players.removeAll()
        
        // Ausgewählte Spieler hinzufügen
        for playerName in selectedPlayers.sorted() {
            gameSettings.addPlayer(name: playerName)
        }
    }
    
    private func loadCurrentPlayers() {
        // Bereits ausgewählte Spieler in der Liste markieren
        selectedPlayers = Set(gameSettings.players.map { $0.name })
    }
    
    private func handleSavedPlayersRequestExpand() {
        selectedTab = 1
        onRequestExpand?()
    }
}

// MARK: - Add Players with Live List Tab
struct AddPlayersWithListTabView: View {
    @EnvironmentObject var gameSettings: GameSettings
    @Binding var newPlayerName: String
    let onAddPlayer: () -> Void
    @Binding var showingAlert: Bool
    @Binding var alertMessage: String
    @Environment(\.colorScheme) var colorScheme
    @FocusState private var nameFieldFocused: Bool
    
    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                
                // Eingabebereich
                VStack(spacing: 15) {
                    HStack(spacing: 12) {
                        TextField("z.B. Max Mustermann", text: $newPlayerName)
                            .textFieldStyle(ModernTextFieldStyle())
                            .focused($nameFieldFocused)
                            .onSubmit {
                                onAddPlayer()
                                DispatchQueue.main.async { nameFieldFocused = true }
                            }
                        
                        Button(action: {
                            onAddPlayer()
                            DispatchQueue.main.async { nameFieldFocused = true }
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                        }
                        .frame(width: 44, height: 44)
                        .background(
                            LinearGradient(
                                colors: newPlayerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?
                                    [Color.gray, Color.gray] : [Color.green, Color.blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(22)
                        .disabled(newPlayerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 2)
                    }
                    
                    Text("Enter drücken oder Plus-Button zum Hinzufügen")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Aktuelle Spieler-Liste (Live)
                if !gameSettings.players.isEmpty {
                    VStack(spacing: 15) {
                        HStack {
                            Text("Spieler im Spiel (\(gameSettings.players.count))")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Spacer()
                            
                            if gameSettings.players.count >= 4 {
                                HStack(spacing: 5) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text("Bereit")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.green)
                                }
                            } else {
                                HStack(spacing: 5) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.orange)
                                    Text("Noch \(4 - gameSettings.players.count) benötigt")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.orange)
                                }
                            }
                        }
                        
                        // Spieler untereinander als Liste
                        VStack(spacing: 8) {
                            ForEach(Array(gameSettings.players.enumerated()), id: \.element.id) { index, player in
                                HStack {
                                    // Nummer
                                    Text("\(index + 1).")
                                        .font(.headline)
                                        .fontWeight(.bold)
                                        .foregroundColor(.blue)
                                        .frame(width: 25, alignment: .leading)
                                    
                                    // Name
                                    Text(player.name)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    
                                    Spacer()
                                    
                                    // Löschen-Button
                                    Button(action: {
                                        gameSettings.removePlayer(at: index)
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.title3)
                                            .foregroundColor(.red)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(colorScheme == .dark ? Color(.systemGray6) : Color.white)
                                        .shadow(color: .black.opacity(colorScheme == .dark ? 0.2 : 0.1), radius: 2, x: 0, y: 1)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                                )
                            }
                        }
                        
                        // Alle löschen Button
                        if gameSettings.players.count > 1 {
                            Button("Alle entfernen") {
                                gameSettings.players.removeAll()
                            }
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.top, 10)
                        }
                    }
                } else {
                    VStack(spacing: 10) {
                        Image(systemName: "person.3.sequence")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                        
                        Text("Noch keine Spieler hinzugefügt")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("Mindestens 4 Spieler erforderlich")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 30)
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
        }
    }
}

// MARK: - Saved Players Tab
struct SavedPlayersTabView: View {
    @EnvironmentObject var gameSettings: GameSettings
    @Binding var selectedPlayers: Set<String>
    @Binding var selectedTab: Int
    let onApplySelected: () -> Void
    let onRequestExpand: (() -> Void)?
    
    init(
        selectedPlayers: Binding<Set<String>>,
        selectedTab: Binding<Int>,
        onApplySelected: @escaping () -> Void,
        onRequestExpand: (() -> Void)? = nil
    ) {
        self._selectedPlayers = selectedPlayers
        self._selectedTab = selectedTab
        self.onApplySelected = onApplySelected
        self.onRequestExpand = onRequestExpand
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                
                if gameSettings.savedPlayersManager.playerCount > 0 {
                    // Spieler-Grid
                    VStack(spacing: 20) {
                        
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
                        
                        // Apply Button
                        if !selectedPlayers.isEmpty {
                            Button(action: {
                                onApplySelected()
                                // Automatisch zum "Hinzufügen" Tab wechseln
                                selectedTab = 0
                            }) {
                                GameActionButton(
                                    title: "\(selectedPlayers.count) Spieler übernehmen",
                                    icon: "checkmark.circle.fill",
                                    isEnabled: true
                                )
                            }
                            .padding(.top, 10)
                        }
                    }
                } else {
                    EmptyView()
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
        }
    }
    
    private func togglePlayerSelection(_ playerName: String) {
        if selectedPlayers.contains(playerName) {
            selectedPlayers.remove(playerName)
        } else {
            selectedPlayers.insert(playerName)
            onRequestExpand?()
        }
    }
    
    private func removePlayer(_ playerName: String) {
        withAnimation {
            selectedPlayers.remove(playerName)
            gameSettings.savedPlayersManager.removePlayer(playerName)
            gameSettings.objectWillChange.send()
        }
    }
}


#Preview {
    let settings = GameSettings()
    settings.players = [
        Player(name: "Alice"),
        Player(name: "Bob")
    ]
    settings.savedPlayersManager.addPlayer("Max")
    settings.savedPlayersManager.addPlayer("Anna")
    
    return PlayerManagementSheet()
        .environmentObject(settings)
}

