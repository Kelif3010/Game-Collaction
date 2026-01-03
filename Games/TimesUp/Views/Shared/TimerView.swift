//
//  TimerView.swift
//  TimesUp
//
//  Created by Ken on 23.09.25.
//

import SwiftUI

struct TimerView: View {
    @ObservedObject var gameManager: GameManager
    
    private var activeBursts: [GameManager.TimerValueBurst] {
        guard let teamId = gameManager.gameState.currentTeam?.id else { return [] }
        return gameManager.timerValueBursts.filter { $0.teamId == teamId }
    }
    
    var body: some View {
        ZStack {
            Text(gameManager.formattedTimeRemaining)
                .font(.system(size: 72, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: gameManager.gameState.turnTimeRemaining < 10 ?
                            [.red, .pink] : [.blue, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .shadow(color: gameManager.gameState.turnTimeRemaining < 10 ? .red : .blue, radius: 20, x: 0, y: 0)
                .shadow(color: .white.opacity(0.5), radius: 2, x: 0, y: 1)
                .animation(.easeInOut(duration: 0.2), value: gameManager.gameState.turnTimeRemaining)
            
            TimerBurstLayer(bursts: activeBursts)
                .allowsHitTesting(false)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .overlay(alignment: .top) {
            if let toast = gameManager.perkToast {
                PerkToastView(toast: toast)
                    .offset(y: -70)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(1)
            }
        }
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
            .foregroundColor(burst.isNegative ? .red : .green)
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
