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

// MARK: - Shared Styles for Setup Screens
private enum SetupStyle {
    static let primaryGradient = LinearGradient(colors: [Color(red: 1.0, green: 0.41, blue: 0.23), Color(red: 0.94, green: 0.16, blue: 0.47)], startPoint: .topLeading, endPoint: .bottomTrailing)
    static let darkCardFill = Color(white: 0.12)
    static let cardStroke = Color.white.opacity(0.08)
}

private struct GradientPrimaryButton: View {
    let title: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline.bold())
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
        }
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(SetupStyle.primaryGradient)
        )
        .shadow(color: .black.opacity(0.25), radius: 16, y: 8)
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
                LinearGradient(
                    colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
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
                                .background(Color.white.opacity(0.15))
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
                                    .background(Color.white.opacity(0.15))
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
                                    .background(Color.white.opacity(0.15))
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
                                    .background(Color.white.opacity(0.15))
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
                                    .background(Color.white.opacity(0.15))
                                    .clipShape(Circle())
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                    .padding(.bottom, 10)

                    ScrollView {
                        VStack(spacing: 10) {

                            GroupedCard {
                                // Spieler Row
                                RowCell(icon: "person.3.fill", title: "Spieler", value: "\(gameSettings.players.count)")
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        showingAddPlayersSheet = true
                                    }

                                Divider()
                                    .opacity(0.2)
                                    .padding(.leading, 64)

                                // Spione Row with Stepper-like controls
                                HStack(spacing: 12) {
                                    IconBadge(systemName: "eye.slash.fill", tint: .red)
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
                                                .background(Color.secondary.opacity(0.15))
                                                .foregroundColor(.primary)
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
                                                .background(Color.secondary.opacity(0.15))
                                                .foregroundColor(.primary)
                                                .clipShape(Circle())
                                        }
                                        .disabled(gameSettings.randomSpyCount)
                                    }
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 14)
                                    .opacity(gameSettings.randomSpyCount ? 0.5 : 1.0)
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 14)

                                Divider()
                                    .opacity(0.2)
                                    .padding(.leading, 64)

                                // Spion-Optionen Row
                                RowCell(
                                    icon: "eye.fill",
                                    title: "Spion-Optionen",
                                    value: "\(activeSpyOptionsCount) aktiv",
                                    tint: .red
                                )
                                .contentShape(Rectangle())
                                .onTapGesture { showingSpyOptionsSheet = true }

                                Divider()
                                    .opacity(0.2)
                                    .padding(.leading, 64)

                                // Spielmodus Row
                                RowCell(icon: "gamecontroller.fill", title: "Spielmodus", value: gameSettings.gameMode.localizedTitle, tint: .accentColor, showsChevron: true)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        showingGameModeSheet = true
                                    }

                                Divider()
                                    .opacity(0.2)
                                    .padding(.leading, 64)

                                // Kategorie Row (Selection for Game)
                                RowCell(icon: "folder.fill", title: "Kategorie wählen", value: categoryDisplayName)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        showingCategorySelectionSheet = true
                                    }

                                Divider()
                                    .opacity(0.2)
                                    .padding(.leading, 64)

                                // Dauer Row
                                RowCell(icon: "timer.circle.fill", title: "Dauer", value: timeString(from: gameSettings.timeLimit), tint: .green, showsChevron: false)

                                Divider()
                                    .opacity(0.2)
                                    .padding(.leading, 64)

                                Slider(value: Binding(
                                    get: { Double(gameSettings.timeLimit) },
                                    set: { gameSettings.timeLimit = Int($0) }
                                ), in: 60...1800, step: 60)
                                .tint(.green)
                                .padding(.horizontal, 14)
                                .padding(.bottom, 14)
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
                    GradientPrimaryButton(title: "Spiel starten") {
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
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)
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
            .presentationBackground(.regularMaterial)
        }
        .sheet(isPresented: $showingCategorySelectionSheet) {
            CategorySelectionSheet(gameSettings: gameSettings)
            .presentationDetents([.large])
            .presentationCornerRadius(28)
            .presentationBackground(.regularMaterial)
        }
        .sheet(isPresented: $showingSpyOptionsSheet) {
            SpyOptionsView()
                .environmentObject(gameSettings)
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
            missingItems.append("Kategorie wählen")
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
        VStack(spacing: 0) {
            content
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 12, y: 6)
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
            IconBadge(systemName: icon, tint: tint)
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
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
    }
}

