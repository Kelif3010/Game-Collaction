import SwiftUI

struct ChallengeStartView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appModel: AppViewModel

    var onStart: () -> Void
    var onClose: () -> Void

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            // 1. Spacing auf 0 setzen, damit wir es manuell steuern können
            VStack(spacing: 0) {
                topBar

                // 2. ERSTER SPACER: Drückt den Inhalt nach unten
                Spacer()

                // 3. GRUPPE: Alles, was mittig sein soll, kommt in diesen VStack
                VStack(spacing: 28) {
                    VStack(spacing: 12) {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 52))
                            .foregroundStyle(Color.pink)

                        Text(appModel.currentChallenge.text)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.white)
                            .font(.title2.weight(.semibold))
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Theme.cardBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.cornerRadius)
                                    .stroke(Theme.cardStroke, lineWidth: 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
                    }
                    .padding(.horizontal, Theme.padding)

                    Button {
                        appModel.refreshChallenge()
                        HapticsService.impact(.light)
                    } label: {
                        Text("Challenge ändern")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.white.opacity(0.08))
                            .clipShape(Capsule())
                    }
                }

                // 4. ZWEITER SPACER: Drückt den Inhalt nach oben
                Spacer()

                // Unterer Bereich (Start Button)
                VStack(spacing: 12) {
                    PrimaryButton(title: "Start") {
                        HapticsService.success()
                        onStart()
                    }
                }
                .padding(.horizontal, Theme.padding)
                .padding(.bottom, 24)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            appModel.refreshChallenge()
        }
    }

    private var topBar: some View {
        HStack {
            Color.clear.frame(width: 44, height: 44)

            Text("Bet Buddy")
                .foregroundStyle(.white)
                .font(.headline)
                .frame(maxWidth: .infinity)

            Button {
                onClose()
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.headline.bold())
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(.horizontal, Theme.padding)
        .padding(.top, 12)
    }
}
