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
    @State private var showPlayerSheet = false
    @State private var showInfoSheet   = false

    // Eingabe
    @State private var newPlayerName = ""
    @FocusState private var inputFocused: Bool

    // Einblend-Animation
    @State private var appeared = false

    private var canStart: Bool {
        selectedNames.count >= 2 && !selectedPacks.isEmpty
    }

    var body: some View {
        ZStack {
            FFBackground()

            VStack(spacing: 0) {
                header
                    .padding(.horizontal, 20)
                    .padding(.top, 12)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        heroBanner
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 16)

                        playerSection
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 20)

                        packSection
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 24)

                        settingsGrid
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 28)

                        optionsSection
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 32)

                        Color.clear.frame(height: 110)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }
            }

            // Floating Start-Button
            VStack {
                Spacer()
                startButton
                    .padding(.bottom, 36)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.82).delay(0.1)) {
                appeared = true
            }
        }
        .sheet(isPresented: $showPlayerSheet) { playerPickerSheet }
        .sheet(isPresented: $showInfoSheet)   { FFInfoSheet() }
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

            Text("Falsche Fährte")
                .font(.system(size: 17, weight: .black, design: .rounded))
                .foregroundStyle(FFStyle.accentViolet)

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
                    .fill(FFStyle.accentViolet.opacity(0.18))
                    .frame(width: 64, height: 64)
                Image(systemName: "magnifyingglass.circle.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(FFStyle.primaryGradient)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Falsche Fährte")
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                Text("Lüge überzeugend — oder finde die Wahrheit!")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(FFStyle.textMuted)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(16)
        .ffCard(isPrimary: true)
    }

    // MARK: - Spieler-Sektion
    private var playerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel(icon: "person.2.fill", title: "Spieler",
                         badge: selectedNames.isEmpty ? nil : "\(selectedNames.count)")

            if selectedNames.isEmpty {
                HStack(spacing: 10) {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 18))
                        .foregroundStyle(FFStyle.accentViolet.opacity(0.6))
                    Text("Mindestens 2 Spieler hinzufügen")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(FFStyle.textMuted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 4)
            } else {
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
                                withAnimation(.spring(response: 0.3)) {
                                    selectedNames.removeAll { $0 == name }
                                }
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(FFStyle.textMuted)
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(FFStyle.accentViolet.opacity(0.12))
                                .overlay(Capsule().stroke(FFStyle.accentViolet.opacity(0.3), lineWidth: 1))
                        )
                    }
                }
            }

            addPlayerRow
        }
        .padding(16)
        .ffCard()
    }

    private var addPlayerRow: some View {
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
                                    ? FFStyle.accentViolet.opacity(0.5)
                                    : Color.white.opacity(0.08),
                                    lineWidth: 1)
                    )
            )

            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                showPlayerSheet = true
            } label: {
                Image(systemName: "person.crop.circle.badge.plus")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(FFStyle.accentViolet)
                    .frame(width: 44, height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(FFStyle.accentViolet.opacity(0.12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(FFStyle.accentViolet.opacity(0.3), lineWidth: 1)
                            )
                    )
            }

            Button { addCurrentName() } label: {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(newPlayerName.trimmingCharacters(in: .whitespaces).isEmpty ? .gray : .black)
                    .frame(width: 44, height: 44)
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

    // MARK: - Pack-Auswahl
    private var packSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel(icon: "square.stack.3d.up.fill", title: "Fragen-Pack")

            VStack(spacing: 10) {
                ForEach(FFPack.allCases) { pack in
                    packRow(pack)
                }
            }
        }
        .padding(16)
        .ffCard()
    }

    private func packRow(_ pack: FFPack) -> some View {
        let isSelected = selectedPacks.contains(pack)
        let accent = pack.accentColor.primary

        return Button {
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
                        .frame(width: 42, height: 42)
                    Text(pack.emoji)
                        .font(.system(size: 20))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(pack.localizedName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                    Text(packDescription(pack))
                        .font(.system(size: 12))
                        .foregroundStyle(FFStyle.textMuted)
                        .lineLimit(1)
                }

                Spacer()

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
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? accent.opacity(0.08) : Color.white.opacity(0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? accent.opacity(0.45) : Color.white.opacity(0.07), lineWidth: 1)
            )
        }
    }

    private func packDescription(_ pack: FFPack) -> String {
        switch pack {
        case .klassisch: return "Kuriose Fakten für jeden"
        case .krass:     return "Schockierende Wahrheiten"
        case .extrem:    return "Nur für Hartgesottene"
        }
    }

    // MARK: - Settings Grid (Runden + Bluff-Timer)
    private var settingsGrid: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 10) {
                sectionLabel(icon: "arrow.clockwise", title: "Runden")
                VStack(spacing: 8) {
                    ForEach(FFRoundCount.allCases) { mode in
                        settingsRow(
                            label: mode.label,
                            isSelected: roundCount == mode,
                            accent: FFStyle.accentViolet
                        ) {
                            withAnimation(.spring(response: 0.3)) { roundCount = mode }
                        }
                    }
                }
            }
            .padding(14)
            .ffCard()
            .frame(maxWidth: .infinity)

            VStack(alignment: .leading, spacing: 10) {
                sectionLabel(icon: "pencil.and.timer", title: "Lügen-Zeit")
                VStack(spacing: 8) {
                    ForEach(FFBluffTimer.allCases) { mode in
                        settingsRow(
                            label: mode.label,
                            isSelected: bluffTimer == mode,
                            accent: FFStyle.accentIndigo
                        ) {
                            withAnimation(.spring(response: 0.3)) { bluffTimer = mode }
                        }
                    }
                }
            }
            .padding(14)
            .ffCard()
            .frame(maxWidth: .infinity)
        }
    }

    private func settingsRow(label: String, isSelected: Bool, accent: Color, action: @escaping () -> Void) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        } label: {
            HStack {
                Text(label)
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
                            .stroke(isSelected ? accent.opacity(0.4) : Color.white.opacity(0.06), lineWidth: 1)
                    )
            )
        }
    }

    // MARK: - Optionen
    private var optionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel(icon: "slider.horizontal.3", title: "Optionen")

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Kategorie-Hinweis")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                    Text("Zeigt z.B. \"Geschichte\" unter der Frage")
                        .font(.system(size: 12))
                        .foregroundStyle(FFStyle.textMuted)
                }
                Spacer()
                Toggle("", isOn: $showCategoryHint)
                    .tint(FFStyle.accentViolet)
                    .labelsHidden()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.white.opacity(0.07), lineWidth: 1)
                    )
            )
        }
        .padding(16)
        .ffCard()
    }

    // MARK: - Start-Button
    private var startButton: some View {
        Button {
            guard canStart else { return }
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            inputFocused = false

            viewModel.settings.selectedPacks   = selectedPacks
            viewModel.settings.roundCount       = roundCount
            viewModel.settings.bluffTimer       = bluffTimer
            viewModel.settings.showCategoryHint = showCategoryHint

            for name in selectedNames {
                viewModel.addPlayer(name)
            }
            GlobalPlayerManager.shared.updateLastPlayed(for: selectedNames)
            viewModel.startGame()
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
        .padding(.horizontal, 24)
    }

    // MARK: - Spieler-Picker Sheet
    private var playerPickerSheet: some View {
        NavigationStack {
            ZStack {
                FFBackground()
                if playerManager.players.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "person.slash")
                            .font(.system(size: 40))
                            .foregroundStyle(FFStyle.textMuted)
                        Text("Keine gespeicherten Spieler")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(FFStyle.textMuted)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 10) {
                            ForEach(playerManager.players) { player in
                                let isAdded = selectedNames.contains(player.name)
                                Button {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    withAnimation(.spring(response: 0.3)) {
                                        if isAdded {
                                            selectedNames.removeAll { $0 == player.name }
                                        } else {
                                            selectedNames.append(player.name)
                                        }
                                    }
                                } label: {
                                    HStack(spacing: 14) {
                                        ZStack {
                                            Circle()
                                                .fill(FFStyle.accentViolet.opacity(0.18))
                                                .frame(width: 40, height: 40)
                                            Text(String(player.name.prefix(1)).uppercased())
                                                .font(.system(size: 16, weight: .bold))
                                                .foregroundStyle(FFStyle.accentViolet)
                                        }
                                        Text(player.name)
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundStyle(.white)
                                        Spacer()
                                        Image(systemName: isAdded ? "checkmark.circle.fill" : "circle")
                                            .font(.title3)
                                            .foregroundStyle(isAdded ? FFStyle.accentViolet : FFStyle.textMuted)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14)
                                            .fill(isAdded ? FFStyle.accentViolet.opacity(0.08) : Color.white.opacity(0.04))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(isAdded ? FFStyle.accentViolet.opacity(0.4) : Color.white.opacity(0.07), lineWidth: 1)
                                    )
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Gespeicherte Spieler")
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

    private func sectionLabel(icon: String, title: String, badge: String? = nil) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(FFStyle.accentViolet)
            Text(title.uppercased())
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(FFStyle.textMuted)
                .tracking(1.5)
            if let badge {
                Text(badge)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(FFStyle.accentViolet))
            }
        }
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
