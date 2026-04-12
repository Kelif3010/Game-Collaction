import SwiftUI

struct TimesUpGameView: View {
    @ObservedObject var gameManager: GameManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingEndGame = false
    
    var body: some View {
        NavigationStack {
            VStack {
                switch gameManager.gameState.phase {
                case .setup:
                    SetupPhaseView(gameManager: gameManager)
                case .playing:
                    // Runde 4 = Zeichnen, andere Runden = normale Spielansicht
                    if gameManager.gameState.currentRound == .round4 {
                        DrawingView(gameManager: gameManager)
                    } else {
                        PlayingPhaseView(gameManager: gameManager)
                    }
                case .slotReward:
                    if let rewardTeam = gameManager.slotRewardTeam() {
                        SlotRewardFullView(gameManager: gameManager, team: rewardTeam)
                    } else {
                        SetupPhaseView(gameManager: gameManager)
                    }
                case .roundEnd:
                    RoundEndView(gameManager: gameManager)
                case .gameEnd:
                    GameEndView(gameManager: gameManager)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Beenden") {
                        showingEndGame = true
                    }
                    .foregroundStyle(.red)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    TeamBadgeBar(gameManager: gameManager)
                }
                
                ToolbarItem(placement: .principal) {
                    Text(gameManager.gameState.currentRound.shortDescription)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                }
            }
            .alert("Spiel beenden?", isPresented: $showingEndGame) {
                Button("Abbrechen", role: .cancel) { }
                Button("Beenden", role: .destructive) {
                    dismiss()
                }
            } message: {
                Text("Möchtest du das aktuelle Spiel wirklich beenden?")
            }
        }
        .overlay(alignment: .topTrailing) {
            if !gameManager.scoreBursts.isEmpty {
                ScoreBurstBar(gameManager: gameManager)
                    .padding(.top, 64)
                    .padding(.trailing, 8)
                    .clipped()
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}

// MARK: - Setup Phase
struct SetupPhaseView: View {
    @ObservedObject var gameManager: GameManager

    var body: some View {
        ZStack {
            // Background
            TimesUpStyle.backgroundGradient
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 20)

                Spacer()

                // Team Info - Neon Style
                VStack(spacing: 15) {
                    if let team = gameManager.gameState.currentTeam {
                        Text("Team: \(team.name)")
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .foregroundStyle(TimesUpStyle.primaryGradient)
                            .shadow(color: .blue, radius: 20, x: 0, y: 0)
                            .shadow(color: .white.opacity(0.5), radius: 2, x: 0, y: 1)
                    }

                    Text(LocalizedStringKey(gameManager.gameState.currentRound.title))
                        .font(.title2)
                        .foregroundStyle(.gray)
                        .fontWeight(.bold)
                }

                Spacer()

                // Round Description Banner
                VStack(spacing: 15) {
                    Text(LocalizedStringKey(gameManager.gameState.currentRound.description))
                        .font(.title2)
                        .foregroundStyle(.primary)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    Text(LocalizedStringKey(gameManager.gameState.currentRound.detailedRules))
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                }
                .padding(.horizontal, 40)
                .padding(.vertical, 70)
                .background(
                    RoundedRectangle(cornerRadius: TimesUpStyle.containerCornerRadius)
                        .fill(Color(.systemGray6).opacity(0.7))
                        .overlay(
                            RoundedRectangle(cornerRadius: TimesUpStyle.containerCornerRadius)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1.5)
                        )
                )
                .padding(.horizontal, 15)

                Spacer()

                // Start Button
                Button(action: {
                    TimesUpHaptics.impact(.medium)
                    gameManager.startRound()
                }) {
                    Circle()
                        .fill(TimesUpStyle.startButtonGradient)
                        .frame(width: TimesUpStyle.largeButtonSize, height: TimesUpStyle.largeButtonSize)
                        .overlay(
                            VStack(spacing: 5) {
                                Image(systemName: "play.fill")
                                    .font(.system(size: 30, weight: .bold))
                                    .foregroundStyle(.white)
                                Text(LocalizedStringKey("Start!"))
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white)
                            }
                        )
                        .shadow(
                            color: TimesUpStyle.shadowColor(.green),
                            radius: TimesUpStyle.largeShadowRadius,
                            x: 0,
                            y: 8
                        )
                }
                .padding(.bottom, TimesUpStyle.bottomPadding + 18)
            }
        }
    }
}

