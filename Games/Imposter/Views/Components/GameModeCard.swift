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
                .foregroundStyle(isSelected ? .white : accentPrimary)
                .frame(width: 30)

            // Inhalt
            VStack(alignment: .leading, spacing: 4) {
                Text(mode.displayName)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)

                Text(mode.description)
                    .font(.caption)
                    .foregroundStyle(isSelected ? .white.opacity(0.9) : .white.opacity(0.6))
                    .multilineTextAlignment(.leading)
            }

            Spacer()

            // Auswahl-Indikator
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.white)
            } else {
                Circle()
                    .strokeBorder(accentPrimary.opacity(0.5), lineWidth: 2)
                    .frame(width: 24, height: 24)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .modifier(GameModeCardBackground(
            isSelected: isSelected,
            accentPrimary: accentPrimary,
            accentSecondary: accentSecondary
        ))
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

// MARK: - Background Modifier

private struct GameModeCardBackground: ViewModifier {
    let isSelected: Bool
    let accentPrimary: Color
    let accentSecondary: Color

    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content
                .glassEffect(
                    isSelected
                        ? Glass.regular.tint(accentPrimary).interactive()
                        : Glass.regular.interactive(),
                    in: RoundedRectangle(cornerRadius: ImposterStyle.rowCornerRadius)
                )
        } else {
            content
                .background(
                    RoundedRectangle(cornerRadius: ImposterStyle.rowCornerRadius)
                        .fill(
                            isSelected
                                ? ImposterStyle.primaryGradient
                                : LinearGradient(
                                    colors: [ImposterStyle.rowBackground, ImposterStyle.rowBackground],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                        )
                        .shadow(
                            color: isSelected ? accentSecondary.opacity(0.4) : .black.opacity(0.2),
                            radius: isSelected ? 8 : 4, x: 0, y: isSelected ? 4 : 2
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: ImposterStyle.rowCornerRadius)
                        .stroke(
                            isSelected ? Color.clear : accentPrimary.opacity(0.25),
                            lineWidth: 1
                        )
                )
        }
    }
}
