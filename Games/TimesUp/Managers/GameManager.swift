import Foundation
import SwiftUI
import Combine

@MainActor
class GameManager: ObservableObject {
    private final class RepeatingMainTimer {
        private var timer: Timer?
        
        func start(interval: TimeInterval, handler: @escaping @MainActor () -> Void) {
            timer?.invalidate()
            timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
                Task { @MainActor in handler() }
            }
        }
        
        func invalidate() {
            timer?.invalidate()
            timer = nil
        }
        
        deinit {
            timer?.invalidate()
        }
    }
    @Published var gameState = GameState()
    @Published var scoreRevealSnapshots: [UUID: ScoreRevealSnapshot] = [:]
    @Published var awardedPerks: [AwardedPerk] = []
    @Published private var visualEffects: [UUID: VisualEffectState] = [:]
    @Published private var skipButtonFreezeUntil: [UUID: Date] = [:]
    private var pendingVisualEffects: [UUID: [VisualEffectRequest]] = [:]
    
    private func notifyUIChange() {
        DispatchQueue.main.async { [weak self] in
            self?.objectWillChange.send()
        }
    }
    private enum LastAction: String { case none, next, skip, wrongGuess, correct, turnEnd, roundEnd }
    private enum MissReason { case skip, wrongGuess }
    private var lastAction: LastAction = .none
    private var lastSkippedIndex: Int?
    private var penaltyCardCounter: Int = 0
    private var perksTriggeredThisTurn: Int = 0
    private var lastPerkTypeThisTurn: PerkType?
    private var timerFreezeTeamId: UUID?
    private var timerFreezeRemaining: TimeInterval = 0
    private var pendingTurnTimePenalty: [UUID: TimeInterval] = [:]
    private var nextWordMultiplier: [UUID: Int] = [:]
    private var turnPointMultiplier: [UUID: Int] = [:]
    private var shieldCharges: [UUID: Int] = [:]
    private var rewindBonusTeams: Set<UUID> = []
    private var comboBonusCounters: [UUID: Int] = [:]
    private var assistListeners: [UUID: [UUID]] = [:]
    private var pausePenaltyTargets: Set<UUID> = []
    private var pendingSwapWordTeams: Set<UUID> = []
    private var swapWordTasks: [UUID: DispatchWorkItem] = [:]
    private var pendingTimeBombTargets: Set<UUID> = []
    private var activeTimeBombTimers: [UUID: RepeatingMainTimer] = [:]
    private var suddenRushExpiry: [UUID: Date] = [:]
    private var pendingInvisibleWordTargets: Set<UUID> = []
    private var invisibleWordActiveTeams: Set<UUID> = []
    private var invisibleWordHiddenTeams: Set<UUID> = []
    private var invisibleWordHideTasks: [UUID: DispatchWorkItem] = [:]
    private var activeStealBadges: Set<UUID> = []
    private var forcedSkipTeams: Set<UUID> = []
    private var activeForcedSkipTeamId: UUID?
    private var slowMotionFlashUntil: [UUID: Date] = [:]
    private let wordTranslationManager = WordTranslationManager()
    private struct EnglishWordEffectState {
        var translation: String?
        var expiresAt: Date?
        var pendingTerm: String?
    }
    private var englishWordEffects: [UUID: EnglishWordEffectState] = [:]
    private var englishWordExpiryTasks: [UUID: DispatchWorkItem] = [:]
    @Published private(set) var perkToast: PerkToast?
    @Published private(set) var timerValueBursts: [TimerValueBurst] = []
    private var slotSpinCredits: [UUID: Int] = [:]
    private var pendingSlotSpinCredits: [UUID: Int] = [:]
    @Published private(set) var slotRewardActiveTeamId: UUID?
    @Published private(set) var slotLastResult: SlotSpinResult?
    @Published private(set) var scoreBursts: [ScoreBurst] = []
    private var attackNotices: [UUID: [PerkAttackNotice]] = [:]
    private var attackNoticeExpiryTasks: [UUID: [UUID: DispatchWorkItem]] = [:]
    private let skipFreezeDuration: TimeInterval = 10
    private var maxPerksPerTurn: Int {
        gameState.settings.perkPartyMode ? 3 : 2
    }

    private var appLocale: Locale {
        let defaults = UserDefaults.standard
        let useSystem: Bool
        if defaults.object(forKey: "useSystemLanguage") == nil {
            useSystem = true
        } else {
            useSystem = defaults.bool(forKey: "useSystemLanguage")
        }
        if useSystem {
            return AppLanguage.fromSystemPreferred().locale
        }
        let code = defaults.string(forKey: "selectedLanguageCode")
        return AppLanguage.from(code: code).locale
    }

    private func localized(_ key: String.LocalizationValue, _ args: CVarArg...) -> String {
        let format = String(localized: key, locale: appLocale)
        guard !args.isEmpty else { return format }
        return String(format: format, locale: appLocale, arguments: args)
    }
    
    private enum VisualEffectKind {
        case mirror
        case glitch
    }
    
    private struct VisualEffectState {
        var mirrorUntil: Date?
        var glitchUntil: Date?
    }
    
    private struct VisualEffectRequest {
        let kind: VisualEffectKind
        let duration: TimeInterval
    }
    
    struct PerkToast: Identifiable {
        let id = UUID()
        let icon: String
        let message: String
    }
    
    struct PerkNotice: Identifiable {
        let id = UUID()
        let icon: String
        let text: String
        let isNegative: Bool
    }

    struct PerkAttackNotice: Identifiable {
        let id = UUID()
        let icon: String
        let label: String
        let targetName: String
    }
    
    struct TimerValueBurst: Identifiable {
        let id = UUID()
        let teamId: UUID
        let text: String
        let isNegative: Bool
    }
    
    struct SlotSpinResult: Identifiable {
        let id = UUID()
        let text: String
        let isWin: Bool
    }
    
    struct ScoreBurst: Identifiable {
        let id = UUID()
        let teamId: UUID
        let text: String
        let isNegative: Bool
    }
    
    private let turnTimer = RepeatingMainTimer()
    private let categoryManager: CategoryManager
    
    struct ScoreRevealSnapshot {
        let preScore: Int
        let penalty: Int
        let finalScore: Int
    }
    
    struct AwardedPerk: Identifiable {
        let id = UUID()
        let teamId: UUID
        let teamName: String
        let round: GameRound
        let type: PerkType
        let streak: Int
    }
    
    var availableCategories: [TimesUpCategory] {
            return categoryManager.categories
        }
    
    init(categoryManager: CategoryManager? = nil) {
        self.categoryManager = categoryManager ?? CategoryManager()
    }
    
    deinit {
        // Safe invalidation
        Task { @MainActor [weak self] in
            self?.turnTimer.invalidate()
            self?.activeTimeBombTimers.values.forEach { $0.invalidate() }
        }
    }
    
    // MARK: - Setup
    // Categories werden jetzt vom CategoryManager verwaltet
    
    // MARK: - Team Management
    func addTeam(name: String) {
        guard !name.isEmpty else { return }
        let team = Team(name: name)
        gameState.settings.teams.append(team)
        gameState.teamTurnCounters[team.id] = 0
        gameState.teamHitStreaks[team.id] = 0
        nextWordMultiplier[team.id] = 1
        turnPointMultiplier[team.id] = 1
    }
    
    func removeTeam(_ team: Team) {
        gameState.settings.teams.removeAll { $0.id == team.id }
        gameState.teamTurnCounters[team.id] = nil
        gameState.teamHitStreaks[team.id] = nil
        nextWordMultiplier[team.id] = nil
        turnPointMultiplier[team.id] = nil
        pendingTurnTimePenalty[team.id] = nil
        shieldCharges[team.id] = nil
        rewindBonusTeams.remove(team.id)
        comboBonusCounters.removeValue(forKey: team.id)
        pausePenaltyTargets.remove(team.id)
        pendingSwapWordTeams.remove(team.id)
        cancelSwapWordTask(for: team.id)
        pendingTimeBombTargets.remove(team.id)
        cancelTimeBomb(for: team.id)
        suddenRushExpiry.removeValue(forKey: team.id)
        pendingInvisibleWordTargets.remove(team.id)
        invisibleWordActiveTeams.remove(team.id)
        removeInvisibleWord(for: team.id)
        slotSpinCredits.removeValue(forKey: team.id)
        pendingSlotSpinCredits.removeValue(forKey: team.id)
        if slotRewardActiveTeamId == team.id {
            slotRewardActiveTeamId = nil
            slotLastResult = nil
        }
        timerValueBursts.removeAll { $0.teamId == team.id }
        activeStealBadges.remove(team.id)
        visualEffects[team.id] = nil
        skipButtonFreezeUntil[team.id] = nil
        pendingVisualEffects[team.id] = nil
        forcedSkipTeams.remove(team.id)
        slowMotionFlashUntil[team.id] = nil
        assistListeners.removeValue(forKey: team.id)
        assistListeners = assistListeners.reduce(into: [:]) { result, entry in
            let filtered = entry.value.filter { $0 != team.id }
            if !filtered.isEmpty {
                result[entry.key] = filtered
            }
        }
        if activeForcedSkipTeamId == team.id {
            activeForcedSkipTeamId = nil
        }
        clearEnglishWordEffect(for: team.id)
    }
    
    // MARK: - Category Management
    func toggleCategory(_ category: TimesUpCategory) {
            if let index = gameState.settings.selectedCategories.firstIndex(where: { $0.id == category.id }) {
                gameState.settings.selectedCategories.remove(at: index)
            } else {
                gameState.settings.selectedCategories.append(category)
            }
        }
    
    // MARK: - Game Control
    var canStartGame: Bool {
        return gameState.settings.isValid
    }
    
    func startGame() {
        guard canStartGame else { return }
        
        // Alle Begriffe aus gewählten Kategorien sammeln
        var allAvailableTerms = gameState.settings.selectedCategories.flatMap { $0.terms }
        allAvailableTerms.shuffle()
        
        // Nur die gewünschte Anzahl von Wörtern auswählen
        let desiredCount = gameState.settings.wordCount
        gameState.allTerms = Array(allAvailableTerms.prefix(desiredCount))
        
        // Begriffe mischen (immer für ersten Start)
        gameState.allTerms.shuffle()
        
        // Spielzustand zurücksetzen
        gameState.currentRound = .round1
        gameState.currentTeamIndex = 0
        gameState.currentTermIndex = 0
        gameState.phase = .setup
        gameState.turnTimeRemaining = gameState.settings.turnTimeLimit
        penaltyCardCounter = 0
        scoreRevealSnapshots = [:]
        
        // Reset Tracking-Sets
        gameState.seenTermsInCurrentTurn.removeAll()
        gameState.seenTermsInCurrentRound.removeAll()
        
        // Team-Punkte zurücksetzen (für den gewählten Modus)
        for i in gameState.settings.teams.indices {
            gameState.settings.teams[i].resetScores()
        }
        gameState.resetTeamTurnCounters()
        gameState.teamHitStreaks = Dictionary(uniqueKeysWithValues: gameState.settings.teams.map { ($0.id, 0) })
        perksTriggeredThisTurn = 0
        lastPerkTypeThisTurn = nil
        awardedPerks.removeAll()
        pendingTurnTimePenalty.removeAll()
        nextWordMultiplier = Dictionary(uniqueKeysWithValues: gameState.settings.teams.map { ($0.id, 1) })
        turnPointMultiplier = Dictionary(uniqueKeysWithValues: gameState.settings.teams.map { ($0.id, 1) })
        shieldCharges.removeAll()
        activeStealBadges.removeAll()
        rewindBonusTeams.removeAll()
        comboBonusCounters.removeAll()
        assistListeners.removeAll()
        pausePenaltyTargets.removeAll()
        pendingSwapWordTeams.removeAll()
        swapWordTasks.values.forEach { $0.cancel() }
        swapWordTasks.removeAll()
        pendingTimeBombTargets.removeAll()
        activeTimeBombTimers.values.forEach { $0.invalidate() }
        activeTimeBombTimers.removeAll()
        suddenRushExpiry.removeAll()
        pendingInvisibleWordTargets.removeAll()
        invisibleWordActiveTeams.removeAll()
        invisibleWordHiddenTeams.removeAll()
        invisibleWordHideTasks.values.forEach { $0.cancel() }
        invisibleWordHideTasks.removeAll()
        timerValueBursts.removeAll()
        slotSpinCredits.removeAll()
        pendingSlotSpinCredits.removeAll()
        slotRewardActiveTeamId = nil
        slotLastResult = nil
        timerFreezeTeamId = nil
        timerFreezeRemaining = 0
        visualEffects.removeAll()
        englishWordEffects.removeAll()
        englishWordExpiryTasks.values.forEach { $0.cancel() }
        englishWordExpiryTasks.removeAll()
        skipButtonFreezeUntil.removeAll()
        pendingVisualEffects.removeAll()
        forcedSkipTeams.removeAll()
        slowMotionFlashUntil.removeAll()
        activeForcedSkipTeamId = nil
        
        // Stelle sicher, dass alle Begriffe für den gewählten Modus korrekt initialisiert sind
        for i in gameState.allTerms.indices {
            gameState.allTerms[i].reset()  // Setzt alle Runden auf false zurück
        }
    }
    
    func startRound() {
        startTurn() // Erster Zug der Runde
    }
    
    func correctGuess() {
        guard gameState.phase == .playing else { return }
        let currentTeamId = gameState.currentTeam?.id
        
        if let teamId = currentTeamId, pausePenaltyTargets.remove(teamId) != nil {
            gameState.turnTimeRemaining = max(0, gameState.turnTimeRemaining - 2)
            triggerTimerBurst(for: teamId, text: "-2s", isNegative: true)
        }
        
        // Score
        addPointsToCurrentTeam(basePoints: 1, reason: String(localized: "✅ Richtig"))
        
        if let teamId = currentTeamId, rewindBonusTeams.contains(teamId) {
            gameState.turnTimeRemaining += 2
            triggerTimerBurst(for: teamId, text: "+2s", isNegative: false)
        }
        
        if let teamId = currentTeamId {
            incrementComboCounter(for: teamId)
            cancelTimeBomb(for: teamId)
            incrementHitStreak(for: teamId)
        }
        
        // Mark seen and completed
        gameState.markCurrentTermAsSeen()
        gameState.markCurrentTermCompleted()
        lastAction = .correct
        lastSkippedIndex = nil
        if gameState.hasTeamSeenAllAvailableTermsForTurn {
            turnTimer.invalidate()
            handleTurnTimeEnd()
        } else {
            gameState.nextTerm(avoiding: nil)
            refreshTermVisualEffectsForCurrentTeam()
        }
        handlePerkProgressAfterCorrect()
    }
    
    func skipTerm() {
        guard gameState.phase == .playing, gameState.currentRound.canSkip else { return }
        let skippingTeamId = gameState.currentTeam?.id
        handleMissedTerm(reason: .skip)
        rewardAssistPointsIfNeeded(forSkippedTeam: skippingTeamId)
        resolveForcedSkipIfNeeded()
    }
    
    func wrongGuess() {
        guard gameState.phase == .playing,
              gameState.currentRound.canSkip,
              gameState.settings.difficulty == .hard else { return }
        handleMissedTerm(reason: .wrongGuess)
    }
    
    private func handleMissedTerm(reason: MissReason) {
        guard gameState.currentTerm != nil else {
            return
        }
        let visibleIndex = gameState.resolvedCurrentTermIndex()
        gameState.markCurrentTermAsSeen()
        
        applySkipPenaltyIfNeeded()
        if reason == .wrongGuess {
            addPenaltyCardForCurrentTeam()
        }
        if gameState.hasTeamSeenAllAvailableTermsForTurn {
            turnTimer.invalidate()
            handleTurnTimeEnd()
            return
        }
        
        lastAction = reason == .skip ? .skip : .wrongGuess
        lastSkippedIndex = visibleIndex
        gameState.nextTerm(avoiding: lastSkippedIndex)
        refreshTermVisualEffectsForCurrentTeam()
        
        if gameState.currentTerm == nil {
            turnTimer.invalidate()
            handleTurnTimeEnd()
        }
        resetStreakForCurrentTeam()
    }
    
    private func rewardAssistPointsIfNeeded(forSkippedTeam teamId: UUID?) {
        guard let teamId = teamId,
              let listeners = assistListeners[teamId],
              !listeners.isEmpty else { return }
        let roundReason = String(localized: "🤝 Assist Bonus")
        listeners.forEach { recipientId in
            addFlatPoints(1, to: recipientId, reason: roundReason)
            if let teamName = gameState.settings.teams.first(where: { $0.id == recipientId })?.name {
                let msg = String(localized: "\(teamName): Assist +1")
                showPerkToast(.init(icon: "hand.wave", message: msg))
            }
            triggerTimerBurst(for: recipientId, text: "+1", isNegative: false)
            triggerScoreBurst(for: recipientId, text: "+1Pkt", isNegative: false)
        }
        triggerTimerBurst(for: teamId, text: "-1", isNegative: true)
        triggerScoreBurst(for: teamId, text: "-1Pkt", isNegative: true)
    }
    
    private func applySkipPenaltyIfNeeded() {
        guard gameState.currentTeamIndex < gameState.settings.teams.count else { return }
        let round = gameState.currentRound.rawValue
        let teamId = gameState.settings.teams[gameState.currentTeamIndex].id
        if consumeShieldIfAvailable(for: teamId) {
            return
        }
        switch gameState.settings.difficulty {
        case .easy:
            break // keine Strafe
        case .medium:
            gameState.settings.teams[gameState.currentTeamIndex].applyPenalty(1, for: round, revealAtEnd: true)
            logPendingPenalties()
        case .hard:
            gameState.settings.teams[gameState.currentTeamIndex].applyPenalty(1, for: round)
            logCurrentScores()
        }
    }

    private func revealDeferredPenaltiesIfNeeded() {
        guard gameState.settings.difficulty == .medium else {
            scoreRevealSnapshots = [:]
            return
        }
        var snapshot: [UUID: ScoreRevealSnapshot] = [:]
        let gameMode = gameState.settings.gameMode
        for i in gameState.settings.teams.indices {
            var team = gameState.settings.teams[i]
            let preScore = team.score
            let penalty = team.pendingPenaltyTotal(for: gameMode)
            team.revealPendingPenalties(for: gameMode)
            let finalScore = team.score
            gameState.settings.teams[i] = team
            snapshot[team.id] = ScoreRevealSnapshot(preScore: preScore, penalty: penalty, finalScore: finalScore)
        }
        scoreRevealSnapshots = snapshot
        logCurrentScores()
    }
    
    private func addPenaltyCardForCurrentTeam() {
        guard gameState.currentTeamIndex < gameState.settings.teams.count else { return }
        let team = gameState.settings.teams[gameState.currentTeamIndex]
        var penaltyTerm = generatePenaltyTerm(for: team)
        penaltyTerm.assignedTeamId = team.id
        let currentTurnCount = gameState.teamTurnCounters[team.id] ?? 0
        penaltyTerm.availableFromTeamTurn = currentTurnCount + 1
        gameState.allTerms.append(penaltyTerm)
    }
    
    private func generatePenaltyTerm(for team: Team) -> Term {
        let pool = gameState.settings.selectedCategories.flatMap { $0.terms }
        let existingTexts = Set(gameState.allTerms.map { $0.text.lowercased() })
        let unused = pool.filter { !existingTexts.contains($0.text.lowercased()) }
        
        if var candidate = (unused.randomElement() ?? pool.randomElement()) {
            candidate.id = UUID()
            candidate.reset()
            return candidate
        }
        
        return makeFallbackPenaltyTerm(for: team)
    }
    
    private func makeFallbackPenaltyTerm(for team: Team) -> Term {
        penaltyCardCounter += 1
        let text = String(localized: "Strafkarte \(penaltyCardCounter) - \(team.name)")
        return Term(text: text)
    }

    private func logScoreChange(for teamIndex: Int, round: Int, delta: Int, reason: String) {
        guard teamIndex < gameState.settings.teams.count,
              round >= 0,
              round < gameState.settings.teams[teamIndex].roundScores.count else { return }
    }
    
    private func addPointsToCurrentTeam(basePoints: Int, reason: String) {
        guard gameState.currentTeamIndex < gameState.settings.teams.count else { return }
        let teamId = gameState.settings.teams[gameState.currentTeamIndex].id
        var total = basePoints
        var usedNextWordBonus = false
        var usedTurnBonus = false
        if let nextMulti = nextWordMultiplier[teamId], nextMulti > 1 {
            total *= nextMulti
            usedNextWordBonus = true
            nextWordMultiplier[teamId] = 1
        }
        if let turnMulti = turnPointMultiplier[teamId], turnMulti > 1 {
            total *= turnMulti
            usedTurnBonus = true
        }
        gameState.settings.teams[gameState.currentTeamIndex].addScore(total, for: gameState.currentRound.rawValue)
        if (usedNextWordBonus || usedTurnBonus), total > basePoints {
            triggerTimerBurst(for: teamId, text: "+\(total)", isNegative: false)
            triggerScoreBurst(for: teamId, text: "+\(total)Pkt", isNegative: false)
        }
    }
    
    private func addFlatPoints(_ points: Int, to teamId: UUID, reason: String) {
        guard let index = gameState.settings.teams.firstIndex(where: { $0.id == teamId }) else { return }
        let round = gameState.currentRound.rawValue
        gameState.settings.teams[index].addScore(points, for: round)
    }
    
    private func incrementComboCounter(for teamId: UUID) {
        guard comboBonusCounters[teamId] != nil else { return }
        comboBonusCounters[teamId, default: 0] += 1
        if comboBonusCounters[teamId, default: 0] >= 3 {
            comboBonusCounters[teamId] = 0
            addFlatPoints(3, to: teamId, reason: String(localized: "🔥 Combo Bonus"))
            if let teamName = gameState.settings.teams.first(where: { $0.id == teamId })?.name {
                let msg = String(localized: "\(teamName): Combo +3")
                showPerkToast(.init(icon: "flame", message: msg))
            }
            triggerTimerBurst(for: teamId, text: "+3", isNegative: false)
        }
    }
    
    private func resetComboCounter(for teamId: UUID) {
        guard comboBonusCounters[teamId] != nil else { return }
        comboBonusCounters[teamId] = 0
    }
    
    private func activateTimeBombIfNeeded() {
        guard let teamId = gameState.currentTeam?.id else { return }
        guard pendingTimeBombTargets.remove(teamId) != nil else { return }
        startTimeBomb(for: teamId)
    }
    
    private func startTimeBomb(for teamId: UUID) {
        cancelTimeBomb(for: teamId)
        let timer = RepeatingMainTimer()
        timer.start(interval: 3.0) { [weak self] in
            guard let self else { return }
            self.applyTimeBombTick(for: teamId)
        }
        activeTimeBombTimers[teamId] = timer
    }
    
    private func applyTimeBombTick(for teamId: UUID) {
        guard gameState.phase == .playing,
              let currentTeamId = gameState.currentTeam?.id,
              currentTeamId == teamId else {
            cancelTimeBomb(for: teamId)
            return
        }
        guard gameState.turnTimeRemaining > 0 else {
            cancelTimeBomb(for: teamId)
            return
        }
        gameState.turnTimeRemaining = max(0, gameState.turnTimeRemaining - 1)
        triggerTimerBurst(for: teamId, text: "-1s", isNegative: true)
    }
    
    private func cancelTimeBomb(for teamId: UUID) {
        activeTimeBombTimers[teamId]?.invalidate()
        activeTimeBombTimers.removeValue(forKey: teamId)
    }

    private func applySuddenRush(to teamId: UUID) {
        suddenRushExpiry[teamId] = Date().addingTimeInterval(10)
        notifyUIChange()
    }
    
    private func timerDecrementForCurrentTeam() -> Double {
        guard let teamId = gameState.currentTeam?.id else { return 1 }
        return isSuddenRushActive(for: teamId) ? 2 : 1
    }
    
    private func isSuddenRushActive(for teamId: UUID?) -> Bool {
        guard let teamId = teamId,
              let expiry = suddenRushExpiry[teamId] else { return false }
        if expiry <= Date() {
            suddenRushExpiry.removeValue(forKey: teamId)
            notifyUIChange()
            return false
        }
        return true
    }
    
    private func cleanupExpiredRushIfNeeded() {
        guard let teamId = gameState.currentTeam?.id,
              let expiry = suddenRushExpiry[teamId],
              expiry <= Date() else { return }
        suddenRushExpiry.removeValue(forKey: teamId)
        notifyUIChange()
    }
    
    private func activateSwapWordIfNeeded() {
        guard let teamId = gameState.currentTeam?.id else { return }
        guard pendingSwapWordTeams.remove(teamId) != nil else { return }
        startSwapWordCountdown(for: teamId)
    }
    
    private func startSwapWordCountdown(for teamId: UUID) {
        cancelSwapWordTask(for: teamId)
        let workItem = DispatchWorkItem { [weak self] in
            self?.performSwapWordForActiveTeam()
        }
        swapWordTasks[teamId] = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: workItem)
    }
    
    private func cancelSwapWordTask(for teamId: UUID) {
        swapWordTasks[teamId]?.cancel()
        swapWordTasks.removeValue(forKey: teamId)
    }
    
    private func performSwapWordForActiveTeam() {
        guard gameState.phase == .playing,
              let teamId = gameState.currentTeam?.id else { return }
        swapWordTasks.removeValue(forKey: teamId)
        let previousIndex = gameState.currentTermIndex
        gameState.nextTerm(avoiding: previousIndex)
        refreshTermVisualEffectsForCurrentTeam()
        showPerkToast(.init(icon: "arrow.2.circlepath", message: "Wort gewechselt!"))
    }

    private func activatePendingInvisibleWordIfNeeded() {
        guard let teamId = gameState.currentTeam?.id else { return }
        if pendingInvisibleWordTargets.remove(teamId) != nil {
            invisibleWordActiveTeams.insert(teamId)
            scheduleInvisibleWord(for: teamId)
        }
    }
    
    private func refreshTermVisualEffectsForCurrentTeam() {
        guard let teamId = gameState.currentTeam?.id else { return }
        if invisibleWordActiveTeams.contains(teamId) {
            invisibleWordHiddenTeams.remove(teamId)
            scheduleInvisibleWord(for: teamId)
            notifyUIChange()
        }
    }

    private func activateEnglishWordEffect(for teamId: UUID) {
        guard let termText = gameState.currentTerm?.text else { return }
        let normalized = termText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return }

        if let english = gameState.currentTerm?.englishTranslation,
           !english.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            startEnglishWordEffect(for: teamId, translation: english)
            return
        }

        englishWordEffects[teamId] = EnglishWordEffectState(translation: nil, expiresAt: nil, pendingTerm: normalized)
        notifyUIChange()

        Task {
            let translated = await wordTranslationManager.translateToEnglish(normalized)
            await MainActor.run {
                guard let current = self.englishWordEffects[teamId],
                      current.pendingTerm == normalized else { return }
                self.startEnglishWordEffect(for: teamId, translation: translated)
            }
        }
    }

    private func startEnglishWordEffect(for teamId: UUID, translation: String) {
        guard var state = englishWordEffects[teamId] else { return }
        let expiry = Date().addingTimeInterval(7)
        state.translation = translation
        state.expiresAt = expiry
        englishWordEffects[teamId] = state
        scheduleEnglishWordEffectExpiry(for: teamId, expiry: expiry)
        notifyUIChange()
    }

    private func scheduleEnglishWordEffectExpiry(for teamId: UUID, expiry: Date) {
        englishWordExpiryTasks[teamId]?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            if let current = self.englishWordEffects[teamId],
               let expiry = current.expiresAt,
               expiry <= Date() {
                self.englishWordEffects.removeValue(forKey: teamId)
                self.notifyUIChange()
            }
            self.englishWordExpiryTasks.removeValue(forKey: teamId)
        }
        englishWordExpiryTasks[teamId] = workItem
        let delay = max(0, expiry.timeIntervalSinceNow)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
    }

    private func clearEnglishWordEffect(for teamId: UUID) {
        englishWordEffects.removeValue(forKey: teamId)
        englishWordExpiryTasks[teamId]?.cancel()
        englishWordExpiryTasks.removeValue(forKey: teamId)
    }

    private func activateInvisibleWord(for teamId: UUID) {
        if gameState.currentTeam?.id == teamId {
            invisibleWordActiveTeams.insert(teamId)
            pendingInvisibleWordTargets.remove(teamId)
            scheduleInvisibleWord(for: teamId)
        } else {
            pendingInvisibleWordTargets.insert(teamId)
        }
    }
    
    private func scheduleInvisibleWord(for teamId: UUID) {
        invisibleWordHideTasks[teamId]?.cancel()
        invisibleWordHiddenTeams.remove(teamId)
        let task = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            self.invisibleWordHiddenTeams.insert(teamId)
            self.notifyUIChange()
        }
        invisibleWordHideTasks[teamId] = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: task)
    }
    
    private func removeInvisibleWord(for teamId: UUID) {
        invisibleWordHideTasks[teamId]?.cancel()
        invisibleWordHideTasks.removeValue(forKey: teamId)
        invisibleWordActiveTeams.remove(teamId)
        let removed = invisibleWordHiddenTeams.remove(teamId) != nil
        pendingInvisibleWordTargets.remove(teamId)
        if removed {
            notifyUIChange()
        }
    }
    
    
    private func logPendingPenalties() {
        guard gameState.settings.difficulty == .medium else { return }
    }
    
    private func logCurrentScores() {
    }
    
    private func consumeShieldIfAvailable(for teamId: UUID) -> Bool {
        guard let charges = shieldCharges[teamId], charges > 0 else { return false }
        shieldCharges[teamId] = charges - 1
        return true
    }
    
    private func logRoundSummary(context: String) {
    }
    
    private func showPerkToast(_ toast: PerkToast) {
        perkToast = toast
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            guard let self = self else { return }
            if self.perkToast?.id == toast.id {
                self.perkToast = nil
            }
        }
    }
    
    func displayTextForCurrentTeam(term: Term?) -> String {
        guard let term = term else { return "" }
        if let teamId = gameState.currentTeam?.id {
            if invisibleWordHiddenTeams.contains(teamId) {
                return ""
            }
            if let effect = englishWordEffects[teamId],
               let expiry = effect.expiresAt,
               expiry > Date(),
               let translation = effect.translation,
               !translation.isEmpty {
                return translation
            }
        }
        return transform(text: term.text, for: gameState.currentTeam?.id)
    }
    
    func shouldFlickerForCurrentTeam() -> Bool { false }
    func shouldDarkenScreenForCurrentTeam() -> Bool { false }
    
    func isSkipButtonFrozenForCurrentTeam() -> Bool {
        guard let teamId = gameState.currentTeam?.id else { return false }
        if isForcedSkipActiveForCurrentTeam() {
            return false
        }
        return isSkipButtonFrozen(for: teamId)
    }
    
    func slowMotionHintForCurrentTeam() -> String? {
        guard let teamId = gameState.currentTeam?.id else { return nil }
        if hasActiveSlowMotion(for: teamId) {
            return "Slow Motion aktiv"
        }
        if pendingTurnTimePenalty[teamId] != nil {
            return "Slow Motion vorbereitet"
        }
        return nil
    }
    
    func currentHitStreakCount() -> Int {
        guard let teamId = gameState.currentTeam?.id else { return 0 }
        return gameState.teamHitStreaks[teamId] ?? 0
    }
    
    func activeBadgesForCurrentTeam() -> [PerkBadge] {
        guard let teamId = gameState.currentTeam?.id else { return [] }
        var badges: [PerkBadge] = []
        if nextWordMultiplier[teamId, default: 1] > 1 {
            badges.append(.nextWordDouble)
        }
        if turnPointMultiplier[teamId, default: 1] > 1 {
            badges.append(.doublePoints)
        }
        if shieldCharges[teamId, default: 0] > 0 {
            badges.append(.shield)
        }
        if isTimerFrozen(for: teamId) {
            badges.append(.freeze)
        }
        if slowMotionHintForCurrentTeam() != nil {
            badges.append(.slowMotion)
        }
        if activeStealBadges.contains(teamId) {
            badges.append(.stealPoints)
        }
        return badges
    }
    
    func perkNoticesForCurrentTeam() -> [PerkNotice] {
        guard let teamId = gameState.currentTeam?.id else { return [] }
        var notices: [PerkNotice] = []
        
        // Positive effects (green)
        if nextWordMultiplier[teamId, default: 1] > 1 {
            notices.append(PerkNotice(icon: "🔁", text: localized("Nächstes Wort x2"), isNegative: false))
        }
        if turnPointMultiplier[teamId, default: 1] > 1 {
            notices.append(PerkNotice(icon: "✨", text: localized("Doppelte Punkte aktiv"), isNegative: false))
        }
        if rewindBonusTeams.contains(teamId) {
            notices.append(PerkNotice(icon: "⏪", text: localized("+2s pro Treffer"), isNegative: false))
        }
        if let freezeRemaining = freezeTimeRemainingSeconds(for: teamId) {
            let msg = localized("Zeit eingefroren (%llds)", Int64(freezeRemaining))
            notices.append(PerkNotice(icon: "❄️", text: msg, isNegative: false))
        }
        if shieldCharges[teamId, default: 0] > 0 {
            notices.append(PerkNotice(icon: "🛡", text: localized("Schutzschild bereit"), isNegative: false))
        }
        if comboBonusCounters[teamId] != nil {
            notices.append(PerkNotice(icon: "🔥", text: localized("Combo Bonus aktiv"), isNegative: false))
        }
        if let attackers = assistListeners[teamId], !attackers.isEmpty {
            let attackerNames = attackers.compactMap { attackerId in
                gameState.settings.teams.first(where: { $0.id == attackerId })?.name
            }
            let label: String
            if attackerNames.isEmpty {
                label = localized("Assist gegen euch aktiv")
            } else if attackerNames.count == 1 {
                label = localized("Assist von %@", attackerNames[0])
            } else {
                label = localized("Assist von %@", attackerNames.joined(separator: ", "))
            }
            notices.append(PerkNotice(icon: "🤝", text: label, isNegative: true))
        }
        
        // Negative effects (red)
        if isSuddenRushActive(for: teamId) {
            notices.append(PerkNotice(icon: "⚡️", text: localized("Timer doppelt so schnell"), isNegative: true))
        }
        if hasActiveSlowMotion(for: teamId) {
            notices.append(PerkNotice(icon: "🐢", text: localized("Slow Motion aktiv (-5s)"), isNegative: true))
        } else if pendingTurnTimePenalty[teamId] != nil {
            notices.append(PerkNotice(icon: "🐢", text: localized("Slow Motion vorbereitet (-5s)"), isNegative: true))
        }
        if pausePenaltyTargets.contains(teamId) {
            notices.append(PerkNotice(icon: "⏱", text: localized("-2s beim nächsten Treffer"), isNegative: true))
        }
        if pendingTimeBombTargets.contains(teamId) || activeTimeBombTimers[teamId] != nil {
            notices.append(PerkNotice(icon: "💣", text: localized("Zeitbombe aktiv (-1s pro 3s)"), isNegative: true))
        }
        if isMirrorActive(for: teamId) {
            notices.append(PerkNotice(icon: "🪞", text: localized("Spiegel-Wort aktiv"), isNegative: true))
        }
        if isGlitchActive(for: teamId) {
            notices.append(PerkNotice(icon: "✨", text: localized("Glitch-Buchstaben"), isNegative: true))
        }
        if pendingInvisibleWordTargets.contains(teamId) || invisibleWordActiveTeams.contains(teamId) {
            notices.append(PerkNotice(icon: "🙈", text: localized("Wort verschwindet gleich"), isNegative: true))
        }
        if pendingSwapWordTeams.contains(teamId) {
            notices.append(PerkNotice(icon: "🔄", text: localized("Wort wird getauscht"), isNegative: true))
        }
        if isSkipButtonFrozen(for: teamId) {
            if let remaining = skipFreezeRemainingSeconds(for: teamId) {
                let msg = localized("Skip gesperrt (%llds)", Int64(remaining))
                notices.append(PerkNotice(icon: "🔒", text: msg, isNegative: true))
            } else {
                notices.append(PerkNotice(icon: "🔒", text: localized("Skip gesperrt"), isNegative: true))
            }
        }
        if forcedSkipTeams.contains(teamId) || activeForcedSkipTeamId == teamId {
            notices.append(PerkNotice(icon: "⛔️", text: localized("Zwangs-Skip aktiv"), isNegative: true))
        }
        
        return notices
    }

    func attackNoticesForCurrentTeam() -> [PerkAttackNotice] {
        guard let teamId = gameState.currentTeam?.id else { return [] }
        return attackNotices[teamId] ?? []
    }

    private func registerAttackNotice(for attackerId: UUID, targetName: String, icon: String, label: String, duration: TimeInterval = 6) {
        let notice = PerkAttackNotice(icon: icon, label: label, targetName: targetName)
        var entries = attackNotices[attackerId] ?? []
        entries.append(notice)
        attackNotices[attackerId] = entries
        notifyUIChange()

        let workItem = DispatchWorkItem { [weak self] in
            self?.removeAttackNotice(notice.id, for: attackerId)
        }

        var expiryEntries = attackNoticeExpiryTasks[attackerId] ?? [:]
        expiryEntries[notice.id] = workItem
        attackNoticeExpiryTasks[attackerId] = expiryEntries
        DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: workItem)
    }

    private func removeAttackNotice(_ noticeId: UUID, for teamId: UUID) {
        guard var entries = attackNotices[teamId] else { return }
        entries.removeAll { $0.id == noticeId }
        if entries.isEmpty {
            attackNotices.removeValue(forKey: teamId)
        } else {
            attackNotices[teamId] = entries
        }
        attackNoticeExpiryTasks[teamId]?[noticeId]?.cancel()
        attackNoticeExpiryTasks[teamId]?[noticeId] = nil
        if attackNoticeExpiryTasks[teamId]?.isEmpty ?? false {
            attackNoticeExpiryTasks.removeValue(forKey: teamId)
        }
        notifyUIChange()
    }
    
    func slotRewardTeam() -> Team? {
        guard let id = slotRewardActiveTeamId else { return nil }
        return gameState.settings.teams.first { $0.id == id }
    }
    
    func slotRewardCredits() -> Int {
        guard let id = slotRewardActiveTeamId else { return 0 }
        return slotSpinCredits[id, default: 0]
    }
    
    func slotRewardLastResultText() -> String? {
        slotLastResult?.text
    }
    
    @discardableResult
    func spinSlotReward() -> SlotSpinResult? {
        guard let teamId = slotRewardActiveTeamId,
              slotSpinCredits[teamId, default: 0] > 0 else { return nil }
        let didWin = Bool.random()
        let delta = didWin ? 10 : -15
        addFlatPoints(delta, to: teamId, reason: String(localized: "🎰 Slot Maschine"))
        triggerScoreBurst(for: teamId,
                          text: delta >= 0 ? "+10Pkt" : "-15Pkt",
                          isNegative: delta < 0)
        let message = delta >= 0 ? String(localized: "+10 Punkte!") : String(localized: "-15 Punkte...")
        showPerkToast(.init(icon: didWin ? "gift.fill" : "hand.thumbsdown.fill", message: message))
        slotSpinCredits[teamId, default: 0] -= 1
        let result = SlotSpinResult(text: message, isWin: didWin)
        slotLastResult = result
        if slotSpinCredits[teamId, default: 0] <= 0 {
            slotSpinCredits.removeValue(forKey: teamId)
        }
        return result
    }
    
    func skipSlotReward() {
        guard let teamId = slotRewardActiveTeamId else { return }
        slotSpinCredits.removeValue(forKey: teamId)
        slotRewardActiveTeamId = nil
        slotLastResult = nil
        proceedAfterSlotIfNeeded()
    }
    
    func finishSlotReward() {
        slotRewardActiveTeamId = nil
        slotLastResult = nil
        proceedAfterSlotIfNeeded()
    }

    private func proceedAfterSlotIfNeeded() {
        guard slotRewardActiveTeamId == nil else { return }
        if gameState.allTermsCompletedForCurrentRound {
            gameState.phase = .roundEnd
        } else {
            gameState.phase = .setup
        }
    }
    
    func triggerTimerBurst(for teamId: UUID, text: String, isNegative: Bool) {
        let burst = TimerValueBurst(teamId: teamId, text: text, isNegative: isNegative)
        timerValueBursts.append(burst)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
            self?.timerValueBursts.removeAll { $0.id == burst.id }
        }
    }
    
    func triggerScoreBurst(for teamId: UUID, text: String, isNegative: Bool) {
        let burst = ScoreBurst(teamId: teamId, text: text, isNegative: isNegative)
        scoreBursts.append(burst)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) { [weak self] in
            self?.scoreBursts.removeAll { $0.id == burst.id }
        }
    }
    
    func isTimerFrozenForCurrentTeam() -> Bool {
        return isTimerFrozen(for: gameState.currentTeam?.id)
    }
    
    func isForcedSkipActiveForCurrentTeam() -> Bool {
        guard let teamId = gameState.currentTeam?.id else { return false }
        return activeForcedSkipTeamId == teamId
    }
    
    private func applyPendingTimePenaltyIfNeeded() {
        guard let team = gameState.currentTeam else { return }
        guard let penalty = pendingTurnTimePenalty.removeValue(forKey: team.id), penalty > 0 else { return }
        let oldTime = gameState.turnTimeRemaining
        gameState.turnTimeRemaining = max(1, gameState.turnTimeRemaining - penalty)
        slowMotionFlashUntil[team.id] = Date().addingTimeInterval(3)
        triggerTimerBurst(for: team.id, text: "-\(Int(min(penalty, oldTime)))s", isNegative: true)
    }
    
    private func normalizeTimerFreezeForCurrentTeam() {
        guard let freezeTeam = timerFreezeTeamId,
              let current = gameState.currentTeam?.id,
              freezeTeam != current else { return }
        timerFreezeTeamId = nil
        timerFreezeRemaining = 0
    }
    
    private func clearTurnScopedPerks(for teamId: UUID) {
        nextWordMultiplier[teamId] = 1
        turnPointMultiplier[teamId] = 1
        activeStealBadges.remove(teamId)
        rewindBonusTeams.remove(teamId)
        comboBonusCounters.removeValue(forKey: teamId)
        assistListeners[teamId] = nil
        cancelSwapWordTask(for: teamId)
        cancelTimeBomb(for: teamId)
        suddenRushExpiry.removeValue(forKey: teamId)
        pendingInvisibleWordTargets.remove(teamId)
        removeInvisibleWord(for: teamId)
        timerValueBursts.removeAll { $0.teamId == teamId }
    }
    
    private func isTimerFrozen(for teamId: UUID?) -> Bool {
        guard let teamId = teamId,
              let freezeTeam = timerFreezeTeamId,
              freezeTeam == teamId else { return false }
        return timerFreezeRemaining > 0
    }

    private func freezeTimeRemainingSeconds(for teamId: UUID) -> Int? {
        guard let freezeTeam = timerFreezeTeamId,
              freezeTeam == teamId,
              timerFreezeRemaining > 0 else { return nil }
        return Int(ceil(timerFreezeRemaining))
    }
    
    private func activateVisualEffect(_ kind: VisualEffectKind, for teamId: UUID, duration: TimeInterval) {
        var state = visualEffects[teamId] ?? VisualEffectState()
        let expiry = Date().addingTimeInterval(duration)
        switch kind {
        case .mirror:
            state.mirrorUntil = expiry
        case .glitch:
            state.glitchUntil = expiry
        }
        visualEffects[teamId] = state
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            self?.clearVisualEffect(kind: kind, teamId: teamId, expectedExpiry: expiry)
        }
    }
    
    private func clearVisualEffect(kind: VisualEffectKind, teamId: UUID, expectedExpiry: Date) {
        guard var state = visualEffects[teamId] else { return }
        let now = Date()
        switch kind {
        case .mirror:
            if state.mirrorUntil == expectedExpiry || state.mirrorUntil ?? .distantPast <= now {
                state.mirrorUntil = nil
            }
        case .glitch:
            if state.glitchUntil == expectedExpiry || state.glitchUntil ?? .distantPast <= now {
                state.glitchUntil = nil
            }
        }
        if state.mirrorUntil == nil && state.glitchUntil == nil {
            visualEffects.removeValue(forKey: teamId)
        } else {
            visualEffects[teamId] = state
        }
    }
    
    private func freezeSkipButton(for teamId: UUID, duration: TimeInterval) {
        let expiry = Date().addingTimeInterval(duration)
        skipButtonFreezeUntil[teamId] = expiry
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            guard let self = self else { return }
            if self.skipButtonFreezeUntil[teamId] == expiry {
                self.skipButtonFreezeUntil[teamId] = nil
            }
        }
    }
    
    private func isSkipButtonFrozen(for teamId: UUID) -> Bool {
        guard let expiry = skipButtonFreezeUntil[teamId] else { return false }
        if expiry <= Date() {
            skipButtonFreezeUntil[teamId] = nil
            return false
        }
        return true
    }

    private func skipFreezeRemainingSeconds(for teamId: UUID) -> Int? {
        guard let expiry = skipButtonFreezeUntil[teamId] else { return nil }
        let remaining = expiry.timeIntervalSinceNow
        if remaining <= 0 {
            skipButtonFreezeUntil[teamId] = nil
            return nil
        }
        return Int(ceil(remaining))
    }
    
    private func queueVisualEffect(_ kind: VisualEffectKind, for teamId: UUID, duration: TimeInterval) {
        if gameState.currentTeam?.id == teamId {
            activateVisualEffect(kind, for: teamId, duration: duration)
            return
        }
        var queue = pendingVisualEffects[teamId] ?? []
        queue.append(VisualEffectRequest(kind: kind, duration: duration))
        pendingVisualEffects[teamId] = queue
    }
    
    private func activatePendingVisualEffectsForCurrentTeam() {
        guard let teamId = gameState.currentTeam?.id,
              let queue = pendingVisualEffects[teamId],
              !queue.isEmpty else { return }
        pendingVisualEffects[teamId] = nil
        queue.forEach { request in
            activateVisualEffect(request.kind, for: teamId, duration: request.duration)
        }
    }
    
    private func scheduleForcedSkip(for teamId: UUID) {
        forcedSkipTeams.insert(teamId)
    }
    
    private func activateForcedSkipIfNeeded() {
        guard let teamId = gameState.currentTeam?.id else {
            activeForcedSkipTeamId = nil
            return
        }
        if activeForcedSkipTeamId == teamId { return }
        if forcedSkipTeams.remove(teamId) != nil {
            activeForcedSkipTeamId = teamId
            let name = gameState.currentTeam?.name ?? "Team"
            let msg = String(localized: "\(name): Zwangs-Skip aktiv")
            showPerkToast(.init(icon: "forward.fill", message: msg))
        }
    }
    
    private func resolveForcedSkipIfNeeded() {
        activeForcedSkipTeamId = nil
    }
    
    private func handlePerkProgressAfterCorrect() {
        guard gameState.settings.perksEnabled,
              gameState.settings.hasAnyPerkSelection,
              gameState.currentTeamIndex < gameState.settings.teams.count else { return }
        guard perksTriggeredThisTurn < maxPerksPerTurn else { return }
        
        let team = gameState.settings.teams[gameState.currentTeamIndex]
        let newStreak = gameState.teamHitStreaks[team.id] ?? 0
        let thresholds = gameState.settings.perkPartyMode ? [3, 6, 9] : [5, 8]
        guard thresholds.contains(newStreak) else { return }
        
        guard let perkType = nextPerkTypeToAward(excluding: lastPerkTypeThisTurn) else {
            return
        }
        
        perksTriggeredThisTurn += 1
        let perk = AwardedPerk(teamId: team.id, teamName: team.name, round: gameState.currentRound, type: perkType, streak: newStreak)
        awardedPerks.append(perk)
        applyPerkEffect(perk, teamIndex: gameState.currentTeamIndex)
        lastPerkTypeThisTurn = perkType
    }
    
    private func incrementHitStreak(for teamId: UUID) {
        let newValue = (gameState.teamHitStreaks[teamId] ?? 0) + 1
        gameState.teamHitStreaks[teamId] = newValue
        if newValue % 10 == 0 {
            pendingSlotSpinCredits[teamId, default: 0] += 1
        }
    }
    
    private func resetStreakForCurrentTeam() {
        guard gameState.currentTeamIndex < gameState.settings.teams.count else { return }
        let teamId = gameState.settings.teams[gameState.currentTeamIndex].id
        resetStreak(for: teamId)
    }
    
    private func resetStreak(for teamId: UUID) {
        gameState.teamHitStreaks[teamId] = 0
        resetComboCounter(for: teamId)
    }
    
    private func activateFreezeTime(for teamId: UUID) {
        timerFreezeTeamId = teamId
        timerFreezeRemaining = 5
    }
    
    private func activateSlowMotionOpponent(from teamIndex: Int) {
        guard let opponentIndex = nextTeamIndex(after: teamIndex) else {
            return
        }
        let opponent = gameState.settings.teams[opponentIndex]
        pendingTurnTimePenalty[opponent.id, default: 0] += 5
    }
    
    @discardableResult
    private func applyStealPoints(from teamIndex: Int) -> Team? {
        guard let opponentIndex = nextTeamIndex(after: teamIndex) else {
            return nil
        }
        let round = gameState.currentRound.rawValue
        let stealAmount = 2
        let opponent = gameState.settings.teams[opponentIndex]
        gameState.settings.teams[opponentIndex].applyPenalty(stealAmount, for: round)
        gameState.settings.teams[teamIndex].addScore(stealAmount, for: round)
        
        let msg = String(localized: "Steal! +\(stealAmount) Punkte")
        showPerkToast(.init(icon: "figure.ninja", message: msg))
        
        let winnerId = gameState.settings.teams[teamIndex].id
        let loserId = opponent.id
        triggerTimerBurst(for: winnerId, text: "+\(stealAmount)", isNegative: false)
        triggerTimerBurst(for: loserId, text: "-\(stealAmount)", isNegative: true)
        triggerScoreBurst(for: winnerId, text: "+\(stealAmount)Pkt", isNegative: false)
        triggerScoreBurst(for: loserId, text: "-\(stealAmount)Pkt", isNegative: true)
        return opponent
    }
    
    private func nextTeamIndex(after index: Int) -> Int? {
        guard !gameState.settings.teams.isEmpty else { return nil }
        if gameState.settings.teams.count == 1 { return nil }
        return (index + 1) % gameState.settings.teams.count
    }
    
    private func nextPerkTypeToAward(excluding lastPerk: PerkType?) -> PerkType? {
        if !gameState.settings.customPerks.isEmpty {
            let allowed = filterPerksForCurrentRound(Array(gameState.settings.customPerks), excluding: lastPerk)
            return allowed.randomElement()
        }
        let packs = gameState.settings.selectedStandardPerkPacks
        guard !packs.isEmpty else { return nil }
        let candidates = PerkType.allCases.filter {
            packs.contains($0.pack) && $0.isImplemented
        }
        let allowed = filterPerksForCurrentRound(candidates, excluding: lastPerk)
        return allowed.randomElement()
    }
    
    private func filterPerksForCurrentRound(_ perks: [PerkType], excluding lastPerk: PerkType?) -> [PerkType] {
        return perks.filter { perk in
            if !gameState.currentRound.canSkip && perk == .assistPoints {
                return false
            }
            if let lastPerk, perk == lastPerk {
                return false
            }
            return true
        }
    }
    
    private func applyPerkEffect(_ perk: AwardedPerk, teamIndex: Int) {
        guard gameState.settings.perksEnabled else { return }
        switch perk.type {
        case .freezeTime:
            activateFreezeTime(for: perk.teamId)
            // showPerkToast(.init(icon: "snowflake", message: "\(perk.teamName): Zeit eingefroren!"))
        case .slowMotionOpponent:
            guard let target = nextTeamIndex(after: teamIndex).map({ gameState.settings.teams[$0] }) else {
                return
            }
            activateSlowMotionOpponent(from: teamIndex)
            // showPerkToast(.init(icon: "tortoise.fill", message: "Gegner -5s"))
            registerAttackNotice(for: perk.teamId, targetName: target.name, icon: "🐢", label: localized("-5s Slow Motion"))
        case .rewindHit:
            rewindBonusTeams.insert(perk.teamId)
            // showPerkToast(.init(icon: "backward.fill", message: "\(perk.teamName): +2s je Treffer"))
        case .timeBomb:
            guard let target = nextTeamIndex(after: teamIndex).map({ gameState.settings.teams[$0] }) else {
                return
            }
            pendingTimeBombTargets.insert(target.id)
            if gameState.currentTeam?.id == target.id {
                activateTimeBombIfNeeded()
            }
            // showPerkToast(.init(icon: "timer", message: "\(target.name): Zeitbombe aktiv"))
            registerAttackNotice(for: perk.teamId, targetName: target.name, icon: "💣", label: localized("Zeitbombe"))
        case .suddenRush:
            guard let target = nextTeamIndex(after: teamIndex).map({ gameState.settings.teams[$0] }) else {
                return
            }
            applySuddenRush(to: target.id)
            // showPerkToast(.init(icon: "bolt.fill", message: "\(target.name): Rush!"))
            registerAttackNotice(for: perk.teamId, targetName: target.name, icon: "⚡️", label: localized("Rush"))
        case .nextWordDouble:
            nextWordMultiplier[perk.teamId] = 2
            // showPerkToast(.init(icon: "textformat.abc", message: "Nächstes Wort x2"))
        case .doublePointsThisTurn:
            turnPointMultiplier[perk.teamId] = 2
            // showPerkToast(.init(icon: "rosette", message: "Doppelte Punkte aktiv"))
        case .stealPoints:
            let target = applyStealPoints(from: teamIndex)
            activeStealBadges.insert(perk.teamId)
            if let target {
                registerAttackNotice(for: perk.teamId, targetName: target.name, icon: "💰", label: localized("2 Punkte gestohlen"))
            }
        case .shield:
            shieldCharges[perk.teamId, default: 0] += 1
            // showPerkToast(.init(icon: "shield.fill", message: "Schutzschild geladen"))
        case .comboBonus:
            comboBonusCounters[perk.teamId] = 0
            // showPerkToast(.init(icon: "flame", message: "\(perk.teamName): Combo aktiv"))
        case .assistPoints:
            guard let target = nextTeamIndex(after: teamIndex).map({ gameState.settings.teams[$0] }) else {
                return
            }
            assistListeners[target.id, default: []].append(perk.teamId)
            // showPerkToast(.init(icon: "hand.wave", message: "\(perk.teamName): Assist wartet"))
            registerAttackNotice(for: perk.teamId, targetName: target.name, icon: "🤝", label: localized("Assist aktiv"))
        case .mirroredWord:
            guard let target = nextTeamIndex(after: teamIndex).map({ gameState.settings.teams[$0] }) else {
                return
            }
            queueVisualEffect(.mirror, for: target.id, duration: 5)
            // showPerkToast(.init(icon: "rectangle.on.rectangle", message: "\(target.name): Wort gespiegelt"))
            registerAttackNotice(for: perk.teamId, targetName: target.name, icon: "🪞", label: localized("Spiegelwort"))
        case .forcedSkip:
            guard gameState.currentRound.canSkip else {
                return
            }
            guard let target = nextTeamIndex(after: teamIndex).map({ gameState.settings.teams[$0] }) else {
                return
            }
            scheduleForcedSkip(for: target.id)
            // showPerkToast(.init(icon: "forward.fill", message: "\(target.name) Zwangs-Skip"))
            registerAttackNotice(for: perk.teamId, targetName: target.name, icon: "⛔️", label: localized("Zwangs-Skip"))
        case .freezeSkipButton:
            guard gameState.currentRound.canSkip else {
                return
            }
            guard let target = nextTeamIndex(after: teamIndex).map({ gameState.settings.teams[$0] }) else {
                return
            }
            freezeSkipButton(for: target.id, duration: skipFreezeDuration)
            // showPerkToast(.init(icon: "lock.fill", message: "\(target.name) Skip gesperrt"))
            registerAttackNotice(for: perk.teamId, targetName: target.name, icon: "🔒", label: localized("Skip gesperrt"))
        case .glitchLetters:
            guard let target = nextTeamIndex(after: teamIndex).map({ gameState.settings.teams[$0] }) else {
                return
            }
            queueVisualEffect(.glitch, for: target.id, duration: 5)
            // showPerkToast(.init(icon: "sparkles", message: "\(target.name) Glitch!"))
            registerAttackNotice(for: perk.teamId, targetName: target.name, icon: "✨", label: localized("Glitch-Buchstaben"))
        case .pausePenalty:
            guard let target = nextTeamIndex(after: teamIndex).map({ gameState.settings.teams[$0] }) else {
                return
            }
            pausePenaltyTargets.insert(target.id)
            // showPerkToast(.init(icon: "pause.circle", message: "\(target.name): -2s beim nächsten Treffer"))
            registerAttackNotice(for: perk.teamId, targetName: target.name, icon: "⏱", label: localized("-2s Penalty"))
        case .swapWord:
            guard let target = nextTeamIndex(after: teamIndex).map({ gameState.settings.teams[$0] }) else {
                return
            }
            pendingSwapWordTeams.insert(target.id)
            if gameState.currentTeam?.id == target.id {
                activateSwapWordIfNeeded()
            }
            // showPerkToast(.init(icon: "arrow.2.circlepath", message: "\(target.name): Worttausch"))
            registerAttackNotice(for: perk.teamId, targetName: target.name, icon: "🔄", label: localized("Worttausch"))
        case .invisibleWord:
            guard let target = nextTeamIndex(after: teamIndex).map({ gameState.settings.teams[$0] }) else {
                return
            }
            activateInvisibleWord(for: target.id)
            // showPerkToast(.init(icon: "eye.slash", message: "\(target.name): Wort verschwindet"))
            registerAttackNotice(for: perk.teamId, targetName: target.name, icon: "🙈", label: localized("Wort verschwindet"))
        case .englishWord:
            guard let target = nextTeamIndex(after: teamIndex).map({ gameState.settings.teams[$0] }) else {
                return
            }
            activateEnglishWordEffect(for: target.id)
            // showPerkToast(.init(icon: "globe", message: "\(target.name): Wort auf Englisch"))
            registerAttackNotice(for: perk.teamId, targetName: target.name, icon: "🌍", label: localized("Wort auf Englisch"))
        }
    }
    
    private func checkForNextTermOrRoundEnd() {
        // Prüfe ob alle Begriffe der aktuellen Runde abgearbeitet wurden
        if gameState.allTermsCompletedForCurrentRound {
            turnTimer.invalidate()
            gameState.phase = .roundEnd
        } else {
            // Gehe zum nächsten verfügbaren Begriff
            gameState.nextTerm()
            refreshTermVisualEffectsForCurrentTeam()
        }
    }
    
    private func transform(text: String, for teamId: UUID?) -> String {
        guard let teamId = teamId else { return text }
        var output = text
        if isMirrorActive(for: teamId) {
            output = String(output.reversed())
        }
        if isGlitchActive(for: teamId) {
            output = glitchText(output)
        }
        return output
    }
    
    private func isMirrorActive(for teamId: UUID?) -> Bool {
        guard let teamId = teamId,
              let expiry = visualEffects[teamId]?.mirrorUntil else { return false }
        if expiry <= Date() {
            clearVisualEffect(kind: .mirror, teamId: teamId, expectedExpiry: expiry)
            return false
        }
        return true
    }
    
    private func isGlitchActive(for teamId: UUID?) -> Bool {
        guard let teamId = teamId,
              let expiry = visualEffects[teamId]?.glitchUntil else { return false }
        if expiry <= Date() {
            clearVisualEffect(kind: .glitch, teamId: teamId, expectedExpiry: expiry)
            return false
        }
        return true
    }
    
    
    private func hasActiveSlowMotion(for teamId: UUID) -> Bool {
        guard let expiry = slowMotionFlashUntil[teamId] else { return false }
        if expiry <= Date() {
            slowMotionFlashUntil[teamId] = nil
            return false
        }
        return true
    }
    
    private func glitchText(_ text: String) -> String {
        guard text.count > 2 else { return String(repeating: "_", count: max(1, text.count)) }
        var characters = Array(text)
        for index in characters.indices where index != 0 && index != characters.count - 1 {
            if Bool.random() {
                characters[index] = "_"
            }
        }
        return String(characters)
    }
    
    // Timer-Ende bedeutet jetzt Team-Wechsel oder Rundenende
    private func handleTurnTimeEnd() {
        turnTimer.invalidate()
        gameState.isTimerRunning = false
        let finishingTeamId = gameState.currentTeam?.id
        perksTriggeredThisTurn = 0
        if let finishingTeamId = finishingTeamId {
            let pendingSpins = pendingSlotSpinCredits.removeValue(forKey: finishingTeamId) ?? 0
            if pendingSpins > 0 {
                slotSpinCredits[finishingTeamId] = (slotSpinCredits[finishingTeamId] ?? 0) + pendingSpins
                slotRewardActiveTeamId = finishingTeamId
                slotLastResult = nil
            } else if slotRewardActiveTeamId == finishingTeamId {
                slotRewardActiveTeamId = nil
                slotLastResult = nil
            }
            clearTurnScopedPerks(for: finishingTeamId)
            resetStreak(for: finishingTeamId)
            cancelTimeBomb(for: finishingTeamId)
        }
        activeForcedSkipTeamId = nil
        
        let roundCompleted = gameState.allTermsCompletedForCurrentRound
        if !roundCompleted {
            gameState.nextTeam()
        }
        if slotRewardActiveTeamId != nil {
            gameState.phase = .slotReward
        } else if roundCompleted {
            gameState.phase = .roundEnd
            logRoundSummary(context: String(localized: "Alle Begriffe erledigt"))
        } else {
            gameState.phase = .setup
            logRoundSummary(context: String(localized: "Team-Wechsel"))
        }
    }
    
    func nextTurn() {
        switch gameState.phase {
        case .slotReward:
            finishSlotReward()
            return
        case .roundEnd:
            // Runde ist komplett beendet -> nächste Runde oder Spielende
            let isLastRound: Bool
            switch gameState.settings.gameMode {
            case .classic, .randomOrder:
                isLastRound = (gameState.currentRound == .round3)
            case .withDrawing:
                isLastRound = (gameState.currentRound == .round4)
            }
            
            if isLastRound {
                // Finale Punkteberechnung für den aktuellen Spielmodus
                revealDeferredPenaltiesIfNeeded()
                for i in gameState.settings.teams.indices {
                    gameState.settings.teams[i].updateTotalScore(for: gameState.settings.gameMode)
                }
                gameState.phase = slotRewardActiveTeamId != nil ? .slotReward : .gameEnd
            } else {
                gameState.nextRound()
                if slotRewardActiveTeamId == nil {
                    startTurn()
                }
            }
        
        case .setup:
            // Team startet seinen Zug
            startTurn()
            
        default:
            break
        }
    }
    
    private func startTurn() {
        gameState.phase = .playing
        gameState.startNewTurn() // Reset seen terms und timer
        slotLastResult = nil
        
        lastAction = .none
        lastSkippedIndex = nil
        perksTriggeredThisTurn = 0
        resetStreakForCurrentTeam()
        applyPendingTimePenaltyIfNeeded()
        normalizeTimerFreezeForCurrentTeam()
        activatePendingVisualEffectsForCurrentTeam()
        activateForcedSkipIfNeeded()
        activateSwapWordIfNeeded()
        activateTimeBombIfNeeded()
        activatePendingInvisibleWordIfNeeded()
        
        if gameState.currentTerm == nil {
            handleTurnTimeEnd()
            return
        }
        
        refreshTermVisualEffectsForCurrentTeam()
        
        // WICHTIG: Den ersten Begriff NICHT sofort als "gesehen" markieren
        // Er wird erst beim ersten Skip oder Correct als gesehen markiert
        // So startet der Counter bei der korrekten Anzahl (z.B. 35 statt 34)
        
        // Timer wird erst in der Drawing-Phase gestartet (bei Runde 4)
        // oder sofort bei anderen Runden
        if gameState.currentRound != .round4 {
            startTimer()
        }
    }
    
    // Entfernt - wird nicht mehr gebraucht, da handleTurnTimeEnd verwendet wird
    
    // MARK: - Timer
    private func startTimer() {
        turnTimer.invalidate()
        gameState.isTimerRunning = true
        
        turnTimer.start(interval: 1.0) { [weak self] in
            guard let self else { return }
            if self.isTimerFrozenForCurrentTeam() {
                self.timerFreezeRemaining = max(0, self.timerFreezeRemaining - 1)
                self.notifyUIChange()
                if self.timerFreezeRemaining <= 0 {
                    self.timerFreezeTeamId = nil
                }
                return
            }
            
            if self.gameState.turnTimeRemaining > 0 {
                let decrement = self.timerDecrementForCurrentTeam()
                self.gameState.turnTimeRemaining = max(0, self.gameState.turnTimeRemaining - decrement)
                self.cleanupExpiredRushIfNeeded()
                self.notifyUIChange()
            } else {
                self.handleTurnTimeEnd()
            }
        }
    }
    
    var formattedTimeRemaining: String {
        let minutes = Int(gameState.turnTimeRemaining) / 60
        let seconds = Int(gameState.turnTimeRemaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // Für Drawing-Phase: Timer manuell starten
    func startDrawingTimer() {
        guard gameState.currentRound == .round4 else { return }
        startTimer()
    }

    // MARK: - DEV Helpers
    #if DEBUG
    func configureDevTestGame() {
        // Reset Zustand
        turnTimer.invalidate()
        gameState = GameState()
        
        // Teams A & B
        gameState.settings.teams = [Team(name: "Team A"), Team(name: "Team B")]
        
        // Einstellungen: 120 Sek., 5 Wörter, Modus Mit Zeichnen
        gameState.settings.turnTimeLimit = 120
        gameState.settings.gameMode = .withDrawing
        gameState.settings.wordCount = 5
        
        // Grüne Kategorie auswählen, falls vorhanden
        if let greenCategory = availableCategories.first(where: { $0.type == .green }) {
                    gameState.settings.selectedCategories = [greenCategory]
                }
        
        // Spiel starten (Begriffe ziehen etc.)
        if canStartGame {
            startGame()
            // Direkt auf Runde 4 springen und im Setup bleiben
            gameState.currentRound = .round4
            gameState.phase = .setup
            gameState.turnTimeRemaining = gameState.settings.turnTimeLimit
        }
    }
    #endif
}

#if DEBUG
extension GameManager {
    struct DebugPositiveConfig {
        var nextWordDouble = true
        var doublePoints = true
        var rewind = true
        var shield = true
        var combo = true
    }
    
    struct DebugNegativeConfig {
        var suddenRush = true
        var slowMotionPending = true
        var timeBomb = true
        var pausePenalty = true
        var invisibleWord = true
        var forcedSkip = true
    }
    
    func debugSetupForPreview() {
        gameState.settings.perksEnabled = true
        if gameState.settings.teams.isEmpty {
            gameState.settings.teams = [
                Team(name: "Team A"),
                Team(name: "Team B")
            ]
        }
        gameState.currentRound = .round2
        gameState.currentTeamIndex = 0
        gameState.turnTimeRemaining = 42
        gameState.phase = .playing
        if gameState.allTerms.isEmpty {
            gameState.allTerms = [Term(text: "Kaleidoskop")]
        }
        gameState.currentTermIndex = 0
        notifyUIChange()
    }
    
    func debugApply(positive: DebugPositiveConfig, negative: DebugNegativeConfig) {
        guard let teamId = gameState.settings.teams.first?.id else { return }
        
        nextWordMultiplier[teamId] = positive.nextWordDouble ? 2 : 1
        turnPointMultiplier[teamId] = positive.doublePoints ? 2 : 1
        rewindBonusTeams = positive.rewind ? [teamId] : []
        comboBonusCounters[teamId] = positive.combo ? 1 : nil
        shieldCharges[teamId] = positive.shield ? 1 : 0
        
        pendingTurnTimePenalty[teamId] = negative.slowMotionPending ? 5 : nil
        if negative.pausePenalty { pausePenaltyTargets.insert(teamId) } else { pausePenaltyTargets.remove(teamId) }
        
        if negative.timeBomb {
            pendingTimeBombTargets = [teamId]
            activateTimeBombIfNeeded()
        } else {
            pendingTimeBombTargets.remove(teamId)
            cancelTimeBomb(for: teamId)
        }
        
        suddenRushExpiry[teamId] = negative.suddenRush ? Date().addingTimeInterval(60) : nil
        
        if negative.invisibleWord {
            pendingInvisibleWordTargets = [teamId]
            activatePendingInvisibleWordIfNeeded()
        } else {
            pendingInvisibleWordTargets.remove(teamId)
            removeInvisibleWord(for: teamId)
        }
        
        if negative.forcedSkip {
            forcedSkipTeams = [teamId]
        } else {
            forcedSkipTeams.remove(teamId)
        }
        
        notifyUIChange()
    }
}
#endif
