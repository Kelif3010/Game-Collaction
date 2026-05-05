import SwiftUI

struct FFSetupView: View {
    @Environment(FFViewModel.self) private var viewModel
    @Environment(\.dismiss) private var dismiss

    @State private var lightHaptic = false
    @State private var mediumHaptic = false

    // Lokaler Setup-State
    @State private var selectedNames: [String] = []
    @State private var selectedPacks: Set<FFPack> = [.klassisch]
    @State private var roundCount: FFRoundCount = .eight
    @State private var bluffTimer: FFBluffTimer = .forty
    @State private var showCategoryHint: Bool = true

    // Sheet-Steuerung
    @State private var showPlayerSheet      = false
    @State private var showInfoSheet        = false
    @State private var showRoundsSheet      = false
    @State private var showBluffTimerSheet  = false
    @State private var showPackSheet        = false
    @State private var showMultiplayerSheet = false

    // Einblend-Animation
    @State private var appeared = false

    private var canStart: Bool {
        selectedNames.count >= 2 && !selectedPacks.isEmpty
    }

    private var playerDetailText: String {
        selectedNames.isEmpty
            ? "Keine"
            : selectedNames.count == 1 ? "1 Spieler" : "\(selectedNames.count) Spieler"
    }

    private var playerSubtitleText: String? {
        selectedNames.isEmpty ? nil : selectedNames.joined(separator: ", ")
    }

    private var packDetailText: String {
        let names = FFPack.allCases
            .filter { selectedPacks.contains($0) }
            .map { $0.localizedName }
        return names.isEmpty ? "Keine" : names.joined(separator: ", ")
    }

