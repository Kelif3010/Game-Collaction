//
//  ImposterHapticsManager.swift
//  Imposter
//
//  Created by Ken on 12.01.2026.
//

@preconcurrency import CoreHaptics
import UIKit

/// High-End Haptik-Manager für Imposter
/// Nutzt CoreHaptics für komplexe Texturen wie Herzschlag oder schwere Schläge.
@MainActor
final class ImposterHapticsManager {
    static let shared = ImposterHapticsManager()

    private var engine: CHHapticEngine?
    private var lifecycleTasks: [Task<Void, Never>] = []

    private var isHapticsEnabledAndSupported: Bool {
        let isEnabled = UserDefaults.standard.object(forKey: "isHapticsEnabled") as? Bool ?? true
        return isEnabled && CHHapticEngine.capabilitiesForHardware().supportsHaptics
    }

    init() {
        createEngine()
        setupLifecycleObservers()
    }

    private func ensureEngine() {
        guard engine == nil, isHapticsEnabledAndSupported else { return }
        createEngine()
    }

    private func createEngine() {
        guard isHapticsEnabledAndSupported else { return }

        do {
            engine = try CHHapticEngine()
            try engine?.start()

            // Engine neu starten, wenn App aus Hintergrund kommt
            engine?.resetHandler = {
                Task { @MainActor [weak self] in
                    print("Haptic Engine Reset - Restarting...")
                    try? await self?.engine?.start()
                }
            }
        } catch {
            print("Haptic Engine Error: \(error)")
        }
    }

    deinit {
        lifecycleTasks.forEach { $0.cancel() }
    }

    private func setupLifecycleObservers() {
        let backgroundTask = Task { @MainActor [weak self] in
            for await _ in NotificationCenter.default.notifications(named: UIApplication.didEnterBackgroundNotification) {
                try? await self?.engine?.stop()
            }
        }
        let foregroundTask = Task { @MainActor [weak self] in
            for await _ in NotificationCenter.default.notifications(named: UIApplication.willEnterForegroundNotification) {
                try? await self?.engine?.start()
            }
        }
        lifecycleTasks = [backgroundTask, foregroundTask]
    }

    /// Spielt einen schweren, dumpfen Schlag (wie ein Richterhammer)
    /// Ideal für: Voting-Entscheidungen
    func playHeavyThud() {
        ensureEngine()
        guard isHapticsEnabledAndSupported else {
            let isEnabled = UserDefaults.standard.object(forKey: "isHapticsEnabled") as? Bool ?? true
            if isEnabled {
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            }
            return
        }

        do {
            let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0)
            let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.1)
            let event = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0)

            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try engine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
        } catch {
            print("Failed to play thud: \(error)")
        }
    }

    /// Spielt einen einzelnen Scan-Tick (Progressiv)
    /// - Parameter progress: Fortschritt von 0.0 bis 1.0
    func playScanTick(progress: Float) {
        ensureEngine()
        guard isHapticsEnabledAndSupported else {
            let isEnabled = UserDefaults.standard.object(forKey: "isHapticsEnabled") as? Bool ?? true
            if isEnabled {
                if progress > 0.8 {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                } else {
                    UISelectionFeedbackGenerator().selectionChanged()
                }
            }
            return
        }

        do {
            let intensityVal = 0.2 + (progress * 0.8)
            let sharpnessVal = 0.4 + (progress * 0.5)

            let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: intensityVal)
            let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpnessVal)
            let event = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0)

            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try engine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
        } catch {
            print("Scan tick failed: \(error)")
        }
    }

    /// Spielt einen Timer-Tick basierend auf der verbleibenden Zeit
    func playTimerTick(secondsRemaining: Int) {
        ensureEngine()
        guard isHapticsEnabledAndSupported else {
            let isEnabled = UserDefaults.standard.object(forKey: "isHapticsEnabled") as? Bool ?? true
            if isEnabled && secondsRemaining <= 5 && secondsRemaining > 0 {
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            }
            return
        }

        do {
            var events: [CHHapticEvent] = []

            if secondsRemaining == 0 {
                let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0)
                let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
                events.append(CHHapticEvent(eventType: .hapticContinuous, parameters: [intensity, sharpness], relativeTime: 0, duration: 0.4))

            } else if secondsRemaining <= 3 {
                let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.9)
                let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
                events.append(CHHapticEvent(eventType: .hapticContinuous, parameters: [intensity, sharpness], relativeTime: 0, duration: 0.1))
                events.append(CHHapticEvent(eventType: .hapticContinuous, parameters: [intensity, sharpness], relativeTime: 0.15, duration: 0.05))

            } else if secondsRemaining <= 10 {
                let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0)
                let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.9)
                events.append(CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0))

            } else if secondsRemaining <= 30 {
                let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.5)
                let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
                events.append(CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0))
            } else {
                return
            }

            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
        } catch {
            print("Timer haptic failed: \(error)")
        }
    }
}
