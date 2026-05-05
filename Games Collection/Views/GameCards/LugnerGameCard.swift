import SwiftUI

struct LugnerGameCard: View {
    @State private var pulseAnimation = false

    private let accentGreen = Color(red: 0.22, green: 1.0, blue: 0.08)

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                Circle()
                    .stroke(accentGreen.opacity(0.3), lineWidth: 2)
                    .frame(width: 54, height: 54)
                    .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                    .opacity(pulseAnimation ? 0 : 0.6)

                Circle()
                    .fill(accentGreen.opacity(0.15))
                    .frame(width: 50, height: 50)
                    .overlay(Circle().stroke(accentGreen.opacity(0.4), lineWidth: 1))

                Image(systemName: "waveform.path.ecg")
                    .font(.title2)
                    .foregroundStyle(accentGreen)
                    .shadow(color: accentGreen.opacity(0.5), radius: 4)
            }

            Spacer()

            VStack(alignment: .leading, spacing: 4) {
                Text("Lügner")
                    .font(.system(.title3, design: .monospaced).bold())
                    .foregroundStyle(Color(red: 0.77, green: 0.73, blue: 0.60))
                Text("Lügendetektor")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(accentGreen.opacity(0.8))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 160)
        .padding()
        .background(
            ZStack {
                LinearGradient(
                    colors: [Color(red: 0.08, green: 0.07, blue: 0.05), Color(red: 0.04, green: 0.04, blue: 0.03)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                RadialGradient(
                    colors: [accentGreen.opacity(0.08), Color.clear],
                    center: .topLeading, startRadius: 0, endRadius: 200
                )
                VStack(spacing: 3) {
                    ForEach(0..<60, id: \.self) { _ in
                        Rectangle().fill(Color.black.opacity(0.15)).frame(height: 1)
                    }
                }
                .opacity(0.3)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(accentGreen.opacity(0.25), lineWidth: 1)
        )
        .shadow(color: accentGreen.opacity(0.15), radius: 12, x: 0, y: 5)
        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false)) { pulseAnimation = true }
        }
    }
}
