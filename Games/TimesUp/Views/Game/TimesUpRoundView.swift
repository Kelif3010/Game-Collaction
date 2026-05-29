import SwiftUI

// MARK: - Playing Phase (Redesigned with Fixed Layout)
struct PlayingPhaseView: View {
    @ObservedObject var viewModel: TimesUpGameViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingEndGame = false

    // Computed properties for cleaner code
    private var forcedSkipActive: Bool {
        viewModel.isForcedSkipActiveForCurrentTeam()
    }

    private var notices: [TimesUpGameViewModel.PerkNotice] {
        viewModel.perkNoticesForCurrentTeam()
    }

    private var attackNotices: [TimesUpGameViewModel.PerkAttackNotice] {
        viewModel.attackNoticesForCurrentTeam()
    }

    private var streak: Int {
        viewModel.currentHitStreakCount()
    }

    private var skipFrozen: Bool {
        viewModel.isSkipButtonFrozenForCurrentTeam()
    }

    private var canSkip: Bool {
        viewModel.gameState.currentRound.canSkip
    }

    private var isHardMode: Bool {
        viewModel.gameState.settings.difficulty == .hard
    }

    var body: some View {
        ZStack {
            NeonGameBackground()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                GameTopHUD(viewModel: viewModel)
                    .padding(.top, 12)

                Spacer(minLength: 8)

                TimerView(viewModel: viewModel)

                if let term = viewModel.gameState.currentTerm {
                    WordBannerView(viewModel: viewModel, term: term)
                        .padding(.top, 12)
                }

                GameEventChips(
                    streak: streak,
                    notices: notices,
                    attackNotices: attackNotices,
                    forcedSkipActive: forcedSkipActive
                )
                .padding(.top, 12)

                Spacer(minLength: 8)

                GameActionDock(
                    canSkip: canSkip,
                    isHardMode: isHardMode,
                    forcedSkipActive: forcedSkipActive,
                    skipFrozen: skipFrozen,
                    onSkip: {
                        TimesUpHaptics.impact(.medium)
                        viewModel.skipTerm()
                    },
                    onCorrect: {
                        TimesUpHaptics.impact(.medium)
                        viewModel.correctGuess()
                    },
                    onWrong: {
                        TimesUpHaptics.impact(.medium)
                        viewModel.wrongGuess()
                    }
                )
                .padding(.bottom, 20)
            }
            .padding(.horizontal, 20)

            if let toast = viewModel.perkToast {
                VStack {
                    PerkToastView(toast: toast)
                        .padding(.top, 72)
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.spring(response: 0.35, dampingFraction: 0.75), value: viewModel.perkToast?.id)
                .allowsHitTesting(false)
            }
        }
        .alert("Spiel beenden?", isPresented: $showingEndGame) {
            Button("Abbrechen", role: .cancel) { }
            Button("Beenden", role: .destructive) {
                viewModel.cleanup()
                dismiss()
            }
        } message: {
            Text("Möchtest du das aktuelle Spiel wirklich beenden?")
        }
    }
}

// MARK: - Game Overlay Components

private struct NeonGameBackground: View {
    var body: some View {
        ZStack {
            Color(red: 0.015, green: 0.015, blue: 0.018)
            RadialGradient(colors: [.cyan.opacity(0.16), .clear], center: .topLeading, startRadius: 8, endRadius: 360)
            RadialGradient(colors: [.purple.opacity(0.12), .clear], center: .bottomTrailing, startRadius: 20, endRadius: 420)
        }
    }
}

private struct GameTopHUD: View {
    @ObservedObject var viewModel: TimesUpGameViewModel

    private var activeTeam: Team? {
        viewModel.gameState.currentTeam
    }

