import Foundation

// 1. Dieser Enum hat gefehlt, weshalb GameResult und AlphabetChallenges Fehler warfen
enum ChallengeInputType: String, Codable, Hashable {
    case numeric // Standard (Zahlen)
    case alphabet // Buchstaben (A-Z)
}

struct Challenge: Identifiable, Hashable, Codable {
    let id: UUID
    let text: String
    let category: CategoryType
    // 2. Dieses Feld hat gefehlt
    var inputType: ChallengeInputType

    // 3. Init angepasst, damit er 'inputType' annimmt (mit Standardwert .numeric)
    init(id: UUID = UUID(), text: String, category: CategoryType, inputType: ChallengeInputType = .numeric) {
        self.id = id
        self.text = text
        self.category = category
        self.inputType = inputType
    }
}
