import Foundation

enum PenaltyIntensity: String, CaseIterable, Identifiable {
    case soft = "Soft"
    case party = "Party"
    case extreme = "Extrem"
    
    var id: String { rawValue }
}

final class PenaltyGenerator {
    static let shared = PenaltyGenerator()
    
    private let softPenalties = [
        "Mache 10 Kniebeugen",
        "Erzähle einen flachen Witz",
        "Sing den Refrain eines Songs",
        "Lass dir eine neue Frisur machen",
        "Sprich 2 Runden nur im Flüsterton"
    ]
    
    private let partyPenalties = [
        "Verteile 2 Schlücke",
        "Trinke einen Schluck ohne Hände",
        "Tausche dein Getränk mit dem Nachbarn",
        "Ex dein Glas (wenn wenig drin ist)",
        "Jeder, der kleiner ist als du, trinkt"
    ]
    
    private let extremePenalties = [
        "Rufe den 5. Kontakt in deinem Handy an",
        "Lass dir ein Eis in den Nacken stecken",
        "Poste das letzte Foto deiner Galerie",
        "Trinke einen Shot Essig (oder was da ist)",
        "Lauf einmal um das Gebäude"
    ]
    
    func getPenalty(intensity: PenaltyIntensity) -> String {
        switch intensity {
        case .soft: return softPenalties.randomElement() ?? "Mache 5 Liegestütze"
        case .party: return partyPenalties.randomElement() ?? "Trink einen Schluck"
        case .extreme: return extremePenalties.randomElement() ?? "Mach was Verrücktes"
        }
    }
}
