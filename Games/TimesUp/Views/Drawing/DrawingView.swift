//
//  DrawingView.swift
//  TimesUp
//
//  Created by Ken  on 24.09.25.
//

import SwiftUI

// MARK: - Drawing Phases

enum DrawingPhase {
    case showingTerm    // Wort wird angezeigt
    case drawing       // User zeichnet (Wort versteckt)
}

// MARK: - Main Drawing View

struct DrawingView: View {
    @StateObject private var drawingState = DrawingState()
    @ObservedObject var gameManager: GameManager
    @State private var drawingPhase: DrawingPhase = .showingTerm
    
    var body: some View {
        ZStack {
            // Dunkler Hintergrund (konsistent mit anderen Views)
            LinearGradient(
                colors: [
                    Color.black,
                    Color(.systemGray6).opacity(0.3),
                    Color.green.opacity(0.15),
                    Color.blue.opacity(0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                switch drawingPhase {
                case .showingTerm:
                    DrawingTermRevealView(
                        gameManager: gameManager,
                        onStartDrawing: {
                            drawingPhase = .drawing
                            drawingState.resetForNewTerm()
                        }
                    )
                    
                case .drawing:
                    DrawingActiveView(
                        drawingState: drawingState,
                        gameManager: gameManager,
                        onCorrectGuess: {
                            // Direkt zum nächsten Begriff springen, ohne Zwischenbildschirm
                            gameManager.correctGuess()
                            drawingState.resetForNewTerm()
                            drawingPhase = .showingTerm
                        },
                        onSkip: {
                            drawingPhase = .showingTerm
                            gameManager.skipTerm()
                        },
                        onWrongGuess: {
                            drawingPhase = .showingTerm
                            gameManager.wrongGuess()
                        }
                    )
                    
                }
            }
        }
        .onAppear {
            drawingPhase = .showingTerm
        }
    }
}

// MARK: - Drawing Tools Header

struct DrawingToolsView: View {
    @ObservedObject var drawingState: DrawingState
    
    var body: some View {
        VStack(spacing: 15) {
            // Tool Selection (Stift/Radiergummi)
            HStack(spacing: 20) {
                ForEach(DrawingTool.allCases) { tool in
                    Button(action: {
                        drawingState.selectTool(tool)
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: tool.systemImage)
                                .font(.title3)
                            Text(tool.name)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(drawingState.selectedTool == tool ? .white : tool.color)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            drawingState.selectedTool == tool ?
                                LinearGradient(colors: [tool.color, tool.color.opacity(0.8)], startPoint: .leading, endPoint: .trailing) :
                                LinearGradient(colors: [Color.gray.opacity(0.1)], startPoint: .leading, endPoint: .trailing)
                        )
                        .cornerRadius(20)
                        .shadow(color: drawingState.selectedTool == tool ? tool.color.opacity(0.3) : .clear, radius: 5, x: 0, y: 2)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .scaleEffect(drawingState.selectedTool == tool ? 1.05 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: drawingState.selectedTool)
                }
                
                Spacer()
                
                // Clear & Undo Buttons
                HStack(spacing: 12) {
                    // Undo Button
                    Button(action: {
                        drawingState.undoLastStroke()
                    }) {
                        Image(systemName: "arrow.uturn.backward")
                            .font(.title3)
                            .foregroundColor(.orange)
                            .frame(width: 44, height: 44)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(22)
                    }
                    .disabled(drawingState.strokes.isEmpty)
                    .opacity(drawingState.strokes.isEmpty ? 0.5 : 1.0)
                    
                    // Clear Button
                    Button(action: {
                        drawingState.clearDrawing()
                    }) {
                        Image(systemName: "trash")
                            .font(.title3)
                            .foregroundColor(.red)
                            .frame(width: 44, height: 44)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(22)
                    }
                    .disabled(drawingState.isEmpty)
                    .opacity(drawingState.isEmpty ? 0.5 : 1.0)
                }
            }
            
            // Color Palette (nur für Stift sichtbar)
            if drawingState.selectedTool == .pen {
                DrawingColorPalette(drawingState: drawingState)
            }
            
            // Line Width Selector
            DrawingLineWidthSelector(drawingState: drawingState)
        }
        .padding(.vertical, 15)
        .background(Color(.systemGray6).opacity(0.8))
        .cornerRadius(20)
        .shadow(color: .primary.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Preview

#Preview {
    DrawingView(gameManager: GameManager())
}
