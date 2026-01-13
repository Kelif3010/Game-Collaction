import SwiftUI

struct GameRecommenderView: View {
    @Environment(\.dismiss) var dismiss
    
    // MARK: - State
    @State private var playerCount: Int = 4
    @State private var timeCategory: TimeCategory = .medium
    @State private var mood: GameMood = .funny
    @State private var playMode: PlayMode = .singleDevice
    
    // MARK: - Definitions
    enum PlayMode: String, CaseIterable, Identifiable {
        case singleDevice = "Ein Gerät"
        case multiplayer = "Multiplayer"
        var id: String { rawValue }
        
        var icon: String {
            switch self {
            case .singleDevice: return "iphone"
            case .multiplayer: return "antenna.radiowaves.left.and.right"
            }
        }
    }
    
    enum GameMood: String, CaseIterable, Identifiable {
        case funny = "Lustig"
        case intense = "Spannend"
        case active = "Aktiv"
        case communication = "Reden"
        
        var id: String { rawValue }
        
        var emoji: String {
            switch self {
            case .funny: return "😂"
            case .intense: return "🔥"
            case .active: return "🏃"
            case .communication: return "💬"
            }
        }
        
        var color: Color {
            switch self {
            case .funny: return .yellow
            case .intense: return .red
            case .active: return .green
            case .communication: return .blue
            }
        }
    }
    
    enum TimeCategory: Int, CaseIterable, Identifiable {
        case short = 5
        case medium = 20
        case long = 45
        
        var id: Int { rawValue }
        
        var label: LocalizedStringKey {
            switch self {
            case .short: return "Schnell (5m)"
            case .medium: return "Mittel (20m)"
            case .long: return "Lang (45m+)"
            }
        }
    }
    
    struct GameRecommendation: Identifiable {
        let id: String
        let name: String
        let description: String
        let imageName: String
        let matchScore: Int // 0-100
        let targetView: AnyView
        let reasons: [String]
        