struct SlotRewardFullView: View {
    @ObservedObject var gameManager: GameManager
    let team: Team
    
    var body: some View {
        ZStack {
            // Animierter Hintergrund
            LinearGradient(
                colors: [Color.black, Color(red: 0.1, green: 0.1, blue: 0.2)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Subtile Lichteffekte im Hintergrund
            GeometryReader { geo in
                Circle()
                    .fill(Color.blue.opacity(0.15))
                    .frame(width: 400, height: 400)
                    .blur(radius: 80)
                    .offset(x: -100, y: -100)
                
                Circle()
                    .fill(Color.purple.opacity(0.15))
                    .frame(width: 400, height: 400)
                    .blur(radius: 80)
                    .offset(x: geo.size.width - 300, y: geo.size.height - 300)
            }
            
            VStack(spacing: 40) {
                VStack(spacing: 8) {
                    Text(LocalizedStringKey("Slot Bonus"))
                        .font(.system(size: 16, weight: .black))
                        .kerning(4)
                        .foregroundStyle(.blue.opacity(0.8))
                    
                    Text(team.name)
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .shadow(color: .blue, radius: 10)
                }
                .padding(.top, 40)
                
                SlotMachineCard(gameManager: gameManager, team: team)
                    .padding(.horizontal, 20)
                
                Spacer()
                
                VStack(spacing: 20) {
                    if gameManager.slotRewardCredits() > 0 {
                        Text(LocalizedStringKey("Verbrauche oder überspringe alle Spins, um fortzufahren."))
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.5))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    
                    Button(action: {
                        gameManager.finishSlotReward()
                    }) {
                        Text(LocalizedStringKey("Weiter"))
                            .font(.title3.bold())
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 60)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(gameManager.slotRewardCredits() > 0 ? Color.white.opacity(0.1) : Color.green)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(gameManager.slotRewardCredits() > 0 ? Color.white.opacity(0.1) : Color.white.opacity(0.3), lineWidth: 1)
                            )
                    }
                    .disabled(gameManager.slotRewardCredits() > 0)
                    .padding(.horizontal, 30)
                    .padding(.bottom, 40)
                }
            }
        }
    }
}

struct SlotMachineCard: View {
    @ObservedObject var gameManager: GameManager
    let team: Team
    @State private var reelSymbols: [SlotSymbol] = Array(repeating: SlotSymbol(value: 10), count: 3)
    @State private var spinning = false
    @State private var leverTilt = 0.0
    @State private var timer: Timer?
    @State private var localResultText: String?
    @State private var blinkActive = false
    
    private let symbolPool = [SlotSymbol(value: 10), SlotSymbol(value: -15)]
    
    var body: some View {
        let credits = gameManager.slotRewardCredits()
        
        VStack(spacing: 0) {
            // Machine Header / Scoreboard
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("JACKPOT")
                        .font(.system(size: 10, weight: .black))
                        .foregroundStyle(.orange)
                    Text("50 / 50")
                        .font(.system(.title3, design: .monospaced))
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                }
                
                Spacer()
                
                // Digital Credit Counter
                VStack(alignment: .trailing, spacing: 4) {
                    let spinsLabel = String(localized: "SPINS")
                    Text(spinsLabel)
                        .font(.system(size: 10, weight: .black))
                        .foregroundStyle(.blue)
                    Text(String(format: "%02d", credits))
                        .font(.system(.title2, design: .monospaced))
                        .fontWeight(.bold)
                        .foregroundStyle(.blue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(12)
                }
            }
            .padding(20)
            .background(Color.black.opacity(0.4))
            
            // The Reels Area
            HStack(spacing: 15) {
                // Left Light Strip
                VStack(spacing: 10) {
                    ForEach(0..<5) { i in
                        Circle()
                            .fill(blinkActive ? Color.blue : Color.blue.opacity(0.3))
                            .frame(width: 6, height: 6)
                            .shadow(color: .blue, radius: blinkActive ? 4 : 0)
                            .animation(.easeInOut(duration: 0.5).delay(Double(i) * 0.1).repeatForever(), value: blinkActive)
                    }
                }
                
                // Slots Case
                HStack(spacing: 10) {
                    ForEach(0..<3, id: \.self) { index in
                        SlotReel(symbol: reelSymbols[index], isSpinning: spinning)
                    }
                }
                .padding(15)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(LinearGradient(colors: [Color(white: 0.15), Color(white: 0.05)], startPoint: .top, endPoint: .bottom))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.black.opacity(0.5), lineWidth: 1)
                )
                
