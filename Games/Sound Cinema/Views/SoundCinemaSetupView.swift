import SwiftUI

struct SoundCinemaSetupView: View {
    @EnvironmentObject private var viewModel: SoundCinemaViewModel
    @ObservedObject private var playerManager = GlobalPlayerManager.shared
    @Environment(\.dismiss) private var dismiss

    // Lokaler Setup-State
    @State private var selectedNames: [String] = []
    @State private var selectedPacks: Set<SoundCinemaPack> = [.party]
    @State private var timerMode: SoundCinemaTimerMode = .medium
    @State private var livesMode: SoundCinemaLivesMode = .three

    // Sheet-Steuerung
    @State private var showPlayerSheet = false
    @State private var showInfoSheet   = false

    // Eintippen neuer Spieler
    @State private var newPlayerName = ""
    @FocusState private var inputFocused: Bool

    // Animation
    @State private var appeared = false

    private var canStart: Bool {
        selectedNames.count >= 2 && !selectedPacks.isEmpty
    }

    var body: some View {
        ZStack {
            SoundCinemaBackground()

            VStack(spacing: 0) {
                header
                    .padding(.horizontal, SoundCinemaStyle.padding)
                    .padding(.top, 12)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Hero-Banner
                        heroBanner
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 16)

                        // Spieler-Sektion
                        playerSection
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 20)

                        // Pack-Auswahl
                        packSection
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 24)

