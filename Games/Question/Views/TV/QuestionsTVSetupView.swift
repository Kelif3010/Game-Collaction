//
//  QuestionsTVSetupView.swift
//  Games Collection
//
//  Setup-Phase + Player-Ticker
//

import SwiftUI

// MARK: - Setup View

struct TVSetupView: View {
    @ObservedObject var viewModel: QuestionsGameViewModel
    @Environment(MultipeerManager.self) private var mpc
    @Environment(\.tvScale) private var tvScale

    var body: some View {
        VStack(spacing: scaled(40)) {
            Spacer()

            VStack(spacing: scaled(12)) {
                Text("SYSTEM INITIALISIERUNG")
                    .font(.system(size: scaled(18), weight: .bold, design: .monospaced))
                    .foregroundStyle(QuestionsTheme.accentGreen)
                    .tracking(scaled(6))

                Text("VERBINDE DEIN GERÄT")
                    .font(.system(size: scaled(36), weight: .bold, design: .monospaced))
                    .foregroundStyle(QuestionsTheme.textTypewriter)
            }

            // Raum-Code
            VStack(spacing: scaled(16)) {
                Text("ZUGANGS-CODE")
                    .font(.system(size: scaled(14), weight: .medium, design: .monospaced))
                    .foregroundStyle(QuestionsTheme.textMuted)
                    .tracking(scaled(4))

                Text(displayRoomCode)
                    .font(.system(size: scaled(100), weight: .heavy, design: .monospaced))
                    .foregroundStyle(QuestionsTheme.accentGreen)
                    .shadow(color: QuestionsTheme.accentGreen.opacity(0.5), radius: scaled(20))
                    .tracking(scaled(20))
            }
            .padding(.vertical, scaled(20))

            TVPlayerTickerBand(
                players: viewModel.appModel.players,
                readyPlayers: mpc.readyPlayers,
                disconnectedPlayers: mpc.disconnectedPeers
            )
            .frame(height: scaled(70))

            HStack(spacing: scaled(8)) {
                Circle()
                    .fill(readyCount == playerCount ? QuestionsTheme.accentGreen : QuestionsTheme.accentAmber)
                    .frame(width: scaled(10), height: scaled(10))
                    .shadow(
                        color: readyCount == playerCount ? QuestionsTheme.accentGreen : QuestionsTheme.accentAmber,
                        radius: scaled(4)
                    )

                Text("\(readyCount) VON \(playerCount) AUTORISIERT")
                    .font(.system(size: scaled(18), weight: .medium, design: .monospaced))
                    .foregroundStyle(QuestionsTheme.textMuted)
                    .tracking(scaled(2))
            }

            Spacer()
        }
    }

    private var displayRoomCode: String {
        let code = mpc.activeRoomCode?.trimmingCharacters(in: .whitespacesAndNewlines)
        return code?.isEmpty == false ? code! : "----"
    }

    private var playerCount: Int { viewModel.appModel.players.count }

    private var readyCount: Int {
        let names = Set(viewModel.appModel.players.map { $0.name })
        return mpc.readyPlayers.intersection(names).count
    }

    private func scaled(_ value: CGFloat) -> CGFloat { value * tvScale }
}

// MARK: - Player Ticker Band

struct TVPlayerTickerBand: View {
    let players: [QuestionPlayer]
    let readyPlayers: Set<String>
    let disconnectedPlayers: Set<String>
    @Environment(\.tvScale) private var tvScale

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: scaled(14)) {
                if players.isEmpty {
                    Text("WARTEN AUF SUBJEKTE...")
                        .font(.system(size: scaled(16), weight: .medium, design: .monospaced))
                        .foregroundStyle(QuestionsTheme.textMuted)
                        .padding(.horizontal, scaled(20))
                } else {
                    ForEach(players) { player in
                        TVPlayerChip(
                            name: player.name,
                            isReady: readyPlayers.contains(player.name),
                            isDisconnected: disconnectedPlayers.contains(player.name)
                        )
                    }
                }
            }
            .padding(.horizontal, scaled(20))
            .padding(.vertical, scaled(10))
        }
        .background(
            RoundedRectangle(cornerRadius: scaled(12))
                .fill(Color.black.opacity(0.4))
                .overlay(
                    RoundedRectangle(cornerRadius: scaled(12))
                        .stroke(QuestionsTheme.accentGreen.opacity(0.15), lineWidth: scaled(1))
                )
        )
    }

    private func scaled(_ value: CGFloat) -> CGFloat { value * tvScale }
}

// MARK: - Player Chip

struct TVPlayerChip: View {
    let name: String
    let isReady: Bool
    let isDisconnected: Bool
    @Environment(\.tvScale) private var tvScale

    private var statusColor: Color {
        if isDisconnected { return QuestionsTheme.accentAmber }
        return isReady ? QuestionsTheme.accentGreen : QuestionsTheme.textMuted
    }

    private var statusText: String {
        if isDisconnected { return "OFFLINE" }
        return isReady ? "BEREIT" : "WARTE"
    }

    var body: some View {
        HStack(spacing: scaled(10)) {
            Circle()
                .fill(statusColor)
                .frame(width: scaled(10), height: scaled(10))
                .shadow(color: statusColor.opacity(0.5), radius: scaled(4))

            Text(name.uppercased())
                .font(.system(size: scaled(16), weight: .bold, design: .monospaced))
                .foregroundStyle(QuestionsTheme.textTypewriter)

            Text(statusText)
                .font(.system(size: scaled(12), weight: .bold, design: .monospaced))
                .foregroundStyle(statusColor)
        }
        .padding(.horizontal, scaled(14))
        .padding(.vertical, scaled(8))
        .background(
            Capsule()
                .fill(Color.black.opacity(0.3))
                .overlay(
                    Capsule()
                        .stroke(statusColor.opacity(0.3), lineWidth: scaled(1))
                )
        )
    }

    private func scaled(_ value: CGFloat) -> CGFloat { value * tvScale }
}
