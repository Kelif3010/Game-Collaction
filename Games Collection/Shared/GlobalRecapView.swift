import SwiftUI

struct GlobalRecapView: View {
    @StateObject private var statsManager = GlobalStatsManager.shared
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                // Hintergrund-Effekte
                VStack {
                    Circle().fill(Color.purple.opacity(0.3)).frame(width: 300).blur(radius: 60).offset(x: -100, y: -100)
                    Spacer()
                    Circle().fill(Color.blue.opacity(0.3)).frame(width: 300).blur(radius: 60).offset(x: 100, y: 100)
                }
                
                ScrollView {
                    VStack(spacing: 30) {
                        // Titel
                        Text("Session Recap")
                            .font(.system(size: 40, weight: .black, design: .rounded))
                            .foregroundStyle(LinearGradient(colors: [.white, .gray], startPoint: .top, endPoint: .bottom))
                            .padding(.top, 20)
                        
                        // Highlights
                        HStack(spacing: 20) {
                            if let mvp = statsManager.mvp, mvp.wins > 0 {
                                GlobalHighlightCard(
                                    title: "MVP",
                                    player: mvp,
                                    icon: "crown.fill",
                                    color: .yellow,
                                    detail: "\(mvp.wins) Siege"
                                )
                            }
                            
                            if let unlucky = statsManager.unluckyPlayer, unlucky.losses > 0 {
                                GlobalHighlightCard(
                                    title: "Pechvogel",
                                    player: unlucky,
                                    icon: "cloud.rain.fill",
                                    color: .blue,
                                    detail: "\(unlucky.losses) Niederlagen"
                                )
                            }
                        }
                        .padding(.horizontal)
                        
                        // Rangliste
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Rangliste")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.7))
                                .padding(.leading)
                            
                            VStack(spacing: 12) {
                                ForEach(sortedPlayers) { player in
                                    HStack {
                                        Text(player.name)
                                            .font(.headline)
                                            .foregroundColor(.white)
                                        Spacer()
                                        
                                        VStack(alignment: .trailing) {
                                            Text("\(Int(player.winRate * 100))% Win Rate")
                                                .font(.caption.bold())
                                                .foregroundColor(.green)
                                            Text("\(player.wins)S - \(player.losses)N")
                                                .font(.caption2)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    .padding()
                                    .background(Color.white.opacity(0.08))
                                    .cornerRadius(12)
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // Reset Button
                        Button(action: { statsManager.resetAllStats() }) {
                            Text("Statistik zurücksetzen")
                                .font(.caption)
                                .foregroundColor(.red.opacity(0.7))
                                .padding()
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fertig") { dismiss() }
                }
            }
        }
    }
    
    var sortedPlayers: [GlobalPlayerStats] {
        statsManager.stats.values.sorted { $0.wins > $1.wins }
    }
}

struct GlobalHighlightCard: View {
    let title: String
    let player: GlobalPlayerStats
    let icon: String
    let color: Color
    let detail: String
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 60, height: 60)
                Image(systemName: icon)
                    .font(.title)
                    .foregroundColor(color)
            }
            
            VStack(spacing: 4) {
                Text(title)
                    .font(.caption.bold())
                    .foregroundColor(color)
                    .textCase(.uppercase)
                
                Text(player.name)
                    .font(.title3.bold())
                    .foregroundColor(.white)
                
                Text(detail)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color.white.opacity(0.05))
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}
