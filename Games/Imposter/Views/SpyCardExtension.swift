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
        .frame(width: 350, height: 500)
        .offset(offset)
        .scaleEffect(isMovingOut ? 0.8 : 1.0)
        .opacity(isMovingOut ? 0.3 : 1.0)
        .onTapGesture {
            handleCardTap()
        }
        .animation(.spring(response: 0.8, dampingFraction: 0.8), value: rotationAngle)
        .animation(.easeInOut(duration: 0.6), value: offset)
        .animation(.easeInOut(duration: 0.6), value: isMovingOut)
    }
    
    private func handleCardTap() {
        if !isFlipped {
            // Erste Berührung: Karte umdrehen
            flipCard()
            onCardTap()
        } else if !isMovingOut {
            // Zweite Berührung: Karte wegbewegen
            moveCardOut()
        }
    }
    
    private func flipCard() {
        withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
            rotationAngle += 180
            isFlipped = true
        }
    }
    
    private func moveCardOut() {
        withAnimation(.easeInOut(duration: 0.6)) {
            offset = CGSize(width: -400, height: -50)
            isMovingOut = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            onCardDismissed()
        }
    }
}

// MARK: - Card Back View
struct CardBackView: View {
    let playerName: String
    
    private let cornerRadius: CGFloat = 28
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.16, green: 0.18, blue: 0.24),
                            Color(red: 0.09, green: 0.1, blue: 0.15)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
            
            VStack(spacing: 28) {
                VStack(spacing: 8) {
                    Text("Nächster Spieler")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.white.opacity(0.7))
                    Text(playerName)
                        .font(.title.weight(.bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                }
                
                VStack(spacing: 10) {
                    Circle()
                        .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
                        .background(Circle().fill(Color.white.opacity(0.07)))
                        .frame(width: 110, height: 110)
                        .overlay(
                            Image(systemName: "eye")
                                .font(.system(size: 44, weight: .bold))
                                .foregroundColor(.white)
                        )
                    
                    Text("Karte verdeckt halten")
                        .font(.footnote)
                        .foregroundColor(.white.opacity(0.65))
                }
                
                VStack(spacing: 6) {
                    Text("Bereit zum Aufdecken")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("Tippe einmal, um deine Rolle zu sehen,\nund danach noch einmal zum Weitergeben.")
                        .font(.footnote)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 16)
            }
            .padding(32)
        }
        .shadow(color: .black.opacity(0.35), radius: 20, y: 10)
    }
}

// MARK: - Spy Card Front View
struct SpyCardFrontView: View {
    let card: GameCard
    let gameSettings: GameSettings
    @Environment(\.colorScheme) var colorScheme
    
    private struct SpyInfo {
        var categoryEmoji: String?
        var categoryName: String?
        var hint: String?
        var otherSpies: [String] = []
    }
    
    private var hasStructuredSpyInfo: Bool {
        parsedSpyInfo.categoryEmoji != nil || parsedSpyInfo.hint != nil || !parsedSpyInfo.otherSpies.isEmpty
    }
    
