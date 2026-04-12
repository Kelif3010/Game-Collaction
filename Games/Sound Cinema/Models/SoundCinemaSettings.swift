import Foundation

// MARK: - Timer-Modus
enum SoundCinemaTimerMode: Int, CaseIterable, Identifiable {
    case short  = 5
    case medium = 8
    case long   = 10

    var id: Int { rawValue }

    var label: String { "\(rawValue)s" }

    var description: String {
        switch self {
        case .short:  return NSLocalizedString("soundcinema_timer_short_desc", comment: "")
        case .medium: return NSLocalizedString("soundcinema_timer_medium_desc", comment: "")
        case .long:   return NSLocalizedString("soundcinema_timer_long_desc", comment: "")
        }
    }
}

// MARK: - Leben-Modus
enum SoundCinemaLivesMode: Int, CaseIterable, Identifiable {
    case three    = 3
    case five     = 5
    case endless  = 0      // 0 = kein Ausscheiden

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .endless: return "∞"
        default:       return "\(rawValue) ♥"
        }
    }

    var isElimination: Bool { self != .endless }
}

// MARK: - Spiel-Einstellungen
struct SoundCinemaSettings {
    var playerNames: [String]          = []
    var selectedPacks: Set<SoundCinemaPack> = [.party]
    var timerMode: SoundCinemaTimerMode    = .medium
    var livesMode: SoundCinemaLivesMode    = .three

    var isValid: Bool {
        playerNames.count >= 2 && !selectedPacks.isEmpty
    }
}
