//
//  SpyCardExtension.swift
//  Imposter
//
//  Created by Ken on 22.09.25.
//  Refactored for Premium UI & Biometric Card Back on 2026-01-12
//

import SwiftUI

private extension Character {
    var isEmojiLike: Bool {
        unicodeScalars.contains { $0.properties.isEmojiPresentation }
    }
}

// MARK: - Spy Card (Container)
struct SpyCardView: View {
    let card: GameCard
    let gameSettings: GameSettings
    @State private var isFlipped = false
    @State private var isMovingOut = false
    @State private var rotationAngle: Double = 0
    @State private var offset: CGSize = .zero
    
    let onCardTap: () -> Void
    let onCardDismissed: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    
    private var isMultiplayer: Bool {
        MultipeerManager.shared.role != .unknown
    }
    
    var body: some View {
        ZStack {
            // Kartenrückseite mit integriertem Scanner
            CardBackView(playerName: card.player.name, isImposter: card.isImposter) {
                // Wird aufgerufen, wenn Scan abgeschlossen ist
                flipCard()
                onCardTap()
            }
            .opacity(isFlipped ? 0 : 1)
            .rotation3DEffect(
                .degrees(rotationAngle),
                axis: (x: 0, y: 1, z: 0)
            )
            
            // Kartenvorderseite
            SpyCardFrontView(
                card: card,
                gameSettings: gameSettings,
                isMultiplayer: isMultiplayer,
                onDismiss: {
                    moveCardOut()
                }
            )
            .opacity(isFlipped ? 1 : 0)
            .rotation3DEffect(
                .degrees(rotationAngle + 180),
                axis: (x: 0, y: 1, z: 0)
            )
        }
        .frame(width: 320, height: 500)
        .offset(offset)
        .scaleEffect(isMovingOut ? 0.8 : 1.0)
        .opacity(isMovingOut ? 0.0 : 1.0)
        .onTapGesture {
            // Nur im lokalen Modus schließt Tap die Karte (wenn umgedreht)
            if isFlipped && !isMovingOut && !isMultiplayer {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                moveCardOut()
            }
        }
        .animation(.spring(response: 0.6, dampingFraction: 0.7, blendDuration: 0), value: rotationAngle)
        .animation(.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0), value: offset)
        .animation(.easeIn(duration: 0.3), value: isMovingOut)
    }
    
    private func flipCard() {
        withAnimation {
            rotationAngle += 180
            isFlipped = true
        }
    }
    
    private func moveCardOut() {
        offset = CGSize(width: -450, height: 0)
        isMovingOut = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            onCardDismissed()
        }
    }
}

// MARK: - Premium Card Back (mit Biometrischem Scanner)
struct CardBackView: View {
    let playerName: String
    let isImposter: Bool
    let onUnlocked: () -> Void
    
    // Scanner State
    @State private var progress: CGFloat = 0.0
    @State private var isScanning = false
    @State private var scanTimer: Timer?
    @State private var showSuccess = false
    
    // Abwechslung: Zufällige Animation
    @State private var selectedAnimation = "Fingerprint biometric scan"
    private let availableAnimations = ["Fingerprint biometric scan", "Android Fingerprint"]
    
    // Haptik
    private let impactGenerator = UIImpactFeedbackGenerator(style: .light)
    private let successGenerator = UINotificationFeedbackGenerator()
    
