import Foundation

enum TimesUpGameMode: String, CaseIterable, Codable {
    case classic = "Klassisch"
    case withDrawing = "Mit Zeichnen"
    case randomOrder = "Zufällige Reihenfolge"
    
    var description: String {
        switch self {
        case .classic:
            return "Das klassische Time's Up Spiel mit 3 Runden"
        case .withDrawing:
            return "Klassisch + 4. Runde mit Zeichnen"
        case .randomOrder:
            return "Begriffe in zufälliger Reihenfolge pro Runde"
        }
    }
    
    var totalRounds: Int {
        switch self {
        case .classic, .randomOrder:
            return 3
        case .withDrawing:
            return 4
        }
    }
    
    var shouldShufflePerRound: Bool {
        return self == .randomOrder
    }
}

enum Difficulty: String, CaseIterable, Codable {
    case easy = "Leicht"
    case medium = "Mittel"
    case hard = "Schwer"
}

enum GameRound: Int, CaseIterable, Codable {
    case round1 = 0
    case round2 = 1
    case round3 = 2
    case round4 = 3  // Neue 4. Runde für "Mit Zeichnen"
    
    var title: String {
        switch self {
        case .round1: return String(localized: "Runde 1")
        case .round2: return String(localized: "Runde 2")
        case .round3: return String(localized: "Runde 3")
        case .round4: return String(localized: "Runde 4")
        }
    }
    
    var description: String {
            switch self {
            case .round1: return String(localized: "Erklären")
            case .round2: return String(localized: "Nur ein Wort")
            case .round3: return String(localized: "Nur Pantomime")
            case .round4: return String(localized: "Zeichnen")
            }
    }
    
    var shortDescription: String {
        switch self {
        case .round1: return String(localized: "Erklären")
        case .round2: return String(localized: "Nur ein Wort")
        case .round3: return String(localized: "Nur Pantomime")
        case .round4: return String(localized: "Zeichnen")
        }
    }
    
    var canSkip: Bool {
        return self != .round1
    }
    
    var detailedRules: String {
        switch self {
        case .round1:
            return String(localized: "Du musst den vorgegebenen Begriff beschreiben. Du darfst keine Wörter verwenden, die zum Wortstamm des gesuchten Begriffs gehören, die gleich klingen, übersetzen oder buchstabieren.")
        case .round2:
            return String(localized: "Du darfst nur EIN Wort sagen. Das Team darf nur EINMAL raten. Wenn das Wort falsch ist, musst du es skippen.")
        case .round3:
            return String(localized: "Du darfst nur pantomimisch agieren - keine Geräusche, keine Wörter, nicht auf Dinge zeigen. Das Team darf nur EINMAL raten. Wenn das Wort falsch ist, musst du es skippen.")
        case .round4:
            return String(localized: "Du darfst nur zeichnen - keine Wörter, keine Geräusche, keine Pantomime, keine Buchstaben, keine Zahlen, keine Symbole. Das Team darf nur EINMAL raten. Wenn das Wort falsch ist, musst du es skippen.")
        }
    }
    
    // Hilfsmethode: Ist diese Runde für den gegebenen Modus verfügbar?
    func isAvailable(for mode: TimesUpGameMode) -> Bool {
        switch self {
        case .round1, .round2, .round3:
            return true  // Alle Modi haben die ersten 3 Runden
        case .round4:
            return mode == .withDrawing  // Nur "Mit Zeichnen" hat Runde 4
        }
    }
}

enum TimesUpGamePhase: Codable {
    case setup
    case playing
    case slotReward
    case roundEnd
    case gameEnd
}

struct TimesUpGameSettings: Codable {
    var teams: [Team] = []
    
    // HIER GEÄNDERT: TimesUpCategory statt Category
    var selectedCategories: [TimesUpCategory] = []
    
    var turnTimeLimit: TimeInterval = 30.0 // Zeit pro Zug (nicht pro Runde!)
    var gameMode: TimesUpGameMode = .classic
    var difficulty: Difficulty = .easy
    var wordCount: Int = 50 // Standard: 50 Wörter
    var perksEnabled: Bool = false
    var perkPartyMode: Bool = false
    var selectedPerkPacks: Set<PerkPack> = []
    var customPerks: Set<PerkType> = []
    
