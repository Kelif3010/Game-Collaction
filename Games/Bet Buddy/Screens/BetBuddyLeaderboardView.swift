import SwiftUI

struct BetBuddyLeaderboardView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appModel: AppViewModel
    
    @State private var showResetStatsAlert = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                
                // Wir prüfen jetzt auf Ewige Daten ODER Aktuelle Daten
                if appModel.activeGroups.isEmpty && !hasAnyHighlights {
                    ContentUnavailableView(
                        "Keine Statistik",
                        systemImage: "chart.bar.xaxis",
                        description: Text("Spiele eine Runde, um Daten zu sammeln.")
                    )
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            
                            // 1. Highlights (Hall of Fame)
                            if hasAnyHighlights {
                                HighlightsSection()
                            } else {
                                Text("Noch keine Rekorde aufgestellt")
                                    .font(.subheadline)
                                    .foregroundStyle(Theme.mutedText)
                                    .padding(.top)
                            }
                            
                            // 2. EWIGE Rangliste (Alle Teams, die je gespielt haben)
                            if !appModel.allTimeLeaderboard.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Ewige Rangliste") // Text geändert!
                                        .font(.headline)
                                        .foregroundStyle(.white)
                                        .padding(.horizontal)
                                    
                                    ForEach(Array(appModel.allTimeLeaderboard.enumerated()), id: \.element.id) { index, entry in
                                        LeaderboardRow(index: index, entry: entry)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle("Bestenliste")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if hasAnyHighlights {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            showResetStatsAlert = true
                        } label: {
                            Image(systemName: "trash")
                                .foregroundStyle(.red)
                        }
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") { dismiss() }
                        .font(.headline)
                        .foregroundStyle(.white)
                }
            }
            .toolbarBackground(Theme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .alert("Statistik löschen?", isPresented: $showResetStatsAlert) {
                Button("Abbrechen", role: .cancel) { }
                Button("Löschen", role: .destructive) {
                    appModel.resetGlobalStats()
                }
            } message: {
                Text("Dies löscht alle Rekorde und die ewige Rangliste dauerhaft.")
            }
        }
    }
    
    private var hasAnyHighlights: Bool {
        appModel.highlights.maxWin != nil ||
        appModel.highlights.maxLoss != nil ||
        appModel.highlights.bestStreak != nil ||
        appModel.highlights.fastestWin != nil ||
        appModel.highlights.mostWinsLeader != nil
    }
    
    private func HighlightsSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Hall of Fame")
                    .font(.headline)
                    .foregroundStyle(.white)
                
                Spacer()
                
                Text("Alle Zeiten")
                    .font(.caption)
                    .foregroundStyle(Theme.mutedText)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Capsule())
            }
            .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    // 1. Höchster Sieg
                    if let win = appModel.highlights.maxWin {
                        HighlightCard(
                            title: "Höchster Sieg",
                            value: "+\(win.value)",
                            teamName: win.teamName,
                            color: .green,
                            icon: "trophy.fill"
                        )
                    }
                    
                    // 2. Dominanz
                    if let most = appModel.highlights.mostWinsLeader, most.value > 0 {
                        HighlightCard(
                            title: "Dominanz",
                            value: "\(most.value) Siege",
                            teamName: most.teamName,
                            color: .yellow,
                            icon: "crown.fill"
                        )
                    }
                    
                    // 3. Blitzmerker
                    if let fast = appModel.highlights.fastestWin {
                        HighlightCard(
                            title: "Blitzmerker",
                            value: "\(fast.value)s",
                            subLabel: "Restzeit auf der Uhr",
                            teamName: fast.teamName,
                            color: .cyan,
                            icon: "bolt.fill"
                        )
                    }
                    
                    // 4. Beste Serie
                    if let streak = appModel.highlights.bestStreak {
                        HighlightCard(
                            title: "Zocker-König",
                            value: "\(streak.value)x",
                            subLabel: "in Folge gespielt",
                            teamName: streak.teamName,
                            color: .orange,
                            icon: "flame.fill"
                        )
                    }
                    
                    // 5. Pechvogel
                    if let loss = appModel.highlights.maxLoss {
                        HighlightCard(
                            title: "Pechvogel",
                            value: "-\(loss.value)",
                            teamName: loss.teamName,
                            color: .red,
                            icon: "hand.thumbsdown.fill"
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

// UI für die Highlight Karte
private struct HighlightCard: View {
    var title: String
    var value: String
    var subLabel: String? = nil
    var teamName: String
    var color: Color
    var icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .font(.headline)
                    .padding(8)
                    .background(color.opacity(0.15))
                    .clipShape(Circle())
                
                Spacer()
                
                Circle()
                    .fill(color.opacity(0.3))
                    .frame(width: 8, height: 8)
                    .shadow(color: color, radius: 4)
            }
            
            Spacer()
            
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(color)
                .minimumScaleFactor(0.8)
                .lineLimit(1)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Theme.mutedText)
                    .textCase(.uppercase)
                
                Text(teamName)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                
                if let sub = subLabel {
                    Text(sub)
                        .font(.caption2)
                        .foregroundStyle(Theme.mutedText)
                        .lineLimit(1)
                }
            }
        }
        .padding(14)
        .frame(width: 155, height: 140)
        .background(
            LinearGradient(
                colors: [Color.white.opacity(0.08), Color.white.opacity(0.03)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        colors: [color.opacity(0.5), color.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
    }
}

private struct LeaderboardRow: View {
    let index: Int
    let entry: HighlightRecord // JETZT: Verwendet den persistenten Record
    
    var body: some View {
        HStack(spacing: 16) {
            Text("\(index + 1).")
                .font(.title3.weight(.bold))
                .foregroundStyle(rankColor(for: index))
                .frame(width: 30, alignment: .leading)

            // Farbe aus Hex string wiederherstellen (einfacher Fall)
            Circle()
                .fill(Color(hex: entry.colorHex) ?? .gray)
                .frame(width: 44, height: 44)
                .overlay(
                    Text(entry.teamName.prefix(1))
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                )

            Text(entry.teamName)
                .foregroundStyle(.white)
                .font(.headline)
            
            Spacer()
            
            Text("\(entry.value)")
                .font(.title3.bold())
                .foregroundStyle(.white)
            
            Text("Pkt")
                .font(.subheadline)
                .foregroundStyle(Theme.mutedText)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(rankColor(for: index).opacity(index == 0 ? 0.5 : 0.0), lineWidth: 1)
        )
    }
    
    private func rankColor(for index: Int) -> Color {
        switch index {
        case 0: return Color(red: 1.0, green: 0.84, blue: 0.0) // Gold
        case 1: return Color(red: 0.75, green: 0.75, blue: 0.75) // Silber
        case 2: return Color(red: 0.8, green: 0.5, blue: 0.2) // Bronze
        default: return Color.white.opacity(0.3)
        }
    }
}

// Hilfserweiterung für Hex-Farben
extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0

        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        let length = hexSanitized.count

        let r, g, b: Double
        if length == 6 {
            r = Double((rgb & 0xFF0000) >> 16) / 255.0
            g = Double((rgb & 0x00FF00) >> 8) / 255.0
            b = Double(rgb & 0x0000FF) / 255.0
        } else {
            return nil
        }

        self.init(red: r, green: g, blue: b)
    }
}