        var isPlayableNow: Bool { reasons.isEmpty }
    }
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack {
                // 1. Background
                LinearGradient(
                    colors: [Color.indigo.opacity(0.8), Color.purple.opacity(0.6), Color.black],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // 2. Content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 30) {
                        
                        // Header Title
                        Text(LocalizedStringKey("Was spielen wir?"))
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.top)
                            .shadow(color: .purple, radius: 10)
                        
                        // --- CONFIGURATION SECTION ---
                        VStack(spacing: 20) {
                            
                            // Row 1: Player Count & Mode
                            HStack(spacing: 15) {
                                // Player Count
                                GlassBox {
                                    VStack(spacing: 8) {
                                        Text(LocalizedStringKey("Spieler"))
                                            .font(.caption)
                                            .textCase(.uppercase)
                                            .foregroundStyle(.white.opacity(0.7))
                                        
                                        HStack(spacing: 15) {
                                            Button(action: { if playerCount > 2 { playerCount -= 1 } }) {
                                                Image(systemName: "minus.circle.fill")
                                                    .font(.title2)
                                                    .foregroundStyle(.white.opacity(0.8))
                                            }
                                            
                                            Text("\(playerCount)")
                                                .font(.system(size: 32, weight: .heavy, design: .rounded))
                                                .foregroundStyle(.white)
                                                .contentTransition(.numericText())
                                            
                                            Button(action: { if playerCount < 20 { playerCount += 1 } }) {
                                                Image(systemName: "plus.circle.fill")
                                                    .font(.title2)
                                                    .foregroundStyle(.white)
                                            }
                                        }
                                        .animation(.spring, value: playerCount)
                                    }
                                    .padding(.vertical, 10)
                                }
                                
                                // Mode Toggle
                                GlassBox {
                                    VStack(spacing: 8) {
                                        Text(LocalizedStringKey("Modus"))
                                            .font(.caption)
                                            .textCase(.uppercase)
                                            .foregroundStyle(.white.opacity(0.7))
                                        
                                        Picker("Mode", selection: $playMode) {
                                            ForEach(PlayMode.allCases) { mode in
                                                Image(systemName: mode.icon).tag(mode)
                                            }
                                        }
                                        .pickerStyle(.segmented)
                                        .colorScheme(.dark) // Force dark appearance for picker
                                        
                                        Text(LocalizedStringKey(playMode.rawValue))
                                            .font(.caption2)
                                            .foregroundStyle(.white)
                                    }
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 4)
                                }
                            }
                            
                            // Row 2: Moods
                            VStack(alignment: .leading, spacing: 10) {
                                Text(LocalizedStringKey("Vibe"))
                                    .font(.caption)
                                    .textCase(.uppercase)
                                    .foregroundStyle(.white.opacity(0.7))
                                    .padding(.leading, 4)
                                
                                HStack(spacing: 10) {
                                    ForEach(GameMood.allCases) { m in
                                        MoodButton(mood: m, isSelected: mood == m) {
                                            mood = m
                                        }
                                    }
                                }
                            }
                            
                            // Row 3: Time
                            VStack(alignment: .leading, spacing: 10) {
                                Text(LocalizedStringKey("Zeit"))
                                    .font(.caption)
                                    .textCase(.uppercase)
                                    .foregroundStyle(.white.opacity(0.7))
                                    .padding(.leading, 4)
                                
                                HStack(spacing: 10) {
                                    ForEach(TimeCategory.allCases) { t in
                                        TimeButton(time: t, isSelected: timeCategory == t) {
                                            timeCategory = t
                                        }
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(24)
                        .padding(.horizontal)
                        
                        // --- RESULTS SECTION ---
                        
                        VStack(spacing: 20) {
                            if let bestMatch = bestMatch {
                                Text(LocalizedStringKey("Bester Treffer"))
                                    .font(.headline)
                                    .foregroundStyle(.white.opacity(0.8))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal)
                                
                                HeroRecommendationCard(game: bestMatch)
                                    .transition(.scale.combined(with: .opacity))
                            } else {
                                Text(LocalizedStringKey("Kein perfekter Treffer..."))
                                    .foregroundStyle(.white.opacity(0.6))
                            }
                            
                            if !alternatives.isEmpty {
                                Text(LocalizedStringKey("Alternativen"))
                                    .font(.headline)
                                    .foregroundStyle(.white.opacity(0.8))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal)
                                    .padding(.top)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 15) {
                                        ForEach(alternatives) { game in
                                            SmallRecommendationCard(game: game)
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                        .animation(.spring(), value: mood)
                        .animation(.spring(), value: playerCount)
                        .animation(.spring(), value: timeCategory)
                        
                        Spacer(minLength: 50)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(LocalizedStringKey("Schließen")) {
                        dismiss()
                    }
                    .foregroundStyle(.white)
                }
            }
        }
    }
    
    // MARK: - Logic Helpers
    
    var bestMatch: GameRecommendation? {
        recommendations.first
    }
    
    var alternatives: [GameRecommendation] {
        Array(recommendations.dropFirst())
    }
    
    var recommendations: [GameRecommendation] {
        var list: [GameRecommendation] = []
        let players = playerCount
        let mins = timeCategory.rawValue
        let isMultiplayer = playMode == .multiplayer
        
        func clampScore(_ score: Int) -> Int {
            min(max(score, 0), 100)
        }
        
        func reasonsForGame(minPlayers: Int, maxPlayers: Int? = nil, minMinutes: Int? = nil, supportsMultiplayer: Bool) -> [String] {
            var reasons: [String] = []
            if isMultiplayer && !supportsMultiplayer {
                reasons.append("Nur 1 Gerät")
            }
            if players < minPlayers {
                reasons.append("Braucht \(minPlayers)+ Spieler")
            }
            if let maxPlayers, players > maxPlayers {
                reasons.append("Max \(maxPlayers) Spieler")
            }
            if let minMinutes, mins < minMinutes {
                reasons.append("Dauert länger (\(minMinutes)+ min)")
            }
            return reasons
        }
        
        // --- LOGIC ---
        
        // 1. Bet Buddy
        var betScore = 70
        if players >= 2 && players <= 8 { betScore += 20 }
        if mood == .communication || mood == .funny { betScore += 15 }
        if isMultiplayer { betScore -= 100 } // Hard exclude for multiplayer preference
        
        let betReasons = reasonsForGame(minPlayers: 2, maxPlayers: 8, supportsMultiplayer: false)
        if !betReasons.isEmpty { betScore = 10 } // Penalize hard if rules broken
        
        list.append(GameRecommendation(
            id: "BetBuddy",
            name: "Bet Buddy",
            description: "Wettet aufeinander. Wer kennt die Gruppe am besten?",
            imageName: "BetBuddyIcon",
            matchScore: clampScore(betScore),
            targetView: AnyView(BetBuddyWrapper()),
            reasons: betReasons
        ))
        
        // 2. Imposter
        let imposterMinPlayers = isMultiplayer ? 2 : 4
        var impScore = 60
        if players >= imposterMinPlayers { impScore += 10 }
        if players >= 5 && players <= 8 { impScore += 20 }
        if mood == .intense || mood == .communication { impScore += 20 }
        if mins < 10 { impScore -= 20 }
        
        let impReasons = reasonsForGame(minPlayers: imposterMinPlayers, minMinutes: 10, supportsMultiplayer: true)
        if !impReasons.isEmpty { impScore = 10 }
        
        list.append(GameRecommendation(
            id: "Imposter",
            name: "Imposter",
            description: "Findet den Spion, bevor die Zeit abläuft!",
            imageName: "ImposterIcon",
            matchScore: clampScore(impScore),
            targetView: AnyView(ImposterGameWrapper()),
            reasons: impReasons
        ))
        
        // 3. TimesUp
        var timeScore = 50
        if players >= 4 { timeScore += 20 }
        if mins >= 20 { timeScore += 15 } else { timeScore -= 20 }
        if mood == .active || mood == .funny { timeScore += 15 }
        if isMultiplayer { timeScore -= 100 }
        
        let timeReasons = reasonsForGame(minPlayers: 4, minMinutes: 20, supportsMultiplayer: false)
        if !timeReasons.isEmpty { timeScore = 10 }
        
        list.append(GameRecommendation(
            id: "TimesUp",
            name: "Time's Up",
            description: "Erklären, Pantomime, Zeichnen. Pures Chaos.",
            imageName: "TimesUpIcon",
            matchScore: clampScore(timeScore),
            targetView: AnyView(TimesUpWrapper()),
            reasons: timeReasons
        ))
        
        // 4. Question
        var questScore = 50
        if players >= 3 { questScore += 15 }
        if mood == .communication { questScore += 30 }
        if isMultiplayer { questScore -= 100 }
        
        let questReasons = reasonsForGame(minPlayers: 3, supportsMultiplayer: false)
        if !questReasons.isEmpty { questScore = 10 }
        
        list.append(GameRecommendation(
            id: "Question",
            name: "Question",
            description: "Deep Talk oder lustige Fragen.",
            imageName: "QuestionIcon",
            matchScore: clampScore(questScore),
            targetView: AnyView(QuestionGameWrapper()),
            reasons: questReasons
        ))
        
        return list.sorted { $0.matchScore > $1.matchScore }
    }
}

// MARK: - Custom Subviews

struct GlassBox<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .frame(maxWidth: .infinity)
            .background(Color.white.opacity(0.1))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
    }
}

