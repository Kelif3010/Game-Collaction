//
//  ImposterHapticsManager.swift
//  Imposter
//
//  Created by Ken on 12.01.2026.
//

import CoreHaptics
import UIKit

/// High-End Haptik-Manager für Imposter
/// Nutzt CoreHaptics für komplexe Texturen wie Herzschlag oder schwere Schläge.
class ImposterHapticsManager {
    static let shared = ImposterHapticsManager()
    
    private var engine: CHHapticEngine?
    private var lifecycleObservers: [NSObjectProtocol] = []
    
    // Prüft, ob Haptik hardwareseitig unterstützt wird UND global aktiviert ist
    private var isHapticsEnabledAndSupported: Bool {
        let isEnabled = UserDefaults.standard.object(forKey: "isHapticsEnabled") as? Bool ?? true
        return isEnabled && CHHapticEngine.capabilitiesForHardware().supportsHaptics
    }
    
    init() {
        createEngine()
        setupLifecycleObservers()
    }
    
    private func createEngine() {
        guard isHapticsEnabledAndSupported else { return }
        
        do {
            engine = try CHHapticEngine()
            try engine?.start()
            
            // Engine neu starten, wenn App aus Hintergrund kommt
            engine?.resetHandler = { [weak self] in
                print("Haptic Engine Reset - Restarting...")
                try? self?.engine?.start()
            }
        } catch {
            print("Haptic Engine Error: \(error)")
        }
    }

    deinit {
        engine?.stop()
        for observer in lifecycleObservers {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    private func setupLifecycleObservers() {
        let center = NotificationCenter.default
        let didEnter = center.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.engine?.stop()
        }
        let willEnter = center.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            try? self?.engine?.start()
        }
        lifecycleObservers = [didEnter, willEnter]
    }
    
    /// Spielt einen schweren, dumpfen Schlag (wie ein Richterhammer)
    /// Ideal für: Voting-Entscheidungen
    func playHeavyThud() {
        guard isHapticsEnabledAndSupported else {
            // Fallback für alte Geräte (nur wenn Haptik generell an ist)
            let isEnabled = UserDefaults.standard.object(forKey: "isHapticsEnabled") as? Bool ?? true
            if isEnabled {
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            }
            return
        }
        
        do {
            // Ein "Thud" ist starke Intensität, aber sehr geringe "Sharpness" (dumpf)
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
        guard isHapticsEnabledAndSupported else {
            // Fallback
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
            // Progressiver Aufbau:
            // Intensität: 0.2 -> 1.0 (wird spürbar stärker)
            // Schärfe: 0.4 -> 0.9 (wird "knackiger")
            let intensityVal = 0.2 + (progress * 0.8)
            let sharpnessVal = 0.4 + (progress * 0.5)
            
            let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: intensityVal)
            let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpnessVal)
            
            // Transient = Einmaliges "Tick"
            let event = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0)
            
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try engine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
        } catch {
            print("Scan tick failed: \(error)")
        }
    }
    
    /// Spielt einen Timer-Tick basierend auf der verbleibenden Zeit
    /// Optimiert für: Spürbarkeit auf dem Tisch (Vibration + Sound)
    func playTimerTick(secondsRemaining: Int) {
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
                // Finale: Langer, kräftiger Brumm-Ton (0.4s)
                let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0)
                let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
                events.append(CHHapticEvent(eventType: .hapticContinuous, parameters: [intensity, sharpness], relativeTime: 0, duration: 0.4))
                
            } else if secondsRemaining <= 3 {
                // Kritisch: Kurze, aggressive Vibrations-Stöße (0.1s)
                let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.9)
                let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
                events.append(CHHapticEvent(eventType: .hapticContinuous, parameters: [intensity, sharpness], relativeTime: 0, duration: 0.1))
                
                // Zweiter Stoß kurz danach für "Panik"-Effekt
                events.append(CHHapticEvent(eventType: .hapticContinuous, parameters: [intensity, sharpness], relativeTime: 0.15, duration: 0.05))
                
            } else if secondsRemaining <= 10 {
                // Warnung: Sehr scharfer Tick (Hörbar auf dem Tisch)
                let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0)
                let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.9) // Hohe Frequenz = Lauter auf Tisch
                events.append(CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0))
                
            } else if secondsRemaining <= 30 {
                // Info: Subtiler Tick
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
