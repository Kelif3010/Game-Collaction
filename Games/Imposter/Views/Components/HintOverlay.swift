//
//  HintOverlay.swift
//  Imposter
//
//  Created by Ken on 23.09.25.
//

import SwiftUI

/// Overlay für aktive Hinweise im Spiel
struct HintOverlay: View {
    @ObservedObject var hintService: HintService
    @ObservedObject private var settings = SettingsService.shared
    @State private var showHints = false
    @State private var animationOffset: CGFloat = -100
    
    var body: some View {
        VStack {
            Spacer()
            
            if !settings.enableHints {
                OverlayStatusBanner(text: "Hinweise deaktiviert", icon: "lightbulb.slash")
            } else if hintService.activeHints.isEmpty {
                OverlayStatusBanner(text: "Hinweise aktiv – warten auf Auslösung", icon: "clock")
            } else {
                Button(action: {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        showHints.toggle()
                        animationOffset = showHints ? 0 : -100
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "lightbulb.fill")
                            .font(.title2)
                        Text("\(hintService.activeHints.count) Hinweis\(hintService.activeHints.count == 1 ? "" : "e")")
                            .font(.headline)
                            .fontWeight(.bold)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(
                                LinearGradient(
                                    colors: [Color.orange, Color.orange.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .shadow(color: .orange.opacity(0.5), radius: 10)
                    )
                }
                .offset(y: animationOffset)
                .transition(.move(edge: .bottom))
            }
            
            // Hinweise-Liste (slide up)
            if showHints && settings.enableHints {
                HintListView(hints: hintService.activeHints)
                    .offset(y: animationOffset)
                    .transition(.move(edge: .bottom))
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 100)
    }
}

/// Liste der aktiven Hinweise
struct HintListView: View {
    let hints: [GameHint]
    @State private var selectedHint: GameHint?
    
    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Text("Aktive Hinweise")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(hints.count)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(10)
            }
            
            // Hinweis-Karten
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(hints) { hint in
                        HintCard(hint: hint) {
                            selectedHint = hint
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.orange.opacity(0.5), lineWidth: 1)
                )
        )
        .sheet(item: $selectedHint) { hint in
            HintDetailView(hint: hint)
        }
    }
}

struct OverlayStatusBanner: View {
    let text: String
    var icon: String = "lightbulb.slash"
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
            Text(text)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
        .foregroundColor(.white.opacity(0.7))
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.black.opacity(0.4))
        )
    }
}

/// Einzelne Hinweis-Karte
struct HintCard: View {
    let hint: GameHint
    let onTap: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                // Icon mit Wahrheits-Status
                ZStack {
                    Image(systemName: hint.type.icon)
                        .font(.title2)
                        .foregroundColor(.white)
                    
                    // Wahrheits-Indikator
                    Circle()
                        .fill(hint.isTrue ? Color.green : Color.red)
                        .frame(width: 12, height: 12)
                        .offset(x: 15, y: -15)
                }
                
                // Hinweis-Text (gekürzt)
                Text(hint.content)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .frame(width: 100)
                
                // Typ
                Text(hint.type.displayName)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(1)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(width: 120, height: 100)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(hint.isTrue ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(hint.isTrue ? Color.green : Color.red, lineWidth: 1)
                    )
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

/// Detail-Ansicht für einen Hinweis
struct HintDetailView: View {
    let hint: GameHint
    @Environment(\.dismiss) var dismiss
    @State private var isSpeaking = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Hintergrund
                LinearGradient(
                    colors: [
                        Color.black,
                        hint.isTrue ? Color.green.opacity(0.1) : Color.red.opacity(0.1),
                        Color.black
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    // Hinweis-Icon
                    ZStack {
                        Circle()
                            .fill(hint.isTrue ? Color.green.opacity(0.3) : Color.red.opacity(0.3))
                            .frame(width: 120, height: 120)
                        
                        Image(systemName: hint.type.icon)
                            .font(.system(size: 50))
                            .foregroundColor(.white)
                        
                        // Wahrheits-Indikator
                        Circle()
                            .fill(hint.isTrue ? Color.green : Color.red)
                            .frame(width: 20, height: 20)
                            .offset(x: 30, y: -30)
                    }
                    
                    // Hinweis-Info
                    VStack(spacing: 15) {
                        Text(hint.type.displayName)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text(hint.content)
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                        
                        // Wahrheits-Status
                        HStack {
                            Image(systemName: hint.isTrue ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(hint.isTrue ? .green : .red)
                            
                            Text(hint.isTrue ? "Echter Hinweis" : "Falscher Hinweis")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(hint.isTrue ? .green : .red)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(hint.isTrue ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                        )
                    }
                    
                    // Action Buttons
                    VStack(spacing: 15) {
                        Button(action: {
                            Task {
                                isSpeaking = true
                                await VoiceService.shared.speakHint(hint)
                                isSpeaking = false
                            }
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: isSpeaking ? "speaker.wave.2.fill" : "speaker.wave.2")
                                    .font(.title2)
                                Text(isSpeaking ? "Wird vorgelesen..." : "Vorlesen")
                                    .font(.headline)
                                    .fontWeight(.bold)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 30)
                            .padding(.vertical, 15)
                            .background(
                                RoundedRectangle(cornerRadius: 25)
                                    .fill(
                                        LinearGradient(
                                            colors: hint.isTrue ? [Color.green, Color.green.opacity(0.8)] : [Color.red, Color.red.opacity(0.8)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .shadow(color: hint.isTrue ? Color.green.opacity(0.5) : Color.red.opacity(0.5), radius: 15)
                            )
                        }
                        .disabled(isSpeaking)
                        
                        Button("Schließen") {
                            dismiss()
                        }
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.horizontal, 30)
                        .padding(.vertical, 15)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(Color.white.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 25)
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 40)
            }
            .navigationTitle("Hinweis Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Schließen") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
}

#Preview {
    HintOverlay(hintService: HintService.shared)
}
