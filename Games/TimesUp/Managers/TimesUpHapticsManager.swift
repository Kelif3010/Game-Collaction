//
//  TimesUpHapticsManager.swift
//  TimesUp
//
//  Created by Ken on 15.01.2026.
//

import CoreHaptics
import UIKit

/// High-End Haptik-Manager für Time's Up
/// Verwaltet die CoreHaptics Engine und sorgt für stabile Lifecycle-Übergänge.
class TimesUpHapticsManager {
    static let shared = TimesUpHapticsManager()
    
    private var engine: CHHapticEngine?
    private var lifecycleObservers: [NSObjectProtocol] = []
    
    // Prüft, ob das Gerät Hardware-Haptik unterstützt UND ob Haptik global aktiviert ist
    var supportsHaptics: Bool {
        let isEnabled = UserDefaults.standard.object(forKey: "isHapticsEnabled") as? Bool ?? true
        return isEnabled && CHHapticEngine.capabilitiesForHardware().supportsHaptics
    }
    
    private init() {
        createEngine()
        setupLifecycleObservers()
    }

    /// Engine bei Bedarf erstellen — falls beim App-Start Haptics deaktiviert war
    private func ensureEngine() {
        guard engine == nil, supportsHaptics else { return }
        createEngine()
    }
    
    deinit {
        stopEngine()
        for observer in lifecycleObservers {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    // MARK: - Engine Setup
    
    private func createEngine() {
        guard supportsHaptics else { return }
        
        do {
            engine = try CHHapticEngine()
            
            // Handler für unerwartete Stopps (z.B. Audio-Session Unterbrechung)
            engine?.stoppedHandler = { reason in
                print("TimesUp Haptic Engine Stopped: \(reason)")
            }
            
            // Handler für Resets (z.B. App kehrt aus Hintergrund zurück)
            engine?.resetHandler = { [weak self] in
                print("TimesUp Haptic Engine Reset - Restarting...")
                try? self?.engine?.start()
            }
            
            try engine?.start()
        } catch {
            print("TimesUp Haptic Engine Error: \(error)")
        }
    }
    
    private func stopEngine() {
        engine?.stop()
    }
    
    // MARK: - Lifecycle Management
    
    private func setupLifecycleObservers() {
        let center = NotificationCenter.default
        
        // App geht in den Hintergrund -> Engine stoppen (spart Batterie)
        let didEnterBackground = center.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.stopEngine()
        }
        
        // App kommt zurück -> Engine starten
        let willEnterForeground = center.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            try? self?.engine?.start()
        }
        
        lifecycleObservers = [didEnterBackground, willEnterForeground]
    }
    
    /// Startet die Engine manuell neu (falls nötig)
    func prepare() {
        guard supportsHaptics else { return }
        try? engine?.start()
    }
    
    // MARK: - Gameplay Effects
    
    /// Spielt einen belohnenden Effekt für eine richtige Antwort
    /// Fühlt sich an wie ein doppeltes "Einrasten" oder ein heller Triller.
    func playSuccess() {
        ensureEngine()
        guard supportsHaptics else {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            return
        }
        
        do {
            // Zwei sehr schnelle Ticks kurz hintereinander
            let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0)
            let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0)
            
            let event1 = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0)
            let event2 = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0.05)
            
            let pattern = try CHHapticPattern(events: [event1, event2], parameters: [])
            let player = try engine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
        } catch {
            print("Haptic Success failed: \(error)")
        }
    }
    
    /// Spielt einen Effekt für das Überspringen (Skip) einer Karte
    /// Fühlt sich an wie physische Reibung beim Wegschieben einer Papierkarte.
    func playSkip() {
        ensureEngine()
        guard supportsHaptics else {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            return
        }
        
        do {
            // Kontinuierliche Vibration mit abnehmender Intensität und geringer Schärfe (körnig)
            let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6)
            let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
            
            let event = CHHapticEvent(eventType: .hapticContinuous, parameters: [intensity, sharpness], relativeTime: 0, duration: 0.15)
            
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try engine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
        } catch {
            print("Haptic Skip failed: \(error)")
        }
    }
    
    // MARK: - Timer & State Effects
    
    /// Spielt einen Timer-Tick basierend auf der verbleibenden Zeit.
    /// Erzeugt eine progressive Spannungskurve.
    func playTimerTick(secondsRemaining: Int) {
        ensureEngine()
        guard supportsHaptics else {
            // Einfacher Fallback für alte Geräte bei den letzten 3 Sekunden
            if secondsRemaining <= 3 && secondsRemaining > 0 {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
            return
        }
        
        do {
            var events: [CHHapticEvent] = []
            
            if secondsRemaining == 0 {
                // GAME OVER: Power-Down Effekt
                // Eine Vibration, die stark beginnt und in 0.5s abfällt
                let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0)
                let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
                events.append(CHHapticEvent(eventType: .hapticContinuous, parameters: [intensity, sharpness], relativeTime: 0, duration: 0.5))
                
            } else if secondsRemaining <= 3 {
                // PANIK: Kurze, aggressive Stöße (0.1s)
                let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8)
                let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.7)
                events.append(CHHapticEvent(eventType: .hapticContinuous, parameters: [intensity, sharpness], relativeTime: 0, duration: 0.1))
                
            } else if secondsRemaining <= 10 {
                // COUNTDOWN: Sehr scharfer, metallischer Tick (Metronom)
                let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.5)
                let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0)
                events.append(CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0))
            } else {
                // Über 10 Sekunden: Keine Haptik, um Batterie zu sparen und Nerven zu schonen
                return
            }
            
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
        } catch {
            print("Timer haptic failed: \(error)")
        }
    }
    
    // MARK: - Special Effects
    
    /// Spielt einen magischen Crescendo-Effekt für die Aktivierung eines Perks.
    /// Fühlt sich an, als würde sich Energie aufladen und entladen.
    func playPerkActivation() {
        ensureEngine()
        guard supportsHaptics else {
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            return
        }
        
        do {
            var events: [CHHapticEvent] = []
            
            // Crescendo: 0.3s kontinuierlicher Anstieg
            let intensityStart = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.2)
            let intensityEnd = CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0)
            let sharpnessStart = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.4)
            let sharpnessEnd = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.9)
            
            let crescendo = CHHapticEvent(eventType: .hapticContinuous, parameters: [intensityStart, sharpnessStart], relativeTime: 0, duration: 0.3)
            events.append(crescendo)
            
            // Der "Plopp" am Ende
            let popIntensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0)
            let popSharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
            let pop = CHHapticEvent(eventType: .hapticTransient, parameters: [popIntensity, popSharpness], relativeTime: 0.3)
            events.append(pop)
            
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
        } catch {
            print("Perk activation haptic failed: \(error)")
        }
    }
    
    /// Spielt einen schweren, dumpfen Schlag für eine Strafe oder Minuspunkte.
    func playPenalty() {
        ensureEngine()
        guard supportsHaptics else {
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            return
        }
        
        do {
            let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0)
            let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.1) // Dumpf
            let event = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0)
            
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try engine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
        } catch {
            print("Penalty haptic failed: \(error)")
        }
    }
}
