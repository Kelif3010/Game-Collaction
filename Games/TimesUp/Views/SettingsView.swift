//
//  SettingsView.swift
//  TimesUp
//

import SwiftUI

// MARK: - Color Helpers
private extension Color {
    init(hex: String, alpha: Double = 1.0) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&int)
        let r, g, b: UInt64
        switch cleaned.count {
        case 3: // RGB (12-bit)
            (r, g, b) = ((int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: alpha
        )
    }
}

private struct SettingsTheme {
    static let gradient = LinearGradient(
        colors: [Color(hex: "#7C3AED"), Color(hex: "#22D3EE")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let glassBackground = Color.white.opacity(0.08)
    static let cardBackground = Color.white.opacity(0.06)
    static let tileBackground = Color.white.opacity(0.04)
    static let cornerRadius: CGFloat = 18
    static let tileRadius: CGFloat = 14
    static let horizontalPadding: CGFloat = 20
    static let verticalSpacing: CGFloat = 16
    static let blurRadius: CGFloat = 14
}

private struct SettingsSectionCard<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12, content: content)
            .padding(16)
            .background(SettingsTheme.cardBackground)
            .background(.ultraThinMaterial)
            .cornerRadius(SettingsTheme.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: SettingsTheme.cornerRadius)
                    .stroke(Color.white.opacity(0.08))
            )
            .shadow(color: Color.black.opacity(0.25), radius: 16, x: 0, y: 12)
    }
}

private struct Pill: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.footnote.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(color.opacity(0.15))
            .foregroundColor(color)
            .cornerRadius(12)
    }
}

private struct SummaryCard<Content: View>: View {
    let title: String
    let subtitle: String
    let icon: String
    let tint: Color
    @ViewBuilder let content: () -> Content

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            LinearGradient(
                colors: [tint, tint.opacity(0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .mask(
                Image(systemName: icon)
                    .font(.title2.weight(.semibold))
            )
            .frame(width: 36, height: 36)
            .background(tint.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.headline.weight(.semibold))
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                content()
            }
            Spacer()
        }
        .padding(16)
        .background(SettingsTheme.tileBackground)
        .background(.thinMaterial)
        .cornerRadius(SettingsTheme.tileRadius)
        .overlay(
            RoundedRectangle(cornerRadius: SettingsTheme.tileRadius)
                .stroke(Color.white.opacity(0.08))
        )
        .shadow(color: tint.opacity(0.2), radius: 12, x: 0, y: 8)
    }
}

private struct SettingsHeader: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Spieleinstellungen")
                .font(.system(size: 32, weight: .heavy, design: .rounded))
                .foregroundStyle(SettingsTheme.gradient)

            Text("Stell nur das Nötigste ein. Alles Weitere findest du in den Detailseiten.")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct StartGameButton: View {
    let enabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "play.fill")
                Text("Spiel starten!")
                    .font(.headline.weight(.bold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                enabled
                ? AnyShapeStyle(LinearGradient(colors: [Color(hex: "#22D3EE"), Color(hex: "#7C3AED")], startPoint: .leading, endPoint: .trailing))
                : AnyShapeStyle(Color.gray.opacity(0.6))
            )
            .cornerRadius(18)
            .shadow(color: enabled ? Color.blue.opacity(0.45) : .clear, radius: 12, x: 0, y: 6)
        }
        .disabled(!enabled)
    }
}

// MARK: - Router
private enum SettingsRoute: Hashable {
    case teams
    case categories
    case gameplay
}

