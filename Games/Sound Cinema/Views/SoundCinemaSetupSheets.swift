//
//  SoundCinemaSetupSheets.swift
//  Games Collection
//
//  Player-, Pack-, Timer- und Lives-Picker Sheets
//

import SwiftUI

// MARK: - Player Picker Sheet

struct SoundCinemaPlayerPickerSheet: View {
    @Binding var selectedNames: [String]
    @Binding var isPresented: Bool

    private let playerManager = GlobalPlayerManager.shared
    @State private var newPlayerName = ""
    @FocusState private var inputFocused: Bool

    var body: some View {
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
                                                .stroke(
                                                    inputFocused
                                                        ? SoundCinemaStyle.accentCyan.opacity(0.5)
                                                        : Color.white.opacity(0.08),
                                                    lineWidth: 1
                                                )
                                        )
                                )

                                Button { addCurrentName() } label: {
                                    Image(systemName: "plus")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundStyle(
                                            newPlayerName.trimmingCharacters(in: .whitespaces).isEmpty
                                                ? .gray : .black
                                        )
                                        .frame(width: 46, height: 46)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(
                                                    newPlayerName.trimmingCharacters(in: .whitespaces).isEmpty
                                                        ? Color.white.opacity(0.06)
                                                        : SoundCinemaStyle.accentCyan
                                                )
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
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 14)
                                                        .stroke(SoundCinemaStyle.accentCyan.opacity(0.35), lineWidth: 1)
                                                )
                                        )
                                    }
                                }
                            }
                        }

                        // Gespeicherte Spieler (nur nicht-ausgewählte)
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
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 14)
                                                            .stroke(Color.white.opacity(0.07), lineWidth: 1)
                                                    )
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
                    Button("Fertig") { isPresented = false }
                        .font(.headline)
                        .foregroundStyle(SoundCinemaStyle.accentCyan)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(28)
    }

    private func addCurrentName() {
        let trimmed = newPlayerName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !selectedNames.contains(trimmed) else {
            newPlayerName = ""
            return
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        withAnimation(.spring(response: 0.35)) { selectedNames.append(trimmed) }
        GlobalPlayerManager.shared.addPlayer(name: trimmed)
        newPlayerName = ""
    }
}

// MARK: - Pack Picker Sheet

struct SoundCinemaPackPickerSheet: View {
    @Binding var selectedPacks: Set<SoundCinemaPack>
    @Binding var isPresented: Bool

    var body: some View {
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
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14)
                                                .stroke(
                                                    isSelected ? accent.opacity(0.4) : Color.white.opacity(0.07),
                                                    lineWidth: 1
                                                )
                                        )
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
                    Button("Fertig") { isPresented = false }
                        .font(.headline)
                        .foregroundStyle(SoundCinemaStyle.accentCyan)
                }
            }
        }
        .presentationDetents([.fraction(0.52)])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(28)
    }
}

// MARK: - Timer Picker Sheet

struct SoundCinemaTimerPickerSheet: View {
    @Binding var timerMode: SoundCinemaTimerMode
    @Binding var isPresented: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                SoundCinemaBackground()
                VStack(spacing: 10) {
                    ForEach(SoundCinemaTimerMode.allCases) { mode in
                        let isSelected = timerMode == mode
                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            withAnimation(.spring(response: 0.3)) { timerMode = mode }
                            isPresented = false
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
                                    .foregroundStyle(
                                        isSelected ? SoundCinemaStyle.accentCyan : SoundCinemaStyle.textMuted
                                    )
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(isSelected ? SoundCinemaStyle.accentCyan.opacity(0.10) : Color.white.opacity(0.04))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(
                                                isSelected ? SoundCinemaStyle.accentCyan.opacity(0.4) : Color.white.opacity(0.07),
                                                lineWidth: 1
                                            )
                                    )
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
                    Button("Fertig") { isPresented = false }
                        .font(.headline)
                        .foregroundStyle(SoundCinemaStyle.accentCyan)
                }
            }
        }
        .presentationDetents([.fraction(0.42)])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(28)
    }
}

// MARK: - Lives Picker Sheet

struct SoundCinemaLivesPickerSheet: View {
    @Binding var livesMode: SoundCinemaLivesMode
    @Binding var isPresented: Bool

    var body: some View {
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
                            isPresented = false
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
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(
                                                isSelected ? accent.opacity(0.4) : Color.white.opacity(0.07),
                                                lineWidth: 1
                                            )
                                    )
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
                    Button("Fertig") { isPresented = false }
                        .font(.headline)
                        .foregroundStyle(SoundCinemaStyle.accentCyan)
                }
            }
        }
        .presentationDetents([.fraction(0.42)])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(28)
    }
}