    var body: some View {
        ZStack {
            // ... (Restlicher Hintergrund-Code bleibt gleich)
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.1, green: 0.1, blue: 0.12),
                            Color(red: 0.05, green: 0.05, blue: 0.06)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    Image(systemName: "circle.grid.2x2.fill")
                        .resizable()
                        .tileImage()
                        .opacity(0.03)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [.white.opacity(0.3), .white.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
                .shadow(color: .black.opacity(0.6), radius: 25, y: 15)
            
            // 2. Scan-Inhalt
            VStack(spacing: 30) {
                // Top Label
                VStack(spacing: 8) {
                    Text("IDENTITÄTS-CHECK")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(4)
                        .foregroundStyle(isScanning ? .cyan : .white.opacity(0.4))
                    
                    Text(playerName.uppercased())
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                }
                .padding(.top, 20)
                
                Spacer()
                
                // Der Scanner (Zentral)
                ZStack {
                    // Lottie Animation (Fingerprint)
                    if !showSuccess {
                        LottieView(
                            filename: selectedAnimation,
                            loopMode: .loop,
                            isPlaying: isScanning
                        )
                        .frame(width: 200, height: 200) // Etwas größer für Details
                        .opacity(isScanning ? 1.0 : 0.7) // Gedimmt wenn inaktiv
                        .scaleEffect(isScanning ? 1.2 : 1.0)
                        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isScanning)
                        // Fallback-Overlay, falls man nicht scannt (damit man sieht wo man drücken muss)
                        .overlay(
                            !isScanning ? Image(systemName: "touchid").font(.largeTitle).foregroundColor(.white.opacity(0.2)) : nil
                        )
                    }
                    
                    // Success State (Checkmark)
                    if showSuccess {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 80))
                            .foregroundStyle(.green)
                            .background(Circle().fill(.white).padding(10))
                            .shadow(color: .green.opacity(0.6), radius: 20)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                // GESTE direkt auf dem Scanner-Zentrum
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in
                            if !isScanning && !showSuccess { startScan() }
                        }
                        .onEnded { _ in
                            stopScan()
                        }
                )
                
                Spacer()
                
                // Info Text unten
                VStack(spacing: 8) {
                    Text(showSuccess ? "ZUGRIFF GEWÄHRT" : (isScanning ? "SCANNT..." : "HALTEN ZUM ENTHÜLLEN"))
                        .font(.system(size: 12, weight: .bold))
                        .tracking(1.5)
                        .foregroundStyle(isScanning ? .cyan : .white.opacity(0.5))
                    
                    if !isScanning && !showSuccess {
                        Image(systemName: "chevron.compact.down")
                            .foregroundStyle(.white.opacity(0.3))
                    }
                }
                .padding(.bottom, 30)
            }
            .padding(30)
        }
        .onAppear {
            impactGenerator.prepare()
            // Zufällige Animation wählen
            selectedAnimation = availableAnimations.randomElement() ?? availableAnimations[0]
        }
    }
    
    private func startScan() {
        isScanning = true
        // Start-Sound (Processing Loop)
        SoundManager.shared.playSound(named: "ui-processing-data-continuous-sequence-sensor-scan-small-230491")
        
        // Start-Tick
        ImposterHapticsManager.shared.playScanTick(progress: 0.0)
        
        progress = 0.0
        let totalSteps = 40
        let interval = 1.2 / Double(totalSteps) // 1.2 Sekunden Scanzeit
        var tickCounter = 0
        
        scanTimer?.invalidate()
        scanTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            if self.progress < 1.0 {
                self.progress += (1.0 / CGFloat(totalSteps))
                
                tickCounter += 1
                // Haptisches Ticken ca. alle 0.1s (jeder 3. Frame)
                if tickCounter % 3 == 0 {
                    ImposterHapticsManager.shared.playScanTick(progress: Float(self.progress))
                }
            } else {
                self.completeScan()
            }
        }
    }
    
    private func stopScan() {
        guard !showSuccess else { return }
        // Sound stoppen
        SoundManager.shared.stopSound()
        
        isScanning = false
        scanTimer?.invalidate()
        scanTimer = nil
        // Kein Herzschlag mehr zu stoppen
        
        withAnimation(.easeOut(duration: 0.3)) {
            progress = 0.0
        }
    }
    
    private func completeScan() {
        // Scan-Sound stoppen bevor der Success-Sound kommt
        SoundManager.shared.stopSound()
        
        scanTimer?.invalidate()
        scanTimer = nil
        // Kein Herzschlag mehr zu stoppen
        
        isScanning = false
        progress = 1.0
        showSuccess = true
        
        // Finaler Bestätigungs-Effekt (Haptik)
        successGenerator.notificationOccurred(.success)
        
        // Sound-Effekt abspielen
        SoundManager.shared.playSound(named: "computer-processing-sound-effects-short-click-select-01-122134")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            onUnlocked()
        }
    }
}

// Hilfs-Extension für Kacheln
extension Image {
    func tileImage() -> some View {
        GeometryReader { geometry in
            let size = geometry.size
            self
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: size.width, height: size.height)
                .clipped()
        }
    }
}

