import SwiftUI

struct GroupSelectionView: View {
    @EnvironmentObject private var appModel: AppViewModel
    var onContinue: () -> Void

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    ScreenHeader(title: "Gruppen", showBack: true)

                    VStack(spacing: 12) {
                        ForEach([2, 3, 4], id: \.self) { count in
                            GroupCountRow(
                                count: count,
                                isSelected: appModel.selectedGroupCount == count,
                                action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        appModel.setGroupCount(count)
                                    }
                                    HapticsService.impact(.light)
                                }
                            )
                        }
                    }


                    if !appModel.activeGroups.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Gruppennamen")
                                .foregroundStyle(.white)
                                .font(.headline)

                            ForEach(appModel.activeGroups) { group in
                                GroupNameField(group: group) { newName in
                                    appModel.updateName(newName, for: group.color)
                                }
                            }
                        }
                        .padding(.top, 4)
                    }

                    Spacer(minLength: 10)

                    PrimaryButton(title: "Weiter") {
                        HapticsService.impact(.medium)
                        onContinue()
                    }
                }
                .padding(Theme.padding)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}