    var isValid: Bool {
        return teams.count >= 2 && !selectedCategories.isEmpty && availableWordCount >= wordCount
    }
    
    var availableWordCount: Int {
        return selectedCategories.reduce(0) { $0 + $1.terms.count }
    }
    
    var minWordCount: Int { 5 }
    var maxWordCount: Int { max(minWordCount, min(availableWordCount, 200)) } // Immer >= minWordCount
}

struct GameState: Codable {
    var settings: TimesUpGameSettings = TimesUpGameSettings()
    var currentRound: GameRound = .round1
    var currentTeamIndex: Int = 0
    var currentTermIndex: Int = 0
    var phase: TimesUpGamePhase = .setup
    var allTerms: [Term] = []
    var turnTimeRemaining: TimeInterval = 30.0 // Zeit für aktuellen Zug
    var isTimerRunning: Bool = false
    var teamTurnCounters: [UUID: Int] = [:]
    var teamHitStreaks: [UUID: Int] = [:]

    // Computed: indices of terms not completed in current round (and zugänglich für aktuelles Team)
    var availableIndices: [Int] {
        let teamId = activeTeamId
        return allTerms.enumerated().compactMap { index, term in
            isTermSelectable(term, for: teamId) ? index : nil
        }
    }

    private var availableIndicesForCurrentTurn: [Int] {
        return availableIndices.filter { !seenTermsInCurrentTurn.contains($0) }
    }

    // Debug dump for troubleshooting
    mutating func debugDump(context: String) {
        print("🧠 GameState | \(context)")
        print("  - round: \(currentRound.rawValue + 1)")
        print("  - team: \(currentTeamIndex)")
        print("  - currentTermIndex: \(currentTermIndex)")
        if let term = currentTerm {
            print("  - currentTerm: '\(term.text)' (\(term.id))")
        } else {
            print("  - currentTerm: nil")
        }
        print("  - remainingTermsCount: \(remainingTermsCount)")
        print("  - seenInTurn: \(seenTermsInCurrentTurn)")
        print("  - seenInRound: \(seenTermsInCurrentRound)")
        print("  - availableIndices: \(availableIndices)")
    }

    /// Picks next term index, trying to avoid the provided index when possible
    mutating func nextTerm(avoiding avoidIndex: Int?) {
        print("🔍 DEBUG: nextTerm(avoiding:) called | avoidIndex: \(avoidIndex?.description ?? "nil")")
        let candidates = availableIndices
        print("🔍 DEBUG: Candidates before selection: \(candidates)")
        guard !candidates.isEmpty else {
            print("🔍 DEBUG: No candidates available for current team")
            return
        }
        
        let teamId = activeTeamId
        let startIndex = resolvedIndexForCurrentTeam() ?? candidates.first!
        var iterations = 0
        var nextIndex = startIndex
        let maxIterations = allTerms.count * 2
        
        repeat {
            nextIndex = (nextIndex + 1) % allTerms.count
            iterations += 1
            
            guard isIndexSelectable(nextIndex, for: teamId) else { continue }
            if seenTermsInCurrentTurn.contains(nextIndex) { continue }
            
            if let avoid = avoidIndex, candidates.count > 1, nextIndex == avoid {
                print("🔍 DEBUG: Avoiding index \(avoid) once")
                continue
            }
            break
        } while iterations <= maxIterations
        
        currentTermIndex = nextIndex
        print("🔍 DEBUG: nextTerm(avoiding:) selected index: \(currentTermIndex) | term: '\(currentTerm?.text ?? "nil")'")
    }
    
    // Tracking für aktuellen Zug: Welche Begriffe hat das Team bereits gesehen?
    var seenTermsInCurrentTurn: Set<Int> = []
    
    // Globales Tracking für alle in der aktuellen Runde gesehenen Begriffe
    var seenTermsInCurrentRound: Set<Int> = []
    
