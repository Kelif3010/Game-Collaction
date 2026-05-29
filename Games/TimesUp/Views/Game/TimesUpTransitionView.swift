import SwiftUI

// MARK: - Setup Phase
struct SetupPhaseView: View {
    @ObservedObject var viewModel: TimesUpGameViewModel

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
                    if let team = viewModel.gameState.currentTeam {
                        Text("Team: \(team.name)")
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .foregroundStyle(TimesUpStyle.primaryGradient)
                            .shadow(color: .blue, radius: 20, x: 0, y: 0)
                            .shadow(color: .white.opacity(0.5), radius: 2, x: 0, y: 1)
                    }

                    Text(LocalizedStringKey(viewModel.gameState.currentRound.title))
                        .font(.title2)
                        .foregroundStyle(.gray)
                        .fontWeight(.bold)
                }

                Spacer()

                // Round Description Banner
                VStack(spacing: 15) {
                    Text(LocalizedStringKey(viewModel.gameState.currentRound.description))
                        .font(.title2)
                        .foregroundStyle(.primary)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    Text(LocalizedStringKey(viewModel.gameState.currentRound.detailedRules))
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
                    viewModel.startRound()
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
    @ObservedObject var viewModel: TimesUpGameViewModel

    @State private var headerVisible = false
    @State private var cardVisible = false
    @State private var buttonVisible = false

    private var sortedTeams: [Team] {
        viewModel.gameState.settings.teams.sorted { $0.score > $1.score }
    }

    var body: some View {
        ZStack {
            TimesUpStyle.backgroundGradient
                .ignoresSafeArea()

            // Ambient neon glows
            GeometryReader { geo in
                Circle()
                    .fill(Color.purple.opacity(0.20))
                    .frame(width: geo.size.width * 0.8)
                    .blur(radius: 80)
                    .offset(x: geo.size.width * 0.35, y: -geo.size.width * 0.2)
                Circle()
                    .fill(Color.cyan.opacity(0.14))
                    .frame(width: geo.size.width * 0.9)
                    .blur(radius: 90)
                    .offset(x: -geo.size.width * 0.2, y: geo.size.height * 0.55)
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)

            VStack(spacing: 0) {
                // Hero
                VStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(Color.cyan.opacity(0.22))
                            .frame(width: 86, height: 86)
                            .blur(radius: 24)
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 64))
                            .foregroundStyle(Color.cyan)
                            .shadow(color: .cyan.opacity(0.55), radius: 14, x: 0, y: 0)
                    }
                    .padding(.bottom, 6)

                    Text("Runde beendet!")
                        .font(.system(size: 42, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .shadow(color: .purple.opacity(0.4), radius: 8, x: 0, y: 0)

                    Text("Zug beendet · Nächstes Team!")
                        .font(.system(size: 17, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.58))
                }
                .padding(.top, 64)
                .opacity(headerVisible ? 1 : 0)
                .offset(y: headerVisible ? 0 : 32)

                // Scoreboard card
                roundEndScoreboardCard
                    .padding(.top, 28)
                    .opacity(cardVisible ? 1 : 0)
                    .offset(y: cardVisible ? 0 : 32)

                Spacer(minLength: 20)

                // Weiter button
                roundEndWeiterButton
                    .padding(.bottom, TimesUpStyle.bottomPadding)
                    .opacity(buttonVisible ? 1 : 0)
                    .offset(y: buttonVisible ? 0 : 20)
            }
            .padding(.horizontal, TimesUpStyle.horizontalPadding)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                headerVisible = true
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.12)) {
                cardVisible = true
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.22)) {
                buttonVisible = true
            }
        }
    }

    private var roundEndScoreboardCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(Color.black.opacity(0.28))
                .overlay(
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.45), radius: 40, x: 0, y: 20)

            VStack(spacing: 0) {
                HStack {
                    Text("Scoreboard")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Spacer()
                    Text(viewModel.gameState.currentRound.shortDescription.uppercased())
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .kerning(1.2)
                        .foregroundStyle(.white.opacity(0.55))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule(style: .continuous)
                                .fill(Color.white.opacity(0.07))
                                .overlay(
                                    Capsule(style: .continuous)
                                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                                )
                        )
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 16)

                VStack(spacing: 12) {
                    ForEach(Array(sortedTeams.enumerated()), id: \.element.id) { index, team in
                        RoundEndTeamRow(
                            team: team,
                            rank: index + 1,
                            rowStyle: index == 0 ? .leader : (index == 1 ? .second : .standard)
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }
        }
    }

    private var roundEndWeiterButton: some View {
        Button(action: {
            TimesUpHaptics.impact(.medium)
            viewModel.nextTurn()
        }) {
            HStack(spacing: 10) {
                Text("Weiter")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.cyan)
                Image(systemName: "arrow.forward")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Color.cyan)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(
                ZStack {
                    Capsule(style: .continuous).fill(Color.cyan.opacity(0.08))
                    Capsule(style: .continuous).stroke(Color.cyan.opacity(0.40), lineWidth: 1)
                }
            )
            .shadow(color: .cyan.opacity(0.18), radius: 20, x: 0, y: 0)
        }
        .buttonStyle(RoundEndScaleButtonStyle())
    }
}

private struct RoundEndScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

