import SwiftUI
import MultipeerConnectivity

struct MPCDebugView: View {
    @Environment(MultipeerManager.self) private var mpc
    @Environment(\.dismiss) var dismiss
    
    @State private var messageText = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Status Header
                VStack {
                    Text(mpc.role == .unknown ? "Modus wählen" : (mpc.role == .host ? "Host (Spielleiter)" : "Client (Spieler)"))
                        .font(.headline)
                        .foregroundStyle(statusColor)
                    
                    Text("Mein Name: \(mpc.myPeerId.displayName)")
                        .font(.caption)
                        .foregroundStyle(.gray)
                    
                    if let error = mpc.lastError {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .padding(.top, 4)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.white.opacity(0.1))
                
                // Connection Controls
                if mpc.role == .unknown {
                    HStack(spacing: 20) {
                        Button {
                            mpc.startHosting(roomCode: "TEST")
                        } label: {
                            VStack {
                                Image(systemName: "antenna.radiowaves.left.and.right")
                                    .font(.largeTitle)
                                Text("Hosten")
                            }
                            .frame(width: 120, height: 100)
                            .background(Color.blue)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        
                        Button {
                            mpc.joinSession(roomCode: "TEST")
                        } label: {
                            VStack {
                                Image(systemName: "magnifyingglass")
                                    .font(.largeTitle)
                                Text("Beitreten")
                            }
                            .frame(width: 120, height: 100)
                            .background(Color.green)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                    }
                } else {
                    Button("Verbindung trennen") {
                        mpc.stop()
                    }
                    .foregroundStyle(.red)
                }
                
                Divider()
                
                // Peer List
                List {
                    Section("Verbundene Geräte") {
                        if mpc.connectedPeers.isEmpty {
                            Text("Suche...")
                                .foregroundStyle(.gray)
                                .italic()
                        }
                        ForEach(mpc.connectedPeers, id: \.self) { peer in
                            HStack {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 10, height: 10)
                                Text(peer.displayName)
                            }
                        }
                    }
                    
                    Section("Log (Nachrichten)") {
                        ForEach(mpc.receivedMessages.reversed(), id: \.type) { msg in
                            VStack(alignment: .leading) {
                                Text(msg.type).font(.caption.bold())
                                if let data = msg.payload, let str = String(data: data, encoding: .utf8) {
                                    Text(str).font(.caption)
                                }
                            }
                        }
                    }
                }
                
                // Test Sender
                if !mpc.connectedPeers.isEmpty {
                    HStack {
                        TextField("Nachricht senden", text: $messageText)
                            .textFieldStyle(.roundedBorder)
                        Button {
                            // Sende String als Payload
                            mpc.sendToAll(event: "CHAT", object: messageText) // Quick hack: passing string as codable works? Yes.
                            messageText = ""
                        } label: {
                            Image(systemName: "paperplane.fill")
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Multipeer Lab")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Schließen") { dismiss() }
                }
            }
        }
    }
    
    var statusColor: Color {
        switch mpc.role {
        case .unknown: return .gray
        case .host: return .blue
        case .peer: return .green
        }
    }
}
