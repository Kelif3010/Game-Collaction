import SwiftUI

struct ScreenHeader: View {
    var title: String
    var showBack: Bool = true
    var backAction: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        HStack {
            if showBack {
                Button {
                    backAction?() ?? dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.headline.bold())
                        .foregroundStyle(BetBuddyTheme.textChampagne)
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.08))
                                .overlay(
                                    Circle()
                                        .stroke(BetBuddyTheme.accentGold.opacity(0.2), lineWidth: 1)
                                )
                        )
                }
            } else {
                Color.clear.frame(width: 36, height: 36)
            }

            Spacer()

            Text(LocalizedStringKey(title))
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(BetBuddyTheme.textGold)
                .tracking(1)

            Spacer()

            Color.clear.frame(width: 36, height: 36)
        }
        .padding(.bottom, 8)
    }
}
