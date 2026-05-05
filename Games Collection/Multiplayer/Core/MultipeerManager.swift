import Foundation
@preconcurrency import MultipeerConnectivity
import SwiftUI

// Swift 6: Wrapper für non-Sendable ObjC-Closures (z.B. MultipeerConnectivity invitation handler)
private final class UncheckedSendable<T>: @unchecked Sendable {
    nonisolated(unsafe) let value: T
    nonisolated init(_ value: T) { self.value = value }
}

// MARK: - Datenmodelle
struct MPCMessage: Codable, Sendable {
    let type: String
    let payload: Data? // JSON-kodierter Inhalt

    // Explizite Implementierung verhindert Swift 6-Fehler, bei dem die synthesized
    // Decodable-Konformanz fälschlicherweise als @MainActor-isoliert inferiert wird.
    private enum CodingKeys: CodingKey { case type, payload }

    init(type: String, payload: Data?) {
        self.type = type
        self.payload = payload
    }

    nonisolated init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(String.self, forKey: .type)
        payload = try container.decodeIfPresent(Data.self, forKey: .payload)
    }
}

/// Eingehendes MPC-Event – wird über `MultipeerManager.events` gestreamt.
struct MPCEvent: Sendable {
    let type: String
    let payload: Data?
}

enum MPCRole {
    case unknown
    case host
    case peer
}

// MARK: - Manager
@Observable
@MainActor
class MultipeerManager: NSObject {
    static let shared = MultipeerManager()

    // Konfiguration
    private let serviceType = "gc-party" // Max 15 Zeichen, keine Sonderzeichen

    let playerId: UUID
    var myPeerId: MCPeerID
    var connectedPeers: [MCPeerID] = []
    var role: MPCRole = .unknown
    var receivedMessages: [MPCMessage] = [] // Für Debugging/Log
    var lastError: String? // Fehleranzeige für UI

    // NEU: Liste aller Spieler in der Lobby (vom Host empfangen)
    var lobbyPeers: [String] = []
    var readyPlayers: Set<String> = []
    var activeRoomCode: String? = nil
    var hostActivity: String = ""
    var disconnectedPeers: Set<String> = []

    // Explizit gespeicherter Host-Name (SVC-06 Fix: nicht mehr Konvention "erster in Array")
    private(set) var hostPeerName: String? = nil
    // Host-Disconnect Alert für Clients (SVC-03 / UX-18 Fix)
    var hostDidDisconnect: Bool = false

    // NEU: Für UI-Benachrichtigungen
    var lastDisconnectedPlayerName: String? = nil
    var lastReconnectedPlayerName: String? = nil
    
    // MC Objekte
    private var session: MCSession?
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?
    
    // Aktueller Ziel-Raumcode (für Clients)
    private var targetRoomCode: String?
    private var disconnectTasks: [String: Task<Void, Never>] = [:]
    private let disconnectGraceInterval: TimeInterval = 30

    // MARK: - Event System

    /// Moderner AsyncStream – bevorzugter Weg für neue Handler.
    /// Jeder Zugriff erzeugt einen eigenen Stream, damit mehrere Listener dieselben Events erhalten.
    var events: AsyncStream<MPCEvent> {
        makeEventStream()
    }

    private var eventContinuations: [UUID: AsyncStream<MPCEvent>.Continuation] = [:]

    /// Sendet ein Event lokal an alle Subscriber (für Host-seitige Eigenverarbeitung ohne Netzwerk).
    func injectLocalEvent(type: String, payload: Data?) {
        broadcastEvent(MPCEvent(type: type, payload: payload))
    }
    
    override init() {
        let defaults = UserDefaults.standard
        if let stored = defaults.string(forKey: "mpc.playerId"),
           let uuid = UUID(uuidString: stored) {
            self.playerId = uuid
        } else {
            let uuid = UUID()
            self.playerId = uuid
            defaults.set(uuid.uuidString, forKey: "mpc.playerId")
        }

        // Name aus UserDefaults oder Gerät
        let savedName = UserDefaults.standard.string(forKey: "myPlayerName")
        let deviceName = UIDevice.current.name
        let displayName: String
        if let saved = savedName, !saved.isEmpty {
            displayName = saved
        } else {
            displayName = deviceName
        }

        self.myPeerId = MCPeerID(displayName: displayName)
        super.init()
    }
    
