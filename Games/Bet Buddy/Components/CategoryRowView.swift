import SwiftUI

struct CategoryRowView: View {
    let category: CategoryType
    let isSelected: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            // Icon-Badge im Casino-Style
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [
                                category.accent.opacity(0.25),
                                category.accent.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)

                RoundedRectangle(cornerRadius: 12)
                    .stroke(category.accent.opacity(0.4), lineWidth: 1)
                    .frame(width: 48, height: 48)

                Image(systemName: category.iconName)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(category.accent)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(LocalizedStringKey(category.title))
                    .foregroundStyle(BetBuddyTheme.textChampagne)
                    .font(.headline)
                Text(LocalizedStringKey(category.description))
                    .foregroundStyle(BetBuddyTheme.textSilver)
                    .font(.subheadline)
                    .lineLimit(2)
            }

            Spacer()

            // Checkmark im Casino-Style
            if category.isLocked {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 28, height: 28)
                    Image(systemName: "lock.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(BetBuddyTheme.textSilver)
                }
            } else {
                ZStack {
                    Circle()
                        .fill(isSelected ? BetBuddyTheme.accentEmerald : Color.clear)
                        .frame(width: 28, height: 28)
                    Circle()
                        .stroke(
                            isSelected ? BetBuddyTheme.accentEmerald : BetBuddyTheme.textSilver.opacity(0.4),
                            lineWidth: 2
                        )
                        .frame(width: 28, height: 28)
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.35))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    isSelected
                        ? category.accent.opacity(0.4)
                        : BetBuddyTheme.accentGold.opacity(0.1),
                    lineWidth: isSelected ? 2 : 1
                )
        )
        .shadow(
            color: isSelected ? category.accent.opacity(0.15) : Color.clear,
            radius: isSelected ? 10 : 0
        )
    }
}
