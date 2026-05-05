import SwiftUI
import Pow
import SFSafeSymbols

struct OnboardingView: View {

    private enum Step: Int, CaseIterable {
        case wow, value, name

        var buttonTitle: String {
            self == .name ? "Loslegen" : "Weiter"
        }
    }

    private enum FocusField: Hashable { case playerName }

    @AppStorage("myPlayerName")     private var myPlayerName     = ""
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @FocusState private var focused: FocusField?

    @State private var step:           Step  = .wow
    @State private var nameInput:      String = ""
    @State private var appeared:       Bool   = false
    @State private var confirmTrigger: Int    = 0
    @State private var invalidTrigger: Int    = 0
    @State private var chipReveal:     Int    = 0

    private var trimmed: String { nameInput.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var nameOK:  Bool   { !trimmed.isEmpty }

    // MARK: – Body

    var body: some View {
        ZStack {
            background.ignoresSafeArea()

            VStack(spacing: 0) {
                progressRow
                    .padding(.top, 20)
                    .padding(.horizontal, 28)

                Spacer(minLength: 0)

                contentArea
                    .padding(.horizontal, 28)
                    .id(step)
                    .transition(reduceMotion ? .opacity : .asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal:   .move(edge: .leading).combined(with: .opacity)
                    ))

                Spacer(minLength: 0)

                actionButton
                    .padding(.horizontal, 24)
                    .padding(.bottom, 48)
            }
        }
        .onAppear {
            nameInput = myPlayerName
            guard !appeared else { return }
            withAnimation(reduceMotion ? nil : .spring(duration: 0.55, bounce: 0.2)) {
                appeared = true
            }
        }
        .onChange(of: step, initial: true) { _, s in onStepChange(s) }
        .sensoryFeedback(.selection, trigger: step)
        .sensoryFeedback(.success,   trigger: confirmTrigger)
        .sensoryFeedback(trigger: invalidTrigger) { old, new in new > old ? .warning : nil }
    }

    // MARK: – Background

    private var background: some View {
        ZStack {
            LinearGradient(
                stops: [
                    .init(color: Color(red: 0.04, green: 0.04, blue: 0.14), location: 0),
                    .init(color: Color(red: 0.08, green: 0.05, blue: 0.22), location: 0.45),
                    .init(color: Color(red: 0.02, green: 0.02, blue: 0.10), location: 1)
                ],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )

            // Glow orbs
            glowOrb(color: .cyan,   size: 380, opacity: 0.22, x: -140, y: -320)
            glowOrb(color: .purple, size: 300, opacity: 0.18, x:  130, y:   20)
            glowOrb(color: Color(red: 0.9, green: 0.6, blue: 0.1),
                    size: 260, opacity: 0.14, x: 100, y: 360)
        }
    }

    private func glowOrb(color: Color, size: CGFloat, opacity: Double, x: CGFloat, y: CGFloat) -> some View {
        Circle()
            .fill(color.opacity(opacity))
            .frame(width: size, height: size)
            .blur(radius: size * 0.18)
            .offset(x: x, y: y)
            .accessibilityHidden(true)
    }

    // MARK: – Progress Row

