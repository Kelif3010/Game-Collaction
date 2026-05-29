//
//  DrawingPhaseViews.swift
//  TimesUp
//
//  Created by Ken  on 24.09.25.
//

import SwiftUI

// MARK: - Term Reveal Phase (Wort anzeigen)

struct DrawingTermRevealView: View {
    @ObservedObject var viewModel: TimesUpGameViewModel
    let onStartDrawing: () -> Void
    
    init(viewModel: TimesUpGameViewModel, onStartDrawing: @escaping () -> Void) {
        self._viewModel = ObservedObject(wrappedValue: viewModel)
        self.onStartDrawing = onStartDrawing
    }
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
                .frame(height: 60)
            
            // Term Display Banner
            if let term = viewModel.gameState.currentTerm {
                ZStack {
                    RoundedRectangle(cornerRadius: 25)
                        .fill(Color(.systemBackground).opacity(0.95))
                        .overlay(
                            RoundedRectangle(cornerRadius: 25)
                                .stroke(
                                    LinearGradient(colors: [.green, .blue], startPoint: .leading, endPoint: .trailing), 
                                    lineWidth: 3
                                )
                        )
                        .shadow(color: .green.opacity(0.4), radius: 20, x: 0, y: 8)
                    
                    VStack(spacing: 15) {
                        Text(LocalizedStringKey("Zeichne diesen Begriff:"))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fontWeight(.medium)
                        
                        PerkWordText(
                            viewModel: viewModel,
                            term: term,
                            font: .system(size: 36, weight: .bold),
                            weight: .bold,
                            alignment: .center,
                            color: .primary
                        )
                        .foregroundStyle(
                            LinearGradient(colors: [.green, .blue], startPoint: .leading, endPoint: .trailing)
                        )
                        
                        // Begriffe übrig Badge
                        HStack {
                            Image(systemName: "paintbrush.pointed")
                                .foregroundStyle(.orange)
                            let remainingLabel = String(localized: "Begriffe übrig")
                            Text("\(viewModel.gameState.remainingTermsCount) \(remainingLabel)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(.orange)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.orange.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                    }
                    .padding(.horizontal, 30)
                    .padding(.vertical, 25)
                }
                .padding(.horizontal, 20)
            }
            
            Spacer()
            
            // Los geht's Button
            Button(action: {
                onStartDrawing()
                // Timer erst jetzt starten!
                viewModel.startDrawingTimer()
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "pencil")
                        .font(.title2)
                    Text(LocalizedStringKey("Los geht's - Zeichnen!"))
                        .font(.title2)
                        .fontWeight(.bold)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .background(
                    LinearGradient(
                        colors: [.green, .blue],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 30))
                .shadow(color: .green.opacity(0.4), radius: 15, x: 0, y: 8)
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 30)
        }
    }
}

// MARK: - Active Drawing Phase (Zeichnen)

struct DrawingActiveView: View {
    @ObservedObject var drawingViewModel: DrawingViewModel
    @ObservedObject var viewModel: TimesUpGameViewModel
    let onCorrectGuess: () -> Void
    let onSkip: () -> Void
    let onWrongGuess: () -> Void
    // Preview override to force showing the Skip button without needing game state
    var previewCanSkipOverride: Bool? = nil
    
    init(
        drawingViewModel: DrawingViewModel,
        viewModel: TimesUpGameViewModel,
        onCorrectGuess: @escaping () -> Void,
        onSkip: @escaping () -> Void,
        onWrongGuess: @escaping () -> Void,
        previewCanSkipOverride: Bool? = nil
    ) {
        self._drawingViewModel = ObservedObject(wrappedValue: drawingViewModel)
        self._viewModel = ObservedObject(wrappedValue: viewModel)
        self.onCorrectGuess = onCorrectGuess
        self.onSkip = onSkip
        self.onWrongGuess = onWrongGuess
        self.previewCanSkipOverride = previewCanSkipOverride
    }
    
