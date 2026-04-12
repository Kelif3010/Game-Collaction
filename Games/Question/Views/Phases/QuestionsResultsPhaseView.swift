import SwiftUI

struct QuestionsResultsPhaseView: View {
    @ObservedObject var viewModel: QuestionsGameViewModel
    @Environment(\.dismiss) var dismiss

    // Animation States
    @State private var revealStage: Int = 0
    @State private var stampScale: CGFloat = 4.0
    @State private var stampOpacity: Double = 0.0
    @State private var stampRotation: Double = -25
    @State private var shakeIntensity: CGFloat = 0
    @State private var showPaperclip: Bool = false
    @State private var documentOffset: CGFloat = 100
    @State private var documentOpacity: Double = 0

    var body: some View {
        let evaluation = viewModel.lastRevealEvaluation

        // Logik: Wer wurde gewählt?
        let suspectID = evaluation?.selected.first
        let suspectName = suspectID.map { viewModel.playerName(for: $0) } ?? "Niemand"

        // Logik: War er ein Lügner?
        let liars = evaluation?.liars ?? viewModel.currentLiarIDs
        let isLiar = suspectID.map { liars.contains($0) } ?? false
        let citizensWon = evaluation?.citizensWon ?? false
        let liarQuestionText = viewModel.currentRound?.promptPair.liarQuestion ?? "Unbekannt"

        // Stempel-Typ bestimmen
        let stampType: StampView.StampType
        let stampText: String

        if citizensWon {
            stampType = .guilty
            stampText = "LÜGNER"
        } else if suspectID == nil {
            stampType = .escaped
            stampText = "ENTKOMMEN"
        } else if isLiar {
            stampType = .guilty
            stampText = "LÜGNER"
        } else {
            stampType = .innocent
            stampText = "EHRLICH"
        }

        return ZStack {
            // Hintergrund mit hohem Stress-Level
            QuestionsBackgroundView(stressLevel: 0.85)
                .ignoresSafeArea()

            // Phase 0: Analyse-Intro
            if revealStage == 0 {
                AnalysisIntroView()
                    .transition(.opacity)
            }

            // Phase 1+: Das Dokument
            if revealStage >= 1 {
                VStack(spacing: 0) {
                    Spacer()

                    // Die Akte
                    DossierView(
                        suspectName: suspectName,
                        liarQuestion: liarQuestionText,
                        showName: revealStage >= 1,
                        showStamp: revealStage >= 2,
                        stampText: stampText,
                        stampType: stampType,
                        stampScale: stampScale,
                        stampOpacity: stampOpacity,
                        stampRotation: stampRotation,
                        showPaperclip: showPaperclip
                    )
                    .shake(trigger: shakeIntensity > 0, intensity: shakeIntensity)
                    .offset(y: documentOffset)
                    .opacity(documentOpacity)

                    Spacer()

                    // Phase 3: Aufklärung & Buttons
                    if revealStage >= 3 {
                        ResultsFooterView(
                            citizensWon: citizensWon,
                            liars: liars,
                            viewModel: viewModel,
                            onNextRound: { viewModel.startRound() },
                            onExit: { dismiss() }
                        )
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            }
        }
        .onAppear {
            runSequence()
        }
    }

    private func runSequence() {
        // Step 0 -> 1: Dokument erscheint
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                revealStage = 1
                documentOffset = 0
                documentOpacity = 1
            }
            // Papier-Geräusch-Haptik
            UISelectionFeedbackGenerator().selectionChanged()
        }

        // Büroklammer erscheint
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                showPaperclip = true
            }
        }

        // Step 1 -> 2: STEMPEL!
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            revealStage = 2

            // Stempel-Animation
            withAnimation(.spring(response: 0.15, dampingFraction: 0.3)) {
                stampScale = 1.0
                stampOpacity = 1.0
                stampRotation = -12
            }

            // Screen-Shake
            withAnimation(.easeOut(duration: 0.1)) {
                shakeIntensity = 15
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeOut(duration: 0.3)) {
                    shakeIntensity = 0
                }
            }

            // Schwerer Impact
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
            }
        }

        // Step 2 -> 3: Buttons erscheinen
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
            withAnimation(.easeOut(duration: 0.5)) {
                revealStage = 3
            }
        }
    }
}

// MARK: - Analyse-Intro View
private struct AnalysisIntroView: View {
    @State private var dots = ""

