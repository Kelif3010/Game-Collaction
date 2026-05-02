import SwiftUI
import Combine

private struct CompatibleGlassEffectContainer<Content: View>: View {
    private let spacing: CGFloat
    private let content: () -> Content

    init(spacing: CGFloat = 24, @ViewBuilder content: @escaping () -> Content) {
        self.spacing = spacing
        self.content = content
    }

    @ViewBuilder
    var body: some View {
        if #available(iOS 26.0, *) {
            GlassEffectContainer(spacing: spacing) {
                content()
            }
        } else {
            content()
        }
    }
}

private extension View {
    @ViewBuilder
    func compatibleGlassCardEffect(cornerRadius: CGFloat) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

        if #available(iOS 26.0, *) {
            glassEffect(.regular.interactive(), in: shape)
                .clipShape(shape)
        } else {
            clipShape(shape)
                .background(.ultraThinMaterial, in: shape)
        }
    }
}

// MARK: - Hauptansicht
struct ContentView: View {
    @ObservedObject private var statsManager = GlobalStatsManager.shared
    @ObservedObject private var quickActionManager = QuickActionManager.shared
    
    // Steuerung für die Spiele
    @State private var isBetBuddyPresented = false
    @State private var isTimesUpPresented = false
    @State private var isQuestionGamePresented = false
    @State private var isImposterPresented = false
    @State private var isSoundCinemaPresented = false
    @State private var isFalscheFaehrtePresented = false
    @State private var isPartyPresented = false

    // Tap-Animation für Karten (Hero-Effekt)
    @State private var betBuddyTap = false
    @State private var timesUpTap = false
    @State private var questionTap = false
    @State private var imposterTap = false
    @State private var soundCinemaTap = false
    @State private var falscheFaehrteTap = false
    
    // Steuerung für Einstellungen
    @State private var showSettings = false
    @State private var showRecommender = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // HINTERGRUND: MeshGradient (iOS 18+) mit animierten Neon-Akzenten
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
                    // Fallback für iOS 17
                    LinearGradient(
                        colors: [Color(red: 0.05, green: 0.05, blue: 0.15), Color(red: 0.1, green: 0.1, blue: 0.25)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .ignoresSafeArea()
                }
                
                // SAISONALER EFFEKT: Schnee – nur im Winter (Dez/Jan/Feb)
                if SnowView.isCurrentlyWinter {
                    SnowView()
                        .opacity(0.6)
                }
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {

                        // ── PARTY STARTEN Banner ──────────────────────────────
                        Button {
                            isPartyPresented = true
                        } label: {
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(.black.opacity(0.15))
                                        .frame(width: 44, height: 44)
                                    Image(systemName: "crown.fill")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundStyle(.black.opacity(0.7))
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Party starten")
                                        .font(.system(size: 17, weight: .bold, design: .rounded))
                                        .foregroundStyle(.black)
                                    Text("Mehrere Spiele · Gesamtwertung")
                                        .font(.system(size: 12))
                                        .foregroundStyle(.black.opacity(0.55))
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(.black.opacity(0.4))
                            }
                            .padding(.horizontal, 18)
                            .padding(.vertical, 14)
                            .background(
                                LinearGradient(
                                    colors: [
                                        Color(red: 1.0, green: 0.83, blue: 0.15),
                                        Color(red: 1.0, green: 0.65, blue: 0.05)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                in: RoundedRectangle(cornerRadius: 18)
                            )
                            .shadow(
                                color: Color(red: 1.0, green: 0.65, blue: 0.05).opacity(0.35),
                                radius: 12, y: 6
                            )
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)

                        CompatibleGlassEffectContainer(spacing: 20) {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 20)], spacing: 20) {
                                // ... rest of buttons remain the same
                                // --- SPIEL 1: Ich biete mehr! ---
                                Button {
                                    statsManager.markGameAsPlayed("BetBuddy")
                                    withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) { betBuddyTap = true }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                                        betBuddyTap = false
                                        isBetBuddyPresented = true
                                    }
                                } label: {
                                    BetBuddyGameCard()
                                        .scaleEffect(betBuddyTap ? 0.93 : 1.0)
                                        .animation(.spring(response: 0.25, dampingFraction: 0.6), value: betBuddyTap)
                                }

