import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var appModel: AppViewModel
    @Environment(\.dismiss) private var dismiss
    
    var onSelectGroups: () -> Void
    var onSelectCategories: () -> Void
    var onStart: () -> Void

    @State private var showTimerSheet = false
    @State private var showPenaltySheet = false
    @State private var showInfoSheet = false
    @State private var showLeaderboardSheet = false
    
    // Dauerhafter Speicher (User hat es schon mal gesehen)
    @AppStorage("hasSeenBetBuddyOnboarding") private var hasSeenOnboarding: Bool = false
    
    // Lokaler State: Haben wir in DIESER Session schon geprüft?
    // Verhindert das Aufpoppen beim Zurücknavigieren.
    @State private var checkPerformed = false

    var body: some View {
        ZStack {
            BetBuddyBackgroundView(intensity: 0.5)

            VStack(alignment: .leading, spacing: 20) {
                topBar

                VStack(spacing: 12) {
                    SettingsRow(
                        icon: "person.2.fill",
                        title: "Gruppen",
                        detail: "\(appModel.selectedGroupCount)",
                        rowType: .groups,
                        onTap: onSelectGroups
                    )

                    SettingsRow(
                        icon: "brain.head.profile",
                        title: "Kategorien",
                        // Hier wird jetzt automatisch "Mix" angezeigt (durch ViewModel Logik)
                        detail: appModel.selectedCategoriesDisplay,
                        rowType: .categories,
                        onTap: onSelectCategories
                    )

                    SettingsRow(
                        icon: "timer",
                        title: "Zeit läuft weiter",
                        detail: appModel.isPartyMode ? "Kein Reset" : "Reset bei Treffer",
                        rowType: .partyMode,
                        isToggleOn: appModel.isPartyMode,
                        onTap: {
                            appModel.isPartyMode.toggle()
                        },
                        onToggle: { isOn in
                            appModel.isPartyMode = isOn
                        }
                    )

                    SettingsRow(
                        icon: "exclamationmark.circle",
                        title: "Punktabzug",
                        detail: appModel.isPenaltyEnabled ? appModel.penaltyLevel.title : "Aus",
                        rowType: .penalty,
                        isToggleOn: appModel.isPenaltyEnabled,
                        onTap: {
                            if appModel.isPenaltyEnabled {
                                showPenaltySheet = true
                            }
                        },
                        onToggle: { isOn in
                            appModel.isPenaltyEnabled = isOn
                            if isOn {
                                showPenaltySheet = true
                            }
                        }
                    )

                    SettingsRow(
                        icon: "lightbulb.fill",
                        title: "Hinweise",
                        detail: appModel.isHintsEnabled ? "An" : "Aus",
                        rowType: .hints,
                        isToggleOn: appModel.isHintsEnabled,
                        onTap: {
                            appModel.isHintsEnabled.toggle()
                        },
                        onToggle: { isOn in
                            appModel.isHintsEnabled = isOn
                        }
                    )

                    SettingsRow(
                        icon: "clock.fill",
                        title: "Zeitlimit",
                        detail: appModel.isTimerEnabled ? "\(appModel.timerSelection)s" : "Aus",
                        rowType: .timer,
                        isToggleOn: appModel.isTimerEnabled,
                        onTap: {
                            if appModel.isTimerEnabled {
                                showTimerSheet = true
                            }
                        },
                        onToggle: { isOn in
                            appModel.isTimerEnabled = isOn
                            if isOn {
                                showTimerSheet = true
                            }
                        }
                    )
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.black.opacity(0.35))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(BetBuddyTheme.accentGold.opacity(0.15), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.3), radius: 12, y: 6)

                Spacer()

                PrimaryButton(title: "Spiel starten") {
                    HapticsService.impact(.medium)
                    onStart()
                }
                .padding(.bottom, 12)
            }
            .padding(Theme.padding)
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showTimerSheet) {
            CasinoTimerSheet(
                options: appModel.timerOptions,
                selected: appModel.timerSelection
            ) { appModel.timerSelection = $0 }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(28)
        }
        .sheet(isPresented: $showPenaltySheet) {
            CasinoPenaltySheet(
                selected: appModel.penaltyLevel
            ) { appModel.penaltyLevel = $0 }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(28)
        }
        .sheet(isPresented: $showInfoSheet) {
            BetBuddyInfoSheet()
        }
        .sheet(isPresented: $showLeaderboardSheet) {
            BetBuddyLeaderboardView()
        }
        // FIX: Nur einmal prüfen!
        .onAppear {
            if !checkPerformed {
                checkPerformed = true
                if !hasSeenOnboarding {
                    // Kleine Verzögerung für schönere UX beim Start
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showInfoSheet = true
                    }
                }
            }
        }
    }

    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.headline.bold())
                    .foregroundStyle(BetBuddyTheme.textChampagne)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.08))
                            .overlay(
                                Circle()
                                    .stroke(BetBuddyTheme.accentGold.opacity(0.2), lineWidth: 1)
                            )
                    )
            }

            Spacer()

            Button {
                HapticsService.impact(.light)
                showLeaderboardSheet = true
            } label: {
                Image(systemName: "trophy.fill")
                    .font(.headline)
                    .foregroundStyle(BetBuddyTheme.accentGold)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(BetBuddyTheme.accentGold.opacity(0.15))
                            .overlay(
                                Circle()
                                    .stroke(BetBuddyTheme.accentGold.opacity(0.3), lineWidth: 1)
                            )
                    )
            }
            .padding(.trailing, 8)

            Button {
                HapticsService.impact(.light)
                showInfoSheet = true
            } label: {
                Image(systemName: "questionmark")
                    .font(.headline.bold())
                    .foregroundStyle(BetBuddyTheme.textChampagne)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.08))
                            .overlay(
                                Circle()
                                    .stroke(BetBuddyTheme.accentGold.opacity(0.2), lineWidth: 1)
                            )
                    )
            }
        }
    }

}

