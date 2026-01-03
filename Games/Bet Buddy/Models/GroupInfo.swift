import Foundation

struct GroupInfo: Identifiable, Hashable {
    let id: UUID
    let color: GroupColor
    var customName: String?
    var score: Int

    init(id: UUID = UUID(), color: GroupColor, customName: String? = nil, score: Int = 0) {
        self.id = id
        self.color = color
        self.customName = customName
        self.score = score
    }

    var displayName: String {
        let trimmed = customName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? color.fallbackName : trimmed
    }
}
