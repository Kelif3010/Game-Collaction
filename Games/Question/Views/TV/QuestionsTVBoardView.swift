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
        case .setup: return 0.2
        case .collecting: return 0.4
        case .overview, .voting: return 0.6
        case .revealed, .finished: return 0.9
        }
    }

    private func triggerCinematicReveal() {
        guard !showCinematicReveal else { return }
        cinematicRevealID = UUID()
        withAnimation(.easeOut(duration: 0.2)) {
            showCinematicReveal = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
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

// MARK: - Cinematic Reveal (Stempel-Animation)

private struct TVCinematicRevealView: View {
    @ObservedObject var viewModel: QuestionsGameViewModel
    @Environment(\.tvScale) private var tvScale
    @State private var stampScale: CGFloat = 2.0
    @State private var stampOpacity: Double = 0
    @State private var stampRotation: Double = -20
    @State private var flashOpacity: Double = 0
    @State private var shakeOffset: CGFloat = 0

    private var evaluation: QuestionsVoteEvaluation? {
        viewModel.revealEvaluation ?? viewModel.lastRevealEvaluation
    }

    private var citizensWon: Bool {
        evaluation?.citizensWon ?? false
    }

    var body: some View {
        ZStack {
            // Dunkler Overlay mit Farbton
            LinearGradient(
                colors: [
                    Color.black.opacity(0.95),
                    citizensWon
                        ? QuestionsTheme.accentSuccess.opacity(0.3)
                        : QuestionsTheme.accentDanger.opacity(0.3)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Vignette
            RadialGradient(
                colors: [Color.clear, Color.black.opacity(0.6)],
                center: .center,
                startRadius: scaled(100),
                endRadius: scaled(500)
            )
            .ignoresSafeArea()

            // Content
            VStack(spacing: scaled(30)) {
                // Header
                Text("AKTE GEÖFFNET")
                    .font(.system(size: scaled(24), weight: .bold, design: .monospaced))
                    .foregroundStyle(QuestionsTheme.accentGreen)
                    .tracking(scaled(8))

                // Dossier-Box
                dossierBox

                // Stempel
                StampView(
                    text: citizensWon ? "LÜGNER" : "ENTKOMMEN",
                    type: citizensWon ? .guilty : .escaped,
                    rotation: stampRotation
                )
                .scaleEffect(stampScale * tvScale)
                .opacity(stampOpacity)
                .offset(x: shakeOffset)
            }

            // Flash
            Rectangle()
                .fill(Color.white)
                .opacity(flashOpacity)
                .ignoresSafeArea()
        }
        .onAppear {
            runAnimation()
        }
    }

    private var dossierBox: some View {
        RoundedRectangle(cornerRadius: scaled(12))
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 0.10, green: 0.08, blue: 0.06),
                        Color(red: 0.06, green: 0.05, blue: 0.03)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: scaled(500), height: scaled(120))
            .overlay(
                RoundedRectangle(cornerRadius: scaled(12))
                    .stroke(QuestionsTheme.accentGreen.opacity(0.3), lineWidth: scaled(1))
            )
            .overlay(
                VStack(spacing: scaled(8)) {
                    Text("IDENTITÄT VERIFIZIERT")
                        .font(.system(size: scaled(14), weight: .medium, design: .monospaced))
                        .foregroundStyle(QuestionsTheme.textMuted)
                        .tracking(scaled(3))

                    Text(targetLine)
                        .font(.system(size: scaled(28), weight: .bold, design: .monospaced))
                        .foregroundStyle(QuestionsTheme.textTypewriter)
                }
            )
    }

    private var targetLine: String {
        let names = evaluation?.liars.map { viewModel.playerName(for: $0) } ?? []
        if names.isEmpty {
            return "UNBEKANNT"
        }
        return names.sorted().joined(separator: " • ").uppercased()
    }

    private func runAnimation() {
        // Flash
        withAnimation(.easeOut(duration: 0.15)) {
            flashOpacity = 0.6
        }
        withAnimation(.easeIn(duration: 0.3).delay(0.15)) {
            flashOpacity = 0
        }

        // Stamp slam
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.4)) {
                stampScale = 1.0
                stampOpacity = 1.0
                stampRotation = citizensWon ? -12 : -8
            }

            // Shake
            withAnimation(.easeOut(duration: 0.05)) {
                shakeOffset = 15
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                withAnimation(.easeOut(duration: 0.05)) {
                    shakeOffset = -12
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeOut(duration: 0.1)) {
                    shakeOffset = 0
                }
            }

            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
    }

    private func scaled(_ value: CGFloat) -> CGFloat {
        value * tvScale
    }
}

