//
//  DrawingGameControlsView.swift
//  TimesUp
//
//  Created by Ken  on 24.09.25.
//

import SwiftUI

// MARK: - Drawing Game Controls

struct DrawingGameControlsView: View {
    @ObservedObject var gameManager: GameManager
    @ObservedObject var drawingState: DrawingState
    
    var body: some View {
        let forcedSkipActive = gameManager.isForcedSkipActiveForCurrentTeam()
        VStack(spacing: 15) {
            // Current Term Display
            if let term = gameManager.gameState.currentTerm {
                TermDisplayBanner(gameManager: gameManager, term: term, remainingCount: gameManager.gameState.remainingTermsCount)
            }
            
            // Action Buttons (Skip & Correct - wie gewohnt)
            HStack(spacing: 30) {
                // Skip Button (gleich wie in anderen Runden)
                if gameManager.gameState.currentRound.canSkip {
                    let skipFrozen = gameManager.isSkipButtonFrozenForCurrentTeam()
                    Button(action: {
                        // Drawing automatisch für nächsten Begriff löschen
                        drawingState.resetForNewTerm()
                        gameManager.skipTerm()
                    }) {
                        VStack(spacing: 8) {
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.system(size: 40))
                            Text(LocalizedStringKey("Skip"))
                                .font(.headline)
                                .fontWeight(.bold)
                        }
                        .foregroundColor(.white)
                        .frame(width: 120, height: 120)
                        .background(
                            LinearGradient(
                                colors: [.blue, .blue.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(Circle())
                        .shadow(color: .blue.opacity(0.4), radius: 8, x: 0, y: 4)
                        .scaleEffect(1.0)
                        .animation(.easeInOut(duration: 0.1), value: gameManager.gameState.phase)
                        .overlay(alignment: .topTrailing) {
                            if skipFrozen {
                                Image(systemName: "lock.fill")
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .padding(4)
                                    .background(Color.black.opacity(0.45))
                                    .clipShape(Circle())
                                    .offset(x: 12, y: -12)
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(skipFrozen)
                    
                    if gameManager.gameState.settings.difficulty == .hard && !forcedSkipActive {
                        Button(action: {
                            drawingState.resetForNewTerm()
                            gameManager.wrongGuess()
                        }) {
                            VStack(spacing: 8) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 40))
                                Text(LocalizedStringKey("Falsch"))
                                    .font(.headline)
                                    .fontWeight(.bold)
                            }
                            .foregroundColor(.white)
                            .frame(width: 120, height: 120)
                            .background(
                                LinearGradient(
                                    colors: [.red, .red.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(Circle())
                            .shadow(color: .red.opacity(0.4), radius: 8, x: 0, y: 4)
                            .scaleEffect(1.0)
                            .animation(.easeInOut(duration: 0.1), value: gameManager.gameState.phase)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                // Correct Button (gleich wie in anderen Runden)
                if forcedSkipActive {
                    Text(LocalizedStringKey("Zwangs-Skip aktiv – erst Skip ausführen."))
                        .font(.footnote)
                        .foregroundColor(.yellow)
                } else {
                    Button(action: {
                        // Drawing automatisch für nächsten Begriff löschen
                        drawingState.resetForNewTerm()
                        gameManager.correctGuess()
                    }) {
                        VStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 40))
                            Text(LocalizedStringKey("Richtig"))
                                .font(.headline)
                                .fontWeight(.bold)
                        }
                        .foregroundColor(.white)
                        .frame(width: 120, height: 120)
                        .background(
                            LinearGradient(
                                colors: [.green, .green.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(Circle())
                        .shadow(color: .green.opacity(0.4), radius: 8, x: 0, y: 4)
                        .scaleEffect(1.0)
                        .animation(.easeInOut(duration: 0.1), value: gameManager.gameState.phase)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
}

// MARK: - Term Display Banner for Drawing

struct TermDisplayBanner: View {
    @ObservedObject var gameManager: GameManager
    let term: Term
    let remainingCount: Int
    
    var body: some View {
        ZStack {
            // Dunkles Banner mit Neon-Rand (passend zum GameView Design)
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground).opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(colors: [.green, .blue], startPoint: .leading, endPoint: .trailing), 
                            lineWidth: 2
                        )
                )
                .shadow(color: .green.opacity(0.3), radius: 15, x: 0, y: 5)
            
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(LocalizedStringKey("Zeichne:"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fontWeight(.medium)
                    
                    PerkWordText(
                        gameManager: gameManager,
                        term: term,
                        font: .system(size: 24, weight: .bold),
                        weight: .bold,
                        alignment: .leading,
                        lineLimit: 2,
                        color: .primary
                    )
                }
                
                Spacer()
                
                // Begriff-Counter Badge (wie in anderen Runden)
                VStack(spacing: 4) {
                    Text(LocalizedStringKey("Übrig"))
                        .font(.caption2)
                        .foregroundColor(.white)
                    
                    Text("\(remainingCount)")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                .frame(width: 50, height: 50)
                .background(
                    LinearGradient(
                        colors: [.orange, .red],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(Circle())
                .shadow(color: .orange.opacity(0.6), radius: 10, x: 0, y: 0)
            }
            .padding(.horizontal, 25)
            .padding(.vertical, 15)
        }
        .frame(height: 70)
    }
}

#Preview("Banner") {
    TermDisplayBanner(
        gameManager: GameManager(),
        term: Term(text: "Eiffelturm"),
        remainingCount: 23
    )
    .padding()
}
