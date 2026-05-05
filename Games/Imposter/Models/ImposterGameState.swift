//
//  ImposterGameState.swift
//  Imposter
//

import Foundation
import Algorithms
import AsyncAlgorithms
import MultipeerConnectivity

extension GameLogic {

    // MARK: - Game Flow Control

    func markCurrentPlayerCardSeen() {
        if gameSettings.currentPlayerIndex < gameSettings.players.count {
            gameSettings.players[gameSettings.currentPlayerIndex].hasSeenCard = true
        }

        if MultipeerManager.shared.role == .host {
            broadcastGameState()
        }
    }

    func nextPlayer() {
        if gameSettings.currentPlayerIndex < gameSettings.players.count - 1 {
            gameSettings.currentPlayerIndex += 1
        } else {
            gameSettings.gamePhase = .playing
            gameSettings.isTimerPaused = true
            startGameTimer()
        }

        if MultipeerManager.shared.role == .host {
            broadcastGameState()
        }
    }

    // MARK: - Timer

    private func startGameTimer() {
        guard gameTimerTask == nil else { return }
        lastTickUptime = ProcessInfo.processInfo.systemUptime
        if preciseTimeRemaining == nil {
            preciseTimeRemaining = Double(gameSettings.timeRemaining)
        }
        lastTimerSyncUptime = nil
        let interval = Duration.milliseconds(Int64((timerTickInterval * 1000).rounded()))
        gameTimerTask = Task { @MainActor [weak self] in
            for await _ in AsyncTimerSequence(interval: interval, clock: .continuous) {
                guard let self else { break }
                guard !Task.isCancelled else { break }
                self.handleTimerTick()
            }
        }
    }

    private func handleTimerTick() {
        let now = ProcessInfo.processInfo.systemUptime
        guard let lastTickUptime else {
            self.lastTickUptime = now
            return
        }

        if gameSettings.isTimerPaused {
            self.lastTickUptime = now
            return
        }

        let delta = max(0, now - lastTickUptime)
        self.lastTickUptime = now

        let previousDisplay = gameSettings.timeRemaining
        let baseRemaining = preciseTimeRemaining ?? Double(previousDisplay)
        let updatedRemaining = max(0, baseRemaining - delta)
        preciseTimeRemaining = updatedRemaining

        let display = max(0, Int(ceil(updatedRemaining)))
        if display != previousDisplay {
            gameSettings.timeRemaining = display
            ImposterHapticsManager.shared.playTimerTick(secondsRemaining: display)
        }

        if MultipeerManager.shared.role == .host {
            maybeSyncTimer(now: now)
        } else if MultipeerManager.shared.role == .peer {
            maybeClientPing(now: now)
        }

        if updatedRemaining <= 0, gameSettings.gamePhase != .finished {
            gameSettings.gamePhase = .finished
            gameSettings.markRoundCompleted()
            stopGameTimer()

            if MultipeerManager.shared.role == .host {
                broadcastGameState()
                MultipeerManager.shared.sendToAll(event: MPCEventType.imposterGameOver)
            }

            let (spies, citizens) = gameSettings.players.partitioned {
                $0.isImposter || $0.roleType?.team == .imposter
            }

            for spy in spies {
                StatsService.shared.recordSpyWinTimeOut(spyName: spy.name)
                GlobalStatsManager.shared.recordWin(for: spy.name)
            }

            for citizen in citizens {
                GlobalStatsManager.shared.recordLoss(for: citizen.name)
            }

            StatsService.shared.recordLoss(playerNames: citizens.map { $0.name }, asImposter: false)
        }
    }

    private func maybeSyncTimer(now: TimeInterval) {
        guard !gameSettings.isTimerPaused else { return }
        if let lastSync = lastTimerSyncUptime, (now - lastSync) < timerSyncInterval {
            return
        }
        lastTimerSyncUptime = now
        broadcastGameState()
    }

    private func maybeClientPing(now: TimeInterval) {
        guard !gameSettings.isTimerPaused else { return }

        if let lastPing = lastClientPingUptime, (now - lastPing) < clientPingSyncInterval {
            return
        }

        lastClientPingUptime = now

        let mpc = MultipeerManager.shared
        let ping = ImposterTimeSyncPingPayload(
            clientName: mpc.myPeerId.displayName,
            pingId: UUID(),
            clientSendUptime: now
        )
        mpc.sendToHost(event: MPCEventType.imposterTimeSyncPing, object: ping)
    }

    func stopGameTimer() {
        gameTimerTask?.cancel()
        gameTimerTask = nil
        lastTickUptime = nil
        lastTimerSyncUptime = nil
        lastClientPingUptime = nil
        preciseTimeRemaining = nil
        lastRemotePauseState = nil
        scheduledStartTask?.cancel()
        scheduledStartTask = nil
        HintService.shared.stopHints()
        VoiceService.shared.stopSpeaking()
    }

