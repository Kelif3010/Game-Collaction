import SwiftUI

struct QuestionsOnboardingSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onFinish: () -> Void

    @State private var currentIndex = 0

    private let pages: [QuestionsOnboardingPage] = [
        QuestionsOnboardingPage(
            title: "Das Team scannen",
            message: "Waehle die Teilnehmer, die Anzahl der Luegner und das Thema.",
            detail: "Mindestens 3 Personen benoetigt.",
            systemImage: "person.3.fill",
            accent: Color.blue
        ),
        QuestionsOnboardingPage(
            title: "Die nackte Wahrheit",
            message: "Jeder sieht geheim seine eigene Frage.",
            detail: "Keine Einblicke gewaehren.",
            systemImage: "eye.slash.fill",
            accent: Color.orange
        ),
        QuestionsOnboardingPage(
            title: "Aussage und Analyse",
            message: "Jeder gibt eine Antwort ein. Die Zeit laeuft mit.",
            detail: "Danach beginnt das Verhoer.",
            systemImage: "bubble.left.and.bubble.right.fill",
            accent: Color.pink
        ),
        QuestionsOnboardingPage(
            title: "Das Urteil",
            message: "Identifiziert die Luegner im Team.",
            detail: "Der Luegendetektor deckt alles auf.",
            systemImage: "waveform.path.ecg",
            accent: Color.green
        )
    ]

    var body: some View {
        ZStack {
            QuestionsStyle.backgroundGradient.ignoresSafeArea()

            VStack(spacing: 0) {
                QuestionsSheetHeader(title: "Anleitung") {
                    dismiss()
                }
                .padding(.horizontal, QuestionsStyle.padding)

                VStack(spacing: 20) {
                    QuestionsOnboardingProgress(currentIndex: currentIndex, count: pages.count)

                    TabView(selection: $currentIndex) {
                        ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                            QuestionsOnboardingCard(page: page, step: index + 1, total: pages.count)
                                .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .frame(height: 280)

                    QuestionsPrimaryButton(
                        title: currentIndex == pages.count - 1 ? "Los geht's" : "Weiter",
                        action: advance
                    )
                }
                .padding(.horizontal, QuestionsStyle.padding)
                .padding(.bottom, 24)
            }
        }
    }

    private func advance() {
        if currentIndex < pages.count - 1 {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                currentIndex += 1
            }
        } else {
            onFinish()
            dismiss()
        }
    }
}

private struct QuestionsOnboardingPage {
    let title: String
    let message: String
    let detail: String
    let systemImage: String
    let accent: Color
}

private struct QuestionsOnboardingProgress: View {
    let currentIndex: Int
    let count: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<count, id: \.self) { index in
                Capsule()
                    .fill(index == currentIndex ? Color.white.opacity(0.9) : Color.white.opacity(0.25))
                    .frame(width: index == currentIndex ? 26 : 10, height: 6)
            }
        }
    }
}

private struct QuestionsOnboardingCard: View {
    let page: QuestionsOnboardingPage
    let step: Int
    let total: Int

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: QuestionsStyle.containerCornerRadius, style: .continuous)
                .fill(Color.white.opacity(0.04))
                .offset(x: 10, y: 10)

            RoundedRectangle(cornerRadius: QuestionsStyle.containerCornerRadius, style: .continuous)
                .fill(QuestionsStyle.containerBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: QuestionsStyle.containerCornerRadius, style: .continuous)
                        .stroke(QuestionsStyle.cardStroke, lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [page.accent.opacity(0.9), page.accent.opacity(0.4)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        Image(systemName: page.systemImage)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .frame(width: 52, height: 52)

                    Spacer()

                    Text("Schritt \(step)/\(total)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(QuestionsStyle.mutedText)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.08))
                        )
                }

                Text(page.title)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)

                Text(page.message)
                    .font(.callout)
                    .foregroundStyle(QuestionsStyle.mutedText)

                Text(page.detail)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.85))

                Spacer()
            }
            .padding(22)
        }
        .padding(.horizontal, 4)
    }
}
