//
//  AITuner.swift
//  Imposter
//
//  Created by Ken on 30.09.25.
//

import Foundation
import Combine

/// Liefert Gewichtungs-Multiplikatoren für die Spionauswahl.
/// Nutzt deterministische Regeln; optional später durch On-Device-KI verfeinerbar.
@MainActor
final class AITuner: ObservableObject {
    static let shared = AITuner()
    
    private init() {}
    
    /// Erzeugt pro Spieler einen Multiplikator (>0), der auf die berechneten Gewichte angewendet wird.
    /// - Note: 1.0 bedeutet keine Änderung. >1.0 erhöht, <1.0 senkt die Chance.
    func suggestWeightMultipliers(
        players: [UUID],
        policy: FairnessPolicy,
        state: FairnessState
    ) -> [UUID: Double] {
        var result: [UUID: Double] = [:]
        let currentRound = state.currentRound
        
        // Statistiken für Normalisierung
        var maxDistance: Int = 0
        var minTimes: Int = Int.max
        var maxTimes: Int = 0
        
        for id in players {
            let s = state.stats(for: id)
            let distance = s.lastPickedRound >= 0 ? max(0, currentRound - s.lastPickedRound) : currentRound + 1
            maxDistance = max(maxDistance, distance)
            minTimes = min(minTimes, s.timesImposter)
            maxTimes = max(maxTimes, s.timesImposter)
        }
        if minTimes == Int.max { minTimes = 0 }
        
        for id in players {
            let s = state.stats(for: id)
            var mult: Double = 1.0
            
            // Frequenz-Ausgleich: Weniger oft gewählt => höherer Multiplikator
            if maxTimes > minTimes {
                let norm = 1.0 - (Double(s.timesImposter - minTimes) / Double(max(1, maxTimes - minTimes)))
                mult *= 0.9 + 0.3 * max(0.0, min(1.0, norm)) // [0.9, 1.2]
            }
            
            // Distanz-Bonus: lange nicht gewählt => Bonus bis +15%
            let distance = s.lastPickedRound >= 0 ? max(0, currentRound - s.lastPickedRound) : (currentRound + 1)
            if maxDistance > 0 {
                let dNorm = Double(distance) / Double(maxDistance)
                mult *= 1.0 + 0.15 * dNorm
            }
            
            // Sehr kürzlich gewählt => zusätzliche leichte Dämpfung
            if s.lastPickedRound >= 0, (currentRound - s.lastPickedRound) <= policy.recentWindow {
                mult *= 0.9
            }
            
            // Clamp
            mult = max(0.2, min(2.0, mult))
            result[id] = mult
        }
        
        return result
    }
}


