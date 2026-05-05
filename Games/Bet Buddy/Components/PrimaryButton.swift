import SwiftUI

struct PrimaryButton: View {
    var title: String
    var action: () -> Void
    var isDisabled: Bool = false

    var body: some View {
        Button(action: action) {
            Text(LocalizedStringKey(title))
                .font(.headline.weight(.bold))
                .foregroundStyle(isDisabled ? BetBuddyTheme.textSilver : BetBuddyTheme.textOnLight)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    Group {
                        if isDisabled {
                            Capsule()
                                .fill(Color.white.opacity(0.08))
                        } else {
                            Capsule()
                                .fill(BetBuddyTheme.goldGradient)
                                .shadow(color: BetBuddyTheme.accentGold.opacity(0.4), radius: 12, y: 4)
                        }
                    }
                )
                .overlay(
                    Capsule()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.3),
                                    Color.clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1
                        )
                        .opacity(isDisabled ? 0 : 1)
                )
        }
        .disabled(isDisabled)
    }
}

#Preview {
    ZStack {
        BetBuddyBackgroundView()
        VStack(spacing: 20) {
            PrimaryButton(title: "Start Game", action: {})
            PrimaryButton(title: "Disabled", action: {}, isDisabled: true)
        }
        .padding()
    }
}
