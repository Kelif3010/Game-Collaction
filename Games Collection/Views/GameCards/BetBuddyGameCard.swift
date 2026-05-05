import SwiftUI

struct BetBuddyGameCard: View {
    @State private var chipRotation = false
    @State private var shimmer = false

    private let accentGold      = Color(red: 0.85, green: 0.65, blue: 0.12)
    private let accentGoldLight = Color(red: 0.95, green: 0.80, blue: 0.35)
    private let textChampagne   = Color(red: 0.95, green: 0.92, blue: 0.85)

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                Circle()
                    .stroke(accentGold.opacity(0.4), lineWidth: 2)
                    .frame(width: 54, height: 54)
                    .scaleEffect(chipRotation ? 1.15 : 1.0)
                    .opacity(chipRotation ? 0 : 0.6)

                Circle()
                    .fill(
                        LinearGradient(
                            colors: [accentGold, accentGold.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                    .overlay(Circle().stroke(accentGoldLight.opacity(0.6), lineWidth: 2))
                    .shadow(color: accentGold.opacity(0.4), radius: 6)

                Image(systemName: "suit.spade.fill")
                    .font(.title2)
                    .foregroundStyle(Color(red: 0.15, green: 0.12, blue: 0.08))
            }

            Spacer()

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text("Ich biete mehr!")
                        .font(.system(.title3, design: .rounded).bold())
                        .foregroundStyle(textChampagne)
                    HStack(spacing: 2) {
                        Text("♠").font(.system(size: 10)).foregroundStyle(accentGold.opacity(0.6))
                        Text("♦").font(.system(size: 10)).foregroundStyle(Color(red: 0.65, green: 0.12, blue: 0.15).opacity(0.6))
                    }
                }
                Text("High Stakes")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(accentGold.opacity(0.8))
                    .tracking(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 160)
        .padding()
        .background(
            ZStack {
                LinearGradient(
                    colors: [Color(red: 0.05, green: 0.08, blue: 0.05), Color(red: 0.03, green: 0.05, blue: 0.03)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                Color(red: 0.05, green: 0.12, blue: 0.08).opacity(0.3)
                RadialGradient(
                    colors: [accentGold.opacity(shimmer ? 0.15 : 0.08), Color.clear],
                    center: .topLeading, startRadius: 0, endRadius: 180
                )
                VStack(spacing: 8) {
                    ForEach(0..<20, id: \.self) { _ in
                        Rectangle().fill(Color.black.opacity(0.08)).frame(height: 1)
                    }
                }
                .opacity(0.5)
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text("♣").font(.system(size: 40)).foregroundStyle(accentGold.opacity(0.08)).offset(x: 10, y: 10)
                    }
                }
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: [accentGold.opacity(0.5), accentGold.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        .shadow(color: accentGold.opacity(0.2), radius: 12, x: 0, y: 5)
        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: false)) { chipRotation = true }
            withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) { shimmer = true }
        }
    }
}
