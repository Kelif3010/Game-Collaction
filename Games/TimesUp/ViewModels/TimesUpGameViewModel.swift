import Foundation
import SwiftUI
import Combine

@MainActor
class TimesUpGameViewModel: ObservableObject {

    // MARK: - Private Inner Types

    final class RepeatingMainTimer {
        nonisolated(unsafe) private var timer: Timer?

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

        deinit { timer?.invalidate() }
    }

    // Shared types used in stored properties — accessible from extension files
    enum VisualEffectKind { case mirror, glitch }
    struct VisualEffectState { var mirrorUntil: Date?; var glitchUntil: Date? }
    struct VisualEffectRequest { let kind: VisualEffectKind; let duration: TimeInterval }
    struct EnglishWordEffectState { var translation: String?; var expiresAt: Date?; var pendingTerm: String? }

    private enum LastAction: String { case none, next, skip, wrongGuess, correct, turnEnd, roundEnd }
    private enum MissReason { case skip, wrongGuess }

    // MARK: - Published State

    @Published var gameState = GameState() {
        didSet {
            if gameState.settings != oldValue.settings { saveSettings() }
        }
    }
    @Published var scoreRevealSnapshots: [UUID: ScoreRevealSnapshot] = [:]
    @Published var awardedPerks: [AwardedPerk] = []
    @Published var visualEffects: [UUID: VisualEffectState] = [:]
    @Published var skipButtonFreezeUntil: [UUID: Date] = [:]
    @Published var perkToast: PerkToast?
    @Published var timerValueBursts: [TimerValueBurst] = []
    @Published var slotRewardActiveTeamId: UUID?
    @Published var slotLastResult: SlotSpinResult?
    @Published var scoreBursts: [ScoreBurst] = []

    // MARK: - Internal State (accessible from extension files)

    var pendingVisualEffects: [UUID: [VisualEffectRequest]] = [:]
    var penaltyCardCounter: Int = 0
    var perksTriggeredThisTurn: Int = 0
    var lastPerkTypeThisTurn: PerkType?
    var timerFreezeTeamId: UUID?
    var timerFreezeRemaining: TimeInterval = 0
    var pendingTurnTimePenalty: [UUID: TimeInterval] = [:]
    var nextWordMultiplier: [UUID: Int] = [:]
    var turnPointMultiplier: [UUID: Int] = [:]
    var shieldCharges: [UUID: Int] = [:]
    var rewindBonusTeams: Set<UUID> = []
    var comboBonusCounters: [UUID: Int] = [:]
    var assistListeners: [UUID: [UUID]] = [:]
    var pausePenaltyTargets: Set<UUID> = []
    var pendingSwapWordTeams: Set<UUID> = []
    var swapWordTasks: [UUID: DispatchWorkItem] = [:]
    var pendingTimeBombTargets: Set<UUID> = []
    var activeTimeBombTimers: [UUID: RepeatingMainTimer] = [:]
    var suddenRushExpiry: [UUID: Date] = [:]
    var pendingInvisibleWordTargets: Set<UUID> = []
    var invisibleWordActiveTeams: Set<UUID> = []
    var invisibleWordHiddenTeams: Set<UUID> = []
    var invisibleWordHideTasks: [UUID: DispatchWorkItem] = [:]
    var activeStealBadges: Set<UUID> = []
    var forcedSkipTeams: Set<UUID> = []
    var activeForcedSkipTeamId: UUID?
    var slowMotionFlashUntil: [UUID: Date] = [:]
    var englishWordEffects: [UUID: EnglishWordEffectState] = [:]
    var englishWordExpiryTasks: [UUID: DispatchWorkItem] = [:]
    var slotSpinCredits: [UUID: Int] = [:]
    var pendingSlotSpinCredits: [UUID: Int] = [:]
    var attackNotices: [UUID: [PerkAttackNotice]] = [:]
    var attackNoticeExpiryTasks: [UUID: [UUID: DispatchWorkItem]] = [:]
    let skipFreezeDuration: TimeInterval = 10
    var maxPerksPerTurn: Int { gameState.settings.perkPartyMode ? 3 : 2 }

