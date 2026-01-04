//
//  CompactDrawingToolsView.swift
//  TimesUp
//
//  Created by Ken  on 24.09.25.
//

import SwiftUI

// MARK: - Compact Drawing Tools (für Drawing Phase)

struct CompactDrawingToolsView: View {
    @ObservedObject var drawingState: DrawingState
    @State private var showingColorPicker = false
    
    var body: some View {
        HStack(spacing: 8) {
            // Tool Selection (Stift/Radiergummi)
            HStack(spacing: 6) {
                ForEach(DrawingTool.allCases) { tool in
                    Button(action: {
                        drawingState.selectTool(tool)
                    }) {
                        let isSelected = drawingState.selectedTool == tool
                        let foregroundColor = isSelected ? .white : tool.color
                        let backgroundGradient = isSelected ? 
                            LinearGradient(colors: [tool.color, tool.color.opacity(0.8)], startPoint: .leading, endPoint: .trailing) :
                            LinearGradient(colors: [Color.gray.opacity(0.1)], startPoint: .leading, endPoint: .trailing)
                        
                        Image(systemName: tool.systemImage)
                            .font(.title3)
                            .foregroundColor(foregroundColor)
                            .frame(width: 32, height: 32)
                            .background(backgroundGradient)
                            .cornerRadius(16)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            
            // Farb-Selector (Kreis mit aktueller Farbe + Sheet)
            Button(action: {
                print("🔵 DEBUG: Color button tapped!")
                showingColorPicker.toggle()
            }) {
                Circle()
                    .fill(drawingState.selectedColor)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Circle()
                            .stroke(Color.primary.opacity(0.2), lineWidth: 2)
                    )
                    .overlay(
                        Circle()
                            .stroke(drawingState.selectedColor == .white ? Color.black.opacity(0.3) : Color.clear, lineWidth: 1)
                    )
                    .shadow(color: drawingState.selectedColor.opacity(0.3), radius: 3, x: 0, y: 2)
            }
            .buttonStyle(PlainButtonStyle())
            .sheet(isPresented: $showingColorPicker) {
                VStack(spacing: 20) {
                    Text(LocalizedStringKey("Farbe wählen"))
                        .font(.headline)
                        .padding(.top)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                        ForEach(DrawingColors.essential, id: \.self) { color in
                            Button(action: {
                                print("🎨 DEBUG: Color selected: \(color)")
                                drawingState.selectColor(color)
                                showingColorPicker = false
                            }) {
                                Circle()
                                    .fill(color)
                                    .frame(width: 50, height: 50)
                                    .overlay(
                                        Circle()
                                            .stroke(drawingState.selectedColor == color ? Color.blue : Color.gray.opacity(0.3), lineWidth: 4)
                                    )
                                    .overlay(
                                        Circle()
                                            .stroke(color == .white ? Color.black.opacity(0.2) : Color.clear, lineWidth: 1)
                                    )
                                    .scaleEffect(drawingState.selectedColor == color ? 1.1 : 1.0)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 30)
                    
                    Spacer()
                }
                .presentationDetents([.height(300)])
                .presentationDragIndicator(.visible)
            }
            
            
            Spacer()
            
            // Line Width Selection (kompakt)
            Menu {
                ForEach(DrawingLineWidths.available, id: \.self) { width in
                    Button(action: {
                        drawingState.selectLineWidth(width)
                    }) {
                        HStack {
                            RoundedRectangle(cornerRadius: width/2)
                                .fill(Color.primary)
                                .frame(width: 30, height: width)
                            
                            Text(DrawingLineWidths.name(for: width))
                                .font(.subheadline)
                            
                            if drawingState.selectedLineWidth == width {
                                Spacer()
                                Image(systemName: "checkmark")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: drawingState.selectedLineWidth/2)
                        .fill(Color.primary)
                        .frame(width: 20, height: drawingState.selectedLineWidth)
                    
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundColor(.primary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(20)
            }
            
            Spacer()
            
                // Action Buttons (Undo/Clear)
                HStack(spacing: 6) {
                    // Undo
                    Button(action: {
                        drawingState.undoLastStroke()
                    }) {
                        Image(systemName: "arrow.uturn.backward")
                            .font(.system(size: 14))
                            .foregroundColor(.orange)
                            .frame(width: 32, height: 32)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(16)
                    }
                    .disabled(drawingState.strokes.isEmpty)
                    .opacity(drawingState.strokes.isEmpty ? 0.5 : 1.0)
                    
                    // Clear
                    Button(action: {
                        drawingState.clearDrawing()
                    }) {
                        Image(systemName: "trash")
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                            .frame(width: 32, height: 32)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(16)
                    }
                    .disabled(drawingState.isEmpty)
                    .opacity(drawingState.isEmpty ? 0.5 : 1.0)
                }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(Color(.systemGray6).opacity(0.8))
        .cornerRadius(12)
    }
}

#Preview {
    CompactDrawingToolsView(drawingState: DrawingState())
        .padding()
}
