import Foundation

enum ClassicHints {
    static let data: [String: [String]] = {
        guard let url = Bundle.main.url(forResource: "classic_hints", withExtension: "json"),
              let raw = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([String: [String]].self, from: raw)
        else { return [:] }
        return decoded
    }()
}
