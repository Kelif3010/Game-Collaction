import SwiftUI

struct TimesUpGameView: View {
    @ObservedObject var gameManager: GameManager
    @Environment(\.presentationMode) var presentationMode
    @State private var showingEndGame = false
    
    var body: some View {
        NavigationView {
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
                    .foregroundColor(.red)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    TeamBadgeBar(gameManager: gameManager)
                }
                
                ToolbarItem(placement: .principal) {
                    Text(gameManager.gameState.currentRound.shortDescription)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
            }
            .alert("Spiel beenden?", isPresented: $showingEndGame) {
                Button("Abbrechen", role: .cancel) { }
                Button("Beenden", role: .destructive) {
                    presentationMode.wrappedValue.dismiss()
                }
            } message: {
                Text("Möchtest du das aktuelle Spiel wirklich beenden?")
            }
        }
        .overlay(alignment: .topTrailing) {
            if !gameManager.scoreBursts.isEmpty {
                ScoreBurstBar(gameManager: gameManager)
                    .padding(.top, 64)
                    .offset(x: 20)
            }
        }
        .navigationBarHidden(true)
    }
}

// MARK: - Setup Phase
struct SetupPhaseView: View {
    @ObservedObject var gameManager: GameManager
    
    var body: some View {
        ZStack {
            // Gleicher dunkler Hintergrund
            LinearGradient(
                colors: [
                    Color.black,
                    Color(.systemGray6).opacity(0.3),
                    Color.blue.opacity(0.15),
                    Color.purple.opacity(0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header Area - leer, da Team-Anzeige jetzt in Toolbar
                Spacer()
                    .frame(height: 20)
                
                Spacer()
                
                // Team Info - Neon Style
                VStack(spacing: 15) {
                    // Team: Team Name - Zusammen in einer Zeile mit Neon-Effekt
                    if let team = gameManager.gameState.currentTeam {
                        Text("Team: \(team.name)")
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .shadow(color: .blue, radius: 20, x: 0, y: 0)
                            .shadow(color: .white.opacity(0.5), radius: 2, x: 0, y: 1)
                    }
                    
                    // Runde Info
                    Text(LocalizedStringKey(gameManager.gameState.currentRound.title))
                        .font(.title2)
                        .foregroundColor(.gray)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                // Runden-Beschreibung Banner - Größerer Style
                VStack(spacing: 15) {
                    Text(LocalizedStringKey(gameManager.gameState.currentRound.description))
                        .font(.title2)
                        .foregroundColor(.primary)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text(LocalizedStringKey(gameManager.gameState.currentRound.detailedRules))
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                }
                .padding(.horizontal, 40)
                .padding(.vertical, 70)
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color(.systemGray6).opacity(0.7))
                        .overlay(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1.5)
                        )
                )
                .padding(.horizontal, 15)
                
                Spacer()
                
                Button(action: {
                    gameManager.startRound()
                }) {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.green, .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 120, height: 120)
                        .overlay(
                            VStack(spacing: 5) {
                                Image(systemName: "play.fill")
                                    .font(.system(size: 30, weight: .bold))
                                    .foregroundColor(.white)
                                Text(LocalizedStringKey("Start!"))
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                        )
                        .shadow(color: .green.opacity(0.4), radius: 15, x: 0, y: 8)
                }
                .padding(.bottom, 50)
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
                        .foregroundColor(.blue.opacity(0.8))
                    
                    Text(team.name)
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
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
                            .foregroundColor(.white.opacity(0.5))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    
                    Button(action: {
                        gameManager.finishSlotReward()
                    }) {
                        Text(LocalizedStringKey("Weiter"))
                            .font(.title3.bold())
                            .foregroundColor(.white)
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
                        .foregroundColor(.orange)
                    Text("50 / 50")
                        .font(.system(.title3, design: .monospaced))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                // Digital Credit Counter
                VStack(alignment: .trailing, spacing: 4) {
                    let spinsLabel = String(localized: "SPINS")
                    Text(spinsLabel)
                        .font(.system(size: 10, weight: .black))
                        .foregroundColor(.blue)
                    Text(String(format: "%02d", credits))
                        .font(.system(.title2, design: .monospaced))
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(8)
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
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.vertical, 12)
                        .padding(.horizontal, 20)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(15)
                }
                .disabled(spinning)
                
                // Big Spin Button
                Button(action: startSpin) {
                    let btnText = spinning ? LocalizedStringKey("SPINNING...") : LocalizedStringKey("PUSH")
                    Text(btnText)
                        .font(.system(size: 18, weight: .black))
                        .foregroundColor(.white)
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
        
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
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
                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
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
            for i in 0..<3 {
                reelSymbols[i] = symbolPool.randomElement()!
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
                .foregroundColor(symbol.color)
                .shadow(color: symbol.color.opacity(0.5), radius: 5)
            
            Text(LocalizedStringKey("PKT"))
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(symbol.color.opacity(0.7))
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

// MARK: - Playing Phase
struct PlayingPhaseView: View {
    @ObservedObject var gameManager: GameManager
    
    var body: some View {
        let forcedSkipActive = gameManager.isForcedSkipActiveForCurrentTeam()
        let notices = gameManager.perkNoticesForCurrentTeam()
        let attackNotices = gameManager.attackNoticesForCurrentTeam()
        let streak = gameManager.currentHitStreakCount()
        
        return ZStack {
            LinearGradient(
                colors: [
                    Color.black,
                    Color(.systemGray6).opacity(0.3),
                    Color.blue.opacity(0.15),
                    Color.purple.opacity(0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Spacer()
                    .frame(height: 30)
                
                TimerView(gameManager: gameManager)
                
                if let term = gameManager.gameState.currentTerm {
                    WordBannerView(
                        gameManager: gameManager,
                        term: term
                    )
                    .padding(.horizontal, 30)
                }
                
                if !notices.isEmpty || !attackNotices.isEmpty {
                    PerkNoticeStack(notices: notices, attackNotices: attackNotices)
                        .padding(.horizontal, 30)
                }
                
                if streak > 1 {
                    StreakFlameView(streak: streak)
                        .padding(.top, -8)
                }
                
                Spacer()
                
                VStack(spacing: 20) {
                    if !forcedSkipActive {
                        Button(action: {
                            gameManager.correctGuess()
                        }) {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.green, .blue],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: 120, height: 120)
                                .overlay(
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 40, weight: .bold))
                                        .foregroundColor(.white)
                                )
                                .shadow(color: .green.opacity(0.4), radius: 15, x: 0, y: 8)
                        }
                    }

                    if gameManager.gameState.currentRound.canSkip {
                        let skipFrozen = gameManager.isSkipButtonFrozenForCurrentTeam()
                        Button(action: {
                            gameManager.skipTerm()
                        }) {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 80, height: 80)
                                .overlay(
                                    Image(systemName: "arrow.right")
                                        .font(.system(size: 25, weight: .bold))
                                        .foregroundColor(.white)
                                )
                                .shadow(color: .blue.opacity(0.4), radius: 10, x: 0, y: 5)
                                .overlay(alignment: .bottomTrailing) {
                                    if skipFrozen {
                                        Image(systemName: "lock.fill")
                                            .font(.caption)
                                            .foregroundColor(.white)
                                            .padding(6)
                                            .background(Color.black.opacity(0.45))
                                            .clipShape(Circle())
                                            .offset(x: 20, y: 20)
                                    }
                                }
                        }
                        .disabled(skipFrozen)
                        if forcedSkipActive {
                            Text("Zwangs-Skip aktiv – zuerst Skip ausführen.")
                                .font(.footnote)
                                .foregroundColor(.yellow)
                        }
                        
                        if !forcedSkipActive && gameManager.gameState.settings.difficulty == .hard {
                            Button(action: {
                                gameManager.wrongGuess()
                            }) {
                                Circle()
                                    .fill(
                                        LinearGradient(colors: [.red, .red.opacity(0.8)],
                                                       startPoint: .topLeading,
                                                       endPoint: .bottomTrailing)
                                    )
                                    .frame(width: 80, height: 80)
                                    .overlay(
                                        Image(systemName: "xmark")
                                            .font(.system(size: 25, weight: .bold))
                                            .foregroundColor(.white)
                                    )
                                    .shadow(color: .red.opacity(0.5), radius: 10, x: 0, y: 5)
                            }
                            .disabled(skipFrozen)
                        }
                    }
                }
                .padding(.bottom, 10)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
        }
    }
}

private struct WordBannerView: View {
    @ObservedObject var gameManager: GameManager
    let term: Term
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground).opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing),
                            lineWidth: 2
                        )
                )
                .shadow(color: .blue.opacity(0.3), radius: 15, x: 0, y: 5)
            
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
                
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.orange, .red],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 52, height: 52)
                    .overlay(
                        Text("\(gameManager.gameState.remainingTermsCount)")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    )
                    .shadow(color: .orange.opacity(0.6), radius: 10, x: 0, y: 0)
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
                .foregroundColor(color.opacity(0.9))
                .padding(.leading, 6)
                .textCase(.uppercase)
            
            VStack(alignment: .leading, spacing: 10) {
                ForEach(notices) { notice in
                    HStack(spacing: 10) {
                        Text(notice.icon)
                            .font(.title3)
                        
                        Text(notice.text)
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                        
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
                .foregroundColor(color.opacity(0.9))
                .padding(.leading, 6)
                .textCase(.uppercase)

            VStack(alignment: .leading, spacing: 10) {
                ForEach(notices) { notice in
                    HStack(spacing: 10) {
                        Text(notice.icon)
                            .font(.title3)

                        Text("An \(notice.targetName), \(notice.label)")
                            .font(.subheadline.bold())
                            .foregroundColor(.white)

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
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "flame.fill")
                .foregroundColor(.orange)
            Text("Streak \(streak)x")
                .font(.subheadline.bold())
                .foregroundColor(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(
                    LinearGradient(colors: [.orange, .pink], startPoint: .leading, endPoint: .trailing)
                        .opacity(0.25)
                )
        )
        .overlay(
            Capsule()
                .stroke(
                    LinearGradient(colors: [.orange, .pink], startPoint: .leading, endPoint: .trailing),
                    lineWidth: 1
                )
        )
        .shadow(color: .orange.opacity(0.4), radius: 6, x: 0, y: 3)
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
        ZStack {
            Circle()
                .fill(isActive ?
                      LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing) :
                        LinearGradient(colors: [.gray.opacity(0.3)], startPoint: .leading, endPoint: .trailing)
                )
                .frame(width: 32, height: 32)
                .overlay(
                    Circle()
                        .stroke(isActive ? Color.blue : Color.gray.opacity(0.5), lineWidth: 1)
                )
            
            Text(initials)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(isActive ? .white : .gray)
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
                    .foregroundColor(.secondary)
            }
            
            // Timer und Team
            HStack {
                // Aktuelles Team
                if let team = gameManager.gameState.currentTeam {
                    VStack(alignment: .leading) {
                        Text("Team:")
                            .font(.caption)
                            .foregroundColor(.secondary)
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
                        .foregroundColor(.secondary)
                    Text("\(gameManager.gameState.remainingTermsCount)")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                }
                
                Spacer()
                
                // Timer
                    VStack(alignment: .trailing) {
                        Text("Zeit:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(gameManager.formattedTimeRemaining)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(gameManager.gameState.turnTimeRemaining < 10 ? .red : .primary)
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
        VStack(spacing: 30) {
            Spacer()
            
            Text(LocalizedStringKey("Runde beendet!"))
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text(LocalizedStringKey("Zug beendet - Nächstes Team!"))
                .font(.title3)
                .foregroundColor(.secondary)
            
            // Zwischenstand
            ScoreboardView(teams: gameManager.gameState.settings.teams)
            
            Spacer()
            
            Button(action: {
                gameManager.nextTurn()
            }) {
                Text(LocalizedStringKey("Weiter"))
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(Color.blue)
                    .cornerRadius(15)
            }
            .padding(.horizontal, 40)
        }
        .padding()
    }
}

// MARK: - Game End View
struct GameEndView: View {
    @ObservedObject var gameManager: GameManager
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Text(LocalizedStringKey("🎉 Spiel beendet! 🎉"))
                .font(.largeTitle)
                .fontWeight(.bold)
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
            
            Button(action: {
                // Neues Spiel starten
                gameManager.startGame()
                presentationMode.wrappedValue.dismiss()
            }) {
                Text(LocalizedStringKey("Neues Spiel"))
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(
                        LinearGradient(
                            colors: [.green, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(15)
            }
            .padding(.horizontal, 40)
        }
        .padding()
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
                        .foregroundColor(index == 0 && showFinal ? .yellow : .primary)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(index == 0 && showFinal ? Color.yellow.opacity(0.2) : Color(.systemGray5))
                .cornerRadius(8)
                .shadow(color: .primary.opacity(0.05), radius: 2, x: 0, y: 1)
            }
        }
        .padding()
        .background(Color(.systemGray5))
        .cornerRadius(15)
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
                withAnimation(.spring(response: 0.6, dampingFraction: 0.65, blendDuration: 0.3)) {
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
                        .foregroundColor(.primary)
                    Text(isRevealed ? "Endstand" : "Zwischenstand")
                        .opacity(showFinalScores ? 0.0 : 1.0)
                        .font(.caption)
                        .foregroundColor(.secondary)
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
        .foregroundColor(.white)
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