    var currentTeam: Team? {
        guard currentTeamIndex < settings.teams.count else { return nil }
        return settings.teams[currentTeamIndex]
    }
    
    private var activeTeamId: UUID? {
        guard currentTeamIndex < settings.teams.count else { return nil }
        return settings.teams[currentTeamIndex].id
    }
    
    var currentTerm: Term? {
        guard let index = resolvedIndexForCurrentTeam() else { return nil }
        return allTerms[index]
    }

    
    // Hilfsmethode um aktuellen Begriff anzuzeigen UND als gesehen zu markieren
    mutating func getCurrentTermAndMarkSeen() -> Term? {
        guard let term = currentTerm else { return nil }
        
        // Markiere aktuellen Begriff als gesehen
        if let actualIndex = getCurrentTermIndex() {
            seenTermsInCurrentTurn.insert(actualIndex)
            seenTermsInCurrentRound.insert(actualIndex) // Auch global für Runde tracken
        }
        
        return term
    }
    
    var allTermsCompletedForCurrentRound: Bool {
        // Eine Runde ist beendet wenn ALLE Begriffe ABGESCHLOSSEN wurden
        // Startkarten müssen immer fertig sein. Strafkarten werden je Team bewertet.
        
        print("🔍 DEBUG: ===== ROUND COMPLETION CHECK =====")
        print("🔍 DEBUG: Current round: \(currentRound.rawValue + 1)")
        print("🔍 DEBUG: Total terms: \(allTerms.count)")
        print("🔍 DEBUG: Seen terms in current round: \(seenTermsInCurrentRound)")
        print("🔍 DEBUG: Seen terms in current turn: \(seenTermsInCurrentTurn)")
        
        let startTerms = allTerms.enumerated().filter { $0.element.assignedTeamId == nil }
        let startCompleted = startTerms.allSatisfy { $0.element.completedInRounds[currentRound.rawValue] }
        let completedCount = startTerms.filter { $0.element.completedInRounds[currentRound.rawValue] }.count
        let totalProcessed = startTerms.count
        
        if !startCompleted {
            print("🔍 DEBUG: Startkarten noch offen -> Runde läuft weiter")
            print("🔍 DEBUG: Completed: \(completedCount), Total Startkarten: \(totalProcessed)")
            print("🔍 DEBUG: ===== END ROUND CHECK =====")
            return false
        }
        
        // Bewertung der Strafkarten pro Team
        var penaltySummary: [(String, Int)] = []
        for team in settings.teams {
            let pending = allTerms.filter { term in
                term.assignedTeamId == team.id && !term.completedInRounds[currentRound.rawValue]
            }.count
            penaltySummary.append((team.name, pending))
        }
        
        penaltySummary.forEach { entry in
            print("🔍 DEBUG: Pending Penalties | \(entry.0): \(entry.1)")
        }
        
        let anyTeamClearedPenalties = penaltySummary.contains { $0.1 == 0 }
        print("🔍 DEBUG: Round completion result: \(anyTeamClearedPenalties) (Startkarten fertig & mind. ein Team ohne Strafkarten)")
        print("🔍 DEBUG: Completed Startkarten: \(completedCount), Total Startkarten: \(totalProcessed)")
        print("🔍 DEBUG: ===== END ROUND CHECK =====")
        
        return anyTeamClearedPenalties
    }
    
    var availableTermsForCurrentRound: [Term] {
        return allTerms.filter { !$0.completedInRounds[currentRound.rawValue] }
    }
    
    // Begriffe die für das aktuelle Team noch offen sind (in diesem Zug)
    var remainingTermsForCurrentTeam: [Term] {
        return availableIndicesForCurrentTurn.map { allTerms[$0] }
    }
    
    var remainingTermsCount: Int {
        return availableIndicesForCurrentTurn.count
    }
    
    mutating func nextTeam() {
        currentTeamIndex = (currentTeamIndex + 1) % settings.teams.count
        turnTimeRemaining = settings.turnTimeLimit // Reset Timer für neues Team
        
        // Reset der "gesehenen Begriffe" für das neue Team
        seenTermsInCurrentTurn.removeAll()
        
        // WICHTIG: currentTermIndex NICHT zurücksetzen!
        // Das nächste Team soll da weitermachen, wo das vorherige aufgehört hat
        // So bekommen sie nur die verbleibenden Begriffe zu sehen
    }
    
