import Foundation
import Observation

@MainActor
@Observable
final class GameTimer {
    private(set) var remaining: Int = 0
    private(set) var isPaused: Bool = false

    private var countdownTask: Task<Void, Never>?
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
        
        countdownTask = Task { @MainActor [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }
                self.tick()
                guard self.remaining > 0 || self.onTimeout != nil else { return }
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
        countdownTask?.cancel()
        countdownTask = nil
        onTimeout = nil
        isPaused = false
    }
}
