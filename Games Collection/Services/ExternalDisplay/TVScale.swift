import SwiftUI

enum TVScaleCalculator {
    static let baseSize = CGSize(width: 1920, height: 1080)

    static func scale(for size: CGSize) -> CGFloat {
        guard size.width > 0, size.height > 0 else { return 1.0 }
        let widthScale = size.width / baseSize.width
        let heightScale = size.height / baseSize.height
        let rawScale = min(widthScale, heightScale)
        return min(max(rawScale, 0.6), 1.6)
    }
}

private struct TVScaleKey: EnvironmentKey {
    static let defaultValue: CGFloat = 1.0
}

extension EnvironmentValues {
    var tvScale: CGFloat {
        get { self[TVScaleKey.self] }
        set { self[TVScaleKey.self] = newValue }
    }
}
