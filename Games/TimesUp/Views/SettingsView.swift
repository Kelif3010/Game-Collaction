//
//  SettingsView.swift
//  TimesUp
//

import SwiftUI

// MARK: - Components

private struct TimesUpSettingsRow: View {
    enum RowType {
        case teams
        case categories
        case timeWords
        case perks
        case difficulty
        case mode
    }

    var icon: String
    var title: LocalizedStringKey
    var detail: String?
    var rowType: RowType
    var isToggleOn: Bool = false
    var onTap: (() -> Void)?
    var onToggle: ((Bool) -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(colors: [.blue.opacity(0.3), .purple.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .foregroundStyle(.white)
                    .font(.headline)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .foregroundStyle(.white)
                    .font(.headline)
                
                // Detail only for non-nav items that need explanation inline
                // HIDE detail for difficulty and mode (since it's shown on the right)
                if let detail, !detail.isEmpty, 
                   rowType != .teams, 
                   rowType != .categories,
                   rowType != .difficulty,
                   rowType != .mode {
                    Text(LocalizedStringKey(detail))
                        .foregroundStyle(TimesUpStyle.mutedText)
                        .font(.subheadline)
                }
            }
            Spacer()

            switch rowType {
            case .perks:
                // For Perks, we show a Toggle AND a Chevron if enabled?
                // The user wants a view to open.
                // Let's just use a Chevron for the view, but show status text.
                 HStack(spacing: 6) {
                    Text(isToggleOn ? "An" : "Aus")
                         .foregroundStyle(isToggleOn ? .green : TimesUpStyle.mutedText)
                        .font(.subheadline.weight(.semibold))
                    
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.white.opacity(0.5))
                        .font(.subheadline)
                }
            default:
                HStack(spacing: 6) {
                    if let detail, !detail.isEmpty {
                        // For difficulty and mode, detail is the raw value which is also the translation key
                        // Only show detail on the right for these types or teams/categories count
                        if rowType == .teams || rowType == .categories || rowType == .difficulty || rowType == .mode {
                            Text(LocalizedStringKey(detail))
                                .foregroundStyle(TimesUpStyle.mutedText)
                                .font(.subheadline.weight(.semibold))
                        }
                    }
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.white.opacity(0.5))
                        .font(.subheadline)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(TimesUpStyle.cardBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(TimesUpStyle.cardStroke, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .contentShape(Rectangle())
        .onTapGesture {
            onTap?()
        }
    }
}

// TimesUpPrimaryButton is now defined in TimesUpStyle.swift

// MARK: - Main Settings View
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.locale) private var locale
    private let categoryManager: CategoryManager
    @StateObject private var gameManager: GameManager
    
    // Navigation Path
    @State private var path: [SettingsRoute] = []
    
    // Sheets
    @State private var showGame = false
    @State private var showInfoSheet = false
    @State private var showLeaderboardSheet = false
    @State private var showTimeWordsSheet = false
    @State private var showDifficultySheet = false
    @State private var showGameModeSheet = false
    @State private var showCategoryManagement = false
    
    enum SettingsRoute: Hashable {
        case teams
        case categories
        case perks
    }

    init(categoryManager: CategoryManager) {
        self.categoryManager = categoryManager
        _gameManager = StateObject(wrappedValue: GameManager(categoryManager: categoryManager))
    }

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                TimesUpStyle.backgroundGradient.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header
                    topBar
                        .padding(.horizontal, TimesUpStyle.horizontalPadding)
                        .padding(.top, TimesUpStyle.horizontalPadding) // Changed to 20 (TimesUpStyle.horizontalPadding)
                        .padding(.bottom, 20)
                    
                    ScrollView {
                        VStack(spacing: 12) {
                            
                            // 1. Teams
                            TimesUpSettingsRow(
                                icon: "person.2.fill",
                                title: "Teams",
                                detail: "\(gameManager.gameState.settings.teams.count)",
                                rowType: .teams,
                                onTap: { path.append(.teams) }
                            )

                            // 2. Categories
                            TimesUpSettingsRow(
                                icon: "list.bullet.rectangle.portrait.fill",
                                title: "Kategorien",
                                detail: gameManager.gameState.settings.selectedCategories.isEmpty ? "Keine" : "\(gameManager.gameState.settings.selectedCategories.count)",
                                rowType: .categories,
                                onTap: { path.append(.categories) }
                            )

                            // 3. Zeit & Wörter (Sheet)
                            let time = Int(gameManager.gameState.settings.turnTimeLimit)
                            let count = gameManager.gameState.settings.wordCount
                            // Construct localized detail string manually to ensure "Words" is translated
                            let wordsLabel = String(localized: "Wörter", locale: locale)
                            let detailText = "\(time)s · \(count) \(wordsLabel)"
                            
                            TimesUpSettingsRow(
                                icon: "timer",
                                title: "Zeit & Wörter",
                                detail: detailText,
                                rowType: .timeWords,
                                onTap: {
                                    TimesUpHaptics.impact(.light)
                                    showTimeWordsSheet = true
                                }
                            )
                            
                            // 4. Perks
                            TimesUpSettingsRow(
                                icon: "sparkles",
                                title: "Perks",
                                detail: nil,
                                rowType: .perks,
                                isToggleOn: gameManager.gameState.settings.perksEnabled,
                                onTap: {
                                    // Always open the view to let user toggle inside or configure
                                    path.append(.perks)
                                }
                            )
                            
                            // 5. Difficulty
                            TimesUpSettingsRow(
                                icon: "gauge.medium",
                                title: "Schwierigkeit",
                                detail: gameManager.gameState.settings.difficulty.rawValue,
                                rowType: .difficulty,
                                onTap: {
                                    TimesUpHaptics.impact(.light)
                                    showDifficultySheet = true
                                }
                            )
                            
                            // 6. Game Mode
                            TimesUpSettingsRow(
                                icon: "gamecontroller.fill",
                                title: "Spielmodus",
                                detail: gameManager.gameState.settings.gameMode.rawValue,
                                rowType: .mode,
                                onTap: {
                                    TimesUpHaptics.impact(.light)
                                    showGameModeSheet = true
                                }
                            )
                        }
                        .padding()
                        .background(Color.black.opacity(0.25))
                        .clipShape(RoundedRectangle(cornerRadius: 22))
                        .overlay(
                            RoundedRectangle(cornerRadius: 22)
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        )
                        .padding(.horizontal, TimesUpStyle.horizontalPadding)
                        .padding(.bottom, 100)
                    }
                }
                
