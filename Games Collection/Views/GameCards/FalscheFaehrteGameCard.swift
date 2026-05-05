import SwiftUI

struct FalscheFaehrteGameCard: View {
    private let accentViolet = Color(red: 0.48, green: 0.36, blue: 0.94)
    private let accentIndigo = Color(red: 0.33, green: 0.25, blue: 0.82)
    private let deepDark     = Color(red: 0.05, green: 0.04, blue: 0.14)

    @State private var glowPulse = false
    @State private var maskPulse = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                Circle()
                    .fill(accentViolet.opacity(0.18))
                    .frame(width: 52, height: 52)
                    .scaleEffect(glowPulse ? 1.18 : 1.0)
                    .opacity(glowPulse ? 0 : 0.7)

                Circle()
                    .fill(LinearGradient(colors: [accentViolet, accentIndigo], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 50, height: 50)

                Image(systemName: "magnifyingglass.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.black.opacity(0.85))
            }

            Spacer()

            VStack(alignment: .leading, spacing: 4) {
                Text("Falsche Fährte")
                    .font(.system(.title3, design: .rounded).bold())
                    .foregroundStyle(.white)
                Text("Lüge & Entlarve")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(accentViolet.opacity(0.9))
                    .tracking(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 160)
        .padding()
        .background(
            ZStack {
                LinearGradient(
                    colors: [deepDark, Color(red: 0.08, green: 0.06, blue: 0.22)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                RadialGradient(
                    colors: [accentViolet.opacity(maskPulse ? 0.16 : 0.08), Color.clear],
                    center: .topLeading, startRadius: 0, endRadius: 180
                )
                HStack(spacing: 10) {
                    ForEach(Array(["?", "!", "?"].enumerated()), id: \.offset) { _, sym in
                        Text(sym)
                            .font(.system(size: 28, weight: .black, design: .rounded))
                            .foregroundStyle(accentViolet.opacity(maskPulse ? 0.1 : 0.05))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .padding(.trailing, 10)
                .padding(.bottom, 10)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: [accentViolet.opacity(0.55), accentIndigo.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        .shadow(color: accentViolet.opacity(0.2), radius: 12, x: 0, y: 5)
        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: false)) { glowPulse = true }
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) { maskPulse = true }
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        FalscheFaehrteGameCard()
            .padding()
    }
}
