import SwiftUI

struct OnboardingView: View {
    @Environment(\.dismiss) var dismiss
    @AppStorage("myPlayerName") private var myPlayerName = ""
    @AppStorage("hasSeenOnboarding") var hasSeenOnboarding = false
    
    @State private var nameInput = ""
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // 1. Hintergrund: Unscharf und abgedunkelt, lässt die App "erahnen" oder nutzt eigenen Style
            ImposterStyle.backgroundGradient
                .ignoresSafeArea()
                .overlay(.ultraThinMaterial) // Milchglas-Effekt
            
            // 2. Die "Willkommens-Karte"
            VStack(spacing: 32) {
                
                // Icon Header
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 100, height: 100)
                        .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                    
                    Image(systemName: "hand.wave.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(.white)
                }
                .padding(.top, 20)
                
                // Text Content
                VStack(spacing: 12) {
                    Text("Herzlich Willkommen!")
                        .font(.title2.bold())
                        .foregroundStyle(.primary)
                    
                    Text("Schön, dass du da bist.\nVerrate uns deinen Namen, um zu starten.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal)
                
                // Input Area
                VStack(spacing: 16) {
                    TextField("Dein Spielername", text: $nameInput)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.blue.opacity(nameInput.isEmpty ? 0 : 0.5), lineWidth: 2)
                        )
                        .submitLabel(.done)
                    
                    Button {
                        completeOnboarding()
                    } label: {
                        Text("Loslegen")
                            .font(.headline.bold())
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing)
                            )
                            .cornerRadius(16)
                            .shadow(color: .blue.opacity(0.3), radius: 8, y: 4)
                    }
                    .disabled(nameInput.trimmingCharacters(in: .whitespaces).isEmpty)
                    .opacity(nameInput.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1.0)
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 32)
                    .fill(Color(.systemBackground)) // Passt sich Light/Dark Mode an
                    .shadow(color: .black.opacity(0.25), radius: 25, x: 0, y: 10)
            )
            .padding(24)
            .scaleEffect(isAnimating ? 1.0 : 0.9)
            .opacity(isAnimating ? 1.0 : 0.0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7, blendDuration: 0)) {
                isAnimating = true
            }
        }
    }
    
    private func completeOnboarding() {
        let trimmed = nameInput.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        
        // Haptic Feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        myPlayerName = trimmed
        
        // Animation beim Schließen
        withAnimation(.easeOut(duration: 0.3)) {
            isAnimating = false
        }
        
        // Kurze Verzögerung, damit die Animation sichtbar ist, bevor die View verschwindet
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation {
                hasSeenOnboarding = true
            }
        }
    }
}

#Preview {
    OnboardingView()
}