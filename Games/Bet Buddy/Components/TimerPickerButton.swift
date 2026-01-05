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
