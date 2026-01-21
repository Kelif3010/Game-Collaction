import SwiftUI

// MARK: - Visual Effects & 3D Components

struct ShakeEffect: GeometryEffect {
    var amount: CGFloat = 8
    var shakesPerUnit: CGFloat = 3
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(
            CGAffineTransform(translationX: amount * sin(animatableData * .pi * shakesPerUnit), y: 0)
        )
    }
}

// Improved 3D Coin with Front and Back
struct Coin3D: View {
    let frontText: String
    let backText: String
    let finalRotation: Double
    let onFinish: () -> Void
    
    @State private var degree: Double = 0
    
    var body: some View {
        ZStack {
            // Back Side (Candidate 2)
            CoinFace(text: backText, color: .red)
                .rotation3DEffect(.degrees(180), axis: (x: 1, y: 0, z: 0))
            
            // Front Side (Candidate 1)
            CoinFace(text: frontText, color: .blue)
        }
        .rotation3DEffect(.degrees(degree), axis: (x: 1, y: 0, z: 0))
        .onAppear {
            let generator = UIImpactFeedbackGenerator(style: .rigid)
            generator.impactOccurred()
            
            withAnimation(.spring(response: 2.5, dampingFraction: 0.5)) {
                degree = finalRotation
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                onFinish()
            }
        }
    }
}

struct CoinFace: View {
    let text: String
    let color: Color
    
    var body: some View {
        ZStack {
            Circle().fill(color)
            Circle().strokeBorder(.white.opacity(0.3), lineWidth: 4)
            Text(text)
                .font(.title.bold())
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding()
        }
        .frame(width: 220, height: 220)
    }
}
