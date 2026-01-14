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
    @ObservedObject var mpc = MultipeerManager.shared

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
    
    private var isMultiplayerActive: Bool {
        mpc.role != .unknown
    }

    private func broadcastConfigIfHost() {
        guard mpc.role == .host else { return }
        guard gameSettings.gamePhase == .setup else { return }
        let config = gameSettings.toMPCConfig()
        mpc.sendToAll(event: MPCEventType.imposterSyncConfig, object: config)
    }

    private func setHostActivity(_ message: String) {
        guard mpc.role == .host else { return }
        if mpc.hostActivity == message {
            return
        }
        mpc.hostActivity = message
        let payload = ImposterHostActivityPayload(message: message)
        mpc.sendToAll(event: MPCEventType.imposterHostActivity, object: payload)
    }
    
    private struct ConfigSignature: Equatable {
        let numberOfImposters: Int
        let timeLimit: Int
        let gameMode: ImposterGameMode
        let spyCanSeeCategory: Bool
        let spiesCanSeeEachOther: Bool
        let randomSpyCount: Bool
        let showSpyHints: Bool
        let activeRoles: Set<RoleType>
        let selectedCategoryIds: Set<UUID>
        let isMixAllCategories: Bool
    }
    
    private var configSignature: ConfigSignature {
        ConfigSignature(
            numberOfImposters: gameSettings.numberOfImposters,
            timeLimit: gameSettings.timeLimit,
            gameMode: gameSettings.gameMode,
            spyCanSeeCategory: gameSettings.spyCanSeeCategory,
            spiesCanSeeEachOther: gameSettings.spiesCanSeeEachOther,
            randomSpyCount: gameSettings.randomSpyCount,
            showSpyHints: gameSettings.showSpyHints,
            activeRoles: gameSettings.activeRoles,
            selectedCategoryIds: gameSettings.selectedCategoryIds,
            isMixAllCategories: gameSettings.isMixAllCategories
        )
    }

    private struct HostSheetState: Equatable {
        let gameMode: Bool
        let categories: Bool
        let rules: Bool
    }

    private var hostSheetState: HostSheetState {
        HostSheetState(
            gameMode: showingGameModeSheet,
            categories: showingCategorySelectionSheet,
            rules: showingSpyOptionsSheet
        )
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
        applySetupBindings(to: navigationBase)
    }

    private var navigationBase: some View {
        NavigationStack {
            mainLayout
                .navigationDestination(item: $route, destination: destinationView)
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .hideNavigationBarBackgroundIfAvailable()
        .navigationBarBackButtonHidden(true)
    }

    private func applySetupBindings<Content: View>(to content: Content) -> some View {
        let step1 = AnyView(
            content
                .onChange(of: gameSettings.players.count) { _, _ in
                    gameSettings.clampNumberOfImpostersToCap()
                }
                .onChange(of: gameSettings.isRolesCategorySelected) { _, isValid in
                    if gameSettings.gameMode == .roles && !isValid {
                        gameSettings.gameMode = .classic
                    }
                }
        )

        let step2 = AnyView(
            step1.onChange(of: mpc.lobbyPeers) { _, newPeers in
                if mpc.role != .unknown, route == nil, gameSettings.gamePhase == .setup {
                    let mpcPlayers = newPeers.map { Player(name: $0) }
                    gameSettings.players = mpcPlayers
                }
                if mpc.role == .host {
                    let validPlayers = Set(newPeers)
                    let filteredReady = mpc.readyPlayers.intersection(validPlayers)
                    if filteredReady != mpc.readyPlayers {
                        mpc.readyPlayers = filteredReady
                    }
                    mpc.sendToAll(event: "LOBBY_STATE_SYNC", object: Array(filteredReady))
                    broadcastConfigIfHost()
                }
            }
        )

        let step3 = AnyView(
            step2.onChange(of: configSignature) { oldValue, newValue in
                broadcastConfigIfHost()
                if oldValue.timeLimit != newValue.timeLimit {
                    setHostActivity("Host stellt Timer ein")
                } else if oldValue.numberOfImposters != newValue.numberOfImposters {
                    setHostActivity("Host waehlt Anzahl Spione")
                }
            }
        )

        let step4 = AnyView(
            step3.onChange(of: hostSheetState) { _, newValue in
                if newValue.gameMode {
                    setHostActivity("Host ist im Spielmodus")
                } else if newValue.categories {
                    setHostActivity("Host waehlt Kategorie")
                } else if newValue.rules {
                    setHostActivity("Host aktiviert Rollen und Regeln")
                } else if mpc.role == .host {
                    setHostActivity("Host wartet auf Start")
                }
            }
        )

        let step5 = AnyView(
            step4.onAppear {
                gameLogic.gameSettings = gameSettings
                setupMPCListeners(gameSettings: gameSettings, route: $route)
                if mpc.role == .host && mpc.hostActivity.isEmpty {
                    setHostActivity("Host wartet auf Start")
                }

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
        )

        return AnyView(
            step5.safeAreaInset(edge: .bottom) {
                startButtonInset
            }
        )
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
        let valueText = isMultiplayerActive
            ? "\(gameSettings.players.count) (online)"
            : "\(gameSettings.players.count)"
        return RowCell(
            icon: "person.3.fill",
            title: "Spieler",
            value: valueText,
            showsChevron: !isMultiplayerActive
        )
            .contentShape(Rectangle())
            .onTapGesture {
                if !isMultiplayerActive {
                    showingAddPlayersSheet = true
                }
            }
            .disabled(isMultiplayerActive)
            .opacity(isMultiplayerActive ? 0.6 : 1.0)
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

private extension View {
    @ViewBuilder
    func hideNavigationBarBackgroundIfAvailable() -> some View {
        if #available(iOS 18.0, *) {
            toolbarBackgroundVisibility(.hidden, for: .navigationBar)
        } else {
            self
        }
    }
}

#Preview {
    GameSetupView()
        .environmentObject(GameSettings())
}