    var body: some View {
        VStack(spacing: 24) {
            // Polygraph-Icon
            Image(systemName: "waveform.path.ecg")
                .font(.system(size: 60))
                .foregroundStyle(QuestionsTheme.accentGreen)
                .shadow(color: QuestionsTheme.accentGreen.opacity(0.5), radius: 10)

            Text("BIOMETRISCHE ANALYSE\(dots)")
                .font(.system(.title3, design: .monospaced))
                .foregroundStyle(QuestionsTheme.accentGreen)
                .tracking(2)

            // Scan-Balken
            ScanningBar()
        }
        .onAppear {
            animateDots()
        }
    }

    private func animateDots() {
        Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { timer in
            if dots.count >= 3 {
                dots = ""
            } else {
                dots += "."
            }
        }
    }
}

// MARK: - Scanning Bar
private struct ScanningBar: View {
    @State private var progress: CGFloat = 0

    var body: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.black.opacity(0.5))
                .frame(width: 200, height: 4)

            RoundedRectangle(cornerRadius: 2)
                .fill(QuestionsTheme.accentGreen)
                .frame(width: 200 * progress, height: 4)
                .shadow(color: QuestionsTheme.accentGreen.opacity(0.8), radius: 4)
        }
        .onAppear {
            withAnimation(.linear(duration: 1.3)) {
                progress = 1.0
            }
        }
    }
}

// MARK: - Dossier (Akte) View
private struct DossierView: View {
    let suspectName: String
    let liarQuestion: String
    let showName: Bool
    let showStamp: Bool
    let stampText: String
    let stampType: StampView.StampType
    let stampScale: CGFloat
    let stampOpacity: Double
    let stampRotation: Double
    let showPaperclip: Bool

    @State private var displayedName = ""
    @State private var cursorVisible = true

    var body: some View {
        ZStack {
            // Papier-Hintergrund
            RoundedRectangle(cornerRadius: 4)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.18, green: 0.16, blue: 0.12),
                            Color(red: 0.14, green: 0.12, blue: 0.08),
                            Color(red: 0.12, green: 0.10, blue: 0.06)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    // Papier-Textur
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.02))
                )
                .overlay(
                    // Rand
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.black.opacity(0.5), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.5), radius: 20, x: 0, y: 10)

            VStack(alignment: .leading, spacing: 20) {
                // Header: CLASSIFIED
                HStack {
                    Text("GEHEIM")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundStyle(QuestionsTheme.accentDanger)
                        .tracking(4)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .overlay(
                            Rectangle()
                                .stroke(QuestionsTheme.accentDanger, lineWidth: 1)
                        )

                    Spacer()

                    Text("AKTE NR. \(Int.random(in: 1000...9999))")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(QuestionsTheme.textMuted)
                }

                Divider()
                    .background(QuestionsTheme.textMuted.opacity(0.3))

                // Subject-Zeile
                VStack(alignment: .leading, spacing: 8) {
                    Text("SUBJEKT:")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(QuestionsTheme.textMuted)
                        .tracking(2)

                    HStack(spacing: 0) {
                        Text(displayedName)
                        .font(.system(size: 30, weight: .bold, design: .monospaced))
                        .foregroundStyle(QuestionsTheme.textTypewriter)

                        if displayedName.count < suspectName.count {
                            Text("▌")
                                .font(.system(size: 30, weight: .bold, design: .monospaced))
                                .foregroundStyle(QuestionsTheme.accentGreen)
                                .opacity(cursorVisible ? 1 : 0)
                        }
                    }
                    .opacity(showName ? 1 : 0)
                    .animation(.easeOut(duration: 0.3), value: showName)
                }

                // Status-Zeile
                HStack {
                    Text("STATUS:")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(QuestionsTheme.textMuted)
                        .tracking(2)

                    Text("AUSWERTUNG ABGESCHLOSSEN")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(QuestionsTheme.accentGreen)
                }
                .opacity(showStamp ? 1 : 0)

                VStack(alignment: .leading, spacing: 6) {
                    Text("SPION-FRAGE:")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(QuestionsTheme.textMuted)
                        .tracking(2)

                    Text(LocalizedStringKey(liarQuestion))
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundStyle(QuestionsTheme.textTypewriter)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.black.opacity(0.18))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(QuestionsTheme.textMuted.opacity(0.2), lineWidth: 1)
                        )
                }

                Spacer()

                // Unterschrift-Linie
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(QuestionsTheme.textMuted.opacity(0.3))
                                .frame(width: 120, height: 1)
                            Text("K. Prüfer")
                                .font(.system(size: 11, design: .monospaced))
                                .italic()
                                .foregroundStyle(QuestionsTheme.textTypewriter.opacity(0.7))
                                .offset(y: -8)
                                .rotationEffect(.degrees(-2))
                        }
                        Text("PRÜFER")
                            .font(.system(size: 8, design: .monospaced))
                            .foregroundStyle(QuestionsTheme.textMuted)
                    }

                    Spacer()

                    Text(Date(), style: .date)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(QuestionsTheme.textMuted)
                }
            }
            .padding(24)

            // Stempel
            if showStamp {
                StampView(text: stampText, type: stampType, rotation: stampRotation)
                    .scaleEffect(stampScale)
                    .opacity(stampOpacity)
                    .offset(x: 40, y: -32)
            }

            // Büroklammer
            if showPaperclip {
                PaperclipView()
                    .offset(x: -140, y: -120)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(width: 320, height: 380)
        .onChange(of: showName) { _, show in
            if show {
                typewriterEffect()
                startCursorBlink()
            }
        }
        .onAppear {
            if showName && displayedName.isEmpty {
                typewriterEffect()
                startCursorBlink()
            }
        }
    }

    private func typewriterEffect() {
        displayedName = ""
        for (index, char) in suspectName.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.08) {
                displayedName += String(char)
                UISelectionFeedbackGenerator().selectionChanged()
            }
        }
    }

    private func startCursorBlink() {
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            cursorVisible.toggle()
        }
    }
}

