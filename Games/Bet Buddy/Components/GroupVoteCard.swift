import SwiftUI
import Lottie

struct GroupVoteCard: View {
    let group: GroupInfo
    var onIncrement: () -> Void
    var onDecrement: () -> Void
    var locked: Bool
    var isLeader: Bool
    var showLeader: Bool

    @State private var animate = false
    @State private var chipPulse = false
    @State private var showCoinAnimation = false
    @State private var coinAnimationID = UUID()

    var body: some View {
        ZStack {
            // Poker-Filz-Hintergrund
            pokerFeltBackground

            // Crown für Leader
            if showLeader && isLeader {
                leaderCrown
            }

            // Content
            VStack(spacing: 0) {
                // Team-Name Header
                teamHeader
                    .padding(.top, 14)

                Spacer()

                // Betting Controls
                bettingControls

                Spacer()

                // Chip-Stack Indicator
                chipIndicator
                    .padding(.bottom, 14)
            }

            // Coin Fall Animation Overlay
            if showCoinAnimation {
                CoinFallAnimationView()
                    .id(coinAnimationID)
                    .allowsHitTesting(false)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 170)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(cardBorder)
        .shadow(
            color: isLeader && showLeader
                ? BetBuddyTheme.accentGold.opacity(0.3)
                : Color.black.opacity(0.3),
            radius: isLeader ? 12 : 8,
            y: 4
        )
        .scaleEffect(animate ? 1.02 : 1.0)
        .animation(.easeOut(duration: 0.15), value: animate)
    }

    // MARK: - Poker Felt Background
    private var pokerFeltBackground: some View {
        ZStack {
            // Basis-Gradient mit Team-Farbe
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.06, green: 0.08, blue: 0.06),
                            Color(red: 0.04, green: 0.05, blue: 0.04)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // Team-Farb-Overlay
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    group.color.primary.opacity(isLeader && showLeader ? 0.2 : 0.1)
                )

            // Filz-Textur
            FeltTextureOverlay()
                .opacity(0.03)
                .clipShape(RoundedRectangle(cornerRadius: 16))

            // Spotlight bei Leader
            if isLeader && showLeader {
                RadialGradient(
                    colors: [
                        BetBuddyTheme.accentGold.opacity(0.15),
                        Color.clear
                    ],
                    center: .top,
                    startRadius: 0,
                    endRadius: 120
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
    }

    // MARK: - Card Border
    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: 16)
            .stroke(
                LinearGradient(
                    colors: isLeader && showLeader
                        ? [BetBuddyTheme.accentGold.opacity(0.6), BetBuddyTheme.accentGold.opacity(0.3)]
                        : [group.color.primary.opacity(0.4), group.color.primary.opacity(0.15)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: isLeader && showLeader ? 2.5 : 1.5
            )
    }

    // MARK: - Leader Crown
    private var leaderCrown: some View {
        VStack {
            HStack {
                Spacer()
                ZStack {
                    // Glow
                    Image(systemName: "crown.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(BetBuddyTheme.accentGold)
                        .blur(radius: 6)

                    Image(systemName: "crown.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(BetBuddyTheme.accentGold)
                }
                .padding(8)
            }
            Spacer()
        }
    }

    // MARK: - Team Header
    private var teamHeader: some View {
        HStack(spacing: 8) {
            // Team-Chip
            Circle()
                .fill(group.color.primary)
                .frame(width: 14, height: 14)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )

            Text(LocalizedStringKey(group.displayName))
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(BetBuddyTheme.textChampagne)
                .lineLimit(1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.4))
                .overlay(
                    Capsule()
                        .stroke(group.color.primary.opacity(0.3), lineWidth: 1)
                )
        )
    }

    // MARK: - Betting Controls
    private var bettingControls: some View {
        HStack(spacing: 0) {
            // FOLD / Minus Button
            Button {
                guard !locked else { return }
                onDecrement()
                HapticsService.impact(.light)
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.black.opacity(0.5))
                        .frame(width: 56, height: 56)
                    Circle()
                        .stroke(
                            locked
                                ? BetBuddyTheme.textSilver.opacity(0.2)
                                : BetBuddyTheme.accentRuby.opacity(0.5),
                            lineWidth: 2
                        )
                        .frame(width: 56, height: 56)
                    Image(systemName: "minus")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(
                            locked
                                ? BetBuddyTheme.textSilver.opacity(0.3)
                                : BetBuddyTheme.textChampagne
                        )
                }
            }
            .buttonStyle(.plain)
            .disabled(locked)

            Spacer()

            // RAISE / Plus Button
            Button {
                guard !locked else { return }
                onIncrement()
                HapticsService.impact(.medium)

                // Trigger coin animation
                coinAnimationID = UUID()
                showCoinAnimation = true

                // Reset animation after it plays
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                    showCoinAnimation = false
                }

                withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) {
                    animate.toggle()
                }
                // Reset animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    animate = false
                }
            } label: {
                ZStack {
                    // Outer glow
                    Circle()
                        .fill(
                            locked
                                ? Color.clear
                                : BetBuddyTheme.accentEmerald.opacity(0.2)
                        )
                        .frame(width: 64, height: 64)

                    Circle()
                        .fill(
                            LinearGradient(
                                colors: locked
                                    ? [Color.gray.opacity(0.3), Color.gray.opacity(0.2)]
                                    : [BetBuddyTheme.accentEmerald, BetBuddyTheme.accentEmerald.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)

                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.3), Color.clear],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1
                        )
                        .frame(width: 56, height: 56)

                    Image(systemName: "plus")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(locked ? BetBuddyTheme.textSilver : .white)
                }
                .shadow(
                    color: locked ? .clear : BetBuddyTheme.accentEmerald.opacity(0.4),
                    radius: 8
                )
            }
            .buttonStyle(.plain)
            .disabled(locked)
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Chip Indicator
    private var chipIndicator: some View {
        HStack(spacing: 4) {
            Text("RAISE")
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundStyle(BetBuddyTheme.textSilver.opacity(0.6))
                .tracking(1)

            Image(systemName: "arrow.up.right")
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(BetBuddyTheme.accentEmerald.opacity(0.6))
        }
    }
}

// MARK: - Coin Fall Animation
struct CoinFallAnimationView: View {
    var body: some View {
        LottieView(
            filename: "3D coin flip",
            loopMode: .playOnce,
            isPlaying: true,
            animationSpeed: 1.2
        )
            .frame(width: 120, height: 120)
    }
}