    func updatePeerName(name: String) {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty, cleanName != myPeerId.displayName else { return }
        
        // Vollständiger Reset nötig für neuen Namen
        stop()
        self.myPeerId = MCPeerID(displayName: cleanName)
        print("MPC: Name geändert zu \(cleanName)")
    }
    
    // MARK: - Public API
    
    func startHosting(roomCode: String) {
        stop()
        syncPeerNameFromDefaults()
        role = .host
        hostPeerName = myPeerId.displayName  // Host-Name explizit merken
        lobbyPeers = [myPeerId.displayName] // Ich bin der erste
        readyPlayers.removeAll()
        activeRoomCode = roomCode
        setupSession()
        
        // Code in Discovery Info packen
        let discoveryInfo = ["code": roomCode]
        
        advertiser = MCNearbyServiceAdvertiser(peer: myPeerId, discoveryInfo: discoveryInfo, serviceType: serviceType)
        advertiser?.delegate = self
        advertiser?.startAdvertisingPeer()
        lastError = nil
        print("MPC: Hosting gestartet als \(myPeerId.displayName) mit Code \(roomCode)")
    }
    
    var lastJoinedRoomCode: String? {
        UserDefaults.standard.string(forKey: "mpc.lastRoomCode")
    }
    
    func joinSession(roomCode: String) {
        stop()
        syncPeerNameFromDefaults()
        
        // Save Code for Rejoin Convenience
        UserDefaults.standard.set(roomCode, forKey: "mpc.lastRoomCode")
        
        role = .peer
        targetRoomCode = roomCode
        lobbyPeers = [myPeerId.displayName] // Reset Lobby
        readyPlayers.removeAll()
        activeRoomCode = roomCode
        setupSession()
        browser = MCNearbyServiceBrowser(peer: myPeerId, serviceType: serviceType)
        browser?.delegate = self
        browser?.startBrowsingForPeers()
        lastError = nil
        print("MPC: Suche nach Host mit Code \(roomCode)...")
    }
    
    func stop() {
        advertiser?.stopAdvertisingPeer()
        browser?.stopBrowsingForPeers()
        session?.disconnect()
        connectedPeers.removeAll()
        lobbyPeers.removeAll()
        readyPlayers.removeAll()
        disconnectedPeers.removeAll()
        for task in disconnectTasks.values {
            task.cancel()
        }
        disconnectTasks.removeAll()
        hostActivity = ""
        role = .unknown
        hostPeerName = nil
        hostDidDisconnect = false
        targetRoomCode = nil
        activeRoomCode = nil
    }
    
    func sendToAll(event: String, object: Codable? = nil) {
        guard let session = session, !session.connectedPeers.isEmpty else { return }
        
        do {
            var payloadData: Data? = nil
            if let object = object {
                payloadData = try JSONEncoder().encode(object)
            }
            
            let message = MPCMessage(type: event, payload: payloadData)
            let data = try JSONEncoder().encode(message)
            
            try session.send(data, toPeers: session.connectedPeers, with: .reliable)
        } catch {
            let errorMsg = "MPC Error sending: \(error.localizedDescription)"
            print(errorMsg)
            lastError = errorMsg
        }
    }

    func sendToPeer(event: String, object: Codable? = nil, to peer: MCPeerID) {
        guard let session = session else { return }
        
        do {
            var payloadData: Data? = nil
            if let object = object {
                payloadData = try JSONEncoder().encode(object)
            }
            
            let message = MPCMessage(type: event, payload: payloadData)
            let data = try JSONEncoder().encode(message)
            
            try session.send(data, toPeers: [peer], with: .reliable)
        } catch {
            let errorMsg = "MPC Error sending to \(peer.displayName): \(error.localizedDescription)"
            print(errorMsg)
            lastError = errorMsg
        }
    }
    
    func sendToHost(event: String, object: Codable? = nil) {
        guard role == .peer else { return }
        // SVC-06 Fix: hostPeerName explizit gespeichert, nicht mehr Konvention "erster in Array"
        guard let hostName = hostPeerName ?? lobbyPeers.first else { return }
        
        if let hostPeer = getPeer(byName: hostName) {
            sendToPeer(event: event, object: object, to: hostPeer)
        } else {
            // Fallback: Wenn wir nur mit einem verbunden sind, ist das wahrscheinlich der Host
            if connectedPeers.count == 1, let singleHost = connectedPeers.first {
                sendToPeer(event: event, object: object, to: singleHost)
            }
        }
    }
    
