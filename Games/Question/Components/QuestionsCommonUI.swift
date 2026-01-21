import SwiftUI

// MARK: - Shared Components

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

struct QuestionsTerminalBackground: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 0.05, green: 0.05, blue: 0.1),
                        Color(red: 0.02, green: 0.02, blue: 0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                // Subtle Grid Effect
                ZStack {
                    VStack(spacing: 4) {
                        ForEach(0..<40) { _ in
                            Divider().background(Color.white.opacity(0.03))
                        }
                    }
                    HStack(spacing: 4) {
                        ForEach(0..<40) { _ in
                            Divider().background(Color.white.opacity(0.03))
                        }
                    }
                }
                .clipped()
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(Color.white.opacity(0.15), lineWidth: 1.2)
            )
            .shadow(color: .black.opacity(0.35), radius: 20, y: 10)
    }
}

struct QuestionsHintBanner: View {
    let text: String
    let actionTitle: String
    let onDismiss: () -> Void

    var body: some View {
        Button(action: onDismiss) {
            HStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(QuestionsStyle.primaryGradient)
                    )
                Text(text)
                    .font(.callout)
                    .foregroundStyle(.white)
                Spacer(minLength: 0)
                Text(actionTitle)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(QuestionsStyle.mutedText)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
        .background(
            RoundedRectangle(cornerRadius: QuestionsStyle.rowCornerRadius, style: .continuous)
                .fill(QuestionsStyle.rowBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: QuestionsStyle.rowCornerRadius, style: .continuous)
                .stroke(QuestionsStyle.cardStroke, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.2), radius: 16, y: 8)
    }
}
