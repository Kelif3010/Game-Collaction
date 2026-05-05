//
//  TimesUpTimeAndWordsSheet.swift
//  TimesUp
//

import SwiftUI

struct TimeAndWordsSheetView: View {
    @ObservedObject var gameManager: GameManager
    @Environment(\.dismiss) private var dismiss

    var wordCountRange: ClosedRange<Double> {
        let minVal = Double(gameManager.gameState.settings.minWordCount)
        let maxVal = max(minVal + 1, Double(gameManager.gameState.settings.maxWordCount))
        return minVal...maxVal
    }

    var body: some View {
        ZStack {
            Color(red: 0.1, green: 0.1, blue: 0.15).ignoresSafeArea()

            VStack(spacing: 10) {
                Capsule()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 40, height: 5)
                    .padding(.top, 10)

                Text("Zeit & Wörter")
                    .font(.title2.bold())
                    .foregroundStyle(.white)

                VStack(alignment: .leading, spacing: 15) {
                    HStack {
                        Label("Zeit pro Zug", systemImage: "timer")
                            .font(.headline)
                            .foregroundStyle(.white)
                        Spacer()
                        Text("\(Int(gameManager.gameState.settings.turnTimeLimit)) s")
                            .font(.title3.bold())
                            .foregroundStyle(.blue)
                    }

                    Slider(
                        value: Binding(
                            get: { gameManager.gameState.settings.turnTimeLimit },
                            set: { gameManager.gameState.settings.turnTimeLimit = $0 }
                        ),
                        in: 10...120,
                        step: 5
                    )
                    .tint(.blue)
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 18))

                VStack(alignment: .leading, spacing: 15) {
                    HStack {
                        Label("Anzahl Wörter", systemImage: "textformat.123")
                            .font(.headline)
                            .foregroundStyle(.white)
                        Spacer()
                        Text("\(gameManager.gameState.settings.wordCount)")
                            .font(.title3.bold())
                            .foregroundStyle(.purple)
                    }

                    if gameManager.gameState.settings.selectedCategories.isEmpty {
                        Text("Mindestens eine Kategorie auswählen")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    } else {
                        Slider(
                            value: Binding(
                                get: { Double(gameManager.gameState.settings.wordCount) },
                                set: { gameManager.gameState.settings.wordCount = Int($0) }
                            ),
                            in: wordCountRange,
                            step: 1
                        )
                        .tint(.purple)

                        HStack {
                            HStack(spacing: 4) {
                                Text("Min:")
                                Text("\(gameManager.gameState.settings.minWordCount)")
                            }
                            Spacer()
                            HStack(spacing: 4) {
                                Text("Verfügbar:")
                                Text("\(gameManager.gameState.settings.availableWordCount)")
                            }
                        }
                        .font(.caption)
                        .foregroundStyle(.gray)
                    }
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 18))

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Text("Weiter")
                        .font(.headline.bold())
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.bottom, 20)
            }
            .padding(.horizontal, 24)
        }
    }
}
