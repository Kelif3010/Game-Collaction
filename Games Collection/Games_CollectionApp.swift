//
//  Games_CollectionApp.swift
//  Games Collection
//
//  Created by Ken  on 27.12.25.
//

import SwiftUI

@main
struct Games_CollectionApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("selectedLanguageCode") private var selectedLanguageCode = "de"
    @AppStorage("useSystemLanguage") private var useSystemLanguage = true
    
    // Lifecycle Manager State
    @StateObject private var lifecycleManager = AppLifecycleManager.shared
    @StateObject private var externalDisplayManager = ExternalDisplayManager.shared
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

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
            Group {
                if hasSeenOnboarding {
                    ContentView()
                } else {
                    OnboardingView()
                }
            }
            .environment(\.locale, activeLocale)
            .environment(MultipeerManager.shared)
            .animation(.smooth, value: hasSeenOnboarding)
            .onAppear {
                lifecycleManager.onAppLaunch()
                QuickActionManager.shared.updateQuickActions()
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .background || newPhase == .inactive {
                    lifecycleManager.onAppBackgroundOrExit()
                } else if newPhase == .active {
                    lifecycleManager.onAppForeground()
                    QuickActionManager.shared.updateQuickActions()
                }
            }
        }
    }
}
