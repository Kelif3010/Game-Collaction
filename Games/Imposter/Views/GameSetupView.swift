//
//  GameSetupView.swift
//  Imposter
//
//  Created by Ken on 22.09.25.
//

import SwiftUI

struct GameSetupView: View {
    @EnvironmentObject var gameSettings: GameSettings
    @Environment(\.dismiss) private var dismiss
    @StateObject var gameLogic: GameLogic

    @State var showingAlert = false
    @State var alertMessage = ""
    @State private var showingSpyOptionsSheet = false

    @State private var showingGameModeSheet = false
    @State private var showingCategorySelectionSheet = false // For selecting game category
    @State private var showingCategoryManagementSheet = false // For managing categories (Folder)
    @State private var showingSettingsSheet = false // For global settings (Gear)
    @State private var showingLeaderboardSheet = false // For Leaderboard (Trophy)
    @State private var showingInfoSheet = false // For Rules (Question Mark)
    @State private var showingMultiplayerSheet = false // NEU: Multiplayer
    @State private var showingAddPlayersSheet = false
    @State private var addPlayersSheetDetent: PresentationDetent = .medium
    @State var route: SetupRoute?

    init() {
        self._gameLogic = StateObject(wrappedValue: GameLogic(gameSettings: GameSettings()))
    }

    var body: some View {
        mainView
            .modifier(GameSetupSheetsModifier(
                showingAddPlayersSheet: $showingAddPlayersSheet,
                addPlayersSheetDetent: $addPlayersSheetDetent,
                showingGameModeSheet: $showingGameModeSheet,
                showingCategorySelectionSheet: $showingCategorySelectionSheet,
                showingSpyOptionsSheet: $showingSpyOptionsSheet,
                showingMultiplayerSheet: $showingMultiplayerSheet,
                showingCategoryManagementSheet: $showingCategoryManagementSheet,
                showingLeaderboardSheet: $showingLeaderboardSheet,
                showingInfoSheet: $showingInfoSheet,
                showingSettingsSheet: $showingSettingsSheet,
                gameSettings: gameSettings
            ))
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

    private var mainView: some View {
        NavigationStack {
            mainLayout
                .navigationDestination(item: $route, destination: destinationView)
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
        .onChange(of: MultipeerManager.shared.lobbyPeers) { _, newPeers in
            if MultipeerManager.shared.role != .unknown, route == nil, gameSettings.gamePhase == .setup {
                let mpcPlayers = newPeers.map { Player(name: $0) }
                gameSettings.players = mpcPlayers
            }
        }
        .onAppear {
            gameLogic.gameSettings = gameSettings
            setupMPCListeners(gameSettings: gameSettings, route: $route)

            if !gameSettings.hasSelectedCategories {
                let fallbackCategory = gameSettings.categories.first(where: { ($0.sourceName ?? $0.name) == "Tiere" }) ?? gameSettings.categories.first
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
            startButtonInset
        }
    }

    private var mainLayout: some View {
        ZStack {
            backgroundView
            contentStack
        }
    }

    private var backgroundView: some View {
        ImposterStyle.backgroundGradient
            .ignoresSafeArea()
    }

    private var contentStack: some View {
        VStack(spacing: 0) {
            topBar
            contentScroll
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
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
            }

            Spacer()

            HStack(spacing: 12) {
                Button {
                    showingMultiplayerSheet = true
                } label: {
                    Image(systemName: "person.2.wave.2.fill")
                        .font(.headline)
                        .foregroundStyle(.cyan)
                        .frame(width: 36, height: 36)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }

                Button {
                    showingLeaderboardSheet = true
                } label: {
                    Image(systemName: "trophy.fill")
                        .font(.headline)
                        .foregroundStyle(.yellow)
                        .frame(width: 36, height: 36)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }

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

                Button {
                    showingInfoSheet = true
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
    }

    private var contentScroll: some View {
        ScrollView {
            VStack(spacing: 16) {
                setupCard
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 120)
        }
    }

    private var setupCard: some View {
        GroupedCard {
            playersRow
            impostersRow
            rolesRulesRow
            gameModeRow
            categoryRow
            durationRow
        }
    }

    private var playersRow: some View {
        RowCell(icon: "person.3.fill", title: "Spieler", value: "\(gameSettings.players.count)")
            .contentShape(Rectangle())
            .onTapGesture {
                showingAddPlayersSheet = true
            }
    }

    private var impostersRow: some View {
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
    }

    private var rolesRulesRow: some View {
        RowCell(
            icon: "theatermasks.fill",
            title: "Rollen & Regeln",
            value: "\(activeSpyOptionsCount) aktiv",
            tint: .orange
        )
        .contentShape(Rectangle())
        .onTapGesture { showingSpyOptionsSheet = true }
    }

    private var gameModeRow: some View {
        RowCell(
            icon: "gamecontroller.fill",
            title: "Spielmodus",
            value: gameSettings.gameMode.localizedTitle,
            tint: .accentColor,
            showsChevron: true
        )
        .contentShape(Rectangle())
        .onTapGesture {
            showingGameModeSheet = true
        }
    }

    private var categoryRow: some View {
        RowCell(icon: "folder.fill", title: "Kategorie", value: categoryDisplayName)
            .contentShape(Rectangle())
            .onTapGesture {
                showingCategorySelectionSheet = true
            }
    }

    private var durationRow: some View {
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

    @ViewBuilder
    private var startButtonInset: some View {
        if route == nil {
            startButtonContent
        }
    }

    private var startButtonContent: some View {
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

    @ViewBuilder
    private func destinationView(for route: SetupRoute) -> some View {
        switch route {
        case .game:
            GamePlayView()
                .environmentObject(gameLogic)
                .environmentObject(gameSettings)
        }
    }

}

private struct GameSetupSheetsModifier: ViewModifier {
    @Binding var showingAddPlayersSheet: Bool
    @Binding var addPlayersSheetDetent: PresentationDetent
    @Binding var showingGameModeSheet: Bool
    @Binding var showingCategorySelectionSheet: Bool
    @Binding var showingSpyOptionsSheet: Bool
    @Binding var showingMultiplayerSheet: Bool
    @Binding var showingCategoryManagementSheet: Bool
    @Binding var showingLeaderboardSheet: Bool
    @Binding var showingInfoSheet: Bool
    @Binding var showingSettingsSheet: Bool
    var gameSettings: GameSettings

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $showingAddPlayersSheet) {
                PlayerManagementSheet()
                .environmentObject(gameSettings)
                .presentationDetents([.medium, .large], selection: $addPlayersSheetDetent)
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(28)
                .presentationBackground(.clear)
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
            .sheet(isPresented: $showingMultiplayerSheet) {
                ImposterMultiplayerSheet()
            }
            .sheet(isPresented: $showingCategoryManagementSheet) {
                CategoriesView()
                    .environmentObject(gameSettings)
            }
            .sheet(isPresented: $showingLeaderboardSheet) {
                LeaderboardView()
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(28)
                    .presentationBackground(.clear)
            }
            .sheet(isPresented: $showingInfoSheet) {
                ImposterInfoSheet()
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(28)
                    .presentationBackground(.clear)
            }
            .sheet(isPresented: $showingSettingsSheet) {
                ImposterSettingsView()
            }
    }
}

#Preview {
    GameSetupView()
        .environmentObject(GameSettings())
}
