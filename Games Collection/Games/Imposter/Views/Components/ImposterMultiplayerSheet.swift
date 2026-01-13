import SwiftUI
import MultipeerConnectivity

struct ImposterMultiplayerSheet: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var mpc = MultipeerManager.shared
    @AppStorage("myPlayerName") private var myPlayerName = ""
    
    @State private var mode: Mode = .menu
    @State private var generatedCode = ""
    @State private var inputCode = ""
    @State private var showNamePrompt = false
    @State private var pendingName = ""
    @State private var pendingAction: PendingAction?
    @State private var showExitConfirmation = false
    @State private var currentDetent: PresentationDetent = .medium
    
    // NEU: Bereit-Status
    @State private var readyPlayers: Set<String> = []

    enum Mode {
        case menu
        case enterCode
        case lobby
    }

    private enum PendingAction {
        case host
        case join
    }
    
    // MARK: - Computed Properties

    private var lobbyNames: [String] {
        // Fallback-Logik für Anzeige
        if mpc.lobbyPeers.count > 1 {
            return mpc.lobbyPeers
        }
        // Fallback falls Lobby noch leer, aber connectedPeers da sind
        var list = [mpc.myPeerId.displayName]
        list.append(contentsOf: mpc.connectedPeers.map { $0.displayName })
        return list.unique() // Extension oder Logik um Doppelte zu vermeiden
    }
    
    private var isHost: Bool {
        mpc.role == .host
    }
    
    private var isConnected: Bool {
        !mpc.connectedPeers.isEmpty || isHost
    }
    
    private var needsNamePrompt: Bool {
        myPlayerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            ImposterStyle.backgroundGradient.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                Spacer()
                
                switch mode {
                case .menu:
                    menuView
                case .enterCode:
                    enterCodeView
                case .lobby:
                    UnifiedLobbyView(
                        roomCode: isHost ? generatedCode : inputCode,
                        isHost: isHost,
                        players: lobbyNames,
                        readyPlayers: readyPlayers,
                        myPlayerName: mpc.myPeerId.displayName,
                        onStartGame: {
                            // TODO: Trigger Game Start Event via MPC
                            mpc.sendToAll(event: MPCEventType.gameStart)
                            // Dismiss sheet handled by Wrapper observing the event
                            dismiss()
                        },
                        onToggleReady: { isReady in
                            toggleReadyState(isReady: isReady)
                        }
                    )
                    .transition(.opacity)
                }
                
                Spacer()
            }
        }
        .presentationDetents([.medium, .large], selection: $currentDetent)
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(28)
        .alert("Wie heißt du?", isPresented: $showNamePrompt) {
            TextField("Dein Name", text: $pendingName)
            Button("OK") {
                confirmNameAndContinue()
            }
            Button("Abbrechen", role: .cancel) {
                pendingAction = nil
            }
        } message: {
            Text("Bitte gib deinen Namen ein, damit die anderen dich sehen.")
        }
        .confirmationDialog(
            "Lobby verlassen?",
            isPresented: $showExitConfirmation,
            titleVisibility: .visible
        ) {
            Button("Abbrechen", role: .cancel) { }
            Button("Verlassen", role: .destructive) {
                exitLobby()
            }
        } message: {
            Text("Die Verbindung wird getrennt.")
        }
        .onAppear {
            setupMPCListener()
        }
        .onChange(of: isConnected) { _, connected in
            // Wenn wir im Code-Eingabe Modus sind und die Verbindung steht -> Ab in die Lobby
            if connected && mode == .enterCode {
                withAnimation {
                    mode = .lobby
                    currentDetent = .large // Lobby braucht Platz
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    var headerView: some View {
        HStack {
            Button {
                if mode == .menu {
                    dismiss()
                } else {
                    showExitConfirmation = true
                }
            } label: {
                Image(systemName: mode == .menu ? "xmark" : "chevron.left")
                    .font(.headline.bold())
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
            }
            
            Spacer()
            
            Text(headerTitle)
                .font(.headline)
                .foregroundColor(.white)
            
            Spacer()
            
            // Placeholder for symmetry
            Color.clear.frame(width: 36, height: 36)
        }
        .padding(.horizontal)
        .padding(.top, 20)
        .padding(.bottom, 10)
    }
    
    var headerTitle: String {
        switch mode {
        case .menu: return "Multiplayer"
        case .enterCode: return "Beitreten"
        case .lobby: return isHost ? "Lobby (Host)" : "Lobby (Gast)"
        }
    }
    
    var menuView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Button {
                handleHostTap()
            } label: {
                HStack {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                    Text("Spiel hosten")
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(16)
            }
            
            Button {
                handleJoinTap()
            } label: {
                HStack {
                    Image(systemName: "person.3.fill")
                    Text("Spiel beitreten")
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(16)
            }
            
            Text("Verbinde dich mit Freunden in der Nähe (WLAN/Bluetooth).")
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
        }
        .padding(.horizontal)
    }
    
    var enterCodeView: some View {
        VStack(spacing: 20) {
            Text("Gib den Code vom Host ein")
                .font(.body)
                .foregroundColor(.white.opacity(0.8))
            
            TextField("0000", text: $inputCode)
                .font(.system(size: 50, weight: .bold, design: .monospaced))
                .multilineTextAlignment(.center)
                .keyboardType(.numberPad)
                .foregroundStyle(.white)
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(20)
                .onChange(of: inputCode) { _, newValue in
                    if newValue.count > 4 {
                        inputCode = String(newValue.prefix(4))
                    }
                }
                .frame(maxWidth: 200)
            
            Button {
                joinGame()
            } label: {
                if mpc.connectedPeers.isEmpty {
                    Text("Verbinden")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(inputCode.count == 4 ? Color.green : Color.white.opacity(0.2))
                        .foregroundColor(.white)
                        .cornerRadius(16)
                } else {
                    ProgressView()
                        .tint(.white)
                }
            }
            .disabled(inputCode.count != 4)
            .padding(.horizontal, 40)
        }
    }
    
    // MARK: - Logic
    
    private func setupMPCListener() {
        mpc.onEventReceived = { type, payload in
            if type == "PLAYER_READY_UPDATE", let data = payload {
                if let info = try? JSONDecoder().decode(ReadyStatusPayload.self, from: data) {
                    withAnimation {
                        if info.isReady {
                            readyPlayers.insert(info.playerName)
                        } else {
                            readyPlayers.remove(info.playerName)
                        }
                    }
                }
            } else if type == "LOBBY_STATE_SYNC", let data = payload {
                // Für neu beigetretene Spieler: Empfange kompletten Status
                if let list = try? JSONDecoder().decode([String].self, from: data) {
                    withAnimation {
                        readyPlayers = Set(list)
                    }
                }
            }
        }
    }
    
    private func toggleReadyState(isReady: Bool) {
        let name = mpc.myPeerId.displayName
        if isReady {
            readyPlayers.insert(name)
        } else {
            readyPlayers.remove(name)
        }
        
        // Sende Update an alle
        let payload = ReadyStatusPayload(playerName: name, isReady: isReady)
        mpc.sendToAll(event: "PLAYER_READY_UPDATE", object: payload)
        
        // Wenn ich Host bin, könnte ich hier noch eine Logik hinzufügen um Späteren Spielern den Status zu senden
    }
    
    private struct ReadyStatusPayload: Codable {
        let playerName: String
        let isReady: Bool
    }
    
    private func startHosting() {
        generatedCode = String(Int.random(in: 1000...9999))
        mode = .lobby
        currentDetent = .large
        readyPlayers.removeAll()
        mpc.startHosting(roomCode: generatedCode)
    }
    
    private func joinGame() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        mpc.joinSession(roomCode: inputCode)
        // Wir wechseln noch nicht in die Lobby, erst wenn connected ist (via onChange)
    }
    
    private func exitLobby() {
        mpc.stop()
        mode = .menu
        currentDetent = .medium
        generatedCode = ""
        inputCode = ""
        readyPlayers.removeAll()
    }

    private func handleHostTap() {
        if needsNamePrompt {
            requestName(for: .host)
            return
        }
        startHosting()
    }

    private func handleJoinTap() {
        if needsNamePrompt {
            requestName(for: .join)
            return
        }
        mode = .enterCode
    }

    private func requestName(for action: PendingAction) {
        pendingAction = action
        pendingName = ""
        showNamePrompt = true
    }

    private func confirmNameAndContinue() {
        let trimmed = pendingName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        myPlayerName = trimmed
        mpc.updatePeerName(name: trimmed)
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
}

// MARK: - Unified Lobby View
// Diese View ist nun das Herzstück für Host UND Gast
private struct UnifiedLobbyView: View {
    let roomCode: String
    let isHost: Bool
    let players: [String]
    let readyPlayers: Set<String>
    let myPlayerName: String
    let onStartGame: () -> Void
    let onToggleReady: (Bool) -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            
            // 1. Raum Code (Prominent)
            VStack(spacing: 8) {
                Text("RAUM-CODE")
                    .font(.caption.bold())
                    .foregroundStyle(.white.opacity(0.6))
                    .tracking(2)
                
                Text(roomCode)
                    .font(.system(size: 60, weight: .heavy, design: .monospaced))
                    .foregroundStyle(
                        LinearGradient(colors: [.yellow, .orange], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .shadow(color: .orange.opacity(0.5), radius: 10, x: 0, y: 0)
            }
            .padding(.vertical, 10)
            
            Divider()
                .background(Color.white.opacity(0.2))
                .padding(.horizontal, 40)
            
            // 2. Spieler Liste
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("LOBBY (\(players.count))")
                        .font(.caption.bold())
                        .foregroundStyle(.white.opacity(0.6))
                    Spacer()
                    if isHost {
                        Label("Du bist Host", systemImage: "crown.fill")
                            .font(.caption)
                            .foregroundStyle(.yellow)
                    }
                }
                .padding(.horizontal)
                
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 12)], spacing: 12) {
                        ForEach(players, id: \.self) { player in
                            LobbyPlayerCard(
                                name: player,
                                isMe: player == myPlayerName,
                                isReady: readyPlayers.contains(player)
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            }
            
            Spacer()
            
            // 3. Action Area
            VStack(spacing: 12) {
                if isHost {
                    Button(action: onStartGame) {
                        VStack(spacing: 4) {
                            Text("Spiel starten")
                                .font(.title3.bold())
                            
                            // Info für Host
                            if players.count >= 3 {
                                let readyCount = readyPlayers.count
                                Text("\(readyCount) von \(players.count) bereit")
                                    .font(.caption2)
                                    .opacity(0.8)
                            }
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(colors: [.green, .mint], startPoint: .leading, endPoint: .trailing)
                        )
                        .cornerRadius(20)
                        .shadow(color: .green.opacity(0.4), radius: 8, y: 4)
                    }
                    .disabled(players.count < 2) // Mindestspielerzahl (anpassbar)
                    .opacity(players.count < 3 ? 0.5 : 1.0)
                    
                    if players.count < 3 {
                        Text("Mindestens 3 Spieler benötigt")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                } else {
                    // Gast Ansicht
                    let amIReady = readyPlayers.contains(myPlayerName)
                    
                    Button {
                        HapticsService.impact(.medium)
                        onToggleReady(!amIReady)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: amIReady ? "checkmark.circle.fill" : "circle")
                            Text(amIReady ? "Bereit!" : "Ich bin bereit")
                        }
                        .font(.headline.bold())
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            amIReady ? Color.green : Color.white.opacity(0.15)
                        )
                        .cornerRadius(20)
                        .animation(.easeInOut, value: amIReady)
                    }
                    
                    if !amIReady {
                        Text("Warte auf Host...")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
    }
}

private struct LobbyPlayerCard: View {
    let name: String
    let isMe: Bool
    let isReady: Bool
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 8) {
                Circle()
                    .fill(isMe ? Color.blue.opacity(0.2) : Color.white.opacity(0.1))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Text(String(name.prefix(1)).uppercased())
                            .font(.title3.bold())
                            .foregroundStyle(isMe ? .blue : .white)
                    )
                
                Text(name)
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                    .lineLimit(1)
                
                if isMe {
                    Text("(Du)")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity)
            .background(Color.black.opacity(0.2))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isMe ? Color.blue.opacity(0.5) : Color.clear, lineWidth: 1)
            )
            
            // Status Icon (Ecke rechts oben)
            // Nur anzeigen, wenn Spieler NICHT der Host ist (optional), 
            // oder einfach immer Status anzeigen (besser für Klarheit)
            Image(systemName: isReady ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(isReady ? .green : .red.opacity(0.5))
                .background(Circle().fill(.white).padding(2))
                .clipShape(Circle())
                .offset(x: 5, y: -5)
                .shadow(radius: 2)
        }
        .padding(4)
    }
}

extension Array where Element: Hashable {
    func unique() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}
