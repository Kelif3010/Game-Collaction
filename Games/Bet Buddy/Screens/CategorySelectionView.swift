import SwiftUI

struct CategorySelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appModel: AppViewModel

    var onContinue: () -> Void
    var onBackToGroups: () -> Void

    var body: some View {
        ZStack {
            BetBuddyBackgroundView(intensity: 0.4)

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    ScreenHeader(title: "Kategorien") {
                        if dismissEnabled {
                            dismiss()
                        } else {
                            onBackToGroups()
                        }
                    }

                    VStack(spacing: 12) {
                        ForEach(appModel.availableCategories) { category in
                            CategoryRowView(
                                category: category,
                                isSelected: appModel.selectedCategories.contains(category)
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                appModel.toggleCategory(category)
                                HapticsService.impact(.light)
                            }
                        }
                    }

                    Spacer(minLength: 10)

                    PrimaryButton(
                        title: "Fertig",
                        action: {
                            HapticsService.impact(.medium)
                            onContinue()
                        },
                        isDisabled: appModel.selectedCategories.isEmpty
                    )
                }
                .padding(Theme.padding)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var dismissEnabled: Bool {
        // In a NavigationStack this will be true when there is a previous screen.
        true
    }
}
