import SwiftUI

// MARK: - Fragen-Pack
enum FFPack: String, Codable, CaseIterable, Identifiable {
    case klassisch = "klassisch"
    case krass     = "krass"
    case extrem    = "extrem"

    var id: String { rawValue }

    var localizedName: String {
        switch self {
        case .klassisch: return NSLocalizedString("ff.pack.klassisch", comment: "")
        case .krass:     return NSLocalizedString("ff.pack.krass", comment: "")
        case .extrem:    return NSLocalizedString("ff.pack.extrem", comment: "")
        }
    }

    var emoji: String {
        switch self {
        case .klassisch: return "🕵️"
        case .krass:     return "🤯"
        case .extrem:    return "💀"
        }
    }

    var accentColor: FFThemeColor {
        switch self {
        case .klassisch: return FFThemeColor(primary: FFStyle.accentViolet, secondary: FFStyle.accentIndigo)
        case .krass:     return FFThemeColor(primary: FFStyle.accentCrimson, secondary: FFStyle.accentViolet)
        case .extrem:    return FFThemeColor(primary: FFStyle.accentGold, secondary: FFStyle.accentCrimson)
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
