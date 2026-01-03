import Foundation

// Diese Datei ist der "Manager", der alles zusammenhält.
enum ChallengeData {
    
    static var classic: [Challenge] { return ClassicChallenges.data }
    static var party: [Challenge] { return PartyChallenges.data }
    static var deep: [Challenge] { return DeepChallenges.data }
    static var spicy: [Challenge] { return SpicyChallenges.data }
    static var active: [Challenge] { return ActiveChallenges.data }
    static var alphabet: [Challenge] { return AlphabetChallenges.data }
    
    // Alle zusammen
    static var all: [Challenge] {
        return classic + party + deep + spicy + active + alphabet
    }
    
    // NEU: Diese Funktion hilft dir im AppViewModel, die richtigen Fragen zu laden
    static func getChallenges(for category: CategoryType) -> [Challenge] {
        switch category {
        case .classic: return classic
        case .party: return party
        case .deep: return deep
        case .spicy: return spicy
        case .active: return active
        case .alphabet: return alphabet
        }
    }
}
