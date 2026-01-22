import SwiftUI
import Combine

// MARK: - Hauptansicht
struct ContentView: View {
    @StateObject private var statsManager = GlobalStatsManager.shared
    @ObservedObject private var quickActionManager = QuickActionManager.shared
    
    // Steuerung für die Spiele
    @State private var isBetBuddyPresented = false
    @State private var isTimesUpPresented = false
    @State private var isQuestionGamePresented = false
    @State private var isImposterPresented = false
    
    // Steuerung für Einstellungen
    @State private var showSettings = false
    @State private var showRecommender = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // HINTERGRUND: Verlauf
                LinearGradient(
                    colors: [Color(red: 0.05, green: 0.05, blue: 0.15), Color(red: 0.1, green: 0.1, blue: 0.25)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // SAISONALER EFFEKT: Schnee
                SnowView()
                    .opacity(0.6)
                
                VStack(spacing: 20) {
                    // HEADER: Einstellungen + Titel
                    HStack {
                        Button {
                            showSettings = true
                        } label: {
                            Image(systemName: "gearshape.fill")
                                .font(.title2)
                                .foregroundStyle(.white.opacity(0.8))
                                .padding(10)
                                .background(.ultraThinMaterial, in: Circle())
                        }
                        
                        Spacer()
                        
                        Text("Games Collection")
                            .font(.title2.bold())
                            .foregroundStyle(.white)
                            .shadow(radius: 5)
                        
                        Spacer()
                        
                        // Magic Recommender Button
                        Button {
                            showRecommender = true
                        } label: {
                            Image(systemName: "wand.and.stars")
                                .font(.title2)
                                .foregroundStyle(.white.opacity(0.8))
                                .padding(10)
                                .background(.ultraThinMaterial, in: Circle())
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)

                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 10) {
                            
                            // --- LIVE TICKER ---
                            InfoTickerView()
                                .padding(.vertical, 10)
                            
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 20)], spacing: 20) {
                                
                                // --- SPIEL 1: BET BUDDY ---
                                Button {
                                    statsManager.markGameAsPlayed("BetBuddy")
                                    isBetBuddyPresented = true
                                } label: {
                                    BetBuddyGameCard()
                                }
                                
                                // --- SPIEL 2: TIME'S UP ---
                                Button { 
                                    statsManager.markGameAsPlayed("TimesUp")
                                    isTimesUpPresented = true 
                                } label: {
                                    MenuGameCard(
                                        title: "Time's Up",
                                        subtitle: "Erklären & Raten",
                                        icon: "hourglass",
                                        gradient: LinearGradient(colors: [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing)
                                    )
                                }
                                
                                // --- SPIEL 3: FINDE DEN LÜGNER ---
                                Button {
                                    statsManager.markGameAsPlayed("Question")
                                    isQuestionGamePresented = true
                                } label: {
                                    LugnerGameCard()
                                }
                                
                                // --- SPIEL 4: IMPOSTER ---
                                Button { 
                                    statsManager.markGameAsPlayed("Imposter")
                                    isImposterPresented = true 
                                } label: {
                                    MenuGameCard(
                                        title: "Imposter",
                                        subtitle: "Finde den Spion",
                                        icon: "theatermasks.fill",
                                        gradient: LinearGradient(colors: [.red, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
                                    )
                                }
                                
                            }
                            .padding()
                        }
                    }
                    
                    Spacer()
                    
                    // MARK: - In-App Branding
                    Text("A KELIF Game ❤️")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.white.opacity(0.5))
                        .padding(.bottom, 10)
                }
            }
        }
        .preferredColorScheme(.dark)
        // MODALS
        .sheet(isPresented: $showSettings) {
            MainSettingsView()
        }
        .sheet(isPresented: $showRecommender) {
            GameRecommenderView()
        }
        .fullScreenCover(isPresented: $isBetBuddyPresented) { BetBuddyWrapper() }
        .fullScreenCover(isPresented: $isQuestionGamePresented) { QuestionGameWrapper() }
        .fullScreenCover(isPresented: $isImposterPresented) {
            ImposterGameWrapper()
        }
        .fullScreenCover(isPresented: $isTimesUpPresented) {
            TimesUpWrapper()
        }
        .onAppear {
            handleQuickActionIfNeeded()
        }
        .onChange(of: quickActionManager.pendingAction) { _, _ in
            handleQuickActionIfNeeded()
        }
    }

    private func handleQuickActionIfNeeded() {
        guard let action = quickActionManager.pendingAction else { return }
        openGame(for: action)
        quickActionManager.pendingAction = nil
    }

    private func openGame(for action: QuickActionType) {
        isBetBuddyPresented = false
        isTimesUpPresented = false
        isQuestionGamePresented = false
        isImposterPresented = false

        switch action {
        case .betBuddy:
            statsManager.markGameAsPlayed(action.gameId)
            isBetBuddyPresented = true
        case .timesUp:
            statsManager.markGameAsPlayed(action.gameId)
            isTimesUpPresented = true
        case .question:
            statsManager.markGameAsPlayed(action.gameId)
            isQuestionGamePresented = true
        case .imposter:
            statsManager.markGameAsPlayed(action.gameId)
            isImposterPresented = true
        }
    }
}

