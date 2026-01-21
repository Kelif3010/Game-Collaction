import SwiftUI
import UIKit

private struct AppIconOption: Identifiable {
    let id: String
    let iconName: String?          // nil = Primary Icon
    let previewImageName: String   // Asset Catalog Image Name
    let titleKey: LocalizedStringKey
    let subtitleKey: LocalizedStringKey
}

struct AppIconPickerView: View {
    @State private var currentIconName: String? = UIApplication.shared.alternateIconName
    @State private var errorMessage = ""
    @State private var showError = false

    private let options: [AppIconOption] = [
        AppIconOption(
            id: "primary",
            iconName: nil,
            previewImageName: "AppIconPreview",
            titleKey: "Default Icon",
            subtitleKey: "The classic look"
        ),
        AppIconOption(
            id: "alternate",
            iconName: "AppIconAlt",
            previewImageName: "AppIconAltPreview",
            titleKey: "Alternate Icon",
            subtitleKey: "Preview / placeholder"
        )
    ]

    private var supportsAlternateIcons: Bool {
        UIApplication.shared.supportsAlternateIcons
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.black, Color.indigo.opacity(0.5), Color.purple.opacity(0.4)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    if !supportsAlternateIcons {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                            Text(LocalizedStringKey("Alternate icons are not supported on this device."))
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.7))
                        }
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }

                    #if targetEnvironment(simulator)
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundStyle(.blue)
                        Text("Im Simulator funktioniert das Icon-Wechseln möglicherweise nicht korrekt.")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    #endif

                    ForEach(options) { option in
                        Button {
                            setIcon(option.iconName)
                        } label: {
                            HStack(spacing: 16) {
                                // Echtes Icon-Preview
                                Image(option.previewImageName)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 60, height: 60)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                    )
                                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(option.titleKey)
                                        .font(.headline)
                                        .foregroundStyle(.white)

                                    Text(option.subtitleKey)
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.6))
                                }

                                Spacer()

                                if currentIconName == option.iconName {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.title2)
                                        .foregroundStyle(.green)
                                }
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(currentIconName == option.iconName
                                          ? Color.white.opacity(0.15)
                                          : Color.white.opacity(0.08))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(currentIconName == option.iconName
                                            ? Color.green.opacity(0.5)
                                            : Color.clear, lineWidth: 2)
                            )
                        }
                        .disabled(!supportsAlternateIcons)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 12)
            }
        }
        .navigationTitle(LocalizedStringKey("App Icons"))
        .navigationBarTitleDisplayMode(.inline)
        .alert(LocalizedStringKey("App Icon"), isPresented: $showError) {
            Button(LocalizedStringKey("OK")) { }
        } message: {
            Text(errorMessage)
        }
    }

    private func setIcon(_ iconName: String?) {
        guard supportsAlternateIcons else { return }
        guard UIApplication.shared.alternateIconName != iconName else { return }

        // Haptisches Feedback
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        UIApplication.shared.setAlternateIconName(iconName) { error in
            DispatchQueue.main.async {
                if let error = error {
                    errorMessage = error.localizedDescription
                    showError = true
                    // Fehler-Haptik
                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                } else {
                    // Erfolgs-Haptik
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
                currentIconName = UIApplication.shared.alternateIconName
            }
        }
    }
}

#Preview {
    NavigationStack {
        AppIconPickerView()
    }
}
