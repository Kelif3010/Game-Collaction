import SwiftUI
import Pow
import SFSafeSymbols

struct GameRecommenderView: View {
    @Environment(\.dismiss) var dismiss
    @Namespace private var glassNamespace
    
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
        let icon: String
        let iconTint: Color
        let matchScore: Int // 0-100
        let reasons: [LocalizedStringKey]

        var isPlayableNow: Bool { reasons.isEmpty }
    }
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack {
                // 1. HINTERGRUND: MeshGradient (Konsistent mit ContentView)
                recommenderBackground
                
                // 2. Content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 30) {
                        
                        // Header Title
                        Text("Was spielen wir?")
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
                                        Text("Spieler")
                                            .font(.caption.bold())
                                            .textCase(.uppercase)
                                            .foregroundStyle(.white.opacity(0.5))
                                        
                                        HStack(spacing: 15) {
                                            Button(action: { 
                                                if playerCount > 2 { 
                                                    playerCount -= 1 
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
                                        Text("Modus")
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
                                Text("Vibe")
                                    .font(.caption.bold())
                                    .textCase(.uppercase)
                                    .foregroundStyle(.white.opacity(0.5))
                                    .padding(.leading, 4)
                                
                                moodButtons
                            }
                            
                            // Row 3: Time
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Zeit")
                                    .font(.caption.bold())
                                    .textCase(.uppercase)
                                    .foregroundStyle(.white.opacity(0.5))
                                    .padding(.leading, 4)
                                
                                timeButtons
                            }
                        }
                        .padding()
                        .liquidGlass(cornerRadius: 24, tint: .white.opacity(0.04))
                        .padding(.horizontal)
                        
                        // --- RESULTS SECTION ---
                        
                        VStack(spacing: 20) {
                            if let bestMatch = bestMatch {
                                Text("Bester Treffer")
                                    .font(.headline)
                                    .foregroundStyle(.white.opacity(0.8))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal)
                                
                                HeroRecommendationCard(game: bestMatch)
                                    .transition(.blurReplace)
                            } else {
                                Text("Kein perfekter Treffer...")
                                    .foregroundStyle(.white.opacity(0.6))
                            }
                            
                            if !alternatives.isEmpty {
                                Text("Alternativen")
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
                .softScrollEdges()
            }
            .sensoryFeedback(.selection, trigger: mood)
            .sensoryFeedback(.selection, trigger: timeCategory)
            .sensoryFeedback(.impact(weight: .light), trigger: playerCount)
            .sensoryFeedback(.selection, trigger: playMode)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    RecommenderCloseButton(action: dismiss.callAsFunction)
                }
            }
        }
    }

    private var recommenderBackground: some View {
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
    }

    @ViewBuilder
    private var moodButtons: some View {
        if #available(iOS 26.0, *) {
            GlassEffectContainer(spacing: 10) {
                HStack(spacing: 10) {
                    ForEach(GameMood.allCases) { m in
                        MoodButton(mood: m, isSelected: mood == m) {
                            selectMood(m)
                        }
                        .glassEffectID(m.id, in: glassNamespace)
                    }
                }
            }
        } else {
            HStack(spacing: 10) {
                ForEach(GameMood.allCases) { m in
                    MoodButton(mood: m, isSelected: mood == m) {
                        selectMood(m)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var timeButtons: some View {
        if #available(iOS 26.0, *) {
            GlassEffectContainer(spacing: 10) {
                HStack(spacing: 10) {
                    ForEach(TimeCategory.allCases) { t in
                        TimeButton(time: t, isSelected: timeCategory == t) {
                            selectTime(t)
                        }
                        .glassEffectID("time-\(t.id)", in: glassNamespace)
                    }
                }
            }
        } else {
            HStack(spacing: 10) {
                ForEach(TimeCategory.allCases) { t in
                    TimeButton(time: t, isSelected: timeCategory == t) {
                        selectTime(t)
                    }
                }
            }
        }
    }

    private func selectMood(_ newMood: GameMood) {
        withAnimation(.spring(response: 0.32, dampingFraction: 0.75)) {
            mood = newMood
        }
    }

    private func selectTime(_ newTime: TimeCategory) {
        withAnimation(.spring(response: 0.32, dampingFraction: 0.75)) {
            timeCategory = newTime
        }
    }
    
    @ViewBuilder
    static func destination(for gameId: String) -> some View {
        switch gameId {
        case "BetBuddy": BetBuddyWrapper()
        case "Imposter": ImposterGameWrapper()
        case "TimesUp": TimesUpWrapper()
        case "Question": QuestionGameWrapper()
        case "SoundCinema": SoundCinemaWrapper()
        case "FalscheFaehrte": FalscheFaehrteWrapper()
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
        
        // --- LOGIC ---
        
        // 1. Ich biete mehr!
        var betScore = 70
        if players >= 2 && players <= 8 { betScore += 20 }
        if mood == .communication || mood == .funny { betScore += 15 }
        
        let betReasons = reasonsForGame(players: players, minutes: mins, isMultiplayer: isMultiplayer, minPlayers: 2, maxPlayers: 8, supportsMultiplayer: false)
        if !betReasons.isEmpty { betScore = 5 } // Penalize hard if rules broken
        
        list.append(GameRecommendation(
            id: "BetBuddy",
            name: "Ich biete mehr!",
            description: "Wettet aufeinander. Wer kennt die Gruppe am besten?",
            icon: "suit.spade.fill",
            iconTint: .orange,
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
        
        let impReasons = reasonsForGame(players: players, minutes: mins, isMultiplayer: isMultiplayer, minPlayers: imposterMinPlayers, minMinutes: 10, supportsMultiplayer: true)
        if !impReasons.isEmpty { impScore = 5 }
        
        list.append(GameRecommendation(
            id: "Imposter",
            name: "Imposter",
            description: "Findet den Spion, bevor die Zeit abläuft!",
            icon: "person.fill.viewfinder",
            iconTint: .red,
            matchScore: clampScore(impScore),
            reasons: impReasons
        ))
        
        // 3. TimesUp
        var timeScore = 50
        if players >= 4 { timeScore += 20 }
        if mins >= 20 { timeScore += 15 } else { timeScore -= 20 }
        if mood == .active || mood == .funny { timeScore += 15 }
        
        let timeReasons = reasonsForGame(players: players, minutes: mins, isMultiplayer: isMultiplayer, minPlayers: 4, minMinutes: 20, supportsMultiplayer: false)
        if !timeReasons.isEmpty { timeScore = 5 }
        
        list.append(GameRecommendation(
            id: "TimesUp",
            name: "Time's Up",
            description: "Erklären, Pantomime, Zeichnen. Pures Chaos.",
            icon: "hourglass.bottomhalf.filled",
            iconTint: .cyan,
            matchScore: clampScore(timeScore),
            reasons: timeReasons
        ))
        
        // 4. Question
        var questScore = 50
        if players >= 3 { questScore += 15 }
        if mood == .communication { questScore += 30 }
        
        let questReasons = reasonsForGame(players: players, minutes: mins, isMultiplayer: isMultiplayer, minPlayers: 3, supportsMultiplayer: false)
        if !questReasons.isEmpty { questScore = 5 }
        
        list.append(GameRecommendation(
            id: "Question",
            name: "Question",
            description: "Deep Talk oder lustige Fragen.",
            icon: "waveform.path.ecg",
            iconTint: .purple,
            matchScore: clampScore(questScore),
            reasons: questReasons
        ))

        // 5. Geraeusch-Kino
        var soundScore = 55
        if players >= 3 && players <= 10 { soundScore += 20 }
        if mood == .active || mood == .funny { soundScore += 20 }
        if mins >= 20 { soundScore += 10 }
        if isMultiplayer { soundScore += 8 }

        let soundReasons = reasonsForGame(players: players, minutes: mins, isMultiplayer: isMultiplayer, minPlayers: 3, supportsMultiplayer: true)
        if !soundReasons.isEmpty { soundScore = 5 }

        list.append(GameRecommendation(
            id: "SoundCinema",
            name: "Geräusch-Kino",
            description: "Imitiert Sounds und erratet die Szene.",
            icon: "waveform.circle.fill",
            iconTint: .cyan,
            matchScore: clampScore(soundScore),
            reasons: soundReasons
        ))

        // 6. Falsche Faehrte
        var ffScore = 55
        if players >= 3 && players <= 8 { ffScore += 20 }
        if mood == .funny || mood == .communication || mood == .intense { ffScore += 18 }
        if mins < 10 { ffScore -= 10 }
        if isMultiplayer { ffScore += 8 }

        let ffReasons = reasonsForGame(players: players, minutes: mins, isMultiplayer: isMultiplayer, minPlayers: 3, minMinutes: 10, supportsMultiplayer: true)
        if !ffReasons.isEmpty { ffScore = 5 }

        list.append(GameRecommendation(
            id: "FalscheFaehrte",
            name: "Falsche Fährte",
            description: "Lügen erkennen, Hinweise lesen, Bluff entlarven.",
            icon: "magnifyingglass.circle.fill",
            iconTint: .indigo,
            matchScore: clampScore(ffScore),
            reasons: ffReasons
        ))
        
        return list.sorted { $0.matchScore > $1.matchScore }
    }

    private func clampScore(_ score: Int) -> Int {
        min(max(score, 0), 100)
    }

    private func reasonsForGame(
        players: Int,
        minutes: Int,
        isMultiplayer: Bool,
        minPlayers: Int,
        maxPlayers: Int? = nil,
        minMinutes: Int? = nil,
        supportsMultiplayer: Bool
    ) -> [LocalizedStringKey] {
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
        if let minMinutes, minutes < minMinutes {
            reasons.append("Dauert länger (\(minMinutes)+ min)")
        }
        return reasons
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
            .padding(.vertical, 12)
            .liquidGlass(cornerRadius: 16, tint: .white.opacity(0.02))
    }
}

struct MoodButton: View {
    let mood: GameRecommenderView.GameMood
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        if #available(iOS 26.0, *) {
            Button(action: action) {
                label
            }
            .buttonStyle(
                isSelected
                    ? .glass(.regular.tint(mood.color).interactive())
                    : .glass(.regular.interactive())
            )
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        } else {
            Button(action: action) {
                label
            }
            .liquidGlass(cornerRadius: 16, tint: isSelected ? mood.color.opacity(0.26) : .white.opacity(0.03), interactive: true)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
    }

    private var label: some View {
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
        .foregroundStyle(.white)
    }
}

struct TimeButton: View {
    let time: GameRecommenderView.TimeCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        if #available(iOS 26.0, *) {
            if isSelected {
                Button(action: action) {
                    label
                }
                .buttonStyle(.glassProminent)
            } else {
                Button(action: action) {
                    label
                }
                .buttonStyle(.glass)
            }
        } else {
            Button(action: action) {
                label
            }
            .liquidGlass(cornerRadius: 18, tint: isSelected ? .white.opacity(0.20) : .white.opacity(0.03), interactive: true)
        }
    }

    private var label: some View {
        Text(time.label)
            .font(.subheadline.bold())
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .foregroundStyle(isSelected ? .white : .white.opacity(0.8))
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

struct HeroRecommendationCard: View {
    let game: GameRecommenderView.GameRecommendation
    
    var body: some View {
        NavigationLink(destination: GameRecommenderView.destination(for: game.id)) {
            VStack(alignment: .leading, spacing: 16) {
                // Top Badge
                HStack(alignment: .top) {
                    MatchScoreGauge(score: game.matchScore, tint: game.iconTint)
                    
                    Spacer()
                    
                    if !game.isPlayableNow {
                        HStack(spacing: 4) {
                            Image(systemName: "info.circle.fill")
                            Text("Bedingungen prüfen")
                        }
                        .font(.caption.bold())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.red.opacity(0.8), in: Capsule())
                        .foregroundStyle(.white)
                    }
                }
                
                HStack(alignment: .center, spacing: 16) {
                    RecommenderGameIcon(symbol: game.icon, tint: game.iconTint, size: 70)
                    
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
                    Text("Jetzt Starten")
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
                LinearGradient(colors: [game.iconTint.opacity(0.26), Color.blue.opacity(0.16)], startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .liquidGlass(cornerRadius: 28, tint: game.iconTint.opacity(0.08))
            .overlay(alignment: .topTrailing) {
                if game.matchScore >= 85 {
                    SharedLottieView(
                        filename: "Money rain",
                        loopMode: .playOnce,
                        contentMode: .scaleAspectFit,
                        animationSpeed: 1.15,
                        playTrigger: game.matchScore
                    )
                    .frame(width: 96, height: 96)
                    .allowsHitTesting(false)
                    .padding(4)
                }
            }
            .padding(.horizontal)
        }
        .disabled(!game.isPlayableNow)
    }
}

private struct MatchScoreGauge: View {
    let score: Int
    let tint: Color
    @State private var animatedScore = 0

    var body: some View {
        HStack(spacing: 10) {
            Gauge(value: Double(animatedScore), in: 0...100) {
                Text("Match")
            } currentValueLabel: {
                Text("\(animatedScore)%")
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .contentTransition(.numericText())
            }
            .gaugeStyle(.accessoryCircularCapacity)
            .tint(tint)
            .frame(width: 46, height: 46)

            VStack(alignment: .leading, spacing: 1) {
                Text("\(animatedScore)% Match")
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
                Text("Bester Treffer")
                    .font(.caption2.bold())
                    .textCase(.uppercase)
                    .foregroundStyle(.white.opacity(0.55))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(Color.black.opacity(0.3), in: Capsule())
        .changeEffect(.jump(height: 8), value: animatedScore, isEnabled: animatedScore > 0)
        .changeEffect(.spray(origin: .center) {
            Image(systemName: "sparkles")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.yellow)
        }, value: animatedScore, isEnabled: animatedScore >= 85)
        .onAppear {
            animateScore(to: score)
        }
        .onChange(of: score) { _, newValue in
            animateScore(to: newValue)
        }
    }

    private func animateScore(to newValue: Int) {
        animatedScore = 0
        withAnimation(.spring(response: 0.55, dampingFraction: 0.82)) {
            animatedScore = newValue
        }
    }
}

struct SmallRecommendationCard: View {
    let game: GameRecommenderView.GameRecommendation
    
    var body: some View {
        NavigationLink(destination: GameRecommenderView.destination(for: game.id)) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    RecommenderGameIcon(symbol: game.icon, tint: game.iconTint, size: 44)
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
            .liquidGlass(cornerRadius: 20, tint: game.iconTint.opacity(0.05), interactive: true)
        }
    }
}

private struct RecommenderGameIcon: View {
    let symbol: String
    let tint: Color
    let size: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.23)
                .fill(LinearGradient(colors: [tint, tint.opacity(0.55)], startPoint: .topLeading, endPoint: .bottomTrailing))

            Image(systemName: symbol)
                .font(.system(size: size * 0.43, weight: .bold))
                .foregroundStyle(.black.opacity(0.82))
        }
        .frame(width: size, height: size)
        .shadow(color: tint.opacity(0.25), radius: 8, y: 4)
    }
}

private struct RecommenderCloseButton: View {
    let action: () -> Void

    var body: some View {
        if #available(iOS 26.0, *) {
            Button("Schließen", action: action)
                .buttonStyle(.glass)
        } else {
            Button("Schließen", action: action)
                .foregroundStyle(.white)
        }
    }
}

private struct LiquidGlassModifier: ViewModifier {
    let cornerRadius: CGFloat
    let tint: Color
    let interactive: Bool

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            if interactive {
                content
                    .glassEffect(.regular.tint(tint).interactive(), in: .rect(cornerRadius: cornerRadius))
            } else {
                content
                    .glassEffect(.regular.tint(tint), in: .rect(cornerRadius: cornerRadius))
            }
        } else {
            content
                .background(.ultraThinMaterial.opacity(0.35), in: RoundedRectangle(cornerRadius: cornerRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        }
    }
}

private struct SoftScrollEdgesModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .scrollEdgeEffectStyle(.soft, for: .top)
                .scrollEdgeEffectStyle(.soft, for: .bottom)
        } else {
            content
        }
    }
}

private extension View {
    func liquidGlass(cornerRadius: CGFloat, tint: Color = .white.opacity(0.04), interactive: Bool = false) -> some View {
        modifier(LiquidGlassModifier(cornerRadius: cornerRadius, tint: tint, interactive: interactive))
    }

    func softScrollEdges() -> some View {
        modifier(SoftScrollEdgesModifier())
    }
}
