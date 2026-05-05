//
//  QuestionsTVBoardView.swift
//  Games Collection
//
//  Redesigned: Verhörraum / Lügendetektor Theme
//

import SwiftUI

struct QuestionsTVBoardView: View {
    @ObservedObject var viewModel: QuestionsGameViewModel
    @Environment(\.tvScale) private var tvScale
    @State private var showCinematicReveal = false
    @State private var cinematicRevealID = UUID()

    var body: some View {
        ZStack {
            // Verhörraum-Hintergrund
            QuestionsBackgroundView(stressLevel: stressLevel)
                .ignoresSafeArea()

            VStack(spacing: scaled(30)) {
                TVHeaderView(viewModel: viewModel)
                mainContent
                Spacer(minLength: 0)
            }
            .padding(scaled(40))

            if showCinematicReveal {
                TVCinematicRevealView(viewModel: viewModel)
                    .id(cinematicRevealID)
                    .transition(.opacity)
                    .zIndex(10)
                    .allowsHitTesting(false)
            }
        }
        .onChange(of: viewModel.revealEvaluation) { _, newValue in
            guard newValue != nil else { return }
            triggerCinematicReveal()
        }
    }

    private var stressLevel: CGFloat {
        switch viewModel.currentPhase {
        case .setup:                return 0.2
        case .collecting:           return 0.4
        case .overview, .voting:    return 0.6
        case .revealed, .finished:  return 0.9
        }
    }

    private func triggerCinematicReveal() {
        guard !showCinematicReveal else { return }
        cinematicRevealID = UUID()
        withAnimation(.easeOut(duration: 0.2)) { showCinematicReveal = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeInOut(duration: 0.4)) { showCinematicReveal = false }
        }
    }

    @ViewBuilder
    private var mainContent: some View {
        switch viewModel.currentPhase {
        case .setup:
            TVSetupView(viewModel: viewModel)
        case .collecting:
            TVCollectingView(viewModel: viewModel)
        case .revealed, .overview, .voting:
            TVOverviewView(viewModel: viewModel)
        case .finished:
            TVResultsView(viewModel: viewModel)
        }
    }

    private func scaled(_ value: CGFloat) -> CGFloat { value * tvScale }
}
