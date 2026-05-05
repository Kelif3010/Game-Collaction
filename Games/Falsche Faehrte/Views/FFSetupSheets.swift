import SwiftUI

// MARK: - Player Picker Sheet
struct FFPlayerPickerSheet: View {
    @Binding var selectedNames: [String]
    @Binding var isPresented: Bool

    private let playerManager = GlobalPlayerManager.shared
    @State private var newPlayerName = ""
    @FocusState private var inputFocused: Bool
    @State private var showCrewPlayers = false
    @State private var lightHaptic = false

    var body: some View {
        NavigationStack {
            ZStack {
                FFBackground()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        addPlayerSection
                        if !selectedNames.isEmpty { selectedPlayersSection }
                        crewSection
                    }
                    .padding()
                }
            }
            .navigationTitle("Spieler")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") { isPresented = false }
                        .font(.headline)
                        .foregroundStyle(FFStyle.accentViolet)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(28)
        .sensoryFeedback(.impact(weight: .light), trigger: lightHaptic)
    }

    private var addPlayerSection: some View {
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
    }

    private var selectedPlayersSection: some View {
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
                            lightHaptic.toggle()
                            withAnimation(.snappy) {
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

    @ViewBuilder
    private var crewSection: some View {
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
                        lightHaptic.toggle()
                        withAnimation(.snappy) {
                            showCrewPlayers.toggle()
                        }
                    } label: {
                        Text(showCrewPlayers ? "Ausblenden" : "Einblenden")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(FFStyle.accentViolet)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(Capsule().fill(FFStyle.accentViolet.opacity(0.12)))
                    }
                    .buttonStyle(.plain)
                }

                if showCrewPlayers {
                    VStack(spacing: 8) {
                        ForEach(crewNotSelected) { player in
                            Button {
                                lightHaptic.toggle()
                                withAnimation(.snappy) {
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

    private func addCurrentName() {
        let trimmed = newPlayerName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !selectedNames.contains(trimmed) else {
            newPlayerName = ""
            return
        }
        lightHaptic.toggle()
        withAnimation(.snappy(duration: 0.35)) {
            selectedNames.append(trimmed)
        }
        GlobalPlayerManager.shared.addPlayer(name: trimmed)
        newPlayerName = ""
    }
}

// MARK: - Pack Picker Sheet
struct FFPackPickerSheet: View {
    @Binding var selectedPacks: Set<FFPack>
    @Binding var isPresented: Bool

    @State private var lightHaptic = false

    var body: some View {
        NavigationStack {
            ZStack {
                FFBackground()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 10) {
                        ForEach(FFPack.allCases) { pack in
                            let isSelected = selectedPacks.contains(pack)
                            let accent = pack.accentColor.primary
                            Button {
                                lightHaptic.toggle()
                                withAnimation(.snappy) {
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
                    Button("Fertig") { isPresented = false }
                        .font(.headline)
                        .foregroundStyle(FFStyle.accentViolet)
                }
            }
        }
        .presentationDetents([.fraction(0.72)])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(28)
        .sensoryFeedback(.impact(weight: .light), trigger: lightHaptic)
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
}

// MARK: - Rounds Picker Sheet
struct FFRoundsPickerSheet: View {
    @Binding var roundCount: FFRoundCount
    @Binding var isPresented: Bool

    @State private var lightHaptic = false

    var body: some View {
        NavigationStack {
            ZStack {
                FFBackground()
                VStack(spacing: 10) {
                    ForEach(FFRoundCount.allCases) { mode in
                        let isSelected = roundCount == mode
                        Button {
                            lightHaptic.toggle()
                            withAnimation(.snappy) { roundCount = mode }
                            isPresented = false
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
                    Button("Fertig") { isPresented = false }
                        .font(.headline)
                        .foregroundStyle(FFStyle.accentViolet)
                }
            }
        }
        .presentationDetents([.fraction(0.46)])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(28)
        .sensoryFeedback(.impact(weight: .light), trigger: lightHaptic)
    }
}

// MARK: - Bluff Timer Picker Sheet
struct FFBluffTimerPickerSheet: View {
    @Binding var bluffTimer: FFBluffTimer
    @Binding var isPresented: Bool

    @State private var lightHaptic = false

    var body: some View {
        NavigationStack {
            ZStack {
                FFBackground()
                VStack(spacing: 10) {
                    ForEach(FFBluffTimer.allCases) { mode in
                        let isSelected = bluffTimer == mode
                        Button {
                            lightHaptic.toggle()
                            withAnimation(.snappy) { bluffTimer = mode }
                            isPresented = false
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
                    Button("Fertig") { isPresented = false }
                        .font(.headline)
                        .foregroundStyle(FFStyle.accentIndigo)
                }
            }
        }
        .presentationDetents([.fraction(0.46)])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(28)
        .sensoryFeedback(.impact(weight: .light), trigger: lightHaptic)
    }
}

#Preview("Player Picker") {
    FFPlayerPickerSheet(selectedNames: .constant(["Test"]), isPresented: .constant(true))
}

#Preview("Pack Picker") {
    FFPackPickerSheet(selectedPacks: .constant([.klassisch]), isPresented: .constant(true))
}

#Preview("Rounds Picker") {
    FFRoundsPickerSheet(roundCount: .constant(.eight), isPresented: .constant(true))
}

#Preview("Bluff Timer Picker") {
    FFBluffTimerPickerSheet(bluffTimer: .constant(.forty), isPresented: .constant(true))
}
