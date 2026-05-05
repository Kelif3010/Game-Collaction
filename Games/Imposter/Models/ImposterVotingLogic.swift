//
//  ImposterVotingLogic.swift
//  Imposter
//

import Foundation
import Algorithms
import OrderedCollections

extension GameLogic {

    // MARK: - Multiplayer Voting

    func startMultiplayerVoting() {
        guard MultipeerManager.shared.role == .host else { return }
        gameSettings.multiplayerVotes.removeAll()
        gameSettings.multiplayerVotingSelection = nil
        gameSettings.multiplayerVotingResult = nil
        multiplayerVotePreview.removeAll()
        gameSettings.isTimerPaused = true
        broadcastGameState()

        let eligibleVoters = gameSettings.players.filter { !$0.isEliminated }
        let tally = initialVotingTally(eligibleVoters: eligibleVoters.map { $0.name })
        let status = ImposterVotingStatusPayload(
            votesReceived: 0,
            totalVoters: eligibleVoters.count,
            tally: tally
        )
        gameSettings.multiplayerVotingProgress = status
        gameSettings.multiplayerVoteTally = tally
        gameSettings.shouldPresentVoting = true

        MultipeerManager.shared.sendToAll(event: MPCEventType.imposterStartVoting, object: status)
    }

    func handleMultiplayerVotePreview(_ preview: ImposterVotePreviewPayload) {
        guard MultipeerManager.shared.role == .host else { return }
        let eligibleVoters = gameSettings.players.filter { !$0.isEliminated }.map { $0.name }
        let eligibleSet = Set(eligibleVoters)
        guard eligibleSet.contains(preview.voterName) else { return }

        if let selectedName = preview.selectedName, eligibleSet.contains(selectedName) {
            multiplayerVotePreview[preview.voterName] = selectedName
        } else {
            multiplayerVotePreview.removeValue(forKey: preview.voterName)
        }

        updateVotingStatus(eligibleVoters: eligibleVoters)
    }

    func handleMultiplayerVoteCast(_ vote: ImposterVoteCastPayload) {
        guard MultipeerManager.shared.role == .host else { return }
        let eligibleVoters = gameSettings.players.filter { !$0.isEliminated }.map { $0.name }
        guard eligibleVoters.contains(vote.voterName) else { return }

        let eligibleTargets = Set(eligibleVoters)
        guard let selectedTarget = vote.votedFor.first(where: { eligibleTargets.contains($0) }) else { return }

        gameSettings.multiplayerVotes[vote.voterName] = [selectedTarget]
        multiplayerVotePreview[vote.voterName] = selectedTarget

        updateVotingStatus(eligibleVoters: eligibleVoters)

        if gameSettings.multiplayerVotes.count >= eligibleVoters.count {
            finalizeMultiplayerVoting(eligibleVoters: eligibleVoters)
        }
    }

    private func finalizeMultiplayerVoting(eligibleVoters: [String]) {
        guard !eligibleVoters.isEmpty else { return }
        let remainingSpies = gameSettings.players
            .filter { ($0.isImposter || $0.roleType?.team == .imposter) && !$0.isEliminated }
            .count
        let selectionCount = min(max(1, remainingSpies), eligibleVoters.count)

        var voteCounts: [String: Int] = [:]
        for name in eligibleVoters {
            voteCounts[name] = 0
        }
        for votes in gameSettings.multiplayerVotes.values {
            for name in votes {
                voteCounts[name, default: 0] += 1
            }
        }

        let selectedNames = selectCandidates(from: voteCounts, requiredCount: selectionCount)
        gameSettings.multiplayerVotingSelection = selectedNames

        gameSettings.multiplayerVotes.removeAll()
        multiplayerVotePreview.removeAll()
    }

    private func updateVotingStatus(eligibleVoters: [String]) {
        let totalVoters = eligibleVoters.count
        let votesReceived = min(gameSettings.multiplayerVotes.count, totalVoters)
        let tally = computeVotingTally(eligibleVoters: eligibleVoters)
        let status = ImposterVotingStatusPayload(
            votesReceived: votesReceived,
            totalVoters: totalVoters,
            tally: tally
        )
        gameSettings.multiplayerVotingProgress = status
        gameSettings.multiplayerVoteTally = tally
        MultipeerManager.shared.sendToAll(event: MPCEventType.imposterVotingStatus, object: status)
    }

    private func computeVotingTally(eligibleVoters: [String]) -> [String: Int] {
        let eligibleSet = Set(eligibleVoters)
        var tally: [String: Int] = [:]
        for name in eligibleVoters {
            tally[name] = 0
        }

        var mergedSelections = multiplayerVotePreview
        for (voter, votes) in gameSettings.multiplayerVotes {
            if let selected = votes.first {
                mergedSelections[voter] = selected
            }
        }

        for (voter, selected) in mergedSelections {
            guard eligibleSet.contains(voter), eligibleSet.contains(selected) else { continue }
            tally[selected, default: 0] += 1
        }

        return tally
    }

    private func initialVotingTally(eligibleVoters: [String]) -> [String: Int] {
        var tally: [String: Int] = [:]
        for name in eligibleVoters {
            tally[name] = 0
        }
        return tally
    }

    private func selectCandidates(from voteCounts: [String: Int], requiredCount: Int) -> [String] {
        guard requiredCount > 0 else { return [] }
        var selected: [String] = []
        let sorted = voteCounts.sorted { $0.value > $1.value }
        for chunk in sorted.chunked(by: { $0.value == $1.value }) {
            for name in chunk.map(\.key).shuffled() where selected.count < requiredCount {
                selected.append(name)
            }
            if selected.count >= requiredCount { break }
        }
        return selected
    }
}