                // Lever (Attached to the right)
                LeverHandle(angle: leverTilt)
                    .frame(width: 40)
                    .onTapGesture {
                        if !spinning && credits > 0 { startSpin() }
                    }
            }
            .padding(.vertical, 30)
            .padding(.horizontal, 10)
            
            // Action Area
            HStack(spacing: 20) {
                // Skip Button
                Button(action: { gameManager.skipSlotReward() }) {
                    Text(LocalizedStringKey("Überspringen"))
                        .font(.caption.bold())
                        .foregroundStyle(.white.opacity(0.6))
                        .padding(.vertical, 12)
                        .padding(.horizontal, 20)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(18)
                }
                .disabled(spinning)
                
                // Big Spin Button
                Button(action: startSpin) {
                    let btnText = spinning ? LocalizedStringKey("SPINNING...") : LocalizedStringKey("PUSH")
                    Text(btnText)
                        .font(.system(size: 18, weight: .black))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(
                            ZStack {
                                RoundedRectangle(cornerRadius: 18)
                                    .fill(spinning || credits == 0 ? Color.gray.opacity(0.3) : Color.red)
                                
                                if !spinning && credits > 0 {
                                    RoundedRectangle(cornerRadius: 18)
                                        .stroke(Color.white.opacity(0.5), lineWidth: 2)
                                        .blur(radius: blinkActive ? 4 : 0)
                                }
                            }
                        )
                        .shadow(color: spinning || credits == 0 ? .clear : .red.opacity(0.5), radius: 10)
                }
                .disabled(spinning || credits == 0)
            }
            .padding(20)
            .background(Color.black.opacity(0.2))
        }
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(LinearGradient(colors: [Color(white: 0.25), Color(white: 0.15)], startPoint: .topLeading, endPoint: .bottomTrailing))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .stroke(LinearGradient(colors: [.white.opacity(0.2), .black.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 2)
        )
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .shadow(color: .black.opacity(0.5), radius: 30, x: 0, y: 20)
        .onAppear { blinkActive = true }
        .onDisappear { stopTimer() }
    }
    
    private func startSpin() {
        guard !spinning, gameManager.slotRewardCredits() > 0 else { return }
        
        TimesUpHaptics.impact(.heavy)
        localResultText = nil
        spinning = true
        
        // Lever animation
        withAnimation(.easeIn(duration: 0.2)) {
            leverTilt = 25
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.4)) {
                leverTilt = 0
            }
        }
        
        startTimer()
        
        let spinDuration = 2.0
        DispatchQueue.main.asyncAfter(deadline: .now() + spinDuration) {
            stopTimer()
            if let result = gameManager.spinSlotReward() {
                TimesUpHaptics.impact(.medium)
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    reelSymbols = Array(repeating: SlotSymbol(value: result.isWin ? 10 : -15), count: 3)
                    localResultText = result.text
                }
            }
            spinning = false
        }
    }
    
    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            guard !symbolPool.isEmpty else { return }
            for i in 0..<3 {
                if let symbol = symbolPool.randomElement() {
                    reelSymbols[i] = symbol
                }
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

private struct SlotSymbol {
    let value: Int
    var primaryText: String { value >= 0 ? "+\(value)" : "\(value)" }
    var color: Color { value >= 0 ? .green : .red }
}

private struct SlotReel: View {
    let symbol: SlotSymbol
    let isSpinning: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            Text(symbol.primaryText)
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundStyle(symbol.color)
                .shadow(color: symbol.color.opacity(0.5), radius: 5)
            
            Text(LocalizedStringKey("PKT"))
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(symbol.color.opacity(0.7))
        }
        .frame(width: 70, height: 90)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.black)
                
                // Glass effect
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        LinearGradient(colors: [.white.opacity(0.1), .clear, .black.opacity(0.2)], 
                                       startPoint: .topLeading, 
                                       endPoint: .bottomTrailing)
                    )
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .scaleEffect(isSpinning ? 0.95 : 1.0)
        .offset(y: isSpinning ? CGFloat.random(in: -2...2) : 0)
    }
}

