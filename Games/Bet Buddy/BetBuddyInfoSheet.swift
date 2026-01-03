//
//  BetBuddyInfoSheet.swift
//  Games Collection
//
//  Created by Ken  on 03.01.26.
//


import SwiftUI

struct BetBuddyInfoSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        
                        // Einleitung
                        InfoSection(
                            icon: "person.3.fill",
                            color: .cyan,
                            title: "Worum geht's?",
                            text: "Bet Buddy ist das ultimative Partyspiel! Schätzt eure Freunde ein, wettet auf ihre Antworten und sammelt Punkte. Wer seine Freunde am besten kennt, gewinnt."
                        )

                        Divider().overlay(.white.opacity(0.2))

                        // Einstellungen Erklärung
                        Text("Die Einstellungen")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .padding(.top, 4)

                        VStack(spacing: 16) {
                            InfoRow(icon: "brain.head.profile", title: "Kategorien", text: "Wählt Themen wie 'Party', 'Spicy' oder 'Deep', um die Art der Fragen zu bestimmen.")
                            InfoRow(icon: "sparkles", title: "Party Modus", text: "Sorgt für mehr Chaos und zufällige Ereignisse zwischen den Runden.")
                            InfoRow(icon: "exclamationmark.circle", title: "Punkte Abzug", text: "Bestimmt, wie hart falsche Tipps bestraft werden. Von 'Harmlos' bis 'Extrem'.")
                            InfoRow(icon: "clock.fill", title: "Zeitlimit", text: "Setzt Druck auf! Beantwortet Fragen, bevor der Timer abläuft.")
                        }

                        Divider().overlay(.white.opacity(0.2))

                        // Spielablauf
                        Text("So wird gespielt")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .padding(.top, 4)

                        VStack(alignment: .leading, spacing: 12) {
                            StepView(number: 1, text: "Ein Spieler liest die Frage laut vor.")
                            StepView(number: 2, text: "Alle tippen geheim auf die Person, auf die die Aussage am ehesten zutrifft.")
                            StepView(number: 3, text: "Die Ergebnisse werden enthüllt. Die Person mit den meisten Stimmen muss trinken (oder eine Aufgabe erfüllen)!")
                            StepView(number: 4, text: "Punkte gibt es für die Mehrheit.")
                        }
                        
                        Spacer(minLength: 40)
                    }
                    .padding()
                }
            }
            .navigationTitle("Spielanleitung")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Verstanden") {
                        dismiss()
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                }
            }
            // Toolbar Hintergrund Styling für Konsistenz
            .toolbarBackground(Theme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .foregroundStyle(.white)
        }
    }
}

// Kleine Hilfs-Komponenten für das InfoSheet
private struct InfoSection: View {
    var icon: String
    var color: Color
    var title: String
    var text: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.largeTitle)
                .foregroundStyle(color)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.white)
                Text(text)
                    .font(.subheadline)
                    .foregroundStyle(Theme.mutedText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

private struct InfoRow: View {
    var icon: String
    var title: String
    var text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(.white)
                .frame(width: 24)
                .padding(8)
                .background(Color.white.opacity(0.1))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                Text(text)
                    .font(.caption)
                    .foregroundStyle(Theme.mutedText)
            }
        }
    }
}

private struct StepView: View {
    var number: Int
    var text: String

    var body: some View {
        HStack(spacing: 12) {
            Text("\(number)")
                .font(.headline)
                .foregroundStyle(.black)
                .frame(width: 24, height: 24)
                .background(Color.white)
                .clipShape(Circle())
            
            Text(text)
                .font(.subheadline)
                .foregroundStyle(Theme.mutedText)
        }
    }
}