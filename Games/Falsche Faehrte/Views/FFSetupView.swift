import SwiftUI

struct FFSetupView: View {
    @EnvironmentObject private var viewModel: FFViewModel
    @ObservedObject private var playerManager = GlobalPlayerManager.shared
    @Environment(\.dismiss) private var dismiss

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
    @State private var showCrewPlayers      = false

    // Eingabe
    @State private var newPlayerName = ""
    @FocusState private var inputFocused: Bool

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
        .safeAreaInset(edge: .bottom) {
            startButtonArea
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)
        }
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.82).delay(0.1)) {
                appeared = true
            }
        }
        .sheet(isPresented: $showPlayerSheet) { playerPickerSheet }
        .sheet(isPresented: $showInfoSheet)   { FFInfoSheet() }
        .sheet(isPresented: $showRoundsSheet) { roundsPickerSheet }
        .sheet(isPresented: $showBluffTimerSheet) { bluffTimerPickerSheet }
        .sheet(isPresented: $showPackSheet)       { packPickerSheet }
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
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
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
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
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

    // MARK: - Spieler-Zeile (tippbar → Sheet)
    private var playerRow: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
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
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
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
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
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
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
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

    // MARK: - Pack Picker Sheet
    private var packPickerSheet: some View {
        NavigationStack {
            ZStack {
                FFBackground()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 10) {
                        ForEach(FFPack.allCases) { pack in
                            let isSelected = selectedPacks.contains(pack)
                            let accent = pack.accentColor.primary
                            Button {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                withAnimation(.spring(response: 0.3)) {
                                    if isSelected {
                                        if selectedPacks.count > 1 { selectedPacks.remove(pack) }
                                    } else {
                                        selectedPacks.insert(pack)
                                    }
                                }
                            } label: {
                                HStack(spacing: 14) {
                                    ZStack {
                                        Circle()
                                            .fill(accent.opacity(0.18))
                                            .frame(width: 44, height: 44)
                                        Text(pack.emoji)
                                            .font(.system(size: 22))
                                    }
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(pack.localizedName)
                                            .font(.system(size: 15, weight: .bold))
                                            .foregroundStyle(isSelected ? .white : FFStyle.textMuted)
                                        Text(packDescription(pack))
                                            .font(.system(size: 12))
                                            .foregroundStyle(FFStyle.textMuted)
                                            .lineLimit(1)
                                    }
                                    Spacer()
                                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                        .font(.title3)
                                        .foregroundStyle(isSelected ? accent : FFStyle.textMuted)
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 13)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(isSelected ? accent.opacity(0.10) : Color.white.opacity(0.04))
                                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(isSelected ? accent.opacity(0.4) : Color.white.opacity(0.07), lineWidth: 1))
                                )
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Fragen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") { showPackSheet = false }
                        .font(.headline)
                        .foregroundStyle(FFStyle.accentViolet)
                }
            }
        }
        .presentationDetents([.fraction(0.72)])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(28)
    }

    private func packDescription(_ pack: FFPack) -> String {
        switch pack {
        case .klassisch: return "Kuriose Fakten für jeden"
        case .krass:     return "Schockierende Wahrheiten"
        case .extrem:    return "Nur für Hartgesottene"
        case .lustig:    return "Absurde Fakten mit Humor"
        case .verrueckt: return "Komplett irre, aber wahr"
        case .pervers:   return "Erwachsen, dreckig, FSK 18"
        case .unnuetz:   return "Herrlich unnützes Wissen"
        }
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

    // MARK: - Runden Picker Sheet
    private var roundsPickerSheet: some View {
        NavigationStack {
            ZStack {
                FFBackground()
                VStack(spacing: 10) {
                    ForEach(FFRoundCount.allCases) { mode in
                        let isSelected = roundCount == mode
                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            withAnimation(.spring(response: 0.3)) { roundCount = mode }
                            showRoundsSheet = false
                        } label: {
                            HStack(spacing: 14) {
                                Text("\(mode.rawValue)")
                                    .font(.system(size: 22, weight: .black, design: .rounded))
                                    .foregroundStyle(isSelected ? FFStyle.accentViolet : .white)
                                    .frame(width: 36, alignment: .leading)
                                Text("Runden")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(FFStyle.textMuted)
                                Spacer()
                                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                    .font(.title3)
                                    .foregroundStyle(isSelected ? FFStyle.accentViolet : FFStyle.textMuted)
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(isSelected ? FFStyle.accentViolet.opacity(0.10) : Color.white.opacity(0.04))
                                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(isSelected ? FFStyle.accentViolet.opacity(0.4) : Color.white.opacity(0.07), lineWidth: 1))
                            )
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Rundenanzahl")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") { showRoundsSheet = false }
                        .font(.headline)
                        .foregroundStyle(FFStyle.accentViolet)
                }
            }
        }
        .presentationDetents([.fraction(0.46)])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(28)
    }

    // MARK: - Bluff-Timer Picker Sheet
    private var bluffTimerPickerSheet: some View {
        NavigationStack {
            ZStack {
                FFBackground()
                VStack(spacing: 10) {
                    ForEach(FFBluffTimer.allCases) { mode in
                        let isSelected = bluffTimer == mode
                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            withAnimation(.spring(response: 0.3)) { bluffTimer = mode }
                            showBluffTimerSheet = false
                        } label: {
                            HStack(spacing: 14) {
                                Text(mode.label)
                                    .font(.system(size: 22, weight: .black, design: .rounded))
                                    .foregroundStyle(isSelected ? FFStyle.accentIndigo : .white)
                                    .frame(width: 52, alignment: .leading)
                                Text("pro Spieler zum Lügen")
                                    .font(.system(size: 14))
                                    .foregroundStyle(FFStyle.textMuted)
                                Spacer()
                                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                    .font(.title3)
                                    .foregroundStyle(isSelected ? FFStyle.accentIndigo : FFStyle.textMuted)
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(isSelected ? FFStyle.accentIndigo.opacity(0.10) : Color.white.opacity(0.04))
                                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(isSelected ? FFStyle.accentIndigo.opacity(0.4) : Color.white.opacity(0.07), lineWidth: 1))
                            )
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Lügen-Zeit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") { showBluffTimerSheet = false }
                        .font(.headline)
                        .foregroundStyle(FFStyle.accentIndigo)
                }
            }
        }
        .presentationDetents([.fraction(0.46)])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(28)
    }

    // MARK: - Start-Button
    private var startButtonArea: some View {
        VStack(spacing: 10) {
            // Einzelgerät-Start
            Button {
                guard canStart else { return }
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                inputFocused = false
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
                              : AnyShapeStyle(LinearGradient(colors: [Color.white.opacity(0.08)],
                                                             startPoint: .leading, endPoint: .trailing)))
                        .shadow(color: canStart ? FFStyle.accentViolet.opacity(0.5) : .clear, radius: 16, y: 6)
                )
            }
            .disabled(!canStart)
            .animation(.spring(response: 0.3), value: canStart)

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
                // Fragenpool aus aktuellen Einstellungen generieren
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

    // MARK: - Spiel starten Hilfsmethoden

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

    // MARK: - Spieler Management Sheet
    private var playerPickerSheet: some View {
        NavigationStack {
            ZStack {
                FFBackground()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {

                        // Neuen Spieler hinzufügen
                        VStack(alignment: .leading, spacing: 10) {
                            Text("NEUER SPIELER")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundStyle(FFStyle.textMuted)
                                .tracking(1.5)

                            HStack(spacing: 10) {
                                HStack(spacing: 8) {
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 13))
                                        .foregroundStyle(FFStyle.accentViolet.opacity(0.7))
                                    TextField("Name eingeben…", text: $newPlayerName)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundStyle(.white)
                                        .tint(FFStyle.accentViolet)
                                        .focused($inputFocused)
                                        .submitLabel(.done)
                                        .onSubmit {
                                            addCurrentName()
                                            inputFocused = false
                                        }
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 11)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white.opacity(0.06))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(inputFocused
                                                        ? FFStyle.accentViolet.opacity(0.5)
                                                        : Color.white.opacity(0.08), lineWidth: 1)
                                        )
                                )

                                Button { addCurrentName() } label: {
                                    Image(systemName: "plus")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundStyle(newPlayerName.trimmingCharacters(in: .whitespaces).isEmpty ? .gray : .black)
                                        .frame(width: 46, height: 46)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(newPlayerName.trimmingCharacters(in: .whitespaces).isEmpty
                                                      ? Color.white.opacity(0.06)
                                                      : FFStyle.accentViolet)
                                        )
                                }
                                .disabled(newPlayerName.trimmingCharacters(in: .whitespaces).isEmpty)
                            }
                        }

                        // Ausgewählte Spieler
                        if !selectedNames.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("AUSGEWÄHLT (\(selectedNames.count))")
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundStyle(FFStyle.accentViolet)
                                    .tracking(1.5)

                                VStack(spacing: 8) {
                                    ForEach(selectedNames, id: \.self) { name in
                                        HStack(spacing: 14) {
                                            ZStack {
                                                Circle()
                                                    .fill(FFStyle.accentViolet.opacity(0.15))
                                                    .frame(width: 38, height: 38)
                                                Text(String(name.prefix(1)).uppercased())
                                                    .font(.system(size: 15, weight: .bold))
                                                    .foregroundStyle(FFStyle.accentViolet)
                                            }
                                            Text(name)
                                                .font(.system(size: 15, weight: .semibold))
                                                .foregroundStyle(.white)
                                            Spacer()
                                            Button {
                                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                                withAnimation(.spring(response: 0.3)) {
                                                    selectedNames.removeAll { $0 == name }
                                                }
                                            } label: {
                                                Image(systemName: "xmark.circle.fill")
                                                    .font(.system(size: 20))
                                                    .foregroundStyle(FFStyle.textMuted)
                                            }
                                        }
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 10)
                                        .background(
                                            RoundedRectangle(cornerRadius: 14)
                                                .fill(FFStyle.accentViolet.opacity(0.08))
                                                .overlay(RoundedRectangle(cornerRadius: 14).stroke(FFStyle.accentViolet.opacity(0.35), lineWidth: 1))
                                        )
                                    }
                                }
                            }
                        }

                        // Gespeicherte Spieler (Crew)
                        // Crew: nur nicht-ausgewählte Spieler anzeigen
                        let crewNotSelected = playerManager.players.filter { !selectedNames.contains($0.name) }
                        if !crewNotSelected.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack(spacing: 12) {
                                    Text("DEINE CREW")
                                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                                        .foregroundStyle(FFStyle.textMuted)
                                        .tracking(1.5)

                                    Spacer()

                                    Button {
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) {
                                            showCrewPlayers.toggle()
                                        }
                                    } label: {
                                        Text(showCrewPlayers ? "Ausblenden" : "Einblenden")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundStyle(FFStyle.accentViolet)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 7)
                                            .background(
                                                Capsule()
                                                    .fill(FFStyle.accentViolet.opacity(0.12))
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }

                                if showCrewPlayers {
                                    VStack(spacing: 8) {
                                        ForEach(crewNotSelected) { player in
                                            Button {
                                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                                withAnimation(.spring(response: 0.3)) {
                                                    selectedNames.append(player.name)
                                                }
                                            } label: {
                                                HStack(spacing: 14) {
                                                    ZStack {
                                                        Circle()
                                                            .fill(Color.white.opacity(0.06))
                                                            .frame(width: 38, height: 38)
                                                        Text(String(player.name.prefix(1)).uppercased())
                                                            .font(.system(size: 15, weight: .bold))
                                                            .foregroundStyle(FFStyle.textMuted)
                                                    }
                                                    Text(player.name)
                                                        .font(.system(size: 15, weight: .semibold))
                                                        .foregroundStyle(.white)
                                                    Spacer()
                                                    Image(systemName: "plus.circle")
                                                        .font(.title3)
                                                        .foregroundStyle(FFStyle.accentViolet)
                                                }
                                                .padding(.horizontal, 14)
                                                .padding(.vertical, 11)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 14)
                                                        .fill(Color.white.opacity(0.04))
                                                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.07), lineWidth: 1))
                                                )
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Spieler")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") { showPlayerSheet = false }
                        .font(.headline)
                        .foregroundStyle(FFStyle.accentViolet)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(28)
    }

    // MARK: - Hilfsmethoden
    private func addCurrentName() {
        let trimmed = newPlayerName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !selectedNames.contains(trimmed) else {
            newPlayerName = ""
            return
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        withAnimation(.spring(response: 0.35)) {
            selectedNames.append(trimmed)
        }
        GlobalPlayerManager.shared.addPlayer(name: trimmed)
        newPlayerName = ""
    }

}

