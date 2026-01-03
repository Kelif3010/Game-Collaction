import Foundation

enum PenaltyLevel: String, CaseIterable, Identifiable {
    case normal
    case medium
    case hardcore

    var id: String { rawValue }

    var title: String {
        switch self {
        case .normal: return "Normal"
        case .medium: return "Mittel"
        case .hardcore: return "Hardcore"
        }
    }
}
