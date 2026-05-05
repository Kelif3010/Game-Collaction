//
//  QuestionsTVOverviewView.swift
//  Games Collection
//
//  Overview / Voting + Antwort-Karten
//

import SwiftUI

// MARK: - Overview View

struct TVOverviewView: View {
    @ObservedObject var viewModel: QuestionsGameViewModel
    @Environment(\.tvScale) private var tvScale

    var body: some View {
        VStack(spacing: scaled(28)) {
            if let round = viewModel.currentRound {
                VStack(spacing: scaled(8)) {
                    Text("AKTIVE ABFRAGE")
                        .font(.system(size: scaled(12), weight: .medium, design: .monospaced))
                        .foregroundStyle(QuestionsTheme.accentGreen)
                        .tracking(scaled(3))

                    Text(round.promptPair.citizenQuestion)
                        .font(.system(size: scaled(32), weight: .bold, design: .monospaced))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(QuestionsTheme.textTypewriter)
                        .padding(.horizontal, scaled(40))
                }
            }

            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
                spacing: scaled(20)
            ) {
                ForEach(viewModel.answersInOrder, id: \.id) { answer in
                    TVAnswerCard(
                        playerName: viewModel.playerName(for: answer.playerID),
                        answer: answer,
                        isLiar: viewModel.revealEvaluation?.incorrect.contains(answer.playerID) ?? false,
                        isCaught: viewModel.revealEvaluation?.correct.contains(answer.playerID) ?? false,
                        voteCount: viewModel.voteCounts[answer.playerID] ?? 0
                    )
                }
            }
        }
    }

    private func scaled(_ value: CGFloat) -> CGFloat { value * tvScale }
}

// MARK: - Answer Card

struct TVAnswerCard: View {
    let playerName: String
    let answer: QuestionsAnswer
    let isLiar: Bool
    let isCaught: Bool
    let voteCount: Int
    @Environment(\.tvScale) private var tvScale

    private var borderColor: Color {
        if isCaught { return QuestionsTheme.accentSuccess }
        if isLiar { return QuestionsTheme.accentDanger }
        if voteCount > 0 { return QuestionsTheme.accentDanger.opacity(0.6) }
        return QuestionsTheme.accentGreen.opacity(0.2)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: scaled(12)) {
            HStack {
                VStack(alignment: .leading, spacing: scaled(2)) {
                    Text("SUBJEKT")
                        .font(.system(size: scaled(9), weight: .medium, design: .monospaced))
                        .foregroundStyle(QuestionsTheme.textMuted)
                        .tracking(scaled(1.5))

                    Text(playerName.uppercased())
                        .font(.system(size: scaled(16), weight: .bold, design: .monospaced))
                        .foregroundStyle(QuestionsTheme.textTypewriter)
                }

                Spacer()

                if voteCount > 0 {
                    HStack(spacing: scaled(4)) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: scaled(12)))
                        Text("\(voteCount)")
                            .font(.system(size: scaled(16), weight: .bold, design: .monospaced))
                    }
                    .foregroundStyle(QuestionsTheme.accentDanger)
                }
            }

            Rectangle()
                .fill(QuestionsTheme.accentGreen.opacity(0.15))
                .frame(height: scaled(1))

            Text(answer.text)
                .font(.system(size: scaled(18), design: .monospaced))
                .foregroundStyle(QuestionsTheme.textTypewriter)
                .frame(maxWidth: .infinity, alignment: .center)
                .multilineTextAlignment(.center)
                .frame(height: scaled(80))

            if isCaught {
                HStack(spacing: scaled(4)) {
                    Image(systemName: "checkmark.seal.fill")
                    Text("VERIFIZIERT")
                }
                .font(.system(size: scaled(10), weight: .bold, design: .monospaced))
                .foregroundStyle(QuestionsTheme.accentSuccess)
                .padding(.horizontal, scaled(10))
                .padding(.vertical, scaled(5))
                .background(Capsule().fill(QuestionsTheme.accentSuccess.opacity(0.2)))
            }
        }
        .padding(scaled(16))
        .background(
            RoundedRectangle(cornerRadius: scaled(12))
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
        )
        .overlay(
            RoundedRectangle(cornerRadius: scaled(12))
                .stroke(borderColor, lineWidth: scaled(isCaught || isLiar || voteCount > 0 ? 2 : 1))
        )
        .shadow(color: borderColor.opacity(0.3), radius: scaled(8))
    }

    private func scaled(_ value: CGFloat) -> CGFloat { value * tvScale }
}
