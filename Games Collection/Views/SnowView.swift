import SwiftUI

struct SnowParticle: Identifiable {
    var id = UUID()
    var x: Double
    var y: Double
    var size: Double
    var speed: Double
    var opacity: Double
}

struct SnowView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var particles: [SnowParticle] = []
    @State private var isAnimating = true

    static var isCurrentlyWinter: Bool {
        let month = Calendar.current.component(.month, from: Date())
        return month == 12 || month == 1 || month == 2
    }

    var body: some View {
        GeometryReader { _ in
            TimelineView(.animation(paused: !isAnimating)) { context in
                Canvas { drawCtx, size in
                    for particle in particles {
                        let rect = CGRect(
                            x: particle.x * size.width,
                            y: particle.y * size.height,
                            width: particle.size,
                            height: particle.size
                        )
                        drawCtx.opacity = particle.opacity
                        drawCtx.fill(Path(ellipseIn: rect), with: .color(.white))
                    }
                }
                .onChange(of: context.date) { _, _ in
                    guard isAnimating else { return }
                    updateParticles()
                }
            }
            .onAppear {
                for _ in 0..<50 {
                    particles.append(createParticle())
                }
            }
            .onChange(of: scenePhase) { _, newPhase in
                isAnimating = (newPhase == .active)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    private func createParticle() -> SnowParticle {
        SnowParticle(
            x: Double.random(in: 0...1),
            y: Double.random(in: -0.2...0),
            size: Double.random(in: 2...6),
            speed: Double.random(in: 0.001...0.005),
            opacity: Double.random(in: 0.3...0.8)
        )
    }

    private func updateParticles() {
        for i in 0..<particles.count {
            particles[i].y += particles[i].speed
            if particles[i].y > 1.0 {
                particles[i].y = Double.random(in: -0.2...0)
                particles[i].x = Double.random(in: 0...1)
            }
        }
    }
}
