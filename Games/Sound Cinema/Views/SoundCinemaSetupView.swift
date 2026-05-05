import SwiftUI

struct SoundCinemaSetupView: View {
    @EnvironmentObject private var viewModel: SoundCinemaViewModel
    @Environment(\.dismiss) private var dismiss

    // Lokaler Setup-State
    @State private var selectedNames: [String] = []
    @State private var selectedPacks: Set<SoundCinemaPack> = [.party]
    @State private var timerMode: SoundCinemaTimerMode = .medium
    @State private var livesMode: SoundCinemaLivesMode = .three

    // Sheet-Steuerung
    @State private var showPlayerSheet = false
    @State private var showInfoSheet   = false
    @State private var showTimerSheet  = false
    @State private var showLivesSheet  = false
    @State private var showPackSheet   = false

    // Animation
    @State private var appeared = false

    private var canStart: Bool {
        selectedNames.count >= 2 && !selectedPacks.isEmpty
    }

    var body: some View {
        ZStack {
            SoundCinemaBackground()

            VStack(spacing: 0) {
                header

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        setupCard
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 18)
                    }
                    .padding(.horizontal, SoundCinemaStyle.padding)
                    .padding(.top, 16)
                    .padding(.bottom, 120)
                }
                .safeAreaInset(edge: .bottom) {
                    startButtonArea
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 20)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.8).delay(0.1)) {
                appeared = true
            }
        }
        .sheet(isPresented: $showPlayerSheet) {
            SoundCinemaPlayerPickerSheet(selectedNames: $selectedNames, isPresented: $showPlayerSheet)
        }
        .sheet(isPresented: $showInfoSheet) {
            SoundCinemaInfoSheet()
        }
        .sheet(isPresented: $showTimerSheet) {
            SoundCinemaTimerPickerSheet(timerMode: $timerMode, isPresented: $showTimerSheet)
        }
        .sheet(isPresented: $showLivesSheet) {
            SoundCinemaLivesPickerSheet(livesMode: $livesMode, isPresented: $showLivesSheet)
        }
        .sheet(isPresented: $showPackSheet) {
            SoundCinemaPackPickerSheet(selectedPacks: $selectedPacks, isPresented: $showPackSheet)
        }
    }

    // MARK: - Header
    private var header: some View {
        HStack(spacing: 0) {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .modifier(GlassCircleButtonBackground())
            }
            .accessibilityLabel("Zurück")

            Spacer()

            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                showInfoSheet = true
            } label: {
                Image(systemName: "questionmark")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .modifier(GlassCircleButtonBackground())
            }
            .accessibilityLabel("Spielregeln")
        }
        .padding(.horizontal, SoundCinemaStyle.padding)
        .padding(.top, 20)
        .padding(.bottom, 10)
    }

    // MARK: - Setup Card
    private var setupCard: some View {
        VStack(spacing: 12) {
            playerRow
            packRow
            timerRow
            livesRow
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.black.opacity(0.35))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(SoundCinemaStyle.accentCyan.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.3), radius: 12, y: 6)
    }

    // MARK: - Spieler-Zeile
    private var playerRow: some View {
        let detail = selectedNames.isEmpty
            ? "Keine"
            : selectedNames.count == 1 ? "1 Spieler" : "\(selectedNames.count) Spieler"

        return Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            showPlayerSheet = true
        } label: {
            SoundCinemaSetupActionRow(
                icon: "person.2.fill",
                title: "Spieler",
                detail: detail,
                subtitle: selectedNames.isEmpty ? nil : selectedNames.joined(separator: ", "),
                accent: SoundCinemaStyle.accentCyan
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Spieler auswählen")
        .accessibilityValue(detail)
    }

    // MARK: - Pack-Zeile
    private var packDetailText: String {
        let names = SoundCinemaPack.allCases
            .filter { selectedPacks.contains($0) }
            .map { $0.localizedName }
        return names.isEmpty ? "Keine" : names.joined(separator: ", ")
    }

    private var packRow: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            showPackSheet = true
        } label: {
            SoundCinemaSetupActionRow(
                icon: "waveform",
                title: "Geräusche",
                detail: packDetailText,
                subtitle: nil,
                accent: SoundCinemaStyle.accentOrange
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Geräusche auswählen")
        .accessibilityValue(packDetailText)
    }

    // MARK: - Timer-Zeile
    private var timerRow: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            showTimerSheet = true
        } label: {
            SoundCinemaSetupActionRow(
                icon: "timer",
                title: "Zeit",
                detail: timerMode.label,
                subtitle: nil,
                accent: SoundCinemaStyle.accentCyan
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Zeit auswählen")
        .accessibilityValue(timerMode.label)
    }

    // MARK: - Lives-Zeile
    private var livesRow: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            showLivesSheet = true
        } label: {
            SoundCinemaSetupActionRow(
                icon: "heart.fill",
                title: "Leben",
                detail: livesMode.label,
                subtitle: nil,
                accent: SoundCinemaStyle.accentMint
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Leben auswählen")
        .accessibilityValue(livesMode.label)
    }

    // MARK: - Start-Button
    private var startButtonArea: some View {
        VStack(spacing: 8) {
            Button {
                guard canStart else { return }
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()

                var settings = SoundCinemaSettings()
                settings.playerNames   = selectedNames
                settings.selectedPacks = selectedPacks
                settings.timerMode     = timerMode
                settings.livesMode     = livesMode

                GlobalPlayerManager.shared.updateLastPlayed(for: selectedNames)
                viewModel.configure(with: settings)
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 16, weight: .bold))
                    Text("Spiel starten")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                }
                .foregroundStyle(canStart ? .black : .white.opacity(0.4))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    Capsule()
                        .fill(canStart
                              ? SoundCinemaStyle.primaryGradient
                              : LinearGradient(colors: [Color.white.opacity(0.08)],
                                               startPoint: .leading, endPoint: .trailing))
                        .shadow(color: canStart ? SoundCinemaStyle.accentCyan.opacity(0.45) : .clear, radius: 14, y: 5)
                )
            }
            .disabled(!canStart)
            .animation(.spring(response: 0.3), value: canStart)

            if !canStart {
                Text(selectedNames.count < 2
                     ? "Mindestens 2 Spieler hinzufügen"
                     : "Mindestens ein Geräusch-Pack auswählen")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(SoundCinemaStyle.textMuted)
                    .multilineTextAlignment(.center)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .padding(.horizontal, SoundCinemaStyle.padding)
        .padding(.top, 12)
        .padding(.bottom, 32)
    }
}
