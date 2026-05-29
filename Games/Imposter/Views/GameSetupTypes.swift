import SwiftUI

enum SetupRoute: Hashable {
    case game
}

extension ImposterGameMode {
    var localizedTitle: String {
        switch self {
        case .classic:
            return "Klassik"
        case .twoWords:
            return "Zwei‑Begriffe"
        case .roles:
            return "Rollen Modus"
        @unknown default:
            return rawValue
        }
    }
}
