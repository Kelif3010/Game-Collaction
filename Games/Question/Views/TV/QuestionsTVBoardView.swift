//
//  QuestionsTVBoardView.swift
//  Games Collection
//
//  Created by Gemini on 17.01.2026.
//

import SwiftUI

struct QuestionsTVBoardView: View {
    @ObservedObject var viewModel: QuestionsGameViewModel
    @Environment(\.tvScale) private var tvScale
    @State private var showCinematicReveal = false
    @State private var cinematicRevealID = UUID()
    
    var body: some View {
        ZStack {
            QuestionsStyle.backgroundGradient.ignoresSafeArea()
            
            VStack(spacing: scaled(30)) {
                // Header mit Timer (wenn aktiv)
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

    private func triggerCinematicReveal() {
        guard !showCinematicReveal else { return }
        cinematicRevealID = UUID()
        withAnimation(.easeOut(duration: 0.2)) {
            showCinematicReveal = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            withAnimation(.easeInOut(duration: 0.4)) {
                showCinematicReveal = false
            }
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

    private func scaled(_ value: CGFloat) -> CGFloat {
        value * tvScale
    }
}

private struct TVCinematicRevealView: View {
    @ObservedObject var viewModel: QuestionsGameViewModel
    @Environment(\.tvScale) private var tvScale
    @State private var stampScale: CGFloat = 1.5
    @State private var stampOpacity: Double = 0
    @State private var stampRotation: Double = -10
    @State private var flashOpacity: Double = 0
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.black.opacity(0.95), Color.red.opacity(0.4)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            RadialGradient(
                colors: [Color.white.opacity(0.12), Color.clear],
                center: .center,
                startRadius: scaled(50),
                endRadius: scaled(420)
            )
            .ignoresSafeArea()
            
            VStack(spacing: scaled(20)) {
                Text("AKTE GEÖFFNET")
                    .font(.system(size: scaled(22), weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.7))
                    .tracking(scaled(6))
                
                RoundedRectangle(cornerRadius: scaled(18))
                    .fill(Color.white.opacity(0.08))
                    .frame(height: scaled(140))
                    .overlay(
                        RoundedRectangle(cornerRadius: scaled(18))
                            .stroke(Color.white.opacity(0.2), lineWidth: scaled(2))
                    )
                    .overlay(
                        VStack(spacing: scaled(6)) {
                            Text("IDENTITÄT PRÜFEN")
                                .font(.system(size: scaled(24), weight: .black))
                                .foregroundColor(.white)
                            Text(targetLine)
                                .font(.system(size: scaled(16), weight: .semibold, design: .monospaced))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    )
            }
            
            Text("ENTTARNT")
                .font(.system(size: scaled(120), weight: .black, design: .monospaced))
                .foregroundColor(.red)
                .padding(.horizontal, scaled(30))
                .padding(.vertical, scaled(12))
                .overlay(
                    RoundedRectangle(cornerRadius: scaled(10))
                        .stroke(Color.red, lineWidth: scaled(6))
                )
                .rotationEffect(.degrees(stampRotation))
                .scaleEffect(stampScale)
                .opacity(stampOpacity)
                .shadow(color: .red.opacity(0.5), radius: scaled(20))
            
            Rectangle()
                .fill(Color.white)
                .opacity(flashOpacity)
                .ignoresSafeArea()
        }
        .onAppear {
            stampScale = 1.6
            stampOpacity = 0
            stampRotation = -12
            flashOpacity = 0
            withAnimation(.easeOut(duration: 0.25)) {
                stampScale = 1.0
                stampOpacity = 1.0
                stampRotation = 0
            }
            withAnimation(.easeOut(duration: 0.2)) {
                flashOpacity = 0.5
            }
            withAnimation(.easeIn(duration: 0.4).delay(0.15)) {
                flashOpacity = 0
            }
        }
    }
    
    private var targetLine: String {
        let evaluation = viewModel.revealEvaluation ?? viewModel.lastRevealEvaluation
        let names = evaluation?.imposters.map { viewModel.playerName(for: $0) } ?? []
        if names.isEmpty {
            return "ZIEL UNBEKANNT"
        }
        let label = names.count > 1 ? "ZIELE" : "ZIEL"
        return "\(label): \(names.sorted().joined(separator: " • "))"
    }

    private func scaled(_ value: CGFloat) -> CGFloat {
        value * tvScale
    }
}

// MARK: - Sub-Views für den TV

private struct TVHeaderView: View {
    @ObservedObject var viewModel: QuestionsGameViewModel
    @Environment(\.tvScale) private var tvScale
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: scaled(5)) {
                Text("FINDE DEN LÜGNER")
                    .font(.system(size: scaled(20), weight: .black, design: .monospaced))
                    .foregroundColor(.white.opacity(0.5))
                
                if let category = viewModel.selectedCategory {
                    Text(category.name.uppercased())
                        .font(.system(size: scaled(32), weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
            }
            
            Spacer()
            
            if viewModel.discussionTime > 0 && (viewModel.currentPhase == .overview || viewModel.currentPhase == .voting) {
                HStack(spacing: scaled(15)) {
                    Image(systemName: "timer")
                        .font(.system(size: scaled(40)))
                    Text(viewModel.timeString(from: viewModel.timeRemaining))
                        .font(.system(size: scaled(60), weight: .bold, design: .monospaced))
                }
                .foregroundColor(viewModel.timeRemaining < 30 ? .red : .white)
                .padding(.horizontal, scaled(30))
                .padding(.vertical, scaled(10))
                .background(Color.white.opacity(0.05))
                .clipShape(Capsule())
            }
        }
    }

    private func scaled(_ value: CGFloat) -> CGFloat {
        value * tvScale
    }
}

private struct TVSetupView: View {
    @ObservedObject var viewModel: QuestionsGameViewModel
    @ObservedObject private var mpc = MultipeerManager.shared
    @Environment(\.tvScale) private var tvScale
    
    var body: some View {
        VStack(spacing: scaled(35)) {
            Spacer()
            
            VStack(spacing: scaled(10)) {
                Text("BÜHNE")
                    .font(.system(size: scaled(24), weight: .black, design: .monospaced))
                    .foregroundColor(.white.opacity(0.6))
                    .tracking(scaled(6))
                
                Text("VERBINDE DEIN HANDY")
                    .font(.system(size: scaled(40), weight: .black))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: scaled(12)) {
                Text("RAUM-CODE")
                    .font(.system(size: scaled(16), weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.6))
                    .tracking(scaled(4))
                
                Text(displayRoomCode)
                    .font(.system(size: scaled(120), weight: .heavy, design: .monospaced))
                    .foregroundStyle(
                        LinearGradient(colors: [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .shadow(color: .red.opacity(0.5), radius: scaled(20))
            }
            .padding(.vertical, scaled(10))
            
            TVStageTickerBand(
                players: viewModel.appModel.players,
                readyPlayers: mpc.readyPlayers,
                disconnectedPlayers: mpc.disconnectedPeers
            )
            .frame(height: scaled(70))
            
            Text("\(readyCount) von \(playerCount) bereit")
                .font(.system(size: scaled(20), weight: .semibold, design: .monospaced))
                .foregroundColor(.white.opacity(0.7))
            
            Spacer()
        }
    }

    private var displayRoomCode: String {
        let code = mpc.activeRoomCode?.trimmingCharacters(in: .whitespacesAndNewlines)
        return code?.isEmpty == false ? code! : "----"
    }

    private var playerCount: Int {
        viewModel.appModel.players.count
    }

    private var readyCount: Int {
        let names = Set(viewModel.appModel.players.map { $0.name })
        return mpc.readyPlayers.intersection(names).count
    }

    private func scaled(_ value: CGFloat) -> CGFloat {
        value * tvScale
    }
}

private struct TVStageTickerBand: View {
    let players: [Player]
    let readyPlayers: Set<String>
    let disconnectedPlayers: Set<String>
    @Environment(\.tvScale) private var tvScale
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: scaled(16)) {
                if players.isEmpty {
                    Text("WARTEN AUF SPIELER...")
                        .font(.system(size: scaled(18), weight: .bold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.horizontal, scaled(20))
                } else {
                    ForEach(players) { player in
                        TVStageTickerChip(
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
        .background(Color.white.opacity(0.06))
        .overlay(
            RoundedRectangle(cornerRadius: scaled(20))
                .stroke(Color.white.opacity(0.12), lineWidth: scaled(1))
        )
        .clipShape(RoundedRectangle(cornerRadius: scaled(20)))
    }

    private func scaled(_ value: CGFloat) -> CGFloat {
        value * tvScale
    }
}

private struct TVStageTickerChip: View {
    let name: String
    let isReady: Bool
    let isDisconnected: Bool
    @Environment(\.tvScale) private var tvScale

    private var statusColor: Color {
        if isDisconnected {
            return .orange
        }
        return isReady ? .green : .white.opacity(0.4)
    }

    private var statusText: String {
        if isDisconnected {
            return "OFFLINE"
        }
        return isReady ? "BEREIT" : "WARTE"
    }

    var body: some View {
        HStack(spacing: scaled(10)) {
            Circle()
                .fill(statusColor)
                .frame(width: scaled(10), height: scaled(10))
            
            Text(name.uppercased())
                .font(.system(size: scaled(18), weight: .bold, design: .monospaced))
                .foregroundColor(.white)
            
            Text(statusText)
                .font(.system(size: scaled(14), weight: .bold, design: .monospaced))
                .foregroundColor(statusColor)
        }
        .padding(.horizontal, scaled(16))
        .padding(.vertical, scaled(8))
        .background(Color.white.opacity(0.08))
        .clipShape(Capsule())
    }

    private func scaled(_ value: CGFloat) -> CGFloat {
        value * tvScale
    }
}

private struct TVCollectingView: View {
    @ObservedObject var viewModel: QuestionsGameViewModel
    @Environment(\.tvScale) private var tvScale
    
    var body: some View {
        VStack(spacing: scaled(32)) {
            Spacer()
            
            VStack(spacing: scaled(8)) {
                Text("LIVE-TICKER")
                    .font(.system(size: scaled(20), weight: .bold, design: .monospaced))
                    .foregroundColor(.orange)
                    .tracking(scaled(4))
                
                Text("ANTWORTEN LAUFEN")
                    .font(.system(size: scaled(42), weight: .black))
                    .foregroundColor(.white)
            }
            
            if let round = viewModel.currentRound, let currentPlayer = viewModel.currentPlayer() {
                VStack(spacing: scaled(12)) {
                    Text(currentPlayer.name.uppercased())
                        .font(.system(size: scaled(70), weight: .black, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("tippt gerade...")
                        .font(.system(size: scaled(24), weight: .semibold))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                TVSignalTickerLine()
                    .frame(height: scaled(18))
                    .padding(.horizontal, scaled(40))
                
                TVCollectingStatusRow(
                    players: viewModel.appModel.players,
                    currentPlayerID: currentPlayer.id,
                    answeredIDs: Set(round.answers.keys)
                )
                .padding(.horizontal, scaled(40))
                
                Text("\(round.answers.count) von \(viewModel.playerCount) Antworten eingegangen")
                    .font(.system(size: scaled(18), weight: .semibold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
        }
    }

    private func scaled(_ value: CGFloat) -> CGFloat {
        value * tvScale
    }
}

private struct TVSignalTickerLine: View {
    @Environment(\.tvScale) private var tvScale
    
    var body: some View {
        GeometryReader { proxy in
            TimelineView(.animation) { context in
                let width = proxy.size.width
                let segment = max(scaled(36), 1)
                let count = max(14, Int(width / segment) + 12)
                let cycle = CGFloat(count) * segment
                let speed = max(scaled(40), 1)
                let time = CGFloat(context.date.timeIntervalSinceReferenceDate)
                let offset = -(time * speed).truncatingRemainder(dividingBy: cycle)
                
                HStack(spacing: scaled(16)) {
                    ForEach(0..<count, id: \.self) { index in
                        if index.isMultiple(of: 2) {
                            Capsule()
                                .fill(Color.white.opacity(0.18))
                                .frame(width: scaled(30), height: scaled(4))
                        } else {
                            Circle()
                                .fill(Color.white.opacity(0.35))
                                .frame(width: scaled(6), height: scaled(6))
                        }
                    }
                }
                .offset(x: offset)
            }
        }
        .clipped()
        .background(Color.white.opacity(0.05))
        .clipShape(Capsule())
    }

    private func scaled(_ value: CGFloat) -> CGFloat {
        value * tvScale
    }
}

private struct TVCollectingStatusRow: View {
    let players: [Player]
    let currentPlayerID: UUID
    let answeredIDs: Set<UUID>
    @Environment(\.tvScale) private var tvScale

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: scaled(12)) {
                ForEach(players) { player in
                    TVCollectingStatusChip(
                        name: player.name,
                        status: status(for: player.id)
                    )
                }
            }
            .padding(.horizontal, scaled(10))
            .padding(.vertical, scaled(8))
        }
        .background(Color.white.opacity(0.06))
        .overlay(
            RoundedRectangle(cornerRadius: scaled(16))
                .stroke(Color.white.opacity(0.1), lineWidth: scaled(1))
        )
        .clipShape(RoundedRectangle(cornerRadius: scaled(16)))
    }

    private func status(for playerID: UUID) -> CollectingStatus {
        if answeredIDs.contains(playerID) {
            return .done
        }
        if playerID == currentPlayerID {
            return .active
        }
        return .waiting
    }

    private func scaled(_ value: CGFloat) -> CGFloat {
        value * tvScale
    }
}

private enum CollectingStatus {
    case active
    case done
    case waiting
}

private struct TVCollectingStatusChip: View {
    let name: String
    let status: CollectingStatus
    @Environment(\.tvScale) private var tvScale

    private var statusColor: Color {
        switch status {
        case .active: return .orange
        case .done: return .green
        case .waiting: return .white.opacity(0.4)
        }
    }

    private var statusText: String {
        switch status {
        case .active: return "LIVE"
        case .done: return "FERTIG"
        case .waiting: return "WARTE"
        }
    }

    var body: some View {
        HStack(spacing: scaled(8)) {
            Circle()
                .fill(statusColor)
                .frame(width: scaled(10), height: scaled(10))
            
            Text(name.uppercased())
                .font(.system(size: scaled(16), weight: .bold, design: .monospaced))
                .foregroundColor(.white)
            
            Text(statusText)
                .font(.system(size: scaled(12), weight: .bold, design: .monospaced))
                .foregroundColor(statusColor)
        }
        .padding(.horizontal, scaled(12))
        .padding(.vertical, scaled(6))
        .background(Color.white.opacity(0.08))
        .clipShape(Capsule())
    }

    private func scaled(_ value: CGFloat) -> CGFloat {
        value * tvScale
    }
}

private struct TVOverviewView: View {
    @ObservedObject var viewModel: QuestionsGameViewModel
    @Environment(\.tvScale) private var tvScale
    
    var body: some View {
        VStack(spacing: scaled(30)) {
            if let round = viewModel.currentRound {
                Text(round.promptPair.citizenQuestion)
                    .font(.system(size: scaled(40), weight: .heavy))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                    .padding(.horizontal, scaled(60))
            }
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: scaled(20)) {
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

    private func scaled(_ value: CGFloat) -> CGFloat {
        value * tvScale
    }
}

private struct TVAnswerCard: View {
    let playerName: String
    let answer: QuestionsAnswer
    let isLiar: Bool
    let isCaught: Bool
    let voteCount: Int
    @Environment(\.tvScale) private var tvScale
    
    var body: some View {
        VStack(alignment: .leading, spacing: scaled(15)) {
            HStack {
                Text(playerName)
                    .font(.system(size: scaled(22), weight: .bold))
                Spacer()
                if voteCount > 0 {
                    HStack(spacing: scaled(5)) {
                        Image(systemName: "hand.point.up.fill")
                        Text("\(voteCount)")
                    }
                    .font(.system(size: scaled(18), weight: .bold))
                    .foregroundColor(.red)
                }
            }
            
            Divider().background(Color.white.opacity(0.2))
            
            Text(answer.text)
                .font(.system(size: scaled(22)))
                .italic()
                .foregroundColor(.white.opacity(0.9))
                .frame(maxWidth: .infinity, alignment: .center)
                .multilineTextAlignment(.center)
                .frame(height: scaled(100))
            
            if isCaught {
                Text("ENTTARNT")
                    .font(.system(size: scaled(12), weight: .bold))
                    .padding(.horizontal, scaled(10))
                    .padding(.vertical, scaled(5))
                    .background(Color.green)
                    .cornerRadius(scaled(5))
            }
        }
        .padding(scaled(20))
        .background(Color.white.opacity(0.05))
        .cornerRadius(scaled(20))
        .overlay(
            RoundedRectangle(cornerRadius: scaled(20))
                .stroke(isCaught ? Color.green : (isLiar ? Color.red : Color.white.opacity(0.1)), lineWidth: scaled(2))
        )
    }

    private func scaled(_ value: CGFloat) -> CGFloat {
        value * tvScale
    }
}

private struct TVResultsView: View {
    @ObservedObject var viewModel: QuestionsGameViewModel
    @Environment(\.tvScale) private var tvScale
    
    var body: some View {
        VStack(spacing: scaled(40)) {
            Spacer()
            
            if let eval = viewModel.lastRevealEvaluation {
                Text(eval.citizensWon ? "BEDROHUNG ELIMINIERT" : "MISSION GESCHEITERT")
                    .font(.system(size: scaled(60), weight: .black))
                    .foregroundColor(eval.citizensWon ? .green : .red)
                
                HStack(spacing: scaled(40)) {
                    ForEach(Array(viewModel.currentSpyIDs), id: \.self) { spyID in
                        VStack(spacing: scaled(15)) {
                            Circle()
                                .fill(Color.red.opacity(0.2))
                                .frame(width: scaled(120), height: scaled(120))
                                .overlay(
                                    Image(systemName: "eye.slash.fill")
                                        .font(.system(size: scaled(50)))
                                        .foregroundColor(.red)
                                )
                            
                            Text(viewModel.playerName(for: spyID))
                                .font(.system(size: scaled(28), weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("DER LÜGNER")
                                .font(.system(size: scaled(12), weight: .bold))
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            
            Spacer()
        }
    }

    private func scaled(_ value: CGFloat) -> CGFloat {
        value * tvScale
    }
}
