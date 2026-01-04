//
//  DrawingLineWidthSelector.swift
//  TimesUp
//
//  Created by Ken  on 24.09.25.
//

import SwiftUI

// MARK: - Line Width Selector

struct DrawingLineWidthSelector: View {
    @ObservedObject var drawingState: DrawingState
    
    var body: some View {
        VStack(spacing: 12) {
            // Section Title
            HStack {
                Image(systemName: "lineweight")
                    .font(.subheadline)
                    .foregroundColor(.primary)
                Text(LocalizedStringKey("Strichstärke"))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                Spacer()
                
                // Current width indicator
                Text(LocalizedStringKey(DrawingLineWidths.name(for: drawingState.selectedLineWidth)))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }
            
            // Line Width Options
            HStack(spacing: 20) {
                ForEach(DrawingLineWidths.available, id: \.self) { width in
                    LineWidthButton(
                        width: width,
                        isSelected: drawingState.selectedLineWidth == width,
                        selectedColor: drawingState.selectedTool == .pen ? drawingState.selectedColor : .gray,
                        action: {
                            drawingState.selectLineWidth(width)
                        }
                    )
                }
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Individual Line Width Button

struct LineWidthButton: View {
    let width: CGFloat
    let isSelected: Bool
    let selectedColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                // Line preview
                RoundedRectangle(cornerRadius: width/2)
                    .fill(isSelected ? selectedColor : Color.gray.opacity(0.6))
                    .frame(width: 40, height: width)
                    .overlay(
                        RoundedRectangle(cornerRadius: width/2)
                            .stroke(isSelected ? selectedColor.opacity(0.3) : Color.clear, lineWidth: 2)
                    )
                
                // Width label
                Text("\(Int(width))")
                    .font(.caption2)
                    .fontWeight(isSelected ? .bold : .medium)
                    .foregroundColor(isSelected ? selectedColor : .secondary)
            }
            .frame(width: 50, height: 60)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? selectedColor.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - Custom Slider Alternative (für mehr Kontrolle)

struct DrawingLineWidthSlider: View {
    @ObservedObject var drawingState: DrawingState
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(LocalizedStringKey("Strichstärke"))
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Text("\(Int(drawingState.selectedLineWidth))")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
            }
            
            // Custom Slider
            HStack(spacing: 12) {
                // Min indicator
                Circle()
                    .fill(drawingState.selectedColor)
                    .frame(width: 2, height: 2)
                
                // Slider
                Slider(
                    value: $drawingState.selectedLineWidth,
                    in: 1...20,
                    step: 1
                ) {
                    Text(LocalizedStringKey("Strichstärke"))
                } minimumValueLabel: {
                    Text("1")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } maximumValueLabel: {
                    Text("20")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .tint(drawingState.selectedColor)
                
                // Max indicator  
                Circle()
                    .fill(drawingState.selectedColor)
                    .frame(width: 20, height: 20)
            }
            
            // Live Preview
            RoundedRectangle(cornerRadius: drawingState.selectedLineWidth/2)
                .fill(drawingState.selectedColor)
                .frame(width: 60, height: drawingState.selectedLineWidth)
                .animation(.easeInOut(duration: 0.1), value: drawingState.selectedLineWidth)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    VStack(spacing: 30) {
        DrawingLineWidthSelector(drawingState: DrawingState())
            .padding()
        
        DrawingLineWidthSlider(drawingState: DrawingState())
            .padding()
        
        Spacer()
    }
    .background(Color.gray.opacity(0.1))
}
