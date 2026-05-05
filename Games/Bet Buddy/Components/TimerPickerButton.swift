import SwiftUI

struct TimerPickerButton: View {
    var title: String
    var value: Int
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(LocalizedStringKey(title))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isSelected ? Color.black : .white)
                .padding(.vertical, 8)
                .padding(.horizontal, 14)
                .background(isSelected ? Color.white : Color.white.opacity(0.08))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ZStack {
        BetBuddyBackgroundView()
        HStack(spacing: 12) {
            TimerPickerButton(title: "30s", value: 30, isSelected: true, action: {})
            TimerPickerButton(title: "60s", value: 60, isSelected: false, action: {})
        }
        .padding()
    }
}