// MARK: - Premium Card Front
struct SpyCardFrontView: View {
    let card: GameCard
    let gameSettings: GameSettings
    let isMultiplayer: Bool
    let onDismiss: () -> Void
    
    struct SpyInfo {
        var categoryEmoji: String?
        var categoryName: String?
        var hint: String?
        var otherSpies: [String] = []
    }
    
    private var parsedSpyInfo: SpyInfo {
        var info = SpyInfo()
        info.categoryEmoji = card.category.emoji
        info.categoryName = card.category.name
        
        let parts = card.displayWord.components(separatedBy: "\n\n")
        
        // Helper um den Kategorie-String zu bauen, damit wir ihn filtern können
        let categoryString = "\(card.category.emoji) \(card.category.name)"
        
        var i = 0
        while i < parts.count {
            let part = parts[i]
            
            // 1. Kategorie-Check (Verhindert Dopplung)
            // Wenn der Part genau der Kategorie entspricht, ignorieren wir ihn hier,
            // da er oben im Hero-Badge angezeigt wird.
            if part == categoryString {
                i += 1
                continue
            }
            
            // 2. Mitspione Parsing
            if part.hasPrefix("Mitspione:") {
                // Fall A: "Mitspione: A, B" (Alles in einer Zeile)
                let content = part.replacingOccurrences(of: "Mitspione:", with: "").trimmingCharacters(in: .whitespaces)
                if !content.isEmpty {
                    let names = content.components(separatedBy: ",")
                    info.otherSpies = names.map { $0.trimmingCharacters(in: .whitespaces) }
                } else {
                    // Fall B: "Mitspione:" \n\n "A, B" (Namen im nächsten Part)
                    if i + 1 < parts.count {
                        let nextPart = parts[i+1]
                        let names = nextPart.components(separatedBy: ",")
                        info.otherSpies = names.map { $0.trimmingCharacters(in: .whitespaces) }
                        i += 1 // Den nächsten Part überspringen, da wir ihn verarbeitet haben
                    }
                }
            }
            // 3. Andere Hinweise
            else if part.contains("Verdächtige") || part.contains("Zwilling") || part.contains("Sicherer") || part.contains("Der Spion") {
                info.hint = part
            } else if part.hasPrefix("Hinweis:") {
                info.hint = part.replacingOccurrences(of: "Hinweis:", with: "").trimmingCharacters(in: .whitespaces)
            }
            
            i += 1
        }
        
        return info
    }
    
    private var cardBackground: LinearGradient {
        let colorName = card.cardColorName
        let c1, c2: Color
        
        switch colorName {
        case "darkRed":
            c1 = Color(red: 0.6, green: 0.1, blue: 0.15)
            c2 = Color(red: 0.2, green: 0.05, blue: 0.05)
        case "darkBlue":
            c1 = Color(red: 0.1, green: 0.3, blue: 0.6)
            c2 = Color(red: 0.05, green: 0.1, blue: 0.2)
        case "darkPurple":
            c1 = Color(red: 0.4, green: 0.1, blue: 0.6)
            c2 = Color(red: 0.1, green: 0.05, blue: 0.2)
        default:
            c1 = Color(red: 0.2, green: 0.2, blue: 0.2)
            c2 = .black
        }
        
        return LinearGradient(colors: [c1, c2], startPoint: .top, endPoint: .bottom)
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(
                            RadialGradient(
                                colors: [.white.opacity(0.15), .clear],
                                center: .topTrailing,
                                startRadius: 20,
                                endRadius: 250
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .strokeBorder(.white.opacity(0.15), lineWidth: 1)
                )
                // KANTE FIX: ClipShape hinzufügen
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .shadow(color: .black.opacity(0.5), radius: 25, y: 15)
            
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: card.cardIcon)
                    Text(card.cardTitle.uppercased())
                        .font(.system(size: 14, weight: .bold))
                        .tracking(1)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(.white.opacity(0.2), lineWidth: 1))
                .padding(.top, 30)
                .foregroundColor(.white)
                
