import SwiftUI

struct HoldToConfirmButton: View {
    var title: String = "Halten zum Bestätigen"
    var duration: Double = 1.0
    var action: () -> Void
    var disabled: Bool = false

    @State private var isPressing = false
    @State private var progress: CGFloat = 0
    @State private var timer: Timer?

    var body: some View {
        ZStack(alignment: .leading) {
            // Hintergrund
            Capsule()
                .fill(Color.white.opacity(0.08))

            // Füllstand (Grün)
            Capsule()
                .fill(disabled ? Color.gray : Color.green) // Grau wenn deaktiviert
                .frame(maxWidth: .infinity, alignment: .leading)
                .scaleEffect(x: progress, y: 1, anchor: .leading)

            HStack {
                Image(systemName: "hand.point.up.left.fill")
                    .foregroundStyle(disabled ? .white.opacity(0.3) : .white)
                Text(title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(disabled ? .white.opacity(0.3) : .white)
                Spacer()
                if !disabled {
                    Text("Halten")
                        .foregroundStyle(.white.opacity(0.7))
                        .font(.subheadline)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .frame(height: 52)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
        // WICHTIG: DragGesture erkennt Touch Down und Up sofort
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    guard !disabled else { return }
                    if !isPressing {
                        startProgress()
                    }
                }
                .onEnded { _ in
                    guard !disabled else { return }
                    stopProgress()
                }
        )
        .onDisappear {
            stopProgress()
        }
        .opacity(disabled ? 0.6 : 1.0) // Visueller Hinweis, dass deaktiviert
        .animation(.easeInOut, value: disabled)
    }

    private func startProgress() {
        isPressing = true
        progress = 0
        timer?.invalidate()
        
        // Timer feuert alle 0.02 Sekunden
        timer = Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { _ in
            withAnimation(.linear(duration: 0.02)) {
                progress += 0.02 / duration
            }
            
            // Wenn voll -> Aktion auslösen
            if progress >= 1.0 {
                completeAction()
            }
        }
    }

    private func stopProgress() {
        isPressing = false
        timer?.invalidate()
        timer = nil
        
        // Sofort zurücksetzen wenn losgelassen
        withAnimation(.easeOut(duration: 0.2)) {
            progress = 0
        }
    }
    
    private func completeAction() {
        isPressing = false
        timer?.invalidate()
        timer = nil
        progress = 1.0 // Bleibt kurz voll für Feedback
        HapticsService.success()
        action()
    }
}
