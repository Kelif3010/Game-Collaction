//
//  QuestionsTheme.swift
//  Question
//
//  Created by Ken  on 27.12.25.
//


import SwiftUI

// MARK: - Design Theme
enum QuestionsTheme {
    static let gradient = LinearGradient(
        colors: [
            Color(red: 0.12, green: 0.02, blue: 0.18),
            Color(red: 0.5, green: 0.0, blue: 0.25),
            Color(red: 0.75, green: 0.0, blue: 0.23)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let accent = Color.white
    static let textAccent = Color(red: 0.22, green: 0.02, blue: 0.14)
}

// MARK: - Shared Style Constants (Matches Imposter/BetBuddy)
enum QuestionsStyle {
    static let backgroundGradient = QuestionsTheme.gradient
    
    // Using the same "dark glass" constants as Imposter for consistency
    static let containerBackground = Color.black.opacity(0.25)
    static let rowBackground = Color.black.opacity(0.25)
    static let cardStroke = Color.white.opacity(0.08)
    static let containerCornerRadius: CGFloat = 22
    static let rowCornerRadius: CGFloat = 18
    static let padding: CGFloat = 20
    static let mutedText = Color.white.opacity(0.7)
    
    static let primaryGradient = LinearGradient(
        colors: [Color(red: 1.0, green: 0.41, blue: 0.23), Color(red: 0.94, green: 0.16, blue: 0.47)], // Keep Imposter orange/pink or custom? Let's use custom for Questions identity
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // Custom button gradient for Questions (Red/Purple) to distinguish from Imposter (Orange)
    static let buttonGradient = LinearGradient(
         colors: [Color(red: 0.99, green: 0.35, blue: 0.38), Color(red: 0.78, green: 0.12, blue: 0.42)],
         startPoint: .topLeading,
         endPoint: .bottomTrailing
    )
}

// MARK: - Shared Components (Matches Imposter/BetBuddy)

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

struct QuestionsSheetHeader: View {
    let title: String
    let onBack: () -> Void

    var body: some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.headline.bold())
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
            }

            Spacer()

            Text(title)
                .font(.title3.bold())
                .foregroundStyle(.white)

            Spacer()

            Color.clear
                .frame(width: 36, height: 36)
        }
        .padding(.top, 20)
        .padding(.bottom, 8)
    }
}

struct QuestionsIconBadge: View {
    let systemName: String
    let tint: Color

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [tint.opacity(0.35), tint.opacity(0.15)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            Image(systemName: systemName)
                .foregroundColor(tint)
                .font(.system(size: 18, weight: .semibold))
        }
        .frame(width: 44, height: 44)
    }
}

struct QuestionsGroupedCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 12) {
            content
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: QuestionsStyle.containerCornerRadius, style: .continuous)
                .fill(QuestionsStyle.containerBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: QuestionsStyle.containerCornerRadius, style: .continuous)
                .stroke(QuestionsStyle.cardStroke, lineWidth: 1)
        )
    }
}

struct QuestionsRowCell: View {
    let icon: String
    let title: String
    let value: String
    var tint: Color = .white
    var showsChevron: Bool = true

    var body: some View {
        HStack(spacing: 12) {
            QuestionsIconBadge(systemName: icon, tint: tint)
            Text(title)
                .font(.body)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            Spacer()
            Text(value)
                .font(.callout)
                .foregroundStyle(QuestionsStyle.mutedText)
            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.footnote)
                    .foregroundStyle(QuestionsStyle.mutedText)
            }
        }
        .questionsRowStyle()
    }
}

extension View {
    func questionsRowStyle() -> some View {
        self
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: QuestionsStyle.rowCornerRadius, style: .continuous)
                    .fill(QuestionsStyle.rowBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: QuestionsStyle.rowCornerRadius, style: .continuous)
                    .stroke(QuestionsStyle.cardStroke, lineWidth: 1)
            )
    }
}

// MARK: - Reusable UI Components

struct QuestionsFlipCard: View {
    let title: String

    var body: some View {
        RoundedRectangle(cornerRadius: 32, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 0.99, green: 0.35, blue: 0.38),
                        Color(red: 0.78, green: 0.12, blue: 0.42)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                Text(title)
                    .font(.system(size: 40, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
            )
            .frame(height: 200)
            .shadow(color: Color.black.opacity(0.3), radius: 20, y: 10)
    }
}

struct QuestionsPromptBoard: View {
    let question: String

