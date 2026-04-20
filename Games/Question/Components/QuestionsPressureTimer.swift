import SwiftUI

struct QuestionsPressureTimer: View {
    let seconds: Int
    
    var color: Color {
        if seconds < 10 { return .white }
        if seconds < 20 { return .orange }
        return .red
    }
    
    var isCritical: Bool {
        seconds >= 20
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "stopwatch.fill")
                .font(.headline)
                .symbolEffect(.pulse, options: .repeating)
            
            Text(timeString)
                .font(.system(.headline, design: .monospaced))
                .fontWeight(.bold)
                .contentTransition(.numericText())
        }
        .foregroundStyle(color)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(color.opacity(0.15))
        )
        .overlay(
            Capsule()
                .stroke(color.opacity(0.5), lineWidth: 1)
        )
        .modifier(ShakeEffect(animatableData: isCritical ? 1 : 0))
        .animation(.default, value: seconds)
    }
    
    private var timeString: String {
        let min = seconds / 60
        let sec = seconds % 60
        return String(format: "%02d:%02d", min, sec)
    }
}
