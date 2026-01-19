import SwiftUI

struct QuestionsResultsPhaseView: View {
    @ObservedObject var viewModel: QuestionsGameViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var revealStage: Int = 0
    @State private var stampScale: CGFloat = 3.0
    @State private var stampOpacity: Double = 0.0
    
    var body: some View {
        let evaluation = viewModel.lastRevealEvaluation
        
        // Logik: Wer wurde gewählt?
        let suspectID = evaluation?.selected.first
        let suspectName = suspectID != nil ? viewModel.playerName(for: suspectID!) : "Niemand"
        
        // Logik: War er ein Lügner?
        let liars = evaluation?.liars ?? viewModel.currentLiarIDs
        let isLiar = suspectID != nil && liars.contains(suspectID!)
        let citizensWon = evaluation?.citizensWon ?? false
        
        // Stempel-Text und Farbe
        let stampText: String
        let stampColor: Color
        
        if citizensWon {
            stampText = "ENTTARNT"
            stampColor = .green
        } else if suspectID == nil {
            stampText = "ENTKOMMEN" // Niemand gewählt
            stampColor = .red
        } else if isLiar {
            stampText = "ENTTARNT" // Sollte durch citizensWon abgedeckt sein, aber sicherheitshalber
            stampColor = .green
        } else {
            stampText = "UNSCHULDIG" // Falscher verdächtigt
            stampColor = .red
        }
        
        return ZStack {
            QuestionsTheme.gradient.ignoresSafeArea()
            
            // Phase 0: Intro (Analyse)
            if revealStage == 0 {
                VStack(spacing: 20) {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.5)
                    Text("ABGLEICH DER BIOMETRISCHEN DATEN...")
                        .font(.system(.title3, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.7))
                }
                .transition(.opacity)
            }
            
            // Phase 1: Der Verdächtige
            if revealStage >= 1 {
                VStack(spacing: 20) {
                    Text("MARKIERTE PERSON")
                        .font(.caption)
                        .foregroundStyle(Color.white.opacity(0.6))
                        .tracking(4)
                    
                    Text(LocalizedStringKey(suspectName))
                        .font(.system(size: 50, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal)
                        .padding(.vertical, 20)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(0.2), lineWidth: 2)
                        )
                }
                .transition(.opacity)
            }
            
            // Phase 2: Der Stempel (Wahrheit / Lüge)
            if revealStage >= 2 {
                Text(stampText)
                    .font(.system(size: 60, weight: .black))
                    .foregroundStyle(stampColor)
                    .padding(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(stampColor, lineWidth: 8)
                    )
                    .rotationEffect(.degrees(-15))
                    .scaleEffect(stampScale)
                    .opacity(stampOpacity)
            }
            
            // Phase 3: Details & Reset
            if revealStage >= 3 {
                VStack {
                    Spacer()
                    
                    // Aufklärung
                    if !citizensWon && !liars.isEmpty {
                        VStack(spacing: 10) {
                            Text("TATSÄCHLICHE LÜGNER:")
                                .font(.caption.bold())
                                .foregroundStyle(.red)
                            
                            ForEach(Array(liars), id: \.self) { id in
                                Text(viewModel.playerName(for: id))
                                    .font(.title3.bold())
                                    .foregroundStyle(.white)
                            }
                        }
                        .padding(20)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(12)
                    }
                    
                    Spacer().frame(height: 40)
                    
                    VStack(spacing: 16) {
                        Button {
                            viewModel.startRound()
                        } label: {
                            Text("Nächste Analyse")
                                .font(.headline)
                                .foregroundStyle(QuestionsTheme.textAccent)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                        }
                        
                        Button {
                            dismiss()
                        } label: {
                            Text("Programm beenden")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.6))
                        }
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 40)
                }
                .transition(.move(edge: .bottom))
            }
        }
        .onAppear {
            runSequence()
        }
    }
    
    private func runSequence() {
        // Step 0 -> 1: Show Suspect
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeIn(duration: 0.5)) {
                revealStage = 1
            }
        }
        
        // Step 1 -> 2: BANG!
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            revealStage = 2
            withAnimation(.spring(response: 0.3, dampingFraction: 0.4)) {
                stampScale = 1.0
                stampOpacity = 1.0
            }
            // Haptic Impact
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
        }
        
        // Step 2 -> 3: Show Menu
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            withAnimation(.easeOut(duration: 0.5)) {
                revealStage = 3
            }
        }
    }
}
