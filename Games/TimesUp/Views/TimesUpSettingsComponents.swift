//
//  TimesUpSettingsComponents.swift
//  TimesUp
//

import SwiftUI

// MARK: - Settings Row

struct TimesUpSettingsRow: View {
    enum RowType {
        case teams
        case categories
        case timeWords
        case perks
        case difficulty
        case mode
    }

    var icon: String
    var title: LocalizedStringKey
    var detail: String?
    var rowType: RowType
    var isToggleOn: Bool = false
    var onTap: (() -> Void)?
    var onToggle: ((Bool) -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(colors: [.blue.opacity(0.3), .purple.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .foregroundStyle(.white)
                    .font(.headline)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .foregroundStyle(.white)
                    .font(.headline)

                if let detail, !detail.isEmpty,
                   rowType != .teams,
                   rowType != .categories,
                   rowType != .difficulty,
                   rowType != .mode {
                    Text(LocalizedStringKey(detail))
                        .foregroundStyle(TimesUpStyle.mutedText)
                        .font(.subheadline)
                }
            }
            Spacer()

            switch rowType {
            case .perks:
                HStack(spacing: 6) {
                    Text(isToggleOn ? "An" : "Aus")
                        .foregroundStyle(isToggleOn ? .green : TimesUpStyle.mutedText)
                        .font(.subheadline.weight(.semibold))

                    Image(systemName: "chevron.right")
                        .foregroundStyle(.white.opacity(0.5))
                        .font(.subheadline)
                }
            default:
                HStack(spacing: 6) {
                    if let detail, !detail.isEmpty {
                        if rowType == .teams || rowType == .categories || rowType == .difficulty || rowType == .mode {
                            Text(LocalizedStringKey(detail))
                                .foregroundStyle(TimesUpStyle.mutedText)
                                .font(.subheadline.weight(.semibold))
                        }
                    }
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.white.opacity(0.5))
                        .font(.subheadline)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(TimesUpStyle.cardBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(TimesUpStyle.cardStroke, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .contentShape(Rectangle())
        .onTapGesture {
            onTap?()
        }
    }
}

// MARK: - Selection Sheet Header

struct TimesUpSelectionSheetHeader: View {
    let icon: String
    let title: String
    let tint: Color

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.headline.bold())
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
            }

            Spacer()

            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(tint)
                Text(LocalizedStringKey(title))
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
                    .tracking(2)
            }

            Spacer()

            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal)
        .padding(.top, 20)
    }
}
