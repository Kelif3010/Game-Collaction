import Foundation

enum PerkBadge: String, Identifiable {
    case freeze
    case slowMotion
    case nextWordDouble
    case doublePoints
    case shield
    case stealPoints
    
    var id: String { rawValue }
    
    var label: String {
        switch self {
        case .freeze: return "Freeze"
        case .slowMotion: return "Slow"
        case .nextWordDouble: return "Next x2"
        case .doublePoints: return "2x Punkte"
        case .shield: return "Shield"
        case .stealPoints: return "Steal"
        }
    }
    
    var icon: String {
        switch self {
        case .freeze: return "snowflake"
        case .slowMotion: return "tortoise.fill"
        case .nextWordDouble: return "textformat.abc"
        case .doublePoints: return "rosette"
        case .shield: return "shield.fill"
        case .stealPoints: return "figure.ninja"
        }
    }
}
