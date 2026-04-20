//
//  TimerView.swift
//  TimesUp
//
//  Created by Ken on 23.09.25.
//

import SwiftUI

struct TimerView: View {
    @ObservedObject var gameManager: GameManager

    private var timeRemaining: Double {
        gameManager.gameState.turnTimeRemaining
    }

    private var timeLimit: Double {
        max(1, gameManager.gameState.settings.turnTimeLimit)
    }

    private var progress: Double {
        min(1, max(0, timeRemaining / timeLimit))
    }

    // Grün → Gelb → Orange → Rot je nach Restzeit
    private var ringColor: Color {
        if progress > 0.66 { return .green }
        if progress > 0.33 { return .yellow }
        if progress > 0.10 { return .orange }
        return .red
    }

    private var isCritical: Bool { timeRemaining <= 5 }

    private var activeBursts: [GameManager.TimerValueBurst] {
        guard let teamId = gameManager.gameState.currentTeam?.id else { return [] }
        return gameManager.timerValueBursts.filter { $0.teamId == teamId }
    }

    var body: some View {
        ZStack {
            // Hintergrund-Ring (Spur)
            Circle()
                .stroke(Color.white.opacity(0.1), lineWidth: 8)
                .frame(width: 160, height: 160)

            // Fortschritts-Ring: Grün → Gelb → Orange → Rot
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [
                            .green, .yellow, .orange, .red,
                            ringColor
                        ]),
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .frame(width: 160, height: 160)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1.0), value: progress)

            // Pulsierende Aura bei ≤5 Sekunden
            if isCritical {
                Circle()
                    .fill(ringColor.opacity(0.15))
                    .frame(width: 170, height: 170)
                    .scaleEffect(isCritical ? 1.05 : 1.0)
                    .animation(
                        .easeInOut(duration: 0.5).repeatForever(autoreverses: true),
                        value: isCritical
                    )
            }

            // Timer-Zahl
            Text(gameManager.formattedTimeRemaining)
                .font(.system(size: 64, weight: .bold, design: .rounded))
                .foregroundStyle(ringColor)
                .shadow(color: ringColor, radius: isCritical ? 16 : 8, x: 0, y: 0)
                .shadow(color: .white.opacity(0.4), radius: 2, x: 0, y: 1)
                .contentTransition(.numericText())
                .animation(.easeInOut(duration: 0.3), value: timeRemaining)

            TimerBurstLayer(bursts: activeBursts)
                .allowsHitTesting(false)
        }
        .frame(width: 160, height: 160)
        .padding(.vertical, 8)
    }
}

private struct TimerBurstLayer: View {
    let bursts: [GameManager.TimerValueBurst]

    var body: some View {
        ZStack {
            ForEach(bursts) { burst in
                TimerBurstLabel(burst: burst)
            }
        }
    }
}

private struct TimerBurstLabel: View {
    let burst: GameManager.TimerValueBurst
    @State private var animate = false

    var body: some View {
        Text(burst.text)
            .font(.system(size: 32, weight: .heavy, design: .rounded))
            .foregroundStyle(burst.isNegative ? .red : .green)
            .shadow(color: (burst.isNegative ? Color.red : Color.green).opacity(0.6), radius: 10, x: 0, y: 0)
            .scaleEffect(animate ? 1.15 : 0.8)
            .opacity(animate ? 0 : 1)
            .offset(y: animate ? -65 : 0)
            .onAppear {
                withAnimation(.easeOut(duration: 1.0)) {
                    animate = true
                }
            }
    }
}

#Preview {
    TimerView(gameManager: GameManager())
}