// MARK: - Main View
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    private let categoryManager: CategoryManager
    @StateObject private var gameManager: GameManager
    @State private var showGame = false
    @State private var path: [SettingsRoute] = []

    init(categoryManager: CategoryManager) {
        self.categoryManager = categoryManager
        _gameManager = StateObject(wrappedValue: GameManager(categoryManager: categoryManager))
    }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: SettingsTheme.verticalSpacing) {
                    SettingsHeader()

                    NavigationLink(value: SettingsRoute.teams) {
                        SummaryCard(
                            title: "Teams",
                            subtitle: "\(gameManager.gameState.settings.teams.count) Teams",
                            icon: "person.3.fill",
                            tint: .blue
                        ) {
                            if let first = gameManager.gameState.settings.teams.first {
                                Text("Erstes Team: \(first.name)")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("Noch keine Teams – jetzt hinzufügen")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    NavigationLink(value: SettingsRoute.categories) {
                        SummaryCard(
                            title: "Kategorien",
                            subtitle: "\(gameManager.gameState.settings.selectedCategories.count) ausgewählt",
                            icon: "folder.badge.gearshape",
                            tint: .orange
                        ) {
                            if gameManager.gameState.settings.selectedCategories.isEmpty {
                                Text("Mindestens eine Kategorie wählen")
                                    .font(.footnote)
                                    .foregroundColor(.orange)
                            } else {
                                Text("Gesamt: \(gameManager.availableCategories.count) verfügbar")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    NavigationLink(value: SettingsRoute.gameplay) {
                        SummaryCard(
                            title: "Spiel & Perks",
                            subtitle: "\(Int(gameManager.gameState.settings.turnTimeLimit)) Sek · \(gameManager.gameState.settings.wordCount) Wörter",
                            icon: "slider.horizontal.3",
                            tint: .purple
                        ) {
                            HStack(spacing: 8) {
                                Pill(text: gameManager.gameState.settings.difficulty.rawValue, color: .purple)
                                Pill(text: gameManager.gameState.settings.gameMode.rawValue, color: .pink)
                                let perkText = gameManager.gameState.settings.perksEnabled ? "Perks an" : "Perks aus"
                                Pill(text: perkText, color: gameManager.gameState.settings.perksEnabled ? .green : .gray)
                            }
                        }
                    }
                }
                .padding(.horizontal, SettingsTheme.horizontalPadding)
                .padding(.top, 16)
                .padding(.bottom, 80)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Einstellungen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.white.opacity(0.85))
                            .padding(6)
                            .background(Color.white.opacity(0.08))
                            .clipShape(Circle())
                    }
                }
            }
            .navigationDestination(for: SettingsRoute.self) { route in
                switch route {
                case .teams:
                    TeamsDetailView(gameManager: gameManager)
                case .categories:
                    CategoriesDetailView(gameManager: gameManager)
                case .gameplay:
                    GameplayDetailView(gameManager: gameManager)
                }
            }
            .fullScreenCover(isPresented: $showGame) {
                // HIER GEÄNDERT: TimesUpGameView statt GameView
                TimesUpGameView(gameManager: gameManager)
            }
            .safeAreaInset(edge: .bottom) {
                StartGameButton(enabled: gameManager.canStartGame, action: startGame)
                .padding(.horizontal, SettingsTheme.horizontalPadding)
                .padding(.bottom, 8)
                .background(
                    LinearGradient(
                        colors: [Color.black.opacity(0.35), Color.black.opacity(0.6)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .blur(radius: 10)
                )
            }
        }
    }

    private func startGame() {
        gameManager.startGame()
        showGame = true
    }
}

// MARK: - Detail Screens
private struct TeamsDetailView: View {
    @ObservedObject var gameManager: GameManager
    @State private var newTeamName = ""

    var body: some View {
        ScrollView {
            SettingsSectionCard {
                HStack {
                    Text("Teams verwalten")
                        .font(.title2.weight(.bold))
                    Spacer()
                }

                HStack(spacing: 12) {
                    TextField("Teamname eingeben", text: $newTeamName)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit(addTeamIfPossible)

                    Button(action: addTeamIfPossible) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.blue)
                            .clipShape(Circle())
                    }
                    .disabled(newTeamName.trimmingCharacters(in: .whitespaces).isEmpty)
                }

                VStack(spacing: 10) {
                    ForEach(gameManager.gameState.settings.teams) { team in
                        HStack {
                            Image(systemName: "person.2.fill")
                                .foregroundColor(.blue)
                            Text(team.name)
                                .font(.body.weight(.medium))
                            Spacer()
                            Button {
                                gameManager.removeTeam(team)
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 12)
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                    }
                }

                if gameManager.gameState.settings.teams.count < 2 {
                    Label("Mindestens 2 Teams erforderlich", systemImage: "exclamationmark.triangle.fill")
                        .font(.footnote.weight(.semibold))
                        .foregroundColor(.orange)
                }
            }
            .padding(.horizontal, SettingsTheme.horizontalPadding)
            .padding(.top, 16)
            .padding(.bottom, 24)
        }
        .background(
            ZStack {
                SettingsTheme.gradient
                    .ignoresSafeArea()
                Color.black.opacity(0.35)
                    .ignoresSafeArea()
            }
        )
        .navigationTitle("Teams")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func addTeamIfPossible() {
        let name = newTeamName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        gameManager.addTeam(name: name)
        newTeamName = ""
    }
}

private struct CategoriesDetailView: View {
    @ObservedObject var gameManager: GameManager
    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ScrollView {
            SettingsSectionCard {
                HStack {
                    Text("Kategorien")
                        .font(.title2.weight(.bold))
                    Spacer()
                    Text("\(gameManager.gameState.settings.selectedCategories.count)/\(gameManager.availableCategories.count)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(gameManager.availableCategories) { category in
                        CategoryCard(
                            category: category,
                            isSelected: gameManager.gameState.settings.selectedCategories.contains(category),
                            onTap: { gameManager.toggleCategory(category) }
                        )
                    }
                }

                if gameManager.gameState.settings.selectedCategories.isEmpty {
                    Label("Mindestens eine Kategorie auswählen", systemImage: "exclamationmark.triangle.fill")
                        .font(.footnote.weight(.semibold))
                        .foregroundColor(.orange)
                }
            }
            .padding(.horizontal, SettingsTheme.horizontalPadding)
            .padding(.top, 16)
            .padding(.bottom, 24)
        }
        .background(
            ZStack {
                SettingsTheme.gradient
                    .ignoresSafeArea()
                Color.black.opacity(0.35)
                    .ignoresSafeArea()
            }
        )
        .navigationTitle("Kategorien")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct GameplayDetailView: View {
    @ObservedObject var gameManager: GameManager

    private var wordCountRange: ClosedRange<Double> {
        let minVal = Double(gameManager.gameState.settings.minWordCount)
        let maxVal = max(minVal + 1, Double(gameManager.gameState.settings.maxWordCount))
        return minVal...maxVal
    }

    private var wordCountBinding: Binding<Double> {
        let range = wordCountRange
        return Binding(
            get: {
                let current = Double(gameManager.gameState.settings.wordCount)
                return min(max(current, range.lowerBound), range.upperBound)
            },
            set: { gameManager.gameState.settings.wordCount = Int($0) }
        )
    }

    var body: some View {
        ScrollView {
            VStack(spacing: SettingsTheme.verticalSpacing) {
                SettingsSectionCard {
                    Text("Zeit & Wörter")
                        .font(.title3.weight(.bold))

                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Label("Zeitlimit pro Zug", systemImage: "timer.circle.fill")
                            Spacer()
                            Text("\(Int(gameManager.gameState.settings.turnTimeLimit)) Sek.")
                                .font(.headline.weight(.bold))
                        }
                        Slider(
                            value: Binding(
                                get: { gameManager.gameState.settings.turnTimeLimit },
                                set: { gameManager.gameState.settings.turnTimeLimit = $0 }
                            ),
                            in: 10...120,
                            step: 1
                        )
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Label("Anzahl Wörter", systemImage: "textformat.123")
                            Spacer()
                            Text("\(gameManager.gameState.settings.wordCount)")
                                .font(.headline.weight(.bold))
                        }
                        Slider(
                            value: wordCountBinding,
                            in: wordCountRange,
                            step: 1
                        )
                        .disabled(gameManager.gameState.settings.selectedCategories.isEmpty)

                        HStack {
                            Text("Min: \(gameManager.gameState.settings.minWordCount)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("Verfügbar: \(gameManager.gameState.settings.availableWordCount)")
                                .font(.caption)
                                .foregroundColor(gameManager.gameState.settings.availableWordCount < gameManager.gameState.settings.minWordCount ? .red : .secondary)
                        }

                        if gameManager.gameState.settings.availableWordCount < gameManager.gameState.settings.minWordCount {
                            Label("Wähle mehr Kategorien für mindestens \(gameManager.gameState.settings.minWordCount) Wörter", systemImage: "exclamationmark.triangle.fill")
                                .font(.caption.weight(.medium))
                                .foregroundColor(.orange)
                        }
                    }
                }

                SettingsSectionCard {
                    Text("Schwierigkeit & Modus")
                        .font(.title3.weight(.bold))

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Schwierigkeit")
                            .font(.headline)
                        HStack(spacing: 10) {
                            ForEach(Difficulty.allCases, id: \.self) { diff in
                                Button {
                                    gameManager.gameState.settings.difficulty = diff
                                } label: {
                                    Text(diff.rawValue)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundColor(gameManager.gameState.settings.difficulty == diff ? .white : .primary)
                                        .padding(.vertical, 10)
                                        .frame(maxWidth: .infinity)
                                        .background(gameManager.gameState.settings.difficulty == diff ? diffColor(diff) : Color(.systemGray6))
                                        .cornerRadius(12)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Spielmodus")
                            .font(.headline)
                        HStack(spacing: 10) {
                            ForEach(TimesUpGameMode.allCases, id: \.self) { mode in
                                Button {
                                    gameManager.gameState.settings.gameMode = mode
                                } label: {
                                    Text(mode.rawValue)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundColor(gameManager.gameState.settings.gameMode == mode ? .white : .purple)
                                        .padding(.vertical, 10)
                                        .frame(maxWidth: .infinity)
                                        .background(gameManager.gameState.settings.gameMode == mode ? Color.purple : Color(.systemGray6))
                                        .cornerRadius(12)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        Text(gameManager.gameState.settings.gameMode.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                PerkSettingsCard(gameManager: gameManager)
            }
            .padding(.horizontal, SettingsTheme.horizontalPadding)
            .padding(.top, 16)
            .padding(.bottom, 24)
        }
        .background(
            ZStack {
                SettingsTheme.gradient
                    .ignoresSafeArea()
                Color.black.opacity(0.35)
                    .ignoresSafeArea()
            }
        )
        .navigationTitle("Spiel & Perks")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func diffColor(_ difficulty: Difficulty) -> Color {
        let label = difficulty.rawValue.lowercased()
        if label.contains("leicht") || label.contains("easy") { return .green }
        if label.contains("mittel") || label.contains("medium") { return .yellow }
        if label.contains("schwer") || label.contains("hard") { return .red }
        return .purple
    }
}

// MARK: - Supporting Views
private struct CategoryCard: View {
    // HIER GEÄNDERT: TimesUpCategory
    let category: TimesUpCategory
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(systemName: category.type.systemImage)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(isSelected ? category.type.color : .secondary)

                Text(category.name)
                    .font(.callout.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)
                    .lineLimit(2)
            }
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? category.type.color.opacity(0.15) : Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? category.type.color : Color.primary.opacity(0.08), lineWidth: 1.5)
            )
            .shadow(color: isSelected ? category.type.color.opacity(0.2) : .clear, radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}

private struct PerkSettingsCard: View {
    @ObservedObject var gameManager: GameManager

    private var perksEnabled: Binding<Bool> {
        Binding(
            get: { gameManager.gameState.settings.perksEnabled },
            set: { newValue in
                gameManager.gameState.settings.perksEnabled = newValue
                if !newValue {
                    gameManager.gameState.settings.selectedPerkPacks.removeAll()
                    gameManager.gameState.settings.clearCustomPerks()
                    gameManager.gameState.settings.perkPartyMode = false
                }
            }
        )
    }

    private var partyModeEnabled: Binding<Bool> {
        Binding(
            get: { gameManager.gameState.settings.perkPartyMode },
            set: { newValue in
                gameManager.gameState.settings.perkPartyMode = newValue
            }
        )
    }

    private func packTint(_ pack: PerkPack) -> Color {
        switch pack {
        case .tempo: return .blue
        case .score: return .green
        case .sabotage: return .pink
        case .custom: return .orange
        }
    }

    var body: some View {
        SettingsSectionCard {
            HStack {
                Text("Perks")
                    .font(.title3.weight(.bold))
                Spacer()
                Toggle("", isOn: perksEnabled)
                    .labelsHidden()
            }

            Text("Optionale Power-Ups. Nach mehreren richtigen Antworten erscheinen Perks aus ausgewählten Paketen.")
                .font(.subheadline)
                .foregroundColor(.secondary)

            if gameManager.gameState.settings.perksEnabled {
                Toggle(isOn: partyModeEnabled) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Party Modus")
                            .font(.subheadline.weight(.semibold))
                        Text("Frühere Perks bei 3/6/9 Treffern.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .toggleStyle(SwitchToggleStyle(tint: .purple))

                let columns = [GridItem(.flexible()), GridItem(.flexible())]
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(PerkPack.allCases) { pack in
                        let isSelected = gameManager.gameState.settings.selectedPerkPacks.contains(pack)
                        Button {
                            toggle(pack)
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                Image(systemName: pack.iconName)
                                    .font(.title3)
                                    .foregroundColor(packTint(pack))
                                Text(pack.title)
                                    .font(.headline)
                                Text(pack.subtitle)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(isSelected ? packTint(pack).opacity(0.15) : Color(.systemGray6))
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(isSelected ? packTint(pack) : Color.clear, lineWidth: 1.5)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }

                if gameManager.gameState.settings.selectedPerkPacks.contains(.custom) {
                    CustomPerkSelectionView(gameManager: gameManager)
                }

                if !gameManager.gameState.settings.hasAnyPerkSelection {
                    Text("Wähle mindestens ein Paket oder stelle eigene Perks zusammen, damit Perks erscheinen können.")
                        .font(.footnote)
                        .foregroundColor(.pink)
                }
            }
        }
    }

    private func toggle(_ pack: PerkPack) {
        if pack.isCustom {
            if gameManager.gameState.settings.selectedPerkPacks.contains(.custom) {
                gameManager.gameState.settings.clearCustomPerks()
            } else {
                gameManager.gameState.settings.selectedPerkPacks.insert(.custom)
            }
            return
        }

        if gameManager.gameState.settings.selectedPerkPacks.contains(pack) {
            gameManager.gameState.settings.selectedPerkPacks.remove(pack)
        } else {
            gameManager.gameState.settings.selectedPerkPacks.insert(pack)
        }
    }
}

private struct CustomPerkSelectionView: View {
    @ObservedObject var gameManager: GameManager
    @State private var expandedPacks: Set<PerkPack> = []

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Individuelle Auswahl")
                    .font(.headline.weight(.semibold))
                Spacer()
                // HIER GEÄNDERT: Explizite Button-Syntax
                Button(action: {
                    gameManager.gameState.settings.clearCustomPerks()
                }) {
                    Text("Zurücksetzen")
                }
                .font(.caption.bold())
                .disabled(gameManager.gameState.settings.customPerks.isEmpty)
            }

            ForEach(PerkPack.standardCases) { pack in
                DisclosureGroup(isExpanded: binding(for: pack)) {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(pack.associatedPerks, id: \.self) { perk in
                            Toggle(isOn: binding(for: perk)) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(perk.displayName)
                                        .font(.subheadline.weight(.semibold))
                                    Text(perk.detailDescription)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .toggleStyle(SwitchToggleStyle(tint: .purple))
                        }
                    }
                    .padding(.top, 6)
                } label: {
                    HStack {
                        Text(pack.title)
                            .font(.headline)
                        Spacer()
                        Text("\(selectedCount(for: pack))/\(pack.associatedPerks.count)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }

            if gameManager.gameState.settings.customPerks.isEmpty {
                Text("Wähle mindestens einen Perk aus, damit der individuelle Modus aktiv ist.")
                    .font(.footnote)
                    .foregroundColor(.pink)
            } else {
                Text("\(gameManager.gameState.settings.customPerks.count) Perks ausgewählt.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.top, 8)
        .animation(.easeInOut, value: gameManager.gameState.settings.customPerks.count)
    }

    private func binding(for pack: PerkPack) -> Binding<Bool> {
        Binding(
            get: { expandedPacks.contains(pack) },
            set: { newValue in
                if newValue {
                    expandedPacks.insert(pack)
                } else {
                    expandedPacks.remove(pack)
                }
            }
        )
    }

    private func binding(for perk: PerkType) -> Binding<Bool> {
        Binding(
            get: { gameManager.gameState.settings.customPerks.contains(perk) },
            set: { enabled in
                gameManager.gameState.settings.setCustomPerk(perk, enabled: enabled)
            }
        )
    }

    private func selectedCount(for pack: PerkPack) -> Int {
        let selected = gameManager.gameState.settings.customPerks
        return pack.associatedPerks.filter { selected.contains($0) }.count
    }
}

#Preview {
    SettingsView(categoryManager: CategoryManager())
}
