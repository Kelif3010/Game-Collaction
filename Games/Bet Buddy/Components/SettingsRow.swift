import SwiftUI

struct SettingsRow: View {
    enum RowType {
        case groups
        case categories
        case timer
        case hints
        case partyMode
        case penalty
    }

    var icon: String
    var title: String
    var detail: String?
    var rowType: RowType
    var isToggleOn: Bool = false
    var onTap: (() -> Void)?
    var onToggle: ((Bool) -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            // Casino-Style Icon Badge
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        LinearGradient(
                            colors: [
                                BetBuddyTheme.accentGold.opacity(0.2),
                                BetBuddyTheme.accentGold.opacity(0.08)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(BetBuddyTheme.accentGold.opacity(0.3), lineWidth: 1)
                    )
                Image(systemName: icon)
                    .foregroundStyle(BetBuddyTheme.accentGold)
                    .font(.headline)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(LocalizedStringKey(title))
                    .foregroundStyle(BetBuddyTheme.textChampagne)
                    .font(.headline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                if let detail, !detail.isEmpty, rowType != .groups, rowType != .categories {
                    Text(LocalizedStringKey(detail))
                        .foregroundStyle(BetBuddyTheme.textSilver)
                        .font(.subheadline)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }
            }
            Spacer()

            switch rowType {
            case .timer, .hints, .partyMode, .penalty:
                Toggle("", isOn: Binding(get: { isToggleOn }, set: { onToggle?($0) }))
                    .labelsHidden()
                    .tint(BetBuddyTheme.accentEmerald)
            default:
                HStack(spacing: 6) {
                    if let detail, !detail.isEmpty {
                        Text(LocalizedStringKey(detail))
                            .foregroundStyle(BetBuddyTheme.textSilver)
                            .font(.subheadline.weight(.semibold))
                    }
                    Image(systemName: "chevron.right")
                        .foregroundStyle(BetBuddyTheme.accentGold.opacity(0.6))
                        .font(.subheadline)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.35))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(BetBuddyTheme.accentGold.opacity(0.12), lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onTap?()
        }
    }
}
