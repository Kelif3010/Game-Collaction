//
//  TimesUpLeaderboardInfoViews.swift
//  TimesUp
//

import SwiftUI

struct TimesUpLeaderboardView: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        ZStack {
            TimesUpStyle.backgroundGradient.ignoresSafeArea()
            VStack {
                Text("Leaderboard")
                    .font(.largeTitle)
                    .foregroundStyle(.white)
                Button("Close") { dismiss() }
            }
        }
    }
}

struct TimesUpInfoSheet: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        ZStack {
            TimesUpStyle.backgroundGradient.ignoresSafeArea()
            VStack(spacing: 20) {
                Text("Info")
                    .font(.largeTitle)
                    .foregroundStyle(.white)
                Button("Close") { dismiss() }
            }
        }
    }
}
