//
//  DrawingLineWidthSelector.swift
//  TimesUp
//
//  Created by Ken  on 24.09.25.
//

import SwiftUI

// MARK: - Line Width Selector

struct DrawingLineWidthSelector: View {
    @ObservedObject var drawingViewModel: DrawingViewModel
    
    var body: some View {
        VStack(spacing: 12) {
            // Section Title
            HStack {
                Image(systemName: "lineweight")
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                Text(LocalizedStringKey("Strichstärke"))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                Spacer()
                
                // Current width indicator
                Text(LocalizedStringKey(DrawingLineWidths.name(for: drawingViewModel.selectedLineWidth)))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            
            // Line Width Options
            HStack(spacing: 20) {
                ForEach(DrawingLineWidths.available, id: \.self) { width in
                    LineWidthButton(
                        width: width,
                        isSelected: drawingViewModel.selectedLineWidth == width,
                        selectedColor: drawingViewModel.selectedTool == .pen ? drawingViewModel.selectedColor : .gray,
                        action: {
                            drawingViewModel.selectLineWidth(width)
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
                    .foregroundStyle(isSelected ? selectedColor : .secondary)
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
    @ObservedObject var drawingViewModel: DrawingViewModel
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(LocalizedStringKey("Strichstärke"))
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Text("\(Int(drawingViewModel.selectedLineWidth))")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(.blue)
            }
            
            // Custom Slider
            HStack(spacing: 12) {
                // Min indicator
                Circle()
                    .fill(drawingViewModel.selectedColor)
                    .frame(width: 2, height: 2)
                
                // Slider
                Slider(
                    value: $drawingViewModel.selectedLineWidth,
                    in: 1...20,
                    step: 1
                ) {
                    Text(LocalizedStringKey("Strichstärke"))
                } minimumValueLabel: {
                    Text("1")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } maximumValueLabel: {
                    Text("20")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .tint(drawingViewModel.selectedColor)
                
                // Max indicator  
                Circle()
                    .fill(drawingViewModel.selectedColor)
                    .frame(width: 20, height: 20)
            }
            
            // Live Preview
            RoundedRectangle(cornerRadius: drawingViewModel.selectedLineWidth/2)
                .fill(drawingViewModel.selectedColor)
                .frame(width: 60, height: drawingViewModel.selectedLineWidth)
                .animation(.easeInOut(duration: 0.1), value: drawingViewModel.selectedLineWidth)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    VStack(spacing: 30) {
        DrawingLineWidthSelector(drawingViewModel: DrawingViewModel())
            .padding()
        
        DrawingLineWidthSlider(drawingViewModel: DrawingViewModel())
            .padding()
        
        Spacer()
    }
    .background(Color.gray.opacity(0.1))
}
