import Foundation

// MARK: - Pack-Typ
enum SoundCinemaPack: String, Codable, CaseIterable, Identifiable {
    case beginner = "beginner"
    case party    = "party"
    case wild     = "wild"

    var id: String { rawValue }

    var localizedName: String {
        switch self {
        case .beginner: return NSLocalizedString("soundcinema_pack_beginner", comment: "")
        case .party:    return NSLocalizedString("soundcinema_pack_party", comment: "")
        case .wild:     return NSLocalizedString("soundcinema_pack_wild", comment: "")
        }
    }

    var emoji: String {
        switch self {
        case .beginner: return "🎙️"
        case .party:    return "🎉"
        case .wild:     return "🔥"
        }
    }

    var description: String {
        switch self {
        case .beginner: return NSLocalizedString("soundcinema_pack_beginner_desc", comment: "")
        case .party:    return NSLocalizedString("soundcinema_pack_party_desc", comment: "")
        case .wild:     return NSLocalizedString("soundcinema_pack_wild_desc", comment: "")
        }
    }

    var accentColor: SoundCinemaColor {
        switch self {
        case .beginner: return .mint
        case .party:    return .cyan
        case .wild:     return .orange
        }
    }
}

// MARK: - Schwierigkeitsgrad
enum SoundDifficulty: String, Codable {
    case easy   = "easy"
    case medium = "medium"
    case hard   = "hard"
}

// MARK: - Karten-Model (Codable für JSON)
struct SoundCard: Identifiable, Codable {
    let id: String
    let de: String
    let en: String
    let pack: SoundCinemaPack
    let difficulty: SoundDifficulty
    let emoji: String

    /// Gibt den lokalisierten Titel zurück
    var localizedTitle: String {
        let code = Locale.current.language.languageCode?.identifier ?? "de"
        return code.hasPrefix("en") ? en : de
    }
}

// MARK: - Karten-Datenbank
enum SoundCardDatabase {
    static var all: [SoundCard] = {
        guard let url = Bundle.main.url(forResource: "sound_cards", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let cards = try? JSONDecoder().decode([SoundCard].self, from: data)
        else { return [] }
        return cards
    }()

    static func cards(for packs: Set<SoundCinemaPack>) -> [SoundCard] {
        all.filter { packs.contains($0.pack) }.shuffled()
    }
}