                                // --- SPIEL 2: TIME'S UP ---
                                Button {
                                    statsManager.markGameAsPlayed("TimesUp")
                                    withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) { timesUpTap = true }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                                        timesUpTap = false
                                        isTimesUpPresented = true
                                    }
                                } label: {
                                    MenuGameCard(
                                        title: "Time's Up",
                                        subtitle: "Erklären & Raten",
                                        icon: "hourglass",
                                        gradient: LinearGradient(colors: [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing)
                                    )
                                    .scaleEffect(timesUpTap ? 0.93 : 1.0)
                                    .animation(.spring(response: 0.25, dampingFraction: 0.6), value: timesUpTap)
                                }

                                // --- SPIEL 3: FINDE DEN LÜGNER ---
                                Button {
                                    statsManager.markGameAsPlayed("Question")
                                    withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) { questionTap = true }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                                        questionTap = false
                                        isQuestionGamePresented = true
                                    }
                                } label: {
                                    LugnerGameCard()
                                        .scaleEffect(questionTap ? 0.93 : 1.0)
                                        .animation(.spring(response: 0.25, dampingFraction: 0.6), value: questionTap)
                                }

                                // --- SPIEL 4: IMPOSTER ---
                                Button {
                                    statsManager.markGameAsPlayed("Imposter")
                                    withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) { imposterTap = true }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                                        imposterTap = false
                                        isImposterPresented = true
                                    }
                                } label: {
                                    ImposterGameCard()
                                        .scaleEffect(imposterTap ? 0.93 : 1.0)
                                        .animation(.spring(response: 0.25, dampingFraction: 0.6), value: imposterTap)
                                }

                                // --- SPIEL 5: GERÄUSCH-KINO ---
                                Button {
                                    statsManager.markGameAsPlayed("SoundCinema")
                                    withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) { soundCinemaTap = true }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                                        soundCinemaTap = false
                                        isSoundCinemaPresented = true
                                    }
                                } label: {
                                    SoundCinemaGameCard()
                                        .scaleEffect(soundCinemaTap ? 0.93 : 1.0)
                                        .animation(.spring(response: 0.25, dampingFraction: 0.6), value: soundCinemaTap)
                                }

                                // --- SPIEL 6: FALSCHE FÄHRTE ---
                                Button {
                                    withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) { falscheFaehrteTap = true }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                                        falscheFaehrteTap = false
                                        isFalscheFaehrtePresented = true
                                    }
                                } label: {
                                    FalscheFaehrteGameCard()
                                        .scaleEffect(falscheFaehrteTap ? 0.93 : 1.0)
                                        .animation(.spring(response: 0.25, dampingFraction: 0.6), value: falscheFaehrteTap)
                                }
                            }
                            .padding(.bottom, 30)
                        }
                        .padding(.horizontal)
                    }
                }
                .ignoresSafeArea(edges: .bottom)
                .navigationTitle("")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            showSettings = true
                        } label: {
                            Image(systemName: "gearshape.fill")
                                .font(.body.bold())
                                .foregroundStyle(.white.opacity(0.8))
                                .padding(8)
                                .background(.ultraThinMaterial, in: Circle())
                        }
                    }
                    
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showRecommender = true
                        } label: {
                            Image(systemName: "wand.and.stars")
                                .font(.body.bold())
                                .foregroundStyle(.white.opacity(0.8))
                                .padding(8)
                                .background(.ultraThinMaterial, in: Circle())
                        }
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        // MODALS
        .sheet(isPresented: $showSettings) {
            MainSettingsView()
                .presentationBackground(.ultraThinMaterial)
        }
        .sheet(isPresented: $showRecommender) {
            GameRecommenderView()
                .presentationBackground(.ultraThinMaterial)
        }
        .fullScreenCover(isPresented: $isBetBuddyPresented) { BetBuddyWrapper() }
        .fullScreenCover(isPresented: $isQuestionGamePresented) { QuestionGameWrapper() }
        .fullScreenCover(isPresented: $isImposterPresented) {
            ImposterGameWrapper()
        }
        .fullScreenCover(isPresented: $isTimesUpPresented) {
            TimesUpWrapper()
        }
        .fullScreenCover(isPresented: $isSoundCinemaPresented) {
            SoundCinemaWrapper()
        }
        .fullScreenCover(isPresented: $isFalscheFaehrtePresented) {
            FalscheFaehrteWrapper()
        }
        .fullScreenCover(isPresented: $isPartyPresented) {
            PartyWrapper()
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
        isSoundCinemaPresented = false
        isFalscheFaehrtePresented = false

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
        case .soundCinema:
            statsManager.markGameAsPlayed(action.gameId)
            isSoundCinemaPresented = true
        case .falscheFaehrte:
            isFalscheFaehrtePresented = true
        }
    }
}

