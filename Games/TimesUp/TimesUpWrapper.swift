import SwiftUI

struct TimesUpWrapper: View {
    // 1. Das Gehirn des Spiels initialisieren
    @StateObject private var categoryManager = CategoryManager()
    
    // 2. Spracheinstellungen aus dem alten TimesUpApp.swift übernehmen
    @AppStorage("selectedLanguageCode") private var selectedLanguageCode = AppLanguage.fallback.rawValue
    @AppStorage("useSystemLanguage") private var useSystemLanguage = true

    private var activeLanguage: AppLanguage {
        if useSystemLanguage {
            return AppLanguage.fromSystemPreferred()
        } else {
            return AppLanguage.from(code: selectedLanguageCode)
        }
    }

    var body: some View {
        // Hier rufen wir jetzt direkt den SettingsView auf, der als neuer HomeView dient.
        // Das alte MainMenuView wird übersprungen.
        SettingsView(categoryManager: categoryManager)
            // WICHTIG: Die Spracheinstellung muss hier injected werden
            .environment(\.locale, activeLanguage.locale)
            .onChange(of: useSystemLanguage) { _ in
                categoryManager.updateLanguage(activeLanguage)
            }
            .onChange(of: selectedLanguageCode) { _ in
                categoryManager.updateLanguage(activeLanguage)
            }
    }
}
