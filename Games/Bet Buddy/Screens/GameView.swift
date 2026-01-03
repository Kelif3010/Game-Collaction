import SwiftUI

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
        winningGroup?.displayName ?? "Dein Buddy"
    }

    private var winningScore: Int {
        guard let id = winningGroup?.id else { return 0 }
        return appModel.voteCounters[id, default: 0]
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

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
                                Image(systemName: gameTimer.isPaused ? "play.fill" : "pause.fill")
                                    .font(.title3)
                                    .foregroundStyle(
                                        gameTimer.isPaused ? Color.orange :
                                        (gameTimer.remaining <= 10 ? Color.red : Theme.mutedText)
                                    )
                                
                                Text(formatTime(gameTimer.remaining))
                                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                                    .foregroundStyle(gameTimer.isPaused ? Color.orange : .white)
                                    .contentTransition(.numericText())
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 24)
                            .background(gameTimer.isPaused ? Color.orange.opacity(0.15) : Color.white.opacity(0.08))
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(
                                        gameTimer.isPaused ? Color.orange.opacity(0.8) :
                                        (gameTimer.remaining <= 10 ? Color.red.opacity(0.8) : Color.white.opacity(0.1)),
                                        lineWidth: 1
                                    )
                            )
                        }
                        .padding(.bottom, 10)
                    }
                }
                .padding(.horizontal, Theme.padding)

                if appModel.isHintsEnabled && !hintItems.isEmpty {
                    VStack(spacing: 0) {
                        HStack(spacing: 6) {
                            Image(systemName: "lightbulb.fill")
                                .font(.caption).foregroundStyle(Theme.mutedText)
                            Text("LÖSUNGEN / HINWEISE")
                                .font(.caption.weight(.bold)).foregroundStyle(Theme.mutedText).textCase(.uppercase)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.horizontal, 16).padding(.top, 16).padding(.bottom, 8)

                        ScrollView(.vertical, showsIndicators: true) {
                            HintChipsView(items: $hintItems)
                                .padding(.horizontal, 16).padding(.bottom, 16)
                        }
                    }
                    .background(Color.black.opacity(0.25))
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.white.opacity(0.08), lineWidth: 1))
                    .padding(.horizontal, Theme.padding).padding(.top, 10)
                } else {
                    Spacer()
                }
                
                if !appModel.isHintsEnabled || hintItems.isEmpty { Spacer() } else { Spacer(minLength: 16) }

                VStack(spacing: 20) {
                    HStack(spacing: 30) {
                        // Linker Button (Zurück)
                        Circle()
                            .fill(Color.white.opacity(0.08))
                            .frame(width: 80, height: 80)
                            .overlay(
                                Image(systemName: appModel.currentChallenge.inputType == .alphabet ? "chevron.down" : "chevron.up")
                                    .font(.title).foregroundStyle(Color.white.opacity(0.7))
                            )
                            .onTapGesture {
                                gameValue += 1
                                HapticsService.impact(.light)
                            }

                        // Rechter Button (Weiter / Geschafft)
                        Circle()
                            .fill(Color.white)
                            .frame(width: 80, height: 80)
                            .overlay(
                                Image(systemName: appModel.currentChallenge.inputType == .alphabet ? "chevron.up" : "chevron.down")
                                    .font(.title).foregroundStyle(Color.black)
                            )
                            .shadow(color: Color.black.opacity(0.3), radius: 10, y: 4)
                            .onTapGesture {
                                gameValue = max(0, gameValue - 1)
                                HapticsService.impact(.medium)
                                
                                if !appModel.isPartyMode {
                                    startTimer()
                                }
                            }
                    }

                    PrimaryButton(title: "Aufgeben") {
                        HapticsService.warning()
                        showGiveUpAlert = true
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
            Text("Bet Buddy").foregroundStyle(.white).font(.headline)
            Spacer()
            Button {
                HapticsService.impact(.medium)
                showExitAlert = true
            } label: {
                Image(systemName: "xmark").font(.headline.bold()).foregroundStyle(.white)
                    .frame(width: 36, height: 36).background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
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
