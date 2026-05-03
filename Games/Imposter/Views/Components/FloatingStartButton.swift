//
//  FloatingStartButton.swift
//  Imposter
//
//  Created by Ken on 22.09.25.
//

import SwiftUI

struct FloatingStartButton: View {
    @Environment(GameSettings.self) var gameSettings
    @Environment(GameLogic.self) var gameLogic
    let canStart: Bool
    let hintText: String
    let onStart: () -> Void
    
    @State private var showingHint = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack {
            Spacer()
            
            VStack(spacing: 8) {
                // Hint Text (bei ausgegrautem Button)
                if !canStart && showingHint {
                    Text(hintText)
                        .font(.caption)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.black.opacity(0.8))
                        )
                        .transition(.opacity.combined(with: .scale))
                }
                
                // Main Floating Button
                if canStart {
                    NavigationLink(destination: GamePlayView()
                        .environment(gameSettings)
                        .environment(gameLogic)) {
                        FloatingButtonContent(
                            title: "Spiel starten",
                            icon: "play.circle.fill",
                            isEnabled: true
                        )
                    }
                    .simultaneousGesture(TapGesture().onEnded {
                        onStart()
                    })
                } else {
                    Button(action: {
                        // Hint anzeigen/verstecken
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showingHint.toggle()
                        }
                        
                        // Hint automatisch nach 3 Sekunden verstecken
                        if showingHint {
                            Task { @MainActor in
                                try? await Task.sleep(for: .seconds(3))
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showingHint = false
                                }
                            }
                        }
                    }) {
                        FloatingButtonContent(
                            title: "Spiel starten",
                            icon: "play.circle.fill",
                            isEnabled: false
                        )
                    }
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Floating Button Content
struct FloatingButtonContent: View {
    let title: String
    let icon: String
    let isEnabled: Bool

    @ViewBuilder
    private var label: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.white)
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }

    var body: some View {
        Group {
            if #available(iOS 26, *) {
                label
                    .glassEffect(
                        isEnabled
                            ? Glass.regular.tint(.orange).interactive()
                            : Glass.regular.tint(.gray),
                        in: Capsule()
                    )
            } else {
                label
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(
                                LinearGradient(
                                    colors: isEnabled
                                        ? [Color.orange, Color.red]
                                        : [Color.gray, Color.gray.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .shadow(
                                color: .black.opacity(isEnabled ? 0.4 : 0.2),
                                radius: 8, x: 0, y: 4
                            )
                    )
            }
        }
        .scaleEffect(isEnabled ? 1.0 : 0.95)
        .animation(.easeInOut(duration: 0.2), value: isEnabled)
    }
}

#Preview {
    let settings = GameSettings()
    let logic = GameLogic(gameSettings: settings)
    VStack(spacing: 50) {
        FloatingStartButton(
            canStart: true,
            hintText: "Bereit zum Starten!",
            onStart: { print("Starting game!") }
        )
        
        FloatingStartButton(
            canStart: false,
            hintText: "Noch 2 Spieler benötigt • Kategorie wählen",
            onStart: { print("Cannot start yet") }
        )
    }
    .environment(settings)
    .environment(logic)
    .padding(40)
    .background(
        LinearGradient(
            colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
}
