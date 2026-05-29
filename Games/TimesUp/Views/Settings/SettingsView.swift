//
//  SettingsView.swift
//  TimesUp
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.locale) private var locale
    private let categoryViewModel: TimesUpCategoryViewModel
    @StateObject private var viewModel: TimesUpGameViewModel

    @State private var path: [SettingsRoute] = []
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

    init(categoryViewModel: TimesUpCategoryViewModel) {
        self.categoryViewModel = categoryViewModel
        _viewModel = StateObject(wrappedValue: TimesUpGameViewModel(categoryViewModel: categoryViewModel))
    }

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                TimesUpStyle.backgroundGradient.ignoresSafeArea()

                VStack(spacing: 0) {
                    topBar
                        .padding(.horizontal, TimesUpStyle.horizontalPadding)
                        .padding(.top, TimesUpStyle.horizontalPadding)
                        .padding(.bottom, 20)

                    ScrollView {
                        VStack(spacing: 12) {
                            TimesUpSettingsRow(
                                icon: "person.2.fill",
                                title: "Teams",
                                detail: "\(viewModel.gameState.settings.teams.count)",
                                rowType: .teams,
                                onTap: { path.append(.teams) }
                            )

                            TimesUpSettingsRow(
                                icon: "list.bullet.rectangle.portrait.fill",
                                title: "Kategorien",
                                detail: viewModel.gameState.settings.selectedCategories.isEmpty ? "Keine" : "\(viewModel.gameState.settings.selectedCategories.count)",
                                rowType: .categories,
                                onTap: { path.append(.categories) }
                            )

                            TimesUpSettingsRow(
                                icon: "timer",
                                title: "Zeit & Wörter",
                                detail: timeWordsDetail,
                                rowType: .timeWords,
                                onTap: {
                                    TimesUpHaptics.impact(.light)
                                    showTimeWordsSheet = true
                                }
                            )

                            TimesUpSettingsRow(
                                icon: "sparkles",
                                title: "Perks",
                                detail: nil,
                                rowType: .perks,
                                isToggleOn: viewModel.gameState.settings.perksEnabled,
                                onTap: { path.append(.perks) }
                            )

                            TimesUpSettingsRow(
                                icon: "gauge.medium",
                                title: "Schwierigkeit",
                                detail: viewModel.gameState.settings.difficulty.rawValue,
                                rowType: .difficulty,
                                onTap: {
                                    TimesUpHaptics.impact(.light)
                                    showDifficultySheet = true
                                }
                            )

                            TimesUpSettingsRow(
                                icon: "gamecontroller.fill",
                                title: "Spielmodus",
                                detail: viewModel.gameState.settings.gameMode.rawValue,
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

                VStack {
                    Spacer()
                    TimesUpPrimaryButton(
                        title: "Spiel starten",
                        action: {
                            TimesUpHaptics.impact(.medium)
                            startGame()
                        },
                        isDisabled: !viewModel.canStartGame
                    )
                    .padding(.horizontal, TimesUpStyle.horizontalPadding)
                    .padding(.bottom, 32)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: SettingsRoute.self) { route in
                switch route {
                case .teams:      TeamsDetailView(viewModel: viewModel)
                case .categories: CategoriesDetailView(viewModel: viewModel)
                case .perks:      PerkSettingsDetailView(viewModel: viewModel)
                }
            }
            .sheet(isPresented: $showTimeWordsSheet) {
                TimeAndWordsSheetView(viewModel: viewModel)
                    .presentationDetents([.medium, .fraction(0.6)])
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(28)
            }
            .sheet(isPresented: $showDifficultySheet) {
                TimesUpDifficultySheet(
                    selected: viewModel.gameState.settings.difficulty
                ) { difficulty in
                    viewModel.gameState.settings.difficulty = difficulty
                }
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(28)
            }
            .sheet(isPresented: $showGameModeSheet) {
                TimesUpGameModeSheet(
                    selected: viewModel.gameState.settings.gameMode
                ) { mode in
                    viewModel.gameState.settings.gameMode = mode
                }
                .presentationDetents([.medium, .fraction(0.58)])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(28)
            }
            .fullScreenCover(isPresented: $showGame) {
                TimesUpGameView(viewModel: viewModel)
            }
            .sheet(isPresented: $showInfoSheet) {
                TimesUpInfoSheet()
            }
            .sheet(isPresented: $showLeaderboardSheet) {
                TimesUpLeaderboardView()
            }
            .sheet(isPresented: $showCategoryManagement) {
                CategoryManagementView(categoryViewModel: categoryViewModel)
            }
        }
    }

    private var timeWordsDetail: String {
        let time = Int(viewModel.gameState.settings.turnTimeLimit)
        let count = viewModel.gameState.settings.wordCount
        let wordsLabel = String(localized: "Wörter", locale: locale)
        return "\(time)s · \(count) \(wordsLabel)"
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
                    Image(systemName: "folder.fill")
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
        viewModel.startGame()
        showGame = true
    }
}

#Preview {
    SettingsView(categoryViewModel: TimesUpCategoryViewModel())
}
