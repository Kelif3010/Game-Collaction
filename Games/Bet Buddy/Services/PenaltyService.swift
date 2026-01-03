import Foundation

struct PenaltyService {
    static func penaltyAmount(level: PenaltyLevel, startValue: Int, remainingValue: Int) -> Int {
        let start = max(0, startValue)
        let remaining = max(0, remainingValue)
        switch level {
        case .normal:
            return remaining
        case .medium:
            return Int(ceil(Double(start) / 2.0))
        case .hardcore:
            return start
        }
    }
}