    private var parsedSpyInfo: SpyInfo {
        guard card.isImposter else { return SpyInfo() }
        let lines = card.displayWord
            .split(separator: "\n")
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        var info = SpyInfo()
        var i = 0
        while i < lines.count {
            let line = lines[i]
            if line.hasPrefix("Hinweis:") {
                info.hint = line.replacingOccurrences(of: "Hinweis:", with: "").trimmingCharacters(in: .whitespaces)
            } else if line.hasPrefix("Mitspione:") {
                var names: [String] = []
                var j = i + 1
                while j < lines.count {
                    let nline = lines[j]
                    if nline.lowercased().hasPrefix("du bist der spion") { break }
                    let parts = nline.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
                    names.append(contentsOf: parts.filter { !$0.isEmpty })
                    j += 1
                }
                info.otherSpies = names
            } else if line.count >= 2, let first = line.first, first.isEmojiLike {
                let comps = line.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true)
                if comps.count == 2 {
                    info.categoryEmoji = String(comps[0])
                    info.categoryName = String(comps[1]).trimmingCharacters(in: .whitespaces)
                }
            }
            i += 1
        }
        return info
    }
    
    private var backgroundGradient: LinearGradient {
        let colors: [Color] = card.isImposter
        ? [Color(red: 0.33, green: 0.07, blue: 0.15), Color(red: 0.12, green: 0.02, blue: 0.07)]
        : [Color(red: 0.08, green: 0.14, blue: 0.28), Color(red: 0.03, green: 0.06, blue: 0.14)]
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(backgroundGradient)
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    headerSection
                    
                    if card.isImposter {
                        spyContent
                    } else {
                        citizenContent
                    }
                    
                    Text("Tippe erneut, um die Karte weiterzugeben")
                        .font(.footnote.weight(.medium))
                        .foregroundColor(.white.opacity(0.65))
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                }
        .frame(maxWidth: .infinity, alignment: .center)
                .padding(28)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: .black.opacity(0.35), radius: 16, y: 8)
    }
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: card.isImposter ? "eye.slash.fill" : "checkmark.seal.fill")
                .font(.title2)
                .foregroundColor(card.isImposter ? .red : .blue)
            Text(card.isImposter ? "IMPOSTER" : "DEINE KARTE")
                .font(.headline.weight(.bold))
                .foregroundColor(.white)
        }
    }
    
    @ViewBuilder
    private var spyContent: some View {
        if let categoryEmoji = parsedSpyInfo.categoryEmoji,
           let categoryName = parsedSpyInfo.categoryName {
            InfoTile(title: "Kategorie", icon: "folder.fill", alignment: .center) {
                Text("\(categoryEmoji) \(categoryName)")
                    .font(.title3.weight(.semibold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
            }
        }
        
        if let hint = parsedSpyInfo.hint, !hint.isEmpty {
            InfoTile(title: "Hinweis", icon: "lightbulb.fill", alignment: .center) {
                Text(hint)
                    .font(.body.weight(.medium))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        
        if !parsedSpyInfo.otherSpies.isEmpty {
            InfoTile(title: "Mitspione", icon: "person.2.fill", alignment: .center) {
                if #available(iOS 16.0, *) {
                    WrapHStack(items: parsedSpyInfo.otherSpies, spacing: 8, runSpacing: 8) { spyName in
                        spyChip(named: spyName)
                    }
                } else {
                    ForEach(parsedSpyInfo.otherSpies, id: \.self) { spyName in
                        spyChip(named: spyName)
                    }
                }
            }
        }
        
        if !hasStructuredSpyInfo {
            InfoTile(title: "Mission", icon: "target", alignment: .center) {
                let fallback = card.displayWord.trimmingCharacters(in: .whitespacesAndNewlines)
                Text(fallback.isEmpty ? "Bleib undercover und finde das geheime Wort." : fallback)
                    .font(.body.weight(.medium))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
    
    private func spyChip(named name: String) -> some View {
        Text(name)
            .font(.subheadline.weight(.semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.08))
            )
    }
    
    private var citizenContent: some View {
        VStack(spacing: 16) {
            InfoTile(title: "Kategorie", icon: "folder.fill") {
                Text("\(card.category.emoji) \(card.category.name)")
                    .font(.title3.weight(.semibold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
            }
            
            InfoTile(title: "Dein Wort") {
                Text(card.displayWord)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(5)
                    .minimumScaleFactor(0.5)
            }
        }
    }
}

private struct InfoTile<Content: View>: View {
    let title: String
    var icon: String?
    var alignment: HorizontalAlignment = .center
    @ViewBuilder var content: () -> Content
    
    var body: some View {
        VStack(alignment: alignment, spacing: 10) {
            HStack(spacing: 6) {
                if let icon {
                    Image(systemName: icon)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.white.opacity(0.8))
                }
                Text(title.uppercased())
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.white.opacity(0.6))
            }
            .frame(maxWidth: .infinity, alignment: .center)
            content()
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .frame(maxWidth: .infinity)
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.05))
        )
    }
}


// MARK: - WrapHStack (Flow layout for chips)
@available(iOS 16.0, macOS 13.0, *)
struct WrapHStack<Data: RandomAccessCollection, Content: View>: View where Data.Element: Hashable {
    let items: Data
    var spacing: CGFloat = 8
    var runSpacing: CGFloat = 8
    @ViewBuilder let content: (Data.Element) -> Content

    var body: some View {
        FlowRowsLayout(spacing: spacing, runSpacing: runSpacing) {
            ForEach(Array(items), id: \.self) { item in
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
    let samplePlayer = Player(name: "Max Mustermann")
    let sampleCategory = Category.defaultCategories[0]
    let sampleCard = GameCard(player: samplePlayer, category: sampleCategory)
    let gameSettings = GameSettings()
    gameSettings.spyCanSeeCategory = true
    gameSettings.spiesCanSeeEachOther = true
    
    return SpyCardView(
        card: sampleCard,
        gameSettings: gameSettings,
        onCardTap: { print("Card tapped") },
        onCardDismissed: { print("Card dismissed") }
    )
    .padding()
    .background(
        LinearGradient(
            colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
}