struct MoodButton: View {
    let mood: GameRecommenderView.GameMood
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                Text(mood.emoji)
                    .font(.largeTitle)
                Text(LocalizedStringKey(mood.rawValue))
                    .font(.caption2)
                    .fontWeight(.bold)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? mood.color.opacity(0.8) : Color.white.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.white : Color.clear, lineWidth: 2)
            )
            .foregroundColor(.white)
            .animation(.spring(), value: isSelected)
        }
    }
}

struct TimeButton: View {
    let time: GameRecommenderView.TimeCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(time.label)
                .font(.subheadline)
                .fontWeight(isSelected ? .bold : .regular)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(isSelected ? Color.white : Color.white.opacity(0.1))
                .foregroundColor(isSelected ? .black : .white)
                .cornerRadius(20)
                .animation(.spring(), value: isSelected)
        }
    }
}

struct HeroRecommendationCard: View {
    let game: GameRecommenderView.GameRecommendation
    
    var body: some View {
        NavigationLink(destination: game.targetView) {
            VStack(alignment: .leading, spacing: 12) {
                // Top Badge
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                    Text("\(game.matchScore)% Match")
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                    Spacer()
                    if !game.isPlayableNow {
                        Text(LocalizedStringKey("Bedingungen prüfen"))
                            .font(.caption)
                            .padding(6)
                            .background(Color.red.opacity(0.8))
                            .cornerRadius(6)
                            .foregroundStyle(.white)
                    }
                }
                
                HStack(alignment: .top) {
                    Image(game.imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .cornerRadius(16)
                        .shadow(radius: 5)
                    
                    VStack(alignment: .leading) {
                        Text(game.name)
                            .font(.title2.bold())
                            .foregroundStyle(.white)
                        
                        Text(game.description)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.8))
                            .multilineTextAlignment(.leading)
                            .lineLimit(3)
                    }
                }
                
                if !game.reasons.isEmpty {
                    VStack(alignment: .leading) {
                        ForEach(game.reasons, id: \.self) { reason in
                            HStack {
                                Image(systemName: "exclamationmark.triangle")
                                    .foregroundColor(.orange)
                                Text(reason)
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.9))
                            }
                        }
                    }
                    .padding(8)
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(8)
                }
                
                HStack {
                    Text(LocalizedStringKey("Jetzt Starten"))
                        .fontWeight(.bold)
                    Image(systemName: "play.circle.fill")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(game.isPlayableNow ? Color.white : Color.gray)
                .foregroundColor(game.isPlayableNow ? .indigo : .white)
                .cornerRadius(14)
                .padding(.top, 4)
            }
            .padding(20)
            .background(
                LinearGradient(colors: [Color.indigo, Color.purple], startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .cornerRadius(24)
            .shadow(color: .indigo.opacity(0.5), radius: 15, x: 0, y: 10)
            .padding(.horizontal)
        }
        .disabled(!game.isPlayableNow)
        .opacity(game.isPlayableNow ? 1 : 0.8)
    }
}

struct SmallRecommendationCard: View {
    let game: GameRecommenderView.GameRecommendation
    
    var body: some View {
        NavigationLink(destination: game.targetView) {
            VStack(alignment: .leading) {
                HStack {
                    Image(game.imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                        .cornerRadius(8)
                    Spacer()
                    Text("\(game.matchScore)%")
                        .font(.caption.bold())
                        .foregroundStyle(game.matchScore > 50 ? .green : .orange)
                }
                
                Text(game.name)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                
                Text(game.description)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.7))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            .padding()
            .frame(width: 160, height: 140)
            .background(Color.white.opacity(0.1))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
    }
}