// MARK: - Casino Timer Sheet

private struct CasinoTimerSheet: View {
    let options: [Int]
    let selected: Int
    let onSelect: (Int) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            BetBuddyBackgroundView(intensity: 0.5)

            VStack(spacing: 0) {
                // Header
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.headline.bold())
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                    }
                    Spacer()
                    HStack(spacing: 6) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(BetBuddyTheme.accentGold)
                        Text("ZEITLIMIT")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundStyle(BetBuddyTheme.textGold)
                            .tracking(2)
                    }
                    Spacer()
                    Color.clear.frame(width: 44, height: 44)
                }
                .padding(.horizontal)
                .padding(.top, 20)

                Text("Wähle die Zeit pro Runde")
                    .font(.subheadline)
                    .foregroundStyle(BetBuddyTheme.textSilver)
                    .padding(.top, 8)

                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(options, id: \.self) { option in
                            let isSelected = selected == option
                            Button {
                                HapticsService.impact(.light)
                                onSelect(option)
                                dismiss()
                            } label: {
                                HStack(spacing: 14) {
                                    ZStack {
                                        Circle()
                                            .fill(isSelected
                                                ? BetBuddyTheme.accentGold.opacity(0.2)
                                                : Color.white.opacity(0.06))
                                            .frame(width: 36, height: 36)
                                        Image(systemName: "timer")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundStyle(isSelected
                                                ? BetBuddyTheme.accentGold
                                                : BetBuddyTheme.textSilver)
                                    }

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("\(option) Sekunden")
                                            .font(.body.weight(.semibold))
                                            .foregroundStyle(.white)
                                        Text(timerHint(for: option))
                                            .font(.caption)
                                            .foregroundStyle(BetBuddyTheme.textSilver)
                                    }

                                    Spacer()

                                    if isSelected {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.title3)
                                            .foregroundStyle(BetBuddyTheme.accentGold)
                                    } else {
                                        Image(systemName: "circle")
                                            .font(.title3)
                                            .foregroundStyle(BetBuddyTheme.textSilver.opacity(0.4))
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(isSelected
                                            ? BetBuddyTheme.accentGold.opacity(0.12)
                                            : Color.black.opacity(0.35))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(isSelected
                                            ? BetBuddyTheme.accentGold.opacity(0.5)
                                            : Color.white.opacity(0.08),
                                            lineWidth: 1)
                                )
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 16)
                }
            }
        }
    }

    private func timerHint(for seconds: Int) -> String {
        switch seconds {
        case 15: return "Blitzrunde"
        case 30: return "Schnell"
        case 45: return "Normal"
        case 60: return "Entspannt"
        case 90: return "Gemächlich"
        case 120: return "Langform · 2 Min"
        case 180: return "Marathon · 3 Min"
        default: return "\(seconds)s"
        }
    }
}

