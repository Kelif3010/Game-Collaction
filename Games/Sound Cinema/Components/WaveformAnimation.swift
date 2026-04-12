import SwiftUI

// MARK: - Pulsierende Schallwellen-Animation
struct WaveformAnimation: View {
    var isActive: Bool
    var progress: Double     // 1.0 = voll, 0.0 = leer
    var accentColor: Color = SoundCinemaStyle.accentCyan
    var barCount: Int = 18

    @State private var phases: [Double] = []

    var body: some View {
        GeometryReader { geo in
            HStack(alignment: .center, spacing: geo.size.width / CGFloat(barCount * 2 + 1)) {
                ForEach(0..<barCount, id: \.self) { i in
                    bar(index: i, totalWidth: geo.size.width, totalHeight: geo.size.height)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear {
            phases = (0..<barCount).map { Double($0) * 0.22 }
            guard isActive else { return }
            startAnimating()
        }
        .onChange(of: isActive) { _, active in
            if active { startAnimating() }
        }
    }

    private func bar(index: Int, totalWidth: CGFloat, totalHeight: CGFloat) -> some View {
        let phase = phases.indices.contains(index) ? phases[index] : 0.0
        // Amplituden-Kurve: Mitte höher, Ränder niedriger
        let centerFactor = 1.0 - abs(Double(index) - Double(barCount) / 2.0) / (Double(barCount) / 2.0) * 0.4
        let amplitude = isActive ? sin(phase) * 0.5 + 0.5 : 0.12
        let height = max(4, totalHeight * CGFloat(amplitude * centerFactor))

        // Farbe abhängig vom verbleibenden Timer-Fortschritt
        let barColor: Color = {
            if progress > 0.5 { return accentColor }
            if progress > 0.25 { return .yellow }
            return .red
        }()

        return Capsule()
            .fill(barColor.opacity(0.7 + amplitude * 0.3))
            .frame(width: max(3, totalWidth / CGFloat(barCount * 2)), height: height)
            .animation(.easeInOut(duration: 0.12), value: height)
    }

    private func startAnimating() {
        guard isActive else { return }
        let timer = Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { _ in
            for i in 0..<phases.count {
                phases[i] += Double.random(in: 0.3...0.9)
            }
        }
        // Timer läuft bis View verschwindet — Task würde hier zu viel Overhead machen
        RunLoop.main.add(timer, forMode: .common)
    }
}

// MARK: - Kreisförmiger Timer
struct CircularTimerRing: View {
    var progress: Double       // 1.0 = voll, 0.0 = leer
    var timeRemaining: Int
    var lineWidth: CGFloat = 6

    private var ringColor: Color {
        if progress > 0.5 { return SoundCinemaStyle.accentCyan }
        if progress > 0.25 { return .yellow }
        return .red
    }

    var body: some View {
        ZStack {
            // Hintergrings-Track
            Circle()
                .stroke(Color.white.opacity(0.08), lineWidth: lineWidth)

            // Fortschritts-Ring
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    ringColor,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1.0), value: progress)

            // Sekunden-Zahl
            Text("\(timeRemaining)")
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundStyle(ringColor)
                .contentTransition(.numericText())
                .animation(.easeInOut(duration: 0.3), value: timeRemaining)
        }
    }
}

// MARK: - Leben-Anzeige
struct LivesDisplay: View {
    var lives: Int
    var maxLives: Int
    var isEliminated: Bool = false

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<maxLives, id: \.self) { i in
                Image(systemName: i < lives ? "heart.fill" : "heart")
                    .font(.system(size: 13))
                    .foregroundStyle(i < lives ? Color.red : Color.white.opacity(0.2))
                    .scaleEffect(i < lives ? 1.0 : 0.8)
            }
        }
    }
}
