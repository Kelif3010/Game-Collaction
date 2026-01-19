import SwiftUI

struct QuestionsSetupView: View {
    @ObservedObject var appModel: AppModel
    @ObservedObject var viewModel: QuestionsGameViewModel
    var onStartGame: () -> Void
    @ObservedObject private var mpc = MultipeerManager.shared
    
    // Navigation State
    @Environment(\.dismiss) var dismiss
    @State private var showPlayerSheet = false
    @State private var showCategorySheet = false
    @State private var showSettingsSheet = false
    @State private var showLeaderboardSheet = false
    @State private var showOnboardingSheet = false
    @State private var showTimerSheet = false
    @State private var showMultiplayerSheet = false
    @AppStorage("question.onboardingSeen") private var onboardingSeen = false
    
    @State var route: SetupRoute? // For consistency with MPC logic
    
    // Validierung
    private var playerCount: Int { appModel.players.count }
    private var maxSpies: Int { max(0, playerCount > 1 ? playerCount - 1 : 0) }
    
    private var minimumPlayersRequired: Int {
        switch mpc.role {
        case .host, .peer: return 2
        case .unknown: return 3
        }
    }
    
    private var allPlayersReady: Bool {
        guard mpc.role == .host else { return true }
        let lobby = Set(mpc.lobbyPeers)
        guard !lobby.isEmpty else { return false }
        return lobby.isSubset(of: mpc.readyPlayers)
    }

    private var canStart: Bool {
        if mpc.role == .peer { return false }
        guard let cat = viewModel.selectedCategory else { return false }
        
        let baseReady = playerCount >= minimumPlayersRequired && 
                       viewModel.numberOfSpies >= 1 && 
                       viewModel.numberOfSpies <= maxSpies && 
                       !cat.promptPairs.isEmpty
        
        return baseReady && allPlayersReady
    }
    
