import SwiftUI
import MultipeerConnectivity

// MARK: - FF Multiplayer Lobby Sheet
// Wird von FFSetupView geöffnet. Basiert auf ImposterMultiplayerSheet.

struct FFMultiplayerSheet: View {
    @Environment(\.dismiss) var dismiss
    @Environment(MultipeerManager.self) private var mpc

    // Callbacks vom Parent (FFSetupView)
    /// Wird aufgerufen wenn das Spiel startet (beide Seiten)
    var onGameStarted: (FFGameConfigPayload, Bool) -> Void
    /// Host ruft das auf um die Spielkonfiguration zu generieren
    var getHostConfig: (_ lobbyPlayers: [String]) -> FFGameConfigPayload

    @State private var lobby = MultiplayerLobbyCoordinator()
    @FocusState private var codeFocused: Bool
    @State private var mediumHaptic = false

    // Client: empfangene Konfiguration
    @State private var receivedConfig: FFGameConfigPayload? = nil
    @State private var gameStartReceived = false

    private var canStartGame: Bool { lobby.lobbyNames.count >= 2 }

    // MARK: - Body

    var body: some View {
        ZStack {
            FFBackground()

            VStack(spacing: 0) {
                headerView
                Spacer()

                switch lobby.mode {
                case .menu:
                    if lobby.isConnected { lobbyView } else { menuView }
                case .enterCode:
                    enterCodeView
                case .lobby:
                    lobbyView
                }

                Spacer()
            }
        }
        .presentationDetents([.medium, .large], selection: $lobby.currentDetent)
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(28)
        .interactiveDismissDisabled(!lobby.isHost && lobby.mode == .lobby)
        .alert("Wie heißt du?", isPresented: $lobby.showNamePrompt) {
            TextField("Dein Name", text: $lobby.pendingName)
                .submitLabel(.done)
                .onSubmit { lobby.confirmNameAndContinue() }
            Button("OK") { lobby.confirmNameAndContinue() }
            Button("Abbrechen", role: .cancel) { lobby.showNamePrompt = false }
        } message: {
            Text("Bitte gib deinen Namen ein, damit die anderen dich sehen.")
        }
        .confirmationDialog("Lobby verlassen?", isPresented: $lobby.showExitConfirmation, titleVisibility: .visible) {
            Button("Abbrechen", role: .cancel) { }
            Button("Verlassen", role: .destructive) { exitLobby() }
        } message: {
            Text("Die Verbindung wird getrennt.")
        }
        .sensoryFeedback(.impact(weight: .medium), trigger: mediumHaptic)
        .onAppear {
            setupMPCListener()
            lobby.handleAppear()
        }
        .onDisappear {
            lobby.stopListening()
        }
        .onChange(of: lobby.isConnected) { _, connected in
            lobby.handleConnectionChange(connected: connected)
        }
        .onChange(of: mpc.lobbyPeers) { _, newPeers in
            lobby.handleLobbyPeersChange(newPeers)
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            Button {
                lobby.handleCloseTap(dismiss: dismiss)
            } label: {
                Image(systemName: lobby.mode == .menu ? "xmark" : "chevron.left")
                    .font(.headline.bold())
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .modifier(GlassCircleButtonBackground())
            }

            Spacer()

            Text(lobby.headerTitle)
                .font(.headline)
                .foregroundStyle(.white)

            Spacer()

            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal)
        .padding(.top, 20)
        .padding(.bottom, 10)
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

            Button { lobby.handleHostTap() } label: {
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

            Button { lobby.handleJoinTap() } label: {
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
                    lobby.joinLastSession()
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

            TextField("0000", text: $lobby.inputCode)
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
                .onChange(of: lobby.inputCode) { _, v in
                    if v.count > 4 { lobby.inputCode = String(v.prefix(4)) }
                }
                .frame(maxWidth: 200)

            Button { lobby.joinGame() } label: {
                if mpc.connectedPeers.isEmpty {
                    Text("Verbinden")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(lobby.inputCode.count == 4 ? FFStyle.accentViolet : Color.white.opacity(0.12))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                } else {
                    ProgressView().tint(.white)
                }
            }
            .disabled(lobby.inputCode.count != 4)
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

                Text(lobby.displayRoomCode)
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
                    Text("LOBBY (\(lobby.lobbyNames.count))")
                        .font(.caption.bold())
                        .foregroundStyle(FFStyle.textMuted)
                    Spacer()
                    if lobby.isHost {
                        Label("Du bist Host", systemImage: "crown.fill")
                            .font(.caption)
                            .foregroundStyle(FFStyle.accentGold)
                    }
                }
                .padding(.horizontal)

                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 130), spacing: 10)], spacing: 10) {
                        ForEach(lobby.lobbyNames, id: \.self) { player in
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
                if !lobby.isHost {
                    let amIReady = mpc.readyPlayers.contains(mpc.myPeerId.displayName)
                    Button {
                        mediumHaptic.toggle()
                        lobby.toggleReadyState(isReady: !amIReady)
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
                if lobby.isHost {
                    let readyCount = mpc.readyPlayers.count
                    let total = lobby.lobbyNames.count

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
                                      : AnyShapeStyle(Color.white.opacity(0.08)))
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
        lobby.startListening(customHandler: handleMPCEvent)
    }

    private func handleMPCEvent(_ event: MPCEvent) -> Bool {
        if event.type == MPCEventType.ffGameConfig, let data = event.payload {
            // Client: Spielkonfiguration empfangen
            if let config = try? JSONDecoder().decode(FFGameConfigPayload.self, from: data) {
                receivedConfig = config
                // Falls GAME_START bereits empfangen
                if gameStartReceived { triggerClientGameStart(config: config) }
            }
            return true
        } else if event.type == MPCEventType.gameStart {
            if !lobby.isHost {
                gameStartReceived = true
                if let config = receivedConfig { triggerClientGameStart(config: config) }
                // Sonst warten auf FF_GAME_CONFIG (kommt kurz danach)
            }
            return true
        } else if event.type == MPCEventType.gameAbort {
            exitLobby()
            return true
        }

        return false
    }

    private func triggerClientGameStart(config: FFGameConfigPayload) {
        onGameStarted(config, false)
        dismiss()
    }

    private func startGame() {
        guard canStartGame else { return }
        mediumHaptic.toggle()

        let config = getHostConfig(lobby.lobbyNames)

        // Config an Clients senden (vor GAME_START, damit Clients vorbereitet sind)
        mpc.sendToAll(event: MPCEventType.ffGameConfig, object: config)

        // Spiel starten Signal
        mpc.sendToAll(event: MPCEventType.gameStart, object: ["game": "FalscheFaehrte"])

        // Callback an FFSetupView → Host startet sein Spiel
        onGameStarted(config, true)
        dismiss()
    }

    private func exitLobby() {
        lobby.exitLobby()
        receivedConfig = nil
        gameStartReceived = false
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
