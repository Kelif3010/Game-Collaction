//
//  GameModeCard.swift
//  Imposter
//
//  Created by Ken on 22.09.25.
//

import SwiftUI

struct GameModeCard: View {
    let mode: ImposterGameMode
    let isSelected: Bool
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: mode.icon)
                .font(.title2)
                .foregroundColor(isSelected ? .white : .purple)
                .frame(width: 30)
            
            // Inhalt
            VStack(alignment: .leading, spacing: 4) {
                Text(mode.displayName)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(isSelected ? .white : .primary)
                
                Text(mode.description)
                    .font(.caption)
                    .foregroundColor(isSelected ? .white.opacity(0.9) : .secondary)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
            
            // Auswahl-Indikator
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.white)
            } else {
                Circle()
                    .strokeBorder(Color.purple.opacity(0.5), lineWidth: 2)
                    .frame(width: 24, height: 24)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    isSelected ?
                        LinearGradient(colors: [.purple, .purple.opacity(0.8)], startPoint: .leading, endPoint: .trailing) :
                        LinearGradient(colors: [Color(.systemGray6), Color(.systemGray6)], startPoint: .leading, endPoint: .trailing)
                )
                .shadow(color: .black.opacity(isSelected ? 0.3 : 0.1), radius: isSelected ? 5 : 2, x: 0, y: isSelected ? 3 : 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    isSelected ? Color.clear : Color.purple.opacity(0.3),
                    lineWidth: isSelected ? 0 : 1
                )
        )
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

#Preview {
    VStack(spacing: 15) {
        GameModeCard(mode: .classic, isSelected: true)
        GameModeCard(mode: .twoWords, isSelected: false)
    }
    .padding(20)
    .background(
        LinearGradient(
            colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
}