    private var startButtonHintText: String {
        if mpc.role == .peer {
            return NSLocalizedString("Warte auf den Host...", comment: "")
        }
        
        var missingItems: [String] = []
        if playerCount < minimumPlayersRequired {
            missingItems.append(String(format: NSLocalizedString("Noch %d Spieler benötigt", comment: ""), minimumPlayersRequired - playerCount))
        }
        
        if viewModel.selectedCategory == nil {
            missingItems.append(NSLocalizedString("Kategorie wählen", comment: ""))
        }
        
        if viewModel.numberOfSpies >= playerCount && playerCount > 0 {
            missingItems.append(NSLocalizedString("Zu viele Spione", comment: ""))
        }
        
        if mpc.role == .host && !allPlayersReady {
            let lobby = Set(mpc.lobbyPeers)
            let missingReady = max(0, lobby.count - mpc.readyPlayers.intersection(lobby).count)
            if missingReady > 0 {
                missingItems.append(String(format: NSLocalizedString("Warten auf %d Spieler", comment: ""), missingReady))
            }
        }
        
        return missingItems.isEmpty ? "" : missingItems.joined(separator: " • ")
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Hintergrund
                QuestionsStyle.backgroundGradient.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // MARK: - Top Bar
                    HStack {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.headline.bold())
                                .foregroundStyle(.white)
                                .frame(width: 36, height: 36)
                                .background(Color.white.opacity(0.1))
                                .clipShape(Circle())
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 12) {
                            // Multiplayer
                            Button { showMultiplayerSheet = true } label: {
                                Image(systemName: "person.2.wave.2.fill")
                                    .font(.headline)
                                    .foregroundStyle(.cyan)
                                    .frame(width: 36, height: 36)
                                    .background(Color.white.opacity(0.1))
                                    .clipShape(Circle())
                            }
                            
                            // Trophäe
                            Button { showLeaderboardSheet = true } label: {
                                Image(systemName: "trophy.fill")
                                    .font(.headline)
                                    .foregroundStyle(.yellow)
                                    .frame(width: 36, height: 36)
                                    .background(Color.white.opacity(0.1))
                                    .clipShape(Circle())
                            }
                            
                            // Ordner (Kategorie)
                            Button { showCategorySheet = true } label: {
                                Image(systemName: "briefcase.fill")
                                    .font(.headline)
                                    .foregroundStyle(.orange)
                                    .frame(width: 36, height: 36)
                                    .background(Color.white.opacity(0.1))
                                    .clipShape(Circle())
                            }
                            
                            // Zahnrad (Settings)
                            Button { showSettingsSheet = true } label: {
                                Image(systemName: "gearshape.fill")
                                    .font(.headline)
                                    .foregroundStyle(.gray)
                                    .frame(width: 36, height: 36)
                                    .background(Color.white.opacity(0.1))
                                    .clipShape(Circle())
                            }
                            
                            // Fragezeichen (Info)
                            Button { showOnboardingSheet = true } label: {
                                Image(systemName: "questionmark")
                                    .font(.headline.bold())
                                    .foregroundStyle(.white)
                                    .frame(width: 36, height: 36)
                                    .background(Color.white.opacity(0.1))
                                    .clipShape(Circle())
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                    .padding(.bottom, 10)
                    
                    ScrollView {
                        VStack(spacing: 16) {
                            
                            QuestionsGroupedCard {
                                // Spieler Row
                                Button {
                                    showPlayerSheet = true
                                } label: {
                                    QuestionsRowCell(
                                        icon: "person.3.fill",
                                        title: "Spieler",
                                        value: "\(playerCount)",
                                        tint: .blue
                                    )
                                }
                                
                                // Spione Row with Stepper
                                HStack(spacing: 12) {
                                    QuestionsIconBadge(systemName: "eye.slash.fill", tint: .red)
                                    Text("Spione")
                                        .font(.body)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                    Spacer()
                                    
                                    HStack(spacing: 8) {
                                        Button {
                                            if viewModel.numberOfSpies > 1 { viewModel.numberOfSpies -= 1 }
                                        } label: {
                                            Image(systemName: "minus")
                                                .font(.system(size: 16, weight: .semibold))
                                                .frame(width: 30, height: 30)
                                                .background(Color.white.opacity(0.12))
                                                .foregroundColor(.white)
                                                .clipShape(Circle())
                                        }
                                        
                                        Text("\(viewModel.numberOfSpies)")
                                            .font(.callout)
                                            .foregroundColor(.white)
                                            .frame(minWidth: 24)
                                            
                                        Button {
                                            if viewModel.numberOfSpies < maxSpies { viewModel.numberOfSpies += 1 }
                                        } label: {
                                            Image(systemName: "plus")
                                                .font(.system(size: 16, weight: .semibold))
                                                .frame(width: 30, height: 30)
                                                .background(Color.white.opacity(0.12))
                                                .foregroundColor(.white)
                                                .clipShape(Circle())
                                        }
                                    }
                                }
                                .questionsRowStyle()
                                
                                // Timer Row
                                Button {
                                    showTimerSheet = true
                                } label: {
                                    QuestionsRowCell(
                                        icon: "timer",
                                        title: "Diskussion",
                                        value: timeString,
                                        tint: .green
                                    )
                                }
                                
                                // Kategorie Row
                                Button {
                                    showCategorySheet = true
                                } label: {
                                    QuestionsRowCell(
                                        icon: "briefcase.fill",
                                        title: "Kategorie",
                                        value: viewModel.selectedCategory?.name ?? "Wählen",
                                        tint: .orange
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, QuestionsStyle.padding)
                        .padding(.top, 16)
                        .padding(.bottom, 120)
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 10) {
                    QuestionsPrimaryButton(title: "Spiel starten") {
                        if mpc.role == .host {
                            startMPCGame()
                        } else {
                            onStartGame()
                        }
                    }
                    .disabled(!canStart)
                    
                    if !canStart {
                        Text(startButtonHintText)
                            .font(.footnote)
                            .foregroundStyle(QuestionsStyle.mutedText)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
            }
            .sheet(isPresented: $showPlayerSheet) {
                QuestionsPlayerManagementSheet(appModel: appModel)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(28)
                    .presentationBackground(.clear)
            }
            .sheet(isPresented: $showCategorySheet) {
                QuestionsCategorySheet(selectedCategory: $viewModel.selectedCategory)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(28)
                    .presentationBackground(.clear)
            }
            .sheet(isPresented: $showSettingsSheet) {
                QuestionsSettingsSheet()
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(28)
                    .presentationBackground(.clear)
            }
            .sheet(isPresented: $showLeaderboardSheet) {
                QuestionsPlaceholderSheet(title: "Bestenliste", icon: "trophy.fill")
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(28)
                    .presentationBackground(.clear)
            }
            .sheet(isPresented: $showOnboardingSheet, onDismiss: {
                onboardingSeen = true
            }) {
                QuestionsOnboardingSheet(onFinish: {
                    onboardingSeen = true
                })
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(28)
                    .presentationBackground(.clear)
            }
            .sheet(isPresented: $showTimerSheet) {
                QuestionsTimerSheet(discussionTime: $viewModel.discussionTime)
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(28)
                    .presentationBackground(.clear)
            }
            .sheet(isPresented: $showMultiplayerSheet) {
                QuestionsMultiplayerSheet()
            }
        }
        .onAppear {
            setupMPCListeners(viewModel: viewModel, route: $route)
            if !onboardingSeen && !showOnboardingSheet {
                DispatchQueue.main.async {
                    showOnboardingSheet = true
                }
            }
        }
        .onChange(of: viewModel.selectedCategory) { _, newValue in
            broadcastConfig()
            if let name = newValue?.name {
                sendHostActivity("Host waehlt Kategorie: \(name)")
            }
        }
        .onChange(of: viewModel.numberOfSpies) { _, newValue in
            broadcastConfig()
            sendHostActivity("Host stellt Spione auf \(newValue)")
        }
        .onChange(of: viewModel.discussionTime) { _, newValue in
            broadcastConfig()
            if newValue == 0 {
                sendHostActivity("Host stellt Diskussion auf unbegrenzt")
            } else {
                let minutes = Int(newValue) / 60
                sendHostActivity("Host stellt Diskussion auf \(minutes) Min")
            }
        }
        .onChange(of: mpc.lobbyPeers) { _, newPeers in
            guard mpc.role != .unknown else { return }
            if mpc.role == .host {
                appModel.players = mergePlayers(existing: appModel.players, names: newPeers)
                let validPlayers = Set(newPeers)
                let filteredReady = mpc.readyPlayers.intersection(validPlayers)
                if filteredReady != mpc.readyPlayers {
                    mpc.readyPlayers = filteredReady
                }
                mpc.sendToAll(event: "LOBBY_STATE_SYNC", object: Array(filteredReady))
                broadcastConfig()
            }
        }
    }
    
    private var timeString: String {
        if viewModel.discussionTime == 0 {
            return NSLocalizedString("Unbegrenzt", comment: "")
        } else {
            let minutes = Int(viewModel.discussionTime) / 60
            let seconds = Int(viewModel.discussionTime) % 60
            if seconds == 0 {
                return "\(minutes) Min"
            } else {
                return "\(minutes):\(String(format: "%02d", seconds)) Min"
            }
        }
    }
    
    private var validationMessage: LocalizedStringKey {
        if playerCount < 3 { return "Mindestens 3 Spieler benötigt." }
        if viewModel.selectedCategory == nil { return "Bitte eine Kategorie wählen." }
        return ""
    }

    private func mergePlayers(existing: [Player], names: [String]) -> [Player] {
        var merged: [Player] = []
        for name in names {
            if let match = existing.first(where: { $0.name == name }) {
                merged.append(match)
            } else {
                merged.append(Player(name: name))
            }
        }
        return merged
    }
}