// MARK: - Header

private struct TVHeaderView: View {
    @ObservedObject var viewModel: QuestionsGameViewModel
    @Environment(\.tvScale) private var tvScale

    var body: some View {
        HStack {
            // Titel
            VStack(alignment: .leading, spacing: scaled(6)) {
                Text("LÜGENDETEKTOR")
                    .font(.system(size: scaled(18), weight: .bold, design: .monospaced))
                    .foregroundStyle(QuestionsTheme.accentGreen)
                    .tracking(scaled(4))

                if let category = viewModel.selectedCategory {
                    Text(category.name.uppercased())
                        .font(.system(size: scaled(28), weight: .bold, design: .monospaced))
                        .foregroundStyle(QuestionsTheme.textTypewriter)
                }
            }

            Spacer()

            // Timer
            if viewModel.discussionTime > 0 && (viewModel.currentPhase == .overview || viewModel.currentPhase == .voting) {
                timerDisplay
            }
        }
    }

    private var timerDisplay: some View {
        HStack(spacing: scaled(12)) {
            // LED
            Circle()
                .fill(timerColor)
                .frame(width: scaled(12), height: scaled(12))
                .shadow(color: timerColor, radius: scaled(6))

            Text("VERBLEIBEND")
                .font(.system(size: scaled(14), weight: .medium, design: .monospaced))
                .foregroundStyle(QuestionsTheme.textMuted)
                .tracking(scaled(2))

            Text(viewModel.timeString(from: viewModel.timeRemaining))
                .font(.system(size: scaled(48), weight: .bold, design: .monospaced))
                .foregroundStyle(timerColor)
                .monospacedDigit()
        }
        .padding(.horizontal, scaled(24))
        .padding(.vertical, scaled(12))
        .background(
            RoundedRectangle(cornerRadius: scaled(12))
                .fill(Color.black.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: scaled(12))
                        .stroke(timerColor.opacity(0.3), lineWidth: scaled(1))
                )
        )
    }

    private var timerColor: Color {
        if viewModel.timeRemaining < 10 {
            return QuestionsTheme.accentDanger
        } else if viewModel.timeRemaining < 30 {
            return QuestionsTheme.accentAmber
        }
        return QuestionsTheme.accentGreen
    }

    private func scaled(_ value: CGFloat) -> CGFloat {
        value * tvScale
    }
}

// MARK: - Setup View

private struct TVSetupView: View {
    @ObservedObject var viewModel: QuestionsGameViewModel
    @ObservedObject private var mpc = MultipeerManager.shared
    @Environment(\.tvScale) private var tvScale

