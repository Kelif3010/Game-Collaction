import Foundation

// MARK: - Timer Logic
extension TimesUpGameViewModel {

    func startTimer() {
        turnTimer.invalidate()
        gameState.isTimerRunning = true
        turnTimer.start(interval: 1.0) { [weak self] in
            guard let self else { return }
            if self.isTimerFrozenForCurrentTeam() {
                self.timerFreezeRemaining = max(0, self.timerFreezeRemaining - 1)
                self.notifyUIChange()
                if self.timerFreezeRemaining <= 0 { self.timerFreezeTeamId = nil }
                return
            }
            if self.gameState.turnTimeRemaining > 0 {
                let decrement = self.timerDecrementForCurrentTeam()
                self.gameState.turnTimeRemaining = max(0, self.gameState.turnTimeRemaining - decrement)
                TimesUpHapticsService.shared.playTimerTick(secondsRemaining: Int(self.gameState.turnTimeRemaining))
                self.cleanupExpiredRushIfNeeded()
                self.notifyUIChange()
            } else {
                TimesUpHapticsService.shared.playTimerTick(secondsRemaining: 0)
                self.handleTurnTimeEnd()
            }
        }
    }

    func startDrawingTimer() {
        guard gameState.currentRound == .round4 else { return }
        startTimer()
    }

    var formattedTimeRemaining: String {
        let minutes = Int(gameState.turnTimeRemaining) / 60
        let seconds = Int(gameState.turnTimeRemaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    func handleTurnTimeEnd() {
        turnTimer.invalidate()
        gameState.isTimerRunning = false
        let finishingTeamId = gameState.currentTeam?.id
        perksTriggeredThisTurn = 0
        if let finishingTeamId {
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
        if !roundCompleted { gameState.nextTeam() }
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

    // MARK: - Timer Freeze

    func isTimerFrozenForCurrentTeam() -> Bool {
        isTimerFrozen(for: gameState.currentTeam?.id)
    }

    func isTimerFrozen(for teamId: UUID?) -> Bool {
        guard let teamId,
              let freezeTeam = timerFreezeTeamId,
              freezeTeam == teamId else { return false }
        return timerFreezeRemaining > 0
    }

    func freezeTimeRemainingSeconds(for teamId: UUID) -> Int? {
        guard let freezeTeam = timerFreezeTeamId,
              freezeTeam == teamId,
              timerFreezeRemaining > 0 else { return nil }
        return Int(ceil(timerFreezeRemaining))
    }

    func activateFreezeTime(for teamId: UUID) {
        timerFreezeTeamId = teamId
        timerFreezeRemaining = 5
    }

    func normalizeTimerFreezeForCurrentTeam() {
        guard let freezeTeam = timerFreezeTeamId,
              let current = gameState.currentTeam?.id,
              freezeTeam != current else { return }
        timerFreezeTeamId = nil
        timerFreezeRemaining = 0
    }

    // MARK: - Timer Modifiers

    func timerDecrementForCurrentTeam() -> Double {
        guard let teamId = gameState.currentTeam?.id else { return 1 }
        return isSuddenRushActive(for: teamId) ? 2 : 1
    }

    func isSuddenRushActive(for teamId: UUID?) -> Bool {
        guard let teamId, let expiry = suddenRushExpiry[teamId] else { return false }
        if expiry <= Date() {
            suddenRushExpiry.removeValue(forKey: teamId)
            notifyUIChange()
            return false
        }
        return true
    }

    func applySuddenRush(to teamId: UUID) {
        suddenRushExpiry[teamId] = Date().addingTimeInterval(10)
        notifyUIChange()
    }

    func cleanupExpiredRushIfNeeded() {
        guard let teamId = gameState.currentTeam?.id,
              let expiry = suddenRushExpiry[teamId],
              expiry <= Date() else { return }
        suddenRushExpiry.removeValue(forKey: teamId)
        notifyUIChange()
    }

    // MARK: - Time Bomb

    func activateTimeBombIfNeeded() {
        guard let teamId = gameState.currentTeam?.id else { return }
        guard pendingTimeBombTargets.remove(teamId) != nil else { return }
        startTimeBomb(for: teamId)
    }

    func startTimeBomb(for teamId: UUID) {
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

    func cancelTimeBomb(for teamId: UUID) {
        activeTimeBombTimers[teamId]?.invalidate()
        activeTimeBombTimers.removeValue(forKey: teamId)
    }

    // MARK: - Slow Motion

    func applyPendingTimePenaltyIfNeeded() {
        guard let team = gameState.currentTeam else { return }
        guard let penalty = pendingTurnTimePenalty.removeValue(forKey: team.id), penalty > 0 else { return }
        let oldTime = gameState.turnTimeRemaining
        gameState.turnTimeRemaining = max(1, gameState.turnTimeRemaining - penalty)
        slowMotionFlashUntil[team.id] = Date().addingTimeInterval(3)
        triggerTimerBurst(for: team.id, text: "-\(Int(min(penalty, oldTime)))s", isNegative: true)
    }
}
