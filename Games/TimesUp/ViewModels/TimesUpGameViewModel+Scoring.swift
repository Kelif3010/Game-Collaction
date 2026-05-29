import Foundation

// MARK: - Scoring & Penalties
extension TimesUpGameViewModel {

    func addPointsToCurrentTeam(basePoints: Int, reason: String) {
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

    func addFlatPoints(_ points: Int, to teamId: UUID, reason: String) {
        guard let index = gameState.settings.teams.firstIndex(where: { $0.id == teamId }) else { return }
        gameState.settings.teams[index].addScore(points, for: gameState.currentRound.rawValue)
    }

    // MARK: - Penalties

    func addPenaltyCardForCurrentTeam() {
        guard gameState.currentTeamIndex < gameState.settings.teams.count else { return }
        TimesUpHapticsService.shared.playPenalty()
        let team = gameState.settings.teams[gameState.currentTeamIndex]
        var penaltyTerm = generatePenaltyTerm(for: team)
        penaltyTerm.assignedTeamId = team.id
        let currentTurnCount = gameState.teamTurnCounters[team.id] ?? 0
        penaltyTerm.availableFromTeamTurn = currentTurnCount + 1
        gameState.allTerms.append(penaltyTerm)
    }

    func generatePenaltyTerm(for team: Team) -> Term {
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

    func applySkipPenaltyIfNeeded() {
        guard gameState.currentTeamIndex < gameState.settings.teams.count else { return }
        if gameState.settings.difficulty != .easy {
            TimesUpHapticsService.shared.playPenalty()
        }
        let round = gameState.currentRound.rawValue
        let teamId = gameState.settings.teams[gameState.currentTeamIndex].id
        if consumeShieldIfAvailable(for: teamId) { return }
        switch gameState.settings.difficulty {
        case .easy:
            break
        case .medium:
            gameState.settings.teams[gameState.currentTeamIndex].applyPenalty(1, for: round, revealAtEnd: true)
            logPendingPenalties()
        case .hard:
            gameState.settings.teams[gameState.currentTeamIndex].applyPenalty(1, for: round)
            logCurrentScores()
        }
    }

    func revealDeferredPenaltiesIfNeeded() {
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

    func consumeShieldIfAvailable(for teamId: UUID) -> Bool {
        guard let charges = shieldCharges[teamId], charges > 0 else { return false }
        shieldCharges[teamId] = charges - 1
        return true
    }

    // MARK: - Streaks & Combos

    func incrementComboCounter(for teamId: UUID) {
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

    func resetComboCounter(for teamId: UUID) {
        guard comboBonusCounters[teamId] != nil else { return }
        comboBonusCounters[teamId] = 0
    }

    func incrementHitStreak(for teamId: UUID) {
        let newValue = (gameState.teamHitStreaks[teamId] ?? 0) + 1
        gameState.teamHitStreaks[teamId] = newValue
        if newValue % 10 == 0 {
            pendingSlotSpinCredits[teamId, default: 0] += 1
        }
    }

    func resetStreakForCurrentTeam() {
        guard gameState.currentTeamIndex < gameState.settings.teams.count else { return }
        let teamId = gameState.settings.teams[gameState.currentTeamIndex].id
        resetStreak(for: teamId)
    }

    func resetStreak(for teamId: UUID) {
        gameState.teamHitStreaks[teamId] = 0
        resetComboCounter(for: teamId)
    }

    // MARK: - Steal & Assist

    @discardableResult
    func applyStealPoints(from teamIndex: Int) -> Team? {
        guard let opponentIndex = nextTeamIndex(after: teamIndex) else { return nil }
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

    func nextTeamIndex(after index: Int) -> Int? {
        guard !gameState.settings.teams.isEmpty, gameState.settings.teams.count > 1 else { return nil }
        return (index + 1) % gameState.settings.teams.count
    }

    func rewardAssistPointsIfNeeded(forSkippedTeam teamId: UUID?) {
        guard let teamId,
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

    func activateSlowMotionOpponent(from teamIndex: Int) {
        guard let opponentIndex = nextTeamIndex(after: teamIndex) else { return }
        let opponent = gameState.settings.teams[opponentIndex]
        pendingTurnTimePenalty[opponent.id, default: 0] += 5
    }

    func clearTurnScopedPerks(for teamId: UUID) {
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

    // MARK: - Perks

    func handlePerkProgressAfterCorrect() {
        guard gameState.settings.perksEnabled,
              gameState.settings.hasAnyPerkSelection,
              gameState.currentTeamIndex < gameState.settings.teams.count else { return }
        guard perksTriggeredThisTurn < maxPerksPerTurn else { return }
        let team = gameState.settings.teams[gameState.currentTeamIndex]
        let newStreak = gameState.teamHitStreaks[team.id] ?? 0
        let thresholds = gameState.settings.perkPartyMode ? [3, 6, 9] : [5, 8]
        guard thresholds.contains(newStreak) else { return }
        guard let perkType = nextPerkTypeToAward(excluding: lastPerkTypeThisTurn) else { return }
        perksTriggeredThisTurn += 1
        let perk = AwardedPerk(teamId: team.id, teamName: team.name, round: gameState.currentRound, type: perkType, streak: newStreak)
        awardedPerks.append(perk)
        applyPerkEffect(perk, teamIndex: gameState.currentTeamIndex)
        lastPerkTypeThisTurn = perkType
    }

    func nextPerkTypeToAward(excluding lastPerk: PerkType?) -> PerkType? {
        if !gameState.settings.customPerks.isEmpty {
            let allowed = filterPerksForCurrentRound(Array(gameState.settings.customPerks), excluding: lastPerk)
            return allowed.randomElement()
        }
        let packs = gameState.settings.selectedStandardPerkPacks
        guard !packs.isEmpty else { return nil }
        let candidates = PerkType.allCases.filter { packs.contains($0.pack) && $0.isImplemented }
        let allowed = filterPerksForCurrentRound(candidates, excluding: lastPerk)
        return allowed.randomElement()
    }

    func filterPerksForCurrentRound(_ perks: [PerkType], excluding lastPerk: PerkType?) -> [PerkType] {
        return perks.filter { perk in
            if !gameState.currentRound.canSkip && perk == .assistPoints { return false }
            if let lastPerk, perk == lastPerk { return false }
            return true
        }
    }

    func applyPerkEffect(_ perk: AwardedPerk, teamIndex: Int) {
        guard gameState.settings.perksEnabled else { return }
        TimesUpHapticsService.shared.playPerkActivation()
        switch perk.type {
        case .freezeTime:
            activateFreezeTime(for: perk.teamId)
        case .slowMotionOpponent:
            guard let target = nextTeamIndex(after: teamIndex).map({ gameState.settings.teams[$0] }) else { return }
            activateSlowMotionOpponent(from: teamIndex)
            registerAttackNotice(for: perk.teamId, targetName: target.name, icon: "🐢", label: localized("-5s Slow Motion"))
        case .rewindHit:
            rewindBonusTeams.insert(perk.teamId)
        case .timeBomb:
            guard let target = nextTeamIndex(after: teamIndex).map({ gameState.settings.teams[$0] }) else { return }
            pendingTimeBombTargets.insert(target.id)
            if gameState.currentTeam?.id == target.id { activateTimeBombIfNeeded() }
            registerAttackNotice(for: perk.teamId, targetName: target.name, icon: "💣", label: localized("Zeitbombe"))
        case .suddenRush:
            guard let target = nextTeamIndex(after: teamIndex).map({ gameState.settings.teams[$0] }) else { return }
            applySuddenRush(to: target.id)
            registerAttackNotice(for: perk.teamId, targetName: target.name, icon: "⚡️", label: localized("Rush"))
        case .nextWordDouble:
            nextWordMultiplier[perk.teamId] = 2
        case .doublePointsThisTurn:
            turnPointMultiplier[perk.teamId] = 2
        case .stealPoints:
            let target = applyStealPoints(from: teamIndex)
            activeStealBadges.insert(perk.teamId)
            if let target {
                registerAttackNotice(for: perk.teamId, targetName: target.name, icon: "💰", label: localized("2 Punkte gestohlen"))
            }
        case .shield:
            shieldCharges[perk.teamId, default: 0] += 1
        case .comboBonus:
            comboBonusCounters[perk.teamId] = 0
        case .assistPoints:
            guard let target = nextTeamIndex(after: teamIndex).map({ gameState.settings.teams[$0] }) else { return }
            assistListeners[target.id, default: []].append(perk.teamId)
            registerAttackNotice(for: perk.teamId, targetName: target.name, icon: "🤝", label: localized("Assist aktiv"))
        case .mirroredWord:
            guard let target = nextTeamIndex(after: teamIndex).map({ gameState.settings.teams[$0] }) else { return }
            queueVisualEffect(.mirror, for: target.id, duration: 5)
            registerAttackNotice(for: perk.teamId, targetName: target.name, icon: "🪞", label: localized("Spiegelwort"))
        case .forcedSkip:
            guard gameState.currentRound.canSkip else { return }
            guard let target = nextTeamIndex(after: teamIndex).map({ gameState.settings.teams[$0] }) else { return }
            scheduleForcedSkip(for: target.id)
            registerAttackNotice(for: perk.teamId, targetName: target.name, icon: "⛔️", label: localized("Zwangs-Skip"))
        case .freezeSkipButton:
            guard gameState.currentRound.canSkip else { return }
            guard let target = nextTeamIndex(after: teamIndex).map({ gameState.settings.teams[$0] }) else { return }
            freezeSkipButton(for: target.id, duration: skipFreezeDuration)
            registerAttackNotice(for: perk.teamId, targetName: target.name, icon: "🔒", label: localized("Skip gesperrt"))
        case .glitchLetters:
            guard let target = nextTeamIndex(after: teamIndex).map({ gameState.settings.teams[$0] }) else { return }
            queueVisualEffect(.glitch, for: target.id, duration: 5)
            registerAttackNotice(for: perk.teamId, targetName: target.name, icon: "✨", label: localized("Glitch-Buchstaben"))
        case .pausePenalty:
            guard let target = nextTeamIndex(after: teamIndex).map({ gameState.settings.teams[$0] }) else { return }
            pausePenaltyTargets.insert(target.id)
            registerAttackNotice(for: perk.teamId, targetName: target.name, icon: "⏱", label: localized("-2s Penalty"))
        case .swapWord:
            guard let target = nextTeamIndex(after: teamIndex).map({ gameState.settings.teams[$0] }) else { return }
            pendingSwapWordTeams.insert(target.id)
            if gameState.currentTeam?.id == target.id { activateSwapWordIfNeeded() }
            registerAttackNotice(for: perk.teamId, targetName: target.name, icon: "🔄", label: localized("Worttausch"))
        case .invisibleWord:
            guard let target = nextTeamIndex(after: teamIndex).map({ gameState.settings.teams[$0] }) else { return }
            activateInvisibleWord(for: target.id)
            registerAttackNotice(for: perk.teamId, targetName: target.name, icon: "🙈", label: localized("Wort verschwindet"))
        case .englishWord:
            guard let target = nextTeamIndex(after: teamIndex).map({ gameState.settings.teams[$0] }) else { return }
            activateEnglishWordEffect(for: target.id)
            registerAttackNotice(for: perk.teamId, targetName: target.name, icon: "🌍", label: localized("Wort auf Englisch"))
        }
    }

    // MARK: - Logging (empty stubs)

    private func logScoreChange(for teamIndex: Int, round: Int, delta: Int, reason: String) { }
    func logPendingPenalties() { }
    func logCurrentScores() { }
    func logRoundSummary(context: String) { }
}