                // Start Button Floating at Bottom
                VStack {
                    Spacer()
                    TimesUpPrimaryButton(
                        title: "Spiel starten",
                        action: {
                            TimesUpHaptics.impact(.medium)
                            startGame()
                        },
                        isDisabled: !gameManager.canStartGame
                    )
                    .padding(.horizontal, TimesUpStyle.horizontalPadding)
                    .padding(.bottom, 32) // Matched BetBuddy (20 container + 12 button padding)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: SettingsRoute.self) { route in
                switch route {
                case .teams:
                    TeamsDetailView(gameManager: gameManager)
                case .categories:
                    CategoriesDetailView(gameManager: gameManager)
                case .perks:
                    PerkSettingsDetailView(gameManager: gameManager)
                }
            }
            .sheet(isPresented: $showTimeWordsSheet) {
                TimeAndWordsSheetView(gameManager: gameManager)
                    .presentationDetents([.medium, .fraction(0.6)])
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(28)
            }
            .sheet(isPresented: $showDifficultySheet) {
                TimesUpDifficultySheet(
                    selected: gameManager.gameState.settings.difficulty
                ) { difficulty in
                    gameManager.gameState.settings.difficulty = difficulty
                }
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(28)
            }
            .sheet(isPresented: $showGameModeSheet) {
                TimesUpGameModeSheet(
                    selected: gameManager.gameState.settings.gameMode
                ) { mode in
                    gameManager.gameState.settings.gameMode = mode
                }
                .presentationDetents([.medium, .fraction(0.58)])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(28)
            }
            .fullScreenCover(isPresented: $showGame) {
                TimesUpGameView(gameManager: gameManager)
            }
            .sheet(isPresented: $showInfoSheet) {
                TimesUpInfoSheet()
            }
            .sheet(isPresented: $showLeaderboardSheet) {
                TimesUpLeaderboardView()
            }
            .sheet(isPresented: $showCategoryManagement) {
                CategoryManagementView(categoryManager: categoryManager)
            }
        }
    }

    private var topBar: some View {
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

            Spacer()
            
            HStack(spacing: 12) {
                Button {
                    TimesUpHaptics.impact(.light)
                    showLeaderboardSheet = true
                } label: {
                    Image(systemName: "trophy.fill")
                        .font(.headline)
                        .foregroundStyle(.yellow)
                        .frame(width: 44, height: 44)
                        .modifier(GlassCircleButtonBackground())
                }
                
                Button {
                    TimesUpHaptics.impact(.light)
                    showCategoryManagement = true
                } label: {
                    Image(systemName: "folder.fill") // Or "folder.badge.gearshape" as requested
                        .font(.headline)
                        .foregroundStyle(.orange)
                        .frame(width: 44, height: 44)
                        .modifier(GlassCircleButtonBackground())
                }
                
                Button {
                    TimesUpHaptics.impact(.light)
                    showInfoSheet = true
                } label: {
                    Image(systemName: "questionmark")
                        .font(.headline.bold())
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .modifier(GlassCircleButtonBackground())
                }
            }
        }
    }

    private func startGame() {
        gameManager.startGame()
        showGame = true
    }
}

