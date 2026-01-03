//
//  AppSettingsView.swift
//  TimesUp
//

import SwiftUI

struct AppSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("selectedLanguageCode") private var selectedLanguageCode = Locale.current.language.languageCode?.identifier ?? AppLanguage.fallback.rawValue
    @AppStorage("useSystemLanguage") private var useSystemLanguage = true

    private var systemLanguage: AppLanguage { AppLanguage.fromSystemPreferred() }

    var body: some View {
        NavigationView {
            List {
                Section {
                    Toggle("Systemsprache verwenden (\(systemLanguage.displayName))", isOn: $useSystemLanguage)
                        .onChange(of: useSystemLanguage) { newValue in
                            if newValue {
                                selectedLanguageCode = systemLanguage.rawValue
                            }
                        }
                }

                Section(header: Text("Sprachen")) {
                    ForEach(AppLanguage.allCases) { language in
                        Button {
                            selectedLanguageCode = language.rawValue
                            useSystemLanguage = false
                        } label: {
                            HStack {
                                Text(language.displayName)
                                Spacer()
                                let isActive = useSystemLanguage
                                    ? language == systemLanguage
                                    : selectedLanguageCode == language.rawValue

                                if isActive {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .foregroundColor(.primary)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(Text("Einstellungen"))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fertig") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    AppSettingsView()
}
