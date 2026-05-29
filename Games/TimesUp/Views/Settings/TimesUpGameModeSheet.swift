//
//  TimesUpGameModeSheet.swift
//  TimesUp
//

import SwiftUI

struct TimesUpGameModeSheet: View {
    let selected: TimesUpGameMode
    let onSelect: (TimesUpGameMode) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            TimesUpStyle.backgroundGradient.ignoresSafeArea()

            VStack(spacing: 0) {
                TimesUpSelectionSheetHeader(
                    icon: "gamecontroller.fill",
                    title: "SPIELMODUS",
                    tint: .blue
                )

                Text("Wähle, wie eure Runden aufgebaut sind")
                    .font(.subheadline)
                    .foregroundStyle(TimesUpStyle.mutedText)
                    .padding(.top, 8)

                VStack(spacing: 10) {
                    ForEach(TimesUpGameMode.allCases, id: \.self) { mode in
                        let isSelected = selected == mode

                        Button {
                            TimesUpHaptics.impact(.light)
                            onSelect(mode)
                            dismiss()
                        } label: {
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(isSelected ? modeColor(mode).opacity(0.2) : Color.white.opacity(0.06))
                                        .frame(width: 40, height: 40)

                                    Image(systemName: modeIcon(mode))
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundStyle(isSelected ? modeColor(mode) : Color.white.opacity(0.8))
                                }

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(LocalizedStringKey(mode.rawValue))
                                        .font(.body.weight(.semibold))
                                        .foregroundStyle(.white)
                                    Text(LocalizedStringKey(mode.description))
                                        .font(.caption)
                                        .foregroundStyle(isSelected ? modeColor(mode).opacity(0.95) : TimesUpStyle.mutedText)
                                        .multilineTextAlignment(.leading)
                                }

                                Spacer()

                                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                    .font(.title3)
                                    .foregroundStyle(isSelected ? modeColor(mode) : Color.white.opacity(0.25))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(isSelected ? modeColor(mode).opacity(0.12) : Color.black.opacity(0.35))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(isSelected ? modeColor(mode).opacity(0.45) : Color.white.opacity(0.08), lineWidth: 1)
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

    private func modeIcon(_ mode: TimesUpGameMode) -> String {
        switch mode {
        case .classic:     return "list.number"
        case .withDrawing: return "pencil.and.outline"
        case .randomOrder: return "shuffle"
        }
    }

    private func modeColor(_ mode: TimesUpGameMode) -> Color {
        switch mode {
        case .classic:     return .blue
        case .withDrawing: return .purple
        case .randomOrder: return .mint
        }
    }
}
