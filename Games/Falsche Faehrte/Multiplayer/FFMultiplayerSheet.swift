import SwiftUI
import MultipeerConnectivity

// MARK: - FF Multiplayer Lobby Sheet
// Wird von FFSetupView geöffnet. Basiert auf ImposterMultiplayerSheet.

struct FFMultiplayerSheet: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var mpc = MultipeerManager.shared
    @AppStorage("myPlayerName") private var myPlayerName = ""

    // Callbacks vom Parent (FFSetupView)
    /// Wird aufgerufen wenn das Spiel startet (beide Seiten)
    var onGameStarted: (FFGameConfigPayload, Bool) -> Void
    /// Host ruft das auf um die Spielkonfiguration zu generieren
    var getHostConfig: (_ lobbyPlayers: [String]) -> FFGameConfigPayload

    @State private var mode: Mode = .menu
    @State private var generatedCode = ""
    @State private var inputCode = ""
    @State private var showNamePrompt = false
    @State private var pendingName = ""
    @State private var pendingAction: PendingAction?
    @State private var showExitConfirmation = false
    @State private var currentDetent: PresentationDetent = .medium
    @State private var listenerTask: Task<Void, Never>?
    @FocusState private var codeFocused: Bool

    // Client: empfangene Konfiguration
    @State private var receivedConfig: FFGameConfigPayload? = nil
    @State private var gameStartReceived = false

    enum Mode { case menu, enterCode, lobby }
    private enum PendingAction { case host, join }

    // MARK: - Computed

    private var lobbyNames: [String] {
        if mpc.lobbyPeers.count > 1 { return mpc.lobbyPeers }
        var list = [mpc.myPeerId.displayName]
        list.append(contentsOf: mpc.connectedPeers.map { $0.displayName })
        return list.unique()
    }

    private var isHost: Bool { mpc.role == .host }
    private var isConnected: Bool { !mpc.connectedPeers.isEmpty || isHost }
    private var needsNamePrompt: Bool { myPlayerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    private var displayRoomCode: String {
        if isHost { return generatedCode.isEmpty ? (mpc.activeRoomCode ?? "") : generatedCode }
        return inputCode.isEmpty ? (mpc.activeRoomCode ?? "") : inputCode
    }

    private var canStartGame: Bool { lobbyNames.count >= 2 }

    // MARK: - Body

    var body: some View {
        ZStack {
            FFBackground()

            VStack(spacing: 0) {
                headerView
                Spacer()

                switch mode {
                case .menu:
                    if isConnected { lobbyView } else { menuView }
                case .enterCode:
                    enterCodeView
                case .lobby:
                    lobbyView
                }

                Spacer()
            }
        }
        .presentationDetents([.medium, .large], selection: $currentDetent)
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(28)
        .interactiveDismissDisabled(!isHost && mode == .lobby)
        .alert("Wie heißt du?", isPresented: $showNamePrompt) {
            TextField("Dein Name", text: $pendingName)
                .submitLabel(.done)
                .onSubmit { confirmNameAndContinue() }
            Button("OK") { confirmNameAndContinue() }
            Button("Abbrechen", role: .cancel) { pendingAction = nil }
        } message: {
            Text("Bitte gib deinen Namen ein, damit die anderen dich sehen.")
        }
        .confirmationDialog("Lobby verlassen?", isPresented: $showExitConfirmation, titleVisibility: .visible) {
            Button("Abbrechen", role: .cancel) { }
            Button("Verlassen", role: .destructive) { exitLobby() }
        } message: {
            Text("Die Verbindung wird getrennt.")
        }
        .onAppear {
            setupMPCListener()
            if isConnected && mode == .menu {
                if let code = mpc.activeRoomCode {
                    if isHost { generatedCode = code } else { inputCode = code }
                }
                withAnimation { mode = .lobby; currentDetent = .large }
            }
        }
        .onDisappear {
            listenerTask?.cancel()
            listenerTask = nil
        }
        .onChange(of: isConnected) { _, connected in
            if connected && mode == .enterCode {
                withAnimation { mode = .lobby; currentDetent = .large }
            }
        }
        .onChange(of: mpc.lobbyPeers) { _, newPeers in
            let valid = Set(newPeers)
            let filtered = mpc.readyPlayers.intersection(valid)
            if filtered != mpc.readyPlayers { mpc.readyPlayers = filtered }
            if isHost { mpc.sendToAll(event: MPCEventType.lobbyStateSync, object: Array(filtered)) }
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            Button {
                if mode == .menu { dismiss() } else { showExitConfirmation = true }
            } label: {
                Image(systemName: mode == .menu ? "xmark" : "chevron.left")
                    .font(.headline.bold())
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .modifier(GlassCircleButtonBackground())
            }

            Spacer()

            Text(headerTitle)
                .font(.headline)
                .foregroundStyle(.white)

            Spacer()

            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal)
        .padding(.top, 20)
        .padding(.bottom, 10)
    }

    private var headerTitle: String {
        if mode == .menu && isConnected { return isHost ? "Lobby (Host)" : "Lobby (Gast)" }
        switch mode {
        case .menu:      return "Multiplayer"
        case .enterCode: return "Beitreten"
        case .lobby:     return isHost ? "Lobby (Host)" : "Lobby (Gast)"
        }
    }

    // MARK: - Menu View

    private var menuView: some View {
        VStack(spacing: 16) {
            Spacer()

            // Spielregeln für Multiplayer
            HStack(spacing: 10) {
                Image(systemName: "info.circle")
                    .font(.system(size: 13))
                    .foregroundStyle(FFStyle.accentViolet)
                Text("Jeder spielt auf seinem eigenen Gerät – keine Pass-the-Phone-Momente!")
                    .font(.system(size: 13))
                    .foregroundStyle(FFStyle.textMuted)
                    .lineSpacing(2)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(FFStyle.accentViolet.opacity(0.08))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(FFStyle.accentViolet.opacity(0.2), lineWidth: 1))
            )
            .padding(.horizontal)

            Button { handleHostTap() } label: {
                HStack {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                    Text("Spiel hosten")
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(FFStyle.accentViolet)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }

            Button { handleJoinTap() } label: {
                HStack {
                    Image(systemName: "person.3.fill")
                    Text("Spiel beitreten")
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.white.opacity(0.12))
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.15), lineWidth: 1))
            }

            if let lastCode = mpc.lastJoinedRoomCode {
                Button {
                    inputCode = lastCode
                    joinGame()
                } label: {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Letzte Sitzung (\(lastCode))")
                    }
                    .font(.subheadline.bold())
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white.opacity(0.08))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }

            Text("Verbinde dich mit Freunden in der Nähe (WLAN / Bluetooth).")
                .font(.caption)
                .foregroundStyle(FFStyle.textSubtle)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Spacer()
        }
        .padding(.horizontal)
    }

    // MARK: - Code-Eingabe

    private var enterCodeView: some View {
        VStack(spacing: 20) {
            Text("Gib den Code vom Host ein")
                .font(.body)
                .foregroundStyle(FFStyle.textMuted)

            TextField("0000", text: $inputCode)
                .font(.system(size: 50, weight: .bold, design: .monospaced))
                .multilineTextAlignment(.center)
                .keyboardType(.numberPad)
                .foregroundStyle(.white)
                .focused($codeFocused)
                .submitLabel(.done)
                .onSubmit {
                    codeFocused = false
                }
                .padding()
                .background(Color.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(FFStyle.accentViolet.opacity(0.4), lineWidth: 1.5))
                .onChange(of: inputCode) { _, v in
                    if v.count > 4 { inputCode = String(v.prefix(4)) }
                }
                .frame(maxWidth: 200)

            Button { joinGame() } label: {
                if mpc.connectedPeers.isEmpty {
                    Text("Verbinden")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(inputCode.count == 4 ? FFStyle.accentViolet : Color.white.opacity(0.12))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                } else {
                    ProgressView().tint(.white)
                }
            }
            .disabled(inputCode.count != 4)
            .padding(.horizontal, 40)
        }
    }

    // MARK: - Lobby View

    private var lobbyView: some View {
        VStack(spacing: 24) {

            // Raum-Code
            VStack(spacing: 8) {
                Text("RAUM-CODE")
                    .font(.caption.bold())
                    .foregroundStyle(FFStyle.textMuted)
                    .tracking(2)

                Text(displayRoomCode)
                    .font(.system(size: 60, weight: .heavy, design: .monospaced))
                    .foregroundStyle(
                        LinearGradient(colors: [FFStyle.accentViolet, FFStyle.accentIndigo], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .shadow(color: FFStyle.accentViolet.opacity(0.5), radius: 10)
            }
            .padding(.vertical, 8)

            Divider().background(Color.white.opacity(0.15)).padding(.horizontal, 40)

            // Spieler-Liste
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("LOBBY (\(lobbyNames.count))")
                        .font(.caption.bold())
                        .foregroundStyle(FFStyle.textMuted)
                    Spacer()
                    if isHost {
                        Label("Du bist Host", systemImage: "crown.fill")
                            .font(.caption)
                            .foregroundStyle(FFStyle.accentGold)
                    }
                }
                .padding(.horizontal)

                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 130), spacing: 10)], spacing: 10) {
                        ForEach(lobbyNames, id: \.self) { player in
                            FFLobbyPlayerCard(
                                name: player,
                                isMe: player == mpc.myPeerId.displayName,
                                isReady: mpc.readyPlayers.contains(player),
                                isDisconnected: mpc.disconnectedPeers.contains(player)
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(maxHeight: 180)
            }

            Spacer()

            // Aktions-Bereich
            VStack(spacing: 12) {
                // Ready-Toggle für Gäste
                if !isHost {
                    let amIReady = mpc.readyPlayers.contains(mpc.myPeerId.displayName)
                    Button {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        toggleReadyState(isReady: !amIReady)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: amIReady ? "checkmark.circle.fill" : "circle")
                            Text(amIReady ? "Bereit!" : "Ich bin bereit")
                        }
                        .font(.headline.bold())
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(amIReady ? Color.green : Color.white.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .animation(.easeInOut, value: amIReady)
                    }

                    if amIReady {
                        Text("Warte auf den Host...")
                            .font(.caption)
                            .foregroundStyle(FFStyle.textSubtle)
                    }
                }

                // Spiel-Starten (nur Host)
                if isHost {
                    let readyCount = mpc.readyPlayers.count
                    let total = lobbyNames.count

                    Button { startGame() } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 15, weight: .bold))
                            Text(canStartGame ? "Spiel starten" : "Mindestens 2 Spieler")
                                .font(.headline.bold())
                        }
                        .foregroundStyle(canStartGame ? .black : .white.opacity(0.4))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            Capsule()
                                .fill(canStartGame
                                      ? AnyShapeStyle(FFStyle.primaryGradient)
                                      : AnyShapeStyle(LinearGradient(colors: [Color.white.opacity(0.08)], startPoint: .leading, endPoint: .trailing)))
                                .shadow(color: canStartGame ? FFStyle.accentViolet.opacity(0.4) : .clear, radius: 12, y: 4)
                        )
                    }
                    .disabled(!canStartGame)

                    Text("\(readyCount) von \(total) bereit")
                        .font(.caption)
                        .foregroundStyle(FFStyle.textSubtle)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
    }

    // MARK: - Logik

    private func setupMPCListener() {
        listenerTask?.cancel()
        listenerTask = Task { @MainActor in
            for await event in mpc.events {
                guard !Task.isCancelled else { break }
                handleMPCEvent(event)
            }
        }
    }

    private func handleMPCEvent(_ event: MPCEvent) {
        if event.type == MPCEventType.playerReadyUpdate, let data = event.payload {
            if let info = try? JSONDecoder().decode(ReadyStatusPayload.self, from: data) {
                withAnimation {
                    if info.isReady { mpc.readyPlayers.insert(info.playerName) }
                    else { mpc.readyPlayers.remove(info.playerName) }
                }
                if isHost { syncReadyState() }
            }
        } else if event.type == MPCEventType.lobbyStateSync, let data = event.payload {
            if let list = try? JSONDecoder().decode([String].self, from: data) {
                withAnimation { mpc.readyPlayers = Set(list) }
            }
        } else if event.type == MPCEventType.ffGameConfig, let data = event.payload {
            // Client: Spielkonfiguration empfangen
            if let config = try? JSONDecoder().decode(FFGameConfigPayload.self, from: data) {
                receivedConfig = config
                // Falls GAME_START bereits empfangen
                if gameStartReceived { triggerClientGameStart(config: config) }
            }
        } else if event.type == MPCEventType.gameStart {
            if !isHost {
                gameStartReceived = true
                if let config = receivedConfig { triggerClientGameStart(config: config) }
                // Sonst warten auf FF_GAME_CONFIG (kommt kurz danach)
            }
        } else if event.type == MPCEventType.gameAbort {
            exitLobby()
        }
    }

    private func triggerClientGameStart(config: FFGameConfigPayload) {
        onGameStarted(config, false)
        dismiss()
    }

    private func startGame() {
        guard canStartGame else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        let config = getHostConfig(lobbyNames)

        // Config an Clients senden (vor GAME_START, damit Clients vorbereitet sind)
        mpc.sendToAll(event: MPCEventType.ffGameConfig, object: config)

        // Spiel starten Signal
        mpc.sendToAll(event: MPCEventType.gameStart, object: ["game": "FalscheFaehrte"])

        // Callback an FFSetupView → Host startet sein Spiel
        onGameStarted(config, true)
        dismiss()
    }

    private func toggleReadyState(isReady: Bool) {
        let name = mpc.myPeerId.displayName
        if isReady { mpc.readyPlayers.insert(name) }
        else { mpc.readyPlayers.remove(name) }

        let payload = ReadyStatusPayload(playerName: name, isReady: isReady)
        mpc.sendToAll(event: MPCEventType.playerReadyUpdate, object: payload)
    }

    private func syncReadyState() {
        let valid = Set(lobbyNames)
        let filtered = mpc.readyPlayers.intersection(valid)
        if filtered != mpc.readyPlayers { mpc.readyPlayers = filtered }
        mpc.sendToAll(event: MPCEventType.lobbyStateSync, object: Array(filtered))
    }

    private func startHosting() {
        generatedCode = String(Int.random(in: 1000...9999))
        mode = .lobby
        currentDetent = .large
        mpc.readyPlayers.removeAll()
        mpc.startHosting(roomCode: generatedCode)
    }

    private func joinGame() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        mpc.joinSession(roomCode: inputCode)
    }

    private func exitLobby() {
        mpc.stop()
        mode = .menu
        currentDetent = .medium
        generatedCode = ""
        inputCode = ""
        mpc.readyPlayers.removeAll()
        receivedConfig = nil
        gameStartReceived = false
    }

    private func handleHostTap() {
        if needsNamePrompt { requestName(for: .host); return }
        startHosting()
    }

    private func handleJoinTap() {
        if needsNamePrompt { requestName(for: .join); return }
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
        showNamePrompt = false
        let action = pendingAction
        pendingAction = nil
        switch action {
        case .host:  startHosting()
        case .join:  mode = .enterCode
        case .none:  break
        }
    }

    private struct ReadyStatusPayload: Codable {
        let playerName: String
        let isReady: Bool
    }
}