// MARK: - Hilfskomponenten

struct MenuGameCard: View {
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey
    let icon: String
    let gradient: LinearGradient
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                Circle()
                    .fill(.white.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(.white)
            }
            
            Spacer()
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.title3.bold())
                    .foregroundStyle(.white)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 160)
        .padding()
        .background(gradient.opacity(0.8))
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(.white.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
    }
}

// MARK: - Spezielle Bet Buddy-Karte (Casino-Theme)
struct BetBuddyGameCard: View {
    @State private var chipRotation = false
    @State private var shimmer = false

    // Casino-Farben
    private let accentGold = Color(red: 0.85, green: 0.65, blue: 0.12)
    private let accentGoldLight = Color(red: 0.95, green: 0.80, blue: 0.35)
    private let accentEmerald = Color(red: 0.15, green: 0.55, blue: 0.35)
    private let textChampagne = Color(red: 0.95, green: 0.92, blue: 0.85)

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Icon: Poker Chip mit Karten
            ZStack {
                // Äußerer Gold-Glow
                Circle()
                    .stroke(accentGold.opacity(0.4), lineWidth: 2)
                    .frame(width: 54, height: 54)
                    .scaleEffect(chipRotation ? 1.15 : 1.0)
                    .opacity(chipRotation ? 0 : 0.6)

                // Chip-Hintergrund
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [accentGold, accentGold.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                    .overlay(
                        Circle()
                            .stroke(accentGoldLight.opacity(0.6), lineWidth: 2)
                    )
                    .shadow(color: accentGold.opacity(0.4), radius: 6)

                // Chip-Symbol
                Image(systemName: "suit.spade.fill")
                    .font(.title2)
                    .foregroundStyle(Color(red: 0.15, green: 0.12, blue: 0.08))
            }

            Spacer()

            VStack(alignment: .leading, spacing: 4) {
                // Titel
                HStack(spacing: 6) {
                    Text("Bet Buddy")
                        .font(.system(.title3, design: .rounded).bold())
                        .foregroundStyle(textChampagne)

                    // Kleine Karten-Symbole
                    HStack(spacing: 2) {
                        Text("♠")
                            .font(.system(size: 10))
                            .foregroundStyle(accentGold.opacity(0.6))
                        Text("♦")
                            .font(.system(size: 10))
                            .foregroundStyle(Color(red: 0.65, green: 0.12, blue: 0.15).opacity(0.6))
                    }
                }

                Text("High Stakes")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(accentGold.opacity(0.8))
                    .tracking(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 160)
        .padding()
        .background(
            ZStack {
                // Basis-Gradient (Casino-Dunkel)
                LinearGradient(
                    colors: [
                        Color(red: 0.05, green: 0.08, blue: 0.05),
                        Color(red: 0.03, green: 0.05, blue: 0.03)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                // Filz-Textur Simulation
                Color(red: 0.05, green: 0.12, blue: 0.08).opacity(0.3)

                // Gold-Schimmer von oben
                RadialGradient(
                    colors: [
                        accentGold.opacity(shimmer ? 0.15 : 0.08),
                        Color.clear
                    ],
                    center: .topLeading,
                    startRadius: 0,
                    endRadius: 180
                )

                // Subtile Streifen (Poker-Tisch)
                VStack(spacing: 8) {
                    ForEach(0..<20, id: \.self) { _ in
                        Rectangle()
                            .fill(Color.black.opacity(0.08))
                            .frame(height: 1)
                    }
                }
                .opacity(0.5)

                // Dekorative Karten-Ecke
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text("♣")
                            .font(.system(size: 40))
                            .foregroundStyle(accentGold.opacity(0.08))
                            .offset(x: 10, y: 10)
                    }
                }
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: [accentGold.opacity(0.5), accentGold.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        .shadow(color: accentGold.opacity(0.2), radius: 12, x: 0, y: 5)
        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: false)) {
                chipRotation = true
            }
            withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
                shimmer = true
            }
        }
    }
}

// MARK: - Spezielle Lügner-Karte (Verhörraum-Theme)
struct LugnerGameCard: View {
    @State private var pulseAnimation = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Icon mit EKG-Puls
            ZStack {
                // Äußerer Glow-Ring
                Circle()
                    .stroke(Color(red: 0.22, green: 1.0, blue: 0.08).opacity(0.3), lineWidth: 2)
                    .frame(width: 54, height: 54)
                    .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                    .opacity(pulseAnimation ? 0 : 0.6)

                Circle()
                    .fill(Color(red: 0.22, green: 1.0, blue: 0.08).opacity(0.15))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Circle()
                            .stroke(Color(red: 0.22, green: 1.0, blue: 0.08).opacity(0.4), lineWidth: 1)
                    )

