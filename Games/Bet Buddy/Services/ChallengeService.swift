import Foundation

struct ChallengeService {
    
    /// Wählt eine zufällige Challenge, schließt aber bereits gespielte aus.
    /// Gibt zusätzlich zurück, ob der Verlauf zurückgesetzt werden musste (weil alle Fragen gespielt wurden).
    func randomChallenge(for categories: Set<CategoryType>, excluding history: Set<UUID>) -> (challenge: Challenge, didReset: Bool) {
        var pool: [Challenge] = []
        
        // 1. Pool aufbauen
        for category in categories {
            pool.append(contentsOf: ChallengeData.getChallenges(for: category))
        }
        
        // Fallback falls leer
        if pool.isEmpty {
            pool = ChallengeData.classic
        }
        
        // 2. Filtern: Nur Fragen nehmen, die NICHT in der History sind
        let availableChallenges = pool.filter { !history.contains($0.id) }
        
        // 3. Entscheidung
        if let newChallenge = availableChallenges.randomElement() {
            // Wir haben noch frische Fragen
            return (newChallenge, false)
        } else {
            // Alle Fragen wurden schon gespielt! Wir fangen von vorne an (Reset).
            // Wir nehmen eine beliebige aus dem vollen Pool.
            let resetChallenge = pool.randomElement() ?? ChallengeData.classic[0]
            return (resetChallenge, true)
        }
    }
}