                        // Timer & Leben
                        settingsGrid
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 28)

                        // Platz für Start-Button
                        Color.clear.frame(height: 100)
                    }
                    .padding(.horizontal, SoundCinemaStyle.padding)
                    .padding(.top, 16)
                }
            }

            // Floating Start-Button
            VStack {
                Spacer()
                startButton
                    .padding(.horizontal, SoundCinemaStyle.padding)
                    .padding(.bottom, 32)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.8).delay(0.1)) {
                appeared = true
            }
        }
        .sheet(isPresented: $showPlayerSheet) {
            playerPickerSheet
        }
        .sheet(isPresented: $showInfoSheet) {
            SoundCinemaInfoSheet()
        }
    }

    // MARK: - Header
    private var header: some View {
        HStack(spacing: 0) {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .modifier(GlassCircleButtonBackground())
            }

            Spacer()

            Text("Geräusch-Kino")
                .font(SoundCinemaStyle.headingFont)
                .foregroundStyle(SoundCinemaStyle.accentCyan)

            Spacer()

            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                showInfoSheet = true
            } label: {
                Image(systemName: "questionmark")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .modifier(GlassCircleButtonBackground())
            }
        }
    }

    // MARK: - Hero Banner
    private var heroBanner: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(SoundCinemaStyle.accentCyan.opacity(0.15))
                    .frame(width: 64, height: 64)
                Image(systemName: "waveform.circle.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(SoundCinemaStyle.primaryGradient)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Geräusch-Kino")
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                Text("Imitiere das Geräusch – die Gruppe rät!")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(SoundCinemaStyle.textMuted)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(16)
        .soundCinemaCard(highlighted: false)
    }

    // MARK: - Spieler-Sektion
    private var playerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel(icon: "person.2.fill", title: "Spieler", badge: selectedNames.isEmpty ? nil : "\(selectedNames.count)")

            if selectedNames.isEmpty {
                emptyPlayersHint
            } else {
                playersGrid
            }

            // Spieler hinzufügen
            addPlayerRow
        }
        .padding(16)
        .soundCinemaCard()
    }

    private var emptyPlayersHint: some View {
        HStack(spacing: 10) {
            Image(systemName: "person.badge.plus")
                .font(.system(size: 18))
                .foregroundStyle(SoundCinemaStyle.accentCyan.opacity(0.6))
            Text("Mindestens 2 Spieler hinzufügen")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(SoundCinemaStyle.textMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
    }

    private var playersGrid: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 100), spacing: 8)],
            spacing: 8
        ) {
            ForEach(selectedNames, id: \.self) { name in
                HStack(spacing: 6) {
                    Text(name)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Spacer(minLength: 0)
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        selectedNames.removeAll { $0 == name }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(SoundCinemaStyle.textMuted)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(SoundCinemaStyle.accentCyan.opacity(0.12))
                        .overlay(Capsule().stroke(SoundCinemaStyle.accentCyan.opacity(0.3), lineWidth: 1))
                )
            }
        }
    }

    private var addPlayerRow: some View {
        HStack(spacing: 10) {
            // Textfeld
            HStack(spacing: 8) {
                Image(systemName: "person.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(SoundCinemaStyle.accentCyan.opacity(0.7))
                TextField("Name eingeben…", text: $newPlayerName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white)
                    .tint(SoundCinemaStyle.accentCyan)
                    .focused($inputFocused)
                    .submitLabel(.done)
                    .onSubmit { addCurrentName() }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(inputFocused
                                    ? SoundCinemaStyle.accentCyan.opacity(0.5)
                                    : Color.white.opacity(0.08),
                                    lineWidth: 1)
                    )
            )

            // Gespeicherte Spieler (Globe-Icon)
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                showPlayerSheet = true
            } label: {
                Image(systemName: "person.crop.circle.badge.plus")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(SoundCinemaStyle.accentCyan)
                    .frame(width: 44, height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(SoundCinemaStyle.accentCyan.opacity(0.12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(SoundCinemaStyle.accentCyan.opacity(0.3), lineWidth: 1)
                            )
                    )
            }

            // Add-Button
            Button { addCurrentName() } label: {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(newPlayerName.trimmingCharacters(in: .whitespaces).isEmpty ? .gray : .black)
                    .frame(width: 44, height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(newPlayerName.trimmingCharacters(in: .whitespaces).isEmpty
                                  ? Color.white.opacity(0.06)
                                  : SoundCinemaStyle.accentCyan)
                    )
            }
            .disabled(newPlayerName.trimmingCharacters(in: .whitespaces).isEmpty)
        }
    }

    // MARK: - Pack-Auswahl
    private var packSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel(icon: "square.stack.3d.up.fill", title: "Karten-Pack")

            VStack(spacing: 10) {
                ForEach(SoundCinemaPack.allCases) { pack in
                    packRow(pack)
                }
            }
        }
        .padding(16)
        .soundCinemaCard()
    }

    private func packRow(_ pack: SoundCinemaPack) -> some View {
        let isSelected = selectedPacks.contains(pack)
        let accent = pack.accentColor.primary

        return Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            if isSelected {
                if selectedPacks.count > 1 { selectedPacks.remove(pack) }
            } else {
                selectedPacks.insert(pack)
            }
        } label: {
            HStack(spacing: 14) {
                // Emoji Badge
                ZStack {
                    Circle()
                        .fill(accent.opacity(0.18))
                        .frame(width: 42, height: 42)
                    Text(pack.emoji)
                        .font(.system(size: 20))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(pack.localizedName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                    Text(pack.description)
                        .font(.system(size: 12))
                        .foregroundStyle(SoundCinemaStyle.textMuted)
                        .lineLimit(1)
                }

                Spacer()

                // Checkmark
                ZStack {
                    Circle()
                        .fill(isSelected ? accent.opacity(0.2) : Color.white.opacity(0.06))
                        .frame(width: 28, height: 28)
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(accent)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: SoundCinemaStyle.rowCornerRadius)
                    .fill(isSelected ? accent.opacity(0.08) : Color.white.opacity(0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: SoundCinemaStyle.rowCornerRadius)
                    .stroke(isSelected ? accent.opacity(0.45) : Color.white.opacity(0.07), lineWidth: 1)
            )
        }
    }

    // MARK: - Settings Grid (Timer + Leben)
    private var settingsGrid: some View {
        HStack(spacing: 12) {
            // Timer-Auswahl
            VStack(alignment: .leading, spacing: 10) {
                sectionLabel(icon: "timer", title: "Zeit")
                VStack(spacing: 8) {
                    ForEach(SoundCinemaTimerMode.allCases) { mode in
                        timerModeRow(mode)
                    }
                }
            }
            .padding(14)
            .soundCinemaCard()
            .frame(maxWidth: .infinity)

            // Leben-Auswahl
            VStack(alignment: .leading, spacing: 10) {
                sectionLabel(icon: "heart.fill", title: "Leben")
                VStack(spacing: 8) {
                    ForEach(SoundCinemaLivesMode.allCases) { mode in
                        livesModeRow(mode)
                    }
                }
            }
            .padding(14)
            .soundCinemaCard()
            .frame(maxWidth: .infinity)
        }
    }

    private func timerModeRow(_ mode: SoundCinemaTimerMode) -> some View {
        let isSelected = timerMode == mode
        return Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.spring(response: 0.3)) { timerMode = mode }
        } label: {
            HStack {
                Text(mode.label)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(isSelected ? SoundCinemaStyle.accentCyan : .white)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(SoundCinemaStyle.accentCyan)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected
                          ? SoundCinemaStyle.accentCyan.opacity(0.12)
                          : Color.white.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isSelected
                                    ? SoundCinemaStyle.accentCyan.opacity(0.4)
                                    : Color.white.opacity(0.06), lineWidth: 1)
                    )
            )
        }
    }

    private func livesModeRow(_ mode: SoundCinemaLivesMode) -> some View {
        let isSelected = livesMode == mode
        let accent: Color = mode == .endless ? SoundCinemaStyle.accentMint : SoundCinemaStyle.accentCyan
        return Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.spring(response: 0.3)) { livesMode = mode }
        } label: {
            HStack {
                Text(mode.label)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(isSelected ? accent : .white)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(accent)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? accent.opacity(0.12) : Color.white.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isSelected
                                    ? accent.opacity(0.4)
                                    : Color.white.opacity(0.06), lineWidth: 1)
                    )
            )
        }
    }

    // MARK: - Start-Button
    private var startButton: some View {
        Button {
            guard canStart else { return }
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            inputFocused = false

            var settings = SoundCinemaSettings()
            settings.playerNames    = selectedNames
            settings.selectedPacks  = selectedPacks
            settings.timerMode      = timerMode
            settings.livesMode      = livesMode

            GlobalPlayerManager.shared.updateLastPlayed(for: selectedNames)
            viewModel.configure(with: settings)
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
                          ? SoundCinemaStyle.primaryGradient
                          : LinearGradient(colors: [Color.white.opacity(0.08)], startPoint: .leading, endPoint: .trailing))
                    .shadow(color: canStart ? SoundCinemaStyle.accentCyan.opacity(0.45) : .clear, radius: 14, y: 5)
            )
        }
        .disabled(!canStart)
        .animation(.spring(response: 0.3), value: canStart)
    }

    // MARK: - Spieler-Picker Sheet
    private var playerPickerSheet: some View {
        NavigationStack {
            ZStack {
                SoundCinemaBackground()
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(playerManager.players) { player in
                            let isAdded = selectedNames.contains(player.name)
                            Button {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                if isAdded {
                                    selectedNames.removeAll { $0 == player.name }
                                } else {
                                    selectedNames.append(player.name)
                                }
                            } label: {
                                HStack(spacing: 14) {
                                    ZStack {
                                        Circle()
                                            .fill(SoundCinemaStyle.accentCyan.opacity(0.15))
                                            .frame(width: 40, height: 40)
                                        Text(String(player.name.prefix(1)).uppercased())
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundStyle(SoundCinemaStyle.accentCyan)
                                    }

                                    Text(player.name)
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundStyle(.white)

                                    Spacer()

                                    Image(systemName: isAdded ? "checkmark.circle.fill" : "circle")
                                        .font(.title3)
                                        .foregroundStyle(isAdded ? SoundCinemaStyle.accentCyan : SoundCinemaStyle.textMuted)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(isAdded
                                              ? SoundCinemaStyle.accentCyan.opacity(0.08)
                                              : Color.white.opacity(0.04))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(isAdded
                                                ? SoundCinemaStyle.accentCyan.opacity(0.35)
                                                : Color.white.opacity(0.07), lineWidth: 1)
                                )
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Gespeicherte Spieler")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") { showPlayerSheet = false }
                        .font(.headline)
                        .foregroundStyle(SoundCinemaStyle.accentCyan)
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

    private func sectionLabel(icon: String, title: String, badge: String? = nil) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(SoundCinemaStyle.accentCyan)
            Text(title.uppercased())
                .font(SoundCinemaStyle.labelFont)
                .foregroundStyle(SoundCinemaStyle.textMuted)
                .tracking(1.5)
            if let badge {
                Text(badge)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(SoundCinemaStyle.accentCyan))
            }
        }
    }
}