// MARK: - Detail Screens

// 1. Teams Detail (Cleaner UI)
private struct TeamsDetailView: View {
    @ObservedObject var gameManager: GameManager
    @Environment(\.dismiss) private var dismiss
    @State private var newTeamName = ""

    var body: some View {
        ZStack {
            TimesUpStyle.backgroundGradient.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Custom Header (scrolls with content like in Bet Buddy)
                    HStack {
                        Button { dismiss() } label: {
                            Image(systemName: "chevron.left")
                                .font(.title2.bold())
                                .foregroundStyle(.white)
                                .frame(width: 44, height: 44)
                                .modifier(GlassCircleButtonBackground())
                        }
                        Spacer()
                        Text("Teams")
                            .font(.title2.bold())
                            .foregroundStyle(.white)
                        Spacer()
                        Color.clear.frame(width: 44)
                    }
                    .padding(.top, 10)

                    VStack(spacing: 16) {
                        // Input Field
                        HStack(spacing: 12) {
                            TextField("", text: $newTeamName, prompt: Text(LocalizedStringKey("Teamname...")).foregroundStyle(.gray))
                                .padding()
                                .background(Color.white.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .foregroundStyle(.white)
                                .onSubmit(addTeamIfPossible)

                            Button(action: addTeamIfPossible) {
                                Image(systemName: "plus")
                                    .font(.title2.bold())
                                    .foregroundStyle(.white)
                                    .frame(width: 50, height: 50)
                                    .background(newTeamName.trimmingCharacters(in: .whitespaces).isEmpty ? Color.gray.opacity(0.3) : Color.blue)
                                    .clipShape(Circle())
                            }
                            .disabled(newTeamName.trimmingCharacters(in: .whitespaces).isEmpty)
                        }
                        
                        if gameManager.gameState.settings.teams.count < 2 {
                            HStack(spacing: 6) {
                                Spacer()
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.orange)
                                Text(LocalizedStringKey("Mindestens 2 Teams erforderlich"))
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                                Spacer()
                            }
                        }

                        // Team List (directly in the main scroll view)
                        VStack(spacing: 12) {
                            ForEach(gameManager.gameState.settings.teams) { team in
                                HStack {
                                    Circle()
                                        .fill(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                                        .frame(width: 40, height: 40)
                                        .overlay(
                                            Text(String(team.name.prefix(1)))
                                                .font(.headline.bold())
                                                .foregroundStyle(.white)
                                        )

                                    Text(team.name)
                                        .font(.body.weight(.medium))
                                        .foregroundStyle(.white)
                                        .padding(.leading, 8)

                                    Spacer()

                                    Button {
                                        withAnimation {
                                            gameManager.removeTeam(team)
                                        }
                                    } label: {
                                        Image(systemName: "trash")
                                            .foregroundStyle(.red.opacity(0.8))
                                            .padding(8)
                                    }
                                }
                                .padding()
                                .background(Color.white.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 18))
                                .scrollTransition { content, phase in
                                    content
                                        .opacity(phase.isIdentity ? 1 : 0.6)
                                        .offset(y: phase.isIdentity ? 0 : 12)
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, TimesUpStyle.horizontalPadding)
            .padding(.bottom, 40) // Bottom padding for scroll content
        }
        .scrollDismissesKeyboard(.interactively)
        .toolbar(.hidden, for: .navigationBar)
    }

    private func addTeamIfPossible() {
        let name = newTeamName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        withAnimation {
            gameManager.addTeam(name: name)
        }
        newTeamName = ""
    }
}

// 2. Categories Detail (BetBuddy Style)
private struct CategoriesDetailView: View {
    @ObservedObject var gameManager: GameManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            TimesUpStyle.backgroundGradient.ignoresSafeArea()

            VStack(spacing: 20) {
                // Header
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .font(.title2.bold())
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .modifier(GlassCircleButtonBackground())
                    }
                    Spacer()
                    Text(LocalizedStringKey("Kategorien"))
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                    Spacer()
                    Text("\(gameManager.gameState.settings.selectedCategories.count)")
                        .font(.headline)
                        .foregroundStyle(.blue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.2))
                        .clipShape(Capsule())
                }
                .padding(.horizontal, TimesUpStyle.horizontalPadding)
                .padding(.top, 10)

                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(gameManager.availableCategories) { category in
                            TimesUpCategoryRowView(
                                category: category,
                                isSelected: gameManager.gameState.settings.selectedCategories.contains(category)
                            )
                            .onTapGesture {
                                TimesUpHaptics.impact(.light)
                                gameManager.toggleCategory(category)
                            }
                        }
                    }
                    .padding(.horizontal, TimesUpStyle.horizontalPadding)
                    .padding(.bottom, 40)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}