    private var lastAction: LastAction = .none
    private var lastSkippedIndex: Int?

    // MARK: - Dependencies

    let turnTimer = RepeatingMainTimer()
    let wordTranslationManager = TimesUpWordTranslationService()
    private let categoryViewModel: TimesUpCategoryViewModel

    // MARK: - Locale

    private lazy var appLocale: Locale = Self.resolveAppLocale()

    private static func resolveAppLocale() -> Locale {
        let defaults = UserDefaults.standard
        let useSystem: Bool
        if defaults.object(forKey: "useSystemLanguage") == nil {
            useSystem = true
        } else {
            useSystem = defaults.bool(forKey: "useSystemLanguage")
        }
        if useSystem { return AppLanguage.fromSystemPreferred().locale }
        let code = defaults.string(forKey: "selectedLanguageCode")
        return AppLanguage.from(code: code).locale
    }

    func localized(_ key: String.LocalizationValue, _ args: CVarArg...) -> String {
        let format = String(localized: key, locale: appLocale)
        guard !args.isEmpty else { return format }
        return String(format: format, locale: appLocale, arguments: args)
    }

    // MARK: - Init & Cleanup

    init(categoryViewModel: TimesUpCategoryViewModel? = nil) {
        self.categoryViewModel = categoryViewModel ?? TimesUpCategoryViewModel()
        if let data = UserDefaults.standard.data(forKey: "timesup.settings"),
           let settings = try? JSONDecoder().decode(TimesUpGameSettings.self, from: data) {
            self.gameState.settings = settings
        }
        NotificationCenter.default.addObserver(
            forName: Notification.Name("AppDidReset"), object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.gameState.settings = TimesUpGameSettings()
            }
        }
    }

    /// Call before dismissing the view to cancel all active timers and tasks (TU-02 Fix).
    func cleanup() {
        turnTimer.invalidate()
        activeTimeBombTimers.values.forEach { $0.invalidate() }
        activeTimeBombTimers.removeAll()
        swapWordTasks.values.forEach { $0.cancel() }
        swapWordTasks.removeAll()
        invisibleWordHideTasks.values.forEach { $0.cancel() }
        invisibleWordHideTasks.removeAll()
        englishWordExpiryTasks.values.forEach { $0.cancel() }
        englishWordExpiryTasks.removeAll()
    }

    deinit { }

    func notifyUIChange() {
        DispatchQueue.main.async { [weak self] in
            self?.objectWillChange.send()
        }
    }

    private func saveSettings() {
        if let data = try? JSONEncoder().encode(gameState.settings) {
            UserDefaults.standard.set(data, forKey: "timesup.settings")
        }
    }

    // MARK: - Setup

    var availableCategories: [TimesUpCategory] { categoryViewModel.categories }

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
            if !filtered.isEmpty { result[entry.key] = filtered }
        }
        if activeForcedSkipTeamId == team.id { activeForcedSkipTeamId = nil }
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

    var canStartGame: Bool { gameState.settings.isValid }

    func startGame() {
        guard canStartGame else { return }
        var allAvailableTerms = gameState.settings.selectedCategories.flatMap { $0.terms }
        allAvailableTerms.shuffle()
        gameState.allTerms = Array(allAvailableTerms.prefix(gameState.settings.wordCount))
        gameState.allTerms.shuffle()
        gameState.currentRound = .round1
        gameState.currentTeamIndex = 0
        gameState.currentTermIndex = 0
        gameState.phase = .setup
        gameState.turnTimeRemaining = gameState.settings.turnTimeLimit
        penaltyCardCounter = 0
        scoreRevealSnapshots = [:]
        gameState.seenTermsInCurrentTurn.removeAll()
        gameState.seenTermsInCurrentRound.removeAll()
        for i in gameState.settings.teams.indices { gameState.settings.teams[i].resetScores() }
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
        for i in gameState.allTerms.indices { gameState.allTerms[i].reset() }
    }

    func startRound() { startTurn() }

    func restartWithSameTeams() {
        for i in gameState.settings.teams.indices { gameState.settings.teams[i].resetScores() }
        gameState.allTerms.shuffle()
        for i in gameState.allTerms.indices { gameState.allTerms[i].reset() }
        gameState.currentRound = .round1
        gameState.currentTeamIndex = 0
        gameState.currentTermIndex = 0
        gameState.phase = .setup
        gameState.turnTimeRemaining = gameState.settings.turnTimeLimit
        scoreRevealSnapshots = [:]
        timerValueBursts.removeAll()
        slotSpinCredits.removeAll()
        pendingSlotSpinCredits.removeAll()
    }

    // MARK: - Gameplay Actions

    func correctGuess() {
        guard gameState.phase == .playing else { return }
        TimesUpHapticsService.shared.playSuccess()
        let currentTeamId = gameState.currentTeam?.id
        if let teamId = currentTeamId, pausePenaltyTargets.remove(teamId) != nil {
            gameState.turnTimeRemaining = max(0, gameState.turnTimeRemaining - 2)
            triggerTimerBurst(for: teamId, text: "-2s", isNegative: true)
        }
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
        guard gameState.currentTerm != nil else { return }
        if reason == .skip { TimesUpHapticsService.shared.playSkip() }
        let visibleIndex = gameState.resolvedCurrentTermIndex()
        gameState.markCurrentTermAsSeen()
        applySkipPenaltyIfNeeded()
        if reason == .wrongGuess { addPenaltyCardForCurrentTeam() }
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

    // MARK: - Turn Flow

    func nextTurn() {
        switch gameState.phase {
        case .slotReward:
            finishSlotReward()
        case .roundEnd:
            let isLastRound: Bool
            switch gameState.settings.gameMode {
            case .classic, .randomOrder: isLastRound = (gameState.currentRound == .round3)
            case .withDrawing: isLastRound = (gameState.currentRound == .round4)
            }
            if isLastRound {
                revealDeferredPenaltiesIfNeeded()
                for i in gameState.settings.teams.indices {
                    gameState.settings.teams[i].updateTotalScore(for: gameState.settings.gameMode)
                }
                gameState.phase = slotRewardActiveTeamId != nil ? .slotReward : .gameEnd
            } else {
                gameState.nextRound()
                if slotRewardActiveTeamId == nil { startTurn() }
            }
        case .setup:
            startTurn()
        default:
            break
        }
    }

    func startTurn() {
        gameState.phase = .playing
        gameState.startNewTurn()
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
        if gameState.currentRound != .round4 { startTimer() }
    }

    func checkForNextTermOrRoundEnd() {
        if gameState.allTermsCompletedForCurrentRound {
            turnTimer.invalidate()
            gameState.phase = .roundEnd
        } else {
            gameState.nextTerm()
            refreshTermVisualEffectsForCurrentTeam()
        }
    }

    // MARK: - DEV Helpers

    #if DEBUG
    func configureDevTestGame() {
        turnTimer.invalidate()
        gameState = GameState()
        gameState.settings.teams = [Team(name: "Team A"), Team(name: "Team B")]
        gameState.settings.turnTimeLimit = 120
        gameState.settings.gameMode = .withDrawing
        gameState.settings.wordCount = 5
        if let greenCategory = availableCategories.first(where: { $0.type == .green }) {
            gameState.settings.selectedCategories = [greenCategory]
        }
        if canStartGame {
            startGame()
            gameState.currentRound = .round4
            gameState.phase = .setup
            gameState.turnTimeRemaining = gameState.settings.turnTimeLimit
        }
    }
    #endif
}

#if DEBUG
extension TimesUpGameViewModel {
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
            gameState.settings.teams = [Team(name: "Team A"), Team(name: "Team B")]
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
        if negative.forcedSkip { forcedSkipTeams = [teamId] } else { forcedSkipTeams.remove(teamId) }
        notifyUIChange()
    }
}
#endif
