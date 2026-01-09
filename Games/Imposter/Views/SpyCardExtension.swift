//
//  SpyCardExtension.swift
//  Imposter
//
//  Created by Ken on 22.09.25.
//

import SwiftUI

private extension Character {
    var isEmojiLike: Bool {
        unicodeScalars.contains { $0.properties.isEmojiPresentation }
    }
}

// MARK: - Spy Card mit zusätzlichen Informationen
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
    
    var body: some View {
        ZStack {
            // Kartenrückseite
            CardBackView(playerName: card.player.name)
                .opacity(isFlipped ? 0 : 1)
                .rotation3DEffect(
                    .degrees(rotationAngle),
                    axis: (x: 0, y: 1, z: 0)
                )
            
            // Kartenvorderseite mit Spy-Features
            SpyCardFrontView(card: card, gameSettings: gameSettings)
                .opacity(isFlipped ? 1 : 0)
                .rotation3DEffect(
                    .degrees(rotationAngle + 180),
                    axis: (x: 0, y: 1, z: 0)
                )
        }
        .frame(width: 320, height: 480)
        .offset(offset)
        .scaleEffect(isMovingOut ? 0.8 : 1.0)
        .opacity(isMovingOut ? 0.0 : 1.0)
        .onTapGesture {
            handleCardTap()
        }
        .animation(.spring(response: 0.6, dampingFraction: 0.7), value: rotationAngle)
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: offset)
        .animation(.easeIn(duration: 0.4), value: isMovingOut)
    }
    
    private func handleCardTap() {
        if !isFlipped {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            flipCard()
            onCardTap()
        } else if !isMovingOut {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            moveCardOut()
        }
    }
    
    private func flipCard() {
        rotationAngle += 180
        isFlipped = true
    }
    
    private func moveCardOut() {
        offset = CGSize(width: -400, height: 0)
        isMovingOut = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            onCardDismissed()
        }
    }
}

// MARK: - Card Back View
struct CardBackView: View {
    let playerName: String
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(white: 0.15), Color(white: 0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.4), radius: 15, y: 10)
            
            VStack(spacing: 30) {
                Text("DEINE ROLLE")
                    .font(.caption.bold())
                    .tracking(2)
                    .foregroundColor(.white.opacity(0.5))
                
                ZStack {
                    Circle()
                        .strokeBorder(
                            LinearGradient(colors: [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing),
                            lineWidth: 3
                        )
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "person.fill.questionmark")
                        .font(.system(size: 50))
                        .foregroundColor(.white)
                }
                .shadow(color: .orange.opacity(0.3), radius: 10)
                
                VStack(spacing: 8) {
                    Text(playerName)
                        .font(.title.bold())
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text("Tippen zum Umdrehen")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .padding(30)
        }
    }
}

// MARK: - Spy Card Front View
struct SpyCardFrontView: View {
    let card: GameCard
    let gameSettings: GameSettings
    
    struct SpyInfo {
        var categoryEmoji: String?
        var categoryName: String?
        var hint: String?
        var otherSpies: [String] = []
    }
    
    private var parsedSpyInfo: SpyInfo {
        // Erweiterte Parsing-Logik für alle Rollen
        var info = SpyInfo()
        
        // 1. Kategorie extrahieren (wird vom HintsManager oder GameLogic gesetzt)
        info.categoryEmoji = card.category.emoji
        info.categoryName = card.category.name
        
        // 2. Text analysieren
        let parts = card.displayWord.components(separatedBy: "\n\n")
        
        // Teil 1 ist meist das Wort (oder Fake-Wort)
        // Teil 2+ sind Zusatzinfos
        
        if parts.count > 1 {
            // Wir haben Zusatzinfos!
            for part in parts.dropFirst() {
                if part.contains("Verdächtige") || part.contains("Zwilling") || part.contains("Sicherer") || part.contains("Der Spion") {
                    info.hint = part // Wir nutzen das 'hint' Feld für generische Rollen-Infos
                } else if part.hasPrefix("Mitspione:") {
                    // Legacy Support für alte Logik
                    let names = part.replacingOccurrences(of: "Mitspione:", with: "").components(separatedBy: ",")
                    info.otherSpies = names.map { $0.trimmingCharacters(in: .whitespaces) }
                } else if part.hasPrefix("Hinweis:") {
                    info.hint = part.replacingOccurrences(of: "Hinweis:", with: "").trimmingCharacters(in: .whitespaces)
                }
            }
        }
        
        return info
    }
    
