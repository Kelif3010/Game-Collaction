import SwiftUI

struct CategorySelectionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var gameSettings: GameSettings

    private var isRolesLocked: Bool {
        gameSettings.gameMode == .roles
    }

    private var hasMultipleSelections: Bool {
        gameSettings.selectedCategoryIds.count > 1
    }

    private func toggleMixSelection() {
        if isRolesLocked {
            return
        }

        if gameSettings.isMixAllCategories {
            gameSettings.isMixAllCategories = false
        } else {
            gameSettings.isMixAllCategories = true
            gameSettings.selectedCategoryIds.removeAll()
            gameSettings.selectedCategory = nil
        }
        enforceRolesRuleIfNeeded()
    }

    private func toggleCategory(_ category: Category) {
        let isRolesCategory = isRolesCategory(category)
        if isRolesLocked && !isRolesCategory {
            return
        }

        if gameSettings.isMixAllCategories {
            gameSettings.isMixAllCategories = false
        }

        if gameSettings.selectedCategoryIds.contains(category.id) {
            gameSettings.selectedCategoryIds.remove(category.id)
        } else {
            gameSettings.selectedCategoryIds.insert(category.id)
        }

        updateSelectedCategoryReference()
        enforceRolesRuleIfNeeded()
    }

    private func isRolesCategory(_ category: Category) -> Bool {
        (category.sourceName ?? category.name).lowercased() == "orte"
    }

    private func clearSelectedCategories() {
        gameSettings.selectedCategoryIds.removeAll()
        gameSettings.selectedCategory = nil
        gameSettings.isMixAllCategories = false
        enforceRolesRuleIfNeeded()
    }

    private func updateSelectedCategoryReference() {
        if gameSettings.selectedCategoryIds.count == 1, let id = gameSettings.selectedCategoryIds.first,
           let category = gameSettings.categories.first(where: { $0.id == id }) {
            gameSettings.selectedCategory = category
        } else {
            gameSettings.selectedCategory = nil
        }
    }

    private func enforceRolesRuleIfNeeded() {
        if gameSettings.gameMode == .roles && !gameSettings.isRolesCategorySelected {
            gameSettings.gameMode = .classic
        }
    }

    var body: some View {
        ZStack {
            ImposterStyle.backgroundGradient.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    ImposterSheetHeader(title: "Kategorien") {
                        dismiss()
                    }

                    if isRolesLocked {
                        HStack(spacing: 12) {
                            ImposterIconBadge(systemName: "lock.fill", tint: .orange)
                            Text("Rollen-Modus erlaubt nur die Kategorie \"Orte\".")
                                .font(.subheadline)
                                .foregroundStyle(ImposterStyle.mutedText)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer()
                        }
                        .imposterRowStyle()
                    }

                    if hasMultipleSelections {
                        Button {
                            clearSelectedCategories()
                        } label: {
                            HStack(spacing: 12) {
                                ImposterIconBadge(systemName: "xmark.circle.fill", tint: .red)
                                Text("Alles abwählen")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                Spacer()
                            }
                            .imposterRowStyle()
                        }
                        .buttonStyle(.plain)
                    }

                    VStack(spacing: 12) {
                        Button {
                            toggleMixSelection()
                        } label: {
                            CategorySelectionRow(
                                name: "Mix",
                                emoji: "🔀",
                                detail: "Alle Kategorien",
                                isSelected: gameSettings.isMixAllCategories,
                                isLocked: isRolesLocked,
                                isDisabled: isRolesLocked
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(isRolesLocked)

                        ForEach(gameSettings.categories) { category in
                            let isRolesCategory = isRolesCategory(category)
                            let isDisabled = isRolesLocked && !isRolesCategory
                            Button {
                                toggleCategory(category)
                            } label: {
                                CategorySelectionRow(
                                    name: category.name,
                                    emoji: category.emoji,
                                    detail: "\(category.words.count) Begriffe",
                                    isSelected: gameSettings.selectedCategoryIds.contains(category.id),
                                    isLocked: isDisabled,
                                    isDisabled: isDisabled
                                )
                            }
                            .buttonStyle(.plain)
                            .disabled(isDisabled)
                        }
                    }

                    ImposterPrimaryButton(title: "Fertig", action: { dismiss() }, isDisabled: !gameSettings.hasSelectedCategories)
                        .padding(.top, 8)
                }
                .padding(.horizontal, ImposterStyle.padding)
                .padding(.bottom, 40)
            }
        }
    }
}
