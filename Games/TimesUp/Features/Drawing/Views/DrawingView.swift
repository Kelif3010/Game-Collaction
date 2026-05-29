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
    @StateObject private var drawingViewModel = DrawingViewModel()
    @ObservedObject var viewModel: TimesUpGameViewModel
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
                        viewModel: viewModel,
                        onStartDrawing: {
                            drawingPhase = .drawing
                            drawingViewModel.resetForNewTerm()
                        }
                    )
                    
                case .drawing:
                    DrawingActiveView(
                        drawingViewModel: drawingViewModel,
                        viewModel: viewModel,
                        onCorrectGuess: {
                            // Direkt zum nächsten Begriff springen, ohne Zwischenbildschirm
                            viewModel.correctGuess()
                            drawingViewModel.resetForNewTerm()
                            drawingPhase = .showingTerm
                        },
                        onSkip: {
                            drawingPhase = .showingTerm
                            viewModel.skipTerm()
                        },
                        onWrongGuess: {
                            drawingPhase = .showingTerm
                            viewModel.wrongGuess()
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
    @ObservedObject var drawingViewModel: DrawingViewModel
    
    var body: some View {
        VStack(spacing: 15) {
            // Tool Selection (Stift/Radiergummi)
            HStack(spacing: 20) {
                ForEach(DrawingTool.allCases) { tool in
                    Button(action: {
                        drawingViewModel.selectTool(tool)
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: tool.systemImage)
                                .font(.title3)
                            Text(tool.name)
                                .fontWeight(.medium)
                        }
                        .foregroundStyle(drawingViewModel.selectedTool == tool ? .white : tool.color)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            drawingViewModel.selectedTool == tool ?
                                LinearGradient(colors: [tool.color, tool.color.opacity(0.8)], startPoint: .leading, endPoint: .trailing) :
                                LinearGradient(colors: [Color.gray.opacity(0.1)], startPoint: .leading, endPoint: .trailing)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(color: drawingViewModel.selectedTool == tool ? tool.color.opacity(0.3) : .clear, radius: 5, x: 0, y: 2)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .scaleEffect(drawingViewModel.selectedTool == tool ? 1.05 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: drawingViewModel.selectedTool)
                }
                
                Spacer()
                
                // Clear & Undo Buttons
                HStack(spacing: 12) {
                    // Undo Button
                    Button(action: {
                        drawingViewModel.undoLastStroke()
                    }) {
                        Image(systemName: "arrow.uturn.backward")
                            .font(.title3)
                            .foregroundStyle(.orange)
                            .frame(width: 44, height: 44)
                            .background(Color.orange.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 22))
                    }
                    .disabled(drawingViewModel.strokes.isEmpty)
                    .opacity(drawingViewModel.strokes.isEmpty ? 0.5 : 1.0)
                    
                    // Clear Button
                    Button(action: {
                        drawingViewModel.clearDrawing()
                    }) {
                        Image(systemName: "trash")
                            .font(.title3)
                            .foregroundStyle(.red)
                            .frame(width: 44, height: 44)
                            .background(Color.red.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 22))
                    }
                    .disabled(drawingViewModel.isEmpty)
                    .opacity(drawingViewModel.isEmpty ? 0.5 : 1.0)
                }
            }
            
            // Color Palette (nur für Stift sichtbar)
            if drawingViewModel.selectedTool == .pen {
                DrawingColorPalette(drawingViewModel: drawingViewModel)
            }
            
            // Line Width Selector
            DrawingLineWidthSelector(drawingViewModel: drawingViewModel)
        }
        .padding(.vertical, 15)
        .background(Color(.systemGray6).opacity(0.8))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .primary.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Preview

#Preview {
    DrawingView(viewModel: TimesUpGameViewModel())
}
