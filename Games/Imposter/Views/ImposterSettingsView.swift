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
        NavigationView {
            VStack(spacing: 30) {
                Text("Einstellungen")
                    .font(.largeTitle)
                    .padding(.top, 50)
                
                VStack(spacing: 16) {
                    Text("Allgemeine Einstellungen")
                        .font(.title3)
                        .foregroundColor(.secondary)

                    // Hinweise-Einstellungen
                    Toggle(isOn: $settings.enableHints) {
                        HStack(spacing: 12) {
                            Image(systemName: "lightbulb.fill")
                                .foregroundColor(.yellow)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Hinweise aktivieren")
                                    .font(.headline)
                                Text("Zeigt während des Spiels gelegentlich Tipps an.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
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
                                .foregroundColor(.blue)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Stimmen & Vorlesen")
                                    .font(.headline)
                                Text("Premium-Stimmen auswählen und testen")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
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
                                .foregroundColor(aiService.isAvailable ? .green : .orange)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Apple Intelligence")
                                    .font(.headline)
                                Text(aiService.isAvailable ? "Aktiv – KI generiert Hinweise, Rollen und Logs." : "Nicht verfügbar – Fallback-Logik wird automatisch genutzt.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            Spacer()
                        }
                    }
                    
#if DEBUG
                    NavigationLink(destination: FairnessDebugView()) {
                        HStack {
                            Image(systemName: "ladybug.fill")
                                .foregroundColor(.orange)
                            Text("Fairness-Simulator (Debug)")
                                .font(.headline)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.secondarySystemBackground))
                        )
                    }
#else
                    NavigationLink(destination: FairnessDebugView()) {
                        HStack {
                            Image(systemName: "ladybug.fill")
                                .foregroundColor(.orange)
                            Text("Fairness-Simulator")
                                .font(.headline)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.secondarySystemBackground))
                        )
                    }
#endif
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
#if os(iOS)
        .navigationViewStyle(StackNavigationViewStyle())
#endif
    }
}

#Preview {
    ImposterSettingsView()
}
