import SwiftUI

// MARK: - Reveal-Phase: Auflösung + Punkte-Anzeige
struct FFRevealPhaseView: View {
    @EnvironmentObject private var viewModel: FFViewModel

    @State private var appeared = false
    @State private var showPoints = false
    @State private var revealStep: Int = 0  // 0=Frage, 1=Antworten, 2=Punkte

    private var round: FFRound? { viewModel.currentRound }

    private var orderedSubmissions: [FFSubmission] {
        guard let round else { return [] }
        return round.displayOrder.compactMap { id in round.submission(for: id) }
    }

    var body: some View {
        ZStack {
            FFBackground()

            // Violetter Glow für Dramatik
            if revealStep >= 1 {
                VStack {
                    Spacer()
                    RadialGradient(
                        colors: [FFStyle.accentViolet.opacity(0.18), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 300
                    )
                    .frame(height: 400)
                }
                .transition(.opacity)
            }

            VStack(spacing: 0) {
                revealHeader
                    .padding(.horizontal, 20)
                    .padding(.top, 12)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Frage
                        questionCard
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 16)

                        // Antworten mit Auflösung
                        if revealStep >= 1 {
                            answersReveal
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }

                        // Punkte-Übersicht
                        if showPoints {
                            pointsSummary
                                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                        }

                        Color.clear.frame(height: 110)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }

            // Floating Next-Button
            VStack {
                Spacer()
                nextButton
                    .padding(.bottom, 36)
                    .opacity(appeared ? 1 : 0)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.82).delay(0.05)) {
                appeared = true
            }
            // Automatisch Antworten enthüllen
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    revealStep = 1
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    showPoints = true
                }
            }
        }
    }

    // MARK: - Header
    private var revealHeader: some View {
        HStack {
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                viewModel.returnToSetup()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(.ultraThinMaterial))
            }

            Spacer()

            VStack(spacing: 2) {
                Text("Runde \(viewModel.currentRoundNumber) / \(viewModel.totalRounds)")
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                Text("Auflösung")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(FFStyle.accentViolet)
            }

            Spacer()
            Circle().fill(Color.clear).frame(width: 36, height: 36)
        }
    }

    // MARK: - Frage-Karte
    private var questionCard: some View {
        VStack(spacing: 12) {
            if viewModel.settings.showCategoryHint, let category = round?.question.category {
                HStack(spacing: 6) {
                    Image(systemName: "tag.fill")
                        .font(.system(size: 10, weight: .bold))
                    Text(category.uppercased())
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .tracking(1.5)
                }
                .foregroundStyle(FFStyle.accentViolet)
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(FFStyle.accentViolet.opacity(0.12))
                        .overlay(Capsule().stroke(FFStyle.accentViolet.opacity(0.3), lineWidth: 1))
                )
            }

            Text(round?.question.localizedQuestion ?? "")
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .ffCard(isPrimary: true)
    }

    // MARK: - Antworten mit Auflösung
    private var answersReveal: some View {
        VStack(spacing: 10) {
            ForEach(Array(orderedSubmissions.enumerated()), id: \.element.id) { idx, submission in
                revealCard(submission: submission, index: idx)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(Double(idx) * 0.12), value: revealStep)
            }
        }
    }

    private func revealCard(submission: FFSubmission, index: Int) -> some View {
        let isAnswer = submission.isAnswer
        let fooledCount = submission.voterIds.count
        let voterNames = submission.voterIds.compactMap { id in
            viewModel.players.first(where: { $0.id == id })?.displayName
        }

        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                // Buchstaben-Badge
                ZStack {
                    Circle()
                        .fill(isAnswer ? Color.green.opacity(0.25) : Color.white.opacity(0.1))
                        .frame(width: 36, height: 36)
                    if isAnswer {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .black))
                            .foregroundStyle(Color.green)
                    } else {
                        Text(String(UnicodeScalar(65 + index)!))
                            .font(.system(size: 14, weight: .black, design: .rounded))
                            .foregroundStyle(FFStyle.textMuted)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(submission.text)
                        .font(.system(size: 15, weight: isAnswer ? .black : .semibold))
                        .foregroundStyle(isAnswer ? Color.green : .white)
                        .lineLimit(3)

                    if !isAnswer {
                        Text("Lüge von \(submission.playerName)")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(FFStyle.textMuted)
                    } else {
                        Text("Die echte Antwort")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Color.green.opacity(0.8))
                    }
                }

                Spacer()

                // Täuschungs-Badge oder Richtig-Zeiger
                if isAnswer && !submission.voterIds.isEmpty {
                    VStack(spacing: 2) {
                        Text("+2")
                            .font(.system(size: 13, weight: .black))
                            .foregroundStyle(Color.green)
                        Text("× \(submission.voterIds.count)")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(FFStyle.textMuted)
                    }
                } else if !isAnswer && fooledCount > 0 {
                    VStack(spacing: 2) {
                        Text("+\(fooledCount)")
                            .font(.system(size: 13, weight: .black))
                            .foregroundStyle(FFStyle.accentGold)
                        Image(systemName: "theatermasks.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(FFStyle.accentGold.opacity(0.7))
                    }
                }
            }

            // Wer hat diese Antwort gewählt?
            if !voterNames.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: isAnswer ? "checkmark.circle" : "person.fill.questionmark")
                        .font(.system(size: 10))
                        .foregroundStyle(isAnswer ? Color.green.opacity(0.7) : FFStyle.accentGold.opacity(0.7))
                    Text(voterNames.joined(separator: ", "))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(isAnswer ? Color.green.opacity(0.7) : FFStyle.accentGold.opacity(0.7))
                        .lineLimit(2)
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(isAnswer ? Color.green.opacity(0.08) : Color.white.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(isAnswer ? Color.green.opacity(0.4) : Color.white.opacity(0.07), lineWidth: isAnswer ? 1.5 : 1)
        )
    }

    // MARK: - Punkte-Zusammenfassung
    private var pointsSummary: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(FFStyle.accentGold)
                Text("PUNKTESTAND")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(FFStyle.textMuted)
                    .tracking(1.5)
            }

            ForEach(viewModel.sortedPlayers) { player in
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(FFStyle.accentViolet.opacity(0.15))
                            .frame(width: 32, height: 32)
                        Text(String(player.displayName.prefix(1).uppercased()))
                            .font(.system(size: 12, weight: .black))
                            .foregroundStyle(FFStyle.accentViolet)
                    }

                    Text(player.displayName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)

                    Spacer()

                    Text("\(player.score) Pkt")
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.04))
                )
            }
        }
        .padding(16)
        .ffCard()
    }

    // MARK: - Next-Button
    private var nextButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            viewModel.nextRound()
        } label: {
            HStack(spacing: 10) {
                Text(viewModel.isLastRound ? "Ergebnis anzeigen" : "Nächste Runde")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                Image(systemName: viewModel.isLastRound ? "trophy.fill" : "arrow.right")
                    .font(.system(size: 16, weight: .bold))
            }
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                Capsule()
                    .fill(FFStyle.primaryGradient)
                    .shadow(color: FFStyle.accentViolet.opacity(0.5), radius: 16, y: 6)
            )
        }
        .padding(.horizontal, 24)
    }
}