    var body: some View {
        let canSkip = previewCanSkipOverride ?? viewModel.gameState.currentRound.canSkip
        let isHardMode = viewModel.gameState.settings.difficulty == .hard
        let forcedSkipActive = viewModel.isForcedSkipActiveForCurrentTeam()
        
        return VStack(spacing: 0) {
            // Kompakte Drawing Tools (ganz oben)
            CompactDrawingToolsView(drawingViewModel: drawingViewModel)
                .padding(.horizontal, 15)
                .padding(.top, 5)
                .padding(.bottom, 10)
            
            // Große Drawing Canvas (MAXIMALER Platz!)
            DrawingCanvasView(drawingViewModel: drawingViewModel)
                .clipShape(RoundedRectangle(cornerRadius: 15))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                .padding(.horizontal, 15)
                .clipped()
            
            Spacer(minLength: 15)
            
            // Action Buttons (unten)
            HStack(spacing: 30) {
                // Skip Button
                if canSkip {
                    let skipFrozen = viewModel.isSkipButtonFrozenForCurrentTeam()
                    Button(action: onSkip) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.right")
                                .font(.title3)
                            Text(LocalizedStringKey("Skip"))
                                .font(.headline)
                                .fontWeight(.bold)
                        }
                        .foregroundStyle(.white)
                        .frame(width: 100, height: 50)
                        .background(
                            LinearGradient(colors: [.blue, .blue.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 25))
                        .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                        .overlay(alignment: .topTrailing) {
                            if skipFrozen {
                                Image(systemName: "lock.fill")
                                    .font(.caption2)
                                    .foregroundStyle(.white)
                                    .padding(4)
                                    .background(Color.black.opacity(0.4))
                                    .clipShape(Circle())
                                    .offset(x: 10, y: -10)
                            }
                        }
                    }
                    .disabled(skipFrozen)
                    
                    if isHardMode && !forcedSkipActive {
                        Button(action: onWrongGuess) {
                            HStack(spacing: 8) {
                                Image(systemName: "xmark")
                                    .font(.title3)
                                Text(LocalizedStringKey("Falsch"))
                                    .font(.headline)
                                    .fontWeight(.bold)
                            }
                            .foregroundStyle(.white)
                            .frame(width: 140, height: 50)
                            .background(
                                LinearGradient(colors: [.red, .red.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 25))
                            .shadow(color: .red.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                    }
                }
                
                // Correct Button
                if forcedSkipActive {
                    Text(LocalizedStringKey("Zwangs-Skip aktiv – erst Skip drücken."))
                        .font(.footnote)
                        .foregroundStyle(.yellow)
                } else {
                    Button(action: onCorrectGuess) {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark")
                                .font(.title3)
                            Text(LocalizedStringKey("Richtig!"))
                                .font(.headline)
                                .fontWeight(.bold)
                        }
                        .foregroundStyle(.white)
                        .frame(width: 120, height: 50)
                        .background(
                            LinearGradient(colors: [.green, .green.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 25))
                        .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, -10)
        }
    }
}

// MARK: - Guessed Phase (Begriff erraten)

struct DrawingGuessedView: View {
    @ObservedObject var viewModel: TimesUpGameViewModel
    let onContinue: () -> Void
    
    init(viewModel: TimesUpGameViewModel, onContinue: @escaping () -> Void) {
        self._viewModel = ObservedObject(wrappedValue: viewModel)
        self.onContinue = onContinue
    }
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Success Message
            VStack(spacing: 20) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(
                        LinearGradient(colors: [.green, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .shadow(color: .green.opacity(0.4), radius: 15, x: 0, y: 5)
                
                Text(LocalizedStringKey("Richtig erraten!"))
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(colors: [.green, .blue], startPoint: .leading, endPoint: .trailing)
                    )
            }
            
            // Term Display
            if let term = viewModel.gameState.currentTerm {
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(.systemBackground).opacity(0.95))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(
                                    LinearGradient(colors: [.green, .blue], startPoint: .leading, endPoint: .trailing),
                                    lineWidth: 2
                                )
                        )
                        .shadow(color: .green.opacity(0.3), radius: 15, x: 0, y: 5)
                    
                    VStack(spacing: 12) {
                        Text(LocalizedStringKey("Der Begriff war:"))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fontWeight(.medium)
                        
                        PerkWordText(
                            viewModel: viewModel,
                            term: term,
                            font: .system(size: 28, weight: .bold),
                            weight: .bold,
                            alignment: .center,
                            color: .primary
                        )
                    }
                    .padding(.horizontal, 25)
                    .padding(.vertical, 20)
                }
                .padding(.horizontal, 30)
            }
            
            Spacer()
            
            // Continue Button
            Button(action: onContinue) {
                HStack(spacing: 12) {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.title2)
                    Text(LocalizedStringKey("Bereit für nächsten Begriff"))
                        .font(.title2)
                        .fontWeight(.bold)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .background(
                    LinearGradient(colors: [.green, .blue], startPoint: .leading, endPoint: .trailing)
                )
                .clipShape(RoundedRectangle(cornerRadius: 30))
                .shadow(color: .green.opacity(0.4), radius: 15, x: 0, y: 8)
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 30)
        }
    }
}

#if DEBUG
struct DrawingPhaseViews_Previews: PreviewProvider {
    static var previews: some View {
        let revealManager = TimesUpGameViewModel()
        let activeManager = TimesUpGameViewModel()
        let activeDrawingViewModel = DrawingViewModel()
        let stackedManager = TimesUpGameViewModel()
        let stackedDrawingViewModel = DrawingViewModel()
        
        return Group {
            DrawingTermRevealView(viewModel: revealManager) {
                print("Start Drawing")
            }
            .padding()
            .previewDisplayName("Reveal")
            
            DrawingActiveView(
                drawingViewModel: activeDrawingViewModel,
                viewModel: activeManager,
                onCorrectGuess: { print("Correct") },
                onSkip: { print("Skip") },
                onWrongGuess: { print("Wrong") },
                previewCanSkipOverride: true
            )
            .padding()
            .previewDisplayName("Active")
            
            DrawingGuessedView(viewModel: TimesUpGameViewModel(), onContinue: { print("Continue") })
                .padding()
                .previewDisplayName("Guessed")
            
            ScrollView {
                VStack(spacing: 30) {
                    DrawingTermRevealView(viewModel: TimesUpGameViewModel()) {
                        print("Start Drawing")
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    
                    DrawingActiveView(
                        drawingViewModel: stackedDrawingViewModel,
                        viewModel: stackedManager,
                        onCorrectGuess: { print("Correct") },
                        onSkip: { print("Skip") },
                        onWrongGuess: { print("Wrong") },
                        previewCanSkipOverride: true
                    )
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    
                    DrawingGuessedView(viewModel: TimesUpGameViewModel(), onContinue: { print("Continue") })
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding()
            }
            .previewDisplayName("All")
        }
    }
}
#endif
