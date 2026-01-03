//
//  AppLanguage.swift
//  TimesUp
//

import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case german = "de"
    case english = "en"

    var id: String { rawValue }

    /// Anzeige-Name für die Sprache.
    var displayName: String {
        switch self {
        case .german: "Deutsch"
        case .english: "English"
        }
    }

    /// Passende Locale für die Sprache.
    var locale: Locale { Locale(identifier: rawValue) }

    static var fallback: AppLanguage { .german }

    static func from(code: String?) -> AppLanguage {
        guard let code, let language = AppLanguage(rawValue: code) else {
            return .fallback
        }
        return language
    }

    /// Ermittelt die bevorzugte Systemsprache, sofern unterstützt, sonst Fallback.
    static func fromSystemPreferred() -> AppLanguage {
        for identifier in Locale.preferredLanguages {
            if let code = Locale(identifier: identifier).language.languageCode?.identifier,
               let language = AppLanguage(rawValue: code) {
                return language
            }
        }
        return .fallback
    }
}
