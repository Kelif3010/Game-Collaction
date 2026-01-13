import SwiftUI
import Combine

/// Verwaltet den App-Status, erkennt Abstürze und ermöglicht das Zurücksetzen aller Einstellungen.
final class AppLifecycleManager: ObservableObject {
    static let shared = AppLifecycleManager()
    
    @AppStorage("app.isRunning") private var isRunning: Bool = false
    @AppStorage("app.didCrashLastTime") var didCrashLastTime: Bool = false
    @AppStorage("app.lastResetTime") private var lastResetTime: Double = 0

    private let resetCooldown: TimeInterval = 60 * 60 * 12
    private var hasHandledLaunch = false
    
    // Publish subject to notify when a reset happens
    let resetPublisher = PassthroughSubject<Void, Never>()

    private init() {}

    /// Rufe dies beim Start der App (in `App.init` oder `.onAppear` der RootView) auf.
    func onAppLaunch() {
        guard !hasHandledLaunch else { return }
        hasHandledLaunch = true

        if isRunning {
            // App war "running", wurde also nicht sauber beendet -> Absturz oder Kill
            didCrashLastTime = true
            print("⚠️ AppLifecycleManager: Möglicher Absturz erkannt!")
            handleCrashIfNeeded()
        } else {
            didCrashLastTime = false
        }
        isRunning = true
    }

    func onAppForeground() {
        isRunning = true
    }

    /// Rufe dies auf, wenn die App in den Hintergrund geht oder beendet wird (`sceneWillResignActive`).
    func onAppBackgroundOrExit() {
        isRunning = false
    }

    private func handleCrashIfNeeded() {
        let now = Date().timeIntervalSince1970
        if now - lastResetTime < resetCooldown {
            didCrashLastTime = false
            return
        }
        factoryReset()
    }
    
    /// Löscht ALLE UserDefaults der App (Rettungsanker).
    func factoryReset() {
        guard let domain = Bundle.main.bundleIdentifier else {
            didCrashLastTime = false
            isRunning = true
            return
        }
        UserDefaults.standard.removePersistentDomain(forName: domain)
        UserDefaults.standard.synchronize()
        lastResetTime = Date().timeIntervalSince1970
        
        print("🚨 AppLifecycleManager: Factory Reset durchgeführt.")
        
        // Benachrichtige alle Listener (ViewModels), dass sie sich neu laden müssen
        resetPublisher.send()
        NotificationCenter.default.post(name: Notification.Name("AppDidReset"), object: nil)
        
        // Reset flags
        didCrashLastTime = false
        isRunning = true // Wir laufen ja noch
    }
}
