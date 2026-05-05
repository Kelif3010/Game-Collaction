import SwiftUI
import Algorithms

// MARK: - Fragen-Pack
enum FFPack: String, Codable, CaseIterable, Identifiable, Sendable {
    case klassisch = "klassisch"
    case krass     = "krass"
    case extrem    = "extrem"
    case lustig    = "lustig"
    case verrueckt = "verrueckt"
    case pervers   = "pervers"
    case unnuetz   = "unnuetz"

    var id: String { rawValue }

    var localizedName: String {
        switch self {
        case .klassisch: return String(localized: "ff.pack.klassisch")
        case .krass:     return String(localized: "ff.pack.krass")
        case .extrem:    return String(localized: "ff.pack.extrem")
        case .lustig:    return String(localized: "ff.pack.lustig")
        case .verrueckt: return String(localized: "ff.pack.verrueckt")
        case .pervers:   return String(localized: "ff.pack.pervers")
        case .unnuetz:   return String(localized: "ff.pack.unnuetz")
        }
    }

    var emoji: String {
        switch self {
        case .klassisch: return "🕵️"
        case .krass:     return "🤯"
        case .extrem:    return "💀"
        case .lustig:    return "😂"
        case .verrueckt: return "🎲"
        case .pervers:   return "🔞"
        case .unnuetz:   return "🧠"
        }
    }

    var accentColor: FFThemeColor {
        switch self {
        case .klassisch: return FFThemeColor(primary: FFStyle.accentViolet, secondary: FFStyle.accentIndigo)
        case .krass:     return FFThemeColor(primary: FFStyle.accentCrimson, secondary: FFStyle.accentViolet)
        case .extrem:    return FFThemeColor(primary: FFStyle.accentGold, secondary: FFStyle.accentCrimson)
        case .lustig:    return FFThemeColor(primary: FFStyle.accentGold, secondary: FFStyle.accentViolet)
        case .verrueckt: return FFThemeColor(primary: FFStyle.accentIndigo, secondary: FFStyle.accentGold)
        case .pervers:   return FFThemeColor(primary: FFStyle.accentCrimson, secondary: FFStyle.accentGold)
        case .unnuetz:   return FFThemeColor(primary: FFStyle.accentViolet, secondary: FFStyle.accentGold)
        }
    }
}

// MARK: - Frage-Modell
struct FFQuestion: Identifiable, Codable, Sendable {
    let id: String
    let de_question: String
    let en_question: String
    let de_answer: String
    let en_answer: String
    let category: String
    let pack: FFPack

    func localizedQuestion(languageCode: String = "de") -> String {
        languageCode == "en" ? en_question : de_question
    }

    func localizedAnswer(languageCode: String = "de") -> String {
        languageCode == "en" ? en_answer : de_answer
    }
}

// MARK: - Datenbank
enum FFQuestionDatabase {
    static var all: [FFQuestion] = {
        guard let url = Bundle.main.url(forResource: "ff_questions", withExtension: "json") else {
            assertionFailure("ff_questions.json nicht im Bundle gefunden")
            return []
        }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode([FFQuestion].self, from: data)
        } catch {
            assertionFailure("ff_questions.json Decodierfehler: \(error)")
            return []
        }
    }()

    static func questions(for packs: Set<FFPack>) -> [FFQuestion] {
        let pool = all.filter { packs.contains($0.pack) }
        return pool.randomSample(count: pool.count)
    }
}
