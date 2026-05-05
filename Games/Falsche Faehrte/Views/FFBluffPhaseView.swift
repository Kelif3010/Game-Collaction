import SwiftUI

// MARK: - Bluff-Phase: Jeder Spieler gibt reihum seine Lüge ein
struct FFBluffPhaseView: View {
    @Environment(FFViewModel.self) private var viewModel
    @FocusState private var textFieldFocused: Bool

    @State private var inputText = ""
    @State private var appeared = false
    @State private var playerAppeared = false
    @State private var shakeTrigger = false
    @State private var inputGlow: CGFloat = 0.0
    @State private var lightHaptic = false
    @State private var mediumHaptic = false
    @State private var errorHaptic = false

    private var round: FFRound? { viewModel.currentRound }
    private var currentPlayer: FFPlayer? { viewModel.currentInputPlayer }
    private var currentIdx: Int { round?.currentInputPlayerIndex ?? 0 }
    private var totalPlayers: Int { viewModel.players.count }

    var body: some View {
        ZStack {
            FFBackground()

            if viewModel.isMultiplayer && viewModel.hasSubmittedBluff {
                mpWaitingView
            } else {
                GeometryReader { geo in
                    VStack(spacing: 0) {
                        topBar
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                            .padding(.bottom, 4)

                        questionZone
                            .frame(height: questionHeight(in: geo.size.height))

                        if !viewModel.isMultiplayer {
                            playerDivider
                                .padding(.horizontal, 24)
                                .padding(.vertical, 4)
                        } else {
                            dividerLine
                                .padding(.horizontal, 24)
                                .padding(.vertical, 4)
                        }

                        inputZone
                            .padding(.horizontal, 20)
                            .padding(.top, 16)

                        Spacer(minLength: 0)
                    }
                    .safeAreaInset(edge: .bottom) {
                        submitButton
                            .padding(.horizontal, 20)
                            .padding(.bottom, 16)
                            .padding(.top, 12)
                            .opacity(appeared ? 1 : 0)
                    }
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .sensoryFeedback(.impact(weight: .light), trigger: lightHaptic)
        .sensoryFeedback(.impact(weight: .medium), trigger: mediumHaptic)
        .sensoryFeedback(.error, trigger: errorHaptic)
        .animation(.snappy(duration: 0.35), value: textFieldFocused)
        .onAppear {
            inputText = ""
            shakeTrigger = false
            inputGlow = 0
            textFieldFocused = false
            inputText = viewModel.currentBluffText
            withAnimation(.spring(duration: 0.5, bounce: 0.2).delay(0.05)) {
                appeared = true
            }
            withAnimation(.spring(duration: 0.45, bounce: 0.25).delay(0.3)) {
                playerAppeared = true
            }
        }
        .onChange(of: viewModel.currentRound?.currentInputPlayerIndex) { _, _ in
            inputText = ""
            inputGlow = 0
            appeared = false
            playerAppeared = false
            withAnimation(.spring(duration: 0.45, bounce: 0.15).delay(0.05)) {
                appeared = true
            }
            withAnimation(.spring(duration: 0.45, bounce: 0.25).delay(0.25)) {
                playerAppeared = true
            }
        }
        .simultaneousGesture(
            TapGesture().onEnded {
                textFieldFocused = false
            }
        )
        .onChange(of: viewModel.currentRoundIndex) { _, _ in
            inputText = viewModel.currentBluffText
            shakeTrigger = false
            inputGlow = 0
            textFieldFocused = false
        }
    }

    private func questionHeight(in height: CGFloat) -> CGFloat {
        textFieldFocused ? max(120, height * 0.24) : height * 0.40
    }

    // MARK: - Top Bar: X + Story-Bar + Runde
    private var topBar: some View {
        HStack(spacing: 12) {
            Button {
                lightHaptic.toggle()
                viewModel.returnToSetup()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white.opacity(0.55))
                    .frame(width: 30, height: 30)
                    .background(Circle().fill(Color.white.opacity(0.07)))
            }

            // Story-Segmente (ein Segment pro Spieler)
            HStack(spacing: 3) {
                ForEach(0..<totalPlayers, id: \.self) { idx in
                    Capsule()
                        .fill(
                            idx < currentIdx
                                ? FFStyle.accentViolet
                                : idx == currentIdx
                                    ? FFStyle.accentViolet.opacity(0.45)
                                    : Color.white.opacity(0.12)
                        )
                        .frame(height: 3)
                        .animation(.snappy(duration: 0.35), value: currentIdx)
                }
            }

            // Runden-Badge
            Text("\(viewModel.currentRoundNumber)/\(viewModel.totalRounds)")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.38))
                .frame(width: 30, alignment: .trailing)
        }
        .frame(height: 42)
    }

