import SwiftUI

// MARK: - Input & Action Components

struct QuestionsPrimaryButton: View {
    let title: String
    let action: () -> Void
    var isDisabled: Bool = false

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline.weight(.semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
        }
        .background(
            Capsule()
                .fill(QuestionsStyle.buttonGradient)
        )
        .shadow(color: .black.opacity(0.25), radius: 16, y: 8)
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.6 : 1.0)
    }
}

struct QuestionsPrimaryButtonStyle: ButtonStyle {
    var disabled: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(disabled ? Color.white.opacity(0.25) : Color.white.opacity(configuration.isPressed ? 0.8 : 1))
            )
            .foregroundColor(disabled ? Color.white.opacity(0.6) : QuestionsTheme.textAccent)
            .shadow(color: .black.opacity(disabled ? 0.0 : 0.2), radius: 12, y: 6)
            .scaleEffect(configuration.isPressed && !disabled ? 0.98 : 1.0)
    }
}

struct QuestionsPromptBoard: View {
    let question: String

    var body: some View {
        QuestionsTerminalBackground()
            .frame(height: 220)
            .overlay(
                VStack(spacing: 20) {
                    Text(LocalizedStringKey(question))
                        .font(.title2.weight(.bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                }
                .padding(24)
            )
    }
}

struct QuestionsAnswerBoard: View {
    @Binding var text: String
    var focus: FocusState<Bool>.Binding

    var body: some View {
        ZStack(alignment: .topLeading) {
            QuestionsTerminalBackground()
                .frame(maxWidth: .infinity)
            TextEditor(text: $text)
                .focused(focus)
                .scrollContentBackground(.hidden)
                .foregroundColor(.white)
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .onChange(of: text) { oldValue, newValue in
                    guard let last = newValue.last else { return }
                    if last == "\n" || last == "↵" {
                        text.removeLast()
                        focus.wrappedValue = false
                    }
                }
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("Fertig") {
                            focus.wrappedValue = false
                        }
                    }
                }
            if text.isEmpty {
                Text(LocalizedStringKey("Tippe deine Antwort…"))
                    .foregroundColor(.white.opacity(0.35))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
            }
        }
        .frame(minHeight: 150, maxHeight: 210)
    }
}

struct QuestionsSecureRevealButton: View {
    let playerName: String
    let onComplete: () -> Void
    
    @State private var isHolding = false
    @State private var progress: CGFloat = 0.0
    @State private var timer: Timer?
    @State private var showSuccess = false
    
    private let holdDuration: TimeInterval = 0.6
    
    var body: some View {
        VStack(spacing: 30) {
            
            VStack(spacing: 12) {
                Text(LocalizedStringKey("Übergabe an"))
                    .font(.subheadline)
                    .foregroundStyle(QuestionsStyle.mutedText)
                    .textCase(.uppercase)
                    .kerning(1)
                
                Text(playerName)
                    .font(.system(size: 32, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
            }
            
            ZStack {
                // Background Circle
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 8)
                    .frame(width: 120, height: 120)
                
                // Progress Circle
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        QuestionsStyle.buttonGradient,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .shadow(color: Color.red.opacity(0.5), radius: 10)
                
                // Fingerprint Icon
                Image(systemName: showSuccess ? "lock.open.fill" : "touchid")
                    .font(.system(size: 50))
                    .foregroundStyle(showSuccess ? .green : .white)
                    .scaleEffect(isHolding ? 1.1 : 1.0)
                    .animation(.spring(response: 0.3), value: isHolding)
            }
            .contentShape(Circle()) // Wichtig für Gesten
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isHolding && !showSuccess {
                            startScanning()
                        }
                    }
                    .onEnded { _ in
                        stopScanning()
                    }
            )
            
            Text(LocalizedStringKey(isHolding ? "Scan läuft..." : "Gedrückt halten zum Entsperren"))
                .font(.headline)
                .foregroundStyle(isHolding ? .white : QuestionsStyle.mutedText)
                .animation(.easeInOut, value: isHolding)
        }
        .padding(40)
        .background(QuestionsStyle.containerBackground)
        .clipShape(RoundedRectangle(cornerRadius: 30))
        .overlay(
            RoundedRectangle(cornerRadius: 30)
                .stroke(QuestionsStyle.cardStroke, lineWidth: 1)
        )
    }
    
    private func startScanning() {
        isHolding = true
        let step = 0.05
        
        // Haptisches Feedback beim Start
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        timer = Timer.scheduledTimer(withTimeInterval: step, repeats: true) { _ in
            withAnimation(.linear(duration: step)) {
                progress += CGFloat(step / holdDuration)
            }
            
            if progress >= 1.0 {
                completeScan()
            }
        }
    }
    
    private func stopScanning() {
        guard !showSuccess else { return }
        isHolding = false
        timer?.invalidate()
        timer = nil
        withAnimation(.easeOut(duration: 0.2)) {
            progress = 0.0
        }
    }
    
    private func completeScan() {
        timer?.invalidate()
        timer = nil
        showSuccess = true
        
        // Erfolgs-Haptik
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // Kurze Verzögerung für visuelles Feedback vor dem Umschalten
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onComplete()
        }
    }
}
