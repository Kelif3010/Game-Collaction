import SwiftUI

// MARK: - Haupt-Spielkarte (Flip-Animation)
struct SoundCardView: View {
    let card: SoundCard?
    var isFlipped: Bool
    var onTap: () -> Void

    @State private var rotation: Double = 0

    var body: some View {
        ZStack {
            // Rückseite — normal orientiert, blendet aus bei > 90°
            cardBack
                .opacity(rotation < 90 ? 1 : 0)

            // Vorderseite — fest um 180° pre-rotiert, damit der äußere
            // 180°-Flip sie wieder korrekt (nicht gespiegelt) anzeigt
            cardFront
                .rotation3DEffect(.degrees(180), axis: (0, 1, 0))
                .opacity(rotation >= 90 ? 1 : 0)
        }
        // Äußerer Container dreht sich: 0° → 180°
        .rotation3DEffect(.degrees(rotation), axis: (0, 1, 0))
        .onTapGesture {
            guard !isFlipped else { return }
            onTap()
        }
        .onChange(of: isFlipped) { _, flipped in
            withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                rotation = flipped ? 180 : 0
            }
        }
    }

    // MARK: Rückseite
    private var cardBack: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            SoundCinemaStyle.accentCyan.opacity(0.18),
                            Color(red: 0.1, green: 0.2, blue: 0.4)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(SoundCinemaStyle.accentCyan.opacity(0.35), lineWidth: 1.5)

            VStack(spacing: 16) {
                Image(systemName: "waveform.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(SoundCinemaStyle.primaryGradient)

                Text("Tippen zum Starten")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(SoundCinemaStyle.textMuted)

                Text("↑ Karte aufdecken")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(SoundCinemaStyle.accentCyan.opacity(0.6))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(SoundCinemaStyle.accentCyan.opacity(0.1)))
            }
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(0.72, contentMode: .fit)
    }

    // MARK: Vorderseite
    private var cardFront: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.03, green: 0.12, blue: 0.28),
                            Color(red: 0.05, green: 0.18, blue: 0.38)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // Cyan Glow-Effekt oben
            VStack {
                RadialGradient(
                    colors: [SoundCinemaStyle.accentCyan.opacity(0.15), Color.clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: 120
                )
                .frame(height: 160)
                Spacer()
            }

            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [SoundCinemaStyle.accentCyan.opacity(0.6), SoundCinemaStyle.accentCyan.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )

            // Inhalt
            VStack(spacing: 20) {
                Spacer()

                // Emoji
                Text(card?.emoji ?? "🎵")
                    .font(.system(size: 64))
                    .shadow(color: SoundCinemaStyle.accentCyan.opacity(0.4), radius: 20)

                // Titel
                Text(card?.localizedTitle ?? "")
                    .font(.system(size: 26, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 24)
                    .shadow(color: SoundCinemaStyle.accentCyan.opacity(0.3), radius: 8)

                // Pack-Badge
                if let card {
                    Text(card.pack.localizedName.uppercased())
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .tracking(2)
                        .foregroundStyle(card.pack.accentColor.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(card.pack.accentColor.primary.opacity(0.15))
                                .overlay(Capsule().stroke(card.pack.accentColor.primary.opacity(0.4), lineWidth: 1))
                        )
                }

                Spacer()

                // Hinweis-Text
                Text("Imitiere dieses Geräusch!")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(SoundCinemaStyle.textMuted)
                    .padding(.bottom, 20)
            }
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(0.72, contentMode: .fit)
    }
}
