import SwiftUI
import Combine

struct InfoTickerView: View {
    @ObservedObject var statsManager = GlobalStatsManager.shared
    
    // Animation State
    @State private var offset: CGFloat = 0
    @State private var textWidth: CGFloat = 0
    @State private var containerWidth: CGFloat = 0
    @State private var tickerText: String = ""
    
    // Timer für flüssige 60fps Animation
    let timer = Timer.publish(every: 0.016, on: .main, in: .common).autoconnect()
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Hintergrund: Moderner "Breaking News" Look
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.black.opacity(0.8), Color(red: 0.1, green: 0.1, blue: 0.3).opacity(0.9), Color.black.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .overlay(
                        Rectangle()
                            .stroke(LinearGradient(colors: [.clear, .white.opacity(0.2), .clear], startPoint: .leading, endPoint: .trailing), lineWidth: 1)
                    )
                
                // Der scrollende Text
                Text(tickerText)
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
                    .shadow(color: .cyan.opacity(0.6), radius: 3, x: 0, y: 0)
                    .padding(.horizontal, 20) // Abstand damit Text nicht klebt
                    .fixedSize() // Verhindert Umbruch
                    .background(GeometryReader { textGeo in
                        Color.clear.onAppear {
                            textWidth = textGeo.size.width
                        }
                        .onChange(of: tickerText) { _ in
                            textWidth = textGeo.size.width
                        }
                    })
                    .offset(x: offset, y: 0)
                    .onAppear {
                        containerWidth = geo.size.width
                        offset = containerWidth // Start ganz rechts außen
                        updateTickerContent() // Text beim Start generieren
                    }
            }
            .clipped()
            .onReceive(timer) { _ in
                animateTicker()
            }
            .onChange(of: geo.size.width) { newWidth in
                containerWidth = newWidth
            }
        }
        .frame(height: 32) // Etwas kompakter
    }
    
    private func animateTicker() {
        // Bewegung nach links
        if textWidth > 0 {
            offset -= 1.2 // Geschwindigkeit
            
            // Wenn Text komplett links raus ist -> Reset nach rechts
            // Fix: Wir setzen ihn auf containerWidth (Bildschirmbreite), damit er von rechts reinläuft
            if offset < -textWidth {
                offset = containerWidth
                // Optional: Text aktualisieren, wenn er einmal durch ist
                updateTickerContent()
            }
        }
    }
    
    // MARK: - Content Generation
    
    private func updateTickerContent() {
        var parts: [String] = []
        let players = statsManager.stats.values.map { $0 }
        let playerNames = players.map { $0.name }
        let playedGames = statsManager.playedGameIDs
        
        // --- 1. ECHTE STATS (Real Data) ---
        // Diese werden immer angezeigt, wenn Daten vorhanden sind
        
        // Session King
        if let king = statsManager.sessionKing {
            parts.append("👑 KING: \(king.name.uppercased()) (\(king.wins) Wins)")
        }
        
        // Win Rate (Präzision)
        if let bestRate = players.filter({ $0.timesPlayed > 2 }).max(by: { $0.winRate < $1.winRate }), bestRate.winRate > 0.6 {
            parts.append("🎯 PRÄZISION: \(bestRate.name.uppercased()) gewinnt \(Int(bestRate.winRate * 100))% der Spiele!")
        }
        
        // Veteran (Vielspieler)
        if let veteran = players.max(by: { $0.timesPlayed < $1.timesPlayed }), veteran.timesPlayed > 4 {
            parts.append("🎖 VETERAN: \(veteran.name.uppercased()) hat heute \(veteran.timesPlayed) Runden absolviert!")
        }
        
        // Pechvogel / Eiskalt
        if let loser = players.filter({ $0.losses > 2 }).max(by: { $0.losses < $1.losses }) {
            parts.append("🧊 EISKALT: \(loser.name.uppercased()) wartet auf den Sieg...")
        }
        
        // --- 2. GAME SPECIFIC (Flavor/Mock Data) - CONTEXT AWARE ---
        // Wir zeigen nur Texte zu Spielen, die auch gestartet wurden
        
        if playedGames.contains("Imposter"), let randomP = playerNames.randomElement() {
            let imposters = [
                "🕵️ MASTERMIND: \(randomP) gewinnt 80% als Imposter!",
                "☠️ FIRST TARGET: \(randomP) wird oft zuerst rausgewählt.",
                "👀 UNSCHULDIG?: \(randomP) war heute noch kein Imposter..."
            ]
            parts.append(imposters.randomElement()!)
        }
        
        if playedGames.contains("BetBuddy"), let randomP = playerNames.randomElement() {
            let betBuddy = [
                "💸 HIGH ROLLER: \(randomP) bietet am höchsten.",
                "🏋️ CARRY: \(randomP) hat noch keine Challenge vermasselt.",
                "❤️ DREAM TEAM: \(randomP) harmoniert perfekt!"
            ]
            parts.append(betBuddy.randomElement()!)
        }
        
        if playedGames.contains("TimesUp"), let randomP = playerNames.randomElement() {
            let timesUp = [
                "⚡️ BLITZ: \(randomP) schafft 5 Begriffe pro Minute!",
                "⏭ SKIP KING: \(randomP) überspringt 40% der Karten.",
                "🧠 WIKI: Team \(randomP) kennt alle Begriffe."
            ]
            parts.append(timesUp.randomElement()!)
        }
        
        if playedGames.contains("Question"), let randomP = playerNames.randomElement() {
            let liar = [
                "🤥 PINOCCHIO: \(randomP) fliegt beim Lügen oft auf.",
                "🤫 MYSTERY: Bei \(randomP) tappen alle im Dunkeln."
            ]
            parts.append(liar.randomElement()!)
        }
        
        // --- 3. FALLBACK (Wenn noch nichts gespielt wurde) ---
        if playedGames.isEmpty {
            let intros = [
                "👋 WILLKOMMEN! Wer holt sich heute den Sieg?",
                "🎮 WÄHLE EIN SPIEL: Bet Buddy, Imposter oder Time's Up?",
                "🏆 STATISTIK: Wir tracken jeden Sieg live mit!"
            ]
            parts.append(intros.randomElement()!)
        }
        
        // --- 4. ALLGEMEINES (Filler) ---
        if !playedGames.isEmpty {
            let filler = [
                "💤 SCHLÄFER: Wer wacht als nächstes auf?",
                "⚔️ RIVALITÄT: Es wird persönlich!",
                "🏅 RECAP: Die letzte Runde war intensiv."
            ]
            parts.append(filler.randomElement()!)
        }

        // Zusammenbauen mit Trenner (wenn leer, Standardtext)
        if parts.isEmpty {
            tickerText = "Games Collection +++ Ready to Play +++"
        } else {
            tickerText = parts.joined(separator: "   +++   ") + "   +++   "
        }
    }
}

#Preview {
    ZStack {
        Color.black
        InfoTickerView()
    }
}