    var body: some View {
        QuestionsChalkboardBackground()
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
            QuestionsChalkboardBackground()
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

struct QuestionsChalkboardBackground: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 0.02, green: 0.02, blue: 0.05),
                        Color(red: 0.08, green: 0.08, blue: 0.16)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(Color.white.opacity(0.15), lineWidth: 1.2)
            )
            .shadow(color: .black.opacity(0.35), radius: 20, y: 10)
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

struct QuestionsAnswerRevealCard: View {
    let playerName: String
    let answer: QuestionsAnswer
    let isSelected: Bool
    let showSelectionBox: Bool
    let selectionEnabled: Bool
    let showGreenCheck: Bool
    let showRedX: Bool
    let shakeTrigger: CGFloat
    let isFullWidth: Bool
    let spyQuestion: String?
    
    // Voting Props
    var voteCount: Int = 0
    var canIncrement: Bool = true
    var onIncrement: (() -> Void)? = nil
    var onDecrement: (() -> Void)? = nil
    
    let onTap: () -> Void

    var body: some View {
        ZStack(alignment: .topLeading) {
            QuestionsChalkboardBackground()
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill((isSelected && selectionEnabled && voteCount == 0) ? Color.white.opacity(0.08) : Color.clear)
                )
                .overlay(
                    VStack(spacing: 10) {
                        HStack(spacing: 8) {
                            Text(LocalizedStringKey(playerName))
                                .font(.headline)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                            
                            if answer.timeTaken > 0 {
                                Text(String(format: NSLocalizedString("Zeit: %.1fs", comment: ""), answer.timeTaken))
                                    .font(.caption2.monospacedDigit())
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(answer.timeTaken > 20 ? Color.orange.opacity(0.8) : Color.white.opacity(0.2))
                                    .cornerRadius(4)
                                    .foregroundColor(.white)
                            }
                            
                            if showGreenCheck {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            } else if showRedX {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .center)

                        if let spyQuestion {
                            Text(LocalizedStringKey(spyQuestion))
                                .font(.callout.weight(.medium))
                                .foregroundColor(.white.opacity(0.9))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 4)
                        }

                        Text(answer.text)
                            .font(.body)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .lineLimit(4)
                            .minimumScaleFactor(0.85)

                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 26)
                    .padding(.bottom, showSelectionBox ? 50 : 18) // Platz für Stepper machen
                )

            if showSelectionBox {
                VStack {
                    Spacer()
                    VoteStepper(
                        count: voteCount,
                        canIncrement: canIncrement,
                        onIncrement: onIncrement,
                        onDecrement: onDecrement
                    )
                    .padding(.bottom, 12)
                }
            }
        }
        .frame(height: isFullWidth ? 210 : 170) // Etwas höher für Stepper
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(
                    (voteCount > 0)
                    ? AnyShapeStyle(QuestionsStyle.buttonGradient)
                    : AnyShapeStyle(Color.white.opacity(0.25)),
                    lineWidth: (voteCount > 0) ? 3 : 1
                )
        )
        .modifier(ShakeEffect(animatableData: showRedX ? shakeTrigger : 0))
        .onTapGesture { onTap() }
    }
}

struct VoteStepper: View {
    let count: Int
    let canIncrement: Bool
    let onIncrement: (() -> Void)?
    let onDecrement: (() -> Void)?
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: { onDecrement?() }) {
                Image(systemName: "minus")
                    .font(.system(size: 14, weight: .bold))
                    .frame(width: 32, height: 32)
                    .background(Color.white.opacity(0.15))
                    .foregroundColor(.white)
                    .clipShape(Circle())
            }
            .buttonStyle(PlainButtonStyle())
            
            Text("\(count)")
                .font(.title3.bold())
                .foregroundColor(.white)
                .frame(minWidth: 20)
            
            Button(action: { if canIncrement { onIncrement?() } }) {
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .bold))
                    .frame(width: 32, height: 32)
                    .background(canIncrement ? Color.white : Color.white.opacity(0.3))
                    .foregroundColor(canIncrement ? QuestionsTheme.textAccent : QuestionsTheme.textAccent.opacity(0.5))
                    .clipShape(Circle())
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(!canIncrement)
        }
        .padding(6)
        .background(Color.black.opacity(0.3))
        .clipShape(Capsule())
    }
}

struct SelectionCheckbox: View {
    let isSelected: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.white.opacity(0.85), lineWidth: 1.5)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(isSelected ? Color.white.opacity(0.2) : Color.clear)
                )
            if isSelected {
                Image(systemName: "checkmark")
                    .foregroundColor(.white)
                    .font(.caption.bold())
            }
        }
        .frame(width: 28, height: 28)
    }
}

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

struct QuestionsSecureRevealButton: View {
    let playerName: String
    let onComplete: () -> Void
    
    @State private var isHolding = false
    @State private var progress: CGFloat = 0.0
    @State private var timer: Timer?
    @State private var showSuccess = false
    
    private let holdDuration: TimeInterval = 1.5
    
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