    var body: some View {
        HStack(spacing: 8) {
            HUDStatBadge(
                icon: "flag.checkered",
                title: "ROUND \(viewModel.gameState.currentRound.rawValue + 1)",
                value: activeTeam?.name ?? "-"
            )

            Spacer(minLength: 8)

            HUDMiniMetric(
                icon: "star.fill",
                value: "\(activeTeam?.score ?? 0)",
                tint: .yellow
            )

            HUDMiniMetric(
                icon: "rectangle.stack.fill",
                value: "\(viewModel.gameState.remainingTermsCount)",
                tint: Color.timesUpNeonOrange
            )
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(height: 58)
        .background(NeonGlassCapsule())
    }
}

private struct HUDStatBadge: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Color.timesUpNeonSecondary)
                .frame(width: 38, height: 38)
                .background(Circle().fill(Color.timesUpNeonSecondary.opacity(0.18)))
                .overlay(Circle().stroke(Color.timesUpNeonSecondary.opacity(0.30), lineWidth: 1.5))
                .shadow(color: Color.timesUpNeonCyan.opacity(0.24), radius: 12, x: 0, y: 0)

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color(red: 0.835, green: 0.753, blue: 0.843))
                    .lineLimit(1)
                    .tracking(1.2)

                Text(value)
                    .font(.system(size: 17, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct HUDMiniMetric: View {
    let icon: String
    let value: String
    let tint: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold))
            Text(value)
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .monospacedDigit()
        }
        .foregroundStyle(tint)
        .frame(minWidth: 58, minHeight: 36)
        .background(
            Capsule(style: .continuous)
                .fill(Color.white.opacity(0.045))
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }
}

private struct GameActionDock: View {
    let canSkip: Bool
    let isHardMode: Bool
    let forcedSkipActive: Bool
    let skipFrozen: Bool
    let onSkip: () -> Void
    let onCorrect: () -> Void
    let onWrong: () -> Void

    var body: some View {
        HStack(spacing: 18) {
            if canSkip {
                PlayingActionButton(
                    icon: skipFrozen ? "lock.fill" : "arrow.right",
                    size: 62,
                    fillColor: Color.timesUpNeonBlue.opacity(0.10),
                    iconColor: Color.timesUpNeonBlue,
                    borderColor: Color.timesUpNeonBlue.opacity(0.42),
                    shadowColor: Color.timesUpNeonBlue,
                    isLocked: skipFrozen,
                    action: onSkip
                )
                .accessibilityLabel("Überspringen")
                .disabled(skipFrozen)
            }

            if !forcedSkipActive {
                PlayingActionButton(
                    icon: "checkmark",
                    size: 92,
                    fillColor: Color.timesUpNeonGreen,
                    iconColor: .black,
                    borderColor: Color.white.opacity(0.20),
                    shadowColor: Color.timesUpNeonGreen,
                    iconSize: 44,
                    action: onCorrect
                )
                .accessibilityLabel("Richtig")
            }

            if !forcedSkipActive && isHardMode {
                PlayingActionButton(
                    icon: "xmark",
                    size: 62,
                    fillColor: Color.timesUpNeonRed.opacity(0.10),
                    iconColor: Color.timesUpNeonRed,
                    borderColor: Color.timesUpNeonRed.opacity(0.42),
                    shadowColor: Color.timesUpNeonRed,
                    iconSize: 28,
                    action: onWrong
                )
                .accessibilityLabel("Falsch")
            }
        }
        .frame(maxWidth: .infinity)
    }
}

private struct GameEventChips: View {
    let streak: Int
    let notices: [TimesUpGameViewModel.PerkNotice]
    let attackNotices: [TimesUpGameViewModel.PerkAttackNotice]
    let forcedSkipActive: Bool

    private var chips: [OverlayChip] {
        var result: [OverlayChip] = []
        if streak > 1 {
            result.append(OverlayChip(icon: "flame.fill", text: "Streak \(streak)x", color: Color.timesUpNeonOrange))
        }
        if forcedSkipActive {
            result.append(OverlayChip(icon: "exclamationmark.triangle.fill", text: "Forced Skip", color: Color.timesUpNeonOrange))
        }
        result.append(contentsOf: notices.prefix(3).map {
            OverlayChip(icon: $0.isNegative ? "bolt.shield.fill" : "bolt.fill", text: $0.text, color: $0.isNegative ? Color.timesUpNeonRed : Color.timesUpNeonGreen)
        })
        result.append(contentsOf: attackNotices.prefix(2).map {
            OverlayChip(icon: "target", text: "\($0.targetName): \($0.label)", color: Color.timesUpNeonBlue)
        })
        return result
    }

    var body: some View {
        if chips.isEmpty {
            Color.clear.frame(height: 30)
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(chips) { chip in
                        EventChip(chip: chip)
                    }
                }
                .padding(.horizontal, 2)
            }
            .frame(height: 34)
            .transition(.opacity.combined(with: .scale(scale: 0.96)))
            .animation(.spring(response: 0.35, dampingFraction: 0.78), value: chips.count)
        }
    }
}

