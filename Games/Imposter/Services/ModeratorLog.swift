//
//  ModeratorLog.swift
//  Imposter
//
//  Created by Ken on 23.09.25.
//

import Foundation
import Combine

/// Moderator-Log für Debugging und Transparenz
@MainActor
class ModeratorLog: ObservableObject {
    static let shared = ModeratorLog()
    
    @Published var logs: [LogEntry] = []
    @Published var isEnabled = true
    
    private let aiService = AIService.shared
    private let maxLogEntries = 100
    
    private init() {}
    
    // MARK: - Logging Methods
    
    /// Loggt eine Imposter-Auswahl
    func logImposterSelection(
        selectedImposters: [Player],
        allPlayers: [Player],
        fairnessState: FairnessState,
        reason: String
    ) async {
        guard isEnabled else { return }
        
        let fairnessScore = calculateFairnessScore(selectedImposters: selectedImposters, allPlayers: allPlayers)
        let cooldownStatus = generateCooldownStatus(selectedImposters: selectedImposters, fairnessState: fairnessState)
        
        let selection = ImposterSelection(
            selectedImposters: selectedImposters,
            fairnessScore: fairnessScore,
            cooldownStatus: cooldownStatus,
            reason: reason
        )
        
        let aiExplanation = await aiService.generateModeratorLog(for: selection)
        
        let logEntry = LogEntry(
            timestamp: Date(),
            type: .imposterSelection,
            title: "Imposter ausgewählt",
            details: aiExplanation,
            metadata: [
                "selectedImposters": selectedImposters.map { $0.name }.joined(separator: ", "),
                "fairnessScore": String(format: "%.2f", fairnessScore),
                "cooldownStatus": cooldownStatus,
                "reason": reason
            ]
        )
        
        addLogEntry(logEntry)
    }
    
    /// Loggt eine Fairness-Anpassung
    func logFairnessAdjustment(
        player: Player,
        oldWeight: Double,
        newWeight: Double,
        reason: String
    ) {
        guard isEnabled else { return }
        
        let logEntry = LogEntry(
            timestamp: Date(),
            type: .fairnessAdjustment,
            title: "Fairness angepasst",
            details: "\(player.name): \(String(format: "%.2f", oldWeight)) → \(String(format: "%.2f", newWeight))",
            metadata: [
                "player": player.name,
                "oldWeight": String(format: "%.2f", oldWeight),
                "newWeight": String(format: "%.2f", newWeight),
                "reason": reason
            ]
        )
        
        addLogEntry(logEntry)
    }
    
    /// Loggt einen Fehler
    func logError(_ error: Error, context: String = "") {
        guard isEnabled else { return }
        
        let logEntry = LogEntry(
            timestamp: Date(),
            type: .error,
            title: "Fehler",
            details: error.localizedDescription,
            metadata: [
                "context": context,
                "errorType": String(describing: type(of: error))
            ]
        )
        
        addLogEntry(logEntry)
    }
    
    /// Loggt eine Debug-Information
    func logDebug(_ message: String, metadata: [String: String] = [:]) {
        guard isEnabled else { return }
        
        let logEntry = LogEntry(
            timestamp: Date(),
            type: .debug,
            title: "Debug",
            details: message,
            metadata: metadata
        )
        
        addLogEntry(logEntry)
    }
    
    // MARK: - Private Methods
    
    private func addLogEntry(_ entry: LogEntry) {
        logs.insert(entry, at: 0)
        
        // Begrenze die Anzahl der Log-Einträge
        if logs.count > maxLogEntries {
            logs = Array(logs.prefix(maxLogEntries))
        }
        
        print("📝 Moderator-Log: \(entry.title) - \(entry.details)")
    }
    
    private func calculateFairnessScore(selectedImposters: [Player], allPlayers: [Player]) -> Double {
        // Vereinfachte Fairness-Berechnung
        let totalPlayers = allPlayers.count
        let selectedCount = selectedImposters.count
        return Double(selectedCount) / Double(totalPlayers)
    }
    
    private func generateCooldownStatus(selectedImposters: [Player], fairnessState: FairnessState) -> String {
        let cooldownPlayers = selectedImposters.filter { player in
            let stats = fairnessState.stats(for: player.id)
            return stats.cooldownUntilRound > fairnessState.currentRound
        }
        
        if cooldownPlayers.isEmpty {
            return "Keine Cooldown-Konflikte"
        } else {
            return "Cooldown-Konflikte: \(cooldownPlayers.map { $0.name }.joined(separator: ", "))"
        }
    }
    
    // MARK: - Public Methods
    
    /// Exportiert die Logs als JSON
    func exportLogs() -> Data? {
        let exportData = LogExport(
            timestamp: Date(),
            logs: logs,
            version: "1.0"
        )
        
        return try? JSONEncoder().encode(exportData)
    }
    
    /// Löscht alle Logs
    func clearLogs() {
        logs.removeAll()
    }
    
    /// Filtert Logs nach Typ
    func filterLogs(by type: LogEntryType) -> [LogEntry] {
        return logs.filter { $0.type == type }
    }
}

// MARK: - Data Models

struct LogEntry: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let type: LogEntryType
    let title: String
    let details: String
    let metadata: [String: String]
    
    init(timestamp: Date, type: LogEntryType, title: String, details: String, metadata: [String: String] = [:]) {
        self.id = UUID()
        self.timestamp = timestamp
        self.type = type
        self.title = title
        self.details = details
        self.metadata = metadata
    }
    
    private enum CodingKeys: String, CodingKey {
        case id, timestamp, type, title, details, metadata
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.timestamp = try container.decode(Date.self, forKey: .timestamp)
        self.type = try container.decode(LogEntryType.self, forKey: .type)
        self.title = try container.decode(String.self, forKey: .title)
        self.details = try container.decode(String.self, forKey: .details)
        self.metadata = try container.decodeIfPresent([String: String].self, forKey: .metadata) ?? [:]
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(type, forKey: .type)
        try container.encode(title, forKey: .title)
        try container.encode(details, forKey: .details)
        try container.encode(metadata, forKey: .metadata)
    }
}

enum LogEntryType: String, CaseIterable, Codable {
    case imposterSelection = "imposter_selection"
    case fairnessAdjustment = "fairness_adjustment"
    case error = "error"
    case debug = "debug"
    
    var displayName: String {
        switch self {
        case .imposterSelection:
            return "Imposter-Auswahl"
        case .fairnessAdjustment:
            return "Fairness-Anpassung"
        case .error:
            return "Fehler"
        case .debug:
            return "Debug"
        }
    }
    
    var icon: String {
        switch self {
        case .imposterSelection:
            return "person.2.fill"
        case .fairnessAdjustment:
            return "scalemass.fill"
        case .error:
            return "exclamationmark.triangle.fill"
        case .debug:
            return "ladybug.fill"
        }
    }
}

struct LogExport: Codable {
    let timestamp: Date
    let logs: [LogEntry]
    let version: String
}

struct ImposterSelection {
    let selectedImposters: [Player]
    let fairnessScore: Double
    let cooldownStatus: String
    let reason: String
}
