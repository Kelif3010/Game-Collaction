import SwiftUI

struct QuestionsModeContainer: View {
    @ObservedObject var appModel: AppModel

    @StateObject private var viewModel: QuestionsGameViewModel

    @Environment(\.dismiss) private var dismiss
    @State private var showAbortConfirmation = false
    @State private var showEmptyCategoryAlert = false

    init(appModel: AppModel) {
        self.appModel = appModel
        _viewModel = StateObject(wrappedValue: QuestionsGameViewModel(appModel: appModel, engine: QuestionsEngine()))
    }

    var body: some View {
        ZStack(alignment: .top) {
            content

            if viewModel.currentPhase != .setup {
                header
            }
        }
        .ignoresSafeArea(edges: .top)
        .navigationBarHidden(true)
        .alert("Test abbrechen?", isPresented: $showAbortConfirmation) {
            Button("Abbrechen", role: .cancel) { }
            Button("Ja", role: .destructive) { dismiss() }
        } message: {
            Text("Bist du sicher, dass du den Test abbrechen willst?")
        }
        .alert("Akte ohne Fragen", isPresented: $showEmptyCategoryAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Diese Akte enthält keine Fragen.")
        }
        .onAppear(perform: attachTVBoard)
        .onDisappear(perform: detachTVBoard)
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.currentPhase {
        case .setup:
            QuestionsSetupView(
                appModel: appModel,
                selectedCategory: $viewModel.selectedCategory,
                numberOfLiars: $viewModel.numberOfLiars,
                discussionTime: $viewModel.discussionTime,
                onStartGame: startRound
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

    private var header: some View {
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

            Text("Lügendetektor-Test")
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

    private func startRound() {
        guard let category = viewModel.selectedCategory else { return }
        guard !category.promptPairs.isEmpty else {
            showEmptyCategoryAlert = true
            return
        }
        viewModel.startRound()
        viewModel.syncStateToAll()
    }

    private func attachTVBoard() {
        ExternalDisplayManager.shared.activeQuestionsViewModel = viewModel
    }

    private func detachTVBoard() {
        if ExternalDisplayManager.shared.activeQuestionsViewModel === viewModel {
            ExternalDisplayManager.shared.activeQuestionsViewModel = nil
        }
    }
}