                // KATEGORIE HERO BADGE (Neu positioniert: Direkt unter Header)
                // Nur anzeigen, wenn kein Spion ODER wenn Spione die Kategorie sehen dürfen
                if (!card.isImposter || gameSettings.shouldSpySeeCategory),
                   let emoji = parsedSpyInfo.categoryEmoji,
                   let name = parsedSpyInfo.categoryName {
                    HStack(spacing: 12) {
                        Text("KATEGORIE")
                            .font(.system(size: 10, weight: .bold))
                            .tracking(1.5)
                            .foregroundStyle(.white.opacity(0.6))
                        
                        Rectangle()
                            .fill(.white.opacity(0.3))
                            .frame(width: 1, height: 12)
                        
                        Text("\(emoji) \(name.uppercased())")
                            .font(.system(size: 14, weight: .heavy))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Capsule())
                    .padding(.top, 16)
                }
                
                Spacer()
                
                RoleCardContent(card: card, parsedInfo: parsedSpyInfo, gameSettings: gameSettings)
                
                Spacer()
                
                // MULTIPLAYER "VERSTANDEN" BUTTON
                if isMultiplayer {
                    Button {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        onDismiss()
                    } label: {
                        Text(LocalizedStringKey("Ich hab's"))
                            .font(.headline.bold())
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.blue)
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                } else if !card.shortInstruction.isEmpty {
                    // LOKAL: Nur Text
                    Text(card.shortInstruction)
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.6))
                        .padding(.bottom, 30)
                        .padding(.horizontal)
                        .multilineTextAlignment(.center)
                        // Tap to dismiss erlauben (unsichtbarer Button oder Overlay)
                        .overlay(
                             Color.clear
                                 .contentShape(Rectangle())
                                 .onTapGesture { onDismiss() }
                        )
                }
            }
        }
        // LOKAL: Tap auf ganze Karte schließt sie
        .onTapGesture {
            if !isMultiplayer {
                onDismiss()
            }
        }
    }
}

// MARK: - Role Card Content
struct RoleCardContent: View {
    let card: GameCard
    let parsedInfo: SpyCardFrontView.SpyInfo
    let gameSettings: GameSettings
    
    var body: some View {
        VStack(spacing: 25) {
            if let role = card.roleType, (role == .hacker || role == .bodyguard) {
                RoleActionView(
                    role: role,
                    players: gameSettings.players,
                    currentPlayer: card.player
                ) { target in
                    if let index = gameSettings.players.firstIndex(where: { $0.id == target.id }) {
                        if role == .bodyguard {
                            gameSettings.players[index].isProtected = true
                        }
                    }
                }
            } else {
                // --- HAUPTBEREICH (Wort oder Rolle) ---
                
                if card.isImposter {
                    // SPION: Schlichtes Design (User Wunsch)
                    // Kein Icon, kein Text in der Mitte.
                    // Der Header sagt bereits "SPION".
                    // Wir nutzen einen Spacer, damit Hints/Partner schön mittig/unten landen oder
                    // einfach leerer Raum entsteht, der "geheimnisvoll" wirkt.
                    Spacer()
                        .frame(minHeight: 20)
                    
                } else {
                    // BÜRGER: Hat ein echtes Wort
                    let mainText = getMainText()
                    let isLongText = mainText.count > 15
                    
                    ZStack {
                        // Glow Effect
                        Text(mainText)
                            .font(.system(size: isLongText ? 32 : 44, weight: .heavy, design: .rounded))
                            .foregroundColor(.blue.opacity(0.4))
                            .blur(radius: 10)
                        
                        Text(mainText)
                            .font(.system(size: isLongText ? 32 : 44, weight: .heavy, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.white, .white.opacity(0.9)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .multilineTextAlignment(.center)
                            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal)
                }
                
                // --- ZUSATZINFOS (Unter dem Hauptbereich) ---
                
                // 1. Hinweis Box (z.B. für KI Hints oder Sonderrollen)
                if let hint = parsedInfo.hint {
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        Image(systemName: "lightbulb.max.fill")
                            .foregroundStyle(.yellow)
                            .font(.title3)
                        
                        Text(hint)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white.opacity(0.9))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                }
                
                // 2. Mitspione Box (Kompakter & Zentriert)
                if !parsedInfo.otherSpies.isEmpty {
                    VStack(spacing: 12) {
                        // Header zentriert
                        HStack {
                            Spacer()
                            Image(systemName: "person.2.fill")
                                .foregroundStyle(.red)
                            Text("DEINE PARTNER")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.red.opacity(0.9))
                                .tracking(1.5)
                            Spacer()
                        }
                        
                        if #available(iOS 16.0, *) {
                            WrapHStack(items: parsedInfo.otherSpies) { name in
                                Text(name)
                                    .font(.system(size: 13, weight: .bold))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.red.opacity(0.15))
                                    .cornerRadius(8)
                                    .foregroundColor(.white)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.red.opacity(0.2), lineWidth: 1)
                                    )
                            }
                        } else {
                            // Fallback
                            HStack {
                                ForEach(parsedInfo.otherSpies, id: \.self) { name in
                                    Text(name).foregroundStyle(.white)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(20)
                    .padding(.horizontal, 30) // Macht die Box schmaler
                }
            }
        }
    }
    