    mutating func nextRound() {
        // Finde nächste verfügbare Runde für aktuellen Spielmodus
        var nextRoundValue = currentRound.rawValue + 1
        var nextRound: GameRound?
        
        while nextRoundValue < 4 {
            if let candidateRound = GameRound(rawValue: nextRoundValue),
               candidateRound.isAvailable(for: settings.gameMode) {
                nextRound = candidateRound
                break
            }
            nextRoundValue += 1
        }
        
        guard let validNextRound = nextRound else {
            phase = .gameEnd
            return
        }
        
        currentRound = validNextRound
        
        // WICHTIG: Nächste Runde startet mit dem nächsten Team (nicht Team 0!)
        currentTeamIndex = (currentTeamIndex + 1) % settings.teams.count
        
        currentTermIndex = 0 // Reset Term Index
        turnTimeRemaining = settings.turnTimeLimit
        phase = .setup // Erst Setup für neue Runde
        
        // Reset für neue Runde
        seenTermsInCurrentTurn.removeAll()
        seenTermsInCurrentRound.removeAll()
        
        // Für "Zufällige Reihenfolge": Begriffe neu mischen
        if settings.gameMode.shouldShufflePerRound {
            allTerms.shuffle()
        }
    }
    
    mutating func markCurrentTermCompleted() {
        // Finde den aktuellen Begriff-Index
        guard let actualIndex = getCurrentTermIndex(), actualIndex < allTerms.count else { return }
        
        // Markiere als erraten
        allTerms[actualIndex].markCompleted(in: currentRound.rawValue, for: settings.gameMode)
        
        // Markiere als gesehen in diesem Zug
        seenTermsInCurrentTurn.insert(actualIndex)
        seenTermsInCurrentRound.insert(actualIndex) // Auch global für Runde tracken
    }
    
    mutating func nextTerm() {
        nextTerm(avoiding: nil)
    }
    
    // Prüfe ob das aktuelle Team alle verfügbaren Begriffe bereits gesehen hat
    var hasTeamSeenAllAvailableTerms: Bool {
        let availableIndices = Set(self.availableIndices)
        
        print("🔍 DEBUG: ===== TEAM SEEN ALL CHECK =====")
        print("🔍 DEBUG: Available indices: \(availableIndices)")
        print("🔍 DEBUG: Seen in current turn: \(seenTermsInCurrentTurn)")
        print("🔍 DEBUG: Is subset: \(availableIndices.isSubset(of: seenTermsInCurrentTurn))")
        print("🔍 DEBUG: ===== END TEAM CHECK =====")
        
        // Wenn das Team alle verfügbaren Begriffe gesehen hat
        return availableIndices.isSubset(of: seenTermsInCurrentTurn)
    }
    
    // Prüfe ob das aktuelle Team alle verfügbaren Begriffe bereits gesehen hat (für Zug-Ende)
    var hasTeamSeenAllAvailableTermsForTurn: Bool {
        let remainingStart = Set(availableIndices.filter { isStartCard(index: $0) && !seenTermsInCurrentTurn.contains($0) })
        let remainingReadyPenalties = Set(availableIndices.filter { !isStartCard(index: $0) &&
            isPenaltyTermActive(allTerms[$0]) &&
            !seenTermsInCurrentTurn.contains($0)
        })
        
        print("🔍 DEBUG: ===== TEAM TURN END CHECK (Hard-aware) =====")
        print("🔍 DEBUG: Remaining start indices: \(remainingStart)")
        print("🔍 DEBUG: Remaining ready penalties: \(remainingReadyPenalties)")
        print("🔍 DEBUG: Seen in current turn: \(seenTermsInCurrentTurn)")
        print("🔍 DEBUG: ===== END TURN CHECK =====")
        
        return remainingStart.isEmpty && remainingReadyPenalties.isEmpty
    }
    
