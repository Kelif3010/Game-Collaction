//
//  SoundManager.swift
//  Games Collection
//
//  Created for Games Collection
//  Global Audio Service for all games
//

import AVFoundation
import UIKit

/// Thread-sicherer Audio-Manager - alle Zugriffe laufen über MainActor
@MainActor
class SoundManager {
    static let shared = SoundManager()

    private var player: AVAudioPlayer?
    var isSoundEnabled: Bool {
        get {
            // Standardmäßig an (true), wenn nicht explizit ausgeschaltet
            if UserDefaults.standard.object(forKey: "global_sound_enabled") == nil {
                return true
            }
            return UserDefaults.standard.bool(forKey: "global_sound_enabled")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "global_sound_enabled")
        }
    }

    private init() {
        // Audio Session konfigurieren
        // .ambient erlaubt, dass Musik von anderen Apps (Spotify etc.) weiterläuft
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("SoundManager: Failed to set audio session: \(error)")
        }
    }

    /// Spielt einen Sound aus dem Main Bundle ab.
    /// - Parameter filename: Der Name der Datei (mit oder ohne Endung).
    /// - Parameter loop: Ob der Sound in Dauerschleife gespielt werden soll.
    func playSound(named filename: String, loop: Bool = false) {
        guard isSoundEnabled else { return }
        
        // Bereinige den Namen, falls Endungen übergeben wurden, 
        // da wir flexibel nach mp3, wav oder m4a suchen.
        let name = filename.replacingOccurrences(of: ".mp3", with: "")
                           .replacingOccurrences(of: ".wav", with: "")
                           .replacingOccurrences(of: ".m4a", with: "")
                           .replacingOccurrences(of: ".caf", with: "")

        // Suche nach unterstützten Formaten
        guard let url = Bundle.main.url(forResource: name, withExtension: "mp3") ??
                        Bundle.main.url(forResource: name, withExtension: "m4a") ??
                        Bundle.main.url(forResource: name, withExtension: "wav") ??
                        Bundle.main.url(forResource: name, withExtension: "caf") else {
            print("SoundManager: File '\(filename)' not found")
            return
        }

        do {
            // Erstelle Player neu für den Sound
            player = try AVAudioPlayer(contentsOf: url)
            player?.numberOfLoops = loop ? -1 : 0
            player?.prepareToPlay()
            player?.play()
        } catch {
            print("SoundManager: Error playing sound: \(error)")
        }
    }
    
    /// Stoppt die aktuelle Wiedergabe sofort.
    func stopSound() {
        player?.stop()
    }
    
    /// Vibriert kurz (Haptisches Feedback Wrapper)
    func vibrate(type: UINotificationFeedbackGenerator.FeedbackType = .success) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }
}
