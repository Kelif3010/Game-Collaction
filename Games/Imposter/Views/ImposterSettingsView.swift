//
//  SettingsView.swift
//  Imposter
//
//  Created by Ken on 22.09.25.
//

import SwiftUI

struct ImposterSettingsView: View {
    @ObservedObject private var settings = SettingsService.shared
    @ObservedObject private var aiService = AIService.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Text("Einstellungen")
                    .font(.largeTitle)
                    .padding(.top, 50)
                
                VStack(spacing: 16) {
                    Text("Allgemeine Einstellungen")
                        .font(.title3)
                        .foregroundStyle(.secondary)

                    // Hinweise-Einstellungen
                    Toggle(isOn: $settings.enableHints) {
                        HStack(spacing: 12) {
                            Image(systemName: "lightbulb.fill")
                                .foregroundStyle(.yellow)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Hinweise aktivieren")
                                    .font(.headline)
                                Text("Zeigt während des Spiels gelegentlich Tipps an.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.secondarySystemBackground))
                    )
                    
                    NavigationLink(destination: VoiceSettingsView()) {
                        HStack {
                            Image(systemName: "waveform")
                                .foregroundStyle(.blue)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Stimmen & Vorlesen")
                                    .font(.headline)
                                Text("Premium-Stimmen auswählen und testen")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.secondarySystemBackground))
                        )
                    }

                    SettingCard {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: aiService.isAvailable ? "brain.head.profile" : "bolt.slash")
                                .font(.title2)
                                .foregroundStyle(aiService.isAvailable ? .green : .orange)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Apple Intelligence")
                                    .font(.headline)
                                Text(aiService.isAvailable ? "Aktiv – KI generiert Hinweise, Rollen und Logs." : "Nicht verfügbar – Fallback-Logik wird automatisch genutzt.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            Spacer()
                        }
                    }
 
                }
                
                Spacer()
            }
            .navigationTitle("Einstellungen")
#if os(iOS)
            .navigationBarHidden(true)
#endif
            .toolbar {
#if os(iOS)
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Zurück") {
                        dismiss()
                    }
                }
#endif
            }
        }
    }
}

#Preview {
    ImposterSettingsView()
}
