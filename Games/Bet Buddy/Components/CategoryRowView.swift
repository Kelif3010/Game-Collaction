import SwiftUI

struct CategoryRowView: View {
    let category: CategoryType
    let isSelected: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            Image(systemName: category.iconName)
                .font(.title3.bold())
                .foregroundStyle(category.accent)
                .frame(width: 44, height: 44)
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 14))

            VStack(alignment: .leading, spacing: 4) {
                Text(LocalizedStringKey(category.title))
                    .foregroundStyle(.white)
                    .font(.headline)
                Text(LocalizedStringKey(category.description))
                    .foregroundStyle(Theme.mutedText)
                    .font(.subheadline)
            }

            Spacer()

            if category.isLocked {
                Image(systemName: "lock.fill")
                    .foregroundStyle(.white.opacity(0.7))
                    .font(.headline)
            } else if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color.green)
                    .font(.headline)
            } else {
                Image(systemName: "circle")
                    .foregroundStyle(.white.opacity(0.3))
                    .font(.headline)
            }
        }
        .padding()
        .background(Theme.cardBackground)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadius)
                .stroke(Theme.cardStroke, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
    }
}