// MARK: - Casino Penalty Sheet

private struct CasinoPenaltySheet: View {
    let selected: PenaltyLevel
    let onSelect: (PenaltyLevel) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            BetBuddyBackgroundView(intensity: 0.5)

            VStack(spacing: 0) {
                // Header
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.headline.bold())
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                    }
                    Spacer()
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(BetBuddyTheme.accentRuby)
                        Text("PUNKTABZUG")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundStyle(BetBuddyTheme.textGold)
                            .tracking(2)
                    }
                    Spacer()
                    Color.clear.frame(width: 44, height: 44)
                }
                .padding(.horizontal)
                .padding(.top, 20)

                Text("Strafe bei Aufgeben oder Zeitablauf")
                    .font(.subheadline)
                    .foregroundStyle(BetBuddyTheme.textSilver)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)

                VStack(spacing: 10) {
                    ForEach(PenaltyLevel.allCases) { level in
                        let isSelected = selected == level
                        Button {
                            HapticsService.impact(.light)
                            onSelect(level)
                            dismiss()
                        } label: {
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(isSelected
                                            ? penaltyColor(level).opacity(0.2)
                                            : Color.white.opacity(0.06))
                                        .frame(width: 40, height: 40)
                                    Text(penaltyEmoji(level))
                                        .font(.system(size: 18))
                                }

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(level.title)
                                        .font(.body.weight(.semibold))
                                        .foregroundStyle(.white)
                                    Text(penaltyDescription(level))
                                        .font(.caption)
                                        .foregroundStyle(isSelected
                                            ? penaltyColor(level).opacity(0.9)
                                            : BetBuddyTheme.textSilver)
                                }

                                Spacer()

                                if isSelected {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.title3)
                                        .foregroundStyle(BetBuddyTheme.accentGold)
                                } else {
                                    Image(systemName: "circle")
                                        .font(.title3)
                                        .foregroundStyle(BetBuddyTheme.textSilver.opacity(0.4))
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(isSelected
                                        ? penaltyColor(level).opacity(0.10)
                                        : Color.black.opacity(0.35))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(isSelected
                                        ? penaltyColor(level).opacity(0.4)
                                        : Color.white.opacity(0.08),
                                        lineWidth: 1)
                            )
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 16)

                Spacer()
            }
        }
    }

    private func penaltyDescription(_ level: PenaltyLevel) -> String {
        switch level {
        case .normal: return "Nur offene Punkte verlieren"
        case .medium: return "Halbe Wette verlieren"
        case .hardcore: return "Ganze Wette verlieren"
        }
    }

    private func penaltyEmoji(_ level: PenaltyLevel) -> String {
        switch level {
        case .normal: return "🎯"
        case .medium: return "💥"
        case .hardcore: return "☠️"
        }
    }

    private func penaltyColor(_ level: PenaltyLevel) -> Color {
        switch level {
        case .normal: return BetBuddyTheme.accentEmerald
        case .medium: return BetBuddyTheme.accentGold
        case .hardcore: return BetBuddyTheme.accentRuby
        }
    }
}
