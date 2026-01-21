import Foundation

struct QuestionPlayer: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var name: String
    var isLiar: Bool
    var word: String
    var hasSeenCard: Bool
    /// Markiert einen Spieler als eliminiert (z.B. korrekt als Lügner gewählt)
    var isEliminated: Bool
    /// Rolle (für verschiedene Spielmodi)
    var role: String?
    /// Falls true, ist dieser Spieler geschützt
    var isProtected: Bool
    
    init(name: String) {
        self.id = UUID()
        self.name = name
        self.isLiar = false
        self.word = ""
        self.hasSeenCard = false
        self.isEliminated = false
        self.role = nil
        self.isProtected = false
    }
}
