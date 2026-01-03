//
//  GameWords.swift
//  Imposter
//
//  Created by Ken on 22.09.25.
//

import Foundation

/// Struktur für Begriffe in verschiedenen Spielmodi
struct GameWords {
    let primary: String      // Hauptbegriff
    let secondary: String?   // Zweiter Begriff (für Zwei-Begriffe Modus)
    
    init(primary: String, secondary: String? = nil) {
        self.primary = primary
        self.secondary = secondary
    }
    
    /// Gibt alle Begriffe als Array zurück
    var allWords: [String] {
        if let secondary = secondary {
            return [primary, secondary]
        }
        return [primary]
    }
    
    /// Gibt die Begriffe als formatierten String zurück
    var displayString: String {
        if let secondary = secondary {
            return "\(primary) & \(secondary)"
        }
        return primary
    }
}
