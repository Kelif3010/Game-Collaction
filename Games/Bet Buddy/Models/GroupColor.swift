import SwiftUI

enum GroupColor: String, CaseIterable, Identifiable {
    case blue
    case purple
    case green
    case red
    // NEU: Die fehlenden Farben ergänzt
    case yellow
    case orange
    case pink
    case teal

    var id: String { rawValue }

    var fallbackName: String {
        switch self {
        case .blue: return "Blau"
        case .purple: return "Lila"
        case .green: return "Grün"
        case .red: return "Rot"
        case .yellow: return "Gelb"
        case .orange: return "Orange"
        case .pink: return "Pink"
        case .teal: return "Türkis"
        }
    }

    var gradient: LinearGradient {
        LinearGradient(
            colors: [primary, secondary],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var primary: Color {
        switch self {
        case .blue: return Color(red: 0.33, green: 0.56, blue: 1.0)
        case .purple: return Color(red: 0.77, green: 0.42, blue: 1.0)
        case .green: return Color(red: 0.26, green: 0.92, blue: 0.65)
        case .red: return Color(red: 0.95, green: 0.32, blue: 0.37)
        // NEU: Farbwerte definiert
        case .yellow: return Color(red: 1.0, green: 0.8, blue: 0.0)
        case .orange: return Color(red: 1.0, green: 0.58, blue: 0.0)
        case .pink: return Color(red: 1.0, green: 0.18, blue: 0.33)
        case .teal: return Color(red: 0.19, green: 0.69, blue: 0.78)
        }
    }

    var secondary: Color {
        switch self {
        case .blue: return Color(red: 0.19, green: 0.30, blue: 0.75)
        case .purple: return Color(red: 0.44, green: 0.20, blue: 0.76)
        case .green: return Color(red: 0.13, green: 0.60, blue: 0.46)
        case .red: return Color(red: 0.62, green: 0.15, blue: 0.20)
        // NEU: Dunklere Abstufungen für den Verlauf
        case .yellow: return Color(red: 0.8, green: 0.6, blue: 0.0)
        case .orange: return Color(red: 0.8, green: 0.4, blue: 0.0)
        case .pink: return Color(red: 0.7, green: 0.1, blue: 0.2)
        case .teal: return Color(red: 0.1, green: 0.5, blue: 0.6)
        }
    }

    var accent: Color {
        switch self {
        case .blue: return Color(red: 0.72, green: 0.84, blue: 1.0)
        case .purple: return Color(red: 0.91, green: 0.72, blue: 1.0)
        case .green: return Color(red: 0.78, green: 1.0, blue: 0.91)
        case .red: return Color(red: 1.0, green: 0.75, blue: 0.79)
        // NEU: Hellere Akzente
        case .yellow: return Color(red: 1.0, green: 0.9, blue: 0.6)
        case .orange: return Color(red: 1.0, green: 0.8, blue: 0.6)
        case .pink: return Color(red: 1.0, green: 0.7, blue: 0.8)
        case .teal: return Color(red: 0.6, green: 0.9, blue: 0.95)
        }
    }
}
