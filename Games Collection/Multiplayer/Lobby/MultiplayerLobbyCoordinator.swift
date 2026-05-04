import Foundation
import MultipeerConnectivity
import Observation
import SwiftUI

enum MultiplayerLobbyMode {
    case menu
    case enterCode
    case lobby
}

struct ReadyStatusPayload: Codable, Sendable {
    let playerName: String
    let isReady: Bool
}

@MainActor
@Observable
final class MultiplayerLobbyCoordinator {
    var mode: MultiplayerLobbyMode = .menu
    var generatedCode = ""
    var inputCode = ""
    var showNamePrompt = false
    var pendingName = ""
    var showExitConfirmation = false
    var currentDetent: PresentationDetent = .medium

    @ObservationIgnored private let mpc: MultipeerManager
    @ObservationIgnored private var pendingAction: PendingAction?
    @ObservationIgnored private var listenerTask: Task<Void, Never>?

    init(mpc: MultipeerManager = .shared) {
        self.mpc = mpc
    }

    var lobbyNames: [String] {
        if mpc.lobbyPeers.count > 1 {
            return mpc.lobbyPeers
        }

        var list = [mpc.myPeerId.displayName]
        list.append(contentsOf: mpc.connectedPeers.map(\.displayName))
        var seen = Set<String>()
        return list.filter { seen.insert($0).inserted }
    }

    var readyPlayers: Set<String> {
        mpc.readyPlayers
    }

    var disconnectedPlayers: Set<String> {
        mpc.disconnectedPeers
    }

    var isHost: Bool {
        mpc.role == .host
    }

    var isConnected: Bool {
        !mpc.connectedPeers.isEmpty || isHost
    }

    var displayRoomCode: String {
        if isHost {
            return generatedCode.isEmpty ? (mpc.activeRoomCode ?? "") : generatedCode
        }

        return inputCode.isEmpty ? (mpc.activeRoomCode ?? "") : inputCode
    }

    var headerTitle: String {
        if mode == .menu && isConnected {
            return isHost ? "Lobby (Host)" : "Lobby (Gast)"
        }

        switch mode {
        case .menu:
            return "Multiplayer"
        case .enterCode:
            return "Beitreten"
        case .lobby:
            return isHost ? "Lobby (Host)" : "Lobby (Gast)"
        }
    }

    func handleAppear() {
        if isConnected && mode == .menu {
            if let roomCode = mpc.activeRoomCode {
                if isHost {
                    generatedCode = roomCode
                } else {
                    inputCode = roomCode
                }
            }
            enterLobby()
        }
    }

    func startListening(
        dismissEvents: Set<String> = [],
        onDismissEvent: (() -> Void)? = nil,
        customHandler: ((MPCEvent) -> Bool)? = nil
    ) {
        listenerTask?.cancel()
        listenerTask = Task { @MainActor [weak self] in
            guard let self else { return }
            for await event in self.mpc.events {
                guard !Task.isCancelled else { break }
                self.handle(
                    event,
                    dismissEvents: dismissEvents,
                    onDismissEvent: onDismissEvent,
                    customHandler: customHandler
                )
            }
        }
    }

    func stopListening() {
        listenerTask?.cancel()
        listenerTask = nil
    }

    func handleConnectionChange(connected: Bool) {
        if connected && mode == .enterCode {
            enterLobby()
        }
    }

    func handleLobbyPeersChange(_ peers: [String]) {
        syncReadyState(validPlayers: Set(peers))
    }

    func handleCloseTap(dismiss: DismissAction) {
        if mode == .menu {
            dismiss()
        } else {
            showExitConfirmation = true
        }
    }

    func handleHostTap() {
        if needsNamePrompt {
            requestName(for: .host)
            return
        }

        startHosting()
    }

    func handleJoinTap() {
        if needsNamePrompt {
            requestName(for: .join)
            return
        }

        mode = .enterCode
    }

    func confirmNameAndContinue() {
        let trimmed = pendingName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        UserDefaults.standard.set(trimmed, forKey: "myPlayerName")
        mpc.updatePeerName(name: trimmed)
        showNamePrompt = false

        let action = pendingAction
        pendingAction = nil

        switch action {
        case .host:
            startHosting()
        case .join:
            mode = .enterCode
        case .none:
            break
        }
    }

    func joinLastSession() {
        guard let lastCode = mpc.lastJoinedRoomCode else { return }
        inputCode = lastCode
        joinGame()
    }

    func startHosting() {
        generatedCode = String(Int.random(in: 1000...9999))
        enterLobby()
        mpc.readyPlayers.removeAll()
        mpc.startHosting(roomCode: generatedCode)
    }

    func joinGame() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        mpc.joinSession(roomCode: inputCode)
    }

    func exitLobby() {
        mpc.stop()
        mode = .menu
        currentDetent = .medium
        generatedCode = ""
        inputCode = ""
        mpc.readyPlayers.removeAll()
    }

    func toggleReadyState(isReady: Bool) {
        let name = mpc.myPeerId.displayName
        if isReady {
            mpc.readyPlayers.insert(name)
        } else {
            mpc.readyPlayers.remove(name)
        }

        let payload = ReadyStatusPayload(playerName: name, isReady: isReady)
        mpc.sendToAll(event: MPCEventType.playerReadyUpdate, object: payload)
    }

    private var needsNamePrompt: Bool {
        let name = UserDefaults.standard.string(forKey: "myPlayerName") ?? ""
        return name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func requestName(for action: PendingAction) {
        pendingAction = action
        pendingName = ""
        showNamePrompt = true
    }

    private func enterLobby() {
        withAnimation {
            mode = .lobby
            currentDetent = .large
        }
    }

    private func handle(
        _ event: MPCEvent,
        dismissEvents: Set<String>,
        onDismissEvent: (() -> Void)?,
        customHandler: ((MPCEvent) -> Bool)?
    ) {
        if customHandler?(event) == true {
            return
        }

        switch event.type {
        case MPCEventType.playerReadyUpdate:
            handleReadyUpdate(event.payload)
        case MPCEventType.lobbyStateSync:
            handleLobbyStateSync(event.payload)
        default:
            if dismissEvents.contains(event.type) {
                showExitConfirmation = false
                onDismissEvent?()
            }
        }
    }

    private func handleReadyUpdate(_ payload: Data?) {
        guard let payload,
              let info = try? JSONDecoder().decode(ReadyStatusPayload.self, from: payload) else { return }

        withAnimation {
            if info.isReady {
                mpc.readyPlayers.insert(info.playerName)
            } else {
                mpc.readyPlayers.remove(info.playerName)
            }
        }

        syncReadyStateIfHost()
    }

    private func handleLobbyStateSync(_ payload: Data?) {
        guard let payload,
              let list = try? JSONDecoder().decode([String].self, from: payload) else { return }

        withAnimation {
            mpc.readyPlayers = Set(list)
        }
    }

    private func syncReadyStateIfHost() {
        guard isHost else { return }
        syncReadyState(validPlayers: Set(lobbyNames))
    }

    private func syncReadyState(validPlayers: Set<String>) {
        let filteredReady = mpc.readyPlayers.intersection(validPlayers)
        if filteredReady != mpc.readyPlayers {
            mpc.readyPlayers = filteredReady
        }
        if isHost {
            mpc.sendToAll(event: MPCEventType.lobbyStateSync, object: Array(filteredReady))
        }
    }

    private enum PendingAction {
        case host
        case join
    }
}
