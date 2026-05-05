import SwiftUI

// MARK: - Playing Phase (Redesigned with Fixed Layout)
struct PlayingPhaseView: View {
    @ObservedObject var gameManager: GameManager

    // Computed properties for cleaner code
    private var forcedSkipActive: Bool {
        gameManager.isForcedSkipActiveForCurrentTeam()
    }

    private var notices: [GameManager.PerkNotice] {
        gameManager.perkNoticesForCurrentTeam()
    }

    private var attackNotices: [GameManager.PerkAttackNotice] {
        gameManager.attackNoticesForCurrentTeam()
    }

    private var streak: Int {
        gameManager.currentHitStreakCount()
    }

    private var skipFrozen: Bool {
        gameManager.isSkipButtonFrozenForCurrentTeam()
    }

    private var canSkip: Bool {
        gameManager.gameState.currentRound.canSkip
    }

    private var isHardMode: Bool {
        gameManager.gameState.settings.difficulty == .hard
    }

    var body: some View {
        ZStack {
            // Background
            TimesUpStyle.backgroundGradient
                .ignoresSafeArea()

            // Fixiertes Layout-Skelett: Timer oben, Buttons immer an fixer Position unten
            VStack(spacing: 0) {
                topSection
                Spacer()
                actionButtons
                    .padding(.bottom, TimesUpStyle.bottomPadding)
            }
            .padding(.horizontal, TimesUpStyle.horizontalPadding)

            // Floating Overlay: Streak + Perk-Notices (verschieben die Buttons NICHT)
            VStack(spacing: 16) {
                Spacer()
                if streak > 1 {
                    StreakFlameView(streak: streak)
                        .transition(.scale.combined(with: .opacity))
                        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: streak)
                }
                if !notices.isEmpty || !attackNotices.isEmpty {
                    ScrollView(.vertical, showsIndicators: false) {
                        PerkNoticeStack(notices: notices, attackNotices: attackNotices)
                    }
                    .frame(maxHeight: 140)
                    .padding(.horizontal, 10)
                }
                // Platzhalter: Notices bleiben über dem Button-Bereich
                Color.clear
                    .frame(height: TimesUpStyle.largeButtonSize + TimesUpStyle.bottomPadding + 16)
            }
            .padding(.horizontal, TimesUpStyle.horizontalPadding)
            .allowsHitTesting(false)

            // Perk-Toast: Oben-zentriert, respektiert Safe Area (kein negativer Offset nötig)
            if let toast = gameManager.perkToast {
                VStack {
                    PerkToastView(toast: toast)
                        .padding(.top, 16)
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.spring(response: 0.35, dampingFraction: 0.75), value: gameManager.perkToast?.id)
                .allowsHitTesting(false)
            }

            // Forced-Skip-Warnung als Overlay – verschiebt Buttons NICHT
            if forcedSkipActive {
                VStack {
                    Spacer()
                    Text(LocalizedStringKey("Zwangs-Skip aktiv – zuerst Skip ausführen."))
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(.yellow)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.yellow.opacity(0.15))
                        .clipShape(Capsule())
                        .padding(.bottom, TimesUpStyle.largeButtonSize + TimesUpStyle.bottomPadding + 20)
                }
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                .animation(.spring(response: 0.3), value: forcedSkipActive)
            }
        }
    }

    // MARK: - Top Section (Timer + Word Banner)

    private var topSection: some View {
        VStack(spacing: 20) {
            Spacer()
                .frame(height: 24)

            // Timer
            TimerView(gameManager: gameManager)

            // Word Banner
            if let term = gameManager.gameState.currentTerm {
                WordBannerView(gameManager: gameManager, term: term)
                    .padding(.horizontal, 10)
            }
        }
    }

    // MARK: - Action Buttons

    @ViewBuilder
    private var actionButtons: some View {
        if canSkip {
            // Layout mit Skip-Button
            VStack(spacing: 16) {
                // Hauptzeile: Skip + Correct
                HStack(spacing: 20) {
                    // Skip Button
                    PlayingActionButton(
                        icon: "arrow.right",
                        size: TimesUpStyle.standardButtonSize,
                        gradient: LinearGradient(colors: [.blue, .blue.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing),
                        shadowColor: .blue,
                        isLocked: skipFrozen
                    ) {
                        TimesUpHaptics.impact(.medium)
                        gameManager.skipTerm()
                    }
                    .accessibilityLabel("Überspringen")
                    .disabled(skipFrozen)

                    // Correct Button (nur wenn kein Forced Skip)
                    if !forcedSkipActive {
                        PlayingActionButton(
                            icon: "checkmark",
                            size: TimesUpStyle.largeButtonSize,
                            gradient: TimesUpStyle.successGradient,
                            shadowColor: .green,
                            iconSize: 40
                        ) {
                            TimesUpHaptics.impact(.medium)
                            gameManager.correctGuess()
                        }
                        .accessibilityLabel("Richtig")
                    }
                }

                // Wrong Button (nur im Hard Mode)
                if !forcedSkipActive && isHardMode {
                    PlayingActionButton(
                        icon: "xmark",
                        size: TimesUpStyle.standardButtonSize,
                        gradient: TimesUpStyle.errorGradient,
                        shadowColor: .red
                    ) {
                        TimesUpHaptics.impact(.medium)
                        gameManager.wrongGuess()
                    }
                    .accessibilityLabel("Falsch")
                    .disabled(skipFrozen)
                }
            }
        } else {
            // Nur Correct-Button (ohne Skip)
            if !forcedSkipActive {
                PlayingActionButton(
                    icon: "checkmark",
                    size: TimesUpStyle.largeButtonSize,
                    gradient: TimesUpStyle.successGradient,
                    shadowColor: .green,
                    iconSize: 40
                ) {
                    TimesUpHaptics.impact(.medium)
                    gameManager.correctGuess()
                }
                .accessibilityLabel("Richtig")
            }
        }
    }
}

