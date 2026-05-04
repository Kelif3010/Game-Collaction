import Foundation

struct BetBuddyHintService {

    private static let allHints: [String: [String]] = {
        var combined = ClassicHints.data
        combined.merge(PartyHints.data)   { _, new in new }
        combined.merge(SpicyHints.data)   { _, new in new }
        combined.merge(AlphabetHints.data) { _, new in new }
        return combined
    }()

    static func hintItems(for challenge: Challenge) -> [String] {
        guard let items = allHints[challenge.text] else { return [] }
        return items.sorted { $0.localizedStandardCompare($1) == .orderedAscending }
    }
}
