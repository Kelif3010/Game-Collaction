//
//  QuestionsSetupView+MPC.swift
//  Games Collection
//
//  Created by Gemini on 17.01.2026.
//

import SwiftUI
import MultipeerConnectivity
import Foundation

extension QuestionsSetupView {
    
    // MARK: - MPC Listeners

    func setupMPCListeners(viewModel: QuestionsGameViewModel, onDismiss: @escaping () -> Void) {
        viewModel.activateMPCHandler(onDismiss: onDismiss)
    }
    
    // MARK: - Host Logic
    
    func startMPCGame(viewModel: QuestionsGameViewModel) {
        guard MultipeerManager.shared.role == .host else { return }
        // Ensure peers have the latest player IDs and settings.
        broadcastConfig(viewModel: viewModel)
        sendHostActivity("Host startet die Runde")
        // 1. Send signal to start locally and remotely
        MultipeerManager.shared.sendToAll(event: MPCEventType.gameStart)
        
        // 2. Start local round
        onStartGame()
    }
    
    func broadcastConfig(viewModel: QuestionsGameViewModel) {
        guard MultipeerManager.shared.role == .host else { return }
        let config = QuestionsConfig(
            numberOfLiars: viewModel.numberOfLiars,
            selectedCategory: viewModel.selectedCategory,
            discussionTime: viewModel.discussionTime,
            players: appModel.players
        )
        MultipeerManager.shared.sendToAll(event: MPCEventType.questionsSyncConfig, object: config)
    }

    func sendHostActivity(_ message: String) {
        guard MultipeerManager.shared.role == .host else { return }
        let payload = QuestionsHostActivityPayload(message: message)
        MultipeerManager.shared.sendToAll(event: MPCEventType.questionsHostActivity, object: payload)
    }
}
