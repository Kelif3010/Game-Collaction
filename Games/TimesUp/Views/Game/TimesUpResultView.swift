import SwiftUI

// MARK: - Game End View
struct GameEndView: View {
    @ObservedObject var viewModel: TimesUpGameViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            TimesUpStyle.backgroundGradient
                .ignoresSafeArea()

            VStack(spacing: 30) {
                Spacer()

                Text(LocalizedStringKey("Spiel beendet!"))
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(TimesUpStyle.primaryGradient)
                    .multilineTextAlignment(.center)

                if viewModel.scoreRevealSnapshots.isEmpty {
                    ScoreboardView(teams: viewModel.gameState.settings.teams, showFinal: true)
                } else {
                    PenaltyRevealScoreboardView(
                        teams: viewModel.gameState.settings.teams,
                        snapshots: viewModel.scoreRevealSnapshots
                    )
                }

                Spacer()

                VStack(spacing: 12) {
                    // Quick Restart: Gleiche Teams, Runde 1 neu
                    Button(action: {
                        TimesUpHaptics.impact(.heavy)
                        viewModel.restartWithSameTeams()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.counterclockwise.circle.fill")
                            Text(LocalizedStringKey("Nochmal! (gleiche Teams)"))
                                .fontWeight(.bold)
                        }
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(TimesUpStyle.primaryGradient.opacity(0.85))
                        .clipShape(RoundedRectangle(cornerRadius: TimesUpStyle.rowCornerRadius))
                    }

                    // Neues Spiel: Setup-Screen öffnen
                    Button(action: {
                        TimesUpHaptics.impact(.medium)
                        viewModel.startGame()
                        dismiss()
                    }) {
                        Text(LocalizedStringKey("Neues Spiel"))
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 60)
                            .background(TimesUpStyle.startButtonGradient)
                            .clipShape(RoundedRectangle(cornerRadius: TimesUpStyle.rowCornerRadius))
                            .shadow(
                                color: TimesUpStyle.shadowColor(.green),
                                radius: TimesUpStyle.shadowRadius,
                                x: 0,
                                y: 5
                            )
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, TimesUpStyle.bottomPadding)
            }
            .padding()
        }
        .onAppear {
            recordStats()
        }
    }

    private func recordStats() {
        let sorted = viewModel.gameState.settings.teams.sorted { $0.score > $1.score }
        guard let topScore = sorted.first?.score, topScore > 0 else { return }

        let winners = sorted.filter { $0.score == topScore }
        let others = sorted.filter { $0.score < topScore }

        for winner in winners {
            GlobalStatsManager.shared.recordWin(for: winner.name)
        }
        for team in others {
            GlobalStatsManager.shared.recordParticipation(for: team.name)
        }
    }
}

// MARK: - Scoreboard
struct ScoreboardView: View {
    let teams: [Team]
    var showFinal: Bool = false
    
    var sortedTeams: [Team] {
        teams.sorted { $0.score > $1.score }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(showFinal ? LocalizedStringKey("🏆 Endstand") : LocalizedStringKey("Zwischenstand"))
                .font(.title2)
                .fontWeight(.bold)
            
            ForEach(Array(sortedTeams.enumerated()), id: \.element.id) { index, team in
                HStack {
                    // Platzierung
                    Text("\(index + 1).")
                        .font(.headline)
                        .fontWeight(.bold)
                        .frame(width: 30, alignment: .leading)
                    
                    // Team Name
                    Text(team.name)
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Punkte
                    Text("\(team.score)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(index == 0 && showFinal ? .yellow : .primary)
                        .contentTransition(.numericText())
                        .animation(.spring(response: 0.4), value: team.score)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(index == 0 && showFinal ? Color.yellow.opacity(0.2) : Color(.systemGray5))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .primary.opacity(0.05), radius: 2, x: 0, y: 1)
            }
        }
        .padding()
        .background(Color(.systemGray5))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .primary.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Dramatic Penalty Reveal

struct PenaltyRevealScoreboardView: View {
    let teams: [Team]
    let snapshots: [UUID: TimesUpGameViewModel.ScoreRevealSnapshot]
    
    @State private var revealedTeamIDs: Set<UUID> = []
    @State private var activeTeamID: UUID?
    @State private var showInterimScores = true
    @State private var showFinalScores = false
    
    private var sortedTeams: [Team] {
        teams.sorted { $0.score > $1.score }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("🏆 Finale Enthüllung")
                .font(.largeTitle)
                .fontWeight(.heavy)
                .foregroundStyle(
                    LinearGradient(colors: [.yellow, .orange, .red], startPoint: .leading, endPoint: .trailing)
                )
                .shadow(color: .yellow.opacity(0.6), radius: 8, x: 0, y: 0)
            
            VStack(spacing: 16) {
                ForEach(Array(sortedTeams.enumerated()), id: \.element.id) { index, team in
                    PenaltyRevealRow(
                        team: team,
                        snapshot: snapshots[team.id],
                        isLeader: index == 0,
                        isRevealed: revealedTeamIDs.contains(team.id),
                        isActiveReveal: activeTeamID == team.id,
                        showInterimScores: showInterimScores,
                        showFinalScores: showFinalScores
                    )
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(Color(.systemBackground).opacity(0.9))
                    .shadow(color: .black.opacity(0.08), radius: 15, x: 0, y: 10)
            )
        }
        .padding()
        .onAppear {
            startRevealSequence()
        }
    }
    
    private func startRevealSequence() {
        let delayBeforeReveal = 2.0
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delayBeforeReveal) {
            showInterimScores = false
            runPenaltyAnimations()
        }
        
        let totalRevealDuration = delayBeforeReveal + (Double(sortedTeams.count) * 1.2) + 1.0
        DispatchQueue.main.asyncAfter(deadline: .now() + totalRevealDuration) {
            showFinalScores = true
        }
    }
    
    private func runPenaltyAnimations() {
        let delayStep = 1.2
        for (index, team) in sortedTeams.enumerated() {
            let delay = Double(index) * delayStep
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                activeTeamID = team.id
                _ = withAnimation(.spring(response: 0.6, dampingFraction: 0.65, blendDuration: 0.3)) {
                    revealedTeamIDs.insert(team.id)
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                    if activeTeamID == team.id {
                        activeTeamID = nil
                    }
                }
            }
        }
    }
}

