import SwiftUI

enum CategoryType: String, CaseIterable, Identifiable, Codable {
    case classic
    case party
    case deep
    case spicy
    case active
    case alphabet // <--- NEU

    var id: String { rawValue }

    var title: String {
        switch self {
        case .classic: return "Klassisch"
        case .party: return "Party"
        case .deep: return "Deep & Persönlich"
        case .spicy: return "Spicy"
        case .active: return "Aktiv"
        case .alphabet: return "Buchstaben" // <--- NEU
        }
    }

    var description: String {
        switch self {
        case .classic: return "Leichte Einstiegsfragen für jede Runde."
        case .party: return "Mehr Chaos, mehr Lacher – perfekt für Gruppen."
        case .deep: return "Fragen mit Tiefgang für vertraute Runden."
        case .spicy: return "Nur für Mutige – erhöhte Herzfrequenz garantiert."
        case .active: return "Bewegung! Wer ist der Sportlichste?"
        case .alphabet: return "Stadt-Land-Fluss Prinzip. Wie weit kommt ihr?" // <--- NEU
        }
    }

    var iconName: String {
        switch self {
        case .classic: return "sparkles"
        case .party: return "party.popper"
        case .deep: return "brain"
        case .spicy: return "flame.fill"
        case .active: return "figure.run"
        case .alphabet: return "textformat.abc" // <--- NEU (SF Symbol)
        }
    }

    var isLocked: Bool {
        false
    }

    var accent: Color {
        switch self {
        case .classic: return Color.cyan
        case .party: return Color.pink
        case .deep: return Color.purple
        case .spicy: return Color.red
        case .active: return Color.green
        case .alphabet: return Color.orange // <--- NEU
        }
    }
}
