import SwiftUI
import SFSafeSymbols

struct SpyOptionsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(GameSettings.self) var gameSettings
    @State private var selectedTab = 0
    @State private var showTutorial = false
    @State private var roleToExplain: RoleType?
    @AppStorage("hasSeenRolesTutorial") private var hasSeenRolesTutorial = false
    
    // AI Alert State
    @State private var showAIAlert = false

    var body: some View {
        @Bindable var gameSettings = gameSettings
        return ZStack {
            ImposterStyle.backgroundGradient.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.headline.bold())
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .modifier(GlassCircleButtonBackground())
                    }

                    Spacer()

                    Text(NSLocalizedString("Rollen & Regeln", comment: ""))
                        .font(.title3.bold())
                        .foregroundStyle(.white)

                    Spacer()

                    Button {
                        showTutorial = true
                    } label: {
                        Image(systemName: "questionmark")
                            .font(.headline.bold())
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .modifier(GlassCircleButtonBackground())
                    }
                }
                .padding(.top, 20)
                .padding(.bottom, 8)
                .padding(.horizontal, ImposterStyle.padding)

                ImposterSegmentedControl(
                    titles: [NSLocalizedString("Spion", comment: ""), NSLocalizedString("Rollen", comment: "")],
                    selectedIndex: $selectedTab
                )
                .padding(.horizontal, ImposterStyle.padding)
                .padding(.bottom, 16)
                .onChange(of: selectedTab) {
                    if selectedTab == 1 && !hasSeenRolesTutorial {
                        showTutorial = true
                    }
                }

                TabView(selection: $selectedTab) {
                    // Tab 1: Spion Optionen
                    ScrollView {
                        VStack(spacing: 16) {
                            Text(NSLocalizedString("Passe die Regeln für Spione an", comment: ""))
                                .font(.subheadline)
                                .foregroundStyle(ImposterStyle.mutedText)
                                .multilineTextAlignment(.center)
                                .padding(.bottom, 4)

                            VStack(spacing: 12) {
                                SpyOptionRow(
                                    icon: "folder.fill",
                                    tint: .orange,
                                    title: NSLocalizedString("Kategorie sichtbar", comment: ""),
                                    subtitle: NSLocalizedString("Spione sehen die gewählte Kategorie.", comment: ""),
                                    isOn: $gameSettings.spyCanSeeCategory
                                )

                                SpyOptionRow(
                                    icon: "person.2.fill",
                                    tint: .orange,
                                    title: NSLocalizedString("Spione sehen sich gegenseitig", comment: ""),
                                    subtitle: NSLocalizedString("Aktiv, wenn es mindestens zwei Spione gibt.", comment: ""),
                                    isDisabled: gameSettings.numberOfImposters < 2,
                                    isOn: Binding(
                                        get: { gameSettings.spiesCanSeeEachOther && gameSettings.numberOfImposters >= 2 },
                                        set: { newVal in gameSettings.spiesCanSeeEachOther = newVal }
                                    )
                                )

                                SpyOptionRow(
                                    icon: "dice.fill",
                                    tint: .orange,
                                    title: NSLocalizedString("Zahl der Spione zufällig", comment: ""),
                                    subtitle: NSLocalizedString("Die Anzahl kann pro Spiel variieren.", comment: ""),
                                    isOn: $gameSettings.randomSpyCount
                                )

                                SpyOptionRow(
                                    icon: "lightbulb.fill",
                                    tint: .orange,
                                    title: NSLocalizedString("Spion-Hinweise anzeigen", comment: ""),
                                    subtitle: NSLocalizedString("Zeigt dezente Tipps für Spione in der Runde.", comment: ""),
                                    isDisabled: !AIService.shared.isAvailable,
                                    badgeText: NSLocalizedString("Beta", comment: ""),
                                    isOn: Binding(
                                        get: { gameSettings.showSpyHints && AIService.shared.isAvailable },
                                        set: { if AIService.shared.isAvailable { gameSettings.showSpyHints = $0 } }
                                    ),
                                    onDisabledTap: {
                                        showAIAlert = true
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, ImposterStyle.padding)
                        .padding(.bottom, 80)
                    }
                    .tag(0)

                    // Tab 2: Sonderrollen
                    ScrollView {
                        VStack(spacing: 24) {
                            Text(NSLocalizedString("Spezialrollen ersetzen normale Spieler", comment: ""))
                                .font(.subheadline)
                                .foregroundStyle(ImposterStyle.mutedText)
                                .multilineTextAlignment(.center)
                            
                            // Team Bürger
                            RoleGroupView(teamName: NSLocalizedString("Team Bürger", comment: ""), teamColor: .blue, roles: [.secretAgent, .twins, .bodyguard], settings: gameSettings) { role in
                                roleToExplain = role
                            }
                            
                            // Team Spion
                            RoleGroupView(teamName: NSLocalizedString("Team Spion", comment: ""), teamColor: .red, roles: [.saboteur, .mole, .hacker], settings: gameSettings) { role in
                                roleToExplain = role
                            }
                            
                            // Team Chaos
                            RoleGroupView(teamName: NSLocalizedString("Team Chaos", comment: ""), teamColor: .purple, roles: [.fool, .confused], settings: gameSettings) { role in
                                roleToExplain = role
                            }
                        }
                        .padding(.horizontal, ImposterStyle.padding)
                        .padding(.bottom, 80)
                    }
                    .tag(1)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                ImposterPrimaryButton(title: NSLocalizedString("Fertig", comment: "")) {
                    dismiss()
                }
                .padding(.horizontal, ImposterStyle.padding)
                .padding(.bottom, 20)
            }
        }
        .presentationDragIndicator(.visible)
        .alert("Apple Intelligence benötigt", isPresented: $showAIAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Diese Funktion nutzt fortschrittliche KI-Modelle, die auf deinem Gerät momentan nicht verfügbar sind.")
        }
        .sheet(isPresented: $showTutorial) {
            RolesTutorialView()
        }
        .sheet(item: $roleToExplain) { role in
            ZStack {
                ImposterStyle.backgroundGradient.ignoresSafeArea()
                VStack {
                    Spacer()
                    RoleCardView(role: TutorialRole(
                        name: role.rawValue,
                        icon: role.icon,
                        team: role.team,
                        ability: role.description,
                        mission: getMissionText(for: role),
                        winCondition: getWinText(for: role),
                        risk: getRiskText(for: role)
                    ))
                    .padding()
                    Spacer()
                }
                .presentationDetents([.medium, .large])
            }
        }
    }
}

