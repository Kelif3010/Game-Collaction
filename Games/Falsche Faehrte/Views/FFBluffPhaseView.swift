import SwiftUI

// MARK: - Bluff-Phase: Jeder Spieler gibt reihum seine Lüge ein
struct FFBluffPhaseView: View {
    @EnvironmentObject private var viewModel: FFViewModel
    @FocusState private var textFieldFocused: Bool

    @State private var inputText = ""
    @State private var appeared = false
    @State private var shakeTrigger = false

    private var round: FFRound? { viewModel.currentRound }
    private var currentPlayer: FFPlayer? { viewModel.currentInputPlayer }

    var body: some View {
        ZStack {
            FFBackground()

            VStack(spacing: 0) {
                roundHeader
                    .padding(.horizontal, 20)
                    .padding(.top, 12)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 22) {
                        questionCard
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 20)

                        playerIndicator
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 16)

                        inputCard
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 12)

                        progressDots
                            .opacity(appeared ? 1 : 0)

                        Color.clear.frame(height: 100)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }

            // Floating Submit-Button
            VStack {
                Spacer()
                submitButton
                    .padding(.bottom, 36)
                    .opacity(appeared ? 1 : 0)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            inputText = viewModel.currentBluffText
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.05)) {
                appeared = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                textFieldFocused = true
            }
        }
        .onChange(of: viewModel.currentRound?.currentInputPlayerIndex) { _, _ in
            inputText = ""
            appeared = false
            withAnimation(.spring(response: 0.45, dampingFraction: 0.82).delay(0.05)) {
                appeared = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                textFieldFocused = true
            }
        }
    }

    // MARK: - Header
    private var roundHeader: some View {
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
                Text("Lügen eingeben")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(FFStyle.textMuted)
            }

            Spacer()

            // Platzhalter für symmetrisches Layout
            Circle().fill(Color.clear).frame(width: 36, height: 36)
        }
    }

    // MARK: - Frage-Karte
    private var questionCard: some View {
        VStack(spacing: 14) {
            // Kategorie-Badge (wenn aktiviert)
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

            // Detektiv-Icon
            ZStack {
                Circle()
                    .fill(FFStyle.accentViolet.opacity(0.15))
                    .frame(width: 56, height: 56)
                Image(systemName: "questionmark.bubble.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(FFStyle.primaryGradient)
            }

            // Frage
            Text(round?.question.localizedQuestion ?? "")
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 8)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .ffCard(isPrimary: true)
    }

    // MARK: - Spieler-Indikator
    private var playerIndicator: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(FFStyle.accentViolet.opacity(0.2))
                    .frame(width: 44, height: 44)
                Text(String(currentPlayer?.displayName.prefix(1).uppercased() ?? "?"))
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundStyle(FFStyle.accentViolet)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(currentPlayer?.displayName ?? "")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                Text("Gib jetzt deine Lüge ein!")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(FFStyle.textMuted)
            }

            Spacer()

            // Schild-Icon: Lüge-Symbol
            Image(systemName: "theatermasks.fill")
                .font(.system(size: 20))
                .foregroundStyle(FFStyle.accentViolet.opacity(0.5))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .ffCard()
    }

    // MARK: - Eingabe-Karte
    private var inputCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "pencil")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(FFStyle.accentViolet)
                Text("DEINE LÜGE")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(FFStyle.textMuted)
                    .tracking(1.5)
            }

            TextField("Eine glaubwürdige Antwort eingeben…", text: $inputText, axis: .vertical)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .tint(FFStyle.accentViolet)
                .focused($textFieldFocused)
                .lineLimit(3)
                .onChange(of: inputText) { _, new in
                    viewModel.currentBluffText = new
                }

            // Zeichenzähler
            HStack {
                Spacer()
                Text("\(inputText.count)/80")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(inputText.count > 80 ? FFStyle.accentCrimson : FFStyle.textSubtle)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: FFStyle.cornerRadius, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: FFStyle.cornerRadius, style: .continuous)
                        .stroke(textFieldFocused
                                ? FFStyle.accentViolet.opacity(0.5)
                                : Color.white.opacity(0.08), lineWidth: 1.5)
                )
        )
        .modifier(ShakeModifier(trigger: shakeTrigger))
    }

    // MARK: - Fortschritts-Punkte
    private var progressDots: some View {
        HStack(spacing: 8) {
            let currentIdx = round?.currentInputPlayerIndex ?? 0
            ForEach(viewModel.players.indices, id: \.self) { idx in
                let done = idx < currentIdx
                let active = idx == currentIdx
                Circle()
                    .fill(done ? FFStyle.accentViolet : (active ? FFStyle.accentViolet.opacity(0.5) : Color.white.opacity(0.15)))
                    .frame(width: active ? 10 : 7, height: active ? 10 : 7)
                    .overlay(
                        Circle().stroke(active ? FFStyle.accentViolet : Color.clear, lineWidth: 1.5)
                            .frame(width: 14, height: 14)
                    )
                    .animation(.spring(response: 0.3), value: active)
            }
        }
    }

    // MARK: - Submit-Button
    private var submitButton: some View {
        let trimmed = inputText.trimmingCharacters(in: .whitespaces)
        let isEmpty = trimmed.isEmpty
        let tooLong = trimmed.count > 80

        return Button {
            guard !isEmpty && !tooLong else {
                UINotificationFeedbackGenerator().notificationOccurred(.error)
                withAnimation(.default) { shakeTrigger.toggle() }
                return
            }
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            textFieldFocused = false
            viewModel.submitBluff(trimmed)
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16, weight: .bold))
                Text("Lüge einreichen")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
            }
            .foregroundStyle((!isEmpty && !tooLong) ? .black : .white.opacity(0.4))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                Capsule()
                    .fill((!isEmpty && !tooLong)
                          ? AnyShapeStyle(FFStyle.primaryGradient)
                          : AnyShapeStyle(LinearGradient(colors: [Color.white.opacity(0.08)],
                                                         startPoint: .leading, endPoint: .trailing)))
                    .shadow(color: (!isEmpty && !tooLong) ? FFStyle.accentViolet.opacity(0.5) : .clear,
                            radius: 16, y: 6)
            )
        }
        .disabled(isEmpty || tooLong)
        .animation(.spring(response: 0.3), value: isEmpty)
        .padding(.horizontal, 24)
    }
}

// MARK: - Shake-Modifier
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
