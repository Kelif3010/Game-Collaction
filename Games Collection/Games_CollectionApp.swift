//
//  Games_CollectionApp.swift
//  Games Collection
//
//  Created by Ken  on 27.12.25.
//

import SwiftUI

@main
struct Games_CollectionApp: App {
    @AppStorage("selectedLanguageCode") private var selectedLanguageCode = "de"
    @AppStorage("useSystemLanguage") private var useSystemLanguage = true

    private var activeLocale: Locale {
        if useSystemLanguage {
            for identifier in Locale.preferredLanguages {
                if identifier.hasPrefix("de") { return Locale(identifier: "de") }
                if identifier.hasPrefix("en") { return Locale(identifier: "en") }
            }
            return Locale(identifier: "de")
        }
        return Locale(identifier: selectedLanguageCode)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.locale, activeLocale)
        }
    }
}