    private func getMainText() -> String {
        let parts = card.displayWord.components(separatedBy: "\n\n")
        return parts.first ?? "???"
    }
}

// MARK: - Helpers (WrapStack)
@available(iOS 16.0, macOS 13.0, *) 
struct WrapHStack<Data: RandomAccessCollection, Content: View>: View where Data.Element: Hashable {
    let items: Data
    var spacing: CGFloat = 8
    var runSpacing: CGFloat = 8
    @ViewBuilder let content: (Data.Element) -> Content

    var body: some View {
        FlowRowsLayout(spacing: spacing, runSpacing: runSpacing) {
            ForEach(Array(items), id: \.self) { item in content(item) }
        }
    }
}

@available(iOS 16.0, macOS 13.0, *) 
private struct FlowRowsLayout: Layout {
    var spacing: CGFloat = 8
    var runSpacing: CGFloat = 8
    
    struct Row {
        var items: [(index: Int, size: CGSize)]
        var width: CGFloat
        var height: CGFloat
    }
    
    private func buildRows(for subviews: Subviews, maxWidth: CGFloat) -> [Row] {
        var rows: [Row] = []
        var currentItems: [(Int, CGSize)] = []
        var currentWidth: CGFloat = 0
        var currentHeight: CGFloat = 0
        
        func commit() {
            guard !currentItems.isEmpty else { return }
            rows.append(Row(items: currentItems, width: currentWidth, height: currentHeight))
            currentItems.removeAll(keepingCapacity: true)
            currentWidth = 0
            currentHeight = 0
        }
        
        for (idx, subview) in subviews.enumerated() {
            let size = subview.sizeThatFits(.unspecified)
            let width = size.width
            let height = size.height
            let proposedWidth = currentItems.isEmpty ? width : currentWidth + spacing + width
            
            if proposedWidth > maxWidth && !currentItems.isEmpty { commit() }
            
            if currentItems.isEmpty {
                currentItems.append((idx, size))
                currentWidth = width
                currentHeight = height
            } else {
                currentItems.append((idx, size))
                currentWidth += spacing + width
                currentHeight = max(currentHeight, height)
            }
        }
        commit()
        return rows
    }
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        let rows = buildRows(for: subviews, maxWidth: maxWidth)
        let height = rows.enumerated().reduce(CGFloat(0)) { partial, element in
            let rowHeight = element.element.height
            return partial + (element.offset == 0 ? 0 : runSpacing) + rowHeight
        }
        let widest = rows.map(\.width).max() ?? 0
        return CGSize(width: proposal.width ?? widest, height: height)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = buildRows(for: subviews, maxWidth: bounds.width)
        var currentY = bounds.minY
        
        for (rowIndex, row) in rows.enumerated() {
            let rowWidth = row.width
            var x = bounds.midX - rowWidth / 2
            for (idx, size) in row.items {
                let yOffset = (row.height - size.height) / 2
                subviews[idx].place(
                    at: CGPoint(x: x, y: currentY + yOffset),
                    proposal: ProposedViewSize(width: size.width, height: size.height)
                )
                x += size.width
                if idx != row.items.last?.index { x += spacing }
            }
            if rowIndex < rows.count - 1 { currentY += row.height + runSpacing }
        }
    }
}