//
//  ExternalDisplayManager.swift
//  Games Collection
//
//  Created by Gemini on 17.01.2026.
//

import SwiftUI
import Combine

/// Manages connections to external displays using modern UIScene APIs.
@MainActor
final class ExternalDisplayManager: ObservableObject {
    static let shared = ExternalDisplayManager()

    @Published var isExternalDisplayConnected = false
    @Published var activeQuestionsViewModel: QuestionsGameViewModel?

    private var externalWindow: UIWindow?
    private var cancellables = Set<AnyCancellable>()

    private init() {
        setupObservers()
        checkInitialConnection()
    }

    private func setupObservers() {
        // Modern UIScene based connection observer
        NotificationCenter.default.publisher(for: UIScene.willConnectNotification)
            .sink { [weak self] notification in
                guard let scene = notification.object as? UIWindowScene,
                      scene.session.role == .windowExternalDisplay else { return }
                self?.handleSceneConnect(scene)
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: UIScene.didDisconnectNotification)
            .sink { [weak self] notification in
                guard let scene = notification.object as? UIWindowScene,
                      scene.session.role == .windowExternalDisplay else { return }
                self?.handleSceneDisconnect()
            }
            .store(in: &cancellables)
    }

    private func checkInitialConnection() {
        let externalScenes = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .filter { $0.session.role == .windowExternalDisplay }

        if let firstScene = externalScenes.first {
            handleSceneConnect(firstScene)
        }
    }

    private func handleSceneConnect(_ scene: UIWindowScene) {
        print("External display connected")
        let window = UIWindow(windowScene: scene)

        let rootView = TVRootView()
            .environmentObject(self)

        window.rootViewController = UIHostingController(rootView: rootView)
        window.isHidden = false

        self.externalWindow = window
        self.isExternalDisplayConnected = true
    }

    private func handleScreenDisconnect() {
        print("External display disconnected")
        externalWindow?.isHidden = true
        externalWindow = nil
        isExternalDisplayConnected = false
    }

    // Fallback for disconnect
    private func handleSceneDisconnect() {
        handleScreenDisconnect()
    }
}
