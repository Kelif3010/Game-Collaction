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
                    Text(question)
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
                Text("Tippe deine Antwort…")
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
    let onTap: () -> Void

    var body: some View {
        ZStack(alignment: .topLeading) {
            QuestionsChalkboardBackground()
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill((isSelected && selectionEnabled) ? Color.white.opacity(0.08) : Color.clear)
                )
                .overlay(
                    VStack(spacing: 10) {
                        HStack(spacing: 8) {
                            Text(playerName)
                                .font(.headline)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
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
                            Text(spyQuestion)
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
                    .padding(.bottom, 18)
                )

            if showSelectionBox {
                SelectionCheckbox(isSelected: isSelected)
                    .padding(16)
            }
        }
        .frame(height: isFullWidth ? 190 : 150)
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(
                    (isSelected && selectionEnabled) ? Color.white.opacity(0.8) : Color.white.opacity(0.25),
                    lineWidth: (isSelected && selectionEnabled) ? 2 : 1
                )
        )
        .modifier(ShakeEffect(animatableData: showRedX ? shakeTrigger : 0))
        .onTapGesture { onTap() }
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