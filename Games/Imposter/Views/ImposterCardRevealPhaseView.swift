//
//  ImposterCardRevealPhaseView.swift
//  Games Collection
//

import SwiftUI

// MARK: - Card Reveal Phase
struct ImposterCardRevealPhaseView: View {
    let currentCard: GameCard?
    let isMultiplayer: Bool
    let onCardTap: () -> Void
    let onCardDismissed: () -> Void

    @Environment(GameSettings.self) var gameSettings

    var body: some View {
        if let card = currentCard {
            VStack {
                Spacer()
                SpyCardView(
                    card: card,
                    gameSettings: gameSettings,
                    onCardTap: onCardTap,
                    onCardDismissed: onCardDismissed
                )
                .id(card.id)
                Spacer()
            }
            .transition(.scale(scale: 0.95).combined(with: .opacity))
        } else {
            ProgressView()
                .tint(.white)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