// MARK: - Lobby-Spielerkarte (FF-Stil)

private struct FFLobbyPlayerCard: View {
    let name: String
    let isMe: Bool
    let isReady: Bool
    let isDisconnected: Bool

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 8) {
                Circle()
                    .fill(isMe ? FFStyle.accentViolet.opacity(0.2) : Color.white.opacity(0.08))
                    .frame(width: 46, height: 46)
                    .overlay(
                        Text(String(name.prefix(1)).uppercased())
                            .font(.system(size: 18, weight: .black, design: .rounded))
                            .foregroundStyle(isMe ? FFStyle.accentViolet : .white)
                    )

                Text(name)
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                    .lineLimit(1)

                if isMe {
                    Text("(Du)").font(.caption2).foregroundStyle(FFStyle.textSubtle)
                }
            }
            .padding(10)
            .frame(maxWidth: .infinity)
            .background(Color.black.opacity(0.25))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isMe ? FFStyle.accentViolet.opacity(0.5) : Color.clear, lineWidth: 1)
            )

            let icon = isDisconnected ? "wifi.slash" : (isReady ? "checkmark.circle.fill" : "xmark.circle.fill")
            let color: Color = isDisconnected ? .orange : (isReady ? .green : .red.opacity(0.5))
            Image(systemName: icon)
                .foregroundStyle(color)
                .background(Circle().fill(.white).padding(2))
                .clipShape(Circle())
                .offset(x: 4, y: -4)
                .shadow(radius: 2)
        }
        .padding(3)
        .opacity(isDisconnected ? 0.6 : 1.0)
    }
}
