import Foundation
import Combine

@MainActor
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
        
        if remaining == 0 {
            onTimeout()
            return
        }
        
        // Timer startet auf dem aktuellen RunLoop (Main), da wir im MainActor sind.
        // Wir nutzen den Block-basierten Timer, der auf dem Main-Thread feuert, wenn er dort geplant wurde.
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            // Da wir wissen, dass dieser Timer auf dem MainThread läuft (weil hier gestartet),
            // können wir MainActor.assumeIsolated nutzen oder Task.
            // Sicherer für Swift 6 Concurrency ist ein Task.
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.tick()
            }
        }
    }
    
    private func tick() {
        if isPaused { return }
        
        if remaining > 0 {
            remaining -= 1
        } else {
            let handler = onTimeout
            stop()
            handler?()
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
