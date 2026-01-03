//
//  PerkPack.swift
//  TimesUp
//
//  Created by Ken on 23.09.25.
//

import Foundation
import SwiftUI

enum PerkPack: String, CaseIterable, Codable, Identifiable {
    case tempo
    case score
    case sabotage
    case custom
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .tempo: return "Zeit & Tempo"
        case .score: return "Punkte & Boosts"
        case .sabotage: return "Sabotage"
        case .custom: return "Individuell"
        }
    }
    
    var subtitle: String {
        switch self {
        case .tempo: return "Timer einfrieren, Slow Motion & mehr Tempo-Tricks."
        case .score: return "Doppelte Punkte, Steals oder Schutzschilde."
        case .sabotage: return "Verwirrung, Glitches & Zwangs-Skips beim Gegner."
        case .custom: return "Stelle deine Lieblings-Perks frei zusammen."
        }
    }
    
    var iconName: String {
        switch self {
        case .tempo: return "timer"
        case .score: return "rosette"
        case .sabotage: return "bolt.trianglebadge.exclamationmark"
        case .custom: return "slider.horizontal.3"
        }
    }
    
    var gradient: LinearGradient {
        switch self {
        case .tempo:
            return LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .score:
            return LinearGradient(colors: [.green, .yellow], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .sabotage:
            return LinearGradient(colors: [.pink, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .custom:
            return LinearGradient(colors: [.orange, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
    
    var isCustom: Bool {
        self == .custom
    }
    
    static var standardCases: [PerkPack] {
        Self.allCases.filter { !$0.isCustom }
    }
    
    var associatedPerks: [PerkType] {
        guard !isCustom else { return PerkType.allCases }
        return PerkType.allCases.filter { $0.pack == self }
    }
}
