import SwiftUI
import Foundation

struct GameView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appModel: AppViewModel

    var onWin: (GameResult) -> Void
    var onLose: (GameResult) -> Void

    @State private var gameValue: Int = 0
    @State private var ended = false
    @State private var hintItems: [HintItem] = []
    
    @State private var allCachedHints: [String] = []
    @State private var solvedHints: Set<String> = []
    @State private var roundStartValue: Int = 0
    
    @StateObject private var gameTimer = GameTimer()
    
    @State private var showGiveUpAlert = false
    @State private var showExitAlert = false

    private var displayValue: Int {
        if appModel.currentChallenge.inputType == .alphabet {
            let current = (roundStartValue - gameValue) + 1
            return max(1, current)
        } else {
            return gameValue
        }
    }

    private var winningGroup: GroupInfo? {
        guard let maxId = appModel.voteCounters.max(by: { $0.value < $1.value })?.key,
              let group = appModel.activeGroups.first(where: { $0.id == maxId }) else { return nil }
        return group
    }

    private var winningColor: Color {
        winningGroup?.color.primary ?? Color.white
    }

    private var winningName: String {
        NSLocalizedString(winningGroup?.displayName ?? "Dein Buddy", comment: "")
    }

    private var winningScore: Int {
        guard let id = winningGroup?.id else { return 0 }
        return appModel.voteCounters[id, default: 0]
    }

    var body: some View {
        ZStack {
            BetBuddyBackgroundView(intensity: 0.8)

            VStack(spacing: 0) {
                VStack(spacing: 0) {
                    topBar.padding(.bottom, 10)
                    VStack(spacing: 6) {
                        Text("Team \(winningName)")
                            .font(.title3.weight(.heavy))
                            .foregroundStyle(winningColor)

                        if appModel.currentChallenge.inputType == .alphabet {
                            LetterFlipView(
                                value: displayValue,
                                remaining: gameValue,
                                color: winningColor
                            )
                        } else {
                            FlipCounterView(value: displayValue, color: winningColor)
                        }
                    }
                    .padding(.bottom, 16)

                    Text(appModel.currentChallenge.text)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white)
                        .font(.title3.weight(.semibold))
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 16)
                        .shadow(color: Color.black.opacity(0.5), radius: 2, x: 0, y: 1)

                    if appModel.isTimerEnabled {
                        Button {
                            if gameTimer.isPaused {
                                gameTimer.resume()
                            } else {
                                gameTimer.pause()
                            }
                            HapticsService.selection()
                        } label: {
                            HStack(spacing: 12) {
                                // Timer Icon
                                ZStack {
                                    Circle()
                                        .fill(
                                            gameTimer.isPaused
                                                ? BetBuddyTheme.accentGold.opacity(0.2)
                                                : (gameTimer.remaining <= 10 ? BetBuddyTheme.accentRuby.opacity(0.2) : Color.white.opacity(0.1))
                                        )
                                        .frame(width: 32, height: 32)

                                    Image(systemName: gameTimer.isPaused ? "play.fill" : "pause.fill")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(
                                            gameTimer.isPaused
                                                ? BetBuddyTheme.accentGold
                                                : (gameTimer.remaining <= 10 ? BetBuddyTheme.accentRuby : BetBuddyTheme.textSilver)
                                        )
                                }

                                Text(formatTime(gameTimer.remaining))
                                    .font(.system(size: 26, weight: .black, design: .monospaced))
                                    .foregroundStyle(
                                        gameTimer.isPaused
                                            ? BetBuddyTheme.accentGold
                                            : (gameTimer.remaining <= 10 ? BetBuddyTheme.accentRuby : BetBuddyTheme.textChampagne)
                                    )
                                    .contentTransition(.numericText())
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 20)
                            .background(
                                Capsule()
                                    .fill(Color.black.opacity(0.5))
                            )
                            .overlay(
                                Capsule()
                                    .stroke(
                                        gameTimer.isPaused
                                            ? BetBuddyTheme.accentGold.opacity(0.6)
                                            : (gameTimer.remaining <= 10 ? BetBuddyTheme.accentRuby.opacity(0.6) : BetBuddyTheme.accentGold.opacity(0.2)),
                                        lineWidth: 1.5
                                    )
                            )
                            .shadow(
                                color: gameTimer.remaining <= 10 && !gameTimer.isPaused
                                    ? BetBuddyTheme.accentRuby.opacity(0.3)
                                    : Color.clear,
                                radius: 8
                            )
                        }
                        .padding(.bottom, 10)
                    }
                }
                .padding(.horizontal, Theme.padding)

                if appModel.isHintsEnabled && !hintItems.isEmpty {
                    VStack(spacing: 0) {
                        // Header
                        HStack(spacing: 8) {
                            Image(systemName: "lightbulb.fill")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(BetBuddyTheme.accentGold)

                            Text("LÖSUNGEN")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundStyle(BetBuddyTheme.textSilver)
                                .tracking(2)

                            Spacer()

                            Text("\(hintItems.filter { $0.isChecked }.count)/\(hintItems.count)")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundStyle(BetBuddyTheme.accentEmerald)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 14)
                        .padding(.bottom, 8)

                        // Divider
                        Rectangle()
                            .fill(BetBuddyTheme.accentGold.opacity(0.15))
                            .frame(height: 1)
                            .padding(.horizontal, 16)

                        ScrollView(.vertical, showsIndicators: true) {
                            HintChipsView(items: $hintItems)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.black.opacity(0.4))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(BetBuddyTheme.accentGold.opacity(0.15), lineWidth: 1)
                    )
                    .padding(.horizontal, Theme.padding)
                    .padding(.top, 10)
                } else {
                    Spacer()
                }
                
                if !appModel.isHintsEnabled || hintItems.isEmpty { Spacer() } else { Spacer(minLength: 16) }

                VStack(spacing: 20) {
                    HStack(spacing: 30) {
                        // Linker Button (Korrektur / Zurück)
                        ZStack {
                            Circle()
                                .fill(Color.black.opacity(0.5))
                                .frame(width: 76, height: 76)

                            Circle()
                                .stroke(BetBuddyTheme.accentRuby.opacity(0.4), lineWidth: 2)
                                .frame(width: 76, height: 76)

                            Image(systemName: appModel.currentChallenge.inputType == .alphabet ? "chevron.down" : "chevron.up")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundStyle(BetBuddyTheme.textChampagne.opacity(0.8))
                        }
                        .onTapGesture {
                            gameValue += 1
                            HapticsService.impact(.light)
                        }

                        // Rechter Button (Geschafft!)
                        ZStack {
                            // Outer Glow
                            Circle()
                                .fill(BetBuddyTheme.accentEmerald.opacity(0.2))
                                .frame(width: 88, height: 88)

                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            BetBuddyTheme.accentGoldLight,
                                            BetBuddyTheme.accentGold
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 76, height: 76)

                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.4), Color.clear],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    ),
                                    lineWidth: 2
                                )
                                .frame(width: 76, height: 76)

                            Image(systemName: appModel.currentChallenge.inputType == .alphabet ? "chevron.up" : "chevron.down")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundStyle(BetBuddyTheme.textOnLight)
                        }
                        .shadow(color: BetBuddyTheme.accentGold.opacity(0.4), radius: 12, y: 4)
                        .onTapGesture {
                            gameValue = max(0, gameValue - 1)
                            HapticsService.impact(.medium)

                            if !appModel.isPartyMode {
                                startTimer()
                            }
                        }
                    }

                    // Give Up Button (Ruby Style)
                    Button {
                        HapticsService.warning()
                        showGiveUpAlert = true
                    } label: {
                        Text("Aufgeben")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(BetBuddyTheme.accentRuby)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                Capsule()
                                    .fill(BetBuddyTheme.accentRuby.opacity(0.15))
                            )
                            .overlay(
                                Capsule()
                                    .stroke(BetBuddyTheme.accentRuby.opacity(0.4), lineWidth: 1)
                            )
                    }
                }
                .padding(.horizontal, Theme.padding).padding(.bottom, 12)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .alert("Aufgeben?", isPresented: $showGiveUpAlert) {
            Button("Abbrechen", role: .cancel) { }
            Button("Ja, aufgeben", role: .destructive) { triggerLose() }
        } message: { Text("Bist du sicher, dass du aufgeben möchtest? Das wird als Niederlage gewertet.") }
        .alert("Spiel beenden?", isPresented: $showExitAlert) {
            Button("Abbrechen", role: .cancel) { }
            Button("Beenden", role: .destructive) {
                dismiss()
            }
        } message: {
            Text("Der aktuelle Spielstand geht verloren. Es werden keine Punkte gewertet.")
        }
        .onAppear {
            gameValue = winningScore
            roundStartValue = winningScore
            DispatchQueue.main.async { startTimer() }
            loadHints()
            
            // NEU: Streak aktualisieren, sobald das Spiel startet!
            if let winnerId = winningGroup?.id {
                appModel.updatePlayStreak(for: winnerId)
            }
        }
        .onChange(of: gameValue) { _, _ in
            triggerWinIfNeeded()
            if appModel.currentChallenge.inputType == .alphabet {
                updateVisibleHints()
            }
        }
        .onChange(of: hintItems) { _, items in
            for item in items {
                if item.isChecked {
                    solvedHints.insert(item.text)
                } else {
                    solvedHints.remove(item.text)
                }
            }
        }
        .onDisappear {
            gameTimer.stop()
        }
    }

    private var topBar: some View {
        HStack {
            // Casino-Style Header
            HStack(spacing: 6) {
                Image(systemName: "suit.club.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(BetBuddyTheme.accentGold.opacity(0.6))

                Text("SHOWDOWN")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(BetBuddyTheme.textGold)
                    .tracking(2)

                Image(systemName: "suit.heart.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(BetBuddyTheme.accentRuby.opacity(0.6))
            }

            Spacer()

            Button {
                HapticsService.impact(.medium)
                showExitAlert = true
            } label: {
                Image(systemName: "xmark")
                    .font(.headline.bold())
                    .foregroundStyle(BetBuddyTheme.textChampagne)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.08))
                            .overlay(
                                Circle()
                                    .stroke(BetBuddyTheme.accentGold.opacity(0.2), lineWidth: 1)
                            )
                    )
            }
        }
    }

    private func formatTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", mins, secs)
    }

    private func startTimer() {
        guard appModel.isTimerEnabled else { return }
        gameTimer.start(seconds: appModel.timerSelection) { triggerLose() }
    }

    private func triggerWinIfNeeded() {
            guard !ended, gameValue == 0 else { return }
            ended = true
            gameTimer.stop()
            
            if let winner = winningGroup {
                // UPDATE: Hier übergeben wir jetzt gameTimer.remaining
                appModel.awardScore(
                    to: winner,
                    amount: roundStartValue,
                    timeRemaining: gameTimer.remaining
                )
            }
            
            let result = GameResult(
                outcome: .win,
                finalScore: gameValue,
                challengeText: appModel.currentChallenge.text,
                inputType: appModel.currentChallenge.inputType,
                leaderboard: appModel.leaderboard
            )
            onWin(result)
        }

    private func triggerLose() {
        guard !ended else { return }
        ended = true
        gameTimer.stop()

        if appModel.isPenaltyEnabled, let loser = winningGroup {
            let penalty = PenaltyService.penaltyAmount(
                level: appModel.penaltyLevel,
                startValue: roundStartValue,
                remainingValue: gameValue
            )
            appModel.deductScore(for: loser, amount: penalty)
        }

        let result = GameResult(
            outcome: .lose,
            finalScore: gameValue,
            challengeText: appModel.currentChallenge.text,
            inputType: appModel.currentChallenge.inputType,
            leaderboard: appModel.leaderboard
        )
        onLose(result)
    }

    private func loadHints() {
        allCachedHints = BetBuddyHintService.hintItems(for: appModel.currentChallenge)
        solvedHints.removeAll()
        updateVisibleHints()
    }

    private func updateVisibleHints() {
        if appModel.currentChallenge.inputType == .alphabet {
            let letterIndex = displayValue
            let currentLetterChar = String(UnicodeScalar(64 + letterIndex) ?? "A")
            
            let filtered = allCachedHints.filter { word in
                word.trimmingCharacters(in: .whitespaces)
                    .uppercased()
                    .hasPrefix(currentLetterChar)
            }
            
            let sorted = filtered.sorted { $0.localizedStandardCompare($1) == .orderedAscending }
            hintItems = sorted.map { HintItem(text: $0, isChecked: solvedHints.contains($0)) }
            
        } else {
            let sorted = allCachedHints.sorted { $0.localizedStandardCompare($1) == .orderedAscending }
            hintItems = sorted.map { HintItem(text: $0, isChecked: solvedHints.contains($0)) }
        }
    }
}