    var body: some View {
        ZStack {
            FFBackground()

            VStack(spacing: 0) {
                header

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        setupCard
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 18)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 120)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .sensoryFeedback(.impact(weight: .light), trigger: lightHaptic)
        .sensoryFeedback(.impact(weight: .medium), trigger: mediumHaptic)
        .safeAreaInset(edge: .bottom) {
            startButtonArea
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)
        }
        .onAppear {
            withAnimation(.spring(duration: 0.55, bounce: 0.15).delay(0.1)) {
                appeared = true
            }
        }
        .sheet(isPresented: $showPlayerSheet) {
            FFPlayerPickerSheet(selectedNames: $selectedNames, isPresented: $showPlayerSheet)
        }
        .sheet(isPresented: $showInfoSheet)   { FFInfoSheet() }
        .sheet(isPresented: $showRoundsSheet) {
            FFRoundsPickerSheet(roundCount: $roundCount, isPresented: $showRoundsSheet)
        }
        .sheet(isPresented: $showBluffTimerSheet) {
            FFBluffTimerPickerSheet(bluffTimer: $bluffTimer, isPresented: $showBluffTimerSheet)
        }
        .sheet(isPresented: $showPackSheet) {
            FFPackPickerSheet(selectedPacks: $selectedPacks, isPresented: $showPackSheet)
        }
        .sheet(isPresented: $showMultiplayerSheet) { multiplayerSheet }
    }

    // MARK: - Header
    private var header: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.headline.bold())
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .modifier(GlassCircleButtonBackground())
            }
            .accessibilityLabel("Zurück")

            Spacer()

            HStack(spacing: 12) {
                Button {
                    lightHaptic.toggle()
                    showMultiplayerSheet = true
                } label: {
                    Image(systemName: "person.2.wave.2.fill")
                        .font(.headline)
                        .foregroundStyle(FFStyle.accentViolet)
                        .frame(width: 44, height: 44)
                        .modifier(GlassCircleButtonBackground())
                }
                .accessibilityLabel("Multiplayer")

                Button {
                    lightHaptic.toggle()
                    showInfoSheet = true
                } label: {
                    Image(systemName: "questionmark")
                        .font(.headline.bold())
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .modifier(GlassCircleButtonBackground())
                }
                .accessibilityLabel("Spielregeln")
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 10)
    }

    // MARK: - Setup Card
    private var setupCard: some View {
        VStack(spacing: 12) {
            playerRow
            packRow
            roundsRow
            bluffTimerRow
            categoryHintRow
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.black.opacity(0.35))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(FFStyle.accentViolet.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.3), radius: 12, y: 6)
    }

    private var playerRow: some View {
        Button {
            lightHaptic.toggle()
            showPlayerSheet = true
        } label: {
            FFSetupActionRow(
                icon: "person.2.fill",
                title: "Spieler",
                detail: playerDetailText,
                subtitle: playerSubtitleText,
                accent: FFStyle.accentViolet
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Spieler auswählen")
        .accessibilityValue(playerDetailText)
    }

    private var packRow: some View {
        Button {
            lightHaptic.toggle()
            showPackSheet = true
        } label: {
            FFSetupActionRow(
                icon: "folder.fill",
                title: "Fragen",
                detail: packDetailText,
                subtitle: nil,
                accent: FFStyle.accentViolet
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Fragen auswählen")
        .accessibilityValue(packDetailText)
    }

    private var roundsRow: some View {
        Button {
            lightHaptic.toggle()
            showRoundsSheet = true
        } label: {
            FFSetupActionRow(
                icon: "arrow.clockwise",
                title: "Runden",
                detail: "\(roundCount.rawValue)",
                subtitle: nil,
                accent: FFStyle.accentViolet
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Runden auswählen")
        .accessibilityValue("\(roundCount.rawValue) Runden")
    }

    private var bluffTimerRow: some View {
        Button {
            lightHaptic.toggle()
            showBluffTimerSheet = true
        } label: {
            FFSetupActionRow(
                icon: "timer",
                title: "Lügen-Zeit",
                detail: bluffTimer.label,
                subtitle: nil,
                accent: FFStyle.accentIndigo
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Lügen-Zeit auswählen")
        .accessibilityValue(bluffTimer.label)
    }

    private var categoryHintRow: some View {
        FFSetupToggleRow(
            icon: "tag.fill",
            title: "Kategorie",
            detail: showCategoryHint ? "An" : "Aus",
            accent: FFStyle.accentViolet,
            isOn: $showCategoryHint
        )
    }

    // MARK: - Start-Button
    private var startButtonArea: some View {
        VStack(spacing: 10) {
            Button {
                guard canStart else { return }
                mediumHaptic.toggle()
                startSinglePlayerGame()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 16, weight: .bold))
                    Text("Spiel starten")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                }
                .foregroundStyle(canStart ? .black : .white.opacity(0.4))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    Capsule()
                        .fill(canStart
                              ? AnyShapeStyle(FFStyle.primaryGradient)
                              : AnyShapeStyle(Color.white.opacity(0.08)))
                        .shadow(color: canStart ? FFStyle.accentViolet.opacity(0.5) : .clear, radius: 16, y: 6)
                )
            }
            .disabled(!canStart)
            .animation(.snappy, value: canStart)

            if !canStart {
                Text(selectedNames.count < 2
                     ? "Mindestens 2 Spieler hinzufügen"
                     : "Mindestens ein Fragen-Pack auswählen")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(FFStyle.textMuted)
                    .multilineTextAlignment(.center)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
        .padding(.bottom, 32)
    }

    // MARK: - Multiplayer Sheet
    private var multiplayerSheet: some View {
        FFMultiplayerSheet(
            onGameStarted: { config, asHost in
                startMultiplayerGame(config: config, asHost: asHost)
            },
            getHostConfig: { lobbyPlayers in
                let pool = FFQuestionDatabase.questions(for: selectedPacks)
                let limited = Array(pool.prefix(roundCount.rawValue))
                return FFGameConfigPayload(
                    questionIds: limited.map { $0.id },
                    playerNames: lobbyPlayers,
                    showCategoryHint: showCategoryHint,
                    bluffTimerSeconds: bluffTimer.rawValue,
                    roundCount: roundCount.rawValue
                )
            }
        )
    }

    // MARK: - Spiel starten
    private func startSinglePlayerGame() {
        viewModel.settings.selectedPacks   = selectedPacks
        viewModel.settings.roundCount       = roundCount
        viewModel.settings.bluffTimer       = bluffTimer
        viewModel.settings.showCategoryHint = showCategoryHint

        for name in selectedNames {
            viewModel.addPlayer(name)
        }
        GlobalPlayerManager.shared.updateLastPlayed(for: selectedNames)
        viewModel.startGame()
    }

    private func startMultiplayerGame(config: FFGameConfigPayload, asHost: Bool) {
        viewModel.isMultiplayer = true
        viewModel.isHost = asHost

        if asHost {
            viewModel.settings.selectedPacks   = selectedPacks
            viewModel.settings.roundCount       = roundCount
            viewModel.settings.bluffTimer       = bluffTimer
            viewModel.settings.showCategoryHint = showCategoryHint

            for name in config.playerNames {
                viewModel.addPlayer(name)
            }
            GlobalPlayerManager.shared.updateLastPlayed(for: config.playerNames)
            viewModel.startMultiplayerGameAsHost(questionIds: config.questionIds)
        } else {
            viewModel.startMultiplayerGameAsClient(config: config)
        }
    }
}

#Preview {
    FFSetupView()
        .environment(FFViewModel.preview)
}
