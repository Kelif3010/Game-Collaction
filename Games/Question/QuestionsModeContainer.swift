import SwiftUI
import Combine

struct QuestionsModeContainer: View {
    @ObservedObject var appModel: AppModel
    @StateObject private var viewModel: QuestionsGameViewModel
    @ObservedObject private var mpc = MultipeerManager.shared

    @Environment(\.dismiss) var dismiss
    @State private var showAbortConfirmation = false
    @State private var showLeaderboardSheet = false
    @State private var showCategorySheet = false

    init(appModel: AppModel) {
        self.appModel = appModel
        _viewModel = StateObject(wrappedValue: QuestionsGameViewModel(appModel: appModel))
    }

    var body: some View {
        ZStack(alignment: .top) {
            
            // LAYER 1: CONTENT
            Group {
                switch viewModel.currentPhase {
                case .setup:
                    QuestionsSetupView(
                        appModel: appModel,
                        viewModel: viewModel,
                        onStartGame: { viewModel.startRound() }
                    )
                case .collecting:
                    QuestionsCollectingPhaseView(viewModel: viewModel)
                case .revealed:
                    QuestionsRevealedPhaseView(viewModel: viewModel)
                case .overview, .voting:
                    QuestionsOverviewPhaseView(viewModel: viewModel)
                case .finished:
                    QuestionsResultsPhaseView(viewModel: viewModel)
                }
            }
            
            // LAYER 2: HEADER (Always visible except in Setup)
            if viewModel.currentPhase != .setup {
                customHeader
            }
            
            // LAYER 3: SUDDEN DEATH OVERLAY
            if viewModel.isSuddenDeathActive {
                suddenDeathOverlay
            }
        }
        .onAppear {
            ExternalDisplayManager.shared.activeQuestionsViewModel = viewModel
        }
        .onDisappear {
            ExternalDisplayManager.shared.activeQuestionsViewModel = nil
        }
        .ignoresSafeArea(edges: .top)
        .navigationBarHidden(true)
        .alert("Spiel abbrechen?", isPresented: $showAbortConfirmation) {
            Button("Abbrechen", role: .cancel) { }
            Button("Ja", role: .destructive) { dismiss() }
        } message: { Text("Bist du dir sicher das du abbrechen willst?") }
        .alert("Kategorie ohne Fragen", isPresented: $viewModel.showEmptyCategoryAlert) {
            Button("OK", role: .cancel) { }
        } message: { Text("Diese Kategorie enthält keine Fragen.") }
        .sheet(isPresented: $showLeaderboardSheet) {
            leaderboardSheet
        }
        .sheet(isPresented: $showCategorySheet) {
            QuestionsCategorySheet(selectedCategory: $viewModel.selectedCategory)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(28)
                .presentationBackground(.clear)
                .disabled(viewModel.currentPhase != .setup)
        }
        .onChange(of: mpc.connectedPeers) { _, newPeers in
            if mpc.role == .peer && !newPeers.isEmpty {
                viewModel.sendRejoinRequestIfNeeded()
            } else if newPeers.isEmpty {
                viewModel.resetRejoinRequestState()
            }
        }
        .onChange(of: appModel.players) { _, _ in
            if mpc.role == .peer && !mpc.connectedPeers.isEmpty {
                viewModel.sendRejoinRequestIfNeeded()
            }
        }
    }
    
    private var customHeader: some View {
        HStack {
            Button(action: { showAbortConfirmation = true }) {
                Image(systemName: "chevron.left")
                    .font(.headline.bold())
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
            }
            
            Spacer()
            
            Text("Finde den Lügner")
                .font(.headline.weight(.bold))
                .foregroundColor(.white)
                .opacity(0.8)
            
            Spacer()
            
            Color.clear
                .frame(width: 36, height: 36)
        }
        .padding(.horizontal, 16)
        .padding(.top, 50)
    }
    
    private var suddenDeathOverlay: some View {
        ZStack {
            Color.black.opacity(0.95).ignoresSafeArea()
            VStack(spacing: 40) {
                Text("SUDDEN DEATH")
                    .font(.system(size: 40, weight: .black, design: .rounded))
                    .foregroundStyle(Color.red)
                    .shadow(color: .red, radius: 10)
                Text("Das Schicksal entscheidet...")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.7))
                Spacer()
                
                if viewModel.suddenDeathCandidates.count == 2 {
                    let c1 = viewModel.suddenDeathCandidates[0]
                    let c2 = viewModel.suddenDeathCandidates[1]
                    let winnerIndex = Int.random(in: 0...1)
                    let winnerID = viewModel.suddenDeathCandidates[winnerIndex]
                    let rotation = Double(5 * 360) + (winnerIndex == 0 ? 0.0 : 180.0)
                    
                    Coin3D(
                        frontText: viewModel.playerName(for: c1),
                        backText: viewModel.playerName(for: c2),
                        finalRotation: rotation,
                        onFinish: { viewModel.resolveSuddenDeath(winnerID: winnerID) }
                    )
                } else if !viewModel.suddenDeathCandidates.isEmpty {
                    let currentID = viewModel.suddenDeathCandidates[viewModel.suddenDeathHighlightIndex]
                    Text(viewModel.playerName(for: currentID))
                        .font(.system(size: 50, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .scaleEffect(1.2)
                        .transition(.identity)
                        .id(currentID)
                }
                Spacer()
            }
            .padding()
        }
        .transition(.opacity)
        .zIndex(100)
    }
    
    private var leaderboardSheet: some View {
        ZStack {
            QuestionsStyle.backgroundGradient.ignoresSafeArea()
            VStack {
                QuestionsSheetHeader(title: "Rangliste") { showLeaderboardSheet = false }
                    .padding(.horizontal, QuestionsStyle.padding)
                ScrollView {
                    QuestionsScoreboardView(appModel: appModel)
                        .padding(.top)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(28)
        .presentationBackground(.clear)
    }
}
