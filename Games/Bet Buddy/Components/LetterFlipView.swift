import SwiftUI

struct LetterFlipView: View {
    let value: Int
    var remaining: Int? = nil
    var color: Color = .white

    var body: some View {
        ZStack {
            // Casino-Karten-Hintergrund
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.14, green: 0.14, blue: 0.12),
                            Color(red: 0.08, green: 0.08, blue: 0.06)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 110, height: 130)

            // Gold-Rahmen (wie Spielkarte)
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: [
                            BetBuddyTheme.accentGoldLight.opacity(0.6),
                            BetBuddyTheme.accentGold.opacity(0.25),
                            BetBuddyTheme.accentGoldLight.opacity(0.4)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 3
                )
                .frame(width: 110, height: 130)

            // Innerer Schimmer
            RoundedRectangle(cornerRadius: 14)
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.08), Color.clear],
                        startPoint: .top,
                        endPoint: .center
                    ),
                    lineWidth: 1
                )
                .frame(width: 104, height: 124)

            // Karten-Ecken-Dekoration (oben links)
            VStack {
                HStack {
                    Text("♠")
                        .font(.system(size: 12))
                        .foregroundStyle(BetBuddyTheme.accentGold.opacity(0.4))
                        .padding(8)
                    Spacer()
                }
                Spacer()
                HStack {
                    Spacer()
                    Text("♠")
                        .font(.system(size: 12))
                        .foregroundStyle(BetBuddyTheme.accentGold.opacity(0.4))
                        .rotationEffect(.degrees(180))
                        .padding(8)
                }
            }
            .frame(width: 110, height: 130)

            // Der Buchstabe
            Text(value.asAlphabet)
                .font(.system(size: 64, weight: .black, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [color, color.opacity(0.85)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: color.opacity(0.5), radius: 8, y: 3)
                .contentTransition(.interpolate)
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: value)

            // Remaining Badge (Poker-Chip-Style)
            if let remaining = remaining, remaining > 0 {
                VStack {
                    HStack {
                        Spacer()
                        ZStack {
                            // Chip-Basis
                            Circle()
                                .fill(BetBuddyTheme.accentRuby)
                                .frame(width: 28, height: 28)

                            // Chip-Ring
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.4),
                                            Color.white.opacity(0.1)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2
                                )
                                .frame(width: 28, height: 28)

                            Text("\(remaining)")
                                .font(.system(size: 13, weight: .black))
                                .foregroundStyle(.white)
                        }
                        .shadow(color: BetBuddyTheme.accentRuby.opacity(0.5), radius: 4)
                        .offset(x: 10, y: -10)
                    }
                    Spacer()
                }
                .frame(width: 110, height: 130)
            }
        }
        .shadow(color: BetBuddyTheme.accentGold.opacity(0.1), radius: 12, y: 6)
        .shadow(color: Color.black.opacity(0.4), radius: 8, y: 4)
    }
}

#Preview {
    ZStack {
        BetBuddyBackgroundView()
        VStack(spacing: 40) {
            HStack(spacing: 20) {
                LetterFlipView(value: 1, color: .blue)
                LetterFlipView(value: 2, remaining: 5, color: .red)
            }
            
            HStack(spacing: 20) {
                LetterFlipView(value: 26, color: .green)
                LetterFlipView(value: 27, color: .purple)
            }
        }
    }
}
