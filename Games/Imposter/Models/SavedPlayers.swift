//
//  SavedPlayers.swift
//  Imposter
//
//  Created by Ken on 22.09.25.
//

import Foundation
import Combine

@MainActor
class SavedPlayersManager: ObservableObject {
    @Published var savedPlayerNames: [String] = []
    
    private let store = UserDefaultsPlayerProfilesStore.shared
    
    init() {
        loadSavedPlayers()
    }
    
    /// Lädt gespeicherte Spielernamen aus dem Store
    private func loadSavedPlayers() {
        let profiles = store.loadAll()
        self.savedPlayerNames = profiles.map { $0.name }
    }
    
    /// Fügt einen neuen Spielernamen hinzu
    func addPlayer(_ name: String) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        store.add(name: trimmedName)
        loadSavedPlayers()
    }
    
    /// Entfernt einen Spielernamen
    func removePlayer(_ name: String) {
        store.remove(name: name)
        loadSavedPlayers()
    }
    
    /// Entfernt alle Spielernamen
    func clearAllPlayers() {
        store.clear()
        loadSavedPlayers()
    }
    
    /// Prüft ob ein Spielername bereits existiert
    func playerExists(_ name: String) -> Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return savedPlayerNames.contains { $0.caseInsensitiveCompare(trimmedName) == .orderedSame }
    }
    
    /// Gibt die Anzahl gespeicherter Spieler zurück
    var playerCount: Int { savedPlayerNames.count }
    
    /// Markiert Namen als verwendet (zur Verbesserung der Sortierung)
    func markUsed(names: [String]) {
        store.markUsed(names: names)
        loadSavedPlayers()
    }
}
