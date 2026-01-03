import Foundation
import Combine

@MainActor // Sicherstellen, dass alles auf dem UI-Thread läuft
final class GameTimer: ObservableObject {
    @Published private(set) var remaining: Int = 0
    @Published private(set) var isPaused: Bool = false

    private var timer: Timer?
    private var onTimeout: (() -> Void)?

    func start(seconds: Int, onTimeout: @escaping () -> Void) {
        stop()
        remaining = max(0, seconds)
        isPaused = false
        self.onTimeout = onTimeout
        
        // Sofort prüfen, falls 0 Sekunden übergeben wurden
        if remaining == 0 {
            onTimeout()
            return
        }
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                if self.isPaused { return }
                
                if self.remaining > 0 {
                    self.remaining -= 1
                } else {
                    // WICHTIG: Erst den Handler sichern, dann stoppen!
                    let handler = self.onTimeout
                    self.stop()
                    handler?() // Jetzt feuern wir das Event
                }
            }
        }
    }

    func pause() {
        isPaused = true
    }

    func resume() {
        isPaused = false
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        onTimeout = nil
        isPaused = false
    }
}
