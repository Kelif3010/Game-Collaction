//
//  GameSetupView.swift
//  Imposter
//
//  Created by Ken on 22.09.25.
//

import SwiftUI

private enum SetupRoute: Hashable {
    case game
}

extension ImposterGameMode {
    var localizedTitle: String {
        switch self {
        case .classic:
            return "Klassik"
        case .twoWords:
            return "Zwei‑Begriffe"
        case .roles:
            return "Rollen Modus"
        case .questions:
            return "Fragen Modus"
        @unknown default:
            return rawValue
        }
    }
}

struct GameSetupView: View {
    @EnvironmentObject var gameSettings: GameSettings
    @Environment(\.dismiss) private var dismiss
    @StateObject private var gameLogic: GameLogic

    @State private var newPlayerName: String = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var showingSpyOptionsSheet = false

    @State private var showingGameModeSheet = false
    @State private var showingCategorySelectionSheet = false // For selecting game category
    @State private var showingCategoryManagementSheet = false // For managing categories (Folder)
    @State private var showingSettingsSheet = false // For global settings (Gear)
    @State private var showingAddPlayersSheet = false
    @State private var addPlayersSheetDetent: PresentationDetent = .medium
    @State private var route: SetupRoute?

    init() {
        self._gameLogic = StateObject(wrappedValue: GameLogic(gameSettings: GameSettings()))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                ImposterStyle.backgroundGradient
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Top Bar
                    HStack {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.headline.bold())
                                .foregroundStyle(.white)
                                .frame(width: 36, height: 36)
                                .background(Color.white.opacity(0.1))
                                .clipShape(Circle())
                        }

                        Spacer()

