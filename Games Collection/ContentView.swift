import SwiftUI

struct ContentView: View {
    @StateObject private var router = AppRouter()
    @ObservedObject private var quickActionManager = QuickActionManager.shared
    private let statsManager = GlobalStatsManager.shared

    @State private var betBuddyTap      = false
    @State private var timesUpTap       = false
    @State private var questionTap      = false
    @State private var imposterTap      = false
    @State private var soundCinemaTap   = false
    @State private var falscheFaehrteTap = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                if SnowView.isCurrentlyWinter {
                    SnowView().opacity(0.6)
                }
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        PartyBannerButton(isPresented: $router.isPartyPresented)

                        CompatibleGlassEffectContainer(spacing: 20) {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 20)], spacing: 20) {
                                gameButton(tap: $betBuddyTap, gameId: "BetBuddy", presented: $router.isBetBuddyPresented) {
                                    BetBuddyGameCard()
                                }
                                gameButton(tap: $timesUpTap, gameId: "TimesUp", presented: $router.isTimesUpPresented) {
                                    MenuGameCard(
                                        title: "Time's Up",
                                        subtitle: "Erklären & Raten",
                                        icon: "hourglass",
                                        gradient: LinearGradient(colors: [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing)
                                    )
                                }
                                gameButton(tap: $questionTap, gameId: "Question", presented: $router.isQuestionGamePresented) {
                                    LugnerGameCard()
                                }
                                gameButton(tap: $imposterTap, gameId: "Imposter", presented: $router.isImposterPresented) {
                                    ImposterGameCard()
                                }
                                gameButton(tap: $soundCinemaTap, gameId: "SoundCinema", presented: $router.isSoundCinemaPresented) {
                                    SoundCinemaGameCard()
                                }
                                gameButton(tap: $falscheFaehrteTap, gameId: nil, presented: $router.isFalscheFaehrtePresented) {
                                    FalscheFaehrteGameCard()
                                }
                            }
                            .padding(.bottom, 30)
                        }
                        .padding(.horizontal)
                    }
                }
                .ignoresSafeArea(edges: .bottom)
                .navigationTitle("")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button { router.showSettings = true } label: {
                            Image(systemName: "gearshape.fill")
                                .font(.body.bold())
                                .foregroundStyle(.white.opacity(0.8))
                                .padding(8)
                                .background(.ultraThinMaterial, in: Circle())
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button { router.showRecommender = true } label: {
                            Image(systemName: "wand.and.stars")
                                .font(.body.bold())
                                .foregroundStyle(.white.opacity(0.8))
                                .padding(8)
                                .background(.ultraThinMaterial, in: Circle())
                        }
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $router.showSettings) {
            MainSettingsView().presentationBackground(.ultraThinMaterial)
        }
        .sheet(isPresented: $router.showRecommender) {
            GameRecommenderView().presentationBackground(.ultraThinMaterial)
        }
        .fullScreenCover(isPresented: $router.isBetBuddyPresented)       { BetBuddyWrapper() }
        .fullScreenCover(isPresented: $router.isQuestionGamePresented)    { QuestionGameWrapper() }
        .fullScreenCover(isPresented: $router.isImposterPresented)        { ImposterGameWrapper() }
        .fullScreenCover(isPresented: $router.isTimesUpPresented)         { TimesUpWrapper() }
        .fullScreenCover(isPresented: $router.isSoundCinemaPresented)     { SoundCinemaWrapper() }
        .fullScreenCover(isPresented: $router.isFalscheFaehrtePresented)  { FalscheFaehrteWrapper() }
        .fullScreenCover(isPresented: $router.isPartyPresented)           { PartyWrapper() }
        .onAppear { handleQuickAction() }
        .onChange(of: quickActionManager.pendingAction) { _, _ in handleQuickAction() }
    }

    private func handleQuickAction() {
        guard let action = quickActionManager.pendingAction else { return }
        router.openGame(for: action)
        quickActionManager.pendingAction = nil
    }

    @ViewBuilder
    private func gameButton<Card: View>(
        tap: Binding<Bool>,
        gameId: String?,
        presented: Binding<Bool>,
        @ViewBuilder card: () -> Card
    ) -> some View {
        Button {
            if let id = gameId { statsManager.markGameAsPlayed(id) }
            withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) { tap.wrappedValue = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                tap.wrappedValue = false
                presented.wrappedValue = true
            }
        } label: {
            card()
                .scaleEffect(tap.wrappedValue ? 0.93 : 1.0)
                .animation(.spring(response: 0.25, dampingFraction: 0.6), value: tap.wrappedValue)
        }
    }
}

#Preview {
    ContentView()
}