    var body: some View {
        VStack(spacing: scaled(40)) {
            Spacer()

            // Header
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

            // Spieler-Ticker
            TVPlayerTickerBand(
                players: viewModel.appModel.players,
                readyPlayers: mpc.readyPlayers,
                disconnectedPlayers: mpc.disconnectedPeers
            )
            .frame(height: scaled(70))

            // Status
            HStack(spacing: scaled(8)) {
                Circle()
                    .fill(readyCount == playerCount ? QuestionsTheme.accentGreen : QuestionsTheme.accentAmber)
                    .frame(width: scaled(10), height: scaled(10))
                    .shadow(color: readyCount == playerCount ? QuestionsTheme.accentGreen : QuestionsTheme.accentAmber, radius: scaled(4))

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

// MARK: - Player Ticker Band

private struct TVPlayerTickerBand: View {
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

    private func scaled(_ value: CGFloat) -> CGFloat {
        value * tvScale
    }
}

private struct TVPlayerChip: View {
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

    private func scaled(_ value: CGFloat) -> CGFloat {
        value * tvScale
    }
}

// MARK: - Collecting View

private struct TVCollectingView: View {
    @ObservedObject var viewModel: QuestionsGameViewModel
    @Environment(\.tvScale) private var tvScale

    var body: some View {
        VStack(spacing: scaled(36)) {
            Spacer()

            // Header
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
                // Aktueller Spieler
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

                // EKG-Linie
                TVSignalLine()
                    .frame(height: scaled(20))
                    .padding(.horizontal, scaled(60))

                // Status-Chips
                TVCollectingStatusRow(
                    players: viewModel.appModel.players,
                    currentPlayerID: currentPlayer.id,
                    answeredIDs: Set(round.answers.keys)
                )
                .padding(.horizontal, scaled(40))

                // Fortschritt
                Text("\(round.answers.count) VON \(viewModel.playerCount) ERFASST")
                    .font(.system(size: scaled(16), weight: .medium, design: .monospaced))
                    .foregroundStyle(QuestionsTheme.textMuted)
                    .tracking(scaled(2))
            }

            Spacer()
        }
    }

    private func scaled(_ value: CGFloat) -> CGFloat {
        value * tvScale
    }
}

// MARK: - Signal Line (EKG-Style)

private struct TVSignalLine: View {
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

    private func scaled(_ value: CGFloat) -> CGFloat {
        value * tvScale
    }
}

// MARK: - Collecting Status Row

private struct TVCollectingStatusRow: View {
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

    private func scaled(_ value: CGFloat) -> CGFloat {
        value * tvScale
    }
}

private enum CollectingStatus {
    case active, done, waiting
}

private struct TVCollectingChip: View {
    let name: String
    let status: CollectingStatus
    @Environment(\.tvScale) private var tvScale

    private var statusColor: Color {
        switch status {
        case .active: return QuestionsTheme.accentAmber
        case .done: return QuestionsTheme.accentGreen
        case .waiting: return QuestionsTheme.textMuted
        }
    }

    private var statusText: String {
        switch status {
        case .active: return "LIVE"
        case .done: return "OK"
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

    private func scaled(_ value: CGFloat) -> CGFloat {
        value * tvScale
    }
}

// MARK: - Overview View

private struct TVOverviewView: View {
    @ObservedObject var viewModel: QuestionsGameViewModel
    @Environment(\.tvScale) private var tvScale

    var body: some View {
        VStack(spacing: scaled(28)) {
            // Frage
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

            // Antwort-Grid
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

// MARK: - Answer Card

private struct TVAnswerCard: View {
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
            // Header
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

            // Divider
            Rectangle()
                .fill(QuestionsTheme.accentGreen.opacity(0.15))
                .frame(height: scaled(1))

            // Antwort
            Text(answer.text)
                .font(.system(size: scaled(18), design: .monospaced))
                .foregroundStyle(QuestionsTheme.textTypewriter)
                .frame(maxWidth: .infinity, alignment: .center)
                .multilineTextAlignment(.center)
                .frame(height: scaled(80))

            // Status-Badge
            if isCaught {
                HStack(spacing: scaled(4)) {
                    Image(systemName: "checkmark.seal.fill")
                    Text("VERIFIZIERT")
                }
                .font(.system(size: scaled(10), weight: .bold, design: .monospaced))
                .foregroundStyle(QuestionsTheme.accentSuccess)
                .padding(.horizontal, scaled(10))
                .padding(.vertical, scaled(5))
                .background(
                    Capsule()
                        .fill(QuestionsTheme.accentSuccess.opacity(0.2))
                )
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

    private func scaled(_ value: CGFloat) -> CGFloat {
        value * tvScale
    }
}

// MARK: - Results View

private struct TVResultsView: View {
    @ObservedObject var viewModel: QuestionsGameViewModel
    @Environment(\.tvScale) private var tvScale

    private var citizensWon: Bool {
        viewModel.lastRevealEvaluation?.citizensWon ?? false
    }

    var body: some View {
        VStack(spacing: scaled(50)) {
            Spacer()

            // Ergebnis-Header
            VStack(spacing: scaled(16)) {
                Text(citizensWon ? "LÜGE VERIFIZIERT" : "LÜGNER ENTKOMMEN")
                    .font(.system(size: scaled(50), weight: .black, design: .monospaced))
                    .foregroundStyle(citizensWon ? QuestionsTheme.accentGreen : QuestionsTheme.accentDanger)
                    .shadow(color: citizensWon ? QuestionsTheme.accentGreen.opacity(0.5) : QuestionsTheme.accentDanger.opacity(0.5), radius: scaled(20))

                Text(citizensWon ? "SUBJEKT ÜBERFÜHRT" : "MISSION GESCHEITERT")
                    .font(.system(size: scaled(20), weight: .medium, design: .monospaced))
                    .foregroundStyle(QuestionsTheme.textMuted)
                    .tracking(scaled(4))
            }

            // Lügner-Anzeige
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
            // Icon
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

            // Name
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

    private func scaled(_ value: CGFloat) -> CGFloat {
        value * tvScale
    }
}
