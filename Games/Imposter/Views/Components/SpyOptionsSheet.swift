//
//  SpyOptionsSheet.swift
//  Imposter
//
//  Created by Ken on 22.09.25.
//

import SwiftUI

struct SpyOptionsSheet: View {
    @EnvironmentObject var gameSettings: GameSettings
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationView {
            ZStack {
                // Hintergrund-Gradient
                LinearGradient(
                    colors: [Color.red.opacity(0.1), Color.orange.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 30) {
                        // Header
                        VStack(spacing: 15) {
                            
                            Text("Konfigurieren Sie das Verhalten der Spione")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 20)
                        
                        // Aktuelle Spion-Anzahl Anzeige
                        InfoCard(
                            text: "Aktuell sind \(gameSettings.numberOfImposters) \(gameSettings.numberOfImposters == 1 ? "Spion" : "Spione") im Spiel",
                            icon: "info.circle"
                        )
                        
                        // Optionen
                        VStack(spacing: 20) {
                            SectionHeader(title: "Verfügbare Optionen", icon: "list.bullet.circle")
                            
                            VStack(spacing: 15) {
                                // Option 1: Spion sieht Kategorie
                                SpyOptionCard(
                                    icon: "folder.fill",
                                    title: "Spion sieht Kategorie",
                                    description: "Spione erfahren, zu welcher Kategorie der gesuchte Begriff gehört. Dies erleichtert das Raten für die Spione.",
                                    isEnabled: gameSettings.spyCanSeeCategory,
                                    onToggle: {
                                        gameSettings.spyCanSeeCategory.toggle()
                                    }
                                )
                                
                                // Option 2: Spione sehen sich gegenseitig
                                SpyOptionCard(
                                    icon: "person.2.fill",
                                    title: "Spione sehen sich gegenseitig",
                                    description: "Bei 2 oder mehr Spionen: Jeder Spion erfährt die Namen seiner Mitspione. Nur verfügbar bei mehreren Spionen.",
                                    isEnabled: gameSettings.spiesCanSeeEachOther,
                                    isDisabled: gameSettings.numberOfImposters < 2,
                                    onToggle: {
                                        if gameSettings.numberOfImposters >= 2 {
                                            gameSettings.spiesCanSeeEachOther.toggle()
                                        }
                                    }
                                )
                                
                                // Option 3: Zufällige Spion-Anzahl (ab 5 Spielern)
                                SpyOptionCard(
                                    icon: "dice.fill",
                                    title: "Zufällige Spion-Anzahl",
                                description: randomSpyDescription,
                                isEnabled: gameSettings.randomSpyCount,
                                isDisabled: gameSettings.players.count < 5,
                                onToggle: {
                                    if gameSettings.players.count >= 5 {
                                        gameSettings.randomSpyCount.toggle()
                                    }
                                }
                            )
                                
                                // Option 4: Hinweise für Imposter
                                SpyOptionCard(
                                    icon: "lightbulb.fill",
                                    title: "Hinweise für Imposter",
                                    description: "Spione erhalten einen zusätzlichen Hinweis zum gesuchten Begriff (z.B. Hund → Bellt). Unabhängig von der Kategorie-Anzeige.",
                                    isEnabled: gameSettings.showSpyHints,
                                    onToggle: {
                                        gameSettings.showSpyHints.toggle()
                                    }
                                )
                            }
                        }
                        
                        Spacer(minLength: 50)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationTitle("Spion-Optionen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fertig") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    /// Zählt die aktiven Spion-Optionen
    private var activeOptionsCount: Int {
        var count = 0
        if gameSettings.spyCanSeeCategory { count += 1 }
        if gameSettings.spiesCanSeeEachOther && gameSettings.numberOfImposters >= 2 { count += 1 }
        if gameSettings.randomSpyCount { count += 1 }
        if gameSettings.showSpyHints { count += 1 }
        return count
    }
}

extension SpyOptionsSheet {
    private var randomSpyDescription: String {
        if gameSettings.players.count < 5 {
            return "Die Anzahl der Spione kann automatisch bestimmt werden. Aktiv ab 5 Spielern."
        }
        let cap = max(1, gameSettings.maxAllowedImpostersCap)
        return "Die Anzahl der Spione wird automatisch bestimmt (1–\(cap) Spione, maximal 50% der Spieler)."
    }
}

// MARK: - Spy Option Card
struct SpyOptionCard: View {
    let icon: String
    let title: String
    let description: String
    let isEnabled: Bool
    var isDisabled: Bool = false
    var isPlaceholder: Bool = false
    let onToggle: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: {
            if !isDisabled && !isPlaceholder {
                onToggle()
            }
        }) {
            VStack(alignment: .leading, spacing: 15) {
                HStack(alignment: .top) {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(isPlaceholder ? .gray : (isDisabled ? .gray : .red))
                        .frame(width: 30)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(title)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(isPlaceholder ? .secondary : .primary)
                            .multilineTextAlignment(.leading)
                        
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    Spacer()
                    
                    if !isPlaceholder {
                        Toggle("", isOn: .constant(isEnabled))
                            .toggleStyle(SwitchToggleStyle(tint: .red))
                            .disabled(isDisabled)
                            .allowsHitTesting(false) // Toggle wird über Button-Tap gesteuert
                    }
                }
                
                if isDisabled && !isPlaceholder {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                        
                        Text(getDisabledText())
                            .font(.caption)
                            .foregroundColor(.orange)
                            .italic()
                        
                        Spacer()
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(colorScheme == .dark ? Color(.systemGray6) : Color.white)
                    .shadow(color: .black.opacity(colorScheme == .dark ? 0.2 : 0.1), radius: 3, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(
                        isEnabled && !isPlaceholder ? Color.red.opacity(0.5) : Color.gray.opacity(0.2),
                        lineWidth: isEnabled && !isPlaceholder ? 2 : 1
                    )
            )
            .opacity(isPlaceholder ? 0.6 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isPlaceholder)
    }
    
    private func getDisabledText() -> String {
        if title == "Spione sehen sich gegenseitig" {
            return "Nur bei 2+ Spionen verfügbar"
        } else if title == "Zufällige Spion-Anzahl" {
            return "Nur ab 5 Spielern verfügbar"
        }
        return "Nicht verfügbar"
    }
}

#Preview {
    let settings = GameSettings()
    settings.numberOfImposters = 2
    settings.spyCanSeeCategory = true
    settings.spiesCanSeeEachOther = false
    
    return SpyOptionsSheet()
        .environmentObject(settings)
}
