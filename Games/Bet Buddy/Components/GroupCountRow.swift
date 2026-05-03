import SwiftUI
import SFSafeSymbols

struct GroupCountRow: View {
    let count: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                // Poker-Chip-Style Zahl
                ZStack {
                    Circle()
                        .fill(
                            isSelected
                                ? BetBuddyTheme.accentGold.opacity(0.2)
                                : Color.white.opacity(0.06)
                        )
                        .frame(width: 48, height: 48)
                    Circle()
                        .stroke(
                            isSelected
                                ? BetBuddyTheme.accentGold.opacity(0.6)
                                : Color.white.opacity(0.15),
                            lineWidth: 2
                        )
                        .frame(width: 48, height: 48)
                    Text("\(count)")
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .foregroundStyle(isSelected ? BetBuddyTheme.accentGold : BetBuddyTheme.textChampagne)
                }

                VStack(alignment: .leading, spacing: 2) {
                    (Text("\(count) ") + Text("Gruppen"))
                        .foregroundStyle(BetBuddyTheme.textChampagne)
                        .font(.headline)
                    Text("je 2-4 Spieler")
                        .foregroundStyle(BetBuddyTheme.textSilver)
                        .font(.caption)
                }

                Spacer()

                // Checkmark im Casino-Style
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
                        Image(systemSymbol: .checkmark)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
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
                            ? BetBuddyTheme.accentGold.opacity(0.5)
                            : BetBuddyTheme.accentGold.opacity(0.1),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .shadow(
                color: isSelected ? BetBuddyTheme.accentGold.opacity(0.2) : Color.clear,
                radius: isSelected ? 12 : 0
            )
        }
    }
}
