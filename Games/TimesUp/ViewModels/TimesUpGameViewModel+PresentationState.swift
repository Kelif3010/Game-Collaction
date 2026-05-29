import Foundation

// MARK: - Nested Types & UI State Queries
extension TimesUpGameViewModel {

    // MARK: - Nested Types

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

    // MARK: - UI Queries

    func displayTextForCurrentTeam(term: Term?) -> String {
        guard let term else { return "" }
        if let teamId = gameState.currentTeam?.id {
            if invisibleWordHiddenTeams.contains(teamId) { return "" }
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

    func currentHitStreakCount() -> Int {
        guard let teamId = gameState.currentTeam?.id else { return 0 }
        return gameState.teamHitStreaks[teamId] ?? 0
    }

    func isForcedSkipActiveForCurrentTeam() -> Bool {
        guard let teamId = gameState.currentTeam?.id else { return false }
        return activeForcedSkipTeamId == teamId
    }

    func isSkipButtonFrozenForCurrentTeam() -> Bool {
        guard let teamId = gameState.currentTeam?.id else { return false }
        if isForcedSkipActiveForCurrentTeam() { return false }
        return isSkipButtonFrozen(for: teamId)
    }

    func slowMotionHintForCurrentTeam() -> String? {
        guard let teamId = gameState.currentTeam?.id else { return nil }
        if hasActiveSlowMotion(for: teamId) { return "Slow Motion aktiv" }
        if pendingTurnTimePenalty[teamId] != nil { return "Slow Motion vorbereitet" }
        return nil
    }

    func activeBadgesForCurrentTeam() -> [PerkBadge] {
        guard let teamId = gameState.currentTeam?.id else { return [] }
        var badges: [PerkBadge] = []
        if nextWordMultiplier[teamId, default: 1] > 1 { badges.append(.nextWordDouble) }
        if turnPointMultiplier[teamId, default: 1] > 1 { badges.append(.doublePoints) }
        if shieldCharges[teamId, default: 0] > 0 { badges.append(.shield) }
        if isTimerFrozen(for: teamId) { badges.append(.freeze) }
        if slowMotionHintForCurrentTeam() != nil { badges.append(.slowMotion) }
        if activeStealBadges.contains(teamId) { badges.append(.stealPoints) }
        return badges
    }

    func perkNoticesForCurrentTeam() -> [PerkNotice] {
        guard let teamId = gameState.currentTeam?.id else { return [] }
        var notices: [PerkNotice] = []
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
            let attackerNames = attackers.compactMap { id in
                gameState.settings.teams.first(where: { $0.id == id })?.name
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

    // MARK: - Toast & Bursts

    func showPerkToast(_ toast: PerkToast) {
        perkToast = toast
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            guard let self else { return }
            if self.perkToast?.id == toast.id { self.perkToast = nil }
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

    // MARK: - Attack Notices

    func registerAttackNotice(for attackerId: UUID, targetName: String, icon: String, label: String, duration: TimeInterval = 6) {
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

    func removeAttackNotice(_ noticeId: UUID, for teamId: UUID) {
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

    // MARK: - Slot Machine

    func slotRewardTeam() -> Team? {
        guard let id = slotRewardActiveTeamId else { return nil }
        return gameState.settings.teams.first { $0.id == id }
    }

    func slotRewardCredits() -> Int {
        guard let id = slotRewardActiveTeamId else { return 0 }
        return slotSpinCredits[id, default: 0]
    }

    func slotRewardLastResultText() -> String? { slotLastResult?.text }

    @discardableResult
    func spinSlotReward() -> SlotSpinResult? {
        guard let teamId = slotRewardActiveTeamId,
              slotSpinCredits[teamId, default: 0] > 0 else { return nil }
        let didWin = Bool.random()
        let delta = didWin ? 10 : -15
        addFlatPoints(delta, to: teamId, reason: String(localized: "🎰 Slot Maschine"))
        triggerScoreBurst(for: teamId, text: delta >= 0 ? "+10Pkt" : "-15Pkt", isNegative: delta < 0)
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

    func proceedAfterSlotIfNeeded() {
        guard slotRewardActiveTeamId == nil else { return }
        gameState.phase = gameState.allTermsCompletedForCurrentRound ? .roundEnd : .setup
    }

    // MARK: - Visual Effects

    func activateVisualEffect(_ kind: VisualEffectKind, for teamId: UUID, duration: TimeInterval) {
        var state = visualEffects[teamId] ?? VisualEffectState()
        let expiry = Date().addingTimeInterval(duration)
        switch kind {
        case .mirror: state.mirrorUntil = expiry
        case .glitch: state.glitchUntil = expiry
        }
        visualEffects[teamId] = state
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            self?.clearVisualEffect(kind: kind, teamId: teamId, expectedExpiry: expiry)
        }
    }

    func clearVisualEffect(kind: VisualEffectKind, teamId: UUID, expectedExpiry: Date) {
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

    func queueVisualEffect(_ kind: VisualEffectKind, for teamId: UUID, duration: TimeInterval) {
        if gameState.currentTeam?.id == teamId {
            activateVisualEffect(kind, for: teamId, duration: duration)
            return
        }
        var queue = pendingVisualEffects[teamId] ?? []
        queue.append(VisualEffectRequest(kind: kind, duration: duration))
        pendingVisualEffects[teamId] = queue
    }

    func activatePendingVisualEffectsForCurrentTeam() {
        guard let teamId = gameState.currentTeam?.id,
              let queue = pendingVisualEffects[teamId],
              !queue.isEmpty else { return }
        pendingVisualEffects[teamId] = nil
        queue.forEach { activateVisualEffect($0.kind, for: teamId, duration: $0.duration) }
    }

    func isMirrorActive(for teamId: UUID?) -> Bool {
        guard let teamId, let expiry = visualEffects[teamId]?.mirrorUntil else { return false }
        if expiry <= Date() {
            clearVisualEffect(kind: .mirror, teamId: teamId, expectedExpiry: expiry)
            return false
        }
        return true
    }

    func isGlitchActive(for teamId: UUID?) -> Bool {
        guard let teamId, let expiry = visualEffects[teamId]?.glitchUntil else { return false }
        if expiry <= Date() {
            clearVisualEffect(kind: .glitch, teamId: teamId, expectedExpiry: expiry)
            return false
        }
        return true
    }

    func transform(text: String, for teamId: UUID?) -> String {
        guard let teamId else { return text }
        var output = text
        if isMirrorActive(for: teamId) { output = String(output.reversed()) }
        if isGlitchActive(for: teamId) { output = glitchText(output) }
        return output
    }

    func glitchText(_ text: String) -> String {
        guard text.count > 2 else { return String(repeating: "_", count: max(1, text.count)) }
        var characters = Array(text)
        for index in characters.indices where index != 0 && index != characters.count - 1 {
            if Bool.random() { characters[index] = "_" }
        }
        return String(characters)
    }

    func hasActiveSlowMotion(for teamId: UUID) -> Bool {
        guard let expiry = slowMotionFlashUntil[teamId] else { return false }
        if expiry <= Date() {
            slowMotionFlashUntil[teamId] = nil
            return false
        }
        return true
    }

    // MARK: - Skip Button

    func isSkipButtonFrozen(for teamId: UUID) -> Bool {
        guard let expiry = skipButtonFreezeUntil[teamId] else { return false }
        if expiry <= Date() {
            skipButtonFreezeUntil[teamId] = nil
            return false
        }
        return true
    }

    func skipFreezeRemainingSeconds(for teamId: UUID) -> Int? {
        guard let expiry = skipButtonFreezeUntil[teamId] else { return nil }
        let remaining = expiry.timeIntervalSinceNow
        if remaining <= 0 {
            skipButtonFreezeUntil[teamId] = nil
            return nil
        }
        return Int(ceil(remaining))
    }

    func freezeSkipButton(for teamId: UUID, duration: TimeInterval) {
        let expiry = Date().addingTimeInterval(duration)
        skipButtonFreezeUntil[teamId] = expiry
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            guard let self else { return }
            if self.skipButtonFreezeUntil[teamId] == expiry {
                self.skipButtonFreezeUntil[teamId] = nil
            }
        }
    }

    // MARK: - Forced Skip

    func scheduleForcedSkip(for teamId: UUID) {
        forcedSkipTeams.insert(teamId)
    }

    func activateForcedSkipIfNeeded() {
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

    func resolveForcedSkipIfNeeded() {
        activeForcedSkipTeamId = nil
    }

    // MARK: - Swap Word

    func activateSwapWordIfNeeded() {
        guard let teamId = gameState.currentTeam?.id else { return }
        guard pendingSwapWordTeams.remove(teamId) != nil else { return }
        startSwapWordCountdown(for: teamId)
    }

    func startSwapWordCountdown(for teamId: UUID) {
        cancelSwapWordTask(for: teamId)
        let workItem = DispatchWorkItem { [weak self] in
            self?.performSwapWordForActiveTeam()
        }
        swapWordTasks[teamId] = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: workItem)
    }

    func cancelSwapWordTask(for teamId: UUID) {
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

    // MARK: - Invisible Word

    func activatePendingInvisibleWordIfNeeded() {
        guard let teamId = gameState.currentTeam?.id else { return }
        if pendingInvisibleWordTargets.remove(teamId) != nil {
            invisibleWordActiveTeams.insert(teamId)
            scheduleInvisibleWord(for: teamId)
        }
    }

    func refreshTermVisualEffectsForCurrentTeam() {
        guard let teamId = gameState.currentTeam?.id else { return }
        if invisibleWordActiveTeams.contains(teamId) {
            invisibleWordHiddenTeams.remove(teamId)
            scheduleInvisibleWord(for: teamId)
            notifyUIChange()
        }
    }

    func activateInvisibleWord(for teamId: UUID) {
        if gameState.currentTeam?.id == teamId {
            invisibleWordActiveTeams.insert(teamId)
            pendingInvisibleWordTargets.remove(teamId)
            scheduleInvisibleWord(for: teamId)
        } else {
            pendingInvisibleWordTargets.insert(teamId)
        }
    }

    func scheduleInvisibleWord(for teamId: UUID) {
        invisibleWordHideTasks[teamId]?.cancel()
        invisibleWordHiddenTeams.remove(teamId)
        let task = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.invisibleWordHiddenTeams.insert(teamId)
            self.notifyUIChange()
        }
        invisibleWordHideTasks[teamId] = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: task)
    }

    func removeInvisibleWord(for teamId: UUID) {
        invisibleWordHideTasks[teamId]?.cancel()
        invisibleWordHideTasks.removeValue(forKey: teamId)
        invisibleWordActiveTeams.remove(teamId)
        let removed = invisibleWordHiddenTeams.remove(teamId) != nil
        pendingInvisibleWordTargets.remove(teamId)
        if removed { notifyUIChange() }
    }

    // MARK: - English Word Effect

    func activateEnglishWordEffect(for teamId: UUID) {
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

    func startEnglishWordEffect(for teamId: UUID, translation: String) {
        guard var state = englishWordEffects[teamId] else { return }
        let expiry = Date().addingTimeInterval(7)
        state.translation = translation
        state.expiresAt = expiry
        englishWordEffects[teamId] = state
        scheduleEnglishWordEffectExpiry(for: teamId, expiry: expiry)
        notifyUIChange()
    }

    func scheduleEnglishWordEffectExpiry(for teamId: UUID, expiry: Date) {
        englishWordExpiryTasks[teamId]?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            guard let self else { return }
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

    func clearEnglishWordEffect(for teamId: UUID) {
        englishWordEffects.removeValue(forKey: teamId)
        englishWordExpiryTasks[teamId]?.cancel()
        englishWordExpiryTasks.removeValue(forKey: teamId)
    }
}