                Image(systemName: "waveform.path.ecg")
                    .font(.title2)
                    .foregroundStyle(Color(red: 0.22, green: 1.0, blue: 0.08))
                    .shadow(color: Color(red: 0.22, green: 1.0, blue: 0.08).opacity(0.5), radius: 4)
            }

            Spacer()

            VStack(alignment: .leading, spacing: 4) {
                Text("Lügner")
                    .font(.system(.title3, design: .monospaced).bold())
                    .foregroundStyle(Color(red: 0.77, green: 0.73, blue: 0.60))

                Text("Lügendetektor")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(Color(red: 0.22, green: 1.0, blue: 0.08).opacity(0.8))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 160)
        .padding()
        .background(
            ZStack {
                // Basis-Gradient (Dossier-Dunkel)
                LinearGradient(
                    colors: [
                        Color(red: 0.08, green: 0.07, blue: 0.05),
                        Color(red: 0.04, green: 0.04, blue: 0.03)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                // Subtiler grüner Schimmer
                RadialGradient(
                    colors: [
                        Color(red: 0.22, green: 1.0, blue: 0.08).opacity(0.08),
                        Color.clear
                    ],
                    center: .topLeading,
                    startRadius: 0,
                    endRadius: 200
                )

                // Scanlines
                VStack(spacing: 3) {
                    ForEach(0..<60, id: \.self) { _ in
                        Rectangle()
                            .fill(Color.black.opacity(0.15))
                            .frame(height: 1)
                    }
                }
                .opacity(0.3)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(red: 0.22, green: 1.0, blue: 0.08).opacity(0.25), lineWidth: 1)
        )
        .shadow(color: Color(red: 0.22, green: 1.0, blue: 0.08).opacity(0.15), radius: 12, x: 0, y: 5)
        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false)) {
                pulseAnimation = true
            }
        }
    }
}

struct SnowView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var particles: [SnowParticle] = []
    @State private var isAnimating = true

    // Timer nur wenn App aktiv ist (spart Batterie im Hintergrund)
    private var timer: Publishers.Autoconnect<Timer.TimerPublisher>? {
        isAnimating ? Timer.publish(every: 0.02, on: .main, in: .common).autoconnect() : nil
    }

    var body: some View {
        GeometryReader { geometry in
            TimelineView(.animation(paused: !isAnimating)) { timeline in
                Canvas { context, size in
                    for particle in particles {
                        let rect = CGRect(x: particle.x * size.width, y: particle.y * size.height, width: particle.size, height: particle.size)
                        context.opacity = particle.opacity
                        context.fill(Path(ellipseIn: rect), with: .color(.white))
                    }
                }
            }
            .onAppear {
                for _ in 0..<50 {
                    particles.append(createParticle())
                }
            }
            .onReceive(Timer.publish(every: 0.02, on: .main, in: .common).autoconnect()) { _ in
                guard isAnimating else { return }
                updateParticles()
            }
            .onChange(of: scenePhase) { _, newPhase in
                // Timer stoppen wenn App in Hintergrund geht
                isAnimating = (newPhase == .active)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
    
    func createParticle() -> SnowParticle {
        SnowParticle(
            x: Double.random(in: 0...1),
            y: Double.random(in: -0.2...0),
            size: Double.random(in: 2...6),
            speed: Double.random(in: 0.001...0.005),
            opacity: Double.random(in: 0.3...0.8)
        )
    }
    
    func updateParticles() {
        for i in 0..<particles.count {
            particles[i].y += particles[i].speed
            if particles[i].y > 1.0 {
                particles[i].y = Double.random(in: -0.2...0)
                particles[i].x = Double.random(in: 0...1)
            }
        }
    }
}

struct SnowParticle: Identifiable {
    var id = UUID()
    var x: Double
    var y: Double
    var size: Double
    var speed: Double
    var opacity: Double
}

struct SessionKingCard: View {
    let name: String
    let wins: Int
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [.yellow, .orange], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 50, height: 50)
                
                Image(systemName: "crown.fill")
                    .font(.title3)
                    .foregroundStyle(.white)
            }
            .shadow(color: .orange.opacity(0.3), radius: 5)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(LocalizedStringKey("King of the Session"))
                    .font(.caption.bold())
                    .foregroundStyle(.orange)
                    .textCase(.uppercase)
                
                Text(name)
                    .font(.title3.bold())
                    .foregroundStyle(.white)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(wins)")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                Text(wins == 1 ? LocalizedStringKey("Sieg") : LocalizedStringKey("Siege"))
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
        .padding()
        .background(.white.opacity(0.08))
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(LinearGradient(colors: [.yellow.opacity(0.5), .clear], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
        )
    }
}

#Preview {
    ContentView()
}