private struct RoleGroupView: View {
    let teamName: String
    let teamColor: Color
    let roles: [RoleType]
    var settings: GameSettings
    var onInfo: (RoleType) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(teamName.uppercased())
                    .font(.caption.bold())
                    .foregroundStyle(teamColor)
                Spacer()
            }
            .padding(.leading, 4)
            
            ForEach(roles) { role in
                RoleToggleRow(role: role, isSelected: Binding(
                    get: { settings.activeRoles.contains(role) },
                    set: { isActive in
                        if isActive {
                            settings.activeRoles.insert(role)
                        } else {
                            settings.activeRoles.remove(role)
                        }
                    }
                ), color: teamColor, onInfo: {
                    onInfo(role)
                })
            }
        }
    }
}

private struct RoleToggleRow: View {
    let role: RoleType
    @Binding var isSelected: Bool
    let color: Color
    var onInfo: () -> Void
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            ZStack {
                Circle()
                    .fill(isSelected ? color.opacity(0.2) : Color.gray.opacity(0.1))
                    .frame(width: 44, height: 44)
                
                Image(systemName: role.icon)
                    .font(.title3)
                    .foregroundStyle(isSelected ? color : .gray)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(role.rawValue)
                        .font(.headline)
                        .foregroundStyle(.white)
                    
                    Button(action: onInfo) {
                        Image(systemName: "questionmark.circle")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
                
                Text(role.description)
                    .font(.caption)
                    .foregroundStyle(ImposterStyle.mutedText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
            
            Toggle("", isOn: $isSelected)
                .labelsHidden()
                .tint(color)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(ImposterStyle.rowBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isSelected ? color.opacity(0.5) : ImposterStyle.cardStroke, lineWidth: 1)
        )
        .animation(.spring(), value: isSelected)
    }
}