                        HStack(spacing: 12) {
                            // Trophy (Placeholder for Leaderboard)
                            Button {
                                // Action for Leaderboard
                            } label: {
                                Image(systemName: "trophy.fill")
                                    .font(.headline)
                                    .foregroundStyle(.yellow)
                                    .frame(width: 36, height: 36)
                                    .background(Color.white.opacity(0.1))
                                    .clipShape(Circle())
                            }

                            // Folder (Category Management)
                            Button {
                                showingCategoryManagementSheet = true
                            } label: {
                                Image(systemName: "folder.fill")
                                    .font(.headline)
                                    .foregroundStyle(.orange)
                                    .frame(width: 36, height: 36)
                                    .background(Color.white.opacity(0.1))
                                    .clipShape(Circle())
                            }

                            // Gear (Settings)
                            Button {
                                showingSettingsSheet = true
                            } label: {
                                Image(systemName: "gearshape.fill")
                                    .font(.headline)
                                    .foregroundStyle(.gray)
                                    .frame(width: 36, height: 36)
                                    .background(Color.white.opacity(0.1))
                                    .clipShape(Circle())
                            }

                            // Question Mark (Rules/Help)
                            Button {
                                // Action for Help
                            } label: {
                                Image(systemName: "questionmark")
                                    .font(.headline.bold())
                                    .foregroundStyle(.white)
                                    .frame(width: 36, height: 36)
                                    .background(Color.white.opacity(0.1))
                                    .clipShape(Circle())
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                    .padding(.bottom, 10)

                    ScrollView {
                        VStack(spacing: 16) {
                            GroupedCard {
                                // Spieler Row
                                RowCell(icon: "person.3.fill", title: "Spieler", value: "\(gameSettings.players.count)")
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        showingAddPlayersSheet = true
                                    }

                                // Spione Row with Stepper-like controls
                                HStack(spacing: 12) {
                                    ImposterIconBadge(systemName: "eye.slash.fill", tint: .red)
                                    Text("Spione")
                                        .font(.body)
                                        .fontWeight(.semibold)
                                    Spacer()
                                    HStack(spacing: 8) {
                                        Button {
                                            let minValue = gameSettings.maxAllowedImpostersCap == 0 ? 0 : 1
                                            gameSettings.numberOfImposters = max(minValue, gameSettings.numberOfImposters - 1)
                                        } label: {
                                            Image(systemName: "minus")
                                                .font(.system(size: 16, weight: .semibold))
                                                .frame(width: 30, height: 30)
                                                .background(Color.white.opacity(0.12))
                                                .foregroundColor(.white)
                                                .clipShape(Circle())
                                        }
                                        .disabled(gameSettings.randomSpyCount)
                                        Text("\(gameSettings.numberOfImposters)")
                                            .font(.callout)
                                            .frame(minWidth: 24)
                                        Button {
                                            let cap = gameSettings.maxAllowedImpostersCap
                                            guard cap > 0 else {
                                                gameSettings.numberOfImposters = 0
                                                return
                                            }
                                            gameSettings.numberOfImposters = min(cap, gameSettings.numberOfImposters + 1)
                                        } label: {
                                            Image(systemName: "plus")
                                                .font(.system(size: 16, weight: .semibold))
                                                .frame(width: 30, height: 30)
                                                .background(Color.white.opacity(0.12))
                                                .foregroundColor(.white)
                                                .clipShape(Circle())
                                        }
                                        .disabled(gameSettings.randomSpyCount)
                                    }
                                    .opacity(gameSettings.randomSpyCount ? 0.5 : 1.0)
                                }
                                .imposterRowStyle()

                                // Spion-Optionen Row
                                RowCell(
                                    icon: "eye.fill",
                                    title: "Spionoptionen",
                                    value: "\(activeSpyOptionsCount) aktiv",
                                    tint: .red
                                )
                                .contentShape(Rectangle())
                                .onTapGesture { showingSpyOptionsSheet = true }

                                // Spielmodus Row
                                RowCell(icon: "gamecontroller.fill", title: "Spielmodus", value: gameSettings.gameMode.localizedTitle, tint: .accentColor, showsChevron: true)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        showingGameModeSheet = true
                                    }

                                // Kategorie Row (Selection for Game)
                                RowCell(icon: "folder.fill", title: "Kategorie", value: categoryDisplayName)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        showingCategorySelectionSheet = true
                                    }

                                VStack(spacing: 10) {
                                    HStack(spacing: 12) {
                                        ImposterIconBadge(systemName: "timer.circle.fill", tint: .green)
                                        Text("Dauer")
                                            .font(.body)
                                            .fontWeight(.semibold)
                                        Spacer()
                                        Text(timeString(from: gameSettings.timeLimit))
                                            .font(.callout)
                                            .foregroundStyle(.secondary)
                                    }

                                    Slider(value: Binding(
                                        get: { Double(gameSettings.timeLimit) },
                                        set: { gameSettings.timeLimit = Int($0) }
                                    ), in: 60...1800, step: 60)
                                    .tint(.green)
                                }
                                .imposterRowStyle()
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 120)
                    }
                }
            }
            .navigationDestination(item: $route) { route in
                switch route {
                case .game:
                    GamePlayView()
                        .environmentObject(gameLogic)
                        .environmentObject(gameSettings)
                }
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .onChange(of: gameSettings.players.count) { _, _ in
            gameSettings.clampNumberOfImpostersToCap()
        }
        .onChange(of: gameSettings.isRolesCategorySelected) { _, isValid in
            if gameSettings.gameMode == .roles && !isValid {
                gameSettings.gameMode = .classic
            }
        }
        .onAppear {
            if !gameSettings.hasSelectedCategories {
                let fallbackCategory = gameSettings.categories.first(where: { $0.name == "Tiere" }) ?? gameSettings.categories.first
                if let fallbackCategory {
                    gameSettings.selectedCategory = fallbackCategory
                    gameSettings.selectedCategoryIds = [fallbackCategory.id]
                    gameSettings.isMixAllCategories = false
                }
            } else if gameSettings.selectedCategoryIds.isEmpty, let selectedCategory = gameSettings.selectedCategory {
                gameSettings.selectedCategoryIds = [selectedCategory.id]
            }
        }
        .safeAreaInset(edge: .bottom) {
            if route == nil {
                VStack(spacing: 10) {
                    ImposterPrimaryButton(title: "Spiel starten") {
                        startGame()
                    }
                    .contentShape(Rectangle())
                    .opacity(canStartGame ? 1.0 : 0.6)
                    .disabled(!canStartGame)
                    if !canStartGame {
                        Text(startButtonHintText)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
            }
        }
        .sheet(isPresented: $showingAddPlayersSheet) {
            PlayerManagementSheet(onRequestExpand: {
                addPlayersSheetDetent = .large
            })
            .environmentObject(gameSettings)
            .presentationDetents([.medium, .large], selection: $addPlayersSheetDetent)
            .presentationCornerRadius(28)
            .presentationBackground(.regularMaterial)
        }
        .sheet(isPresented: $showingGameModeSheet) {
            GameModeSheet(selected: gameSettings.gameMode, gameSettings: gameSettings) { mode in
                gameSettings.gameMode = mode
            }
            .presentationDetents([.fraction(0.7), .large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(28)
            .presentationBackground(.clear)
        }
        .sheet(isPresented: $showingCategorySelectionSheet) {
            CategorySelectionSheet(gameSettings: gameSettings)
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(28)
            .presentationBackground(.clear)
        }
        .sheet(isPresented: $showingSpyOptionsSheet) {
            SpyOptionsView()
                .environmentObject(gameSettings)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(28)
                .presentationBackground(.clear)
        }
        // New Sheets for Top Bar Icons
        .sheet(isPresented: $showingCategoryManagementSheet) {
            CategoriesView()
                .environmentObject(gameSettings)
        }
        .sheet(isPresented: $showingSettingsSheet) {
            ImposterSettingsView()
        }
        .alert("Fehler", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .onChange(of: gameSettings.requestExitToMain) { _, newValue in
            guard newValue else { return }
            dismiss()
            DispatchQueue.main.async {
                gameSettings.requestExitToMain = false
            }
        }
    }

    private func addPlayer() {
        let name = newPlayerName.trimmingCharacters(in: .whitespacesAndNewlines)

        if name.isEmpty {
            return
        }

        if gameSettings.players.contains(where: { $0.name == name }) {
            alertMessage = "Ein Spieler mit diesem Namen existiert bereits."
            showingAlert = true
            return
        }

        gameSettings.addPlayer(name: name)
        newPlayerName = ""
    }

    private var canStartGame: Bool {
        return gameSettings.players.count >= 4 && gameSettings.hasSelectedCategories && gameSettings.numberOfImposters < gameSettings.players.count
    }

    private var startButtonHintText: String {
        var missingItems: [String] = []
        let minPlayers = 4
        if gameSettings.players.count < minPlayers {
            let needed = minPlayers - gameSettings.players.count
            missingItems.append("Noch \(needed) Spieler benötigt")
        }
        
        if !gameSettings.hasSelectedCategories {
            missingItems.append("Kategorie")
        }
        
        if gameSettings.numberOfImposters >= gameSettings.players.count && gameSettings.players.count > 0 {
            missingItems.append("Zu viele Spione für die Spieleranzahl")
        }
        return missingItems.isEmpty ? "Alle Einstellungen vollständig" : missingItems.joined(separator: " • ")
    }

    private func startGame() {
        guard canStartGame else {
            alertMessage = "Bitte stelle sicher, dass mindestens 4 Spieler vorhanden sind und eine Kategorie ausgewählt wurde."
            showingAlert = true
            return
        }

        gameLogic.gameSettings = gameSettings
        
        Task { @MainActor in
            await gameLogic.startGame()
            route = .game
        }
    }

    private func timeString(from seconds: Int) -> String {
        let minutes = seconds / 60
        return minutes == 1 ? "1 Minute" : "\(minutes) Minuten"
    }

    private var activeSpyOptionsCount: Int {
        var count = 0
        if gameSettings.spyCanSeeCategory { count += 1 }
        if gameSettings.spiesCanSeeEachOther && gameSettings.numberOfImposters >= 2 { count += 1 }
        if gameSettings.randomSpyCount { count += 1 }
        if gameSettings.showSpyHints { count += 1 }
        return count
    }

    private var playerSummaryText: String {
        let count = gameSettings.players.count

        if count == 0 {
            return "Noch keine Spieler hinzugefügt"
        } else if count < 4 {
            let names = gameSettings.players.prefix(3).map { $0.name }.joined(separator: ", ")
            return "Noch \(4 - count) benötigt: \(names)"
        } else {
            let names = gameSettings.players.prefix(3).map { $0.name }.joined(separator: ", ")
            let additional = count > 3 ? " + \(count - 3) weitere" : ""
            return "Bereit: \(names)\(additional)"
        }
    }
    
    private var categoryDisplayName: String {
        return gameSettings.categorySelectionDisplayName
    }
}


// MARK: - Helper Views

private struct GroupedCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 12) {
            content
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: ImposterStyle.containerCornerRadius, style: .continuous)
                .fill(ImposterStyle.containerBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: ImposterStyle.containerCornerRadius, style: .continuous)
                .stroke(ImposterStyle.cardStroke, lineWidth: 1)
        )
    }
}

