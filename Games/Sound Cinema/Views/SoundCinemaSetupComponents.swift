//
//  SoundCinemaSetupComponents.swift
//  Games Collection
//
//  Wiederverwendbare Setup-Zeilen-Komponenten
//

import SwiftUI

// MARK: - Action Row

struct SoundCinemaSetupActionRow: View {
    let icon: String
    let title: String
    let detail: String
    let subtitle: String?
    let accent: Color

    var body: some View {
        HStack(spacing: 12) {
            SoundCinemaSetupIconBadge(icon: icon, accent: accent)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.white)

                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(SoundCinemaStyle.textMuted)
                        .lineLimit(2)
                }
            }

            Spacer()

            HStack(spacing: 6) {
                Text(detail)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(SoundCinemaStyle.textMuted)
                    .lineLimit(1)
                Image(systemName: "chevron.right")
                    .font(.subheadline)
                    .foregroundStyle(SoundCinemaStyle.textMuted.opacity(0.7))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.black.opacity(0.35))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(accent.opacity(0.12), lineWidth: 1)
        )
        .contentShape(Rectangle())
    }
}

// MARK: - Icon Badge

struct SoundCinemaSetupIconBadge: View {
    let icon: String
    let accent: Color

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [accent.opacity(0.22), accent.opacity(0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 44, height: 44)
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(accent.opacity(0.3), lineWidth: 1)
                )

            Image(systemName: icon)
                .font(.headline)
                .foregroundStyle(accent)
        }
        .accessibilityHidden(true)
    }
}
