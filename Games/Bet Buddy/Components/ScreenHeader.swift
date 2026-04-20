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
                        .frame(width: 44, height: 44)
                        .modifier(GlassCircleButtonBackground())
                }
                .accessibilityLabel("Zurück")
            } else {
                Color.clear.frame(width: 44, height: 44)
            }

            Spacer()

            Text(LocalizedStringKey(title))
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(BetBuddyTheme.textGold)
                .tracking(1)

            Spacer()

            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.bottom, 8)
    }
}
