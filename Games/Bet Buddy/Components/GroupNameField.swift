import SwiftUI

struct GroupNameField: View {
    let group: GroupInfo
    let onChange: (String) -> Void

    @State private var text: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Zeigt z.B. "Team Blau" als Label an
            Text(LocalizedStringKey(group.color.fallbackName))
                .foregroundStyle(group.color.accent)
                .font(.subheadline.weight(.semibold))

            TextField(LocalizedStringKey(group.color.fallbackName), text: binding)
                .textInputAutocapitalization(.words)
                .disableAutocorrection(true)
                .padding()
                .background(Theme.textFieldBackground())
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Theme.cardStroke, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .onAppear {
            text = group.customName ?? ""
        }
        // FIX: Neue Syntax für onChange
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
