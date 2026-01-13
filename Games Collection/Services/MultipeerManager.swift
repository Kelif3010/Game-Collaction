import Foundation
import MultipeerConnectivity
import SwiftUI
import Combine

// MARK: - Datenmodelle
struct MPCMessage: Codable {
    let type: String
    let payload: Data? // JSON-kodierter Inhalt
}

enum MPCRole {
    case unknown
    case host
    case peer
}

// MARK: - Manager
@MainActor
class MultipeerManager: NSObject, ObservableObject {
    static let shared = MultipeerManager()
    
    // Konfiguration
    private let serviceType = "gc-party" // Max 15 Zeichen, keine Sonderzeichen
    
    @Published var myPeerId: MCPeerID
    @Published var connectedPeers: [MCPeerID] = []
    @Published var role: MPCRole = .unknown
    @Published var receivedMessages: [MPCMessage] = [] // Für Debugging/Log
    @Published var lastError: String? // Fehleranzeige für UI
    
    // NEU: Liste aller Spieler in der Lobby (vom Host empfangen)
    @Published var lobbyPeers: [String] = [] 
    
    // MC Objekte
    private var session: MCSession?
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?
    
    // Aktueller Ziel-Raumcode (für Clients)
    private var targetRoomCode: String?
    
    // Publishers für spezifische Events (damit ViewModels lauschen können)
    // Key: EventType (String), Value: Payload (Data)
    var onEventReceived: ((String, Data?) -> Void)?
    
    override init() {
        // Name aus UserDefaults oder Gerät
        let savedName = UserDefaults.standard.string(forKey: "myPlayerName")
        let deviceName = UIDevice.current.name
        let displayName = (savedName?.isEmpty == false) ? savedName! : deviceName
        
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
        lobbyPeers = [myPeerId.displayName] // Ich bin der erste
        setupSession()
        
        // Code in Discovery Info packen
        let discoveryInfo = ["code": roomCode]
        
        advertiser = MCNearbyServiceAdvertiser(peer: myPeerId, discoveryInfo: discoveryInfo, serviceType: serviceType)
        advertiser?.delegate = self
        advertiser?.startAdvertisingPeer()
        lastError = nil
        print("MPC: Hosting gestartet als \(myPeerId.displayName) mit Code \(roomCode)")
    }
    
    func joinSession(roomCode: String) {
        stop()
        syncPeerNameFromDefaults()
        role = .peer
        targetRoomCode = roomCode
        lobbyPeers = [myPeerId.displayName] // Reset Lobby
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
        role = .unknown
        targetRoomCode = nil
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
            print("MPC Error sending: \(error.localizedDescription)")
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
            print("MPC Error sending to \(peer.displayName): \(error.localizedDescription)")
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
        
        // Lokal updaten
        self.lobbyPeers = allNames
        
        print("MPC Host: Sende Lobby-Update an \(connectedPeers.count) Peers: \(allNames)")
        
        // An alle senden
        sendToAll(event: "LOBBY_UPDATE", object: allNames)
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
}

// MARK: - Delegates

extension MultipeerManager: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            self.connectedPeers = session.connectedPeers
            
            // Wenn Host: Lobby updaten und verteilen (mit kurzer Verzögerung für Stabilität)
            if self.role == .host {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.broadcastLobbyState()
                }
            }
            
            switch state {
            case .connected: print("MPC: Verbunden mit \(peerID.displayName)")
            case .connecting: print("MPC: Verbinde mit \(peerID.displayName)...")
            case .notConnected: print("MPC: Getrennt von \(peerID.displayName)")
            @unknown default: break
            }
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        do {
            let message = try JSONDecoder().decode(MPCMessage.self, from: data)
            DispatchQueue.main.async {
                // Interne Events abfangen
                if message.type == "LOBBY_UPDATE", let payload = message.payload {
                    if let names = try? JSONDecoder().decode([String].self, from: payload) {
                        print("MPC Gast: Lobby-Update empfangen: \(names)")
                        self.lobbyPeers = names
                        return // Nicht weiterleiten, ist intern
                    }
                }
                
                self.receivedMessages.append(message)
                // Event weiterleiten
                self.onEventReceived?(message.type, message.payload)
            }
        } catch {
            print("MPC: Fehler beim Dekodieren: \(error)")
        }
    }
    
    // Boilerplate
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}

extension MultipeerManager: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        print("MPC: Einladung von \(peerID.displayName) erhalten. Akzeptiere automatisch.")
        invitationHandler(true, self.session)
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        print("MPC Error Advertising: \(error.localizedDescription)")
        DispatchQueue.main.async { self.lastError = "Host Error: \(error.localizedDescription)" }
    }
}

extension MultipeerManager: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        // Prüfen, ob wir einen Ziel-Code haben
        guard let targetCode = self.targetRoomCode else {
            print("MPC: Ignoriere Peer \(peerID.displayName) (kein Zielcode gesetzt)")
            return
        }
        
        // Prüfen, ob der Peer den richtigen Code hat
        if let peerCode = info?["code"], peerCode == targetCode {
            print("MPC: Peer gefunden: \(peerID.displayName) mit Code \(peerCode). Einladung senden...")
            browser.invitePeer(peerID, to: self.session!, withContext: nil, timeout: 10)
        } else {
            print("MPC: Ignoriere Peer \(peerID.displayName) (Falscher Code: \(info?["code"] ?? "nil"))")
        }
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        print("MPC: Peer verloren: \(peerID.displayName)")
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        print("MPC Error Browsing: \(error.localizedDescription)")
        DispatchQueue.main.async { self.lastError = "Join Error: \(error.localizedDescription)" }
    }
}
