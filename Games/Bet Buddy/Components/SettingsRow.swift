import SwiftUI

struct SettingsRow: View {
    enum RowType {
        case groups
        case categories
        case timer
        case hints
        case partyMode
        case penalty
    }

    var icon: String
    var title: String
    var detail: String?
    var rowType: RowType
    var isToggleOn: Bool = false
    var onTap: (() -> Void)?
    var onToggle: ((Bool) -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .foregroundStyle(.white)
                    .font(.headline)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .foregroundStyle(.white)
                    .font(.headline)
                
                // ÄNDERUNG: Detailtext hier ausblenden, wenn es Gruppen ODER Kategorien sind.
                // Dadurch steht der Text nur noch auf der rechten Seite.
                if let detail, !detail.isEmpty, rowType != .groups, rowType != .categories {
                    Text(detail)
                        .foregroundStyle(Theme.mutedText)
                        .font(.subheadline)
                }
            }
            Spacer()

            switch rowType {
            case .timer, .hints, .partyMode, .penalty:
                Toggle("", isOn: Binding(get: { isToggleOn }, set: { onToggle?($0) }))
                    .labelsHidden()
            default:
                HStack(spacing: 6) {
                    // Hier wird das Detail für Gruppen und Kategorien angezeigt (rechts)
                    if let detail, !detail.isEmpty {
                        Text(detail)
                            .foregroundStyle(Theme.mutedText)
                            .font(.subheadline.weight(.semibold))
                    }
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.white.opacity(0.5))
                        .font(.subheadline)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.25))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onTap?()
        }
    }
}
