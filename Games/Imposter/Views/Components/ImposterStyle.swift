import SwiftUI

enum ImposterStyle {
    static let backgroundGradient = LinearGradient(
        colors: [
            Color.black,
            Color(red: 0.16, green: 0.02, blue: 0.08),
            Color(red: 0.28, green: 0.02, blue: 0.18)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let primaryGradient = LinearGradient(
        colors: [Color(red: 1.0, green: 0.41, blue: 0.23), Color(red: 0.94, green: 0.16, blue: 0.47)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let darkCardFill = Color.black.opacity(0.25)
    static let containerBackground = Color.black.opacity(0.25)
    static let rowBackground = Color.black.opacity(0.25)
    static let cardStroke = Color.white.opacity(0.08)
    static let containerCornerRadius: CGFloat = 22
    static let rowCornerRadius: CGFloat = 18
    static let padding: CGFloat = 20
    static let mutedText = Color.white.opacity(0.7)
}

extension View {
    func imposterRowStyle() -> some View {
        self
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
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

struct ImposterPrimaryButton: View {
    let title: String
    let action: () -> Void
    var isDisabled: Bool = false

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline.weight(.semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
        }
        .background(
            Capsule()
                .fill(ImposterStyle.primaryGradient)
        )
        .shadow(color: .black.opacity(0.25), radius: 16, y: 8)
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.6 : 1.0)
    }
}

struct ImposterIconBadge: View {
    let systemName: String
    let tint: Color

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [tint.opacity(0.35), tint.opacity(0.15)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            Image(systemName: systemName)
                .foregroundColor(tint)
                .font(.system(size: 18, weight: .semibold))
        }
        .frame(width: 44, height: 44)
    }
}
