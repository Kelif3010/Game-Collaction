import SwiftUI

struct ChallengeStartView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appModel: AppViewModel

    var onStart: () -> Void
    var onClose: () -> Void
    
    // Alert State für den "Notausgang"
    @State private var showExitAlert = false

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar

                Spacer()

                VStack(spacing: 24) {
                    
                    // 1. KATEGORIE (Jetzt ganz oben)
                    VStack(spacing: 8) {
                        Text("Kategorie")
                            .font(.caption)
                            .foregroundStyle(Theme.mutedText)
                            .textCase(.uppercase)
                        
                        Text(appModel.currentChallenge.category.title)
                            .font(.headline)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.08))
                            .clipShape(Capsule())
                    }
                    
                    // 2. DIE KARTE (Bild + Text)
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
                            .shadow(color: Color.black.opacity(0.3), radius: 10, y: 5)
                    }
                    
                    // 3. CHALLENGE ÄNDERN BUTTON (Wieder da!)
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
                .padding(.horizontal, Theme.padding)

                Spacer()

                // START BUTTON
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
        // Alert Logik
        .alert("Spiel beenden?", isPresented: $showExitAlert) {
            Button("Abbrechen", role: .cancel) { }
            Button("Beenden", role: .destructive) {
                onClose()
                dismiss()
            }
        } message: {
            Text("Möchtest du das Spiel wirklich beenden?")
        }
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
                HapticsService.impact(.medium)
                showExitAlert = true
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
