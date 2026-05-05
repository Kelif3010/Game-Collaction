//
//  QuestionsTVCollectingView.swift
//  Games Collection
//
//  Collecting-Phase + EKG-Signal + Status-Chips
//

import SwiftUI

// MARK: - Collecting View

struct TVCollectingView: View {
    @ObservedObject var viewModel: QuestionsGameViewModel
    @Environment(\.tvScale) private var tvScale

    var body: some View {
        VStack(spacing: scaled(36)) {
            Spacer()

            VStack(spacing: scaled(10)) {
                HStack(spacing: scaled(10)) {
                    Circle()
                        .fill(QuestionsTheme.accentGreen)
                        .frame(width: scaled(12), height: scaled(12))
                        .shadow(color: QuestionsTheme.accentGreen, radius: scaled(6))

                    Text("LIVE-ERFASSUNG")
                        .font(.system(size: scaled(18), weight: .bold, design: .monospaced))
                        .foregroundStyle(QuestionsTheme.accentGreen)
                        .tracking(scaled(4))
                }

                Text("DATENAUFNAHME AKTIV")
                    .font(.system(size: scaled(38), weight: .bold, design: .monospaced))
                    .foregroundStyle(QuestionsTheme.textTypewriter)
            }

            if let round = viewModel.currentRound, let currentPlayer = viewModel.currentPlayer() {
                VStack(spacing: scaled(14)) {
                    Text("AKTIVES SUBJEKT")
                        .font(.system(size: scaled(14), weight: .medium, design: .monospaced))
                        .foregroundStyle(QuestionsTheme.textMuted)
                        .tracking(scaled(3))

                    Text(currentPlayer.name.uppercased())
                        .font(.system(size: scaled(60), weight: .bold, design: .monospaced))
                        .foregroundStyle(QuestionsTheme.textTypewriter)

                    Text("EINGABE LÄUFT...")
                        .font(.system(size: scaled(20), weight: .medium, design: .monospaced))
                        .foregroundStyle(QuestionsTheme.accentGreen.opacity(0.8))
                }

                TVSignalLine()
                    .frame(height: scaled(20))
                    .padding(.horizontal, scaled(60))

                TVCollectingStatusRow(
                    players: viewModel.appModel.players,
                    currentPlayerID: currentPlayer.id,
                    answeredIDs: Set(round.answers.keys)
                )
                .padding(.horizontal, scaled(40))

                Text("\(round.answers.count) VON \(viewModel.playerCount) ERFASST")
                    .font(.system(size: scaled(16), weight: .medium, design: .monospaced))
                    .foregroundStyle(QuestionsTheme.textMuted)
                    .tracking(scaled(2))
            }

            Spacer()
        }
    }

    private func scaled(_ value: CGFloat) -> CGFloat { value * tvScale }
}

// MARK: - Signal Line (EKG-Style)

struct TVSignalLine: View {
    @Environment(\.tvScale) private var tvScale

    var body: some View {
        GeometryReader { proxy in
            TimelineView(.animation) { context in
                let width = proxy.size.width
                let segment = max(scaled(40), 1)
                let count = max(14, Int(width / segment) + 12)
                let cycle = CGFloat(count) * segment
                let speed = max(scaled(50), 1)
                let time = CGFloat(context.date.timeIntervalSinceReferenceDate)
                let offset = -(time * speed).truncatingRemainder(dividingBy: cycle)

                HStack(spacing: scaled(20)) {
                    ForEach(0..<count, id: \.self) { index in
                        if index.isMultiple(of: 2) {
                            Capsule()
                                .fill(QuestionsTheme.accentGreen.opacity(0.4))
                                .frame(width: scaled(30), height: scaled(4))
                        } else {
                            Circle()
                                .fill(QuestionsTheme.accentGreen.opacity(0.6))
                                .frame(width: scaled(8), height: scaled(8))
                                .shadow(color: QuestionsTheme.accentGreen.opacity(0.5), radius: scaled(4))
                        }
                    }
                }
                .offset(x: offset)
            }
        }
        .clipped()
        .background(
            Capsule()
                .fill(Color.black.opacity(0.3))
        )
    }

    private func scaled(_ value: CGFloat) -> CGFloat { value * tvScale }
}

// MARK: - Collecting Status Row

struct TVCollectingStatusRow: View {
    let players: [QuestionPlayer]
    let currentPlayerID: UUID
    let answeredIDs: Set<UUID>
    @Environment(\.tvScale) private var tvScale

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: scaled(12)) {
                ForEach(players) { player in
                    TVCollectingChip(
                        name: player.name,
                        status: status(for: player.id)
                    )
                }
            }
            .padding(.horizontal, scaled(14))
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

    private func status(for playerID: UUID) -> CollectingStatus {
        if answeredIDs.contains(playerID) { return .done }
        if playerID == currentPlayerID { return .active }
        return .waiting
    }

    private func scaled(_ value: CGFloat) -> CGFloat { value * tvScale }
}

// MARK: - Collecting Status

enum CollectingStatus {
    case active, done, waiting
}

// MARK: - Collecting Chip

struct TVCollectingChip: View {
    let name: String
    let status: CollectingStatus
    @Environment(\.tvScale) private var tvScale

    private var statusColor: Color {
        switch status {
        case .active:  return QuestionsTheme.accentAmber
        case .done:    return QuestionsTheme.accentGreen
        case .waiting: return QuestionsTheme.textMuted
        }
    }

    private var statusText: String {
        switch status {
        case .active:  return "LIVE"
        case .done:    return "OK"
        case .waiting: return "—"
        }
    }

    var body: some View {
        HStack(spacing: scaled(8)) {
            Circle()
                .fill(statusColor)
                .frame(width: scaled(10), height: scaled(10))
                .shadow(color: statusColor.opacity(0.5), radius: scaled(3))

            Text(name.uppercased())
                .font(.system(size: scaled(14), weight: .bold, design: .monospaced))
                .foregroundStyle(QuestionsTheme.textTypewriter)

            Text(statusText)
                .font(.system(size: scaled(11), weight: .bold, design: .monospaced))
                .foregroundStyle(statusColor)
        }
        .padding(.horizontal, scaled(12))
        .padding(.vertical, scaled(6))
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
