import SwiftUI

struct GroupNameField: View {
    let group: GroupInfo
    let onChange: (String) -> Void

    @State private var text: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Team-Label mit Chip-Icon
            HStack(spacing: 8) {
                Circle()
                    .fill(group.color.primary)
                    .frame(width: 12, height: 12)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )

                Text(LocalizedStringKey(group.color.fallbackName))
                    .foregroundStyle(group.color.accent)
                    .font(.system(size: 14, weight: .bold))
            }

            TextField(LocalizedStringKey(group.color.fallbackName), text: binding)
                .textInputAutocapitalization(.words)
                .disableAutocorrection(true)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(BetBuddyTheme.textChampagne)
                .focused($isFocused)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black.opacity(0.4))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            isFocused
                                ? group.color.primary.opacity(0.6)
                                : BetBuddyTheme.accentGold.opacity(0.15),
                            lineWidth: isFocused ? 2 : 1
                        )
                )
                .shadow(
                    color: isFocused ? group.color.primary.opacity(0.2) : Color.clear,
                    radius: 8
                )
        }
        .onAppear {
            text = group.customName ?? ""
        }
        .onChange(of: group.customName) { _, newValue in
            text = newValue ?? ""
        }
    }

    private var binding: Binding<String> {
        Binding(
            get: { text },
            set: { newValue in
                text = newValue
                onChange(newValue)
            }
        )
    }
}

#Preview {
    ZStack {
        BetBuddyBackgroundView()
        VStack(spacing: 20) {
            GroupNameField(group: GroupInfo(color: .blue, customName: "Team Alpha")) { _ in }
            GroupNameField(group: GroupInfo(color: .red)) { _ in }
        }
        .padding()
    }
}