// MARK: - Playing Action Button Component

private struct PlayingActionButton: View {
    let icon: String
    let size: CGFloat
    let gradient: LinearGradient
    let shadowColor: Color
    var iconSize: CGFloat = 25
    var isLocked: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Circle()
                .fill(gradient)
                .frame(width: size, height: size)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: iconSize, weight: .bold))
                        .foregroundStyle(.white)
                )
                .shadow(
                    color: shadowColor.opacity(0.4),
                    radius: size > 100 ? TimesUpStyle.largeShadowRadius : TimesUpStyle.shadowRadius,
                    x: 0,
                    y: size > 100 ? 8 : 5
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
    @ObservedObject var gameManager: GameManager
    let term: Term

    var body: some View {
        ZStack {
            // Background Card
            RoundedRectangle(cornerRadius: TimesUpStyle.containerCornerRadius)
                .fill(Color(.systemBackground).opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: TimesUpStyle.containerCornerRadius)
                        .stroke(TimesUpStyle.primaryGradient, lineWidth: 2)
                )
                .shadow(
                    color: TimesUpStyle.shadowColor(.blue, opacity: 0.3),
                    radius: TimesUpStyle.largeShadowRadius,
                    x: 0,
                    y: 5
                )

            // Content
            HStack(spacing: 16) {
                PerkWordText(
                    gameManager: gameManager,
                    term: term,
                    font: .system(size: 28, weight: .bold),
                    weight: .bold,
                    alignment: .leading,
                    lineLimit: 2,
                    color: .primary
                )

                Spacer()

                // Remaining Terms Badge
                Circle()
                    .fill(TimesUpStyle.termsBadgeGradient)
                    .frame(width: 52, height: 52)
                    .overlay(
                        Text("\(gameManager.gameState.remainingTermsCount)")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                    )
                    .shadow(
                        color: TimesUpStyle.shadowColor(.orange, opacity: 0.6),
                        radius: TimesUpStyle.shadowRadius,
                        x: 0,
                        y: 0
                    )
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 18)
        }
        .frame(height: 90)
    }
}

struct PerkNoticeStack: View {
    let notices: [GameManager.PerkNotice]
    let attackNotices: [GameManager.PerkAttackNotice]
    
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
    let notices: [GameManager.PerkNotice]
    
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
    let notices: [GameManager.PerkAttackNotice]

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

