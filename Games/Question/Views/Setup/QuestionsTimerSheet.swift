import SwiftUI

struct QuestionsTimerSheet: View {
    @Binding var discussionTime: TimeInterval
    @Environment(\.dismiss) var dismiss
    
    // Range: 30 Sekunden bis 5 Minuten (300 Sekunden)
    private let timeRange: ClosedRange<Double> = 30...300
    private let step: Double = 30
    
    var body: some View {
        ZStack {
            QuestionsStyle.backgroundGradient.ignoresSafeArea()
            
            VStack(spacing: 30) {
                QuestionsSheetHeader(title: "Diskussionszeit") {
                    dismiss()
                }
                .padding(.horizontal, QuestionsStyle.padding)
                
                Spacer()
                
                // Große Anzeige
                VStack(spacing: 10) {
                    Image(systemName: "timer")
                        .font(.system(size: 60))
                        .foregroundStyle(discussionTime == 0 ? .gray : .green)
                    
                    Text(formatTime(discussionTime))
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .contentTransition(.numericText())
                }
                
                // Slider Control
                VStack(spacing: 20) {
                    Slider(
                        value: Binding(
                            get: { discussionTime == 0 ? 0 : discussionTime },
                            set: { newVal in
                                if newVal < 30 {
                                    discussionTime = 0 // Unbegrenzt
                                } else {
                                    discussionTime = newVal
                                }
                            }
                        ),
                        in: 0...300,
                        step: step
                    )
                    .tint(discussionTime == 0 ? .gray : .green)
                    
                    HStack {
                        Text("Unbegrenzt")
                        Spacer()
                        Text("5 Min")
                    }
                    .font(.caption)
                    .foregroundStyle(QuestionsStyle.mutedText)
                }
                .padding(.horizontal, 40)
                
                Spacer()
                
                QuestionsPrimaryButton(title: "Übernehmen") {
                    dismiss()
                }
                .padding(.horizontal, QuestionsStyle.padding)
                .padding(.bottom, 20)
            }
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        if time == 0 { return "∞" }
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        if seconds == 0 {
            return "\(minutes) Min"
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}