import SwiftUI

struct BetBuddyInfoSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentPage = 0
    
    // FIX: Zugriff auf den Speicher, um zu markieren, dass es erledigt ist
    @AppStorage("hasSeenBetBuddyOnboarding") private var hasSeenOnboarding: Bool = false
    
    // Wir haben 4 Seiten (0 bis 3)
    private let pageCount = 4

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Der Inhalt als Swipe-View (TabView)
                    TabView(selection: $currentPage) {
                        
                        // SEITE 1: Intro (Worum geht's?)
                        InfoPage(
                            icon: "person.2.wave.2.fill", // Passendes Icon für Partner/Teams
                            color: .cyan,
                            title: "Worum geht's?",
                            content: {
                                VStack(alignment: .leading, spacing: 14) {
                                    BulletPoint(text: "Bet Buddy ist ein Wettspiel für 2er-Teams.", icon: "person.2.fill")
                                    BulletPoint(text: "Ihr wettet darauf, dass euer Partner eine Challenge schafft (z.B. '5 Länder mit K nennen').", icon: "hand.raised.fingers.spread.fill")
                                    BulletPoint(text: "Je höher die Wette, desto mehr Punkte – aber auch mehr Risiko!", icon: "chart.line.uptrend.xyaxis")
                                }
                            }
                        )
                        .tag(0)

                        // SEITE 2: Ablauf (So wird gespielt)
                        InfoPage(
                            icon: "list.number",
                            color: .mint,
                            title: "So wird gespielt",
                            content: {
                                VStack(alignment: .leading, spacing: 12) {
                                    StepRow(number: 1, text: "Eine Challenge erscheint. Jedes Team bietet geheim Punkte auf den eigenen Partner.")
                                    StepRow(number: 2, text: "Das Team mit der HÖCHSTEN Wette muss spielen!")
                                    StepRow(number: 3, text: "Der Partner muss liefern. Tippt auf 'Geschafft', um den Zähler zu senken.")
                                    StepRow(number: 4, text: "Ziel: Den Zähler auf 0 bringen, bevor die Zeit abläuft.")
                                }
                            }
                        )
                        .tag(1)

                        // SEITE 3: Punkte & Risiko (Deine Logik!)
                        InfoPage(
                            icon: "trophy.fill",
                            color: .yellow,
                            title: "Punkte & Wertung",
                            content: {
                                VStack(spacing: 12) {
                                    Text("Bei Erfolg:")
                                        .font(.caption.bold())
                                        .foregroundStyle(Theme.mutedText)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    
                                    ScoreRow(title: "Wette geschafft", value: "+ Wette", color: .green)
                                    
                                    Divider().background(Color.white.opacity(0.2)).padding(.vertical, 4)
                                    
                                    Text("Bei Misserfolg (je nach Einstellung):")
                                        .font(.caption.bold())
                                        .foregroundStyle(Theme.mutedText)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    
                                    ScoreRow(title: "Normal", value: "- Rest", color: .yellow)
                                    ScoreRow(title: "Mittel", value: "- ½ Wette", color: .orange)
                                    ScoreRow(title: "Hardcore", value: "- Ganze Wette", color: .red)
                                    
                                    Text("Beispiel: Wette 20, es fehlen noch 7. Normal: -7 Pkt, Mittel: -10 Pkt, Hardcore: -20 Pkt.")
                                        .font(.caption2)
                                        .foregroundStyle(Theme.mutedText)
                                        .padding(.top, 4)
                                        .multilineTextAlignment(.center)
                                }
                                .padding()
                                .background(Color.white.opacity(0.05))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        )
                        .tag(2)

                        // SEITE 4: Einstellungen
                        InfoPage(
                            icon: "slider.horizontal.3",
                            color: .pink,
                            title: "Einstellungen",
                            content: {
                                VStack(alignment: .leading, spacing: 12) {
                                    BulletPoint(text: "Party Modus: Der Timer läuft durch. Ohne Modus startet er bei Treffern neu.", icon: "sparkles")
                                    BulletPoint(text: "Punkte Abzug: Bestimmt das Risiko (Normal, Mittel, Hardcore).", icon: "exclamationmark.circle")
                                    BulletPoint(text: "Kategorien: Wählt Themen wie 'Deep', 'Aktiv' oder 'Buchstaben'.", icon: "square.grid.2x2.fill")
                                }
                            }
                        )
                        .tag(3)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .always))
                    .indexViewStyle(.page(backgroundDisplayMode: .always))
                    
                    // Der "Action Button" unten
                    Button {
                        withAnimation {
                            if currentPage < pageCount - 1 {
                                currentPage += 1
                                HapticsService.impact(.light)
                            } else {
                                HapticsService.impact(.medium)
                                
                                // WICHTIG: Hier speichern wir jetzt, dass das Tutorial erledigt ist!
                                hasSeenOnboarding = true
                                
                                dismiss()
                            }
                        }
                    } label: {
                        let actionTitle: LocalizedStringKey = currentPage == pageCount - 1
                            ? "Alles klar, los geht's!"
                            : "Weiter"
                        Text(actionTitle)
                            .font(.headline)
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(currentPage == pageCount - 1 ? Color.green : Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
                    .padding(.top, 10)
                }
            }
            .navigationTitle("Spielanleitung")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Schließen") { dismiss() }
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            .toolbarBackground(Theme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }
}

// MARK: - Subviews für das Design

// 1. Die generelle Seite (Container)
struct InfoPage<Content: View>: View {
    var icon: String
    var color: Color
    var title: String
    @ViewBuilder var content: Content

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Großes Icon oben
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 90, height: 90)
                    Image(systemName: icon)
                        .font(.system(size: 36))
                        .foregroundStyle(color)
                }
                .padding(.top, 24)

                Text(LocalizedStringKey(title))
                    .font(.title2.bold())
                    .foregroundStyle(.white)

                // Der variable Inhalt
                content
                    .padding(.horizontal, 20)
            }
            .padding(.bottom, 60) // Platz für den Button unten lassen
        }
    }
}

// 2. Ein schöner Listenpunkt mit Icon
struct BulletPoint: View {
    var text: String
    var icon: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .foregroundStyle(.cyan)
                .font(.body)
                .frame(width: 24)
                .padding(.top, 2)
            Text(LocalizedStringKey(text))
                .foregroundStyle(Theme.mutedText)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
    }
}

// 3. Schritte (1., 2., 3.) visuell hervorgehoben
struct StepRow: View {
    var number: Int
    var text: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Text("\(number)")
                .font(.headline)
                .foregroundStyle(.black)
                .frame(width: 28, height: 28)
                .background(Color.white)
                .clipShape(Circle())
            
            Text(LocalizedStringKey(text))
                .font(.body)
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// 4. Punkte-Tabelle Zeile (für Seite 3)
struct ScoreRow: View {
    var title: String
    var value: String
    var color: Color

    var body: some View {
        HStack {
            Text(LocalizedStringKey(title))
                .foregroundStyle(.white)
                .font(.body)
            Spacer()
            Text(LocalizedStringKey(value))
                .font(.headline.bold())
                .foregroundStyle(color)
        }
    }
}