    private var progressRow: some View {
        HStack(spacing: 0) {
            // Back button
            if step != .wow {
                Button { goBack() } label: {
                    Image(systemName: "chevron.left")
                        .font(.body.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                        .background(.white.opacity(0.10), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Zurück")
                .transition(.opacity.combined(with: .scale))
            } else {
                Color.clear.frame(width: 40, height: 40)
            }

            Spacer()

            // Step dots
            HStack(spacing: 7) {
                ForEach(Step.allCases, id: \.self) { s in
                    Capsule()
                        .fill(s.rawValue <= step.rawValue ? Color.white : Color.white.opacity(0.22))
                        .frame(width: s == step ? 22 : 7, height: 7)
                        .animation(reduceMotion ? nil : .spring(duration: 0.35, bounce: 0.3), value: step)
                }
            }

            Spacer()

            Color.clear.frame(width: 40, height: 40)
        }
        .opacity(appeared ? 1 : 0)
        .animation(reduceMotion ? nil : .easeIn(duration: 0.4), value: appeared)
    }

    // MARK: – Step Content

    @ViewBuilder
    private var contentArea: some View {
        switch step {
        case .wow:   wowContent
        case .value: valueContent
        case .name:  nameContent
        }
    }

    // Step 1 ─────────────────────────────────────────────────────────────────

    private var wowContent: some View {
        VStack(spacing: 32) {
            heroIcon
                .scaleEffect(appeared ? 1 : 0.7)
                .opacity(appeared ? 1 : 0)
                .animation(reduceMotion ? nil : .spring(duration: 0.65, bounce: 0.35), value: appeared)

            VStack(spacing: 14) {
                Text("Spiele.\nLachen.\nLegenden.")
                    .font(.system(size: 46, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .accessibilityAddTraits(.isHeader)

                Text("Deine Sammlung für legendäre\nSpielabende – jederzeit bereit.")
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.68))
                    .multilineTextAlignment(.center)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 16)
            .animation(reduceMotion ? nil : .spring(duration: 0.6, bounce: 0.2).delay(0.15), value: appeared)
        }
    }

    private var heroIcon: some View {
        ZStack {
            // Outer glow ring
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.cyan.opacity(0.35), .clear],
                        center: .center, startRadius: 60, endRadius: 120
                    )
                )
                .frame(width: 240, height: 240)
                .blur(radius: 12)

            // Inner circle
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.18, green: 0.22, blue: 0.55), Color(red: 0.08, green: 0.10, blue: 0.30)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
                .frame(width: 150, height: 150)
                .shadow(color: .cyan.opacity(0.4), radius: 28, y: 8)

            Image(systemName: "gamecontroller.fill")
                .font(.system(size: 64, weight: .bold))
                .foregroundStyle(.white)
        }
        .accessibilityHidden(true)
    }

    // Step 2 ─────────────────────────────────────────────────────────────────

    private var valueContent: some View {
        VStack(alignment: .leading, spacing: 28) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Was dich erwartet")
                    .font(.system(.title, design: .rounded, weight: .bold))
                    .foregroundStyle(.white)
                    .accessibilityAddTraits(.isHeader)

                Text("Alles für schnelle Gruppenrunden\nan einem Ort.")
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.64))
            }

            VStack(spacing: 0) {
                featureRow(symbol: "gamecontroller.fill", color: .cyan,
                           title: "6 Spiele für jede Runde",
                           detail: "Sofort bereit für kleine und große Gruppen.",
                           index: 0)
                featureDivider
                featureRow(symbol: "wifi", color: .green,
                           title: "Multiplayer über WLAN",
                           detail: "Zusammen spielen, ohne kompliziertes Setup.",
                           index: 1)
                featureDivider
                featureRow(symbol: "trophy.fill", color: Color(red: 1, green: 0.75, blue: 0.1),
                           title: "Punkte & Leaderboards",
                           detail: "Fortschritt und Sieger direkt in der App.",
                           index: 2)
            }
            .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
    }

    private func featureRow(symbol: String, color: Color, title: String, detail: String, index: Int) -> some View {
        HStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(color.opacity(0.18))
                .frame(width: 52, height: 52)
                .overlay {
                    Image(systemName: symbol)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(color)
                }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.white)
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.58))
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .opacity(chipReveal > index ? 1 : 0)
        .offset(y: chipReveal > index || reduceMotion ? 0 : 14)
        .animation(reduceMotion ? nil : .spring(duration: 0.5, bounce: 0.15).delay(Double(index) * 0.10), value: chipReveal)
        .accessibilityElement(children: .combine)
    }

    private var featureDivider: some View {
        Divider()
            .background(.white.opacity(0.08))
            .padding(.leading, 86)
    }

    // Step 3 ─────────────────────────────────────────────────────────────────

    private var nameContent: some View {
        VStack(spacing: 28) {
            VStack(spacing: 10) {
                Text("Wie heißt du?")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)

                Text("Dein Name erscheint in Multiplayer-Runden\nund auf dem Leaderboard.")
                    .font(.callout)
                    .foregroundStyle(.white.opacity(0.64))
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 10) {
                TextField("Dein Spielername", text: $nameInput)
                    .font(.title3.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white)
                    .tint(.cyan)
                    .padding(.vertical, 20)
                    .padding(.horizontal, 20)
                    .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(nameOK ? Color.cyan.opacity(0.6) : Color.white.opacity(0.12), lineWidth: 1.5)
                    )
                    .focused($focused, equals: .playerName)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .textContentType(.name)
                    .submitLabel(.go)
                    .onSubmit { confirmName() }
                    .accessibilityLabel("Spielername")
                    .accessibilityHint("Wird nur auf diesem Gerät gespeichert")
                    .changeEffect(.shake(rate: .fast), value: invalidTrigger, isEnabled: !reduceMotion)

                Label("Nur lokal auf diesem Gerät gespeichert", systemImage: "lock.fill")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.white.opacity(0.44))
            }
        }
    }

    // MARK: – Bottom Button

    private var actionButton: some View {
        VStack(spacing: 12) {
            Button { primaryAction() } label: {
                HStack(spacing: 10) {
                    Text(step.buttonTitle)
                        .font(.headline.weight(.bold))
                    Image(systemName: step == .name ? "checkmark" : "arrow.right")
                        .font(.subheadline.weight(.bold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background { buttonBackground }
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .shadow(color: .cyan.opacity(step == .name && nameOK ? 0.35 : 0.2), radius: 18, y: 6)
            }
            .buttonStyle(.plain)
            .disabled(step == .name && !nameOK)
            .opacity(step == .name && !nameOK ? 0.38 : 1)
            .animation(reduceMotion ? nil : .smooth(duration: 0.25), value: nameOK)
            .changeEffect(
                .spray(origin: .center) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.yellow)
                },
                value: confirmTrigger, isEnabled: !reduceMotion
            )

            if step == .name {
                Text("Kannst du jederzeit in den Einstellungen ändern.")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.38))
                    .multilineTextAlignment(.center)
            }
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
        .animation(reduceMotion ? nil : .spring(duration: 0.55, bounce: 0.1).delay(0.25), value: appeared)
    }

    @ViewBuilder
    private var buttonBackground: some View {
        LinearGradient(
            colors: [Color(red: 0.20, green: 0.55, blue: 0.95), Color(red: 0.10, green: 0.36, blue: 0.85)],
            startPoint: .leading, endPoint: .trailing
        )
    }

    // MARK: – Actions

    private func primaryAction() {
        switch step {
        case .wow, .value: goForward()
        case .name:        confirmName()
        }
    }

    private func goForward() {
        guard let next = Step(rawValue: step.rawValue + 1) else { return }
        withAnimation(reduceMotion ? nil : .smooth) { step = next }
    }

    private func goBack() {
        guard let prev = Step(rawValue: step.rawValue - 1) else { return }
        withAnimation(reduceMotion ? nil : .smooth) { step = prev }
    }

    private func confirmName() {
        guard nameOK else { invalidTrigger += 1; return }

        confirmTrigger += 1
        myPlayerName   = trimmed

        if reduceMotion {
            hasSeenOnboarding = true
        } else {
            withAnimation(.spring(duration: 0.38, bounce: 0)) { appeared = false }
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(220))
                withAnimation(.smooth) { hasSeenOnboarding = true }
            }
        }
    }

    private func onStepChange(_ s: Step) {
        switch s {
        case .wow:
            chipReveal = 0
        case .value:
            chipReveal = 0
            guard !reduceMotion else { chipReveal = 3; return }
            Task { @MainActor in
                for i in 1...3 {
                    try? await Task.sleep(for: .milliseconds(110))
                    chipReveal = i
                }
            }
        case .name:
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(reduceMotion ? 0 : 200))
                focused = .playerName
            }
        }
    }
}

// MARK: – Preview

#Preview { OnboardingView() }
