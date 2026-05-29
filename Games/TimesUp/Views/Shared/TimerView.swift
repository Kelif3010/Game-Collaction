//
//  TimerView.swift
//  TimesUp
//
//  Created by Ken on 23.09.25.
//

import SwiftUI

struct TimerView: View {
    @ObservedObject var viewModel: TimesUpGameViewModel
    @State private var criticalPulse = false

    private var timeRemaining: Double {
        viewModel.gameState.turnTimeRemaining
    }

    private var timeLimit: Double {
        max(1, viewModel.gameState.settings.turnTimeLimit)
    }

    private var progress: Double {
        min(1, max(0, timeRemaining / timeLimit))
    }

    private var ringColor: Color {
        if progress > 0.66 { return .green }
        if progress > 0.33 { return .yellow }
        if progress > 0.10 { return .orange }
        return .red
    }

    private var isCritical: Bool {
        timeRemaining <= 5 && viewModel.gameState.phase == .playing
    }

    private var isFrozen: Bool {
        viewModel.isTimerFrozenForCurrentTeam()
    }

    private var isRushActive: Bool {
        viewModel.isSuddenRushActive(for: viewModel.gameState.currentTeam?.id)
    }

    private var isTimeBombActive: Bool {
        guard let teamId = viewModel.gameState.currentTeam?.id else { return false }
        return viewModel.activeTimeBombTimers[teamId] != nil
    }

    private var pressureColor: Color {
        if isFrozen { return .cyan }
        if isTimeBombActive { return .red }
        if isRushActive { return .orange }
        return ringColor
    }

    private var pressureGradient: AngularGradient {
        AngularGradient(
            colors: [
                pressureColor.opacity(0.25),
                pressureColor,
                Color.white.opacity(0.95),
                pressureColor,
                pressureColor.opacity(0.45)
            ],
            center: .center,
            startAngle: .degrees(-90),
            endAngle: .degrees(270)
        )
    }

    private var activeBursts: [TimesUpGameViewModel.TimerValueBurst] {
        guard let teamId = viewModel.gameState.currentTeam?.id else { return [] }
        return viewModel.timerValueBursts.filter { $0.teamId == teamId }
    }

    private var displayTime: String {
        if timeRemaining < 100 {
            return "\(Int(ceil(timeRemaining)))"
        }
        return viewModel.formattedTimeRemaining
    }

    var body: some View {
        ZStack {
            if isCritical {
                Circle()
                    .fill(Color.red.opacity(0.16))
                    .frame(width: 218, height: 218)
                    .blur(radius: 9)
                    .scaleEffect(criticalPulse ? 1.08 : 0.96)
                    .opacity(criticalPulse ? 0.28 : 0.75)
            }

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.black.opacity(0.80),
                            Color.black.opacity(0.45),
                            Color.cyan.opacity(0.08)
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: 102
                    )
                )
                .frame(width: 204, height: 204)
                .shadow(color: Color.cyan.opacity(isCritical ? 0.42 : 0.22), radius: isCritical ? 34 : 22, x: 0, y: 0)

            Circle()
                .stroke(Color.white.opacity(0.055), lineWidth: 12)
                .frame(width: 188, height: 188)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    isCritical ? Color.red : Color.cyan,
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .frame(width: 188, height: 188)
                .rotationEffect(.degrees(-90))
                .shadow(color: (isCritical ? Color.red : Color.cyan).opacity(isCritical ? 0.80 : 0.62), radius: isCritical ? 20 : 16, x: 0, y: 0)
                .animation(.linear(duration: isRushActive ? 0.35 : 0.85), value: progress)

            Text(displayTime)
                    .font(.system(size: displayTime.count <= 2 ? 64 : 42, weight: .heavy, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(Color(red: 0.90, green: 0.88, blue: 0.90))
                    .shadow(color: Color.white.opacity(0.32), radius: 18, x: 0, y: 0)
                    .contentTransition(.numericText())
                    .scaleEffect(isCritical && criticalPulse ? 1.06 : 1)
                    .animation(.easeInOut(duration: 0.22), value: timeRemaining)

            TimerBurstLayer(bursts: activeBursts)
                .allowsHitTesting(false)
        }
        .frame(width: 216, height: 216)
        .padding(.vertical, 4)
        .onAppear { updateCriticalPulse() }
        .onChange(of: isCritical) { _, _ in updateCriticalPulse() }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Timer \(viewModel.formattedTimeRemaining)")
    }

    private var timerCaption: String {
        if isFrozen { return "Freeze" }
        if isTimeBombActive { return "Time Bomb" }
        if isRushActive { return "Rush" }
        if isCritical { return "Endspurt" }
        return "Timer"
    }

    private func updateCriticalPulse() {
        if isCritical {
            criticalPulse = false
            withAnimation(.easeInOut(duration: 0.55).repeatForever(autoreverses: true)) {
                criticalPulse = true
            }
        } else {
            criticalPulse = false
        }
    }
}

private struct PressureRingTickMarks: View {
    let progress: Double
    let color: Color
    let isCritical: Bool

    var body: some View {
        ZStack {
            ForEach(0..<40, id: \.self) { index in
                let threshold = Double(index + 1) / 40.0
                let isActive = threshold <= progress
                Capsule()
                    .fill(isActive ? color.opacity(isCritical ? 0.95 : 0.72) : Color.white.opacity(0.13))
                    .frame(width: index.isMultiple(of: 5) ? 3 : 2, height: index.isMultiple(of: 5) ? 12 : 7)
                    .offset(y: -91)
                    .rotationEffect(.degrees(Double(index) * 9))
            }
        }
    }
}

private struct TimerStatusBadges: View {
    let isFrozen: Bool
    let isTimeBombActive: Bool
    let isRushActive: Bool

    var body: some View {
        ZStack {
            if isFrozen {
                TimerEffectBadge(icon: "snowflake", color: .cyan)
                    .offset(x: -70, y: -68)
            }
            if isTimeBombActive {
                TimerEffectBadge(icon: "flame.fill", color: .red)
                    .offset(x: 70, y: -68)
            }
            if isRushActive {
                TimerEffectBadge(icon: "bolt.fill", color: .orange)
                    .offset(x: 0, y: 86)
            }
        }
    }
}

private struct TimerEffectBadge: View {
    let icon: String
    let color: Color

    var body: some View {
        Image(systemName: icon)
            .font(.system(size: 13, weight: .heavy))
            .foregroundStyle(.white)
            .frame(width: 30, height: 30)
            .background(
                Circle()
                    .fill(color.opacity(0.95))
                    .shadow(color: color.opacity(0.65), radius: 8, x: 0, y: 0)
            )
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(0.35), lineWidth: 1)
            )
    }
}

private struct TimerBurstLayer: View {
    let bursts: [TimesUpGameViewModel.TimerValueBurst]

    var body: some View {
        ZStack {
            ForEach(bursts) { burst in
                TimerBurstLabel(burst: burst)
            }
        }
    }
}

private struct TimerBurstLabel: View {
    let burst: TimesUpGameViewModel.TimerValueBurst
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
    TimerView(viewModel: TimesUpGameViewModel())
}
