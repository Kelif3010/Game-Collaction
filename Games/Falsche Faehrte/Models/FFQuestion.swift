import SwiftUI

// MARK: - Fragen-Pack
enum FFPack: String, Codable, CaseIterable, Identifiable {
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
        case .klassisch: return NSLocalizedString("ff.pack.klassisch", comment: "")
        case .krass:     return NSLocalizedString("ff.pack.krass", comment: "")
        case .extrem:    return NSLocalizedString("ff.pack.extrem", comment: "")
        case .lustig:    return NSLocalizedString("ff.pack.lustig", comment: "")
        case .verrueckt: return NSLocalizedString("ff.pack.verrueckt", comment: "")
        case .pervers:   return NSLocalizedString("ff.pack.pervers", comment: "")
        case .unnuetz:   return NSLocalizedString("ff.pack.unnuetz", comment: "")
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
struct FFQuestion: Identifiable, Codable {
    let id: String
    let de_question: String
    let en_question: String
    let de_answer: String
    let en_answer: String
    let category: String
    let pack: FFPack

    var localizedQuestion: String {
        let code = UserDefaults.standard.string(forKey: "selectedLanguageCode") ?? "de"
        return code == "en" ? en_question : de_question
    }

    var localizedAnswer: String {
        let code = UserDefaults.standard.string(forKey: "selectedLanguageCode") ?? "de"
        return code == "en" ? en_answer : de_answer
    }
}

// MARK: - Datenbank
enum FFQuestionDatabase {
    static var all: [FFQuestion] = {
        guard let url = Bundle.main.url(forResource: "ff_questions", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let questions = try? JSONDecoder().decode([FFQuestion].self, from: data)
        else { return [] }
        return questions
    }()

    static func questions(for packs: Set<FFPack>) -> [FFQuestion] {
        all.filter { packs.contains($0.pack) }.shuffled()
    }
}