// MARK: - Hilfskomponenten

struct MenuGameCard: View {
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey
    let icon: String
    let gradient: LinearGradient

    @State private var hourglassFlipped = false
    @State private var hourglassTimer: Timer?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                Circle()
                    .fill(.white.opacity(0.2))
                    .frame(width: 50, height: 50)

                Image(systemName: hourglassFlipped ? "hourglass.bottomhalf.filled" : "hourglass.tophalf.filled")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .symbolEffect(.bounce, value: hourglassFlipped)
                    .rotationEffect(.degrees(hourglassFlipped ? 180 : 0))
                    .animation(.easeInOut(duration: 0.6), value: hourglassFlipped)
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
        .onAppear {
            hourglassTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
                Task { @MainActor in hourglassFlipped.toggle() }
            }
        }
        .onDisappear {
            hourglassTimer?.invalidate()
            hourglassTimer = nil
        }
        .background(gradient.opacity(0.6), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .compatibleGlassCardEffect(cornerRadius: 24)
        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
    }
}

// MARK: - Spezielle Ich biete mehr!-Karte (Casino-Theme)
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
                    Text("Ich biete mehr!")
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

// MARK: - Spezielle Imposter-Karte (Spy/Agent-Theme)
struct ImposterGameCard: View {
    @State private var scanAnimation = false
    @State private var glowPulse = false

