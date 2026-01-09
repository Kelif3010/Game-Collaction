import SwiftUI

struct SpyOptionsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var gameSettings: GameSettings
    @State private var selectedTab = 0
    @State private var showTutorial = false
    @State private var roleToExplain: RoleType?
    @AppStorage("hasSeenRolesTutorial") private var hasSeenRolesTutorial = false

    var body: some View {
        ZStack {
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
                            .frame(width: 36, height: 36)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }

                    Spacer()

                    Text("Rollen & Regeln")
                        .font(.title3.bold())
                        .foregroundStyle(.white)

                    Spacer()

                    Button {
                        showTutorial = true
                    } label: {
                        Image(systemName: "questionmark")
                            .font(.headline.bold())
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
                .padding(.top, 20)
                .padding(.bottom, 8)
                .padding(.horizontal, ImposterStyle.padding)

                ImposterSegmentedControl(
                    titles: ["Spion", "Rollen"],
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
                            Text("Passe die Regeln für Spione an")
                                .font(.subheadline)
                                .foregroundStyle(ImposterStyle.mutedText)
                                .multilineTextAlignment(.center)
                                .padding(.bottom, 4)

                            VStack(spacing: 12) {
                                SpyOptionRow(
                                    icon: "folder.fill",
                                    tint: .orange,
                                    title: "Kategorie sichtbar",
                                    subtitle: "Spione sehen die gewählte Kategorie.",
                                    isOn: $gameSettings.spyCanSeeCategory
                                )

                                SpyOptionRow(
                                    icon: "person.2.fill",
                                    tint: .orange,
                                    title: "Spione sehen sich gegenseitig",
                                    subtitle: "Aktiv, wenn es mindestens zwei Spione gibt.",
                                    isDisabled: gameSettings.numberOfImposters < 2,
                                    isOn: Binding(
                                        get: { gameSettings.spiesCanSeeEachOther && gameSettings.numberOfImposters >= 2 },
                                        set: { newVal in gameSettings.spiesCanSeeEachOther = newVal }
                                    )
                                )

                                SpyOptionRow(
                                    icon: "dice.fill",
                                    tint: .orange,
                                    title: "Zahl der Spione zufällig",
                                    subtitle: "Die Anzahl kann pro Spiel variieren.",
                                    isOn: $gameSettings.randomSpyCount
                                )

                                SpyOptionRow(
                                    icon: "lightbulb.fill",
                                    tint: .orange,
                                    title: "Spion-Hinweise anzeigen",
                                    subtitle: "Zeigt dezente Tipps für Spione in der Runde.",
                                    isOn: $gameSettings.showSpyHints
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
                            Text("Spezialrollen ersetzen normale Spieler")
                                .font(.subheadline)
                                .foregroundStyle(ImposterStyle.mutedText)
                                .multilineTextAlignment(.center)
                            
                            // Team Bürger
                            RoleGroupView(teamName: "Team Bürger", teamColor: .blue, roles: [.secretAgent, .twins, .bodyguard], settings: gameSettings) { role in
                                roleToExplain = role
                            }
                            
                            // Team Spion
                            RoleGroupView(teamName: "Team Spion", teamColor: .red, roles: [.saboteur, .mole, .hacker], settings: gameSettings) { role in
                                roleToExplain = role
                            }
                            
                            // Team Chaos
                            RoleGroupView(teamName: "Team Chaos", teamColor: .purple, roles: [.fool, .confused], settings: gameSettings) { role in
                                roleToExplain = role
                            }
                        }
                        .padding(.horizontal, ImposterStyle.padding)
                        .padding(.bottom, 80)
                    }
                    .tag(1)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                ImposterPrimaryButton(title: "Fertig") {
                    dismiss()
                }
                .padding(.horizontal, ImposterStyle.padding)
                .padding(.bottom, 20)
            }
        }
        .presentationDragIndicator(.visible)
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
    @ObservedObject var settings: GameSettings
    var onInfo: (RoleType) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(teamName.uppercased())
                    .font(.caption.bold())
                    .foregroundColor(teamColor)
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
                    .foregroundColor(isSelected ? color : .gray)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(role.rawValue)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Button(action: onInfo) {
                        Image(systemName: "questionmark.circle")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                
                Text(role.description)
                    .font(.caption)
                    .foregroundColor(ImposterStyle.mutedText)
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