private struct TimesUpCategoryRowView: View {
    let category: TimesUpCategory
    let isSelected: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            // Icon Box
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        LinearGradient(
                            colors: [category.type.color.opacity(0.3), category.type.color.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)
                
                Image(systemName: category.type.systemImage)
                    .font(.title3.bold())
                    .foregroundStyle(category.type.color)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(LocalizedStringKey(category.name))
                    .foregroundStyle(.white)
                    .font(.headline)
                
                Text(LocalizedStringKey(category.type.rawValue))
                    .foregroundStyle(TimesUpStyle.mutedText)
                    .font(.caption)
            }

            Spacer()

            // Selection Indicator
            ZStack {
                if isSelected {
                    Circle()
                        .fill(category.type.color)
                        .frame(width: 24, height: 24)
                        .overlay(
                            Image(systemName: "checkmark")
                                .font(.caption.bold())
                                .foregroundStyle(.black) // Black check on neon color looks punchy
                        )
                        .shadow(color: category.type.color.opacity(0.6), radius: 6, x: 0, y: 0) // Glow effect
                } else {
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 2)
                        .frame(width: 24, height: 24)
                }
            }
        }
        .padding()
        .background(
            ZStack {
                if isSelected {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(category.type.color.opacity(0.15)) // Subtle colored background
                } else {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.black.opacity(0.3))
                }
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    isSelected ? category.type.color.opacity(0.6) : Color.white.opacity(0.05),
                    lineWidth: isSelected ? 1.5 : 1
                )
        )
        .shadow(color: isSelected ? category.type.color.opacity(0.15) : .clear, radius: 10, x: 0, y: 4)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .scaleEffect(isSelected ? 1.02 : 1.0) // Slight pop when selected
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
    }
}

