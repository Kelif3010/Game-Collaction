import SwiftUI

struct GameRecommenderView: View {
    @Environment(\.dismiss) var dismiss
    
    @State private var playerCount: Double = 4
    @State private var timeAvailable: Double = 15 // Minuten
    @State private var mood: GameMood = .funny
    
    enum GameMood: String, CaseIterable, Identifiable {
        case funny = "Lustig"
        case intense = "Spannend"
        case active = "Aktiv"
        case communication = "Reden"
        
        var id: String { rawValue }
    }
    
    struct GameRecommendation: Identifiable {
        let id = UUID()
        let name: String
        let description: String
        let imageName: String
        let matchScore: Int // 0-100
        let targetView: AnyView
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    Text(LocalizedStringKey("Finde das perfekte Spiel"))
                        .font(.title2.bold())
                        .multilineTextAlignment(.center)
                        .padding(.top)
                    
                    // Filter: Spieleranzahl
                    VStack(alignment: .leading) {
                        Text(LocalizedStringKey("Wie viele seid ihr?"))
                            .font(.headline)
                        HStack {
                            Image(systemName: "person.2.fill")
                            Slider(value: $playerCount, in: 2...12, step: 1)
                            Text("\(Int(playerCount))")
                                .font(.title3.bold())
                                .frame(width: 40)
                        }
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(12)
                    
                    // Filter: Zeit
                    VStack(alignment: .leading) {
                        Text(LocalizedStringKey("Wie viel Zeit habt ihr?"))
                            .font(.headline)
                        HStack {
                            Image(systemName: "clock.fill")
                            Slider(value: $timeAvailable, in: 5...60, step: 5)
                            Text("\(Int(timeAvailable)) min")
                                .font(.subheadline.bold())
                                .frame(width: 60)
                        }
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(12)
                    
                    // Filter: Stimmung
                    VStack(alignment: .leading) {
                        Text(LocalizedStringKey("Worauf habt ihr Lust?"))
                            .font(.headline)
                        Picker("", selection: $mood) {
                            ForEach(GameMood.allCases) { mood in
                                Text(LocalizedStringKey(mood.rawValue)).tag(mood)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding()
                    
                    Divider()
                    
                    // Ergebnisse
                    Text(LocalizedStringKey("Vorschläge"))
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    ForEach(recommendations) { game in
                        NavigationLink(destination: game.targetView) {
                            HStack {
                                Image(game.imageName) // Placeholder check needed
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 60, height: 60)
                                    .cornerRadius(10)
                                    .padding(4)
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(12)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(game.name)
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        Spacer()
                                        Text("\(game.matchScore)% Match")
                                            .font(.caption)
                                            .foregroundColor(.green)
                                            .padding(4)
                                            .background(Color.green.opacity(0.1))
                                            .cornerRadius(6)
                                    }
                                    Text(game.description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.leading)
                                }
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            .background(Color.secondary.opacity(0.05))
                            .cornerRadius(16)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle(LocalizedStringKey("Spiele-Berater"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(LocalizedStringKey("Schließen")) {
                        dismiss()
                    }
                }
            }
        }
    }
    
    var recommendations: [GameRecommendation] {
        var list: [GameRecommendation] = []
        let players = Int(playerCount)
        let mins = Int(timeAvailable)
        
        // --- LOGIK ---
        
        // 1. Bet Buddy
        // Gut für 2-8 Leute, schnell oder lang, Lustig/Kommunikation
        var betScore = 70
        if players >= 2 && players <= 8 { betScore += 20 }
        if mood == .communication || mood == .funny { betScore += 10 }
        // Bet Buddy passt fast immer
        list.append(GameRecommendation(
            name: "Bet Buddy",
            description: "Wettet aufeinander. Wer kennt die Gruppe am besten?",
            imageName: "BetBuddyIcon", // Placeholder Name
            matchScore: betScore,
            targetView: AnyView(BetBuddyWrapper())
        ))
        
        // 2. Imposter
        // Braucht mind 3 Leute (besser 4+), intensiv/spannend/reden
        var impScore = 0
        if players >= 3 {
            impScore = 60
            if players >= 5 { impScore += 20 } // Perfekt für 5-8
            if mood == .intense || mood == .communication { impScore += 15 }
            if mins < 10 { impScore -= 20 } // Zu kurz für gute Runden
        }
        if impScore > 0 {
            list.append(GameRecommendation(
                name: "Imposter",
                description: "Finde den Spion, bevor die Zeit abläuft!",
                imageName: "ImposterIcon",
                matchScore: impScore,
                targetView: AnyView(ImposterGameWrapper())
            ))
        }
        
        // 3. TimesUp
        // Braucht Teams (mind 4 Leute), Aktiv/Lustig, Dauert länger
        var timeScore = 0
        if players >= 4 {
            timeScore = 50
            if players >= 6 { timeScore += 20 }
            if mins >= 20 { timeScore += 20 } else { timeScore -= 30 }
            if mood == .active || mood == .funny { timeScore += 10 }
        }
        if timeScore > 0 {
            list.append(GameRecommendation(
                name: "Time's Up",
                description: "Erklären, Pantomime, Zeichnen. Chaos garantiert.",
                imageName: "TimesUpIcon",
                matchScore: timeScore,
                targetView: AnyView(TimesUpWrapper())
            ))
        }
        
        // 4. Question
        // Gut für 3+, Reden/Deep
        var questScore = 50
        if players >= 3 { questScore += 10 }
        if mood == .communication { questScore += 30 }
        list.append(GameRecommendation(
            name: "Question",
            description: "Spannende Fragen, um euch besser kennenzulernen.",
            imageName: "QuestionIcon",
            matchScore: questScore,
            targetView: AnyView(QuestionGameWrapper())
        ))
        
        return list.sorted { $0.matchScore > $1.matchScore }
    }
}

// Fallback Wrappers need simple init or usage
// Assuming Wrappers exist as per file list, but ensure they don't require params in init or have defaults.
// BetBuddyWrapper, ImposterGameWrapper, TimesUpWrapper seem to exist.
