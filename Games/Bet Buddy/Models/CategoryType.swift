import SwiftUI

enum CategoryType: String, CaseIterable, Identifiable, Codable {
    case classic
    case party
    case spicy
    case active
    case alphabet

    var id: String { rawValue }

    var title: String {
        switch self {
        case .classic: return "Klassisch"
        case .party: return "Party"
        case .spicy: return "Spicy"
        case .active: return "Aktiv"
        case .alphabet: return "Buchstaben"
        }
    }

    var description: String {
        switch self {
        case .classic: return "Leichte Einstiegsfragen für jede Runde."
        case .party: return "Mehr Chaos, mehr Lacher – perfekt für Gruppen."
        case .spicy: return "Nur für Mutige – erhöhte Herzfrequenz garantiert."
        case .active: return "Bewegung! Wer ist der Sportlichste?"
        case .alphabet: return "Stadt-Land-Fluss Prinzip. Wie weit kommt ihr?"
        }
    }

    var iconName: String {
        switch self {
        case .classic: return "sparkles"
        case .party: return "party.popper"
        case .spicy: return "flame.fill"
        case .active: return "figure.run"
        case .alphabet: return "textformat.abc"
        }
    }

    var isLocked: Bool {
        false
    }

    var accent: Color {
        switch self {
        case .classic: return Color.cyan
        case .party: return Color.pink
        case .spicy: return Color.red
        case .active: return Color.green
        case .alphabet: return Color.orange
        }
    }
}
