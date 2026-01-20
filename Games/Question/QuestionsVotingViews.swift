import SwiftUI

struct QuestionsVotingView: View {
    let players: [QuestionPlayer]
    let liars: Set<UUID>
    let onFinished: (QuestionsVoteEvaluation) -> Void
    
    @StateObject private var manager: QuestionsVotingManager
    
    init(players: [QuestionPlayer], liars: Set<UUID>, onFinished: @escaping (QuestionsVoteEvaluation) -> Void) {
        self.players = players
        self.liars = liars
        self.onFinished = onFinished
        _manager = StateObject(wrappedValue: QuestionsVotingManager(players: players.map { $0.id }, liars: liars))
    }
    
    private let columns = [GridItem(.adaptive(minimum: 140), spacing: 16)]
    
    var body: some View {
        VStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(players, id: \.id) { player in
                        QVPlayerCard(player: player,
                                     isSelected: manager.selected.contains(player.id),
                                     disabled: (!manager.isActive || manager.hasResults))
                        .onTapGesture {
                            guard !(!manager.isActive || manager.hasResults) else { return }
                            manager.toggle(player.id)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 48)
            }
        }
        .safeAreaInset(edge: .bottom) {
            Button {
                if let eval = manager.confirm() {
                    onFinished(eval)
                }
            } label: {
                Text("Auswertung bestätigen")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(manager.canConfirm ? Color.accentColor : Color.gray.opacity(0.5))
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
            }
            .disabled(!manager.canConfirm)
        }
        .onAppear {
            if !manager.isActive && !manager.hasResults {
                manager.start()
            }
        }
    }
}

private struct QVPlayerCard: View {
    let player: QuestionPlayer
    let isSelected: Bool
    let disabled: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            Text(String(player.name.prefix(1)))
                .font(.largeTitle.bold())
                .frame(width: 60, height: 60)
                .background(isSelected ? Color.accentColor.opacity(0.2) : Color.gray.opacity(0.2))
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(isSelected ? Color.accentColor : Color.gray.opacity(0.5), lineWidth: 2)
                )
            
            Text(LocalizedStringKey(player.name))
                .font(.body)
                .foregroundColor(disabled ? Color.gray : Color.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(
            Capsule()
                .fill(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
        )
        .overlay(
            Capsule()
                .stroke(isSelected ? Color.accentColor : Color.gray.opacity(0.3), lineWidth: isSelected ? 2 : 1)
        )
        .opacity(disabled ? 0.6 : 1)
    }
}

struct QuestionsVotingResultsView: View {
    let players: [QuestionPlayer]
    let evaluation: QuestionsVoteEvaluation
    let onClose: () -> Void
    
    private var title: LocalizedStringKey {
        switch evaluation.outcome {
        case .citizensWin:
            return "Probanden haben gewonnen"
        case .liarsWin:
            return "Lügner haben gewonnen"
        }
    }
    
    private var selectedPlayerIDs: Set<UUID> {
        evaluation.selected
    }
    
    private var selectedPlayers: [QuestionPlayer] {
        players.filter { selectedPlayerIDs.contains($0.id) }
    }
    
    private var liars: [QuestionPlayer] {
        players.filter { evaluation.liars.contains($0.id) }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text(title)
                .font(.title2.bold())
                .padding(.top, 24)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Gewählte Verdächtige")
                    .font(.headline)
                
                if selectedPlayers.isEmpty {
                    Text("Keine Verdächtigen gewählt")
                        .foregroundColor(.secondary)
                } else {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 12)], spacing: 12) {
                        ForEach(selectedPlayers, id: \.id) { player in
                            HStack {
                                Text(LocalizedStringKey(player.name))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                                    .foregroundColor(.primary)
                                Spacer()
                                Text(evaluation.correct.contains(player.id) ? "✔️" : "✖️")
                            }
                            .padding(10)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.gray.opacity(0.1))
                            )
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Tatsächliche Lügner")
                    .font(.headline)
                
                if liars.isEmpty {
                    Text("Keine Lügner")
                        .foregroundColor(.secondary)
                } else {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 12)], spacing: 12) {
                        ForEach(liars, id: \.id) { player in
                            Text(LocalizedStringKey(player.name))
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                                .padding(10)
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.red.opacity(0.2))
                                )
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            
            Spacer()
            
            Button("Zurück") {
                onClose()
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.accentColor)
            .foregroundColor(.white)
            .cornerRadius(12)
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .onAppear {
            recordStats()
        }
    }
    
    private func recordStats() {
        let liarIds = evaluation.liars
        let winners: [QuestionPlayer]
        let losers: [QuestionPlayer]
        
        if evaluation.outcome == .citizensWin {
            winners = players.filter { !liarIds.contains($0.id) }
            losers = players.filter { liarIds.contains($0.id) }
        } else {
            winners = players.filter { liarIds.contains($0.id) }
            losers = players.filter { !liarIds.contains($0.id) }
        }
        
        for p in winners { GlobalStatsManager.shared.recordWin(for: p.name) }
        for p in losers { GlobalStatsManager.shared.recordLoss(for: p.name) }
    }
}
