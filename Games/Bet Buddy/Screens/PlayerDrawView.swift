import SwiftUI
import SFSafeSymbols

struct PlayerDrawView: View {
    @Environment(AppViewModel.self) private var appModel
    var onContinue: () -> Void

    @State private var spinCounters: [UUID: Int] = [:]
    @State private var lockedGroups: Set<UUID> = []
    @State private var flippingGroups: Set<UUID> = []
    @State private var coinFlipTriggers: [UUID: Int] = [:]
    @State private var flipCompletionTasks: [UUID: Task<Void, Never>] = [:]
    @State private var showButton = false
    @State private var headerAppeared = false

    var body: some View {
        ZStack {
            BetBuddyBackgroundView(intensity: 0.7)

            VStack(spacing: 0) {
                topTitle
                    .padding(.top, 16)

                Spacer()

                VStack(spacing: 14) {
                    ForEach(Array(appModel.activeGroups.enumerated()), id: \.element.id) { index, group in
                        teamDrawCard(group: group, spinDelay: Double(index) * 0.6)
                    }
                }
                .padding(.horizontal, 24)

                Spacer()

                if showButton {
                    continueButton
                        .padding(.horizontal, 24)
                        .padding(.bottom, 32)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            appModel.randomizeStartingPlayers()
            lockedGroups = []
            flippingGroups = []
            showButton = false
            spinCounters = Dictionary(uniqueKeysWithValues: appModel.activeGroups.map { ($0.id, 0) })
            coinFlipTriggers = Dictionary(uniqueKeysWithValues: appModel.activeGroups.map { ($0.id, 0) })
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                headerAppeared = true
            }
            startSpinning()
        }
        .onDisappear {
            flipCompletionTasks.values.forEach { $0.cancel() }
            flipCompletionTasks.removeAll()
        }
    }

    // MARK: - Header

    private var topTitle: some View {
        VStack(spacing: 8) {
            Text("🎲")
                .font(.system(size: 44))
                .scaleEffect(headerAppeared ? 1.0 : 0.5)
                .opacity(headerAppeared ? 1.0 : 0)

            Text("AUSLOSUNG")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(BetBuddyTheme.textSilver)
                .tracking(4)
                .opacity(headerAppeared ? 1.0 : 0)

            Text("Wer startet?")
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundStyle(BetBuddyTheme.textChampagne)
                .opacity(headerAppeared ? 1.0 : 0)
        }
    }

    // MARK: - Team Draw Card

    private func teamDrawCard(group: GroupInfo, spinDelay: Double) -> some View {
        let isLocked = lockedGroups.contains(group.id)
        let tick = spinCounters[group.id, default: 0]
        let names = playerNames(for: group)

        let activeIndex = tick % names.count
        let activeName = isLocked ? group.activePlayerName : names[activeIndex]
        let biddingName = isLocked ? group.biddingPlayerName : names[(activeIndex + 1) % names.count]

        return HStack(spacing: 14) {
            // Team-Farb-Indikator
            RoundedRectangle(cornerRadius: 3)
                .fill(group.color.gradient)
                .frame(width: 5, height: 52)

            VStack(alignment: .leading, spacing: 3) {
                Text(group.displayName.uppercased())
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(group.color.accent)
                    .tracking(2)

                HStack(spacing: 6) {
                    Text("MACHT ES")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(BetBuddyTheme.textSilver)
                        .tracking(1)

                    Text(activeName)
                        .font(.system(size: 17, weight: .black, design: .rounded))
                        .foregroundStyle(isLocked ? group.color.primary : BetBuddyTheme.textChampagne)
                        .id("active-\(group.id)-\(activeName)")
                        .transition(.opacity)
                        .animation(.easeInOut(duration: 0.06), value: activeName)
                }

                HStack(spacing: 6) {
                    Text(group.playerSlotCount > 2 ? "NÄCHSTE/R" : "BIETET")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(BetBuddyTheme.textSilver)
                        .tracking(1)

                    Text(biddingName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(BetBuddyTheme.textSilver)
                        .id("bidding-\(group.id)-\(biddingName)")
                        .transition(.opacity)
                        .animation(.easeInOut(duration: 0.06), value: biddingName)
                }
            }

            Spacer()

            // Lock-Icon wenn fertig
            if isLocked {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(group.color.primary)
                    .transition(.scale.combined(with: .opacity))
            } else if flippingGroups.contains(group.id) {
                BetBuddyLottieView(
                    filename: "3D coin flip",
                    loopMode: .playOnce,
                    isPlaying: true,
                    contentMode: .scaleAspectFit,
                    animationSpeed: 1.15,
                    playTrigger: coinFlipTriggers[group.id, default: 0]
                ) {
                    finishCoinFlip(for: group.id)
                }
                .frame(width: 56, height: 56)
            } else {
                Image(systemName: "shuffle")
                    .font(.system(size: 18))
                    .foregroundStyle(BetBuddyTheme.textSilver.opacity(0.4))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(isLocked ? 0.55 : 0.35))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            isLocked ? group.color.primary.opacity(0.45) : BetBuddyTheme.accentGold.opacity(0.12),
                            lineWidth: isLocked ? 1.5 : 1
                        )
                )
        )
        .shadow(color: isLocked ? group.color.primary.opacity(0.15) : .clear, radius: 10, y: 4)
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: isLocked)
    }

    // MARK: - Continue Button

    private var continueButton: some View {
        Button {
            HapticsService.success()
            onContinue()
        } label: {
            HStack(spacing: 12) {
                Text("LOS GEHT'S")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .tracking(2)
                Image(systemName: "arrow.right")
                    .font(.system(size: 16, weight: .bold))
            }
            .foregroundStyle(BetBuddyTheme.textOnLight)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                Capsule()
                    .fill(BetBuddyTheme.goldGradient)
                    .shadow(color: BetBuddyTheme.accentGold.opacity(0.5), radius: 15, y: 5)
            )
            .overlay(
                Capsule()
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.4), Color.clear],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
            )
        }
    }

    // MARK: - Helpers

    private func playerNames(for group: GroupInfo) -> [String] {
        group.displayPlayerNames
    }

    // MARK: - Spin Animation

    private func startSpinning() {
        let groups = appModel.activeGroups

        for (index, group) in groups.enumerated() {
            let totalTicks = 18 + index * 6  // 1.8s + 0.6s Staffel pro Team

            Task { @MainActor in
                for tick in 0..<totalTicks {
                    try? await Task.sleep(for: .milliseconds(100))
                    spinCounters[group.id] = tick
                }

                flippingGroups.insert(group.id)
                coinFlipTriggers[group.id, default: 0] += 1
                scheduleFlipFallback(for: group.id)
            }
        }
    }

    private func finishCoinFlip(for groupID: UUID) {
        guard flippingGroups.contains(groupID) else { return }
        flippingGroups.remove(groupID)
        flipCompletionTasks[groupID]?.cancel()
        flipCompletionTasks[groupID] = nil

        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            _ = lockedGroups.insert(groupID)
        }
        HapticsService.impact(.medium)

        if lockedGroups.count == appModel.activeGroups.count {
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(500))
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    showButton = true
                }
                HapticsService.impact(.light)
            }
        }
    }

    private func scheduleFlipFallback(for groupID: UUID) {
        flipCompletionTasks[groupID]?.cancel()
        flipCompletionTasks[groupID] = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(1400))
            guard !Task.isCancelled else { return }
            finishCoinFlip(for: groupID)
        }
    }
}

#Preview {
    PlayerDrawView(onContinue: {})
        .environment(AppViewModel())
}
