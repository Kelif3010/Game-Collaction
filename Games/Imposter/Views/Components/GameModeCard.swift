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

    // Imposter Theme Colors
    private let accentPrimary = Color(red: 1.0, green: 0.41, blue: 0.23)
    private let accentSecondary = Color(red: 0.94, green: 0.16, blue: 0.47)

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: mode.icon)
                .font(.title2)
                .foregroundColor(isSelected ? .white : accentPrimary)
                .frame(width: 30)

            // Inhalt
            VStack(alignment: .leading, spacing: 4) {
                Text(mode.displayName)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)

                Text(mode.description)
                    .font(.caption)
                    .foregroundColor(isSelected ? .white.opacity(0.9) : .white.opacity(0.6))
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
                    .strokeBorder(accentPrimary.opacity(0.5), lineWidth: 2)
                    .frame(width: 24, height: 24)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: ImposterStyle.rowCornerRadius)
                .fill(
                    isSelected
                        ? ImposterStyle.primaryGradient
                        : LinearGradient(colors: [ImposterStyle.rowBackground, ImposterStyle.rowBackground], startPoint: .leading, endPoint: .trailing)
                )
                .shadow(color: isSelected ? accentSecondary.opacity(0.4) : .black.opacity(0.2), radius: isSelected ? 8 : 4, x: 0, y: isSelected ? 4 : 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: ImposterStyle.rowCornerRadius)
                .stroke(
                    isSelected ? Color.clear : accentPrimary.opacity(0.25),
                    lineWidth: 1
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
    .background(ImposterStyle.backgroundGradient)
}
