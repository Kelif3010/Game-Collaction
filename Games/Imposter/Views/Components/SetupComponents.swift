//
//  SetupComponents.swift
//  Imposter
//
//  Created by Ken on 22.09.25.
//

import SwiftUI

// MARK: - Grouped Card Container
struct GroupedCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 12) {
            content
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: ImposterStyle.containerCornerRadius, style: .continuous)
                .fill(ImposterStyle.containerBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: ImposterStyle.containerCornerRadius, style: .continuous)
                .stroke(ImposterStyle.cardStroke, lineWidth: 1)
        )
    }
}

// MARK: - Row Cell
struct RowCell: View {
    let icon: String
    let title: String
    let value: String
    var tint: Color = .accentColor
    var showsChevron: Bool = true

    var body: some View {
        HStack(spacing: 12) {
            ImposterIconBadge(systemName: icon, tint: tint)
            Text(title)
                .font(.body)
                .fontWeight(.semibold)
            Spacer()
            Text(value)
                .font(.callout)
                .foregroundStyle(.secondary)
            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.footnote)
                    .foregroundStyle(.tertiary)
            }
        }
        .imposterRowStyle()
    }
}

// MARK: - Spy Option Row
struct SpyOptionRow: View {
    let icon: String
    let tint: Color
    let title: String
    let subtitle: String
    var isDisabled: Bool = false
    var isOn: Binding<Bool>

    var body: some View {
        HStack(spacing: 12) {
            ImposterIconBadge(systemName: icon, tint: tint)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(ImposterStyle.mutedText)
            }

            Spacer()

            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(.green)
        }
        .imposterRowStyle()
        .opacity(isDisabled ? 0.5 : 1.0)
        .disabled(isDisabled)
    }
}

// MARK: - Category Selection Row
struct CategorySelectionRow: View {
    let name: String
    let emoji: String
    let detail: String
    let isSelected: Bool
    var isLocked: Bool = false
    var isDisabled: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.orange.opacity(0.35), Color.red.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)

                Text(emoji)
                    .font(.system(size: 20))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.headline)
                    .foregroundStyle(.white)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(ImposterStyle.mutedText)
            }

            Spacer()

            if isLocked {
                Image(systemName: "lock.fill")
                    .foregroundStyle(.orange)
                    .font(.headline)
            } else if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.headline)
            } else {
                Image(systemName: "circle")
                    .foregroundStyle(.white.opacity(0.3))
                    .font(.headline)
            }
        }
        .imposterRowStyle()
        .opacity(isDisabled ? 0.5 : 1.0)
    }
}

// MARK: - Segmented Control
struct ImposterSegmentedControl: View {
    let titles: [String]
    @Binding var selectedIndex: Int
    var onSelect: ((Int) -> Void)? = nil

    var body: some View {
        HStack(spacing: 6) {
            ForEach(titles.indices, id: \.self) { index in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedIndex = index
                        onSelect?(index)
                    }
                } label: {
                    Text(titles[index])
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(selectedIndex == index ? .white : ImposterStyle.mutedText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(selectedIndex == index ? Color.white.opacity(0.12) : Color.clear)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: ImposterStyle.rowCornerRadius, style: .continuous)
                .fill(ImposterStyle.rowBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: ImposterStyle.rowCornerRadius, style: .continuous)
                .stroke(ImposterStyle.cardStroke, lineWidth: 1)
        )
    }
}

// MARK: - Game Mode Row
struct GameModeRow: View {
    let mode: ImposterGameMode
    let isSelected: Bool
    var isDisabled: Bool = false

    private var accent: Color {
        isDisabled ? .gray : .orange
    }

    var body: some View {
        HStack(spacing: 12) {
            ImposterIconBadge(systemName: mode.icon, tint: accent)

            VStack(alignment: .leading, spacing: 4) {
                Text(mode.localizedTitle)
                    .font(.headline)
                    .foregroundStyle(.white)
                Text(mode.description)
                    .font(.caption)
                    .foregroundStyle(ImposterStyle.mutedText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            if isDisabled {
                Image(systemName: "lock.fill")
                    .foregroundStyle(.orange)
                    .font(.headline)
            } else if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.headline)
            } else {
                Image(systemName: "circle")
                    .foregroundStyle(.white.opacity(0.3))
                    .font(.headline)
            }
        }
        .imposterRowStyle()
        .opacity(isDisabled ? 0.5 : 1.0)
    }
}