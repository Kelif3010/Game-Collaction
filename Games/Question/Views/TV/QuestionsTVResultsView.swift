//
//  QuestionsTVResultsView.swift
//  Games Collection
//
//  Ergebnis-Anzeige nach Abstimmung
//

import SwiftUI

// MARK: - Results View

struct TVResultsView: View {
    @ObservedObject var viewModel: QuestionsGameViewModel
    @Environment(\.tvScale) private var tvScale

    private var citizensWon: Bool {
        viewModel.lastRevealEvaluation?.citizensWon ?? false
    }

    var body: some View {
        VStack(spacing: scaled(50)) {
            Spacer()

            VStack(spacing: scaled(16)) {
                Text(citizensWon ? "LÜGE VERIFIZIERT" : "LÜGNER ENTKOMMEN")
                    .font(.system(size: scaled(50), weight: .black, design: .monospaced))
                    .foregroundStyle(citizensWon ? QuestionsTheme.accentGreen : QuestionsTheme.accentDanger)
                    .shadow(
                        color: citizensWon
                            ? QuestionsTheme.accentGreen.opacity(0.5)
                            : QuestionsTheme.accentDanger.opacity(0.5),
                        radius: scaled(20)
                    )

                Text(citizensWon ? "SUBJEKT ÜBERFÜHRT" : "MISSION GESCHEITERT")
                    .font(.system(size: scaled(20), weight: .medium, design: .monospaced))
                    .foregroundStyle(QuestionsTheme.textMuted)
                    .tracking(scaled(4))
            }

            HStack(spacing: scaled(50)) {
                ForEach(Array(viewModel.currentLiarIDs), id: \.self) { liarID in
                    liarRevealCard(for: liarID)
                }
            }

            Spacer()
        }
    }

    private func liarRevealCard(for liarID: UUID) -> some View {
        VStack(spacing: scaled(16)) {
            ZStack {
                Circle()
                    .fill(QuestionsTheme.accentDanger.opacity(0.15))
                    .frame(width: scaled(120), height: scaled(120))
                    .overlay(
                        Circle()
                            .stroke(QuestionsTheme.accentDanger.opacity(0.4), lineWidth: scaled(2))
                    )

                Image(systemName: "eye.slash.fill")
                    .font(.system(size: scaled(50)))
                    .foregroundStyle(QuestionsTheme.accentDanger)
            }

            VStack(spacing: scaled(6)) {
                Text(viewModel.playerName(for: liarID).uppercased())
                    .font(.system(size: scaled(28), weight: .bold, design: .monospaced))
                    .foregroundStyle(QuestionsTheme.textTypewriter)

                Text("LÜGNER")
                    .font(.system(size: scaled(12), weight: .bold, design: .monospaced))
                    .foregroundStyle(QuestionsTheme.accentDanger)
                    .tracking(scaled(3))
            }
        }
    }

    private func scaled(_ value: CGFloat) -> CGFloat { value * tvScale }
}
