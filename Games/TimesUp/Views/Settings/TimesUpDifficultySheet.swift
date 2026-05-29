//
//  TimesUpDifficultySheet.swift
//  TimesUp
//

import SwiftUI

struct TimesUpDifficultySheet: View {
    let selected: Difficulty
    let onSelect: (Difficulty) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            TimesUpStyle.backgroundGradient.ignoresSafeArea()

            VStack(spacing: 0) {
                TimesUpSelectionSheetHeader(
                    icon: "gauge.medium",
                    title: "SCHWIERIGKEIT",
                    tint: .orange
                )

                Text("Wähle, wie streng Fehler und Skips behandelt werden")
                    .font(.subheadline)
                    .foregroundStyle(TimesUpStyle.mutedText)
                    .padding(.top, 8)

                VStack(spacing: 10) {
                    ForEach(Difficulty.allCases, id: \.self) { difficulty in
                        let isSelected = selected == difficulty

                        Button {
                            TimesUpHaptics.impact(.light)
                            onSelect(difficulty)
                            dismiss()
                        } label: {
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(isSelected ? difficultyColor(difficulty).opacity(0.2) : Color.white.opacity(0.06))
                                        .frame(width: 40, height: 40)

                                    Text(difficultyEmoji(difficulty))
                                        .font(.system(size: 18))
                                }

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(LocalizedStringKey(difficulty.rawValue))
                                        .font(.body.weight(.semibold))
                                        .foregroundStyle(.white)
                                    Text(LocalizedStringKey(difficultyDescription(difficulty)))
                                        .font(.caption)
                                        .foregroundStyle(isSelected ? difficultyColor(difficulty).opacity(0.95) : TimesUpStyle.mutedText)
                                        .multilineTextAlignment(.leading)
                                }

                                Spacer()

                                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                    .font(.title3)
                                    .foregroundStyle(isSelected ? difficultyColor(difficulty) : Color.white.opacity(0.25))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(isSelected ? difficultyColor(difficulty).opacity(0.12) : Color.black.opacity(0.35))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(isSelected ? difficultyColor(difficulty).opacity(0.45) : Color.white.opacity(0.08), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 16)

                Spacer()
            }
        }
    }

    private func difficultyDescription(_ difficulty: Difficulty) -> String {
        switch difficulty {
        case .easy:   return "Entspannt. Fehler kosten keine zusätzlichen Punkte."
        case .medium: return "Ausgewogen. Fehler bremsen stärker."
        case .hard:   return "Hart. Für riskante Runden mit mehr Druck."
        }
    }

    private func difficultyEmoji(_ difficulty: Difficulty) -> String {
        switch difficulty {
        case .easy:   return "🙂"
        case .medium: return "⚡"
        case .hard:   return "🔥"
        }
    }

    private func difficultyColor(_ difficulty: Difficulty) -> Color {
        switch difficulty {
        case .easy:   return .green
        case .medium: return .orange
        case .hard:   return .red
        }
    }
}
