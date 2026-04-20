import SwiftUI

// MARK: - Voting & Reveal Components

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
    let liarQuestion: String?
    let isSlowest: Bool

    // Voting Props
    var voteCount: Int = 0
    var canIncrement: Bool = true
    var onIncrement: (() -> Void)? = nil
    var onDecrement: (() -> Void)? = nil

    let onTap: () -> Void

    init(playerName: String, answer: QuestionsAnswer, isSelected: Bool, showSelectionBox: Bool, selectionEnabled: Bool, showGreenCheck: Bool, showRedX: Bool, shakeTrigger: CGFloat, isFullWidth: Bool, liarQuestion: String?, isSlowest: Bool = false, voteCount: Int = 0, canIncrement: Bool = true, onIncrement: (() -> Void)? = nil, onDecrement: (() -> Void)? = nil, onTap: @escaping () -> Void) {
        self.playerName = playerName
        self.answer = answer
        self.isSelected = isSelected
        self.showSelectionBox = showSelectionBox
        self.selectionEnabled = selectionEnabled
        self.showGreenCheck = showGreenCheck
        self.showRedX = showRedX
        self.shakeTrigger = shakeTrigger
        self.isFullWidth = isFullWidth
        self.liarQuestion = liarQuestion
        self.isSlowest = isSlowest
        self.voteCount = voteCount
        self.canIncrement = canIncrement
        self.onIncrement = onIncrement
        self.onDecrement = onDecrement
        self.onTap = onTap
    }

    var body: some View {
        ZStack(alignment: .top) {
            // Dossier-Hintergrund
            cardBackground

            VStack(spacing: 0) {
                // Header: Subjekt & Status
                headerSection
                    .padding(.horizontal, 14)
                    .padding(.top, 14)
                    .padding(.bottom, 10)

                // Divider
                Rectangle()
                    .fill(QuestionsTheme.accentGreen.opacity(0.15))
                    .frame(height: 1)
                    .padding(.horizontal, 14)

                // Antwort-Bereich
                answerSection
                    .padding(14)

                // Footer: Voting Stepper
                if showSelectionBox {
                    VoteStepper(
                        count: voteCount,
                        canIncrement: canIncrement,
                        onIncrement: onIncrement,
                        onDecrement: onDecrement
                    )
                    .padding(.bottom, 14)
                } else {
                    Spacer().frame(height: 14)
                }
            }
        }
        .frame(height: isFullWidth ? 240 : 200)
        .overlay(cardBorder)
        .modifier(ShakeEffect(animatableData: showRedX ? shakeTrigger : 0))
        .onTapGesture {
            UISelectionFeedbackGenerator().selectionChanged()
            onTap()
        }
    }

    // MARK: - Card Background

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 0.08, green: 0.07, blue: 0.05),
                        Color(red: 0.05, green: 0.04, blue: 0.03)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                // Verdächtigen-Markierung
                RoundedRectangle(cornerRadius: 12)
                    .fill(voteCount > 0 ? QuestionsTheme.accentDanger.opacity(0.1) : Color.clear)
            )
            .overlay(
                // Scanlines
                ScanLinesOverlay()
                    .opacity(0.015)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            )
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: 12)
            .stroke(
                voteCount > 0 ? QuestionsTheme.accentDanger : QuestionsTheme.accentGreen.opacity(0.15),
                lineWidth: voteCount > 0 ? 2 : 1
            )
            .shadow(color: voteCount > 0 ? QuestionsTheme.accentDanger.opacity(0.3) : .clear, radius: 8)
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack {
            // Subjekt-Label + Name
            VStack(alignment: .leading, spacing: 2) {
                Text("SUBJEKT")
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundStyle(QuestionsTheme.textMuted)
                    .tracking(1.5)

                Text(playerName.uppercased())
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundStyle(QuestionsTheme.textTypewriter)
                    .lineLimit(1)
            }

            Spacer()

            // Status-Icons
            statusIcon
        }
    }

    @ViewBuilder
    private var statusIcon: some View {
        if showGreenCheck {
            HStack(spacing: 4) {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(QuestionsTheme.accentSuccess)
                Text("VERIFIZIERT")
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundStyle(QuestionsTheme.accentSuccess)
            }
        } else if showRedX {
            HStack(spacing: 4) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(QuestionsTheme.accentDanger)
                Text("LÜGNER")
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundStyle(QuestionsTheme.accentDanger)
            }
        } else if answer.timeTaken > 0 {
            timeIndicator
        }
    }

    private var timeIndicator: some View {
        HStack(spacing: 3) {
            Image(systemName: isSlowest ? "exclamationmark.circle.fill" : "clock")
                .font(.system(size: 10))
            Text(String(format: "%.0fs", answer.timeTaken))
                .font(.system(size: 10, weight: .medium, design: .monospaced))
        }
        .foregroundStyle(isSlowest ? QuestionsTheme.accentDanger : QuestionsTheme.textMuted)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(isSlowest ? QuestionsTheme.accentDanger.opacity(0.2) : Color.white.opacity(0.05))
        )
    }

    // MARK: - Answer Section

    private var answerSection: some View {
        VStack(spacing: 6) {
            if let liarQuestion {
                Text(LocalizedStringKey(liarQuestion))
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(QuestionsTheme.accentDanger.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 2)
            }

            Text(answer.text)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(QuestionsTheme.textTypewriter)
                .multilineTextAlignment(.center)
                .lineLimit(isFullWidth ? nil : 4)
                .minimumScaleFactor(0.85)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

// MARK: - Vote Stepper

struct VoteStepper: View {
    let count: Int
    let canIncrement: Bool
    let onIncrement: (() -> Void)?
    let onDecrement: (() -> Void)?

    var body: some View {
        HStack(spacing: 16) {
            // Minus Button
            Button {
                UISelectionFeedbackGenerator().selectionChanged()
                onDecrement?()
            } label: {
                Image(systemName: "minus")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .frame(width: 44, height: 44)
                    .foregroundStyle(count == 0 ? QuestionsTheme.textMuted.opacity(0.3) : QuestionsTheme.textPrimary)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.05))
                            .overlay(
                                Circle()
                                    .stroke(QuestionsTheme.textMuted.opacity(0.2), lineWidth: 1)
                            )
                    )
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(count == 0)

            // Zentrale Anzeige
            ZStack {
                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                        .foregroundStyle(QuestionsTheme.accentDanger)
                        .shadow(color: QuestionsTheme.accentDanger.opacity(0.5), radius: 4)
                        .transition(.scale.combined(with: .opacity))
                } else {
                    Image(systemName: "fingerprint")
                        .font(.system(size: 22))
                        .foregroundStyle(QuestionsTheme.textMuted.opacity(0.4))
                }
            }
            .frame(width: 36)
            .animation(.spring(response: 0.3), value: count)

            // Plus Button
            Button {
                UISelectionFeedbackGenerator().selectionChanged()
                onIncrement?()
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .frame(width: 44, height: 44)
                    .foregroundStyle(canIncrement ? QuestionsTheme.accentGreen : QuestionsTheme.textMuted.opacity(0.3))
                    .background(
                        Circle()
                            .fill(canIncrement ? QuestionsTheme.accentGreen.opacity(0.15) : Color.white.opacity(0.05))
                            .overlay(
                                Circle()
                                    .stroke(
                                        canIncrement ? QuestionsTheme.accentGreen.opacity(0.4) : QuestionsTheme.textMuted.opacity(0.2),
                                        lineWidth: 1
                                    )
                            )
                    )
                    .shadow(color: canIncrement ? QuestionsTheme.accentGreen.opacity(0.3) : .clear, radius: 4)
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(!canIncrement)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.4))
                .overlay(
                    Capsule()
                        .stroke(QuestionsTheme.textMuted.opacity(0.1), lineWidth: 1)
                )
        )
    }
}
