import SwiftUI

enum AppRoute: Hashable {
    case categories
    case challengeStart
    case voting
    case groupSelection
    case game
    case result(GameResult)
}

struct BetBuddyRootView: View {
    // WICHTIG: Wir bekommen das Model vom Wrapper (kein @StateObject hier!)
    let viewModel: AppViewModel
    
    // WICHTIG: Wir nutzen ein echtes Array [AppRoute], damit die Navigation nicht hängt
    @State private var path: [AppRoute] = []

    var body: some View {
        NavigationStack(path: $path) {
            HomeView(
                onSelectGroups: { path.append(.groupSelection) },
                onSelectCategories: { path.append(.categories) },
                onStart: { path.append(.challengeStart) }
            )
            // WICHTIG: Der Destination-Modifier muss INNEN an der View hängen
            .navigationDestination(for: AppRoute.self) { route in
                Group {
                    switch route {
                    case .groupSelection:
                        GroupSelectionView {
                            path.append(.categories)
                        }
                    case .categories:
                        CategorySelectionView(
                            onContinue: {
                                // VORHER: path.append(.challengeStart)
                                // NEU: Alles schließen und zur HomeView
                                path = []
                            },
                            onBackToGroups: {
                                // Das kann so bleiben oder auf path.removeLast() geändert werden,
                                // falls der "Zurück"-Pfeil oben links komisch reagiert.
                                path = []
                            }
                        )
                    case .challengeStart:
                        ChallengeStartView(
                            onStart: { path.append(.voting) },
                            onClose: { path = [] }
                        )
                    case .voting:
                        BetBuddyVotingView(
                            onClose: { path = [] },
                            onConfirm: { path.append(.game) }
                        )
                    case .game:
                        GameView(
                            onWin: { result in path.append(.result(result)) },
                            onLose: { result in path.append(.result(result)) }
                        )
                    case .result(let result):
                        ResultView(
                            result: result,
                            onRestart: { path = [] },
                            onNewChallenge: {
                                path = [.challengeStart] // Reset & Sprung
                            }
                        )
                    }
                }
                // WICHTIG: Hier impfen wir jede Unterseite mit dem ViewModel
                .environmentObject(viewModel)
            }
            .background(Theme.background.ignoresSafeArea())
        }
        // Auch die HomeView braucht das Model
        .environmentObject(viewModel)
    }
}

#Preview {
    BetBuddyRootView(viewModel: AppViewModel())
}