private struct LeverHandle: View {
    let angle: Double
    
    var body: some View {
        VStack(spacing: 0) {
            // Ball
            Circle()
                .fill(RadialGradient(colors: [.red, Color(red: 0.5, green: 0, blue: 0)], center: .center, startRadius: 2, endRadius: 15))
                .frame(width: 24, height: 24)
                .shadow(color: .black.opacity(0.5), radius: 4, x: 2, y: 2)
            
            // Rod
            RoundedRectangle(cornerRadius: 4)
                .fill(LinearGradient(colors: [Color(white: 0.6), Color(white: 0.3), Color(white: 0.5)], startPoint: .leading, endPoint: .trailing))
                .frame(width: 8, height: 60)
            
            // Base
            Circle()
                .fill(Color(white: 0.2))
                .frame(width: 30, height: 30)
                .overlay(Circle().stroke(Color.black, lineWidth: 2))
        }
        .rotationEffect(.degrees(angle), anchor: .bottom)
    }
}

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

struct TeamBadgeBar: View {
    @ObservedObject var gameManager: GameManager
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(Array(gameManager.gameState.settings.teams.enumerated()), id: \.element.id) { entry in
                let team = entry.element
                TeamBadgeView(
                    team: team,
                    isActive: entry.offset == gameManager.gameState.currentTeamIndex
                )
            }
        }
    }
}

private struct TeamBadgeView: View {
    let team: Team
    let isActive: Bool

    private var initials: String {
        String(team.name.prefix(2)).uppercased()
    }

    var body: some View {
        VStack(spacing: 2) {
            ZStack {
                Circle()
                    .fill(
                        isActive
                        ? AnyShapeStyle(TimesUpStyle.primaryGradient)
                        : AnyShapeStyle(Color.gray.opacity(0.3))
                    )
                    .frame(width: 32, height: 32)
                    .overlay(
                        Circle()
                            .stroke(
                                isActive ? Color.blue : Color.gray.opacity(0.5),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: isActive ? .blue.opacity(0.5) : .clear, radius: 4)

                Text(initials)
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(isActive ? .white : .gray)
            }

            // Score unter dem Badge
            Text("\(team.score)")
                .font(.system(size: 10, weight: .heavy, design: .rounded))
                .foregroundStyle(isActive ? .white : .gray.opacity(0.7))
                .contentTransition(.numericText())
                .animation(.spring(response: 0.3), value: team.score)
        }
    }
}

struct ScoreBurstBar: View {
    @ObservedObject var gameManager: GameManager
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(gameManager.gameState.settings.teams) { team in
                ScoreBurstStack(bursts: gameManager.scoreBursts.filter { $0.teamId == team.id })
                    .frame(width: 54, alignment: .center)
            }
        }
    }
}

private struct ScoreBurstStack: View {
    let bursts: [GameManager.ScoreBurst]
    
    var body: some View {
        ZStack {
            ForEach(bursts) { burst in
                ScoreBurstLabel(burst: burst)
            }
        }
        .allowsHitTesting(false)
    }
}

private struct ScoreBurstLabel: View {
    let burst: GameManager.ScoreBurst
    @State private var animate = false
    
    private var burstColor: Color {
        burst.isNegative ? .red : .green
    }
    
    var body: some View {
        Text(burst.text)
            .font(.caption2.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(burstColor.opacity(0.9))
            .clipShape(Capsule())
            .shadow(color: burstColor.opacity(0.4), radius: 6, x: 0, y: 3)
            .offset(y: animate ? 34 : -12)
            .opacity(animate ? 0 : 1)
            .scaleEffect(animate ? 0.85 : 1.05)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.2)) {
                    animate = true
                }
            }
    }
}


