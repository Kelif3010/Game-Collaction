import SwiftUI
import Combine

// MARK: - Hauptansicht
struct ContentView: View {
    // Steuerung für die Spiele
    @State private var isBetBuddyPresented = false
    @State private var isTimesUpPresented = false
    @State private var isQuestionGamePresented = false
    @State private var isImposterPresented = false
    
    // Steuerung für Einstellungen
    @State private var showSettings = false
    
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
                        
                        // Unsichtbarer Platzhalter für Symmetrie
                        Image(systemName: "gearshape.fill")
                            .font(.title2)
                            .opacity(0)
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)

                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(LocalizedStringKey("Deine Bibliothek"))
                                .font(.headline)
                                .foregroundStyle(.white.opacity(0.7))
                                .padding(.horizontal)
                                .padding(.top, 20)
                            
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 20)], spacing: 20) {
                                
                                // --- SPIEL 1: BET BUDDY ---
                                Button { isBetBuddyPresented = true } label: {
                                    MenuGameCard(
                                        title: "Bet Buddy",
                                        subtitle: "Wetten & Lachen",
                                        icon: "person.2.fill",
                                        gradient: LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                                    )
                                }
                                
                                // --- SPIEL 2: TIME'S UP ---
                                Button { isTimesUpPresented = true } label: {
                                    MenuGameCard(
                                        title: "Time's Up",
                                        subtitle: "Erklären & Raten",
                                        icon: "hourglass",
                                        gradient: LinearGradient(colors: [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing)
                                    )
                                }
                                
                                // --- SPIEL 3: FINDE DEN LÜGNER ---
                                Button { isQuestionGamePresented = true } label: {
                                    MenuGameCard(
                                        title: "Lügner",
                                        subtitle: "Wer blufft?",
                                        icon: "person.fill.questionmark",
                                        gradient: LinearGradient(colors: [.purple, .indigo], startPoint: .topLeading, endPoint: .bottomTrailing)
                                    )
                                }
                                
                                // --- SPIEL 4: IMPOSTER ---
                                Button { isImposterPresented = true } label: {
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
        .fullScreenCover(isPresented: $isBetBuddyPresented) { BetBuddyWrapper() }
        .fullScreenCover(isPresented: $isQuestionGamePresented) { QuestionGameWrapper() }
        .fullScreenCover(isPresented: $isImposterPresented) {
            ImposterGameWrapper()
        }
        .fullScreenCover(isPresented: $isTimesUpPresented) {
            TimesUpWrapper()
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

struct SnowView: View {
    @State private var particles: [SnowParticle] = []
    
    var body: some View {
        GeometryReader { geometry in
            TimelineView(.animation) { timeline in
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
                updateParticles()
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

#Preview {
    ContentView()
}
