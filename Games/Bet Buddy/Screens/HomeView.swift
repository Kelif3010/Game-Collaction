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
            Theme.background.ignoresSafeArea()

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
                        icon: "sparkles",
                        title: "Party Modus",
                        detail: appModel.isPartyMode  ? "An" : "Aus",
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
                        title: "Punkte Abzug",
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
                .background(Color.black.opacity(0.25))
                .clipShape(RoundedRectangle(cornerRadius: 22))
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )

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
        .sheet(isPresented: $showTimerSheet) { timerSheet }
        .sheet(isPresented: $showPenaltySheet) { penaltySheet }
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
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Circle())
            }

            Spacer()
            
            Button {
                HapticsService.impact(.light)
                showLeaderboardSheet = true
            } label: {
                Image(systemName: "trophy.fill")
                    .font(.headline)
                    .foregroundStyle(.yellow)
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Circle())
            }
            .padding(.trailing, 8)
            
            Button {
                HapticsService.impact(.light)
                showInfoSheet = true
            } label: {
                Image(systemName: "questionmark")
                    .font(.headline.bold())
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Circle())
            }
        }
    }

    private var timerSheet: some View {
        NavigationStack {
            List {
                ForEach(appModel.timerOptions, id: \.self) { option in
                    Button {
                        appModel.timerSelection = option
                        showTimerSheet = false
                        HapticsService.impact(.light)
                    } label: {
                        HStack {
                            (Text("\(option) ") + Text("Sekunden"))
                                .foregroundStyle(.white)
                            Spacer()
                            if appModel.timerSelection == option {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color.green)
                            }
                        }
                    }
                    .listRowBackground(Color.black)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Schließen") { showTimerSheet = false }
                }
            }
        }
    }

    private var penaltySheet: some View {
        NavigationStack {
            List {
                ForEach(PenaltyLevel.allCases) { level in
                    Button {
                        appModel.penaltyLevel = level
                        showPenaltySheet = false
                        HapticsService.impact(.light)
                    } label: {
                        HStack {
                            Text(LocalizedStringKey(level.title))
                                .foregroundStyle(.white)
                            Spacer()
                            if appModel.penaltyLevel == level {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color.green)
                            }
                        }
                    }
                    .listRowBackground(Color.black)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Schließen") { showPenaltySheet = false }
                }
            }
        }
    }
}