private enum RoundEndRowStyle: Equatable {
    case leader
    case second
    case standard
}

private struct RoundEndTeamRow: View {
    let team: Team
    let rank: Int
    let rowStyle: RoundEndRowStyle

    @State private var glowing = false

    var body: some View {
        ZStack {
            rowBackground
            rowContent
        }
        .frame(height: 64)
        .opacity(rowStyle == .standard ? (rank <= 3 ? 0.70 : 0.50) : 1.0)
        .onAppear {
            if rowStyle == .second {
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                    glowing = true
                }
            }
        }
    }

    @ViewBuilder
    private var rowBackground: some View {
        switch rowStyle {
        case .leader:
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(LinearGradient(
                        colors: [.purple, .pink, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
                    .opacity(0.55)
                RoundedRectangle(cornerRadius: 23, style: .continuous)
                    .fill(Color.black.opacity(0.80))
                    .padding(1)
            }
        case .second:
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.black.opacity(0.38))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.cyan.opacity(glowing ? 0.55 : 0.25), lineWidth: 1)
                )
                .shadow(color: .cyan.opacity(glowing ? 0.22 : 0.08), radius: 10, x: 0, y: 0)
        case .standard:
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                )
        }
    }

    private var rowContent: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(rankBadgeFill)
                    .overlay(Circle().stroke(rankBadgeBorder, lineWidth: 1))
                    .frame(width: 40, height: 40)
                Text("\(rank)")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(scoreColor)
            }

            Text(team.name)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(rowStyle == .standard ? Color.white.opacity(0.55) : .white)
                .lineLimit(1)

            Spacer()

            if rowStyle == .leader {
                Image(systemName: "star.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.purple)
                    .shadow(color: .purple.opacity(0.6), radius: 5)
            }

            Text("\(team.score)")
                .font(.system(size: 28, weight: .heavy, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(scoreColor)
                .shadow(color: scoreColor.opacity(0.45), radius: 6)
                .contentTransition(.numericText())
                .animation(.spring(response: 0.4), value: team.score)
        }
        .padding(.horizontal, 16)
    }

    private var scoreColor: Color {
        switch rowStyle {
        case .leader:   return Color.purple
        case .second:   return Color.cyan
        case .standard: return Color.white.opacity(0.50)
        }
    }

    private var rankBadgeFill: Color {
        switch rowStyle {
        case .leader:   return Color.purple.opacity(0.20)
        case .second:   return Color.cyan.opacity(0.18)
        case .standard: return Color.white.opacity(0.08)
        }
    }

    private var rankBadgeBorder: Color {
        switch rowStyle {
        case .leader:   return Color.purple.opacity(0.35)
        case .second:   return Color.cyan.opacity(0.30)
        case .standard: return Color.white.opacity(0.05)
        }
    }
}


struct SlotRewardFullView: View {
    @ObservedObject var viewModel: TimesUpGameViewModel
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
                
                SlotMachineCard(viewModel: viewModel, team: team)
                    .padding(.horizontal, 20)
                
                Spacer()
                
                VStack(spacing: 20) {
                    if viewModel.slotRewardCredits() > 0 {
                        Text(LocalizedStringKey("Verbrauche oder überspringe alle Spins, um fortzufahren."))
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.5))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    
                    Button(action: {
                        viewModel.finishSlotReward()
                    }) {
                        Text(LocalizedStringKey("Weiter"))
                            .font(.title3.bold())
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 60)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(viewModel.slotRewardCredits() > 0 ? Color.white.opacity(0.1) : Color.green)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(viewModel.slotRewardCredits() > 0 ? Color.white.opacity(0.1) : Color.white.opacity(0.3), lineWidth: 1)
                            )
                    }
                    .disabled(viewModel.slotRewardCredits() > 0)
                    .padding(.horizontal, 30)
                    .padding(.bottom, 40)
                }
            }
        }
    }
}

struct SlotMachineCard: View {
    @ObservedObject var viewModel: TimesUpGameViewModel
    let team: Team
    @State private var reelSymbols: [SlotSymbol] = Array(repeating: SlotSymbol(value: 10), count: 3)
    @State private var spinning = false
    @State private var leverTilt = 0.0
    @State private var timer: Timer?
    @State private var localResultText: String?
    @State private var blinkActive = false
    
    private let symbolPool = [SlotSymbol(value: 10), SlotSymbol(value: -15)]
    
    var body: some View {
        let credits = viewModel.slotRewardCredits()
        
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
                Button(action: { viewModel.skipSlotReward() }) {
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
        guard !spinning, viewModel.slotRewardCredits() > 0 else { return }
        
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
            if let result = viewModel.spinSlotReward() {
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

#Preview("Runde beendet") {
    @Previewable @State var vm = TimesUpGameViewModel()
    let _ = {
        vm.gameState.settings.teams = [
            Team(name: "Team Alpha"),
            Team(name: "Team Bravo"),
            Team(name: "Team Charlie"),
            Team(name: "Team Delta")
        ]
        vm.gameState.settings.teams[0].score = 42
        vm.gameState.settings.teams[1].score = 38
        vm.gameState.settings.teams[2].score = 25
        vm.gameState.settings.teams[3].score = 12
        vm.gameState.phase = .roundEnd
    }()
    return RoundEndView(viewModel: vm)
}