// MARK: - Game Header
struct GameHeaderView: View {
    @ObservedObject var gameManager: GameManager
    
    var body: some View {
        VStack(spacing: 15) {
            // Runden-Info
            HStack {
                Text(gameManager.gameState.currentRound.title)
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Text(gameManager.gameState.currentRound.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            // Timer und Team
            HStack {
                // Aktuelles Team
                if let team = gameManager.gameState.currentTeam {
                    VStack(alignment: .leading) {
                        Text("Team:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(team.name)
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                }
                
                Spacer()
                
                // Verbleibende Begriffe für aktuelles Team
                VStack(alignment: .center) {
                    Text("Begriffe übrig:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(gameManager.gameState.remainingTermsCount)")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(.orange)
                }
                
                Spacer()
                
                // Timer
                    VStack(alignment: .trailing) {
                        Text("Zeit:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(gameManager.formattedTimeRemaining)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundStyle(gameManager.gameState.turnTimeRemaining < 10 ? .red : .primary)
                    }
            }
            .padding()
            .background(Color(.systemGray5))
            .cornerRadius(12)
            .shadow(color: .primary.opacity(0.08), radius: 3, x: 0, y: 1)
        }
    }
}

// MARK: - Round End View
struct RoundEndView: View {
    @ObservedObject var gameManager: GameManager

    var body: some View {
        ZStack {
            TimesUpStyle.backgroundGradient
                .ignoresSafeArea()

            VStack(spacing: 30) {
                Spacer()

                Text(LocalizedStringKey("Runde beendet!"))
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)

                Text(LocalizedStringKey("Zug beendet - Nächstes Team!"))
                    .font(.title3)
                    .foregroundStyle(TimesUpStyle.secondaryText)

                ScoreboardView(teams: gameManager.gameState.settings.teams)

                Spacer()

                Button(action: {
                    TimesUpHaptics.impact(.medium)
                    gameManager.nextTurn()
                }) {
                    Text(LocalizedStringKey("Weiter"))
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(TimesUpStyle.primaryGradient)
                        .clipShape(RoundedRectangle(cornerRadius: TimesUpStyle.rowCornerRadius))
                }
                .padding(.horizontal, 40)
                .padding(.bottom, TimesUpStyle.bottomPadding)
            }
            .padding()
        }
    }
}

// MARK: - Game End View
struct GameEndView: View {
    @ObservedObject var gameManager: GameManager
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

                if gameManager.scoreRevealSnapshots.isEmpty {
                    ScoreboardView(teams: gameManager.gameState.settings.teams, showFinal: true)
                } else {
                    PenaltyRevealScoreboardView(
                        teams: gameManager.gameState.settings.teams,
                        snapshots: gameManager.scoreRevealSnapshots
                    )
                }

                Spacer()

                VStack(spacing: 12) {
                    // Quick Restart: Gleiche Teams, Runde 1 neu
                    Button(action: {
                        TimesUpHaptics.impact(.heavy)
                        gameManager.restartWithSameTeams()
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
                        gameManager.startGame()
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
        let sorted = gameManager.gameState.settings.teams.sorted { $0.score > $1.score }
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
                .cornerRadius(12)
                .shadow(color: .primary.opacity(0.05), radius: 2, x: 0, y: 1)
            }
        }
        .padding()
        .background(Color(.systemGray5))
        .cornerRadius(18)
        .shadow(color: .primary.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Dramatic Penalty Reveal

struct PenaltyRevealScoreboardView: View {
    let teams: [Team]
    let snapshots: [UUID: GameManager.ScoreRevealSnapshot]
    
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
    let snapshot: GameManager.ScoreRevealSnapshot?
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

#Preview {
    @Previewable @State var gameManager = GameManager()
    
    // Teams für Preview hinzufügen
    gameManager.gameState.settings.teams = [
        Team(name: "Ken"),
        Team(name: "Elif")
    ]
    
    return TimesUpGameView(gameManager: gameManager)
}