private struct FFSetupActionRow: View {
    let icon: String
    let title: String
    let detail: String
    let subtitle: String?
    let accent: Color

    var body: some View {
        HStack(spacing: 12) {
            FFSetupIconBadge(icon: icon, accent: accent)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.white)

                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(FFStyle.textMuted)
                        .lineLimit(2)
                }
            }

            Spacer()

            HStack(spacing: 6) {
                Text(detail)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(FFStyle.textMuted)
                    .lineLimit(1)
                Image(systemName: "chevron.right")
                    .font(.subheadline)
                    .foregroundStyle(FFStyle.textMuted.opacity(0.7))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.black.opacity(0.35))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(accent.opacity(0.12), lineWidth: 1)
        )
        .contentShape(Rectangle())
    }
}

private struct FFSetupToggleRow: View {
    let icon: String
    let title: String
    let detail: String
    let accent: Color
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 12) {
            FFSetupIconBadge(icon: icon, accent: accent)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.white)
                Text("Zeigt die Themenrichtung direkt unter der Frage")
                    .font(.subheadline)
                    .foregroundStyle(FFStyle.textMuted)
                    .lineLimit(2)
            }

            Spacer()

            Text(detail)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(FFStyle.textMuted)

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(accent)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.black.opacity(0.35))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(accent.opacity(0.12), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityValue(detail)
    }
}

