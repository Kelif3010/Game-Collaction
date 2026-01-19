//
//  TVRootView.swift
//  Games Collection
//
//  Created by Gemini on 17.01.2026.
//

import SwiftUI

struct TVRootView: View {
    @EnvironmentObject var displayManager: ExternalDisplayManager
    
    var body: some View {
        GeometryReader { proxy in
            let scale = TVScaleCalculator.scale(for: proxy.size)
            ZStack {
                if let questionsVM = displayManager.activeQuestionsViewModel {
                    QuestionsTVBoardView(viewModel: questionsVM)
                        .transition(.opacity)
                } else {
                    defaultDashboard(scale: scale)
                        .transition(.opacity)
                }
            }
            .environment(\.tvScale, scale)
            .frame(width: proxy.size.width, height: proxy.size.height)
            .animation(.easeInOut, value: displayManager.activeQuestionsViewModel != nil)
        }
    }
    
    private func defaultDashboard(scale: CGFloat) -> some View {
        ZStack {
            // Hintergrund-Gradient (Passend zur App)
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.15),
                    Color(red: 0.1, green: 0.1, blue: 0.2)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Subtiles Pattern
            Image(systemName: "circle.grid.3x3.fill")
                .resizable()
                .scaledToFill()
                .opacity(0.02)
                .ignoresSafeArea()
            
            VStack(spacing: scaled(40, by: scale)) {
                // App Logo / Titel
                VStack(spacing: scaled(10, by: scale)) {
                    Image(systemName: "gamecontroller.fill")
                        .font(.system(size: scaled(100, by: scale)))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.orange, .red],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: .red.opacity(0.5), radius: scaled(20, by: scale))
                    
                    Text("GAMES COLLECTION")
                        .font(.system(size: scaled(60, by: scale), weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .tracking(scaled(5, by: scale))
                }
                
                // Status Info
                HStack(spacing: scaled(15, by: scale)) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: scaled(12, by: scale), height: scaled(12, by: scale))
                        .opacity(pulseOpacity)
                        .animation(.easeInOut(duration: 1.0).repeatForever(), value: pulseOpacity)
                    
                    Text("BEREIT FÜR DAS NÄCHSTE SPIEL")
                        .font(.system(size: scaled(24, by: scale), weight: .bold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.horizontal, scaled(30, by: scale))
                .padding(.vertical, scaled(15, by: scale))
                .background(Color.white.opacity(0.05))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color.white.opacity(0.1), lineWidth: scaled(1, by: scale)))
            }
        }
    }
    
    @State private var pulseOpacity: Double = 1.0

    private func scaled(_ value: CGFloat, by scale: CGFloat) -> CGFloat {
        value * scale
    }
}

#Preview {
    TVRootView()
        .environmentObject(ExternalDisplayManager.shared)
}