private struct RowCell: View {
    let icon: String
    let title: String
    let value: String
    var tint: Color = .accentColor
    var showsChevron: Bool = true

    var body: some View {
        HStack(spacing: 12) {
            ImposterIconBadge(systemName: icon, tint: tint)
            Text(title)
                .font(.body)
                .fontWeight(.semibold)
            Spacer()
            Text(value)
                .font(.callout)
                .foregroundStyle(.secondary)
            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.footnote)
                    .foregroundStyle(.tertiary)
            }
        }
        .imposterRowStyle()
    }
}

private struct SheetHeader: View {
    let title: String
    let onBack: () -> Void

    var body: some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.headline.bold())
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
            }

            Spacer()

            Text(title)
                .font(.title3.bold())
                .foregroundStyle(.white)

            Spacer()

            Color.clear
                .frame(width: 36, height: 36)
        }
        .padding(.top, 20)
        .padding(.bottom, 8)
    }
}

private struct SpyOptionRow: View {
    let icon: String
    let tint: Color
    let title: String
    let subtitle: String
    var isDisabled: Bool = false
    var isOn: Binding<Bool>

    var body: some View {
        HStack(spacing: 12) {
            ImposterIconBadge(systemName: icon, tint: tint)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(ImposterStyle.mutedText)
            }

            Spacer()

            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(.green)
        }
        .imposterRowStyle()
        .opacity(isDisabled ? 0.5 : 1.0)
        .disabled(isDisabled)
    }
}

