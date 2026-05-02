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
        case singleDevice
        case multiplayer

        var id: String { rawValue }

        var label: LocalizedStringKey {
            switch self {
            case .singleDevice: return "Ein Gerät"
            case .multiplayer: return "Multiplayer"
            }
        }

        var icon: String {
            switch self {
            case .singleDevice: return "iphone"
            case .multiplayer: return "antenna.radiowaves.left.and.right"
            }
        }
    }

    enum GameMood: String, CaseIterable, Identifiable {
        case funny
        case intense
        case active
        case communication

        var id: String { rawValue }

        var label: LocalizedStringKey {
            switch self {
            case .funny: return "Lustig"
            case .intense: return "Spannend"
            case .active: return "Aktiv"
            case .communication: return "Reden"
            }
        }

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
        let name: LocalizedStringKey
        let description: LocalizedStringKey
        let imageName: String
        let matchScore: Int // 0-100
        let reasons: [LocalizedStringKey]

        var isPlayableNow: Bool { reasons.isEmpty }
    }
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack {
                // 1. HINTERGRUND: MeshGradient (Konsistent mit ContentView)
                if #available(iOS 18.0, *) {
                    MeshGradient(
                        width: 3,
                        height: 3,
                        points: [
                            [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                            [0.0, 0.5], [0.5, 0.5], [1.0, 0.5],
                            [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
                        ],
                        colors: [
                            Color(red: 0.05, green: 0.05, blue: 0.18),
                            Color(red: 0.08, green: 0.05, blue: 0.22),
                            Color(red: 0.05, green: 0.05, blue: 0.18),
                            Color(red: 0.10, green: 0.05, blue: 0.25),
                            Color(red: 0.12, green: 0.08, blue: 0.30),
                            Color(red: 0.08, green: 0.05, blue: 0.20),
                            Color(red: 0.05, green: 0.05, blue: 0.15),
                            Color(red: 0.10, green: 0.08, blue: 0.22),
                            Color(red: 0.05, green: 0.05, blue: 0.15)
                        ]
                    )
                    .ignoresSafeArea()
                } else {
                    LinearGradient(
                        colors: [Color(red: 0.05, green: 0.05, blue: 0.15), Color(red: 0.1, green: 0.1, blue: 0.25)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .ignoresSafeArea()
                }
                
                // 2. Content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 30) {
                        
                        // Header Title
                        Text(LocalizedStringKey("Was spielen wir?"))
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.top)
                            .shadow(color: .cyan.opacity(0.3), radius: 10)
                        
                        // --- CONFIGURATION SECTION ---
                        VStack(spacing: 20) {
                            
                            // Row 1: Player Count & Mode
                            HStack(spacing: 15) {
                                // Player Count
                                GlassBox {
                                    VStack(spacing: 8) {
                                        Text(LocalizedStringKey("Spieler"))
                                            .font(.caption.bold())
                                            .textCase(.uppercase)
                                            .foregroundStyle(.white.opacity(0.5))
                                        
                                        HStack(spacing: 15) {
                                            Button(action: { 
                                                if playerCount > 2 { 
                                                    playerCount -= 1 
                                                    hapticFeedback()
                                                } 
                                            }) {
                                                Image(systemName: "minus.circle.fill")
                                                    .font(.title2)
                                                    .foregroundStyle(.white.opacity(0.6))
                                            }
                                            .accessibilityLabel("Spieleranzahl verringern")
                                            
                                            Text("\(playerCount)")
                                                .font(.system(size: 32, weight: .heavy, design: .rounded))
                                                .foregroundStyle(.white)
                                                .contentTransition(.numericText())
                                            
                                            Button(action: { 
                                                if playerCount < 20 { 
                                                    playerCount += 1 
                                                    hapticFeedback()
                                                } 
                                            }) {
                                                Image(systemName: "plus.circle.fill")
                                                    .font(.title2)
                                                    .foregroundStyle(.white)
                                            }
                                            .accessibilityLabel("Spieleranzahl erhöhen")
                                        }
                                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: playerCount)
                                    }
                                    .padding(.vertical, 12)
                                }
                                
                                // Mode Toggle
                                GlassBox {
                                    VStack(spacing: 8) {
                                        Text(LocalizedStringKey("Modus"))
                                            .font(.caption.bold())
                                            .textCase(.uppercase)
                                            .foregroundStyle(.white.opacity(0.5))
                                        
                                        Picker("Mode", selection: $playMode) {
                                            ForEach(PlayMode.allCases) { mode in
                                                Image(systemName: mode.icon).tag(mode)
                                            }
                                        }
                                        .pickerStyle(.segmented)
                                        .colorScheme(.dark)
                                        
                                        Text(playMode.label)
                                            .font(.caption2.bold())
                                            .foregroundStyle(.white.opacity(0.8))
                                    }
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 4)
                                }
                            }
                            
                            // Row 2: Moods
                            VStack(alignment: .leading, spacing: 10) {
                                Text(LocalizedStringKey("Vibe"))
                                    .font(.caption.bold())
                                    .textCase(.uppercase)
                                    .foregroundStyle(.white.opacity(0.5))
                                    .padding(.leading, 4)
                                
                                HStack(spacing: 10) {
                                    ForEach(GameMood.allCases) { m in
                                        MoodButton(mood: m, isSelected: mood == m) {
                                            mood = m
                                            hapticFeedback()
                                        }
                                    }
                                }
                            }
                            
                            // Row 3: Time
                            VStack(alignment: .leading, spacing: 10) {
                                Text(LocalizedStringKey("Zeit"))
                                    .font(.caption.bold())
                                    .textCase(.uppercase)
                                    .foregroundStyle(.white.opacity(0.5))
                                    .padding(.leading, 4)
                                
                                HStack(spacing: 10) {
                                    ForEach(TimeCategory.allCases) { t in
                                        TimeButton(time: t, isSelected: timeCategory == t) {
                                            timeCategory = t
                                            hapticFeedback()
                                        }
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(.ultraThinMaterial.opacity(0.5), in: RoundedRectangle(cornerRadius: 24))
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
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
                                    .transition(.asymmetric(insertion: .scale.combined(with: .opacity), removal: .opacity))
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
                                        // Invisible Spacer at the end to help with scroll hint (DAU-friendly)
                                        Spacer().frame(width: 20)
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: mood)
                        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: playerCount)
                        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: timeCategory)
                        
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
    
    private func hapticFeedback() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    
    @ViewBuilder
    static func destination(for gameId: String) -> some View {
        switch gameId {
        case "BetBuddy": BetBuddyWrapper()
        case "Imposter": ImposterGameWrapper()
        case "TimesUp": TimesUpWrapper()
        case "Question": QuestionGameWrapper()
        default: EmptyView()
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
        
        func reasonsForGame(minPlayers: Int, maxPlayers: Int? = nil, minMinutes: Int? = nil, supportsMultiplayer: Bool) -> [LocalizedStringKey] {
            var reasons: [LocalizedStringKey] = []
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
        
        // 1. Ich biete mehr!
        var betScore = 70
        if players >= 2 && players <= 8 { betScore += 20 }
        if mood == .communication || mood == .funny { betScore += 15 }
        if isMultiplayer { betScore -= 100 } // Hard exclude for multiplayer preference
        
        let betReasons = reasonsForGame(minPlayers: 2, maxPlayers: 8, supportsMultiplayer: false)
        if !betReasons.isEmpty { betScore = 10 } // Penalize hard if rules broken
        
        list.append(GameRecommendation(
            id: "BetBuddy",
            name: "Ich biete mehr!",
            description: "Wettet aufeinander. Wer kennt die Gruppe am besten?",
            imageName: "BetBuddyIcon",
            matchScore: clampScore(betScore),
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
            .background(.ultraThinMaterial.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
    }
}

struct MoodButton: View {
    let mood: GameRecommenderView.GameMood
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text(mood.emoji)
                    .font(.largeTitle)
                Text(mood.label)
                    .font(.caption2.bold())
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? mood.color.opacity(0.3) : Color.white.opacity(0.05))
            .background(isSelected ? AnyShapeStyle(.ultraThinMaterial) : AnyShapeStyle(Color.clear))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? mood.color : Color.white.opacity(0.1), lineWidth: isSelected ? 2 : 1)
            )
            .foregroundStyle(.white)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
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
                .font(.subheadline.bold())
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(isSelected ? Color.white : Color.white.opacity(0.05))
                .foregroundStyle(isSelected ? .black : .white.opacity(0.8))
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.1), lineWidth: isSelected ? 0 : 1)
                )
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
    }
}

