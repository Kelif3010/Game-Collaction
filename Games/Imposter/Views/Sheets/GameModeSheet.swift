import SwiftUI

struct GameModeSheet: View {
    @Environment(\.dismiss) private var dismiss
    let selected: ImposterGameMode
    let gameSettings: GameSettings
    let onSelect: (ImposterGameMode) -> Void

    @State private var current: ImposterGameMode

    init(selected: ImposterGameMode, gameSettings: GameSettings, onSelect: @escaping (ImposterGameMode) -> Void) {
        self.selected = selected
        self.gameSettings = gameSettings
        self.onSelect = onSelect
        _current = State(initialValue: selected)
    }
    
    private var canUseRolesMode: Bool {
        return gameSettings.isRolesCategorySelected
    }

    var body: some View {
        ZStack {
            ImposterStyle.backgroundGradient.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    ImposterSheetHeader(title: "Spielmodus") {
                        dismiss()
                    }

                    if !canUseRolesMode {
                        HStack(spacing: 12) {
                            ImposterIconBadge(systemName: "lock.fill", tint: .orange)
                            Text("Rollen-Modus ist nur mit der Kategorie \"Orte\" verfügbar.")
                                .font(.subheadline)
                                .foregroundStyle(ImposterStyle.mutedText)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer()
                        }
                        .imposterRowStyle()
                    }

                    VStack(spacing: 12) {
                        ForEach(ImposterGameMode.allCases.filter { $0 != .questions }, id: \.self) { mode in
                            let isDisabled = mode == .roles && !canUseRolesMode
                            Button {
                                if isDisabled {
                                    return
                                }
                                current = mode
                            } label: {
                                GameModeRow(
                                    mode: mode,
                                    isSelected: current == mode,
                                    isDisabled: isDisabled
                                )
                            }
                            .buttonStyle(.plain)
                            .disabled(isDisabled)
                        }
                    }

                    ImposterPrimaryButton(
                        title: "Speichern",
                        action: {
                            onSelect(current)
                            dismiss()
                        },
                        isDisabled: current == .roles && !canUseRolesMode
                    )
                    .padding(.top, 8)
                }
                .padding(.horizontal, ImposterStyle.padding)
                .padding(.bottom, 40)
            }
        }
    }
}