    func getPeer(byName name: String) -> MCPeerID? {
        return connectedPeers.first(where: { $0.displayName == name })
    }
    
    // NEU: Lobby Update senden (nur Host)
    private func broadcastLobbyState() {
        guard role == .host else { return }
        
        // Liste aller: Ich + Verbundenen
        var allNames = [myPeerId.displayName]
        allNames.append(contentsOf: connectedPeers.map { $0.displayName })
        if !disconnectedPeers.isEmpty {
            allNames.append(contentsOf: disconnectedPeers.filter { $0 != myPeerId.displayName })
        }
        allNames = Array(Set(allNames))
        
        // Lokal updaten
        self.lobbyPeers = allNames
        
        print("MPC Host: Sende Lobby-Update an \(connectedPeers.count) Peers: \(allNames)")
        
        // An alle senden
        sendToAll(event: MPCEventType.lobbyUpdate, object: allNames)
        sendToAll(event: MPCEventType.lobbyDisconnected, object: Array(disconnectedPeers))
    }

    private func markPeerDisconnected(_ name: String) {
        guard role == .host else { return }
        disconnectedPeers.insert(name)
        readyPlayers.remove(name)
        broadcastLobbyState()
        sendToAll(event: MPCEventType.lobbyStateSync, object: Array(readyPlayers))
        
        disconnectTasks[name]?.cancel()
        let task = Task { [weak self] in
            let seconds = self?.disconnectGraceInterval ?? 30
            try? await Task.sleep(for: .seconds(seconds))

            // Prüfen ob Task abgebrochen wurde (z.B. durch stop() oder Reconnect)
            guard !Task.isCancelled else { return }

            await MainActor.run {
                guard let self else { return }

                // Nochmal prüfen - Task könnte zwischen sleep und MainActor.run abgebrochen worden sein
                guard !Task.isCancelled else { return }

                guard self.disconnectedPeers.contains(name) else { return }
                self.disconnectedPeers.remove(name)
                self.disconnectTasks.removeValue(forKey: name)
                self.broadcastLobbyState()
            }
        }
        disconnectTasks[name] = task
    }

    private func clearPeerDisconnected(_ name: String) {
        guard role == .host else { return }
        disconnectedPeers.remove(name)
        disconnectTasks[name]?.cancel()
        disconnectTasks.removeValue(forKey: name)
        broadcastLobbyState()
    }
    
    // MARK: - Private Setup
    
    private func setupSession() {
        session = MCSession(peer: myPeerId, securityIdentity: nil, encryptionPreference: .required)
        session?.delegate = self
    }

    private func syncPeerNameFromDefaults() {
        let savedName = UserDefaults.standard.string(forKey: "myPlayerName") ?? ""
        let trimmed = savedName.trimmingCharacters(in: .whitespacesAndNewlines)
        let displayName = trimmed.isEmpty ? UIDevice.current.name : trimmed
        guard displayName != myPeerId.displayName else { return }
        myPeerId = MCPeerID(displayName: displayName)
        print("MPC: Name synchronisiert zu \(displayName)")
    }

    private func makeEventStream() -> AsyncStream<MPCEvent> {
        AsyncStream(MPCEvent.self, bufferingPolicy: .bufferingNewest(32)) { continuation in
            let id = UUID()
            eventContinuations[id] = continuation
            continuation.onTermination = { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.eventContinuations.removeValue(forKey: id)
                }
            }
        }
    }

    private func broadcastEvent(_ event: MPCEvent) {
        for continuation in eventContinuations.values {
            continuation.yield(event)
        }
    }
}

// MARK: - Delegates

extension MultipeerManager: MCSessionDelegate {
    nonisolated func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        // WICHTIG: Snapshot der Peers erstellen BEVOR wir auf MainActor wechseln
        // So vermeiden wir Race Conditions wenn sich die Liste während des Wechsels ändert
        let currentPeers = session.connectedPeers
        let peerDisplayName = peerID.displayName