    private var cardBackground: LinearGradient {
        // Mapping von Farbnamen zu echten Farben
        let colorName = card.cardColorName
        let baseColor: Color
        
        switch colorName {
        case "darkRed": baseColor = Color(red: 0.5, green: 0.1, blue: 0.1)
        case "darkBlue": baseColor = Color(red: 0.1, green: 0.2, blue: 0.4)
        case "darkPurple": baseColor = Color(red: 0.3, green: 0.1, blue: 0.4)
        default: baseColor = Color(red: 0.1, green: 0.2, blue: 0.4)
        }
        
        return LinearGradient(
            colors: [baseColor, Color.black],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.5), radius: 20, y: 10)
            
            VStack(spacing: 25) {
                // HEADER
                HStack {
                    Image(systemName: card.cardIcon)
                    Text(card.cardTitle)
                }
                .font(.headline.bold())
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.black.opacity(0.4))
                .clipShape(Capsule())
                
                Spacer()
                
                // CONTENT
                if card.roleType != nil {
                    // Neue Rollen-Logik
                    RoleCardContent(card: card, parsedInfo: parsedSpyInfo, gameSettings: gameSettings)
                } else if card.isImposter {
                    // Klassischer Spion (Fallback/Standard)
                    spyContent
                } else {
                    // Klassischer Bürger (Fallback/Standard)
                    citizenContent
                }
                
                Spacer()
                
                Text("Tippe erneut zum Schließen")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(30)
        }
    }
    
    @ViewBuilder
    private var spyContent: some View {
        // ... (Der bestehende Spy-Content Code bleibt hier als Fallback, falls roleType nil ist)
        VStack(spacing: 20) {
            if let emoji = parsedSpyInfo.categoryEmoji, let name = parsedSpyInfo.categoryName {
                VStack(spacing: 8) {
                    Text("KATEGORIE")
                        .font(.caption.bold())
                        .foregroundColor(.white.opacity(0.6))
                    Text("\(emoji) \(name)")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                }
            }
            
            // ... Rest vom alten Code für SpyContent
            if let hint = parsedSpyInfo.hint {
                VStack(spacing: 8) {
                    Label("HINWEIS", systemImage: "lightbulb.fill")
                        .font(.caption.bold())
                        .foregroundColor(.yellow)
                    Text(hint)
                        .font(.body.italic())
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                }
            }
            
            if !parsedSpyInfo.otherSpies.isEmpty {
                VStack(spacing: 8) {
                    Text("MITSPIONE")
                        .font(.caption.bold())
                        .foregroundColor(.red)
                    
                    if #available(iOS 16.0, *) {
                        WrapHStack(items: parsedSpyInfo.otherSpies) { name in
                            Text(name)
                                .font(.caption.bold())
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.red.opacity(0.2))
                                .cornerRadius(8)
                                .foregroundColor(.white)
                        }
                    } else {
                        HStack {
                            ForEach(parsedSpyInfo.otherSpies, id: \.self) { name in
                                Text(name)
                                    .font(.caption.bold())
                                    .foregroundColor(.white)
                            }
                        }
                    }
                }
            }
            
            if !hasStructuredSpyInfo {
                Text(card.shortInstruction) // Nutze die neue Property
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    @ViewBuilder
    private var citizenContent: some View {
        VStack(spacing: 20) {
            VStack(spacing: 4) {
                Text("KATEGORIE")
                    .font(.caption.bold())
                    .foregroundColor(.white.opacity(0.6))
                Text("\(card.category.emoji) \(card.category.name)")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.9))
            }
            
            Divider().background(Color.white.opacity(0.2))
            
            VStack(spacing: 10) {
                Text("DEIN WORT")
                    .font(.caption.bold())
                    .foregroundColor(.blue)
                
                Text(card.displayWord)
                    .font(.system(size: 32, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .minimumScaleFactor(0.5)
            }
            
            Spacer()
            Text(card.shortInstruction)
                .font(.footnote)
                .foregroundColor(.white.opacity(0.6))
        }
    }
    
    private var hasStructuredSpyInfo: Bool {
        parsedSpyInfo.categoryEmoji != nil || parsedSpyInfo.hint != nil || !parsedSpyInfo.otherSpies.isEmpty
    }
}

