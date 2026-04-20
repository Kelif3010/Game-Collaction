import SwiftUI

struct ChallengeStartView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appModel: AppViewModel

    var onStart: () -> Void
    var onClose: () -> Void

    @State private var showExitAlert = false
    @State private var cardAppeared = false
    @State private var shuffleRotation: Double = 0
    @State private var shimmerOffset: CGFloat = -200

    var body: some View {
        ZStack {
            BetBuddyBackgroundView(intensity: 0.6)

            // Decorative card spread in background
            decorativeCards

            VStack(spacing: 0) {
                topBar

                Spacer()

                VStack(spacing: 28) {
                    // Category Chip
                    categoryBadge

                    // The Challenge Card (Playing Card Style)
                    challengeCard
                        .scaleEffect(cardAppeared ? 1.0 : 0.8)
                        .opacity(cardAppeared ? 1.0 : 0)
                        .rotation3DEffect(
                            .degrees(cardAppeared ? 0 : 180),
                            axis: (x: 0, y: 1, z: 0)
                        )

                    // Shuffle / Change Button
                    shuffleButton
                }
                .padding(.horizontal, Theme.padding)

                Spacer()

                // Aktive Spieler anzeigen (nur wenn Namen vorhanden)
                let teamsWithNames = appModel.activeGroups.filter { $0.hasPlayerNames }
                if !teamsWithNames.isEmpty {
                    activePlayersBar(teams: teamsWithNames)
                        .padding(.horizontal, Theme.padding)
                        .padding(.bottom, 12)
                }

                // Deal Button (Start)
                dealButton
                    .padding(.horizontal, Theme.padding)
                    .padding(.bottom, 28)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .alert("Spiel beenden?", isPresented: $showExitAlert) {
            Button("Abbrechen", role: .cancel) { }
            Button("Beenden", role: .destructive) {
                onClose()
                dismiss()
            }
        } message: {
            Text("Möchtest du das Spiel wirklich beenden?")
        }
        .onAppear {
            appModel.refreshChallenge()
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2)) {
                cardAppeared = true
            }
            // Shimmer sweep nach Card-Eingang
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                withAnimation(.easeInOut(duration: 0.7)) {
                    shimmerOffset = 300
                }
            }
        }
    }

    // MARK: - Top Bar
    private var topBar: some View {
        HStack {
            Color.clear.frame(width: 44, height: 44)

            // Casino Dealer Title
            HStack(spacing: 8) {
                Text("♠")
                    .font(.system(size: 14))
                    .foregroundStyle(BetBuddyTheme.accentGold.opacity(0.6))

                Text("THE DEAL")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(BetBuddyTheme.textGold)
                    .tracking(3)

                Text("♠")
                    .font(.system(size: 14))
                    .foregroundStyle(BetBuddyTheme.accentGold.opacity(0.6))
            }
            .frame(maxWidth: .infinity)

            Button {
                HapticsService.impact(.medium)
                showExitAlert = true
            } label: {
                Image(systemName: "xmark")
                    .font(.headline.bold())
                    .foregroundStyle(BetBuddyTheme.textChampagne)
                    .frame(width: 44, height: 44)
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
        .padding(.horizontal, Theme.padding)
        .padding(.top, 12)
    }

    // MARK: - Decorative Background Cards
    private var decorativeCards: some View {
        ZStack {
            // Left card — Spades
            decorativeCard(suit: "♠", number: "A", rotation: -15, offsetX: -100, offsetY: -20)
            // Right card — Hearts
            decorativeCard(suit: "♥", number: "K", rotation: 15, offsetX: 100, offsetY: -20)
        }
    }

    private func decorativeCard(suit: String, number: String, rotation: Double, offsetX: CGFloat, offsetY: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.12, green: 0.12, blue: 0.10),
                            Color(red: 0.07, green: 0.07, blue: 0.06)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 80, height: 110)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(BetBuddyTheme.accentGold.opacity(0.2), lineWidth: 1)
                )

            // Corner marks
            VStack {
                HStack {
                    VStack(spacing: 1) {
                        Text(number)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(BetBuddyTheme.accentGold.opacity(0.8))
                        Text(suit)
                            .font(.system(size: 9))
                            .foregroundStyle(suit == "♥" ? BetBuddyTheme.accentRuby.opacity(0.8) : BetBuddyTheme.accentGold.opacity(0.6))
                    }
                    Spacer()
                }
                Spacer()
                HStack {
                    Spacer()
                    VStack(spacing: 1) {
                        Text(suit)
                            .font(.system(size: 9))
                            .foregroundStyle(suit == "♥" ? BetBuddyTheme.accentRuby.opacity(0.8) : BetBuddyTheme.accentGold.opacity(0.6))
                        Text(number)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(BetBuddyTheme.accentGold.opacity(0.8))
                    }
                    .rotationEffect(.degrees(180))
                }
            }
            .padding(8)
            .frame(width: 80, height: 110)

            // Center suit
            Text(suit)
                .font(.system(size: 26))
                .foregroundStyle(suit == "♥" ? BetBuddyTheme.accentRuby.opacity(0.5) : BetBuddyTheme.accentGold.opacity(0.4))
        }
        .rotationEffect(.degrees(rotation))
        .offset(x: offsetX, y: offsetY)
        .opacity(0.6)
        .shadow(color: BetBuddyTheme.accentGold.opacity(0.1), radius: 8, y: 4)
    }

    // MARK: - Category Badge
    private var categoryBadge: some View {
        VStack(spacing: 6) {
            Text("KATEGORIE")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(BetBuddyTheme.textSilver)
                .tracking(2)

            HStack(spacing: 8) {
                Image(systemName: appModel.currentChallenge.category.iconName)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(appModel.currentChallenge.category.accent)

                Text(LocalizedStringKey(appModel.currentChallenge.category.title))
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(BetBuddyTheme.textChampagne)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(Color.black.opacity(0.5))
                    .overlay(
                        Capsule()
                            .stroke(appModel.currentChallenge.category.accent.opacity(0.4), lineWidth: 1)
                    )
            )
        }
    }

    // MARK: - Challenge Card (Playing Card Style)
    private var challengeCard: some View {
        ZStack {
            // Card Base
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.12, green: 0.12, blue: 0.10),
                            Color(red: 0.06, green: 0.06, blue: 0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // Felt texture
            FeltTextureOverlay()
                .opacity(0.02)
                .clipShape(RoundedRectangle(cornerRadius: 20))

            // Card Content
            VStack(spacing: 16) {
                // Top-Left Corner
                HStack {
                    VStack(spacing: 2) {
                        Text("♦")
                            .font(.system(size: 18))
                            .foregroundStyle(BetBuddyTheme.accentRuby)
                        Text("?")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(BetBuddyTheme.accentGold)
                    }
                    Spacer()
                }
                .padding(.leading, 16)
                .padding(.top, 12)

                Spacer(minLength: 12)

                // Center Icon
                ZStack {
                    Circle()
                        .fill(BetBuddyTheme.accentGold.opacity(0.1))
                        .frame(width: 70, height: 70)

                    Circle()
                        .stroke(BetBuddyTheme.accentGold.opacity(0.3), lineWidth: 2)
                        .frame(width: 70, height: 70)

                    Image(systemName: appModel.currentChallenge.category.iconName)
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(BetBuddyTheme.accentGold)
                }

                // Challenge Text
                Text(appModel.currentChallenge.text)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(BetBuddyTheme.textChampagne)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 20)

                Spacer(minLength: 12)

                // Bottom-Right Corner (mirrored)
                HStack {
                    Spacer()
                    VStack(spacing: 2) {
                        Text("?")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(BetBuddyTheme.accentGold)
                        Text("♦")
                            .font(.system(size: 18))
                            .foregroundStyle(BetBuddyTheme.accentRuby)
                    }
                    .rotationEffect(.degrees(180))
                }
                .padding(.trailing, 16)
                .padding(.bottom, 12)
            }
        }
        .frame(minHeight: 300)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        colors: [
                            BetBuddyTheme.accentGoldLight.opacity(0.5),
                            BetBuddyTheme.accentGold.opacity(0.2),
                            BetBuddyTheme.accentGoldLight.opacity(0.3)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2.5
                )
        )
        // Shimmer sweep
        .overlay(
            LinearGradient(
                colors: [
                    Color.clear,
                    Color.white.opacity(0.12),
                    Color.clear
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: 80)
            .offset(x: shimmerOffset)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .allowsHitTesting(false)
        )
        .clipped()
        .shadow(color: BetBuddyTheme.accentGold.opacity(0.15), radius: 20, y: 10)
        .shadow(color: Color.black.opacity(0.4), radius: 15, y: 8)
    }

    // MARK: - Shuffle Button
    private var shuffleButton: some View {
        Button {
            // Shuffle animation
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                cardAppeared = false
                shuffleRotation += 360
            }

            HapticsService.impact(.medium)

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                appModel.refreshChallenge()
                shimmerOffset = -200
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    cardAppeared = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                    withAnimation(.easeInOut(duration: 0.7)) {
                        shimmerOffset = 300
                    }
                }
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "shuffle")
                    .font(.system(size: 16, weight: .bold))
                    .rotationEffect(.degrees(shuffleRotation))

                Text("Neue Karte ziehen")
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundStyle(BetBuddyTheme.textChampagne)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.08))
                    .overlay(
                        Capsule()
                            .stroke(BetBuddyTheme.accentGold.opacity(0.25), lineWidth: 1)
                    )
            )
        }
    }

    // MARK: - Active Players Bar
    private func activePlayersBar(teams: [GroupInfo]) -> some View {
        VStack(spacing: 8) {
            Text("DIESE RUNDE")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(BetBuddyTheme.textSilver)
                .tracking(2)

            HStack(spacing: 10) {
                ForEach(teams) { group in
                    HStack(spacing: 6) {
                        Circle()
                            .fill(group.color.primary)
                            .frame(width: 8, height: 8)

                        VStack(alignment: .leading, spacing: 1) {
                            Text(group.activePlayerName)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(group.color.accent)
                                .lineLimit(1)
                            Text("macht es")
                                .font(.system(size: 10))
                                .foregroundStyle(BetBuddyTheme.textSilver)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(group.color.primary.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(group.color.primary.opacity(0.2), lineWidth: 1)
                            )
                    )

                    if group.id != teams.last?.id {
                        Text("vs")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(BetBuddyTheme.textSilver.opacity(0.5))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.black.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(BetBuddyTheme.accentGold.opacity(0.1), lineWidth: 1)
                )
        )
    }

    // MARK: - Deal Button
    private var dealButton: some View {
        Button {
            HapticsService.success()
            onStart()
        } label: {
            HStack(spacing: 12) {
                Text("DEAL")
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
}
