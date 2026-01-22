import SwiftUI

struct ChallengeStartView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appModel: AppViewModel

    var onStart: () -> Void
    var onClose: () -> Void

    @State private var showExitAlert = false
    @State private var cardAppeared = false
    @State private var shuffleRotation: Double = 0

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
        .padding(.horizontal, Theme.padding)
        .padding(.top, 12)
    }

    // MARK: - Decorative Background Cards
    private var decorativeCards: some View {
        ZStack {
            // Left card
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.3))
                .frame(width: 80, height: 110)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(BetBuddyTheme.accentGold.opacity(0.1), lineWidth: 1)
                )
                .rotationEffect(.degrees(-15))
                .offset(x: -100, y: -20)
                .opacity(0.5)

            // Right card
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.3))
                .frame(width: 80, height: 110)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(BetBuddyTheme.accentGold.opacity(0.1), lineWidth: 1)
                )
                .rotationEffect(.degrees(15))
                .offset(x: 100, y: -20)
                .opacity(0.5)
        }
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

                Spacer()

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
                    .padding(.horizontal, 20)
                    .minimumScaleFactor(0.8)

                Spacer()

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
        .frame(height: 320)
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

            HapticsService.impact(.light)

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                appModel.refreshChallenge()
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    cardAppeared = true
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