private struct OverlayChip: Identifiable {
    var id: String { "\(icon)-\(text)" }
    let icon: String
    let text: String
    let color: Color
}

private struct EventChip: View {
    let chip: OverlayChip

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: chip.icon)
                .font(.caption.weight(.heavy))
            Text(chip.text)
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .lineLimit(1)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(
            Capsule(style: .continuous)
                .fill(chip.color.opacity(0.08))
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(chip.color.opacity(0.38), lineWidth: 1.2)
        )
        .shadow(color: chip.color.opacity(0.18), radius: 8, x: 0, y: 0)
    }
}

// MARK: - Playing Action Button Component

private struct PlayingActionButton: View {
    let icon: String
    let size: CGFloat
    let fillColor: Color
    let iconColor: Color
    let borderColor: Color
    let shadowColor: Color
    var iconSize: CGFloat = 25
    var isLocked: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Circle()
                .fill(fillColor)
                .frame(width: size, height: size)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: iconSize, weight: .bold))
                        .foregroundStyle(iconColor)
                )
                .overlay(
                    Circle()
                        .stroke(borderColor, lineWidth: size > 100 ? 6 : 1.5)
                )
                .shadow(
                    color: shadowColor.opacity(size > 100 ? 0.52 : 0.22),
                    radius: size > 100 ? 42 : 22,
                    x: 0,
                    y: 0
                )
                .overlay(alignment: .bottomTrailing) {
                    if isLocked {
                        lockBadge
                    }
                }
        }
    }

    private var lockBadge: some View {
        Image(systemName: "lock.fill")
            .font(.caption)
            .foregroundStyle(.white)
            .padding(6)
            .background(Color.black.opacity(0.6))
            .clipShape(Circle())
            .offset(x: 8, y: 8)
    }
}

private struct WordBannerView: View {
    @ObservedObject var viewModel: TimesUpGameViewModel
    let term: Term

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: TimesUpStyle.containerCornerRadius)
                .fill(Color(red: 0.075, green: 0.075, blue: 0.082).opacity(0.84))
                .overlay(
                    RoundedRectangle(cornerRadius: TimesUpStyle.containerCornerRadius)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
                .shadow(
                    color: Color.black.opacity(0.40),
                    radius: 34,
                    x: 0,
                    y: 20
                )

            HStack(spacing: 16) {
                PerkWordText(
                    viewModel: viewModel,
                    term: term,
                    font: .system(size: 27, weight: .heavy, design: .rounded),
                    weight: .heavy,
                    alignment: .leading,
                    lineLimit: 2,
                    color: .white
                )
                .minimumScaleFactor(0.58)

                Spacer()

                VStack(spacing: 3) {
                    Text("\(viewModel.gameState.remainingTermsCount)")
                        .font(.system(size: 19, weight: .heavy, design: .rounded))
                        .monospacedDigit()
                    Image(systemName: "rectangle.on.rectangle")
                        .font(.system(size: 22, weight: .bold))
                }
                .foregroundStyle(Color.timesUpNeonOrange)
                .frame(width: 44, height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .fill(Color.timesUpNeonOrange.opacity(0.14))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .stroke(Color.timesUpNeonOrange.opacity(0.40), lineWidth: 1.2)
                )
                .shadow(color: Color.timesUpNeonOrange.opacity(0.24), radius: 10, x: 0, y: 0)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
        }
        .frame(minHeight: 68)
    }
}

private struct NeonGlassCapsule: View {
    var body: some View {
        Capsule(style: .continuous)
            .fill(Color(red: 0.125, green: 0.122, blue: 0.129).opacity(0.40))
            .overlay(
                Capsule(style: .continuous)
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.38), radius: 32, x: 0, y: 8)
    }
}

struct PerkNoticeStack: View {
    let notices: [TimesUpGameViewModel.PerkNotice]
    let attackNotices: [TimesUpGameViewModel.PerkAttackNotice]
    
