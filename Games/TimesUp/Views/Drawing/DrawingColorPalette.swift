//
//  DrawingColorPalette.swift
//  TimesUp
//
//  Created by Ken  on 24.09.25.
//

import SwiftUI

// MARK: - Color Palette

struct DrawingColorPalette: View {
    @ObservedObject var drawingState: DrawingState
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        VStack(spacing: 12) {
            // Section Title
            HStack {
                Image(systemName: "paintpalette")
                    .font(.subheadline)
                    .foregroundColor(.primary)
                Text(LocalizedStringKey("Farben"))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                Spacer()
            }
            
            // Color Grid
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(DrawingColors.essential, id: \.self) { color in
                    ColorCircle(
                        color: color,
                        isSelected: drawingState.selectedColor == color,
                        action: {
                            drawingState.selectColor(color)
                        }
                    )
                }
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Individual Color Circle

struct ColorCircle: View {
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // Main color circle
                Circle()
                    .fill(color)
                    .frame(width: 36, height: 36)
                
                // Selection border
                if isSelected {
                    Circle()
                        .stroke(Color.white, lineWidth: 3)
                        .frame(width: 36, height: 36)
                    
                    Circle()
                        .stroke(color == .black ? Color.white : Color.black, lineWidth: 2)
                        .frame(width: 40, height: 40)
                }
                
                // Selection checkmark for white/light colors
                if isSelected && (color == .white || isLightColor(color)) {
                    Image(systemName: "checkmark")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
    
    // Helper to detect light colors
    private func isLightColor(_ color: Color) -> Bool {
        // Simplified light color detection
        return color == .white || color == .yellow || color == .cyan || color == .mint
    }
}

#Preview {
    VStack {
        DrawingColorPalette(drawingState: DrawingState())
            .padding()
        
        Spacer()
    }
    .background(Color.gray.opacity(0.1))
}
