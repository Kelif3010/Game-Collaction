import SwiftUI

struct PrimaryButton: View {
    var title: String
    var action: () -> Void
    var isDisabled: Bool = false

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(isDisabled ? Color.white.opacity(0.4) : Color.white)
                .clipShape(Capsule())
        }
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.6 : 1.0)
    }
}
