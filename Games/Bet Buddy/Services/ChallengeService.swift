import Foundation

protocol ChallengeProviding {
    func randomChallenge(
        for categories: Set<CategoryType>,
        excluding history: Set<UUID>,
        avoiding lastCategory: CategoryType?
    ) -> (challenge: Challenge, didReset: Bool)
}

struct ChallengeService: ChallengeProviding {
    
    /// Wählt eine zufällige Challenge, schließt aber bereits gespielte aus.
    /// Gibt zusätzlich zurück, ob der Verlauf zurückgesetzt werden musste (weil alle Fragen gespielt wurden).
    func randomChallenge(
        for categories: Set<CategoryType>,
        excluding history: Set<UUID>,
        avoiding lastCategory: CategoryType? = nil
    ) -> (challenge: Challenge, didReset: Bool) {
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
        let didReset = availableChallenges.isEmpty
        let candidatePool = didReset ? pool : availableChallenges

        if let lastCategory {
            let categoryVariedPool = candidatePool.filter { $0.category != lastCategory }
            if let variedChallenge = categoryVariedPool.randomElement() {
                return (variedChallenge, didReset)
            }
        }

        let fallbackChallenge = candidatePool.randomElement()
            ?? pool.randomElement()
            ?? ChallengeData.classic.first
            ?? Challenge(text: "Wer zuletzt lacht, lacht am besten!", category: .classic)
        return (fallbackChallenge, didReset)
    }
}
