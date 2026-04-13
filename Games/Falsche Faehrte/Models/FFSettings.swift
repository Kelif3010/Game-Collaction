import Foundation

// MARK: - Rundenanzahl
enum FFRoundCount: Int, CaseIterable, Identifiable {
    case five  = 5
    case eight = 8
    case ten   = 10
    case twelve = 12

    var id: Int { rawValue }

    var label: String { "\(rawValue)" }
}

// MARK: - Bluff-Eingabe-Timer
enum FFBluffTimer: Int, CaseIterable, Identifiable {
    case thirty  = 30
    case forty   = 40
    case sixty   = 60
    case ninety  = 90

    var id: Int { rawValue }

    var label: String { "\(rawValue)s" }
}

// MARK: - Abstimmungs-Timer
enum FFVoteTimer: Int, CaseIterable, Identifiable {
    case twenty  = 20
    case thirty  = 30
    case fortyfive = 45

    var id: Int { rawValue }

    var label: String { "\(rawValue)s" }
}

// MARK: - Einstellungen
struct FFSettings {
    var selectedPacks: Set<FFPack>
    var roundCount: FFRoundCount
    var bluffTimer: FFBluffTimer
    var voteTimer: FFVoteTimer
    var showCategoryHint: Bool

    init() {
        selectedPacks = [.klassisch]
        roundCount = .eight
        bluffTimer = .forty
        voteTimer = .thirty
        showCategoryHint = true
    }
}