private struct IconBadge: View {
    let systemName: String
    let tint: Color

    var body: some View {
        ZStack {
            Circle()
                .fill(tint.opacity(0.15))
            Image(systemName: systemName)
                .foregroundColor(tint)
                .font(.system(size: 16, weight: .semibold))
        }
        .frame(width: 36, height: 36)
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
        VStack(spacing: 16) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "eye.slash.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(.white)
                    .padding(10)
                    .background(Circle().fill(Color.white.opacity(0.15)))
                Text("Spion-Optionen")
                    .font(.largeTitle.bold())
                Text("Passe die Regeln für Spione an")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 12)

            // Content
            VStack(spacing: 12) {
                Toggle(isOn: $gameSettings.spyCanSeeCategory) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Kategorie sichtbar")
                            .font(.headline)
                        Text("Spione sehen die gewählte Kategorie.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .toggleStyle(SwitchToggleStyle(tint: .green))
                .padding()
                .background(RoundedRectangle(cornerRadius: 16).fill(SetupStyle.darkCardFill))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(SetupStyle.cardStroke, lineWidth: 1))

                Toggle(isOn: Binding(
                    get: { gameSettings.spiesCanSeeEachOther && gameSettings.numberOfImposters >= 2 },
                    set: { newVal in gameSettings.spiesCanSeeEachOther = newVal }
                )) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Spione sehen sich gegenseitig")
                            .font(.headline)
                        Text("Aktiv, wenn es mindestens zwei Spione gibt.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .disabled(gameSettings.numberOfImposters < 2)
                .opacity(gameSettings.numberOfImposters < 2 ? 0.5 : 1)
                .toggleStyle(SwitchToggleStyle(tint: .green))
                .padding()
                .background(RoundedRectangle(cornerRadius: 16).fill(SetupStyle.darkCardFill))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(SetupStyle.cardStroke, lineWidth: 1))

                Toggle(isOn: $gameSettings.randomSpyCount) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Zahl der Spione zufällig")
                            .font(.headline)
                        Text("Die Anzahl kann pro Spiel variieren.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .toggleStyle(SwitchToggleStyle(tint: .green))
                .padding()
                .background(RoundedRectangle(cornerRadius: 16).fill(SetupStyle.darkCardFill))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(SetupStyle.cardStroke, lineWidth: 1))

                Toggle(isOn: $gameSettings.showSpyHints) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Spion‑Hinweise anzeigen")
                            .font(.headline)
                        Text("Zeigt dezente Tipps für Spione in der Runde.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .toggleStyle(SwitchToggleStyle(tint: .green))
                .padding()
                .background(RoundedRectangle(cornerRadius: 16).fill(SetupStyle.darkCardFill))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(SetupStyle.cardStroke, lineWidth: 1))
            }
            .padding(.horizontal)

            // Bottom actions
            HStack(spacing: 16) {
                Spacer()
                GradientPrimaryButton(title: "Speichern") {
                    dismiss()
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
        .presentationDragIndicator(.visible)
    }
}

private struct CategorySelectionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var gameSettings: GameSettings

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    private var isRolesLocked: Bool {
        gameSettings.gameMode == .roles
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
        VStack(spacing: 16) {
            HStack(alignment: .center) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.primary)
                        .padding(8)
                        .background(
                            Circle().fill(Color.secondary.opacity(0.15))
                        )
                        .accessibilityLabel("Zurück")
                }

                Spacer()

                Text("Kategorien")
                    .font(.largeTitle.bold())
                    .lineLimit(1)

                Spacer()

                Color.clear
                    .frame(width: 44, height: 44)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal)
            .padding(.top, 12)
            .padding(.bottom, 8)
            .background(
                .ultraThinMaterial,
                in: RoundedRectangle(cornerRadius: 20, style: .continuous)
            )
            .padding(.horizontal)

            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    Button {
                        toggleMixSelection()
                    } label: {
                        CategoryCardView(
                            name: "Mix",
                            emoji: "🔀",
                            isSelected: gameSettings.isMixAllCategories,
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
                            CategoryCardView(
                                name: category.name,
                                emoji: category.emoji,
                                isSelected: gameSettings.selectedCategoryIds.contains(category.id),
                                isDisabled: isDisabled
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(isDisabled)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
        }
    }
}

