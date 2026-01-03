import Foundation

struct LeaderboardEntry: Identifiable, Hashable {
    let id = UUID()
    let groupId: UUID
    let name: String
    let color: GroupColor
    let score: Int
}