private struct FFSetupIconBadge: View {
    let icon: String
    let accent: Color

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [accent.opacity(0.22), accent.opacity(0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 44, height: 44)
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(accent.opacity(0.3), lineWidth: 1)
                )

            Image(systemName: icon)
                .font(.headline)
                .foregroundStyle(accent)
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Info Sheet (Spielregeln)
struct FFInfoSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                FFBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        ruleBlock(
                            icon: "1.circle.fill", color: FFStyle.accentViolet,
                            title: "Frage erscheint",
                            text: "Eine seltsame, aber wahre Frage wird angezeigt — z.B. \"Womit putzten sich Römer die Zähne?\""
                        )
                        ruleBlock(
                            icon: "2.circle.fill", color: FFStyle.accentIndigo,
                            title: "Alle lügen",
                            text: "Jeder Spieler tippt eine glaubwürdige Lüge ein — am besten eine, die die anderen als Wahrheit wählen!"
                        )
                        ruleBlock(
                            icon: "3.circle.fill", color: FFStyle.accentViolet,
                            title: "Abstimmung",
                            text: "Alle Antworten (Lügen + echte Antwort) erscheinen gemischt. Jeder tippt, was er für die Wahrheit hält."
                        )
                        ruleBlock(
                            icon: "4.circle.fill", color: FFStyle.accentIndigo,
                            title: "Auflösung",
                            text: "Die echte Antwort wird enthüllt. Wer sie gefunden hat, bekommt 2 Punkte. Wer andere mit seiner Lüge täuschte: 1 Punkt pro getäuschtem Spieler."
                        )
                        ruleBlock(
                            icon: "trophy.fill", color: FFStyle.accentGold,
                            title: "Gewinner",
                            text: "Nach allen Runden gewinnt, wer die meisten Punkte gesammelt hat. Kein Ausscheiden — alle spielen bis zum Ende!"
                        )
                        ruleBlock(
                            icon: "lightbulb.fill", color: FFStyle.accentViolet,
                            title: "Profi-Tipp",
                            text: "Die beste Lüge klingt plausibel, aber nicht zu offensichtlich. Verwende Fachbegriffe oder spezifische Details — das überzeugt!"
                        )
                    }
                    .padding()
                }
            }
            .navigationTitle("Spielregeln")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Verstanden!") { dismiss() }
                        .font(.headline)
                        .foregroundStyle(FFStyle.accentViolet)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(28)
    }

    private func ruleBlock(icon: String, color: Color, title: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundStyle(color)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                Text(text)
                    .font(.system(size: 14))
                    .foregroundStyle(FFStyle.textMuted)
                    .lineSpacing(3)
            }
        }
        .padding(14)
        .ffCard()
    }
}