private struct CategorySelectionRow: View {
    let name: String
    let emoji: String
    let detail: String
    let isSelected: Bool
    var isLocked: Bool = false
    var isDisabled: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.orange.opacity(0.35), Color.red.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)

                Text(emoji)
                    .font(.system(size: 20))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.headline)
                    .foregroundStyle(.white)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(ImposterStyle.mutedText)
            }

            Spacer()

            if isLocked {
                Image(systemName: "lock.fill")
                    .foregroundStyle(.orange)
                    .font(.headline)
            } else if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.headline)
            } else {
                Image(systemName: "circle")
                    .foregroundStyle(.white.opacity(0.3))
                    .font(.headline)
            }
        }
        .imposterRowStyle()
        .opacity(isDisabled ? 0.5 : 1.0)
    }
}

private struct GameModeRow: View {
    let mode: ImposterGameMode
    let isSelected: Bool
    var isDisabled: Bool = false

    private var accent: Color {
        isDisabled ? .gray : .orange
    }

    var body: some View {
        HStack(spacing: 12) {
            ImposterIconBadge(systemName: mode.icon, tint: accent)

            VStack(alignment: .leading, spacing: 4) {
                Text(mode.localizedTitle)
                    .font(.headline)
                    .foregroundStyle(.white)
                Text(mode.description)
                    .font(.caption)
                    .foregroundStyle(ImposterStyle.mutedText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            if isDisabled {
                Image(systemName: "lock.fill")
                    .foregroundStyle(.orange)
                    .font(.headline)
            } else if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.headline)
            } else {
                Image(systemName: "circle")
                    .foregroundStyle(.white.opacity(0.3))
                    .font(.headline)
            }
        }
        .imposterRowStyle()
        .opacity(isDisabled ? 0.5 : 1.0)
    }
}

