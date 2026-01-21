import SwiftUI

struct QuestionsCollectingPhaseView: View {
    @ObservedObject var viewModel: QuestionsGameViewModel
    @FocusState private var isAnswerFocused: Bool
    @AppStorage("question.hint.collecting") private var collectingHintSeen = false
    @State private var hasSubmittedAnswer = false
    
    var body: some View {
        let mpcRole = MultipeerManager.shared.role
        let isMultiplayer = mpcRole != .unknown
        
        return ZStack {
            QuestionsBackgroundView(stressLevel: viewModel.showQuestionToCurrentPlayer ? 0.28 : 0.18)
                .ignoresSafeArea()
            VStack(spacing: 20) {
                Color.clear.frame(height: 110)
                Spacer(minLength: 0)

                Group {
                    if let round = viewModel.currentRound {
                        VStack(spacing: 22) {
                            
                            // Header: Name & Timer
                            VStack(spacing: 8) {
                                if isMultiplayer {
                                    Text("ANALYSE LÄUFT...")
                                        .font(.subheadline)
                                        .foregroundStyle(QuestionsStyle.mutedText)
                                        .textCase(.uppercase)
                                        .kerning(1)
                                } else {
                                    Text("PROBAND \(round.currentPlayerIndex + 1) von \(viewModel.playerCount)")
                                        .font(.subheadline)
                                        .foregroundStyle(QuestionsStyle.mutedText)
                                        .textCase(.uppercase)
                                        .kerning(1)
                                }
                                
                                if viewModel.showQuestionToCurrentPlayer {
                                    QuestionsPressureTimer(seconds: Int(viewModel.currentInputDuration))
                                } else if !isMultiplayer {
                                    Text("Bereit?")
                                        .font(.title3.bold())
                                        .foregroundStyle(.white)
                                }
                            }

                            if !viewModel.showQuestionToCurrentPlayer && !isMultiplayer {
                                // Nur im Single Device Modus zeigen wir den sicheren Reveal Button
                                if let player = viewModel.currentPlayer() {
                                    QuestionsSecureRevealButton(playerName: player.name) {
                                        viewModel.revealQuestionForCurrentPlayer()
                                    }
                                    .padding(.top, 20)
                                }
                            } else {
                                // Anzeige der Frage (Entweder aus RoundState oder aus myPrompt im Multiplayer)
                                let question = isMultiplayer ? (viewModel.myPrompt ?? "Lade...") : (viewModel.role(for: viewModel.currentPlayer()?.id ?? UUID()) == .liar ? round.promptPair.liarQuestion : round.promptPair.citizenQuestion)
                                
                                VStack(spacing: 18) {
                                    if isMultiplayer && hasSubmittedAnswer {
                                        // Warte Screen nach der Eingabe
                                        VStack(spacing: 20) {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(size: 60))
                                                .foregroundColor(.green)
                                            Text("Antwort gesendet!")
                                                .font(.headline)
                                                .foregroundColor(.white)
                                            Text("Warte auf die anderen Spieler...")
                                                .font(.subheadline)
                                                .foregroundColor(QuestionsStyle.mutedText)
                                        }
                                        .padding(40)
                                        .background(QuestionsStyle.containerBackground)
                                        .cornerRadius(20)
                                    } else {
                                        QuestionsPromptBoard(question: question)
                                        QuestionsAnswerBoard(text: $viewModel.answerText, focus: $isAnswerFocused)
                                        Button(action: { 
                                            viewModel.submitCurrentAnswer() 
                                            if isMultiplayer { hasSubmittedAnswer = true }
                                        }) {
                                            Text("Antwort speichern").font(.headline)
                                        }
                                        .buttonStyle(QuestionsPrimaryButtonStyle(disabled: !viewModel.isAnswerValid))
                                        .disabled(!viewModel.isAnswerValid)
                                    }
                                }
                            }
                        }
                        .frame(maxWidth: 520)
                        .padding(.horizontal, 24)
                    } else {
                        ProgressView("Runde wird vorbereitet…").tint(.white)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(.bottom, 32)
            if !collectingHintSeen {
                VStack {
                    QuestionsHintBanner(
                        text: "Lies deine Frage und gib deine Antwort ehrlich (oder auch nicht) ein.",
                        actionTitle: "Bereit",
                        onDismiss: { collectingHintSeen = true }
                    )
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                    Spacer()
                }
                .transition(.opacity)
            }
        }
        .onTapGesture { isAnswerFocused = false }
        .onChange(of: viewModel.currentRound?.roundIndex) { _, _ in
            hasSubmittedAnswer = false
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: viewModel.showQuestionToCurrentPlayer)
        .animation(.easeInOut(duration: 0.2), value: collectingHintSeen)
    }
}
