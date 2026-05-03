import SwiftUI

struct SoundCinemaSetupView: View {
    @EnvironmentObject private var viewModel: SoundCinemaViewModel
    private let playerManager = GlobalPlayerManager.shared
    @Environment(\.dismiss) private var dismiss

    // Lokaler Setup-State
    @State private var selectedNames: [String] = []
    @State private var selectedPacks: Set<SoundCinemaPack> = [.party]
    @State private var timerMode: SoundCinemaTimerMode = .medium
    @State private var livesMode: SoundCinemaLivesMode = .three

    // Sheet-Steuerung
    @State private var showPlayerSheet = false
    @State private var showInfoSheet   = false
    @State private var showTimerSheet  = false
    @State private var showLivesSheet  = false
    @State private var showPackSheet   = false

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

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        setupCard
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 18)
                    }
                    .padding(.horizontal, SoundCinemaStyle.padding)
                    .padding(.top, 16)
                    .padding(.bottom, 120)
                }
                .safeAreaInset(edge: .bottom) {
                    startButtonArea
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 20)
                }
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
        .sheet(isPresented: $showTimerSheet) {
            timerPickerSheet
        }
        .sheet(isPresented: $showLivesSheet) {
            livesPickerSheet
        }
        .sheet(isPresented: $showPackSheet) {
            packPickerSheet
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
            .accessibilityLabel("Zurück")

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
            .accessibilityLabel("Spielregeln")
        }
        .padding(.horizontal, SoundCinemaStyle.padding)
        .padding(.top, 20)
        .padding(.bottom, 10)
    }

    private var setupCard: some View {
        VStack(spacing: 12) {
            playerRow
            packRow
            timerRow
            livesRow
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.black.opacity(0.35))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(SoundCinemaStyle.accentCyan.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.3), radius: 12, y: 6)
    }

    // MARK: - Spieler-Zeile (tippbar → Sheet)
    private var playerRow: some View {
        let detail = selectedNames.isEmpty
            ? "Keine"
            : selectedNames.count == 1 ? "1 Spieler" : "\(selectedNames.count) Spieler"

        return Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            showPlayerSheet = true
        } label: {
            SoundCinemaSetupActionRow(
                icon: "person.2.fill",
                title: "Spieler",
                detail: detail,
                subtitle: selectedNames.isEmpty ? nil : selectedNames.joined(separator: ", "),
                accent: SoundCinemaStyle.accentCyan
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Spieler auswählen")
        .accessibilityValue(detail)
    }

    // MARK: - Pack-Zeile (tippbar → Sheet)
    private var packDetailText: String {
        let names = SoundCinemaPack.allCases
            .filter { selectedPacks.contains($0) }
            .map { $0.localizedName }
        return names.isEmpty ? "Keine" : names.joined(separator: ", ")
    }

    private var packRow: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            showPackSheet = true
        } label: {
            SoundCinemaSetupActionRow(
                icon: "waveform",
                title: "Geräusche",
                detail: packDetailText,
                subtitle: nil,
                accent: SoundCinemaStyle.accentOrange
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Geräusche auswählen")
        .accessibilityValue(packDetailText)
    }

    // MARK: - Pack Picker Sheet
    private var packPickerSheet: some View {
        NavigationStack {
            ZStack {
                SoundCinemaBackground()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 10) {
                        ForEach(SoundCinemaPack.allCases) { pack in
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
                                            .foregroundStyle(isSelected ? .white : SoundCinemaStyle.textMuted)
                                        Text(pack.description)
                                            .font(.system(size: 12))
                                            .foregroundStyle(SoundCinemaStyle.textMuted)
                                            .lineLimit(1)
                                    }
                                    Spacer()
                                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                        .font(.title3)
                                        .foregroundStyle(isSelected ? accent : SoundCinemaStyle.textMuted)
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
            .navigationTitle("Geräusche")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") { showPackSheet = false }
                        .font(.headline)
                        .foregroundStyle(SoundCinemaStyle.accentCyan)
                }
            }
        }
        .presentationDetents([.fraction(0.52)])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(28)
    }

    private var timerRow: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            showTimerSheet = true
        } label: {
            SoundCinemaSetupActionRow(
                icon: "timer",
                title: "Zeit",
                detail: timerMode.label,
                subtitle: nil,
                accent: SoundCinemaStyle.accentCyan
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Zeit auswählen")
        .accessibilityValue(timerMode.label)
    }

    private var livesRow: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            showLivesSheet = true
        } label: {
            SoundCinemaSetupActionRow(
                icon: "heart.fill",
                title: "Leben",
                detail: livesMode.label,
                subtitle: nil,
                accent: SoundCinemaStyle.accentMint
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Leben auswählen")
        .accessibilityValue(livesMode.label)
    }

    // MARK: - Timer Picker Sheet
    private var timerPickerSheet: some View {
        NavigationStack {
            ZStack {
                SoundCinemaBackground()
                VStack(spacing: 10) {
                    ForEach(SoundCinemaTimerMode.allCases) { mode in
                        let isSelected = timerMode == mode
                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            withAnimation(.spring(response: 0.3)) { timerMode = mode }
                            showTimerSheet = false
                        } label: {
                            HStack(spacing: 14) {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(mode.label)
                                        .font(.system(size: 17, weight: .bold, design: .rounded))
                                        .foregroundStyle(isSelected ? SoundCinemaStyle.accentCyan : .white)
                                    Text(mode.description)
                                        .font(.system(size: 13))
                                        .foregroundStyle(SoundCinemaStyle.textMuted)
                                }
                                Spacer()
                                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                    .font(.title3)
                                    .foregroundStyle(isSelected ? SoundCinemaStyle.accentCyan : SoundCinemaStyle.textMuted)
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(isSelected ? SoundCinemaStyle.accentCyan.opacity(0.10) : Color.white.opacity(0.04))
                                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(isSelected ? SoundCinemaStyle.accentCyan.opacity(0.4) : Color.white.opacity(0.07), lineWidth: 1))
                            )
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Zeit pro Karte")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") { showTimerSheet = false }
                        .font(.headline)
                        .foregroundStyle(SoundCinemaStyle.accentCyan)
                }
            }
        }
        .presentationDetents([.fraction(0.42)])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(28)
    }

    // MARK: - Lives Picker Sheet
    private var livesPickerSheet: some View {
        NavigationStack {
            ZStack {
                SoundCinemaBackground()
                VStack(spacing: 10) {
                    ForEach(SoundCinemaLivesMode.allCases) { mode in
                        let isSelected = livesMode == mode
                        let accent: Color = mode == .endless ? SoundCinemaStyle.accentMint : SoundCinemaStyle.accentCyan
                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            withAnimation(.spring(response: 0.3)) { livesMode = mode }
                            showLivesSheet = false
                        } label: {
                            HStack(spacing: 14) {
                                Text(mode.label)
                                    .font(.system(size: 22, weight: .bold, design: .rounded))
                                    .foregroundStyle(isSelected ? accent : .white)
                                    .frame(width: 40, alignment: .leading)
                                Text(mode == .endless ? "Kein Ausscheiden" : "\(mode.rawValue) Leben – Ausscheiden aktiv")
                                    .font(.system(size: 14))
                                    .foregroundStyle(SoundCinemaStyle.textMuted)
                                Spacer()
                                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                    .font(.title3)
                                    .foregroundStyle(isSelected ? accent : SoundCinemaStyle.textMuted)
                            }
                            .padding(16)
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
            .navigationTitle("Leben")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") { showLivesSheet = false }
                        .font(.headline)
                        .foregroundStyle(SoundCinemaStyle.accentCyan)
                }
            }
        }
        .presentationDetents([.fraction(0.42)])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(28)
    }

    // MARK: - Start-Button
    private var startButtonArea: some View {
        VStack(spacing: 8) {
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

            if !canStart {
                Text(selectedNames.count < 2
                     ? "Mindestens 2 Spieler hinzufügen"
                     : "Mindestens ein Geräusch-Pack auswählen")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(SoundCinemaStyle.textMuted)
                    .multilineTextAlignment(.center)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .padding(.horizontal, SoundCinemaStyle.padding)
        .padding(.top, 12)
        .padding(.bottom, 32)
    }

    // MARK: - Spieler Management Sheet
    private var playerPickerSheet: some View {
        NavigationStack {
            ZStack {
                SoundCinemaBackground()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {

                        // Neuen Spieler hinzufügen
                        VStack(alignment: .leading, spacing: 10) {
                            Text("NEUER SPIELER")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundStyle(SoundCinemaStyle.textMuted)
                                .tracking(1.5)

                            HStack(spacing: 10) {
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
                                .padding(.vertical, 11)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white.opacity(0.06))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(inputFocused
                                                        ? SoundCinemaStyle.accentCyan.opacity(0.5)
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
                                                      : SoundCinemaStyle.accentCyan)
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
                                    .foregroundStyle(SoundCinemaStyle.accentCyan)
                                    .tracking(1.5)

                                VStack(spacing: 8) {
                                    ForEach(selectedNames, id: \.self) { name in
                                        HStack(spacing: 14) {
                                            ZStack {
                                                Circle()
                                                    .fill(SoundCinemaStyle.accentCyan.opacity(0.15))
                                                    .frame(width: 38, height: 38)
                                                Text(String(name.prefix(1)).uppercased())
                                                    .font(.system(size: 15, weight: .bold))
                                                    .foregroundStyle(SoundCinemaStyle.accentCyan)
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
                                                    .foregroundStyle(SoundCinemaStyle.textMuted)
                                            }
                                        }
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 10)
                                        .background(
                                            RoundedRectangle(cornerRadius: 14)
                                                .fill(SoundCinemaStyle.accentCyan.opacity(0.08))
                                                .overlay(RoundedRectangle(cornerRadius: 14).stroke(SoundCinemaStyle.accentCyan.opacity(0.35), lineWidth: 1))
                                        )
                                    }
                                }
                            }
                        }

                        // Gespeicherte Spieler (nur nicht-ausgewählte zeigen)
                        let crewNotSelected = playerManager.players.filter { !selectedNames.contains($0.name) }
                        if !crewNotSelected.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("DEINE CREW")
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundStyle(SoundCinemaStyle.textMuted)
                                    .tracking(1.5)

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
                                                        .foregroundStyle(SoundCinemaStyle.textMuted)
                                                }
                                                Text(player.name)
                                                    .font(.system(size: 15, weight: .semibold))
                                                    .foregroundStyle(.white)
                                                Spacer()
                                                Image(systemName: "plus.circle")
                                                    .font(.title3)
                                                    .foregroundStyle(SoundCinemaStyle.accentCyan)
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
                    .padding()
                }
            }
            .navigationTitle("Spieler")
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

}

private struct SoundCinemaSetupActionRow: View {
    let icon: String
    let title: String
    let detail: String
    let subtitle: String?
    let accent: Color

    var body: some View {
        HStack(spacing: 12) {
            SoundCinemaSetupIconBadge(icon: icon, accent: accent)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.white)

                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(SoundCinemaStyle.textMuted)
                        .lineLimit(2)
                }
            }

            Spacer()

            HStack(spacing: 6) {
                Text(detail)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(SoundCinemaStyle.textMuted)
                    .lineLimit(1)
                Image(systemName: "chevron.right")
                    .font(.subheadline)
                    .foregroundStyle(SoundCinemaStyle.textMuted.opacity(0.7))
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

private struct SoundCinemaSetupIconBadge: View {
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
