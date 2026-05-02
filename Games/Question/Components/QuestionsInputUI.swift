import SwiftUI

// MARK: - Input & Action Components

struct QuestionsPrimaryButton: View {
    let title: String
    let action: () -> Void
    var isDisabled: Bool = false

    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            action()
        }) {
            Text(title)
                .font(.system(.headline, design: .monospaced).weight(.semibold))
                .foregroundStyle(QuestionsTheme.textOnDark)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
        }
        .background(
            Capsule()
                .fill(QuestionsStyle.buttonGradient)
        )
        .shadow(color: QuestionsTheme.accentGreen.opacity(0.3), radius: 12, y: 6)
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.5 : 1.0)
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
                    .fill(disabled ? AnyShapeStyle(QuestionsTheme.textMuted.opacity(0.3)) : AnyShapeStyle(QuestionsStyle.buttonGradient))
            )
            .foregroundStyle(disabled ? QuestionsTheme.textMuted : QuestionsTheme.textOnDark)
            .shadow(color: disabled ? .clear : QuestionsTheme.accentGreen.opacity(0.25), radius: 10, y: 4)
            .scaleEffect(configuration.isPressed && !disabled ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct QuestionsPromptBoard: View {
    let question: String

    var body: some View {
        ZStack {
            // Terminal-Hintergrund
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(QuestionsTheme.accentGreen.opacity(0.2), lineWidth: 1)
                )

            // Scanlines-Effekt
            ScanLinesOverlay()
                .opacity(0.02)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(spacing: 16) {
                // Header
                HStack {
                    Circle()
                        .fill(QuestionsTheme.accentGreen)
                        .frame(width: 6, height: 6)
                        .shadow(color: QuestionsTheme.accentGreen, radius: 3)
                    Text("AKTIVE ABFRAGE")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundStyle(QuestionsTheme.accentGreen)
                        .tracking(2)
                    Spacer()
                }

                Text(LocalizedStringKey(question))
                    .font(.system(.title3, design: .monospaced).weight(.bold))
                    .foregroundStyle(QuestionsTheme.textTypewriter)
                    .multilineTextAlignment(.center)
            }
            .padding(24)
        }
        .frame(height: 220)
    }
}

