//
//  SoundCinemaInfoSheet.swift
//  Games Collection
//
//  Spielregeln-Sheet
//

import SwiftUI

// MARK: - Info Sheet (Spielregeln)

struct SoundCinemaInfoSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                SoundCinemaBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        ruleBlock(icon: "1.circle.fill", color: SoundCinemaStyle.accentCyan,
                                  title: "Karte ziehen",
                                  text: "Der aktive Spieler tippt auf die Karte. Ein Geräusch erscheint – z.B. \"Startendes Flugzeug\".")

                        ruleBlock(icon: "2.circle.fill", color: SoundCinemaStyle.accentMint,
                                  title: "Geräusch imitieren",
                                  text: "Der Timer startet. Imitiere das Geräusch nur mit dem Mund – so gut du kannst!")

                        ruleBlock(icon: "3.circle.fill", color: SoundCinemaStyle.accentCyan,
                                  title: "Gruppe rät",
                                  text: "Die anderen Spieler versuchen das Geräusch zu erraten. Hat jemand es erraten, tippt der aktive Spieler auf ✓.")

                        ruleBlock(icon: "4.circle.fill", color: SoundCinemaStyle.accentMint,
                                  title: "Zeit abgelaufen?",
                                  text: "Wenn der Timer abläuft ohne dass jemand geraten hat, verliert der aktive Spieler ein Leben.")

                        ruleBlock(icon: "heart.fill", color: .red,
                                  title: "Leben & Ausscheiden",
                                  text: "Wer alle Leben verliert, scheidet aus. Das Spiel endet wenn nur noch ein Spieler übrig ist – er gewinnt!")

                        ruleBlock(icon: "infinity", color: SoundCinemaStyle.accentMint,
                                  title: "Endlos-Modus",
                                  text: "Mit ∞ Leben scheidet niemand aus. Ihr spielt bis ihr aufhören wollt – perfekt für lockere Runden.")
                    }
                    .padding()
                }
            }
            .navigationTitle("Spielregeln")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Verstanden!") { dismiss() }
                        .font(.headline)
                        .foregroundStyle(SoundCinemaStyle.accentCyan)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(28)
    }

    private func ruleBlock(icon: String, color: Color, title: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundStyle(color)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                Text(text)
                    .font(.system(size: 14))
                    .foregroundStyle(SoundCinemaStyle.textMuted)
                    .lineSpacing(3)
            }
        }
        .padding(14)
        .soundCinemaCard()
    }
}
