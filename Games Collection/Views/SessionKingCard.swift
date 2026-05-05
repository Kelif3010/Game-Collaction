import SwiftUI

struct SessionKingCard: View {
    let name: String
    let wins: Int

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [.yellow, .orange], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 50, height: 50)
                Image(systemName: "crown.fill")
                    .font(.title3)
                    .foregroundStyle(.white)
            }
            .shadow(color: .orange.opacity(0.3), radius: 5)

            VStack(alignment: .leading, spacing: 2) {
                Text(LocalizedStringKey("King of the Session"))
                    .font(.caption.bold())
                    .foregroundStyle(.orange)
                    .textCase(.uppercase)
                Text(name)
                    .font(.title3.bold())
                    .foregroundStyle(.white)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(wins)")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                Text(wins == 1 ? LocalizedStringKey("Sieg") : LocalizedStringKey("Siege"))
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
        .padding()
        .background(.white.opacity(0.08))
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(
                    LinearGradient(colors: [.yellow.opacity(0.5), .clear], startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: 1
                )
        )
    }
}
