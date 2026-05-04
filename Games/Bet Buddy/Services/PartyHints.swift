import Foundation

enum PartyHints {
    static let data: [String: [String]] = {
        guard let url = Bundle.main.url(forResource: "party_hints", withExtension: "json"),
              let raw = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([String: [String]].self, from: raw)
        else { return [:] }
        return decoded
    }()
}
