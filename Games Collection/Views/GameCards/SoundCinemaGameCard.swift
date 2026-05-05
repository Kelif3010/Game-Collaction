import SwiftUI

struct SoundCinemaGameCard: View {
    private let accentCyan = Color(red: 0.0,  green: 0.83, blue: 1.0)
    private let accentBlue = Color(red: 0.15, green: 0.45, blue: 1.0)
    private let deepNavy   = Color(red: 0.02, green: 0.06, blue: 0.20)

    @State private var wavePulse = false
    @State private var glowPulse = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                Circle()
                    .fill(accentCyan.opacity(0.18))
                    .frame(width: 52, height: 52)
                    .scaleEffect(glowPulse ? 1.18 : 1.0)
                    .opacity(glowPulse ? 0 : 0.7)

                Circle()
                    .fill(LinearGradient(colors: [accentCyan, accentBlue], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 50, height: 50)

                Image(systemName: "waveform.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.black.opacity(0.85))
            }

            Spacer()

            VStack(alignment: .leading, spacing: 4) {
                Text("Geräusch-Kino")
                    .font(.system(.title3, design: .rounded).bold())
                    .foregroundStyle(.white)
                Text("Imitier & Rate")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(accentCyan.opacity(0.85))
                    .tracking(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 160)
        .padding()
        .background(
            ZStack {
                LinearGradient(
                    colors: [deepNavy, Color(red: 0.03, green: 0.10, blue: 0.28)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                RadialGradient(
                    colors: [accentCyan.opacity(wavePulse ? 0.14 : 0.07), Color.clear],
                    center: .topLeading, startRadius: 0, endRadius: 180
                )
                HStack(alignment: .center, spacing: 3) {
                    ForEach(Array([0.3, 0.7, 0.5, 1.0, 0.6, 0.8, 0.4, 0.9, 0.5, 0.3].enumerated()), id: \.offset) { _, h in
                        Capsule()
                            .fill(accentCyan.opacity(wavePulse ? 0.12 : 0.06))
                            .frame(width: 3, height: 40 * h)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .padding(.trailing, 8)
                .padding(.bottom, 8)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: [accentCyan.opacity(0.55), accentBlue.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        .shadow(color: accentCyan.opacity(0.18), radius: 12, x: 0, y: 5)
        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) { wavePulse = true }
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: false)) { glowPulse = true }
        }
    }
}