// MARK: - Role Card Content (Neu für Rollen-Modus)
struct RoleCardContent: View {
    let card: GameCard
    let parsedInfo: SpyCardFrontView.SpyInfo
    let gameSettings: GameSettings
    
    var body: some View {
        VStack(spacing: 10) { // Reduziertes Spacing (war 20)
            // 1. Kategorie
            if let emoji = parsedInfo.categoryEmoji, let name = parsedInfo.categoryName {
                VStack(spacing: 4) { // Kompakter
                    Text("KATEGORIE")
                        .font(.caption.bold())
                        .foregroundColor(.white.opacity(0.6))
                    Text("\(emoji) \(name)")
                        .font(.title3.bold()) // Etwas kleiner (war title2)
                        .foregroundColor(.white)
                }
                .padding(.top, 0) // Ganz nach oben
            }
            
            Divider().background(Color.white.opacity(0.2))
            
            // 2. Interaktive Rollen (Hacker & Leibwächter)
            if let role = card.roleType, (role == .hacker || role == .bodyguard) {
                RoleActionView(
                    role: role,
                    players: gameSettings.players,
                    currentPlayer: card.player
                ) { target in
                    // Aktion ausführen
                    if let index = gameSettings.players.firstIndex(where: { $0.id == target.id }) {
                        if role == .bodyguard {
                            gameSettings.players[index].isProtected = true
                        }
                    }
                }
                // KEIN Spacer und KEIN shortInstruction hier, um Platz zu sparen
            } else {
                // Standard Anzeige für andere Rollen
                
                // 3. Das Wort (oder Pseudo-Wort)
                let hasExtraInfo = parsedInfo.hint != nil || !parsedInfo.otherSpies.isEmpty
                
                VStack(spacing: 10) {
                    Text("DEIN WORT")
                        .font(.caption.bold())
                        .foregroundColor(.blue)
                    
                    let mainText = getMainText()
                    Text(mainText)
                        .font(.system(size: hasExtraInfo ? 28 : 36, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .minimumScaleFactor(0.5)
                }
                
                // 4. Zusatzinfos (Verdächtige, Partner etc.)
                if let infoText = parsedInfo.hint {
                    VStack(spacing: 8) {
                        Label("INFO", systemImage: "info.circle.fill")
                            .font(.caption.bold())
                            .foregroundColor(.yellow)
                        Text(infoText)
                            .font(.body.bold())
                            .foregroundColor(.white.opacity(0.95))
                            .multilineTextAlignment(.center)
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(12)
                    }
                }
                
                // 5. Mission / Kurzanweisung (nur für nicht-interaktive Rollen)
                Spacer()
                Text(card.shortInstruction)
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
    }
    
    private func getMainText() -> String {
        // Extrahiere das Wort aus dem Gesamttext.
        let parts = card.displayWord.components(separatedBy: "\n\n")
        if let first = parts.first {
            return first
        }
        return "???"
    }
}

// MARK: - WrapHStack Implementation
@available(iOS 16.0, macOS 13.0, *) 
struct WrapHStack<Data: RandomAccessCollection, Content: View>: View where Data.Element: Hashable {
    let items: Data
    var spacing: CGFloat = 8
    var runSpacing: CGFloat = 8
    @ViewBuilder let content: (Data.Element) -> Content

    var body: some View {
        FlowRowsLayout(spacing: spacing, runSpacing: runSpacing) {
            ForEach(Array(items), id: \.self) {
                item in 
                content(item)
            }
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
            
            if proposedWidth > maxWidth && !currentItems.isEmpty {
                commit()
            }
            
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
            if element.offset == 0 {
                return partial + rowHeight
            } else {
                return partial + runSpacing + rowHeight
            }
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
                if idx != row.items.last?.index {
                    x += spacing
                }
            }
            if rowIndex < rows.count - 1 {
                currentY += row.height + runSpacing
            }
        }
    }
}

#Preview {
    let settings = GameSettings()
    let player = Player(name: "Max")
    // Wir setzen die View hier als letztes Statement, ohne 'return'
    SpyCardView(
        card: GameCard(player: player, category: Category.defaultCategories[0]),
        gameSettings: settings,
        onCardTap: {},
        onCardDismissed: {}
    )
    .padding()
    .background(Color.black)
}
