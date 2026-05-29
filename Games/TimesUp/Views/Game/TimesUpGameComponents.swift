import SwiftUI

struct TeamBadgeBar: View {
    @ObservedObject var viewModel: TimesUpGameViewModel
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(Array(viewModel.gameState.settings.teams.enumerated()), id: \.element.id) { entry in
                let team = entry.element
                TeamBadgeView(
                    team: team,
                    isActive: entry.offset == viewModel.gameState.currentTeamIndex
                )
            }
        }
    }
}

private struct TeamBadgeView: View {
    let team: Team
    let isActive: Bool

    private var initials: String {
        String(team.name.prefix(2)).uppercased()
    }

    var body: some View {
        VStack(spacing: 2) {
            ZStack {
                Circle()
                    .fill(
                        isActive
                        ? AnyShapeStyle(TimesUpStyle.primaryGradient)
                        : AnyShapeStyle(Color.gray.opacity(0.3))
                    )
                    .frame(width: 32, height: 32)
                    .overlay(
                        Circle()
                            .stroke(
                                isActive ? Color.blue : Color.gray.opacity(0.5),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: isActive ? .blue.opacity(0.5) : .clear, radius: 4)

                Text(initials)
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(isActive ? .white : .gray)
            }

            // Score unter dem Badge
            Text("\(team.score)")
                .font(.system(size: 10, weight: .heavy, design: .rounded))
                .foregroundStyle(isActive ? .white : .gray.opacity(0.7))
                .contentTransition(.numericText())
                .animation(.spring(response: 0.3), value: team.score)
        }
    }
}

struct ScoreBurstBar: View {
    @ObservedObject var viewModel: TimesUpGameViewModel
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(viewModel.gameState.settings.teams) { team in
                ScoreBurstStack(bursts: viewModel.scoreBursts.filter { $0.teamId == team.id })
                    .frame(width: 54, alignment: .center)
            }
        }
    }
}

private struct ScoreBurstStack: View {
    let bursts: [TimesUpGameViewModel.ScoreBurst]
    
    var body: some View {
        ZStack {
            ForEach(bursts) { burst in
                ScoreBurstLabel(burst: burst)
            }
        }
        .allowsHitTesting(false)
    }
}

private struct ScoreBurstLabel: View {
    let burst: TimesUpGameViewModel.ScoreBurst
    @State private var animate = false
    
    private var burstColor: Color {
        burst.isNegative ? .red : .green
    }
    
    var body: some View {
        Text(burst.text)
            .font(.caption2.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(burstColor.opacity(0.9))
            .clipShape(Capsule())
            .shadow(color: burstColor.opacity(0.4), radius: 6, x: 0, y: 3)
            .offset(y: animate ? 34 : -12)
            .opacity(animate ? 0 : 1)
            .scaleEffect(animate ? 0.85 : 1.05)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.2)) {
                    animate = true
                }
            }
    }
}


// MARK: - Game Header
struct GameHeaderView: View {
    @ObservedObject var viewModel: TimesUpGameViewModel
    
    var body: some View {
        VStack(spacing: 15) {
            // Runden-Info
            HStack {
                Text(viewModel.gameState.currentRound.title)
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Text(viewModel.gameState.currentRound.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            // Timer und Team
            HStack {
                // Aktuelles Team
                if let team = viewModel.gameState.currentTeam {
                    VStack(alignment: .leading) {
                        Text("Team:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(team.name)
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                }
                
                Spacer()
                
                // Verbleibende Begriffe für aktuelles Team
                VStack(alignment: .center) {
                    Text("Begriffe übrig:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(viewModel.gameState.remainingTermsCount)")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(.orange)
                }
                
                Spacer()
                
                // Timer
                    VStack(alignment: .trailing) {
                        Text("Zeit:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(viewModel.formattedTimeRemaining)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundStyle(viewModel.gameState.turnTimeRemaining < 10 ? .red : .primary)
                    }
            }
            .padding()
            .background(Color(.systemGray5))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .primary.opacity(0.08), radius: 3, x: 0, y: 1)
        }
    }
}