// 3. Time & Words Sheet (Clean)
private struct TimeAndWordsSheetView: View {
    @ObservedObject var gameManager: GameManager
    @Environment(\.dismiss) private var dismiss

    var wordCountRange: ClosedRange<Double> {
        let minVal = Double(gameManager.gameState.settings.minWordCount)
        let maxVal = max(minVal + 1, Double(gameManager.gameState.settings.maxWordCount))
        return minVal...maxVal
    }

    var body: some View {
        ZStack {
            // Sheet background
            Color(red: 0.1, green: 0.1, blue: 0.15).ignoresSafeArea()
            
            VStack(spacing: 10) {
                Capsule()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 40, height: 5)
                    .padding(.top, 10)
                
                Text("Zeit & Wörter")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                
                // Time Slider
                VStack(alignment: .leading, spacing: 15) {
                    HStack {
                        Label("Zeit pro Zug", systemImage: "timer")
                            .font(.headline)
                            .foregroundStyle(.white)
                        Spacer()
                        Text("\(Int(gameManager.gameState.settings.turnTimeLimit)) s")
                            .font(.title3.bold())
                            .foregroundStyle(.blue)
                    }
                    
                    Slider(
                        value: Binding(
                            get: { gameManager.gameState.settings.turnTimeLimit },
                            set: { gameManager.gameState.settings.turnTimeLimit = $0 }
                        ),
                        in: 10...120,
                        step: 5
                    )
                    .tint(.blue)
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 18))
                
                // Words Slider
                VStack(alignment: .leading, spacing: 15) {
                    HStack {
                        Label("Anzahl Wörter", systemImage: "textformat.123")
                            .font(.headline)
                            .foregroundStyle(.white)
                        Spacer()
                        Text("\(gameManager.gameState.settings.wordCount)")
                            .font(.title3.bold())
                            .foregroundStyle(.purple)
                    }
                    
                    if gameManager.gameState.settings.selectedCategories.isEmpty {
                         Text("Mindestens eine Kategorie auswählen")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    } else {
                        Slider(
                            value: Binding(
                                get: { Double(gameManager.gameState.settings.wordCount) },
                                set: { gameManager.gameState.settings.wordCount = Int($0) }
                            ),
                            in: wordCountRange,
                            step: 1
                        )
                        .tint(.purple)
                        
                        HStack {
                            HStack(spacing: 4) {
                                Text("Min:")
                                Text("\(gameManager.gameState.settings.minWordCount)")
                            }
                            Spacer()
                            HStack(spacing: 4) {
                                Text("Verfügbar:")
                                Text("\(gameManager.gameState.settings.availableWordCount)")
                            }
                        }
                        .font(.caption)
                        .foregroundStyle(.gray)
                    }
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 18))
                
                Spacer()
                
                Button {
                    dismiss()
                } label: {
                    Text("Weiter")
                        .font(.headline.bold())
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.bottom, 20)
            }
            .padding(.horizontal, 24)
        }
    }
}

private struct TimesUpDifficultySheet: View {
    let selected: Difficulty
    let onSelect: (Difficulty) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            TimesUpStyle.backgroundGradient.ignoresSafeArea()