struct HeroRecommendationCard: View {
    let game: GameRecommenderView.GameRecommendation
    
    var body: some View {
        NavigationLink(destination: GameRecommenderView.destination(for: game.id)) {
            VStack(alignment: .leading, spacing: 16) {
                // Top Badge
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .foregroundStyle(.yellow)
                        Text("\(game.matchScore)% Match")
                            .font(.subheadline.bold())
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.3), in: Capsule())
                    
                    Spacer()
                    
                    if !game.isPlayableNow {
                        HStack(spacing: 4) {
                            Image(systemName: "info.circle.fill")
                            Text(LocalizedStringKey("Bedingungen prüfen"))
                        }
                        .font(.caption.bold())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.red.opacity(0.8), in: Capsule())
                        .foregroundStyle(.white)
                    }
                }
                
                HStack(alignment: .center, spacing: 16) {
                    Image(game.imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 70, height: 70)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .black.opacity(0.2), radius: 8)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(game.name)
                            .font(.title3.bold())
                            .foregroundStyle(.white)
                        
                        Text(game.description)
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.7))
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)
                    }
                }
                
                if !game.reasons.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(Array(game.reasons.enumerated()), id: \.offset) { _, reason in
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.caption)
                                    .foregroundStyle(.yellow)
                                Text(reason)
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.9))
                            }
                        }
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.black.opacity(0.2), in: RoundedRectangle(cornerRadius: 12))
                }
                
                HStack {
                    Text(LocalizedStringKey("Jetzt Starten"))
                        .font(.headline)
                    Image(systemName: "play.fill")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(game.isPlayableNow ? Color.white : Color.white.opacity(0.1))
                .foregroundStyle(game.isPlayableNow ? Color(red: 0.1, green: 0.1, blue: 0.3) : .white.opacity(0.3))
                .clipShape(Capsule())
                .shadow(color: game.isPlayableNow ? .white.opacity(0.2) : .clear, radius: 10)
            }
            .padding(20)
            .background(
                LinearGradient(colors: [Color.cyan.opacity(0.3), Color.blue.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 28))
            .overlay(
                RoundedRectangle(cornerRadius: 28)
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
            )
            .padding(.horizontal)
        }
        .disabled(!game.isPlayableNow)
    }
}

struct SmallRecommendationCard: View {
    let game: GameRecommenderView.GameRecommendation
    
    var body: some View {
        NavigationLink(destination: GameRecommenderView.destination(for: game.id)) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(game.imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 44, height: 44)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    Spacer()
                    Text("\(game.matchScore)%")
                        .font(.system(.caption, design: .rounded).bold())
                        .foregroundStyle(game.matchScore > 50 ? .green : .orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.black.opacity(0.2), in: Capsule())
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(game.name)
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    
                    Text(game.description)
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.5))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
            }
            .padding(14)
            .frame(width: 150, height: 130)
            .background(.ultraThinMaterial.opacity(0.3), in: RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
    }
}
