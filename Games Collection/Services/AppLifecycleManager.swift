import SwiftUI
import Combine

/// Verwaltet den App-Status, erkennt Abstürze und ermöglicht das Zurücksetzen aller Einstellungen.
final class AppLifecycleManager: ObservableObject {
    static let shared = AppLifecycleManager()
    
    @AppStorage("app.isRunning") private var isRunning: Bool = false
    @AppStorage("app.didCrashLastTime") var didCrashLastTime: Bool = false
    
    // Publish subject to notify when a reset happens
    let resetPublisher = PassthroughSubject<Void, Never>()

    private init() {}

    /// Rufe dies beim Start der App (in `App.init` oder `.onAppear` der RootView) auf.
    func onAppLaunch() {
        if isRunning {
            // App war "running", wurde also nicht sauber beendet -> Absturz oder Kill
            didCrashLastTime = true
            print("⚠️ AppLifecycleManager: Möglicher Absturz erkannt!")
        } else {
            didCrashLastTime = false
        }
        isRunning = true
    }

    /// Rufe dies auf, wenn die App in den Hintergrund geht oder beendet wird (`sceneWillResignActive`).
    func onAppBackgroundOrExit() {
        isRunning = false
    }
    
    /// Löscht ALLE UserDefaults der App (Rettungsanker).
    func factoryReset() {
        let domain = Bundle.main.bundleIdentifier!
        UserDefaults.standard.removePersistentDomain(forName: domain)
        UserDefaults.standard.synchronize()
        
        print("🚨 AppLifecycleManager: Factory Reset durchgeführt.")
        
        // Benachrichtige alle Listener (ViewModels), dass sie sich neu laden müssen
        resetPublisher.send()
        NotificationCenter.default.post(name: Notification.Name("AppDidReset"), object: nil)
        
        // Reset flags
        didCrashLastTime = false
        isRunning = true // Wir laufen ja noch
    }
}