            VStack(spacing: 0) {
                TimesUpSelectionSheetHeader(
                    icon: "gauge.medium",
                    title: "SCHWIERIGKEIT",
                    tint: .orange
                )

                Text("Wähle, wie streng Fehler und Skips behandelt werden")
                    .font(.subheadline)
                    .foregroundStyle(TimesUpStyle.mutedText)
                    .padding(.top, 8)

                VStack(spacing: 10) {
                    ForEach(Difficulty.allCases, id: \.self) { difficulty in
                        let isSelected = selected == difficulty

                        Button {
                            TimesUpHaptics.impact(.light)
                            onSelect(difficulty)
                            dismiss()
                        } label: {
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(isSelected ? difficultyColor(difficulty).opacity(0.2) : Color.white.opacity(0.06))
                                        .frame(width: 40, height: 40)

                                    Text(difficultyEmoji(difficulty))
                                        .font(.system(size: 18))
                                }

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(LocalizedStringKey(difficulty.rawValue))
                                        .font(.body.weight(.semibold))
                                        .foregroundStyle(.white)
                                    Text(LocalizedStringKey(difficultyDescription(difficulty)))
                                        .font(.caption)
                                        .foregroundStyle(isSelected ? difficultyColor(difficulty).opacity(0.95) : TimesUpStyle.mutedText)
                                        .multilineTextAlignment(.leading)
                                }

                                Spacer()

                                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                    .font(.title3)
                                    .foregroundStyle(isSelected ? difficultyColor(difficulty) : Color.white.opacity(0.25))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(isSelected ? difficultyColor(difficulty).opacity(0.12) : Color.black.opacity(0.35))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(isSelected ? difficultyColor(difficulty).opacity(0.45) : Color.white.opacity(0.08), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 16)

                Spacer()
            }
        }
    }

    private func difficultyDescription(_ difficulty: Difficulty) -> String {
        switch difficulty {
        case .easy:
            return "Entspannt. Fehler kosten keine zusätzlichen Punkte."
        case .medium:
            return "Ausgewogen. Fehler bremsen stärker."
        case .hard:
            return "Hart. Für riskante Runden mit mehr Druck."
        }
    }

    private func difficultyEmoji(_ difficulty: Difficulty) -> String {
        switch difficulty {
        case .easy:
            return "🙂"
        case .medium:
            return "⚡"
        case .hard:
            return "🔥"
        }
    }

    private func difficultyColor(_ difficulty: Difficulty) -> Color {
        switch difficulty {
        case .easy:
            return .green
        case .medium:
            return .orange
        case .hard:
            return .red
        }
    }
}

private struct TimesUpGameModeSheet: View {
    let selected: TimesUpGameMode
    let onSelect: (TimesUpGameMode) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            TimesUpStyle.backgroundGradient.ignoresSafeArea()

            VStack(spacing: 0) {
                TimesUpSelectionSheetHeader(
                    icon: "gamecontroller.fill",
                    title: "SPIELMODUS",
                    tint: .blue
                )

                Text("Wähle, wie eure Runden aufgebaut sind")
                    .font(.subheadline)
                    .foregroundStyle(TimesUpStyle.mutedText)
                    .padding(.top, 8)

                VStack(spacing: 10) {
                    ForEach(TimesUpGameMode.allCases, id: \.self) { mode in
                        let isSelected = selected == mode

                        Button {
                            TimesUpHaptics.impact(.light)
                            onSelect(mode)
                            dismiss()
                        } label: {
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(isSelected ? modeColor(mode).opacity(0.2) : Color.white.opacity(0.06))
                                        .frame(width: 40, height: 40)

                                    Image(systemName: modeIcon(mode))
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundStyle(isSelected ? modeColor(mode) : Color.white.opacity(0.8))
                                }

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(LocalizedStringKey(mode.rawValue))
                                        .font(.body.weight(.semibold))
                                        .foregroundStyle(.white)
                                    Text(LocalizedStringKey(mode.description))
                                        .font(.caption)
                                        .foregroundStyle(isSelected ? modeColor(mode).opacity(0.95) : TimesUpStyle.mutedText)
                                        .multilineTextAlignment(.leading)
                                }

                                Spacer()

                                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                    .font(.title3)
                                    .foregroundStyle(isSelected ? modeColor(mode) : Color.white.opacity(0.25))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(isSelected ? modeColor(mode).opacity(0.12) : Color.black.opacity(0.35))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(isSelected ? modeColor(mode).opacity(0.45) : Color.white.opacity(0.08), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 16)

                Spacer()
            }
        }
    }

    private func modeIcon(_ mode: TimesUpGameMode) -> String {
        switch mode {
        case .classic:
            return "list.number"
        case .withDrawing:
            return "pencil.and.outline"
        case .randomOrder:
            return "shuffle"
        }
    }

    private func modeColor(_ mode: TimesUpGameMode) -> Color {
        switch mode {
        case .classic:
            return .blue
        case .withDrawing:
            return .purple
        case .randomOrder:
            return .mint
        }
    }
}

