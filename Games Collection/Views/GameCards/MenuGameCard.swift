import SwiftUI

struct MenuGameCard: View {
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey
    let icon: String
    let gradient: LinearGradient

    @State private var hourglassFlipped = false
    @State private var hourglassTimer: Timer?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                Circle()
                    .fill(.white.opacity(0.2))
                    .frame(width: 50, height: 50)
                Image(systemName: hourglassFlipped ? "hourglass.bottomhalf.filled" : "hourglass.tophalf.filled")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .symbolEffect(.bounce, value: hourglassFlipped)
                    .rotationEffect(.degrees(hourglassFlipped ? 180 : 0))
                    .animation(.easeInOut(duration: 0.6), value: hourglassFlipped)
            }

            Spacer()

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.title3.bold())
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 160)
        .padding()
        .onAppear {
            hourglassTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
                Task { @MainActor in hourglassFlipped.toggle() }
            }
        }
        .onDisappear {
            hourglassTimer?.invalidate()
            hourglassTimer = nil
        }
        .background(gradient.opacity(0.6), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .compatibleGlassCardEffect(cornerRadius: 24)
        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
    }
}
