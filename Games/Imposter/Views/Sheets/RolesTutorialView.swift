//
//  RolesTutorialView.swift
//  Imposter
//
//  Created by Ken on 06.01.2026.
//

import SwiftUI

struct RolesTutorialView: View {
    @Environment(\.dismiss) var dismiss
    @AppStorage("hasSeenRolesTutorial") private var hasSeenRolesTutorial = false
    @State private var currentPage = 0
    
    // Alle Rollen inklusive der Standard-Rollen (Bürger, Spion) für das Tutorial
    private let roles: [TutorialRole] = [
        TutorialRole(
            name: "Bürger",
            icon: "person.fill",
            team: .citizen,
            ability: "Kennt das geheime Wort.",
            mission: "Beschreibe das Wort unauffällig. Finde den Spion.",
            winCondition: "Wenn der Spion rausgewählt wird.",
            risk: "Wenn du zu vage bist, hält man dich für den Spion."
        ),
        TutorialRole(
            name: "Spion",
            icon: "eye.slash.fill",
            team: .imposter,
            ability: "Kennt das Wort NICHT (sieht evtl. Kategorie).",
            mission: "Bleib unentdeckt. Rate das Wort oder werde nicht gevotet.",
            winCondition: "Wenn du bis zum Ende überlebst oder das Wort errätst.",
            risk: "Verrate dich nicht durch falsche Aussagen."
        )
    ] + RoleType.allCases.map { role in
        TutorialRole(
            name: role.rawValue,
            icon: role.icon,
            team: role.team,
            ability: role.description,
            mission: getMissionText(for: role),
            winCondition: getWinText(for: role),
            risk: getRiskText(for: role)
        )
    }
    
    var body: some View {
        ZStack {
            ImposterStyle.backgroundGradient.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Spacer()
                    Text("Rollen-Handbuch")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.7))
                    Spacer()
                    
                    Button {
                        completeTutorial()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                .padding()
                
                // Karussell
                TabView(selection: $currentPage) {
                    ForEach(roles.indices, id: \.self) { index in
                        RoleCardView(role: roles[index])
                            .tag(index)
                            .padding(.horizontal, 20)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))
                
                // Footer Controls
                HStack {
                    if currentPage < roles.count - 1 {
                        Button("Überspringen") {
                            completeTutorial()
                        }
                        .foregroundColor(.white.opacity(0.5))
                        
                        Spacer()
                        
                        Button {
                            withAnimation {
                                currentPage += 1
                            }
                        } label: {
                            HStack {
                                Text("Nächste")
                                Image(systemName: "arrow.right")
                            }
                            .font(.headline.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.blue)
                            .cornerRadius(20)
                        }
                    } else {
                        Button {
                            completeTutorial()
                        } label: {
                            Text("Verstanden")
                                .font(.headline.bold())
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.green)
                                .cornerRadius(16)
                        }
                        .padding(.horizontal, 40)
                    }
                }
                .padding(20)
                .padding(.bottom, 10)
            }
        }
    }
    
    private func completeTutorial() {
        hasSeenRolesTutorial = true
        dismiss()
    }
}

// MARK: - Helper Models & Views (Public for reuse)

struct TutorialRole: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let team: RoleTeam
    let ability: String
    let mission: String
    let winCondition: String
    let risk: String
    
    var color: Color {
        switch team {
        case .citizen: return .blue
        case .imposter: return .red
        case .neutral: return .purple
        }
    }
}

struct RoleCardView: View {
    let role: TutorialRole
    
    var body: some View {
        VStack(spacing: 20) {
            // Icon
            ZStack {
                Circle()
                    .fill(role.color.opacity(0.2))
                    .frame(width: 100, height: 100)
                
                Circle()
                    .stroke(role.color, lineWidth: 2)
                    .frame(width: 100, height: 100)
                
                Image(systemName: role.icon)
                    .font(.system(size: 50))
                    .foregroundColor(role.color)
            }
            .padding(.top, 20)
            
            // Name & Team
            VStack(spacing: 5) {
                Text(role.name)
                    .font(.largeTitle.bold())
                    .foregroundColor(.white)
                
                Text(role.team.rawValue)
                    .font(.headline)
                    .foregroundColor(role.color)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(role.color.opacity(0.15))
                    .cornerRadius(8)
            }
            
            Divider().background(Color.white.opacity(0.2))
            
            // Details List
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    InfoRow(icon: "bolt.fill", title: "Fähigkeit", text: role.ability, color: .yellow)
                    InfoRow(icon: "target", title: "Mission", text: role.mission, color: .orange)
                    InfoRow(icon: "trophy.fill", title: "Sieg", text: role.winCondition, color: .green)
                    InfoRow(icon: "exclamationmark.triangle.fill", title: "Gefahr", text: role.risk, color: .red)
                }
                .padding()
            }
            
            Spacer()
        }
        .background(Color.white.opacity(0.08))
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

private struct InfoRow: View {
    let icon: String
    let title: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title3)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption.bold())
                    .foregroundColor(color.opacity(0.8))
                    .textCase(.uppercase)
                
                Text(text)
                    .font(.body)
                    .foregroundColor(.white.opacity(0.9))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

// Hilfsfunktionen für Texte
func getMissionText(for role: RoleType) -> String {
    switch role {
    case .secretAgent: return "Führe die Bürger zum Spion, ohne dich als Agent zu outen."
    case .twins: return "Arbeite mit deinem Zwilling zusammen. Ihr seid sicher."
    case .bodyguard: return "Verhalte dich verdächtig oder wie der Agent, um den Spion zu täuschen."
    case .saboteur: return "Verwirre die Bürger. Beschuldige Unschuldige, um den Spion zu retten."
    case .hacker: return "Wähle einen Spieler beim Start aus, um seine wahre Rolle zu hacken."
    case .mole: return "Verwirre den Geheimagenten, da du ihm als böse angezeigt wirst."
    case .fool: return "Verhalte dich so verdächtig, dass alle denken, du bist der Spion."
    case .confused: return "Du denkst, du bist Bürger. Beschreibe dein (falsches) Wort normal."
    }
}

func getWinText(for role: RoleType) -> String {
    switch role {
    case .secretAgent, .twins, .bodyguard, .confused:
        return "Wenn das Team Bürger den Spion rauswählt."
    case .saboteur, .mole, .hacker:
        return "Wenn der Spion gewinnt (nicht entdeckt wird)."
    case .fool:
        return "ALLEINIGER SIEG: Wenn du rausgewählt wirst."
    }
}

func getRiskText(for role: RoleType) -> String {
    switch role {
    case .secretAgent: return "Wenn du dich zu früh verrätst, erschießt dich der Spion am Ende und gewinnt trotzdem!"
    case .twins: return "Wenn ihr euch zu sehr verteidigt, wirkt ihr wie Spion & Saboteur."
    case .bodyguard: return "Übertreib es nicht! Wenn die Bürger dich zu früh rauswählen, hilfst du niemandem."
    case .saboteur: return "Verrate nicht, dass du das Wort kennst, sonst fliegst du auf."
    case .hacker: return "Nutze dein Wissen weise! Wenn du den Agenten findest, sag es dem Spion unauffällig."
    case .mole: return "Der Geheimagent wird dich jagen. Du musst ihn als Lügner darstellen."
    case .fool: return "Wenn du zu offensichtlich trollst, ignorieren dich die Bürger einfach."
    case .confused: return "Du wirst schnell verdächtig wirken. Verteidige dich ruhig."
    }
}