// MARK: - Info Sheet (Spielregeln)
struct SoundCinemaInfoSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                SoundCinemaBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        ruleBlock(icon: "1.circle.fill", color: SoundCinemaStyle.accentCyan,
                                  title: "Karte ziehen",
                                  text: "Der aktive Spieler tippt auf die Karte. Ein Geräusch erscheint – z.B. \"Startendes Flugzeug\".")

                        ruleBlock(icon: "2.circle.fill", color: SoundCinemaStyle.accentMint,
                                  title: "Geräusch imitieren",
                                  text: "Der Timer startet. Imitiere das Geräusch nur mit dem Mund – so gut du kannst!")

                        ruleBlock(icon: "3.circle.fill", color: SoundCinemaStyle.accentCyan,
                                  title: "Gruppe rät",
                                  text: "Die anderen Spieler versuchen das Geräusch zu erraten. Hat jemand es erraten, tippt der aktive Spieler auf ✓.")

                        ruleBlock(icon: "4.circle.fill", color: SoundCinemaStyle.accentMint,
                                  title: "Zeit abgelaufen?",
                                  text: "Wenn der Timer abläuft ohne dass jemand geraten hat, verliert der aktive Spieler ein Leben.")

                        ruleBlock(icon: "heart.fill", color: .red,
                                  title: "Leben & Ausscheiden",
                                  text: "Wer alle Leben verliert, scheidet aus. Das Spiel endet wenn nur noch ein Spieler übrig ist – er gewinnt!")

                        ruleBlock(icon: "infinity", color: SoundCinemaStyle.accentMint,
                                  title: "Endlos-Modus",
                                  text: "Mit ∞ Leben scheidet niemand aus. Ihr spielt bis ihr aufhören wollt – perfekt für lockere Runden.")
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
                        .foregroundStyle(SoundCinemaStyle.accentCyan)
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
                    .foregroundStyle(SoundCinemaStyle.textMuted)
                    .lineSpacing(3)
            }
        }
        .padding(14)
        .soundCinemaCard()
    }
}
