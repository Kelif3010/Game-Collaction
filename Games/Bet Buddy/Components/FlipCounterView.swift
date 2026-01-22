import SwiftUI

struct FlipCounterView: View {
    var value: Int
    var color: Color

    private var digits: [String] {
        let string = String(format: "%03d", max(0, value))
        return string.map { String($0) }
    }

    var body: some View {
        HStack(spacing: 10) {
            ForEach(Array(digits.enumerated()), id: \.offset) { index, digit in
                CasinoChipDigit(digit: digit, color: color)
                    .id("\(index)-\(digit)")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.4))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(BetBuddyTheme.accentGold.opacity(0.2), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.3), radius: 10, y: 5)
    }
}

// MARK: - Casino Chip Digit
struct CasinoChipDigit: View {
    let digit: String
    let color: Color

    var body: some View {
        ZStack {
            // Äußerer Chip-Ring (Gold)
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.14, green: 0.14, blue: 0.12),
                            Color(red: 0.08, green: 0.08, blue: 0.06)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            // Metallic Gold Border
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    LinearGradient(
                        colors: [
                            BetBuddyTheme.accentGoldLight.opacity(0.7),
                            BetBuddyTheme.accentGold.opacity(0.3),
                            BetBuddyTheme.accentGoldLight.opacity(0.5)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2.5
                )

            // Innerer Glanz
            RoundedRectangle(cornerRadius: 10)
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.1), Color.clear],
                        startPoint: .top,
                        endPoint: .center
                    ),
                    lineWidth: 1
                )
                .padding(3)

            // Die Ziffer
            Text(digit)
                .font(.system(size: 42, weight: .black, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [color, color.opacity(0.85)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: color.opacity(0.6), radius: 6, y: 2)
                .contentTransition(.numericText())
                .animation(.spring(response: 0.35, dampingFraction: 0.7), value: digit)
        }
        .frame(width: 60, height: 72)
        .shadow(color: BetBuddyTheme.accentGold.opacity(0.15), radius: 8, y: 4)
    }
}