    // Spy Theme Colors
    private let accentOrange = Color(red: 1.0, green: 0.41, blue: 0.23)
    private let accentPink = Color(red: 0.94, green: 0.16, blue: 0.47)
    private let backgroundDark = Color(red: 0.16, green: 0.02, blue: 0.08)

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Icon: Spy mit Scan-Animation
            ZStack {
                // Äußerer Scan-Ring
                Circle()
                    .stroke(accentOrange.opacity(0.4), lineWidth: 2)
                    .frame(width: 54, height: 54)
                    .scaleEffect(scanAnimation ? 1.3 : 1.0)
                    .opacity(scanAnimation ? 0 : 0.7)

                // Innerer Kreis
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [accentOrange.opacity(0.3), accentPink.opacity(0.1)],
                            center: .center,
                            startRadius: 0,
                            endRadius: 25
                        )
                    )
                    .frame(width: 50, height: 50)
                    .overlay(
                        Circle()
                            .stroke(accentOrange.opacity(0.5), lineWidth: 1.5)
                    )

                // Spy Icon
                Image(systemName: "person.fill.viewfinder")
                    .font(.title2)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [accentOrange, accentPink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: accentOrange.opacity(0.6), radius: 4)
            }

            Spacer()

            VStack(alignment: .leading, spacing: 4) {
                // Titel mit kleinem Agent-Badge
                HStack(spacing: 6) {
                    Text("Spy")
                        .font(.system(.title3, design: .rounded).bold())
                        .foregroundStyle(.white)

                    // Kleines "TOP SECRET" Badge
                    Text("🔒")
                        .font(.system(size: 10))
                }

                Text("TOP SECRET")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(accentOrange.opacity(0.8))
                    .tracking(1.5)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 160)
        .padding()
        .background(
            ZStack {
                // Basis-Gradient (Spy-Dunkelrot)
                LinearGradient(
                    colors: [
                        Color.black,
                        backgroundDark,
                        Color(red: 0.20, green: 0.02, blue: 0.10)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                // Radiales Orange-Glow von oben links
                RadialGradient(
                    colors: [
                        accentOrange.opacity(glowPulse ? 0.12 : 0.06),
                        Color.clear
                    ],
                    center: .topLeading,
                    startRadius: 0,
                    endRadius: 180
                )

                // Subtile Scan-Linien
                VStack(spacing: 4) {
                    ForEach(0..<40, id: \.self) { _ in
                        Rectangle()
                            .fill(Color.white.opacity(0.02))
                            .frame(height: 1)
                    }
                }

                // Dekorative "TARGET" Ecke
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        // Fadenkreuz-Element
                        ZStack {
                            Circle()
                                .stroke(accentOrange.opacity(0.1), lineWidth: 1)
                                .frame(width: 40, height: 40)
                            Circle()
                                .stroke(accentOrange.opacity(0.05), lineWidth: 1)
                                .frame(width: 25, height: 25)
                        }
                        .offset(x: 15, y: 15)
                    }
                }
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: [accentOrange.opacity(0.5), accentPink.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        .shadow(color: accentOrange.opacity(0.25), radius: 12, x: 0, y: 5)
        .shadow(color: .black.opacity(0.4), radius: 10, x: 0, y: 5)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false)) {
                scanAnimation = true
            }
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                glowPulse = true
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

    /// Schnee nur im Winter: Dezember (12), Januar (1), Februar (2)
    static var isCurrentlyWinter: Bool {
        let month = Calendar.current.component(.month, from: Date())
        return month == 12 || month == 1 || month == 2
    }

    var body: some View {
        GeometryReader { geometry in
            // Einziger Timer: TimelineView steuert Rendering UND Partikel-Update
            TimelineView(.animation(paused: !isAnimating)) { context in
                Canvas { drawCtx, size in
                    for particle in particles {
                        let rect = CGRect(x: particle.x * size.width, y: particle.y * size.height, width: particle.size, height: particle.size)
                        drawCtx.opacity = particle.opacity
                        drawCtx.fill(Path(ellipseIn: rect), with: .color(.white))
                    }
                }
                .onChange(of: context.date) { _, _ in
                    guard isAnimating else { return }
                    updateParticles()
                }
            }
            .onAppear {
                for _ in 0..<50 {
                    particles.append(createParticle())
                }
            }
            .onChange(of: scenePhase) { _, newPhase in
                // Animation stoppen wenn App in Hintergrund geht (Batterie sparen)
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

// MARK: - Geräusch-Kino Spielkarte
struct SoundCinemaGameCard: View {
    private let accentCyan  = Color(red: 0.0,  green: 0.83, blue: 1.0)
    private let accentBlue  = Color(red: 0.15, green: 0.45, blue: 1.0)
    private let deepNavy    = Color(red: 0.02, green: 0.06, blue: 0.20)

    @State private var wavePulse = false
    @State private var glowPulse = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Icon: Waveform
            ZStack {
                Circle()
                    .fill(accentCyan.opacity(0.18))
                    .frame(width: 52, height: 52)
                    .scaleEffect(glowPulse ? 1.18 : 1.0)
                    .opacity(glowPulse ? 0 : 0.7)

                Circle()
                    .fill(
                        LinearGradient(
                            colors: [accentCyan, accentBlue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)

                Image(systemName: "waveform.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.black.opacity(0.85))
            }

            Spacer()

            VStack(alignment: .leading, spacing: 4) {
                Text("Geräusch-Kino")
                    .font(.system(.title3, design: .rounded).bold())
                    .foregroundStyle(.white)

                Text("Imitier & Rate")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(accentCyan.opacity(0.85))
                    .tracking(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 160)
        .padding()
        .background(
            ZStack {
                LinearGradient(
                    colors: [deepNavy, Color(red: 0.03, green: 0.10, blue: 0.28)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                // Cyan-Glow von oben links
                RadialGradient(
                    colors: [accentCyan.opacity(wavePulse ? 0.14 : 0.07), Color.clear],
                    center: .topLeading,
                    startRadius: 0,
                    endRadius: 180
                )

                // Mini Waveform Dekoration
                HStack(alignment: .center, spacing: 3) {
                    ForEach([0.3, 0.7, 0.5, 1.0, 0.6, 0.8, 0.4, 0.9, 0.5, 0.3], id: \.self) { h in
                        Capsule()
                            .fill(accentCyan.opacity(wavePulse ? 0.12 : 0.06))
                            .frame(width: 3, height: 40 * h)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .padding(.trailing, 8)
                .padding(.bottom, 8)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: [accentCyan.opacity(0.55), accentBlue.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        .shadow(color: accentCyan.opacity(0.18), radius: 12, x: 0, y: 5)
        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                wavePulse = true
            }
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: false)) {
                glowPulse = true
            }
        }
    }
}

// MARK: - Falsche Fährte Karte (Detektiv-Theme: Violett/Indigo)
struct FalscheFaehrteGameCard: View {
    private let accentViolet = Color(red: 0.48, green: 0.36, blue: 0.94)
    private let accentIndigo = Color(red: 0.33, green: 0.25, blue: 0.82)
    private let deepDark     = Color(red: 0.05, green: 0.04, blue: 0.14)

    @State private var glowPulse  = false
    @State private var maskPulse  = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Icon: Detektiv-Lupe mit Puls
            ZStack {
                Circle()
                    .fill(accentViolet.opacity(0.18))
                    .frame(width: 52, height: 52)
                    .scaleEffect(glowPulse ? 1.18 : 1.0)
                    .opacity(glowPulse ? 0 : 0.7)

                Circle()
                    .fill(
                        LinearGradient(
                            colors: [accentViolet, accentIndigo],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)

                Image(systemName: "magnifyingglass.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.black.opacity(0.85))
            }

            Spacer()

            VStack(alignment: .leading, spacing: 4) {
                Text("Falsche Fährte")
                    .font(.system(.title3, design: .rounded).bold())
                    .foregroundStyle(.white)

                Text("Lüge & Entlarve")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(accentViolet.opacity(0.9))
                    .tracking(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 160)
        .padding()
        .background(
            ZStack {
                LinearGradient(
                    colors: [deepDark, Color(red: 0.08, green: 0.06, blue: 0.22)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                // Violett-Glow von oben links
                RadialGradient(
                    colors: [accentViolet.opacity(maskPulse ? 0.16 : 0.08), Color.clear],
                    center: .topLeading,
                    startRadius: 0,
                    endRadius: 180
                )

                // Fragezeichen-Deko im Hintergrund
                HStack(spacing: 10) {
                    ForEach(["?", "!", "?"], id: \.self) { sym in
                        Text(sym)
                            .font(.system(size: 28, weight: .black, design: .rounded))
                            .foregroundStyle(accentViolet.opacity(maskPulse ? 0.1 : 0.05))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .padding(.trailing, 10)
                .padding(.bottom, 10)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: [accentViolet.opacity(0.55), accentIndigo.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        .shadow(color: accentViolet.opacity(0.2), radius: 12, x: 0, y: 5)
        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: false)) {
                glowPulse = true
            }
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                maskPulse = true
            }
        }
    }
}

#Preview {
    ContentView()
}