private struct AddPlayersSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var names: [String]
    let onSave: ([String]) -> Void

    private func handleAddPlayer() { names.append("") }
    private func handleSave() { onSave(names); dismiss() }

    init(existingNames: [String], onSave: @escaping ([String]) -> Void) {
        if existingNames.isEmpty {
            self._names = State(initialValue: ["", "", "", ""])
        } else {
            self._names = State(initialValue: existingNames)
        }
        self.onSave = onSave
    }

    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 6) {
                Text("Spieler hinzufügen")
                    .font(.title)
                    .bold()

                Text("\(names.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }.count) Spieler")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 20)

            ScrollView {
                VStack(spacing: 14) {
                    ForEach(names.indices, id: \.self) { index in
                        HStack(spacing: 12) {
                            Image(systemName: "person.crop.circle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.orange)

                            TextField("Player \(index + 1)", text: $names[index])
                                .textFieldStyle(.roundedBorder)
                                .disableAutocorrection(true)
                                .autocapitalization(.words)
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }

            Button {
                handleAddPlayer()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                    Text("Spieler hinzufügen")
                }
                .font(.headline)
                .foregroundColor(.orange)
            }
            .buttonStyle(.borderless)

            HStack {
                Button(role: .cancel) {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.title3)
                        .padding()
                        .background(
                            Circle()
                                .fill(Color.secondary.opacity(0.15))
                        )
                }

                Spacer()

                Button {
                    handleSave()
                } label: {
                    Text("Speichern")
                        .font(.headline)
                        .bold()
                        .padding(.vertical, 12)
                        .padding(.horizontal, 28)
                        .background(
                            Capsule()
                                .fill(LinearGradient(colors: [Color.orange, Color.red], startPoint: .leading, endPoint: .trailing))
                        )
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
        .presentationDragIndicator(.visible)
        .padding(.horizontal)
    }
}

private struct SpyOptionsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var gameSettings: GameSettings

    var body: some View {
        ZStack {
            ImposterStyle.backgroundGradient.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    SheetHeader(title: "Spion-Optionen") {
                        dismiss()
                    }

                    Text("Passe die Regeln für Spione an")
                        .font(.subheadline)
                        .foregroundStyle(ImposterStyle.mutedText)
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 4)

                    VStack(spacing: 12) {
                        SpyOptionRow(
                            icon: "folder.fill",
                            tint: .orange,
                            title: "Kategorie sichtbar",
                            subtitle: "Spione sehen die gewählte Kategorie.",
                            isOn: $gameSettings.spyCanSeeCategory
                        )

                        SpyOptionRow(
                            icon: "person.2.fill",
                            tint: .orange,
                            title: "Spione sehen sich gegenseitig",
                            subtitle: "Aktiv, wenn es mindestens zwei Spione gibt.",
                            isDisabled: gameSettings.numberOfImposters < 2,
                            isOn: Binding(
                                get: { gameSettings.spiesCanSeeEachOther && gameSettings.numberOfImposters >= 2 },
                                set: { newVal in gameSettings.spiesCanSeeEachOther = newVal }
                            )
                        )

                        SpyOptionRow(
                            icon: "dice.fill",
                            tint: .orange,
                            title: "Zahl der Spione zufällig",
                            subtitle: "Die Anzahl kann pro Spiel variieren.",
                            isOn: $gameSettings.randomSpyCount
                        )

                        SpyOptionRow(
                            icon: "lightbulb.fill",
                            tint: .orange,
                            title: "Spion-Hinweise anzeigen",
                            subtitle: "Zeigt dezente Tipps für Spione in der Runde.",
                            isOn: $gameSettings.showSpyHints
                        )
                    }

                    ImposterPrimaryButton(title: "Speichern") {
                        dismiss()
                    }
                    .padding(.top, 8)
                }
                .padding(.horizontal, ImposterStyle.padding)
                .padding(.bottom, 40)
            }
        }
        .presentationDragIndicator(.visible)
    }
}