    var body: some View {
        let positiveNotices = notices.filter { !$0.isNegative }
        let negativeNotices = notices.filter { $0.isNegative }
        
        return VStack(alignment: .leading, spacing: 14) {
            if !positiveNotices.isEmpty {
                PerkNoticeGroup(
                    title: "Boosts",
                    color: .green,
                    notices: positiveNotices
                )
            }
            
            if !negativeNotices.isEmpty {
                PerkNoticeGroup(
                    title: "Sabotage",
                    color: .red,
                    notices: negativeNotices
                )
            }

            if !attackNotices.isEmpty {
                PerkAttackNoticeGroup(
                    title: "Angriff",
                    color: .blue,
                    notices: attackNotices
                )
            }
        }
    }
}

private struct PerkNoticeGroup: View {
    let title: LocalizedStringKey
    let color: Color
    let notices: [TimesUpGameViewModel.PerkNotice]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.bold())
                .foregroundStyle(color.opacity(0.9))
                .padding(.leading, 6)
                .textCase(.uppercase)
            
            VStack(alignment: .leading, spacing: 10) {
                ForEach(notices) { notice in
                    HStack(spacing: 10) {
                        Text(notice.icon)
                            .font(.title3)
                        
                        Text(notice.text)
                            .font(.subheadline.bold())
                            .foregroundStyle(.white)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(color.opacity(0.25))
                            .overlay(
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(color.opacity(0.6), lineWidth: 1)
                            )
                    )
                    .shadow(color: color.opacity(0.3), radius: 6, x: 0, y: 3)
                }
            }
        }
    }
}

private struct PerkAttackNoticeGroup: View {
    let title: LocalizedStringKey
    let color: Color
    let notices: [TimesUpGameViewModel.PerkAttackNotice]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.bold())
                .foregroundStyle(color.opacity(0.9))
                .padding(.leading, 6)
                .textCase(.uppercase)

            VStack(alignment: .leading, spacing: 10) {
                ForEach(notices) { notice in
                    HStack(spacing: 10) {
                        Text(notice.icon)
                            .font(.title3)

                        Text("An \(notice.targetName), \(notice.label)")
                            .font(.subheadline.bold())
                            .foregroundStyle(.white)

                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(color.opacity(0.25))
                            .overlay(
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(color.opacity(0.6), lineWidth: 1)
                            )
                    )
                    .shadow(color: color.opacity(0.3), radius: 6, x: 0, y: 3)
                }
            }
        }
    }
}

private extension Color {
    static let timesUpNeonPrimary = Color(red: 0.925, green: 0.694, blue: 1.0)
    static let timesUpNeonSecondary = Color(red: 0.741, green: 0.957, blue: 1.0)
    static let timesUpNeonCyan = Color(red: 0.0, green: 0.89, blue: 0.992)
    static let timesUpNeonBlue = Color(red: 0.039, green: 0.518, blue: 1.0)
    static let timesUpNeonOrange = Color(red: 1.0, green: 0.584, blue: 0.0)
    static let timesUpNeonGreen = Color(red: 0.204, green: 0.780, blue: 0.349)
    static let timesUpNeonRed = Color(red: 1.0, green: 0.231, blue: 0.188)
}

struct StreakFlameView: View {
    let streak: Int

    @State private var isAnimating = false

    var body: some View {
        HStack(spacing: 10) {
            // Animated Flame Icon
            flameIcon

            Text("Streak \(streak)x")
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)
                .contentTransition(.numericText())
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            Capsule()
                .fill(TimesUpStyle.streakGradient.opacity(0.25))
        )
        .overlay(
            Capsule()
                .stroke(TimesUpStyle.streakGradient, lineWidth: 1.5)
        )
        .shadow(
            color: TimesUpStyle.shadowColor(.orange),
            radius: 8,
            x: 0,
            y: 4
        )
        .onAppear {
            isAnimating = true
        }
    }

    @ViewBuilder
    private var flameIcon: some View {
        if #available(iOS 18.0, *) {
            Image(systemName: "flame.fill")
                .font(.title2)
                .foregroundStyle(TimesUpStyle.streakGradient)
                .symbolEffect(.wiggle.byLayer, options: .repeating)
        } else {
            Image(systemName: "flame.fill")
                .font(.title2)
                .foregroundStyle(TimesUpStyle.streakGradient)
                .rotationEffect(.degrees(isAnimating ? 8 : -8))
                .scaleEffect(isAnimating ? 1.06 : 0.96)
                .animation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true), value: isAnimating)
        }
    }
}
