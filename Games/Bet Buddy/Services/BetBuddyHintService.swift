import Foundation

struct BetBuddyHintService {
    
    // --- Aggregierte Hinweise ---
    // Wir bauen hier einmalig das große Wörterbuch aus den Einzelteilen zusammen.
    private static var allHints: [String: String] {
        // 1. Starte mit den klassischen Hinweisen
        var combined = ClassicHints.data
        
        // 2. Mische Party-Hinweise dazu
        // (Falls du PartyHints.swift schon erstellt hast - sonst diese Zeile auskommentieren)
        combined.merge(PartyHints.data) { (_, new) in new }
        
        // 3. Mische Spicy-Hinweise dazu
        // (Falls du SpicyHints.swift schon erstellt hast - sonst diese Zeile auskommentieren)
        combined.merge(SpicyHints.data) { (_, new) in new }
        
        // 4. NEU: Alphabet-Hinweise dazu
                combined.merge(AlphabetHints.data) { (_, new) in new }
                
                return combined
            }

    // --- Public API ---
    static func hintItems(for challenge: Challenge) -> [String] {
        // Suche in der großen, kombinierten Liste nach der Frage
        guard let raw = allHints[challenge.text] else { return [] }
        
        // Zerlege den String in eine saubere Liste
        return raw
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .sorted(by: { $0.localizedStandardCompare($1) == .orderedAscending }) // Alphabetisch sortieren
    }
}
