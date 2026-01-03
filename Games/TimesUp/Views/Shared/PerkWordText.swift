//
//  PerkWordText.swift
//  TimesUp
//
//  Created by Ken on 23.09.25.
//

import SwiftUI

struct PerkWordText: View {
    @ObservedObject var gameManager: GameManager
    let term: Term?
    var font: Font = .system(size: 48, weight: .bold)
    var weight: Font.Weight = .bold
    var alignment: TextAlignment = .center
    var lineLimit: Int = 2
    var color: Color = .primary
    
    var body: some View {
        FlickerText(active: gameManager.shouldFlickerForCurrentTeam()) {
            Text(gameManager.displayTextForCurrentTeam(term: term))
                .font(font)
                .fontWeight(weight)
                .multilineTextAlignment(alignment)
                .lineLimit(lineLimit)
                .minimumScaleFactor(0.6)
                .foregroundColor(color)
        }
    }
}

struct FlickerText<Content: View>: View {
    let active: Bool
    @ViewBuilder var content: () -> Content
    
    var body: some View {
        if active {
            TimelineView(.animation) { timeline in
                let oscillation = abs(sin(timeline.date.timeIntervalSinceReferenceDate * 8))
                content()
                    .opacity(0.4 + 0.6 * oscillation)
            }
        } else {
            content()
        }
    }
}