    func startMultiplayerTimerIfNeeded() {
        guard MultipeerManager.shared.role == .host else { return }
        if gameSettings.timeRemaining <= 0 {
            gameSettings.timeRemaining = gameSettings.timeLimit
        }
        gameSettings.gamePhase = .playing
        scheduleMultiplayerStart(startAtHostUptime: ProcessInfo.processInfo.systemUptime)
    }

    func applyRemoteTimerSync(_ sync: ImposterGameStateSync, hostClockOffset: TimeInterval) {
        let now = ProcessInfo.processInfo.systemUptime
        let hostUptimeAtClient = sync.hostUptime - hostClockOffset
        let elapsed = max(0, now - hostUptimeAtClient)
        let baseRemaining = max(0, sync.timeRemainingPrecise)
        let expectedRemaining = max(0, baseRemaining - (sync.isTimerPaused ? 0 : elapsed))
        let pauseChanged = lastRemotePauseState == nil || lastRemotePauseState != sync.isTimerPaused
        lastRemotePauseState = sync.isTimerPaused
        gameSettings.isTimerPaused = sync.isTimerPaused

        if pauseChanged {
            preciseTimeRemaining = expectedRemaining
        } else {
            let currentRemaining = preciseTimeRemaining ?? Double(gameSettings.timeRemaining)
            let delta = expectedRemaining - currentRemaining
            if abs(delta) >= softSyncThreshold {
                preciseTimeRemaining = expectedRemaining
            } else {
                preciseTimeRemaining = currentRemaining + delta * softSyncFactor
            }
        }

        let display = max(0, Int(ceil(preciseTimeRemaining ?? expectedRemaining)))
        if gameSettings.timeRemaining != display {
            gameSettings.timeRemaining = display
        }

        lastTickUptime = now
        if gameTimerTask == nil {
            startGameTimer()
        }
    }

    func scheduleMultiplayerStart(startAtHostUptime: TimeInterval) {
        scheduledStartTask?.cancel()
        scheduledStartTask = nil

        if gameSettings.timeRemaining <= 0 {
            gameSettings.timeRemaining = gameSettings.timeLimit
        }

        preciseTimeRemaining = Double(gameSettings.timeRemaining)
        gameSettings.isTimerPaused = true

        if gameTimerTask == nil {
            startGameTimer()
        }

        let now = ProcessInfo.processInfo.systemUptime
        let startAtClientUptime = startAtHostUptime - gameSettings.hostClockOffset
        let delay = max(0, startAtClientUptime - now)

        scheduledStartTask = Task { [weak self] in
            if delay > 0 {
                try? await Task.sleep(for: .seconds(delay))
            }
            guard let self, !Task.isCancelled else { return }
            self.gameSettings.multiplayerStartAtHostUptime = nil
            self.gameSettings.isTimerPaused = false
            self.lastTickUptime = ProcessInfo.processInfo.systemUptime
            if MultipeerManager.shared.role == .host {
                self.broadcastGameState()
            }
        }
    }

    // MARK: - MPC Broadcast

    func broadcastGameState() {
        guard MultipeerManager.shared.role == .host else { return }
        let now = ProcessInfo.processInfo.systemUptime
        let preciseRemaining = preciseTimeRemaining ?? Double(gameSettings.timeRemaining)
        let sync = ImposterGameStateSync(
            timeRemaining: gameSettings.timeRemaining,
            timeRemainingPrecise: preciseRemaining,
            isTimerPaused: gameSettings.isTimerPaused,
            gamePhase: gameSettings.gamePhase,
            currentPlayerIndex: gameSettings.currentPlayerIndex,
            startingPlayerName: gameSettings.startingPlayerName,
            hostUptime: now
        )

        MultipeerManager.shared.sendToAll(event: MPCEventType.imposterTimerSync, object: sync)
    }

    // MARK: - Computed Properties

    var currentPlayer: Player? {
        guard gameSettings.currentPlayerIndex < gameSettings.players.count else { return nil }
        return gameSettings.players[gameSettings.currentPlayerIndex]
    }

    var allPlayersSeenCards: Bool {
        return gameSettings.players.allSatisfy { $0.hasSeenCard }
    }

    var remainingPlayersCount: Int {
        return gameSettings.players.count - gameSettings.currentPlayerIndex - 1
    }

    // MARK: - Restart

    func restartGame() async {
        stopGameTimer()
        gameSettings.isTimerPaused = true
        gameSettings.markRoundCompleted()

        gameSettings.currentPlayerIndex = 0
        gameSettings.gamePhase = .setup
        gameSettings.timeRemaining = gameSettings.timeLimit
        gameSettings.multiplayerStartAtHostUptime = nil

        for i in gameSettings.players.indices {
            gameSettings.players[i].hasSeenCard = false
            gameSettings.players[i].isImposter = false
            gameSettings.players[i].word = ""
            gameSettings.players[i].isEliminated = false
            gameSettings.players[i].roleType = nil
        }

        HintService.shared.stopHints()

        await startGame()
    }
}
