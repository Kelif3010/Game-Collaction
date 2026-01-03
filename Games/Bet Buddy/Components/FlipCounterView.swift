import SwiftUI

struct FlipCounterView: View {
    var value: Int
    var color: Color

    private var digits: [String] {
        let string = String(format: "%03d", max(0, value))
        return string.map { String($0) }
    }

    var body: some View {
        HStack(spacing: 12) {
            ForEach(digits, id: \.self) { digit in
                VStack {
                    Text(digit)
                        .font(.system(size: 44, weight: .heavy, design: .rounded))
                        .foregroundStyle(color)
                        .frame(width: 64, height: 70)
                        .background(Color.black.opacity(0.25))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }
}
