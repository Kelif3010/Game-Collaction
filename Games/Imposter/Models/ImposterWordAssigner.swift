//
//  ImposterWordAssigner.swift
//  Imposter
//

import Foundation
import Algorithms

extension GameLogic {

    // MARK: - Role Distribution

    func distributeRoles(playersCount: Int) {
        let playerIds = gameSettings.players.map { $0.id }
        let imposters = selectRandomImposters()

        for i in gameSettings.players.indices {
            if imposters.contains(gameSettings.players[i].id) {
                gameSettings.players[i].isImposter = true
            }
        }

        // Pool of citizen IDs available for special role assignment
        var availableIds = playerIds.filter { !imposters.contains($0) }

        let activeRoles = gameSettings.activeRoles.shuffled()

        for role in activeRoles {
            if !canAssignRole(role, availableCount: availableIds.count, totalPlayers: playersCount) {
                continue
            }

            if role == .twins {
                guard availableIds.count >= 2 else { continue }
                // Pick exactly 2 candidates with randomSample – no repetition guaranteed
                let twins = availableIds.randomSample(count: 2)
                twins.forEach { assignRole(role, to: $0) }
                availableIds.removeAll { twins.contains($0) }
            } else {
                guard let picked = availableIds.randomSample(count: 1).first else { break }
                assignRole(role, to: picked)
                availableIds.removeAll { $0 == picked }
            }
        }
    }

    private func assignRole(_ role: RoleType, to playerId: UUID) {
        if let index = gameSettings.players.firstIndex(where: { $0.id == playerId }) {
            gameSettings.players[index].roleType = role
        }
    }

    private func canAssignRole(_ role: RoleType, availableCount: Int, totalPlayers: Int) -> Bool {
        if availableCount <= 0 { return false }

        switch role {
        case .twins:
            return availableCount >= 2
        case .secretAgent:
            return totalPlayers >= 5
        case .saboteur, .mole:
            let currentEvil = gameSettings.players.filter { $0.isImposter || $0.roleType?.team == .imposter }.count
            return Double(currentEvil + 1) <= Double(totalPlayers) / 2.5
        default:
            return true
        }
    }

    // MARK: - Word Assignment

    @MainActor
    func assignWordsToPlayers(gameWords: GameWords) async {
        guard let roundCategory = gameSettings.roundCategory else { return }
        let allPlayers = gameSettings.players

        for i in gameSettings.players.indices {
            let player = gameSettings.players[i]
            let text: String

            if player.isImposter {
                if gameSettings.showSpyHints {
                    let otherSpies = gameSettings.players
                        .filter { $0.isImposter && $0.id != player.id }
                        .map { $0.name }

                    text = await HintsManager.createSpyCardTextWithAI(
                        word: gameWords.primary,
                        categoryName: roundCategory.name,
                        category: roundCategory,
                        categoryEmoji: roundCategory.emoji,
                        showCategory: gameSettings.shouldSpySeeCategory,
                        showHints: true,
                        otherSpyNames: gameSettings.shouldSpiesSeeEachOther ? otherSpies : []
                    )
                } else {
                    let otherSpies = gameSettings.players
                        .filter { $0.isImposter && $0.id != player.id }
                        .map { $0.name }

                    text = HintsManager.createSpyCardText(
                        word: gameWords.primary,
                        categoryName: roundCategory.name,
                        categoryEmoji: roundCategory.emoji,
                        showCategory: gameSettings.shouldSpySeeCategory,
                        showHints: false,
                        otherSpyNames: gameSettings.shouldSpiesSeeEachOther ? otherSpies : []
                    )
                }
            } else if let role = player.roleType {
                text = HintsManager.createRoleCardText(
                    role: role,
                    word: gameWords.primary,
                    category: roundCategory,
                    allPlayers: allPlayers,
                    currentPlayer: player
                )
            } else {
                text = gameWords.primary
            }

            gameSettings.players[i].word = text
            gameSettings.players[i].hasSeenCard = false
        }
    }

    // MARK: - Word Selection

    func selectWordsForGameMode(from category: Category) -> GameWords? {
        guard !category.words.isEmpty else { return nil }
        switch gameSettings.gameMode {
        case .classic:
            guard let word = category.words.randomElement() else { return nil }
            return GameWords(primary: word, secondary: nil)

        case .twoWords:
            let shuffledWords = category.words.shuffled()
            let primary = shuffledWords[0]
            let secondary = shuffledWords.count > 1 ? shuffledWords[1] : primary
            return GameWords(primary: primary, secondary: secondary)

        case .roles:
            guard let word = category.words.randomElement() else { return nil }
            return GameWords(primary: word, secondary: nil)

        case .questions:
            guard let word = category.words.randomElement() else { return nil }
            return GameWords(primary: word, secondary: nil)
        }
    }

    // MARK: - Imposter Selection

    func maxAllowedImposters(for playersCount: Int) -> Int {
        if playersCount <= 1 { return 0 }
        if playersCount == 4 { return 1 }
        let cap = max(1, playersCount / 2)
        return min(cap, playersCount - 1)
    }

    private func selectRandomImposters() -> Set<UUID> {
        let players = gameSettings.players
        let playerIds = players.map { $0.id }

        if gameSettings.randomSpyCount {
            let capForUI = maxAllowedImposters(for: players.count)
            if gameSettings.numberOfImposters > capForUI {
                gameSettings.numberOfImposters = capForUI
            }
        }

        let cap = maxAllowedImposters(for: players.count)
        let imposterCount: Int
        if gameSettings.randomSpyCount && players.count >= 5 {
            let upperBound = max(1, cap)
            imposterCount = Int.random(in: 1...upperBound)
            gameSettings.numberOfImposters = imposterCount
        } else {
            let requested = max(1, gameSettings.numberOfImposters)
            imposterCount = min(requested, cap)
        }

        if imposterCount <= 0 || players.isEmpty {
            return []
        }

        var rng: any RandomNumberGeneratorLike = SystemRNGAdapter()
        let multipliers = AITuner.shared.suggestWeightMultipliers(
            players: playerIds,
            policy: gameSettings.fairnessPolicy,
            state: gameSettings.fairnessState
        )

        ModeratorLog.shared.logDebug(
            AIService.shared.isAvailable ? "Spion-Verteilung: KI verfügbar" : "Spion-Verteilung: Fallback aktiv",
            metadata: [
                "players": String(gameSettings.players.count),
                "requestedImposters": String(gameSettings.numberOfImposters)
            ]
        )

        let picked = ImposterPicker.pickImposters(
            players: playerIds,
            count: imposterCount,
            policy: gameSettings.fairnessPolicy,
            state: gameSettings.fairnessState,
            rng: &rng,
            weightMultipliers: multipliers
        )

        let round = gameSettings.fairnessState.currentRound
        let pickedSet = Set(picked)

        gameSettings.fairnessState.recordImposters(picked)

        for id in picked {
            gameSettings.fairnessState.updateStats(for: id) { s in
                s.cooldownUntilRound = round + gameSettings.fairnessPolicy.minCooldownRounds
            }
        }

        for id in playerIds where !pickedSet.contains(id) {
            gameSettings.fairnessState.updateStats(for: id) { s in
                if s.currentStreak > 0 { s.currentStreak = 0 }
            }
        }

        return Set(picked)
    }
}
