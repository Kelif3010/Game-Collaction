import SwiftUI

struct QuestionsScoreboardView: View {
    @ObservedObject var appModel: AppModel
    
    var sortedPlayers: [(player: Player, score: Int)] {
        appModel.players.map { ($0, appModel.getScore(for: $0.id)) }
            .sorted { $0.score > $1.score }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Rangliste")
                .font(.headline)
                .foregroundStyle(QuestionsStyle.mutedText)
                .textCase(.uppercase)
                .kerning(1)
            
            VStack(spacing: 8) {
                ForEach(Array(sortedPlayers.enumerated()), id: \.element.player.id) { index, entry in
                    HStack {
                        // Rank
                        Text("\(index + 1).")
                            .font(.headline.monospacedDigit())
                            .foregroundStyle(QuestionsStyle.mutedText)
                            .frame(width: 30, alignment: .leading)
                        
                        // Name
                        Text(entry.player.name)
                            .font(.headline)
                            .foregroundStyle(.white)
                        
                        Spacer()
                        
                        // Score
                        Text("\(entry.score) Pkt")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(entry.score > 0 ? QuestionsTheme.accent : .white.opacity(0.5))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 20)
    }
}