    // MARK: - Question Zone: kein Karten-Rahmen, pure Atmosphäre
    private var questionZone: some View {
        ZStack {
            // Atmosphärischer Hintergrund-Glow
            RadialGradient(
                colors: [FFStyle.accentViolet.opacity(0.22), Color.clear],
                center: .center,
                startRadius: 0,
                endRadius: 200
            )
            .allowsHitTesting(false)

            VStack(spacing: 14) {
                Spacer()

                // Kategorie-Chip
                if viewModel.settings.showCategoryHint,
                   let category = round?.question.category {
                    Text(category.uppercased())
                        .font(.system(size: 9, weight: .black, design: .monospaced))
                        .tracking(3)
                        .foregroundStyle(FFStyle.accentViolet)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(FFStyle.accentViolet.opacity(0.1))
                                .overlay(Capsule().stroke(FFStyle.accentViolet.opacity(0.3), lineWidth: 1))
                        )
                        .opacity(appeared ? 1 : 0)
                        .animation(.easeOut(duration: 0.4).delay(0.1), value: appeared)
                }

                // Hero-Frage
                Text(round?.question.localizedQuestion(languageCode: viewModel.languageCode) ?? "")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
                    .padding(.horizontal, 24)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 14)
                    .animation(.spring(duration: 0.55, bounce: 0.2).delay(0.08), value: appeared)

                Spacer()
            }
        }
    }

    // MARK: - Spieler-Divider: Name sitzt in der Trennlinie
    private var playerDivider: some View {
        HStack(spacing: 0) {
            fadeLine(direction: .trailing)

            if let player = currentPlayer {
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(FFStyle.accentViolet.opacity(0.18))
                            .frame(width: 26, height: 26)
                        Text(String(player.displayName.prefix(1).uppercased()))
                            .font(.system(size: 11, weight: .black))
                            .foregroundStyle(FFStyle.accentViolet)
                    }
                    Text(player.displayName)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.9))
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .minimumScaleFactor(0.85)
                        .layoutPriority(1)
                    Image(systemName: "theatermasks.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(FFStyle.accentViolet.opacity(0.6))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(
                    Capsule()
                        .fill(Color.black.opacity(0.5))
                        .overlay(
                            Capsule()
                                .stroke(FFStyle.accentViolet.opacity(0.28), lineWidth: 1)
                        )
                )
                .scaleEffect(playerAppeared ? 1 : 0.6)
                .opacity(playerAppeared ? 1 : 0)
                .animation(.bouncy(duration: 0.4), value: playerAppeared)
            }

            fadeLine(direction: .leading)
        }
    }

    // Einfache Trennlinie für Multiplayer (kein Spieler-Chip)
    private var dividerLine: some View {
        HStack(spacing: 0) {
            fadeLine(direction: .trailing)
            Image(systemName: "theatermasks.fill")
                .font(.system(size: 13))
                .foregroundStyle(FFStyle.accentViolet.opacity(0.5))
                .padding(.horizontal, 14)
            fadeLine(direction: .leading)
        }
    }

    private func fadeLine(direction: UnitPoint) -> some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: direction == .trailing
                        ? [Color.clear, FFStyle.accentViolet.opacity(0.3)]
                        : [FFStyle.accentViolet.opacity(0.3), Color.clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: 1)
    }

    // MARK: - Input Zone: dynamisches Glühen
    private var inputZone: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("DEINE LÜGE")
                .font(.system(size: 9, weight: .black, design: .monospaced))
                .tracking(3)
                .foregroundStyle(FFStyle.accentViolet.opacity(0.65))
                .opacity(appeared ? 1 : 0)

            ZStack(alignment: .bottomTrailing) {
                TextField("Eine glaubwürdige Antwort…", text: $inputText, axis: .vertical)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .tint(FFStyle.accentViolet)
                    .focused($textFieldFocused)
                    .submitLabel(.done)
                    .onSubmit {
                        textFieldFocused = false
                    }
                    .lineLimit(3)
                    .padding(16)
                    .padding(.bottom, 10)
                    .onChange(of: inputText) { _, new in
                        let sanitized = new.components(separatedBy: .newlines).joined(separator: " ")
                        if sanitized != new {
                            inputText = sanitized
                            textFieldFocused = false
                        }

                        viewModel.currentBluffText = sanitized
                        let count = sanitized.trimmingCharacters(in: .whitespaces).count
                        withAnimation(.easeInOut(duration: 0.25)) {
                            inputGlow = count == 0 ? 0 : count > 80 ? 0 : min(CGFloat(count) / 30.0, 1.0)
                        }
                    }

                // Zeichenzähler
                let count = inputText.trimmingCharacters(in: .whitespaces).count
                Text("\(count)/80")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(count > 80 ? FFStyle.accentCrimson : .white.opacity(0.22))
                    .padding(12)
            }
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(
                                textFieldFocused
                                    ? AnyShapeStyle(LinearGradient(
                                        colors: [
                                            FFStyle.accentViolet.opacity(0.75),
                                            FFStyle.accentIndigo.opacity(0.45)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ))
                                    : AnyShapeStyle(Color.white.opacity(0.08)),
                                lineWidth: 1.5
                            )
                    )
                    .shadow(
                        color: FFStyle.accentViolet.opacity(inputGlow * 0.5),
                        radius: 24,
                        y: 4
                    )
            )
            .modifier(ShakeModifier(trigger: shakeTrigger))
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 10)
            .animation(.spring(duration: 0.5, bounce: 0.2).delay(0.15), value: appeared)
        }
    }

    // MARK: - Submit Button
    private var submitButton: some View {
        let trimmed = inputText.trimmingCharacters(in: .whitespaces)
        let canSubmit = !trimmed.isEmpty && trimmed.count <= 80

        return Button {
            guard canSubmit else {
                errorHaptic.toggle()
                withAnimation(.default) { shakeTrigger.toggle() }
                return
            }
            mediumHaptic.toggle()
            textFieldFocused = false
            if viewModel.isMultiplayer {
                viewModel.submitBluffMultiplayer(trimmed)
            } else {
                viewModel.submitBluff(trimmed)
            }
        } label: {
            HStack(spacing: 10) {
                Text(canSubmit ? "Lüge einreichen" : "Lüge eingeben…")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                if canSubmit {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 17, weight: .bold))
                }
            }
            .foregroundStyle(canSubmit ? .black : .white.opacity(0.28))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                Capsule()
                    .fill(
                        canSubmit
                            ? AnyShapeStyle(FFStyle.primaryGradient)
                            : AnyShapeStyle(Color.white.opacity(0.07))
                    )
                    .shadow(
                        color: canSubmit ? FFStyle.accentViolet.opacity(0.55) : .clear,
                        radius: 22, y: 6
                    )
            )
        }
        .disabled(!canSubmit)
        .animation(.snappy(duration: 0.25), value: canSubmit)
    }

    // MARK: - Multiplayer Warte-Screen
    private var mpWaitingView: some View {
        let submitted = viewModel.bluffSubmittedCount
        let total = viewModel.totalMultiplayerPlayers
        let progress = total > 0 ? CGFloat(submitted) / CGFloat(total) : 0

        return VStack(spacing: 36) {
            Spacer()

            // Icon mit Puls-Ring
            ZStack {
                Circle()
                    .fill(FFStyle.accentViolet.opacity(0.06))
                    .frame(width: 110, height: 110)
                Circle()
                    .stroke(FFStyle.accentViolet.opacity(0.15), lineWidth: 1)
                    .frame(width: 90, height: 90)
                Circle()
                    .fill(FFStyle.accentViolet.opacity(0.12))
                    .frame(width: 72, height: 72)
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(FFStyle.primaryGradient)
            }

            VStack(spacing: 8) {
                Text("Lüge übermittelt")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                Text("Warte auf die anderen Spieler")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.4))
            }

            // Fortschritt
            VStack(spacing: 14) {
                // Player dots
                HStack(spacing: 8) {
                    ForEach(0..<total, id: \.self) { idx in
                        Circle()
                            .fill(idx < submitted
                                  ? FFStyle.accentViolet
                                  : Color.white.opacity(0.12))
                            .frame(width: 8, height: 8)
                            .animation(.snappy(duration: 0.35).delay(Double(idx) * 0.05), value: submitted)
                    }
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.06))
                            .frame(height: 3)
                        Capsule()
                            .fill(FFStyle.primaryGradient)
                            .frame(width: geo.size.width * progress, height: 3)
                            .animation(.smooth(duration: 0.5), value: submitted)
                    }
                }
                .frame(height: 3)
                .padding(.horizontal, 48)

                Text("\(submitted) von \(total) eingereicht")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.3))
            }

            Spacer()
        }
    }
}

// MARK: - Shake-Modifier (unverändert)
struct ShakeModifier: ViewModifier {
    var trigger: Bool

    func body(content: Content) -> some View {
        content
            .keyframeAnimator(initialValue: 0.0, trigger: trigger) { view, offset in
                view.offset(x: offset)
            } keyframes: { _ in
                KeyframeTrack {
                    LinearKeyframe(0, duration: 0.05)
                    LinearKeyframe(-8, duration: 0.08)
                    LinearKeyframe(8, duration: 0.08)
                    LinearKeyframe(-6, duration: 0.07)
                    LinearKeyframe(6, duration: 0.07)
                    LinearKeyframe(0, duration: 0.05)
                }
            }
    }
}

#Preview {
    FFBluffPhaseView()
        .environment(FFViewModel.preview)
}
