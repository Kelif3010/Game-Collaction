import SwiftUI

// MARK: - Voting & Reveal Components

struct QuestionsAnswerRevealCard: View {
    let playerName: String
    let answer: QuestionsAnswer
    let isSelected: Bool
    let showSelectionBox: Bool
    let selectionEnabled: Bool
    let showGreenCheck: Bool
    let showRedX: Bool
    let shakeTrigger: CGFloat
    let isFullWidth: Bool
    let liarQuestion: String?
    let isSlowest: Bool
    
    // Voting Props
    var voteCount: Int = 0
    var canIncrement: Bool = true
    var onIncrement: (() -> Void)? = nil
    var onDecrement: (() -> Void)? = nil
    
    let onTap: () -> Void
    
    init(playerName: String, answer: QuestionsAnswer, isSelected: Bool, showSelectionBox: Bool, selectionEnabled: Bool, showGreenCheck: Bool, showRedX: Bool, shakeTrigger: CGFloat, isFullWidth: Bool, liarQuestion: String?, isSlowest: Bool = false, voteCount: Int = 0, canIncrement: Bool = true, onIncrement: (() -> Void)? = nil, onDecrement: (() -> Void)? = nil, onTap: @escaping () -> Void) {
        self.playerName = playerName
        self.answer = answer
        self.isSelected = isSelected
        self.showSelectionBox = showSelectionBox
        self.selectionEnabled = selectionEnabled
        self.showGreenCheck = showGreenCheck
        self.showRedX = showRedX
        self.shakeTrigger = shakeTrigger
        self.isFullWidth = isFullWidth
        self.liarQuestion = liarQuestion
        self.isSlowest = isSlowest
        self.voteCount = voteCount
        self.canIncrement = canIncrement
        self.onIncrement = onIncrement
        self.onDecrement = onDecrement
        self.onTap = onTap
    }

    var body: some View {
        ZStack(alignment: .top) {
            // Hintergrund (Akten-Look)
            QuestionsTerminalBackground()
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(voteCount > 0 ? Color.red.opacity(0.15) : Color.clear)
                )
                .overlay(
                    VStack(spacing: 0) {
                        // Header: Name & Zeit
                        HStack {
                            Text(LocalizedStringKey(playerName))
                                .font(.headline.weight(.bold))
                                .foregroundColor(.white)
                                .lineLimit(1)
                            
                            Spacer()
                            
                            if showGreenCheck {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.title3)
                            } else if showRedX {
                                Image(systemName: "brain.head.profile") // Liar Symbol
                                    .foregroundColor(.red)
                                    .font(.title3)
                            } else if answer.timeTaken > 0 {
                                // Subtile Zeitanzeige
                                HStack(spacing: 2) {
                                    Image(systemName: isSlowest ? "exclamationmark.circle" : "clock")
                                    Text(String(format: "%.0fs", answer.timeTaken))
                                }
                                .font(.caption2.weight(.medium))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(isSlowest ? Color.red.opacity(0.8) : Color.white.opacity(0.1))
                                .cornerRadius(4)
                                .foregroundColor(.white.opacity(isSlowest ? 1.0 : 0.7))
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .padding(.bottom, 12)

                        // Divider
                        Rectangle()
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 1)
                            .padding(.horizontal, 16)

                        // Antwort-Bereich (Zentrum)
                        VStack {
                            if let liarQuestion {
                                Text(LocalizedStringKey(liarQuestion))
                                    .font(.caption.weight(.medium))
                                    .foregroundColor(.red.opacity(0.8))
                                    .multilineTextAlignment(.center)
                                    .padding(.bottom, 4)
                            }

                            Text(answer.text)
                                .font(.system(.body, design: .serif)) // Handschrift/Akten-Look
                                .italic()
                                .foregroundColor(.white.opacity(0.95))
                                .multilineTextAlignment(.center)
                                .lineLimit(isFullWidth ? nil : 5)
                                .minimumScaleFactor(0.85)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                        .padding(16)
                        
                        // Footer: Voting Stepper (Zentriert)
                        if showSelectionBox {
                            VStack {
                                VoteStepper(
                                    count: voteCount,
                                    canIncrement: canIncrement,
                                    onIncrement: onIncrement,
                                    onDecrement: onDecrement
                                )
                            }
                            .padding(.bottom, 16)
                        } else {
                            // Platzhalter damit Layout stabil bleibt oder leer wenn nur Anzeige
                            Spacer().frame(height: 16)
                        }
                    }
                )

        }
        .frame(height: isFullWidth ? 240 : 200) // Etwas höher für besseres Layout
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(
                    voteCount > 0 ? Color.red : Color.white.opacity(0.15),
                    lineWidth: voteCount > 0 ? 3 : 1
                )
                .shadow(color: voteCount > 0 ? Color.red.opacity(0.5) : .clear, radius: 10)
        )
        .modifier(ShakeEffect(animatableData: showRedX ? shakeTrigger : 0))
        .onTapGesture { onTap() }
    }
}

struct VoteStepper: View {
    let count: Int
    let canIncrement: Bool
    let onIncrement: (() -> Void)?
    let onDecrement: (() -> Void)?
    
    var body: some View {
        HStack(spacing: 20) { // Breiteres Spacing für besseres Treffen
            Button(action: { onDecrement?() }) {
                Image(systemName: "minus")
                    .font(.system(size: 16, weight: .bold))
                    .frame(width: 40, height: 40)
                    .background(Color.white.opacity(0.1))
                    .foregroundColor(.white)
                    .clipShape(Circle())
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(count == 0)
            .opacity(count == 0 ? 0.3 : 1.0)
            
            // Zentrale Anzeige (Fingerabdruck oder Zahl)
            ZStack {
                if count > 0 {
                    Text("\(count)")
                        .font(.title2.weight(.heavy))
                        .foregroundColor(.red)
                        .transition(.scale)
                } else {
                    Image(systemName: "fingerprint")
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.3))
                }
            }
            .frame(width: 40)
            
            Button(action: { if canIncrement { onIncrement?() } }) {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .bold))
                    .frame(width: 40, height: 40)
                    .background(canIncrement ? Color.white.opacity(0.2) : Color.white.opacity(0.05))
                    .foregroundColor(canIncrement ? .white : .white.opacity(0.3))
                    .clipShape(Circle())
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(!canIncrement)
        }
        .padding(6)
        .background(Color.black.opacity(0.3))
        .clipShape(Capsule())
    }
}