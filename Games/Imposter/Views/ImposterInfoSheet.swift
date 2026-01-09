//
//  ImposterInfoSheet.swift
//  Imposter
//
//  Created by Ken on 25.09.25.
//

import SwiftUI

struct ImposterInfoSheet: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                ImposterStyle.backgroundGradient
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        
                        // Header Image or Icon
                        HStack {
                            Spacer()
                            Image(systemName: "person.crop.circle.badge.questionmark")
                                .font(.system(size: 60))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.orange, .red],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: .orange.opacity(0.5), radius: 10)
                            Spacer()
                        }
                        .padding(.top, 20)
                        .padding(.bottom, 10)

                        Text("Spielanleitung")
                            .font(.largeTitle)
                            .bold()
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, alignment: .center)

                        VStack(spacing: 24) {
                            InstructionSection(
                                icon: "person.3.fill",
                                title: "Das Ziel",
                                content: "Finde heraus, wer der Spion (Imposter) ist, bevor die Zeit abläuft. Der Spion muss versuchen, unerkannt zu bleiben und das geheime Wort zu erraten."
                            )

                            InstructionSection(
                                icon: "eye.slash.fill",
                                title: "Der Ablauf",
                                content: "Jeder Spieler erhält eine Karte. Die Bürger sehen das geheime Wort, der Spion sieht nur seine Rolle. Reihum beschreibt jeder Spieler das Wort mit einem einzigen Begriff oder Satz, ohne es zu verraten."
                            )

                            InstructionSection(
                                icon: "hand.raised.fill",
                                title: "Verdacht & Voting",
                                content: "Sobald ein Verdacht besteht, kann diskutiert und abgestimmt werden. Wählen die Bürger den Spion raus, gewinnen sie. Wählt ihr einen Unschuldigen, gewinnt der Spion sofort!"
                            )
                            
                            InstructionSection(
                                icon: "lightbulb.fill",
                                title: "Hinweise & Challenges",
                                content: "Während des Spiels können zufällige Ereignisse auftreten. Hinweise helfen (oder verwirren), und Challenges zwingen Spieler zu bestimmten Aussagen."
                            )
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.gray)
                            .font(.title2)
                    }
                }
            }
        }
    }
}

private struct InstructionSection: View {
    let icon: String
    let title: LocalizedStringKey
    let content: LocalizedStringKey

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(.orange)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.white)
                
                Text(content)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

#Preview {
    ImposterInfoSheet()
}