// MARK: - Büroklammer
private struct PaperclipView: View {
    var body: some View {
        ZStack {
            // Äußere Klammer
            RoundedRectangle(cornerRadius: 8)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color(red: 0.7, green: 0.7, blue: 0.75),
                            Color(red: 0.5, green: 0.5, blue: 0.55)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 3
                )
                .frame(width: 24, height: 50)

            // Innere Klammer
            RoundedRectangle(cornerRadius: 5)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color(red: 0.6, green: 0.6, blue: 0.65),
                            Color(red: 0.45, green: 0.45, blue: 0.5)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 2
                )
                .frame(width: 14, height: 35)
                .offset(y: 5)
        }
        .rotationEffect(.degrees(-15))
        .shadow(color: Color.black.opacity(0.3), radius: 2, x: 1, y: 1)
    }
}

// MARK: - Results Footer
private struct ResultsFooterView: View {
    let citizensWon: Bool
    let liars: Set<UUID>
    let viewModel: QuestionsGameViewModel
    let onNextRound: () -> Void
    let onExit: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            liarRevealSection
            buttonSection
        }
        .padding(.bottom, 40)
    }

    @ViewBuilder
    private var liarRevealSection: some View {
        if !citizensWon && !liars.isEmpty {
            VStack(spacing: 10) {
                Text("TATSÄCHLICHE LÜGNER:")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(QuestionsTheme.accentDanger)
                    .tracking(2)

                ForEach(Array(liars), id: \.self) { id in
                    Text(viewModel.playerName(for: id))
                        .font(.system(.title3, design: .monospaced).bold())
                        .foregroundStyle(QuestionsTheme.textPrimary)
                }
            }
            .padding(16)
            .background(liarRevealBackground)
        }
    }

    private var liarRevealBackground: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(QuestionsTheme.accentDanger.opacity(0.1))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(QuestionsTheme.accentDanger.opacity(0.3), lineWidth: 1)
            )
    }

    private var buttonSection: some View {
        VStack(spacing: 12) {
            nextRoundButton
            exitButton
        }
        .padding(.horizontal, 40)
    }

    private var nextRoundButton: some View {
        Button(action: onNextRound) {
            HStack {
                Image(systemName: "arrow.clockwise")
                Text("Nächste Analyse")
            }
            .font(.system(.headline, design: .monospaced))
            .foregroundStyle(QuestionsTheme.textOnDark)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(QuestionsStyle.buttonGradient)
            .clipShape(Capsule())
            .shadow(color: QuestionsTheme.accentGreen.opacity(0.3), radius: 8, y: 4)
        }
    }

    private var exitButton: some View {
        Button(action: onExit) {
            Text("Programm beenden")
                .font(.system(.subheadline, design: .monospaced))
                .foregroundStyle(QuestionsTheme.textMuted)
        }
    }
}
