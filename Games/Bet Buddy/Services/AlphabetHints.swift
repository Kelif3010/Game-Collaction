import Foundation

enum AlphabetHints {
    static let data: [String: [String]] = {
        guard let url = Bundle.main.url(forResource: "alphabet_hints", withExtension: "json"),
              let raw = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([String: [String]].self, from: raw)
        else { return [:] }
        return decoded
    }()
}
