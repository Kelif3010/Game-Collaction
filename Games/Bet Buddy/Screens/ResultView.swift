import SwiftUI
import StoreKit
import Foundation

struct ResultView: View {
    let result: GameResult
    @EnvironmentObject private var appModel: AppViewModel
    
    var onRestart: () -> Void
    var onNewChallenge: () -> Void

    @State private var currentScores: [UUID: Int] = [:]
    @Namespace private var leaderboardNamespace
    @Environment(\.requestReview) var requestReview
    
    @State private var showRestartAlert = false

    private var animatedLeaderboard: [LeaderboardEntry] {
        result.leaderboard.sorted { lhs, rhs in
            let scoreL = currentScores[lhs.id, default: 0]
            let scoreR = currentScores[rhs.id, default: 0]
            
            if scoreL != scoreR {
                return scoreL > scoreR
            }
            return lhs.name < rhs.name
        }
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            
            if result.outcome == .win {
                ParticleEffectView(type: .confetti)
            } else {
                ParticleEffectView(type: .rain)
            }

            VStack(spacing: 0) {
                topBar.padding(.bottom, 30)

                VStack(spacing: 24) {
                    VStack(spacing: 16) {
                        let topScore = currentScores[animatedLeaderboard.first?.id ?? UUID()] ?? 0
                        
                        if result.inputType == .alphabet {
                            LetterFlipView(
                                value: topScore,
                                color: result.outcome == .win ? .purple : .red
                            )
                            .id(animatedLeaderboard.first?.id)
                        } else {
                            FlipCounterView(
                                value: topScore,
                                color: result.outcome == .win ? .purple : .red
                            )
                            .id(animatedLeaderboard.first?.id)
                        }
                        
                        Text(result.challengeText)
                            .foregroundStyle(.white)
                            .font(.headline.weight(.semibold))
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal)
                    }

                    leaderboardView.padding(.horizontal)
                }

                Spacer()

                HStack(spacing: 12) {
                    Button {
                        HapticsService.impact(.medium)
                        showRestartAlert = true
                    } label: {
                        Text("Neu starten")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.white.opacity(0.12))
                            .clipShape(Capsule())
                    }

                    Button {
                        HapticsService.impact(.light)
                        onNewChallenge()
                    } label: {
                        Text("Neue Challenge")
                            .font(.headline)
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.white)
                            .clipShape(Capsule())
                    }
                }
                .padding(.top, 20)
            }
            .padding(Theme.padding)
        }
        .toolbar(.hidden, for: .navigationBar)
        .alert("Neu starten", isPresented: $showRestartAlert) {
            Button("Abbrechen", role: .cancel) { }
            
            Button("Alles löschen", role: .destructive) {
                // ÄNDERUNG: Nur Session Reset, Stats bleiben
                appModel.resetSessionScores()
                onRestart()
            }
            
            Button("Punkte behalten") {
                onRestart()
            }
        } message: {
            Text("Möchtest du die Punkte behalten oder alles auf 0 setzen?")
        }
        .onAppear {
            startRaceAnimation()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                requestReview()
            }
        }
    }

    private var topBar: some View {
        HStack {
            Text("Bet Buddy")
                .foregroundStyle(.white)
                .font(.headline)
            Spacer()
            Button {
                onRestart()
            } label: {
                Image(systemName: "xmark")
                    .font(.headline.bold())
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private var leaderboardView: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(Array(animatedLeaderboard.enumerated()), id: \.element.id) { index, entry in
                let currentScore = currentScores[entry.id, default: 0]
                let displayName = NSLocalizedString(entry.name, comment: "")
                
                HStack(spacing: 16) {
                    Text("\(index + 1).")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(rankColor(for: index))
                        .frame(width: 30, alignment: .leading)
                        .contentTransition(.numericText())

                    Circle()
                        .fill(entry.color.gradient)
                        .frame(width: 40, height: 40)
                        .overlay(
                            Text(String(displayName.prefix(1)))
                                .font(.headline.weight(.bold))
                                .foregroundStyle(.white)
                        )

                    Text(displayName)
                        .foregroundStyle(.white)
                        .font(.subheadline.weight(.semibold))
                    
                    Spacer()
                    
                    (Text("\(currentScore) ") + Text("Pkt"))
                        .foregroundStyle(Theme.mutedText)
                        .font(.subheadline.weight(.medium))
                        .contentTransition(.numericText())
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(rankColor(for: index).opacity(index == 0 ? 0.5 : 0.0), lineWidth: 1)
                )
                .matchedGeometryEffect(id: entry.id, in: leaderboardNamespace)
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: animatedLeaderboard)
    }

    private func rankColor(for index: Int) -> Color {
        switch index {
        case 0: return Color(red: 1.0, green: 0.84, blue: 0.0)
        case 1: return Color(red: 0.75, green: 0.75, blue: 0.75)
        case 2: return Color(red: 0.8, green: 0.5, blue: 0.2)
        default: return Color.white.opacity(0.3)
        }
    }

    private func startRaceAnimation() {
        for entry in result.leaderboard {
            currentScores[entry.id] = 0
        }

        Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { timer in
            var allDone = true
            
            for entry in result.leaderboard {
                let current = currentScores[entry.id, default: 0]
                let target = entry.score
                
                if current < target {
                    let step = max(1, (target - current) / 12)
                    currentScores[entry.id] = current + step
                    allDone = false
                }
            }
            
            if allDone {
                timer.invalidate()
            }
        }
    }
}

struct ParticleEffectView: View {
    enum EffectType {
        case confetti
        case rain
    }
    
    let type: EffectType
    
    private var particleCount: Int {
        type == .rain ? 200 : 50
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(0..<particleCount, id: \.self) { index in
                    Particle(type: type, screenSize: geometry.size)
                        .id("\(geometry.size.width)-\(index)")
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

struct Particle: View {
    let type: ParticleEffectView.EffectType
    let screenSize: CGSize
    
    @State private var position: CGPoint = CGPoint(x: -100, y: -100)
    @State private var opacity: Double = 0
    @State private var rotation: Double = 0
    @State private var scale: CGFloat = 1.0
    
    let speed: Double
    let size: CGFloat
    let color: Color
    let delay: Double
    
    init(type: ParticleEffectView.EffectType, screenSize: CGSize) {
        self.type = type
        self.screenSize = screenSize
        self.delay = Double.random(in: 0...2.0)
        
        if type == .confetti {
            self.speed = Double.random(in: 2.0...5.0)
            self.size = CGFloat.random(in: 6...12)
            self.color = [Color.red, .blue, .green, .yellow, .pink, .purple, .cyan].randomElement()!
        } else {
            self.speed = Double.random(in: 0.8...1.6)
            self.size = CGFloat.random(in: 20...40)
            self.color = Color.white.opacity(Double.random(in: 0.1...0.4))
        }
    }
    
    var body: some View {
        Group {
            if type == .confetti {
                if Bool.random() {
                    Circle().fill(color)
                } else {
                    Rectangle().fill(color)
                }
            } else {
                Rectangle()
                    .fill(LinearGradient(
                        colors: [color.opacity(0), color],
                        startPoint: .top,
                        endPoint: .bottom
                    ))
                    .frame(width: 2, height: size)
            }
        }
        .frame(width: type == .confetti ? size : 2, height: size)
        .scaleEffect(type == .rain ? scale : 1.0)
        .position(position)
        .opacity(opacity)
        .rotationEffect(.degrees(rotation))
        .onAppear {
            configureAndAnimate()
        }
    }
    
    private func configureAndAnimate() {
        opacity = 1.0
        if type == .rain {
            scale = CGFloat.random(in: 0.5...1.0)
            rotation = 10
        }
        
        let safePadding: CGFloat = 100
        let minX = -safePadding
        let maxX = screenSize.width + safePadding
        
        let startX = Double.random(in: minX...maxX)
        let startY = Double.random(in: -200 ... -50)
        
        position = CGPoint(x: startX, y: startY)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            withAnimation(
                .linear(duration: speed)
                .repeatForever(autoreverses: false)
            ) {
                let endY = screenSize.height + 100
                let xOffset = type == .rain ? CGFloat(tan(10 * .pi / 180) * endY) : 0
                
                position.y = endY
                position.x += xOffset
                
                if type == .confetti {
                    rotation = Double.random(in: 0...360)
                }
            }
            
            if type == .confetti {
                withAnimation(
                    .easeInOut(duration: Double.random(in: 1...3))
                    .repeatForever(autoreverses: true)
                ) {
                    position.x += CGFloat.random(in: -30...30)
                }
            }
        }
    }
}