private struct TimesUpSelectionSheetHeader: View {
    let icon: String
    let title: String
    let tint: Color

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.headline.bold())
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
            }

            Spacer()

            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(tint)
                Text(LocalizedStringKey(title))
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
                    .tracking(2)
            }

            Spacer()

            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal)
        .padding(.top, 20)
    }
}

// 4. Perks Detail (Beautified)
private struct PerkSettingsDetailView: View {
    @ObservedObject var gameManager: GameManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            TimesUpStyle.backgroundGradient.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .font(.title2.bold())
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .modifier(GlassCircleButtonBackground())
                    }
                    Spacer()
                    Text(LocalizedStringKey("Perks"))
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                    Spacer()
                    
                    Toggle("", isOn: $gameManager.gameState.settings.perksEnabled)
                        .labelsHidden()
                        .toggleStyle(SwitchToggleStyle(tint: .green))
                }
                .padding(.horizontal, TimesUpStyle.horizontalPadding)
                .padding(.top, 10)
                .padding(.bottom, 20)

                ScrollView {
                    VStack(spacing: 24) {
                        
                        if !gameManager.gameState.settings.perksEnabled {
                            VStack(spacing: 20) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 60))
                                    .foregroundStyle(.gray)
                                Text(LocalizedStringKey("Perks sind deaktiviert"))
                                    .font(.headline)
                                    .foregroundStyle(.gray)
                                Text(LocalizedStringKey("Aktiviere sie oben rechts, um Power-Ups ins Spiel zu bringen."))
                                    .font(.caption)
                                    .foregroundStyle(.gray.opacity(0.7))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                            .padding(.top, 60)
                        } else {
                            // Party Mode Toggle Card
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(LocalizedStringKey("Party Modus"))
                                        .font(.headline.bold())
                                        .foregroundStyle(.white)
                                    Text(LocalizedStringKey("Häufigere Perks bei 3/6/9 Treffern"))
                                        .font(.caption)
                                        .foregroundStyle(.gray)
                                }
                                Spacer()
                                Toggle("", isOn: $gameManager.gameState.settings.perkPartyMode)
                                    .labelsHidden()
                                    .toggleStyle(SwitchToggleStyle(tint: .purple))
                            }
                            .padding()
                            .background(Color.white.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                            
                            // Perk Packs List
                            VStack(spacing: 16) {
                                Text(LocalizedStringKey("Verfügbare Pakete"))
                                    .font(.headline)
                                    .foregroundStyle(.white.opacity(0.8))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                ForEach(PerkPack.allCases) { pack in
                                    PerkPackCard(
                                        pack: pack,
                                        isSelected: gameManager.gameState.settings.selectedPerkPacks.contains(pack),
                                        onTap: { toggle(pack) }
                                    )
                                }
                            }
                            
                            // Custom Selection Area
                            if gameManager.gameState.settings.selectedPerkPacks.contains(.custom) {
                                CustomPerkSelectionView(gameManager: gameManager)
                            }
                        }
                    }
                    .padding(.horizontal, TimesUpStyle.horizontalPadding)
                    .padding(.bottom, 40)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private func toggle(_ pack: PerkPack) {
        TimesUpHaptics.impact(.light)
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

private struct PerkPackCard: View {
    let pack: PerkPack
    let isSelected: Bool
    let onTap: () -> Void
    
    // Gradient helper based on pack
    var packGradient: LinearGradient {
        switch pack {
        case .tempo:
            return LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .score:
            return LinearGradient(colors: [.green, .yellow], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .sabotage:
            return LinearGradient(colors: [.pink, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .custom:
            return LinearGradient(colors: [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Icon Box
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(packGradient.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: pack.iconName)
                        .font(.title2)
                        .foregroundStyle(packGradient)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(LocalizedStringKey(pack.title))
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text(LocalizedStringKey(pack.subtitle))
                        .font(.caption)
                        .foregroundStyle(.gray)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                }
                
                Spacer()
                
                // Checkbox
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.clear : Color.white.opacity(0.3), lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(packGradient)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.black.opacity(0.3))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(isSelected ? packGradient : LinearGradient(colors: [.white.opacity(0.1)], startPoint: .top, endPoint: .bottom), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isSelected)
    }
}

private struct CustomPerkSelectionView: View {
    @ObservedObject var gameManager: GameManager
    @State private var expandedPacks: Set<String> = [] // Using ID string for ease

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(LocalizedStringKey("Individuelle Perks wählen"))
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.top, 10)
            
            ForEach(PerkPack.standardCases) { pack in
                VStack(spacing: 0) {
                    Button {
                        withAnimation {
                            if expandedPacks.contains(pack.id) {
                                expandedPacks.remove(pack.id)
                            } else {
                                expandedPacks.insert(pack.id)
                            }
                        }
                    } label: {
                        HStack {
                            Text(LocalizedStringKey(pack.title))
                                .font(.subheadline.bold())
                                .foregroundStyle(.white)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .rotationEffect(.degrees(expandedPacks.contains(pack.id) ? 90 : 0))
                                .foregroundStyle(.gray)
                        }
                        .padding()
                        .background(Color.white.opacity(0.05))
                    }
                    
                    if expandedPacks.contains(pack.id) {
                        VStack(spacing: 0) {
                            ForEach(pack.associatedPerks, id: \.self) { perk in
                                Toggle(isOn: binding(for: perk)) {
                                    Text(LocalizedStringKey(perk.displayName))
                                        .font(.subheadline)
                                        .foregroundStyle(.white.opacity(0.9))
                                }
                                .toggleStyle(SwitchToggleStyle(tint: .purple))
                                .padding(.horizontal)
                                .padding(.vertical, 12)
                                
                                Divider().background(Color.white.opacity(0.1))
                            }
                        }
                        .background(Color.black.opacity(0.2))
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
            }
        }
    }

    private func binding(for perk: PerkType) -> Binding<Bool> {
        Binding(
            get: { gameManager.gameState.settings.customPerks.contains(perk) },
            set: { enabled in
                gameManager.gameState.settings.setCustomPerk(perk, enabled: enabled)
            }
        )
    }
}

// MARK: - Placeholders

struct TimesUpLeaderboardView: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        ZStack {
            TimesUpStyle.backgroundGradient.ignoresSafeArea()
            VStack {
                Text("Leaderboard")
                    .font(.largeTitle)
                    .foregroundStyle(.white)
                Button("Close") { dismiss() }
            }
        }
    }
}

struct TimesUpInfoSheet: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        ZStack {
            TimesUpStyle.backgroundGradient.ignoresSafeArea()
            VStack(spacing: 20) {
                Text("Info")
                    .font(.largeTitle)
                    .foregroundStyle(.white)
                Button("Close") { dismiss() }
            }
        }
    }
}

#Preview {
    SettingsView(categoryManager: CategoryManager())
}