private struct CategorySelectionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var gameSettings: GameSettings

    private var isRolesLocked: Bool {
        gameSettings.gameMode == .roles
    }

    private var hasMultipleSelections: Bool {
        gameSettings.selectedCategoryIds.count > 1
    }

    private func toggleMixSelection() {
        if isRolesLocked {
            return
        }

        if gameSettings.isMixAllCategories {
            gameSettings.isMixAllCategories = false
        } else {
            gameSettings.isMixAllCategories = true
            gameSettings.selectedCategoryIds.removeAll()
            gameSettings.selectedCategory = nil
        }
        enforceRolesRuleIfNeeded()
    }

    private func toggleCategory(_ category: Category) {
        let isRolesCategory = category.name.lowercased() == "orte"
        if isRolesLocked && !isRolesCategory {
            return
        }

        if gameSettings.isMixAllCategories {
            gameSettings.isMixAllCategories = false
        }

        if gameSettings.selectedCategoryIds.contains(category.id) {
            gameSettings.selectedCategoryIds.remove(category.id)
        } else {
            gameSettings.selectedCategoryIds.insert(category.id)
        }

        updateSelectedCategoryReference()
        enforceRolesRuleIfNeeded()
    }

    private func clearSelectedCategories() {
        gameSettings.selectedCategoryIds.removeAll()
        gameSettings.selectedCategory = nil
        gameSettings.isMixAllCategories = false
        enforceRolesRuleIfNeeded()
    }

    private func updateSelectedCategoryReference() {
        if gameSettings.selectedCategoryIds.count == 1, let id = gameSettings.selectedCategoryIds.first,
           let category = gameSettings.categories.first(where: { $0.id == id }) {
            gameSettings.selectedCategory = category
        } else {
            gameSettings.selectedCategory = nil
        }
    }

    private func enforceRolesRuleIfNeeded() {
        if gameSettings.gameMode == .roles && !gameSettings.isRolesCategorySelected {
            gameSettings.gameMode = .classic
        }
    }

    var body: some View {
        ZStack {
            ImposterStyle.backgroundGradient.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    SheetHeader(title: "Kategorien") {
                        dismiss()
                    }

                    if isRolesLocked {
                        HStack(spacing: 12) {
                            ImposterIconBadge(systemName: "lock.fill", tint: .orange)
                            Text("Rollen-Modus erlaubt nur die Kategorie \"Orte\".")
                                .font(.subheadline)
                                .foregroundStyle(ImposterStyle.mutedText)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer()
                        }
                        .imposterRowStyle()
                    }

                    if hasMultipleSelections {
                        Button {
                            clearSelectedCategories()
                        } label: {
                            HStack(spacing: 12) {
                                ImposterIconBadge(systemName: "xmark.circle.fill", tint: .red)
                                Text("Alles abwählen")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                Spacer()
                            }
                            .imposterRowStyle()
                        }
                        .buttonStyle(.plain)
                    }

                    VStack(spacing: 12) {
                        Button {
                            toggleMixSelection()
                        } label: {
                            CategorySelectionRow(
                                name: "Mix",
                                emoji: "🔀",
                                detail: "Alle Kategorien",
                                isSelected: gameSettings.isMixAllCategories,
                                isLocked: isRolesLocked,
                                isDisabled: isRolesLocked
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(isRolesLocked)

                        ForEach(gameSettings.categories) { category in
                            let isRolesCategory = category.name.lowercased() == "orte"
                            let isDisabled = isRolesLocked && !isRolesCategory
                            Button {
                                toggleCategory(category)
                            } label: {
                                CategorySelectionRow(
                                    name: category.name,
                                    emoji: category.emoji,
                                    detail: "\(category.words.count) Begriffe",
                                    isSelected: gameSettings.selectedCategoryIds.contains(category.id),
                                    isLocked: isDisabled,
                                    isDisabled: isDisabled
                                )
                            }
                            .buttonStyle(.plain)
                            .disabled(isDisabled)
                        }
                    }

                    ImposterPrimaryButton(title: "Fertig", action: { dismiss() }, isDisabled: !gameSettings.hasSelectedCategories)
                        .padding(.top, 8)
                }
                .padding(.horizontal, ImposterStyle.padding)
                .padding(.bottom, 40)
            }
        }
    }
}

private struct GameModeSheet: View {
    @Environment(\.dismiss) private var dismiss
    let selected: ImposterGameMode
    let gameSettings: GameSettings
    let onSelect: (ImposterGameMode) -> Void

    @State private var current: ImposterGameMode

    init(selected: ImposterGameMode, gameSettings: GameSettings, onSelect: @escaping (ImposterGameMode) -> Void) {
        self.selected = selected
        self.gameSettings = gameSettings
        self.onSelect = onSelect
        _current = State(initialValue: selected)
    }
    
    private var canUseRolesMode: Bool {
        return gameSettings.isRolesCategorySelected
    }

    var body: some View {
        ZStack {
            ImposterStyle.backgroundGradient.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    SheetHeader(title: "Spielmodus") {
                        dismiss()
                    }

                    if !canUseRolesMode {
                        HStack(spacing: 12) {
                            ImposterIconBadge(systemName: "lock.fill", tint: .orange)
                            Text("Rollen-Modus ist nur mit der Kategorie \"Orte\" verfügbar.")
                                .font(.subheadline)
                                .foregroundStyle(ImposterStyle.mutedText)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer()
                        }
                        .imposterRowStyle()
                    }

                    VStack(spacing: 12) {
                        ForEach(ImposterGameMode.allCases.filter { $0 != .questions }, id: \.self) { mode in
                            let isDisabled = mode == .roles && !canUseRolesMode
                            Button {
                                if isDisabled {
                                    return
                                }
                                current = mode
                            } label: {
                                GameModeRow(
                                    mode: mode,
                                    isSelected: current == mode,
                                    isDisabled: isDisabled
                                )
                            }
                            .buttonStyle(.plain)
                            .disabled(isDisabled)
                        }
                    }

                    ImposterPrimaryButton(
                        title: "Speichern",
                        action: {
                            onSelect(current)
                            dismiss()
                        },
                        isDisabled: current == .roles && !canUseRolesMode
                    )
                    .padding(.top, 8)
                }
                .padding(.horizontal, ImposterStyle.padding)
                .padding(.bottom, 40)
            }
        }
    }
}

#Preview {
    GameSetupView()
        .environmentObject(GameSettings())
}
