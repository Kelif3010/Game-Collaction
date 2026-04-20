import SwiftUI

// MARK: - Shared Components

struct QuestionsSheetHeader: View {
    let title: String
    let onBack: () -> Void

    var body: some View {
        HStack {
            Button(action: {
                UISelectionFeedbackGenerator().selectionChanged()
                onBack()
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundStyle(QuestionsTheme.textPrimary)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.08))
                            .overlay(
                                Circle()
                                    .stroke(QuestionsTheme.accentGreen.opacity(0.2), lineWidth: 1)
                            )
                    )
            }

            Spacer()

            Text(title.uppercased())
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundStyle(QuestionsTheme.textTypewriter)
                .tracking(2)

            Spacer()

            Color.clear
                .frame(width: 44, height: 44)
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
            RoundedRectangle(cornerRadius: 10)
                .fill(
                    LinearGradient(
                        colors: [tint.opacity(0.25), tint.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(tint.opacity(0.3), lineWidth: 1)
                )

            Image(systemName: systemName)
                .foregroundStyle(tint)
                .font(.system(size: 16, weight: .semibold))
        }
        .frame(width: 40, height: 40)
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
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.06, green: 0.05, blue: 0.04),
                            Color(red: 0.04, green: 0.03, blue: 0.02)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(QuestionsTheme.accentGreen.opacity(0.12), lineWidth: 1)
        )
    }
}

struct QuestionsRowCell: View {
    let icon: String
    let title: String
    let value: String
    var tint: Color = QuestionsTheme.accentGreen
    var showsChevron: Bool = true

    var body: some View {
        HStack(spacing: 12) {
            QuestionsIconBadge(systemName: icon, tint: tint)

            Text(title)
                .font(.system(.body, design: .monospaced).weight(.medium))
                .foregroundStyle(QuestionsTheme.textPrimary)

            Spacer()

            Text(value)
                .font(.system(.callout, design: .monospaced))
                .foregroundStyle(QuestionsTheme.textMuted)

            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(QuestionsTheme.textMuted.opacity(0.6))
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
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.black.opacity(0.3))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(QuestionsTheme.accentGreen.opacity(0.1), lineWidth: 1)
            )
    }
}

struct QuestionsFlipCard: View {
    let title: String

    var body: some View {
        ZStack {
            // Dossier-Hintergrund
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.12, green: 0.10, blue: 0.08),
                            Color(red: 0.08, green: 0.06, blue: 0.04)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // Scanlines
            ScanLinesOverlay()
                .opacity(0.02)
                .clipShape(RoundedRectangle(cornerRadius: 16))

            // Content
            VStack(spacing: 12) {
                // "GEHEIM" Header
                Text("GEHEIM")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(QuestionsTheme.accentDanger)
                    .tracking(3)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .overlay(
                        Rectangle()
                            .stroke(QuestionsTheme.accentDanger.opacity(0.5), lineWidth: 1)
                    )

                // Titel
                Text(title.uppercased())
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .foregroundStyle(QuestionsTheme.textTypewriter)
                    .tracking(2)
                    .multilineTextAlignment(.center)

                // Dekoration
                Rectangle()
                    .fill(QuestionsTheme.accentGreen.opacity(0.3))
                    .frame(width: 60, height: 2)
            }
            .padding(24)
        }
        .frame(height: 200)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(QuestionsTheme.accentGreen.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.4), radius: 20, y: 10)
    }
}

struct QuestionsTerminalBackground: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 0.06, green: 0.05, blue: 0.04),
                        Color(red: 0.03, green: 0.03, blue: 0.02)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                // Scanlines statt Grid
                ScanLinesOverlay()
                    .opacity(0.02)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(QuestionsTheme.accentGreen.opacity(0.15), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.3), radius: 16, y: 8)
    }
}

struct QuestionsHintBanner: View {
    let text: String
    let actionTitle: String
    let onDismiss: () -> Void

    var body: some View {
        Button(action: {
            UISelectionFeedbackGenerator().selectionChanged()
            onDismiss()
        }) {
            HStack(spacing: 12) {
                // System-Icon
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(QuestionsTheme.accentGreen)

                // Text
                VStack(alignment: .leading, spacing: 2) {
                    Text("SYSTEM")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(QuestionsTheme.accentGreen)
                        .tracking(2)

                    Text(text)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(QuestionsTheme.textPrimary)
                        .lineLimit(2)
                }

                Spacer(minLength: 0)

                // Action
                Text(actionTitle.uppercased())
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(QuestionsTheme.accentGreen)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .stroke(QuestionsTheme.accentGreen.opacity(0.4), lineWidth: 1)
                    )
            }
            .padding(14)
        }
        .buttonStyle(.plain)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.black.opacity(0.7))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(QuestionsTheme.accentGreen.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.3), radius: 12, y: 6)
    }
}
