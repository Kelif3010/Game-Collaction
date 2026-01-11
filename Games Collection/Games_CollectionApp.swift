//
//  Games_CollectionApp.swift
//  Games Collection
//
//  Created by Ken  on 27.12.25.
//

import SwiftUI

@main
struct Games_CollectionApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("selectedLanguageCode") private var selectedLanguageCode = "de"
    @AppStorage("useSystemLanguage") private var useSystemLanguage = true
    
    // Lifecycle Manager State
    @StateObject private var lifecycleManager = AppLifecycleManager.shared

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
                .alert(isPresented: $lifecycleManager.didCrashLastTime) {
                    Alert(
                        title: Text("Upps!"),
                        message: Text("Die App wurde unerwartet beendet. Möchtest du alle Einstellungen zurücksetzen, um Fehler zu beheben?"),
                        primaryButton: .destructive(Text("Einstellungen zurücksetzen")) {
                            lifecycleManager.factoryReset()
                        },
                        secondaryButton: .cancel(Text("Nein, behalten"))
                    )
                }
                .onAppear {
                    lifecycleManager.onAppLaunch()
                }
                .onChange(of: scenePhase) { newPhase in
                    if newPhase == .background || newPhase == .inactive {
                        lifecycleManager.onAppBackgroundOrExit()
                    } else if newPhase == .active {
                        lifecycleManager.onAppLaunch()
                    }
                }
        }
    }
}
