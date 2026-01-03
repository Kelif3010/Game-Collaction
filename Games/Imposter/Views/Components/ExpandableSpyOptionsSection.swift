//
//  ExpandableSpyOptionsSection.swift
//  Imposter
//
//  Created by Ken on 22.09.25.
//

import SwiftUI

struct ExpandableSpyOptionsSection: View {
    @ObservedObject var gameSettings: GameSettings
    @Binding var isExpanded: Bool
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 15) {
            // Header mit Expand/Collapse Button
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isExpanded.toggle()
                }
            }) {
                SettingCard {
                    HStack {
                        Image(systemName: "eye.slash.fill")
                            .font(.title2)
                            .foregroundColor(.red)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Spion-Optionen")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text("\(gameSettings.numberOfImposters) \(gameSettings.numberOfImposters == 1 ? "Spion" : "Spione") • \(activeOptionsCount) von 2 Optionen aktiv")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        // Anzahl Spione (immer sichtbar)
                        HStack(spacing: 8) {
                            Text("\(gameSettings.numberOfImposters)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.red)
                            
                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                .font(.title3)
                                .foregroundColor(.red)
                                .animation(.easeInOut(duration: 0.2), value: isExpanded)
                        }
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            // Expandable Content
            if isExpanded {
                VStack(spacing: 15) {
                    // Anzahl Spione Stepper
                    SettingCard {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Image(systemName: "number.circle.fill")
                                    .foregroundColor(.red)
                                Text("Anzahl Spione anpassen")
                                    .font(.headline)
                                Spacer()
                            }
                            
                            let minImposters = gameSettings.maxAllowedImpostersCap == 0 ? 0 : 1
                            let maxImposters = max(gameSettings.maxAllowedImpostersCap, minImposters)
                            Stepper("", value: $gameSettings.numberOfImposters,
                                    in: minImposters...maxImposters)
                                .labelsHidden()
                                .disabled(gameSettings.randomSpyCount)
                        }
                        .opacity(gameSettings.randomSpyCount ? 0.5 : 1.0)
                    }
                    
                    // Spion sieht Kategorie
                    SettingCard {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "folder.fill")
                                    .foregroundColor(.red)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Spion sieht Kategorie")
                                        .font(.headline)
                                    Text("Spione erfahren, zu welcher Kategorie der Begriff gehört")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Toggle("", isOn: $gameSettings.spyCanSeeCategory)
                                    .toggleStyle(SwitchToggleStyle(tint: .red))
                            }
                        }
                    }
                    
                    // Spione sehen sich gegenseitig
                    SettingCard {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "person.2.fill")
                                    .foregroundColor(gameSettings.numberOfImposters >= 2 ? .red : .gray)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Spione sehen sich gegenseitig")
                                        .font(.headline)
                                        .foregroundColor(gameSettings.numberOfImposters >= 2 ? .primary : .secondary)
                                    Text("Bei 2+ Spionen: Spione erfahren die Namen ihrer Mitspione")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Toggle("", isOn: $gameSettings.spiesCanSeeEachOther)
                                    .toggleStyle(SwitchToggleStyle(tint: .red))
                                    .disabled(gameSettings.numberOfImposters < 2)
                            }
                        }
                    }
                    
                    // Hinweis bei weniger als 2 Spionen
                    if gameSettings.numberOfImposters < 2 {
                        InfoCard(text: "Die Option 'Spione sehen sich gegenseitig' ist nur bei 2 oder mehr Spionen verfügbar", icon: "info.circle")
                    }
                    
                    // Platzhalter für zukünftige Features
                    SettingCard {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "plus.circle.dashed")
                                    .foregroundColor(.gray)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Weitere Optionen")
                                        .font(.headline)
                                        .foregroundColor(.secondary)
                                    Text("Zukünftige Spion-Features werden hier angezeigt")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .italic()
                                }
                                Spacer()
                            }
                        }
                    }
                    .opacity(0.5)
                }
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
    }
    
    /// Zählt die aktiven Spion-Optionen
    private var activeOptionsCount: Int {
        var count = 0
        if gameSettings.spyCanSeeCategory { count += 1 }
        if gameSettings.spiesCanSeeEachOther && gameSettings.numberOfImposters >= 2 { count += 1 }
        return count
    }
}

#Preview {
    let settings = GameSettings()
    settings.players = [
        Player(name: "Alice"),
        Player(name: "Bob"),
        Player(name: "Charlie"),
        Player(name: "David")
    ]
    
    return ScrollView {
        ExpandableSpyOptionsSection(
            gameSettings: settings,
            isExpanded: .constant(true)
        )
        .padding(20)
    }
    .background(
        LinearGradient(
            colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
}
