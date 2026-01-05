import SwiftUI

struct GroupCountRow: View {
    let count: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 44, height: 44)
                    Text("\(count)")
                        .foregroundStyle(.white)
                        .font(.headline.bold())
                }

                VStack(alignment: .leading, spacing: 2) {
                    (Text("\(count) ") + Text("Gruppen"))
                        .foregroundStyle(.white)
                        .font(.headline)
                    Text("je 2 Spieler")
                        .foregroundStyle(Theme.mutedText)
                        .font(.caption)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? Color.green : .white.opacity(0.3))
                    .font(.headline)
            }
            .padding()
            .background(Theme.cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadius)
                    .stroke(isSelected ? Color.white.opacity(0.2) : Theme.cardStroke, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(isSelected ? 0.4 : 0.0), radius: isSelected ? 12 : 0)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
        }
    }
}
