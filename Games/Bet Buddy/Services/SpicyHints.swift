import Foundation

enum SpicyHints {
    static let data: [String: [String]] = {
        guard let url = Bundle.main.url(forResource: "spicy_hints", withExtension: "json"),
              let raw = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([String: [String]].self, from: raw)
        else { return [:] }
        return decoded
    }()
}
