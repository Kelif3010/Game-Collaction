//
//  QuestionsMultiplayerSheet.swift
//  Games Collection
//
//  Created by Gemini on 17.01.2026.
//

import SwiftUI
import MultipeerConnectivity

struct QuestionsMultiplayerSheet: View {
    @Environment(\.dismiss) var dismiss
    @Environment(MultipeerManager.self) private var mpc
    @State private var lobby = MultiplayerLobbyCoordinator()
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            QuestionsStyle.backgroundGradient.ignoresSafeArea()
            
            VStack(spacing: 0) {
                headerView
                
                Spacer()
                
                switch lobby.mode {
                case .menu:
                    if lobby.isConnected {
                        lobbyView
                    } else {
                        menuView
                    }
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
            Button("OK") {
                lobby.confirmNameAndContinue()
            }
            Button("Abbrechen", role: .cancel) {
                lobby.showNamePrompt = false
            }
        } message: {
            Text("Bitte gib deinen Namen ein, damit die anderen dich sehen.")
        }
        .confirmationDialog(
            "Lobby verlassen?",
            isPresented: $lobby.showExitConfirmation,
            titleVisibility: .visible
        ) {
            Button("Abbrechen", role: .cancel) { }
            Button("Verlassen", role: .destructive) {
                lobby.exitLobby()
            }
        } message: {
            Text("Die Verbindung wird getrennt.")
        }
        .onAppear {
            lobby.startListening()
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
    
    // MARK: - Subviews
    
    var headerView: some View {
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
    
    @ViewBuilder
    private var lobbyView: some View {
        QuestionsLobbyView(
            roomCode: lobby.displayRoomCode,
            isHost: lobby.isHost,
            players: lobby.lobbyNames,
            readyPlayers: lobby.readyPlayers,
            disconnectedPlayers: lobby.disconnectedPlayers,
            myPlayerName: mpc.myPeerId.displayName,
            onOpenSettings: {
                if lobby.isHost {
                    dismiss()
                }
            },
            onToggleReady: { isReady in
                lobby.toggleReadyState(isReady: isReady)
            }
        )
        .transition(.opacity)
    }
    
    var menuView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Button {
                lobby.handleHostTap()
            } label: {
                HStack {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                    Text("Spiel hosten")
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            
            Button {
                lobby.handleJoinTap()
            } label: {
                HStack {
                    Image(systemName: "person.3.fill")
                    Text("Spiel beitreten")
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
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
                    .background(Color.white.opacity(0.15))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
            
            Text("Verbinde dich mit Freunden in der Nähe (WLAN/Bluetooth).")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.6))
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
                .foregroundStyle(.white.opacity(0.8))
            
            TextField("0000", text: $lobby.inputCode)
                .font(.system(size: 50, weight: .bold, design: .monospaced))
                .multilineTextAlignment(.center)
                .keyboardType(.numberPad)
                .foregroundStyle(.white)
                .padding()
                .background(Color.white.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .onChange(of: lobby.inputCode) { _, newValue in
                    if newValue.count > 4 {
                        lobby.inputCode = String(newValue.prefix(4))
                    }
                }
                .frame(maxWidth: 200)
            
            Button {
                lobby.joinGame()
            } label: {
                if mpc.connectedPeers.isEmpty {
                    Text("Verbinden")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(lobby.inputCode.count == 4 ? Color.green : Color.white.opacity(0.2))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                } else {
                    ProgressView()
                        .tint(.white)
                }
            }
            .disabled(lobby.inputCode.count != 4)
            .padding(.horizontal, 40)
        }
    }
    
}

// MARK: - Questions Lobby View
private struct QuestionsLobbyView: View {
    let roomCode: String
    let isHost: Bool
    let players: [String]
    let readyPlayers: Set<String>
    let disconnectedPlayers: Set<String>
    let myPlayerName: String
    let onOpenSettings: () -> Void
    let onToggleReady: (Bool) -> Void
    @Environment(MultipeerManager.self) private var mpc

    private var hostActivityText: String {
        mpc.hostActivity.isEmpty ? "wartet..." : mpc.hostActivity
    }
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("RAUM-CODE")
                    .font(.caption.bold())
                    .foregroundStyle(.white.opacity(0.6))
                    .tracking(2)
                
                Text(roomCode)
                    .font(.system(size: 60, weight: .heavy, design: .monospaced))
                    .foregroundStyle(
                        LinearGradient(colors: [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .shadow(color: .red.opacity(0.5), radius: 10)
            }
            .padding(.vertical, 10)
            
            Divider().background(Color.white.opacity(0.2)).padding(.horizontal, 40)
            
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("LOBBY (\(players.count))")
                        .font(.caption.bold())
                        .foregroundStyle(.white.opacity(0.6))
                    Spacer()
                    if isHost {
                        Label("Host", systemImage: "crown.fill").font(.caption).foregroundStyle(.yellow)
                    }
                }
                .padding(.horizontal)
                
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 12)], spacing: 12) {
                        ForEach(players, id: \.self) { player in
                            QuestionsLobbyPlayerCard(
                                name: player,
                                isMe: player == myPlayerName,
                                isReady: readyPlayers.contains(player),
                                isDisconnected: disconnectedPlayers.contains(player)
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                
                if !isHost {
                    Text("Host: \(hostActivityText)")
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.7))
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(Color.white.opacity(0.08))
                        .clipShape(Capsule())
                }
            }
            
            Spacer()
            
            VStack(spacing: 12) {
                let amIReady = readyPlayers.contains(myPlayerName)
                
                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
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
                    .background(amIReady ? Color.green : Color.white.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                }
                
                if isHost {
                    Button(action: onOpenSettings) {
                        HStack(spacing: 10) {
                            Image(systemName: "slider.horizontal.3")
                            Text("Einstellungen")
                        }
                        .font(.headline.bold())
                        .foregroundStyle(.white.opacity(0.9))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.white.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                    }
                }
                
                Text("\(readyPlayers.count) von \(players.count) bereit")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
    }
}

private struct QuestionsLobbyPlayerCard: View {
    let name: String
    let isMe: Bool
    let isReady: Bool
    let isDisconnected: Bool
    
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
            }
            .padding(12)
            .frame(maxWidth: .infinity)
            .background(Color.black.opacity(0.2))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            
            let statusIcon = isDisconnected ? "wifi.slash" : (isReady ? "checkmark.circle.fill" : "xmark.circle.fill")
            let statusColor: Color = isDisconnected ? .orange : (isReady ? .green : .red.opacity(0.5))
            Image(systemName: statusIcon)
                .foregroundStyle(statusColor)
                .background(Circle().fill(.white).padding(2))
                .clipShape(Circle())
                .offset(x: 5, y: -5)
        }
        .padding(4)
        .opacity(isDisconnected ? 0.6 : 1.0)
    }
}
