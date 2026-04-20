import SwiftUI

struct PlayerDrawView: View {
    @EnvironmentObject private var appModel: AppViewModel
    var onContinue: () -> Void

    @State private var spinCounters: [UUID: Int] = [:]
    @State private var lockedGroups: Set<UUID> = []
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
            spinCounters = Dictionary(uniqueKeysWithValues: appModel.activeGroups.map { ($0.id, 0) })
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                headerAppeared = true
            }
            startSpinning()
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

        let activeName = isLocked ? group.activePlayerName : names[tick % 2]
        let biddingName = isLocked ? group.biddingPlayerName : names[(tick + 1) % 2]

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
                    Text("BIETET")
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
        [
            group.player1Name?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
                ? group.player1Name! : "Spieler 1",
            group.player2Name?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
                ? group.player2Name! : "Spieler 2"
        ]
    }

    // MARK: - Spin Animation

    private func startSpinning() {
        let groups = appModel.activeGroups

        for (index, group) in groups.enumerated() {
            let totalTicks = 18 + index * 6  // 1.8s + 0.6s Staffel pro Team

            Task { @MainActor in
                for tick in 0..<totalTicks {
                    try? await Task.sleep(nanoseconds: 100_000_000)
                    spinCounters[group.id] = tick
                }

                // Einrasten
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    lockedGroups.insert(group.id)
                }
                HapticsService.impact(.medium)

                // Button nach dem letzten Team zeigen
                if index == groups.count - 1 {
                    try? await Task.sleep(nanoseconds: 500_000_000)
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        showButton = true
                    }
                    HapticsService.impact(.light)
                }
            }
        }
    }
}