struct QuestionsAnswerBoard: View {
    @Binding var text: String
    var focus: FocusState<Bool>.Binding

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Terminal-Hintergrund
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(
                            focus.wrappedValue
                                ? QuestionsTheme.accentGreen.opacity(0.5)
                                : QuestionsTheme.accentGreen.opacity(0.15),
                            lineWidth: 1
                        )
                )
                .animation(.easeOut(duration: 0.2), value: focus.wrappedValue)

            VStack(alignment: .leading, spacing: 8) {
                // Header
                HStack {
                    Text("EINGABE:")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundStyle(QuestionsTheme.textMuted)
                        .tracking(2)
                    Spacer()
                    if focus.wrappedValue {
                        Circle()
                            .fill(QuestionsTheme.accentGreen)
                            .frame(width: 6, height: 6)
                            .shadow(color: QuestionsTheme.accentGreen, radius: 3)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)

                TextEditor(text: $text)
                    .focused(focus)
                    .scrollContentBackground(.hidden)
                    .foregroundStyle(QuestionsTheme.textTypewriter)
                    .font(.system(.body, design: .monospaced))
                    .padding(.horizontal, 12)
                    .padding(.bottom, 12)
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
                            Button {
                                focus.wrappedValue = false
                            } label: {
                                Text("BESTÄTIGEN")
                                    .font(.system(.subheadline, design: .monospaced).weight(.medium))
                                    .foregroundStyle(QuestionsTheme.accentGreen)
                            }
                        }
                    }
            }

            // Placeholder
            if text.isEmpty {
                Text(LocalizedStringKey("Antwort eingeben..."))
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(QuestionsTheme.textMuted.opacity(0.6))
                    .padding(.horizontal, 16)
                    .padding(.top, 38)
                    .allowsHitTesting(false)
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
    @State private var pulseAnimation = false

    private let holdDuration: TimeInterval = 0.6

    var body: some View {
        VStack(spacing: 28) {
            // Header
            VStack(spacing: 6) {
                Text("BIOMETRISCHE AUTORISIERUNG")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(QuestionsTheme.accentGreen)
                    .tracking(3)

                Rectangle()
                    .fill(QuestionsTheme.accentGreen.opacity(0.3))
                    .frame(height: 1)
                    .padding(.horizontal, 40)
            }

            // Subject Name
            VStack(spacing: 8) {
                Text("SUBJEKT:")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(QuestionsTheme.textMuted)
                    .tracking(2)

                Text(playerName.uppercased())
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .foregroundStyle(QuestionsTheme.textTypewriter)
                    .tracking(1)
            }

            // Fingerprint Scanner
            ZStack {
                // Outer Ring - Pulse
                Circle()
                    .stroke(QuestionsTheme.accentGreen.opacity(0.1), lineWidth: 2)
                    .frame(width: 140, height: 140)
                    .scaleEffect(pulseAnimation ? 1.1 : 1.0)
                    .opacity(pulseAnimation ? 0 : 0.5)

                // Background Ring
                Circle()
                    .stroke(QuestionsTheme.textMuted.opacity(0.2), lineWidth: 6)
                    .frame(width: 120, height: 120)

                // Progress Ring
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        LinearGradient(
                            colors: [
                                QuestionsTheme.accentGreen,
                                QuestionsTheme.accentGreen.opacity(0.7)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .shadow(color: QuestionsTheme.accentGreen.opacity(0.5), radius: 8)

                // Icon
                Image(systemName: showSuccess ? "checkmark.shield.fill" : "touchid")
                    .font(.system(size: 44))
                    .foregroundStyle(
                        showSuccess
                            ? QuestionsTheme.accentSuccess
                            : (isHolding ? QuestionsTheme.accentGreen : QuestionsTheme.textMuted)
                    )
                    .scaleEffect(isHolding ? 1.1 : 1.0)
                    .animation(.spring(response: 0.3), value: isHolding)
                    .shadow(
                        color: isHolding ? QuestionsTheme.accentGreen.opacity(0.5) : .clear,
                        radius: 10
                    )
            }
            .contentShape(Circle())
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
            .onAppear {
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                    pulseAnimation = true
                }
            }

            // Status Text
            VStack(spacing: 4) {
                Text(statusText)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(isHolding ? QuestionsTheme.accentGreen : QuestionsTheme.textMuted)
                    .tracking(1)

                if !isHolding && !showSuccess {
                    Text("FINGERABDRUCK ERFORDERLICH")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(QuestionsTheme.textMuted.opacity(0.6))
                        .tracking(2)
                }
            }
            .animation(.easeInOut, value: isHolding)
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 36)
        .background(dossierBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(QuestionsTheme.accentGreen.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.4), radius: 20, y: 10)
    }

    private var statusText: LocalizedStringKey {
        if showSuccess {
            return "AUTORISIERUNG ERFOLGREICH"
        } else if isHolding {
            return "IDENTIFIKATION LÄUFT..."
        } else {
            return "GEDRÜCKT HALTEN"
        }
    }

    private var dossierBackground: some View {
        LinearGradient(
            colors: [
                Color(red: 0.12, green: 0.10, blue: 0.08),
                Color(red: 0.08, green: 0.07, blue: 0.05)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private func startScanning() {
        isHolding = true
        let step = 0.05

        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        timer = Timer.scheduledTimer(withTimeInterval: step, repeats: true) { _ in
            Task { @MainActor in
                withAnimation(.linear(duration: step)) {
                    progress += CGFloat(step / holdDuration)
                }
                // Leichte Haptik während des Scans
                if Int(progress * 10) % 2 == 0 {
                    UISelectionFeedbackGenerator().selectionChanged()
                }
                if progress >= 1.0 {
                    completeScan()
                }
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

        UINotificationFeedbackGenerator().notificationOccurred(.success)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            onComplete()
        }
    }
}

