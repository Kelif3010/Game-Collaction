import Foundation
import SwiftUI

// Umbenannt zu TimesUpCategoryType, um Konflikte zu vermeiden
enum TimesUpCategoryType: String, CaseIterable, Codable {
    case green = "Sehr leichte Kategorie"
    case yellow = "Leichte Kategorie"
    case red = "Mittel Kategorie"
    case blue = "Schwere Kategorie"
    case kids = "Kinder (7-12)"
    case teens = "Jugendliche (13-17)"
    case custom = "Eigene Kategorie"
    
    var color: Color {
        switch self {
        case .green: return .green
        case .yellow: return .yellow
        case .red: return .red
        case .blue: return .blue
        case .kids: return .orange
        case .teens: return .cyan
        case .custom: return .purple
        }
    }
    
    var systemImage: String {
        switch self {
        case .green: return "leaf.fill"
        case .yellow: return "sun.max.fill"
        case .red: return "flame.fill"
        case .blue: return "drop.fill"
        case .kids: return "figure.child"
        case .teens: return "headphones"
        case .custom: return "star.fill"
        }
    }
}

struct TimesUpCategory: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var type: TimesUpCategoryType
    var terms: [Term] = []
    var isSelected: Bool = false
    
    init(name: String, type: TimesUpCategoryType, terms: [Term] = []) {
        self.name = name
        self.type = type
        self.terms = terms
    }
    
    // Hier stand vorher fälschlicherweise 'Category' in den Parametern
    static func == (lhs: TimesUpCategory, rhs: TimesUpCategory) -> Bool {
        lhs.id == rhs.id
    }
}