    mutating func markCurrentTermAsSeen() {
        guard let actualIndex = getCurrentTermIndex() else { return }
        seenTermsInCurrentTurn.insert(actualIndex)
        seenTermsInCurrentRound.insert(actualIndex) // Auch global für Runde tracken
    }
    
    // Reset für neuen Zug
    mutating func startNewTurn() {
        seenTermsInCurrentTurn.removeAll()
        turnTimeRemaining = settings.turnTimeLimit
        if currentTeamIndex < settings.teams.count {
            let teamId = settings.teams[currentTeamIndex].id
            teamTurnCounters[teamId, default: 0] += 1
        }
    }
    
    // Public helper to expose the resolved current term index (used by GameManager)
    func resolvedCurrentTermIndex() -> Int {
        return resolvedIndexForCurrentTeam() ?? currentTermIndex
    }
    
    private func getCurrentTermIndex() -> Int? {
        return resolvedIndexForCurrentTeam()
    }
    
    private func resolvedIndexForCurrentTeam(startingFrom startIndex: Int? = nil) -> Int? {
        guard !allTerms.isEmpty else { return nil }
        let baseStart = startIndex ?? currentTermIndex
        let boundedStart = ((baseStart % allTerms.count) + allTerms.count) % allTerms.count
        return nextSelectableIndex(startingFrom: boundedStart, teamId: activeTeamId)
    }
    
    private func nextSelectableIndex(startingFrom startIndex: Int, teamId: UUID?) -> Int? {
        guard !allTerms.isEmpty else { return nil }
        for offset in 0..<allTerms.count {
            let index = (startIndex + offset) % allTerms.count
            if isIndexSelectable(index, for: teamId) {
                return index
            }
        }
        return nil
    }
    
    private func isIndexSelectable(_ index: Int, for teamId: UUID?) -> Bool {
        guard index >= 0 && index < allTerms.count else { return false }
        let term = allTerms[index]
        return isTermSelectable(term, for: teamId)
    }
    
    private func isTermSelectable(_ term: Term, for teamId: UUID?) -> Bool {
        if term.completedInRounds[currentRound.rawValue] {
            return false
        }
        guard let assignedTeam = term.assignedTeamId else {
            return true
        }
        guard let teamId = teamId, assignedTeam == teamId else {
            return false
        }
        let currentTurn = teamTurnCounters[teamId] ?? 0
        return currentTurn >= term.availableFromTeamTurn
    }
    
    private func isStartCard(index: Int) -> Bool {
        guard index < allTerms.count else { return true }
        return allTerms[index].assignedTeamId == nil
    }
    
    private func isPenaltyCardReady(term: Term, teamId: UUID?) -> Bool {
        guard let assigned = term.assignedTeamId,
              let teamId = teamId,
              assigned == teamId else { return false }
        let currentTurn = teamTurnCounters[teamId] ?? 0
        return currentTurn >= term.availableFromTeamTurn
    }
    
    private func isPenaltyTermActive(_ term: Term) -> Bool {
        guard let owner = term.assignedTeamId else { return false }
        let turnCount = teamTurnCounters[owner] ?? 0
        return turnCount >= term.availableFromTeamTurn
    }

    mutating func resetTeamTurnCounters() {
        teamTurnCounters = Dictionary(uniqueKeysWithValues: settings.teams.map { ($0.id, 0) })
    }
}

extension TimesUpGameSettings {
    var selectedStandardPerkPacks: Set<PerkPack> {
        selectedPerkPacks.filter { !$0.isCustom }
    }
    
    var hasAnyPerkSelection: Bool {
        !selectedStandardPerkPacks.isEmpty || !customPerks.isEmpty
    }
    
    mutating func setCustomPerk(_ perk: PerkType, enabled: Bool) {
        if enabled {
            customPerks.insert(perk)
            selectedPerkPacks.insert(.custom)
        } else {
            customPerks.remove(perk)
            if customPerks.isEmpty {
                selectedPerkPacks.remove(.custom)
            }
        }
    }
    
    mutating func clearCustomPerks() {
        customPerks.removeAll()
        selectedPerkPacks.remove(.custom)
    }
}
