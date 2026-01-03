import SwiftUI

struct MainSettingsView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                // MARK: - Allgemein
                Section(header: Text("Allgemein")) {
                    NavigationLink(destination: Text("Sprachauswahl hier")) {
                        Label("Sprache", systemImage: "globe")
                    }
                    NavigationLink(destination: Text("App Icons hier")) {
                        Label("App Icon", systemImage: "app.badge")
                    }
                }
                
                // MARK: - Community (NEU)
                Section(header: Text("Community")) {
                    // YouTube Link
                    Link(destination: URL(string: "https://www.youtube.com/@elfiandken")!) {
                        Label {
                            Text("YouTube")
                                .foregroundStyle(.primary)
                        } icon: {
                            Image(systemName: "play.rectangle.fill")
                                .foregroundStyle(.red) // YouTube Rot
                        }
                    }
                    
                    // Instagram Link
                    Link(destination: URL(string: "https://www.instagram.com/elfiandken/")!) {
                        Label {
                            Text("Instagram")
                                .foregroundStyle(.primary)
                        } icon: {
                            Image(systemName: "camera.fill")
                                .foregroundStyle(.purple) // Insta Purple
                        }
                    }
                }
                
                // MARK: - Support & Info
                Section(header: Text("Support & Info")) {
                    NavigationLink(destination: Text("Über uns Text")) {
                        Label("Über uns", systemImage: "info.circle")
                    }
                    Button("Feedback senden") {
                        // Action für Feedback
                    }
                    Toggle("Benachrichtigungen", isOn: .constant(true))
                }
                
                // MARK: - Branding Footer (NEU)
                Section {
                    VStack(alignment: .center, spacing: 6) {
                        Text("Made with ❤️ by KELIF")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        
                        Text("KELIF Studios")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Text("Version 1.0.0")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear) // Transparenter Hintergrund für Footer-Look
                }
            }
            .navigationTitle("Einstellungen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fertig") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

#Preview {
    MainSettingsView()
}