struct PenaltyRevealRow: View {
    let team: Team
    let snapshot: TimesUpGameViewModel.ScoreRevealSnapshot?
    let isLeader: Bool
    let isRevealed: Bool
    let isActiveReveal: Bool
    let showInterimScores: Bool
    let showFinalScores: Bool
    
    @State private var showPenaltyBadge = false
    @State private var glowPulse = false
    @State private var wobbleAngle: Double = 0
    @State private var isShaking = false
    
    private var preScore: Int {
        snapshot?.preScore ?? team.score
    }
    
    private var finalScore: Int {
        snapshot?.finalScore ?? team.score
    }
    
    private var penalty: Int {
        snapshot?.penalty ?? 0
    }
    
    private var displayScore: Int {
        if showFinalScores || isRevealed {
            return finalScore
        } else {
            return preScore
        }
    }
    
    private var scoreStyle: AnyShapeStyle {
        if showFinalScores || isRevealed {
            return AnyShapeStyle(
                LinearGradient(colors: [.yellow, .orange], startPoint: .topLeading, endPoint: .bottomTrailing)
            )
        } else {
            return AnyShapeStyle(
                LinearGradient(colors: [.green, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
            )
        }
    }
    
    private var cardFillStyle: AnyShapeStyle {
        if isLeader && (showFinalScores || isRevealed) {
            return AnyShapeStyle(
                LinearGradient(colors: [.yellow.opacity(0.35), .orange.opacity(0.35)], startPoint: .topLeading, endPoint: .bottomTrailing)
            )
        } else {
            return AnyShapeStyle(Color(.systemGray6))
        }
    }
    
    var body: some View {
        ZStack(alignment: .trailing) {
            HStack {
                // Platzierung/Name block
                VStack(alignment: .leading, spacing: 4) {
                    Text(team.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(isRevealed ? "Endstand" : "Zwischenstand")
                        .opacity(showFinalScores ? 0.0 : 1.0)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Text("\(displayScore)")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundStyle(scoreStyle)
                    .shadow(color: (isRevealed ? Color.orange : Color.blue).opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(cardFillStyle)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(isActiveReveal ? Color.red.opacity(glowPulse ? 0.8 : 0.2) : Color.clear, lineWidth: 2)
                            .animation(isActiveReveal ? .easeInOut(duration: 0.6).repeatForever(autoreverses: true) : .default, value: glowPulse)
                    )
            )
            .scaleEffect(isActiveReveal ? 1.02 : 1.0)
            .rotationEffect(.degrees(wobbleAngle))
            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isActiveReveal)
            
            if showPenaltyBadge && penalty > 0 && !showFinalScores {
                PenaltyBadgeView(penalty: penalty)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .onChange(of: isActiveReveal) { oldValue, newValue in
            guard newValue else { return }
            glowPulse = true
            if penalty > 0 {
                withAnimation(.easeOut(duration: 0.45)) {
                    showPenaltyBadge = true
                }
            }
        }
        .onChange(of: showFinalScores) { oldValue, showFinal in
            if showFinal {
                withAnimation {
                    showPenaltyBadge = false
                }
                stopShaking()
            }
        }
        .onChange(of: showInterimScores) { oldValue, isInterim in
            if isInterim {
                startShaking()
            } else {
                stopShaking()
            }
        }
        .onAppear {
            if showInterimScores {
                startShaking()
            }
        }
    }
    
    private func startShaking() {
        guard !isShaking else { return }
        isShaking = true
        animateWobble(to: 3)
    }
    
    private func stopShaking() {
        guard isShaking else { return }
        isShaking = false
        withAnimation(.easeOut(duration: 0.2)) {
            wobbleAngle = 0
        }
    }
    
    private func animateWobble(to target: Double) {
        guard isShaking else { return }
        withAnimation(.easeInOut(duration: 0.12)) {
            wobbleAngle = target
        }
        let nextTarget: Double = target > 0 ? -3 : 3
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            animateWobble(to: nextTarget)
        }
    }
}

struct PenaltyBadgeView: View {
    let penalty: Int
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "flame.fill")
                .font(.caption)
            Text("-\(penalty)")
                .font(.headline)
                .fontWeight(.heavy)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .background(
            Capsule()
                .fill(
                    LinearGradient(colors: [.red, .orange], startPoint: .leading, endPoint: .trailing)
                )
        )
        .foregroundStyle(.white)
        .shadow(color: .red.opacity(0.4), radius: 8, x: 0, y: 4)
    }
}