private struct CategoryCardView: View {
    let name: String
    let emoji: String
    let isSelected: Bool
    var isDisabled: Bool = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 12) {
                Text(emoji)
                    .font(.system(size: 48))
                Text(name)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)
            }
            .padding(20)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(LinearGradient(colors: [Color.orange.opacity(0.15), Color.red.opacity(0.15)], startPoint: .topLeading, endPoint: .bottomTrailing))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.orange : Color.clear, lineWidth: 3)
            )
            .opacity(isDisabled ? 0.4 : 1.0)

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(Color.orange)
                    .padding(8)
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
        VStack(spacing: 16) {
            Text("Spielmodus")
                .font(.largeTitle)
                .bold()
                .padding(.top, 20)
            
            if current == .roles && !canUseRolesMode {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("Rollen-Modus ist nur mit der Kategorie 'Orte' verfügbar")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }

            ScrollView {
                VStack(spacing: 16) {
                    // Filter out questions mode completely
                    ForEach(ImposterGameMode.allCases.filter { $0 != .questions }, id: \.self) { mode in
                        Button {
                            if mode == .roles && !canUseRolesMode {
                                return
                            }
                            current = mode
                        } label: {
                            GameModeCardView(
                                mode: mode,
                                isSelected: current == mode,
                                isDisabled: mode == .roles && !canUseRolesMode
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(mode == .roles && !canUseRolesMode)
                    }
                }
                .padding(.horizontal)
            }

            HStack {
                Spacer()
                GradientPrimaryButton(title: "Speichern") {
                    onSelect(current)
                    dismiss()
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
    }
}

private struct GameModeCardView: View {
    let mode: ImposterGameMode
    let isSelected: Bool
    var isDisabled: Bool = false
    
    private var features: [String] {
        switch mode {
        case .classic:
            return [
                "Ein oder mehrere Spione befinden sich unter euch. Ihr habt ein gemeinsames geheimes Wort, das nur die Eingeweihten kennen. Durch Diskussion und Deduktion versucht ihr herauszufinden, wer zur Gruppe gehört – und wer die Spione sind.",
            ]
        case .twoWords:
            return [
                "Zwei geheime Wörter",
                "Teams erhalten unterschiedliche Hinweise",
                "Mehr Bluff und Verwirrung"
            ]
        case .roles:
            return [
                "Jeder Spieler erhält eine passende Rolle",
                "KI-generierte Rollen basierend auf dem Ort",
                "Nur mit Kategorie 'Orte' verfügbar"
            ]
        default:
            return [
                "Modus: \(mode.localizedTitle)",
                "Standard-Regeln für diesen Modus",
                "Ideal für flexible Runden"
            ]
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: mode.icon)
                    .font(.title2)
                Text(mode.localizedTitle)
                    .font(.title3)
                    .bold()
                Spacer()
            }

            VStack(alignment: .leading, spacing: 6) {
                ForEach(features, id: \.self) { line in
                    Text("- \(line)")
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .font(.callout)
            .foregroundColor(isDisabled ? .secondary.opacity(0.5) : .secondary)
            
            if isDisabled {
                HStack {
                    Image(systemName: "lock.fill")
                        .font(.caption)
                    Text("Nur mit Kategorie 'Orte' verfügbar")
                        .font(.caption)
                }
                .foregroundColor(.orange)
                .padding(.top, 4)
            }

            if isSelected {
                HStack {
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(LinearGradient(
                    colors: isDisabled
                        ? [Color.gray.opacity(0.1), Color.gray.opacity(0.1)]
                        : [Color.orange.opacity(0.15), Color.red.opacity(0.15)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
        )
        .opacity(isDisabled ? 0.6 : 1.0)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isSelected ? Color.orange : Color.clear, lineWidth: 3)
        )
    }
}

#Preview {
    GameSetupView()
        .environmentObject(GameSettings())
}