import SwiftUI

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
                        .clipShape(RoundedRectangle(cornerRadius: 12))
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
                        .clipShape(RoundedRectangle(cornerRadius: 18))
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
            Task { @MainActor in
                guard !symbolPool.isEmpty else { return }
                for i in 0..<3 {
                    if let symbol = symbolPool.randomElement() {
                        reelSymbols[i] = symbol
                    }
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

