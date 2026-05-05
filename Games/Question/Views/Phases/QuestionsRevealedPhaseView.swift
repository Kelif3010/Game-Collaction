import SwiftUI

struct QuestionsRevealedPhaseView: View {
    @ObservedObject var viewModel: QuestionsGameViewModel
    @Environment(MultipeerManager.self) private var mpc
    
    var body: some View {
        ZStack {
            QuestionsBackgroundView(stressLevel: 0.35)
                .ignoresSafeArea()
            VStack(spacing: 24) {
                Color.clear.frame(height: 110)
                Spacer(minLength: 0)
                if let round = viewModel.currentRound {
                    QuestionsPromptBoard(question: round.promptPair.citizenQuestion)
                        .padding(.horizontal, 24)
                }
                Text("Los geht’s! Gleich seht ihr alle Antworten – danach diskutiert ihr die Frage oben.")
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                
                if mpc.role != .peer {
                    Button("Runde starten") {
                        viewModel.startDiscussion()
                        // Host schickt State-Sync an alle, damit Phasenwechsel auf allen Geräten passiert
                        if mpc.role == .host {
                            viewModel.syncStateToAll()
                        }
                    }
                    .buttonStyle(QuestionsPrimaryButtonStyle())
                    .padding(.horizontal, 40)
                }
                Spacer(minLength: 0)
            }
            .padding(.bottom, 32)
        }
    }
}