        Task { @MainActor in
            self.connectedPeers = currentPeers

            switch state {
            case .connected:
                print("MPC: Verbunden mit \(peerDisplayName)")
                self.lastReconnectedPlayerName = peerDisplayName
                self.clearPeerDisconnected(peerDisplayName)
                if self.role == .host {
                    Task { @MainActor [self] in
                        try? await Task.sleep(for: .milliseconds(500))
                        self.broadcastLobbyState()
                    }
                }
            case .connecting:
                print("MPC: Verbinde mit \(peerDisplayName)...")
            case .notConnected:
                print("MPC: Getrennt von \(peerDisplayName)")
                self.lastDisconnectedPlayerName = peerDisplayName
                self.markPeerDisconnected(peerDisplayName)
                // SVC-03 / UX-18 Fix: Clients erkennen Host-Disconnect und können Alert zeigen
                if self.role == .peer, peerDisplayName == self.hostPeerName {
                    self.hostDidDisconnect = true
                }
                if self.role == .host {
                    Task { @MainActor [self] in
                        try? await Task.sleep(for: .milliseconds(500))
                        self.broadcastLobbyState()
                    }
                }
            @unknown default:
                break
            }
        }
    }
    
    nonisolated func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        // Dekodieren auf Background-Thread (entlastet MainActor)
        let message: MPCMessage
        do {
            message = try JSONDecoder().decode(MPCMessage.self, from: data)
        } catch {
            print("MPC: Fehler beim Dekodieren: \(error)")
            return
        }

        Task { @MainActor in
            // Interne Events abfangen
            if message.type == MPCEventType.lobbyUpdate, let payload = message.payload {
                if let names = try? JSONDecoder().decode([String].self, from: payload) {
                    print("MPC Gast: Lobby-Update empfangen: \(names)")
                    self.lobbyPeers = names
                    // SVC-06 Fix: Host-Name aus Lobby-Update ableiten (erster Eintrag = Host-Konvention beim Broadcast)
                    if self.role == .peer, self.hostPeerName == nil, let first = names.first {
                        self.hostPeerName = first
                    }
                    return // Nicht weiterleiten, ist intern
                }
            }
            if message.type == MPCEventType.lobbyDisconnected, let payload = message.payload {
                if let names = try? JSONDecoder().decode([String].self, from: payload) {
                    self.disconnectedPeers = Set(names)
                    return
                }
            }

            self.receivedMessages.append(message)
            if self.receivedMessages.count > 100 {
                self.receivedMessages.removeFirst(self.receivedMessages.count - 100)
            }

            self.broadcastEvent(MPCEvent(type: message.type, payload: message.payload))
        }
    }

    // Boilerplate - müssen nonisolated sein da Delegate auf Background-Thread läuft
    nonisolated func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    nonisolated func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    nonisolated func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}

extension MultipeerManager: MCNearbyServiceAdvertiserDelegate {
    nonisolated func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        print("MPC: Einladung von \(peerID.displayName) erhalten. Akzeptiere automatisch.")
        // UncheckedSendable nötig da MultipeerConnectivity-Handler nicht als @Sendable annotiert ist
        let box = UncheckedSendable(invitationHandler)
        Task { @MainActor in
            box.value(true, self.session)
        }
    }

    nonisolated func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        let errorMessage = error.localizedDescription
        print("MPC Error Advertising: \(errorMessage)")
        Task { @MainActor in
            self.lastError = "Host Error: \(errorMessage)"
        }
    }
}

extension MultipeerManager: MCNearbyServiceBrowserDelegate {
    nonisolated func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        let peerDisplayName = peerID.displayName
        let peerCode = info?["code"]

        Task { @MainActor in
            // Prüfen, ob wir einen Ziel-Code haben
            guard let targetCode = self.targetRoomCode else {
                print("MPC: Ignoriere Peer \(peerDisplayName) (kein Zielcode gesetzt)")
                return
            }

            // Prüfen, ob der Peer den richtigen Code hat
            if peerCode == targetCode {
                // Sicherstellen, dass Session noch existiert (verhindert Crash bei schnellem Stop/Start)
                guard let session = self.session else {
                    print("MPC: Keine aktive Session - Einladung abgebrochen")
                    return
                }
                print("MPC: Peer gefunden: \(peerDisplayName) mit Code \(peerCode ?? ""). Einladung senden...")
                browser.invitePeer(peerID, to: session, withContext: nil, timeout: 10)
            } else {
                print("MPC: Ignoriere Peer \(peerDisplayName) (Falscher Code: \(peerCode ?? "nil"))")
            }
        }
    }

    nonisolated func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        print("MPC: Peer verloren: \(peerID.displayName)")
    }

    nonisolated func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        let errorMessage = error.localizedDescription
        print("MPC Error Browsing: \(errorMessage)")
        Task { @MainActor in
            self.lastError = "Join Error: \(errorMessage)"
        }
    }
}
