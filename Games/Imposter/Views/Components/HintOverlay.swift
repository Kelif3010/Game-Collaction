//
//  HintOverlay.swift
//  Imposter
//
//  Created by Ken on 23.09.25.
//

import SwiftUI

/// Overlay für aktive Hinweise im Spiel - Jetzt oben platziert und neutral gestaltet
struct HintOverlay: View {
    @ObservedObject var hintService: HintService
    @ObservedObject private var settings = SettingsService.shared
    @State private var showHistory = false
    
    var body: some View {
        VStack {
            // Nur anzeigen, wenn Hinweise aktiviert sind
            if settings.enableHints {
                if let latestHint = hintService.activeHints.last {
                    // Neuester Hinweis als kompakte "Notification" oben
                    CompactHintPill(hint: latestHint)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .onTapGesture {
                            showHistory = true
                        }
                }
            }
            Spacer()
        }
        .padding(.top, 120) // Mehr Platz für Timer/Header
        .padding(.horizontal, 20)
        .sheet(isPresented: $showHistory) {
            HintHistoryView(hints: hintService.hintHistory)
        }
    }
}

/// Kompakte Anzeige des neuesten Hinweises
struct CompactHintPill: View {
    let hint: GameHint
    @State private var pulse = false
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: hint.type.icon)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.orange)
                .overlay(
                    Circle()
                        .stroke(Color.orange, lineWidth: 2)
                        .scaleEffect(pulse ? 1.5 : 1.0)
                        .opacity(pulse ? 0 : 0.5)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(hint.type.displayName.uppercased())
                    .font(.system(size: 10, weight: .black))
                    .foregroundColor(.orange.opacity(0.8))
                
                Text(hint.content)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.white)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption.bold())
                .foregroundColor(.white.opacity(0.3))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            ZStack {
                BlurView(style: .systemUltraThinMaterialDark)
                Color.black.opacity(0.4)
            }
        )
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.3), radius: 10, y: 5)
        .onAppear {
            withAnimation(.easeOut(duration: 1.5).repeatForever(autoreverses: false)) {
                pulse = true
            }
        }
    }
}

/// Verlauf aller bisherigen Hinweise (Neutral gestaltet)
struct HintHistoryView: View {
    let hints: [GameHint]
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                ImposterStyle.backgroundGradient.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        if hints.isEmpty {
                            Text("Noch keine Funksprüche empfangen.")
                                .foregroundColor(.white.opacity(0.4))
                                .padding(.top, 100)
                        } else {
                            ForEach(hints.reversed()) { hint in
                                NeutralHintRow(hint: hint)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("MISSIONSLOG")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Schließen") { dismiss() }
                        .foregroundColor(.orange)
                }
            }
        }
    }
}

/// Neutrale Zeile für den Verlauf (keine isTrue Info!)
struct NeutralHintRow: View {
    let hint: GameHint
    
    var body: some View {
        HStack(spacing: 15) {
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.1))
                    .frame(width: 40, height: 40)
                Image(systemName: hint.type.icon)
                    .foregroundColor(.orange)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(hint.type.displayName)
                    .font(.caption.bold())
                    .foregroundColor(.orange.opacity(0.7))
                
                Text(hint.content)
                    .font(.body)
                    .foregroundColor(.white)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

// Hilfskonstrukt für Blur
struct BlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}

#Preview {
    HintOverlay(hintService: HintService.shared)
}
