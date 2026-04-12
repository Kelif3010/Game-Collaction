import SwiftUI
import Combine

// MARK: - Spielphase
enum SoundCinemaPhase: Equatable {
    case setup
    case playing
    case voting
    case eliminated(playerName: String)
    case gameOver
}

// MARK: - Voting-Ergebnis (Präfix wegen globalem VoteResult in Imposter)
enum SCVoteResult {
    case success
    case failure
}

// MARK: - ViewModel
@MainActor
final class SoundCinemaViewModel: ObservableObject {

    // MARK: Spiel-Phase
    @Published var phase: SoundCinemaPhase = .setup

    // MARK: Spieler
    @Published var players: [SoundCinemaPlayer] = []
    @Published var currentPlayerIndex: Int = 0

    // MARK: Karten
    @Published var cardDeck: [SoundCard] = []
    @Published var currentCard: SoundCard?
    @Published var cardIndex: Int = 0

    // MARK: Timer
    @Published var timeRemaining: Int = 8
    @Published var timerProgress: Double = 1.0  // 1.0 = voll, 0.0 = leer
    @Published var isTimerRunning: Bool = false

    // MARK: Settings
    private(set) var settings: SoundCinemaSettings = SoundCinemaSettings()

    // MARK: Animationen
    @Published var cardFlipped: Bool = false
    @Published var showVoteOverlay: Bool = false
    @Published var lastVoteWasSuccess: Bool = false
    @Published var pulseTimer: Bool = false

    private var timerTask: Task<Void, Never>?

    // MARK: - Computed
    var currentPlayer: SoundCinemaPlayer? {
        guard players.indices.contains(currentPlayerIndex) else { return nil }
        return players[currentPlayerIndex]
    }

    var activePlayers: [SoundCinemaPlayer] {
        players.filter { !$0.isEliminated }
    }

    var winner: SoundCinemaPlayer? {
        activePlayers.count == 1 ? activePlayers.first : nil
    }

    var isEndless: Bool {
        settings.livesMode == .endless
    }

    // MARK: - Setup
    func configure(with settings: SoundCinemaSettings) {
        self.settings = settings
        let lives = settings.livesMode.rawValue > 0 ? settings.livesMode.rawValue : 999
        self.players = settings.playerNames.map { SoundCinemaPlayer(name: $0, lives: lives) }
        self.cardDeck = SoundCardDatabase.cards(for: settings.selectedPacks)
        self.currentPlayerIndex = 0
        self.cardIndex = 0
        self.currentCard = cardDeck.first
        self.phase = .playing
        self.timeRemaining = settings.timerMode.rawValue
    }

    // MARK: - Timer
    func startTimer() {
        guard !isTimerRunning else { return }
        isTimerRunning = true
        timeRemaining = settings.timerMode.rawValue
        timerProgress = 1.0

        timerTask = Task {
            let total = settings.timerMode.rawValue
            while timeRemaining > 0 {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard !Task.isCancelled else { return }
                timeRemaining -= 1
                timerProgress = Double(timeRemaining) / Double(total)

                // Pulse-Effekt in den letzten 3 Sekunden
                if timeRemaining <= 3 {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        pulseTimer.toggle()
                    }
                }
            }
            // Zeit abgelaufen → automatisch Misserfolg
            if !Task.isCancelled {
                await handleVote(.failure)
            }
        }
    }

    func stopTimer() {
        timerTask?.cancel()
        timerTask = nil
        isTimerRunning = false
    }

    // MARK: - Karten-Navigation
    func revealCard() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            cardFlipped = true
        }
        startTimer()
    }

    // MARK: - Voting
    func handleVote(_ result: SCVoteResult) async {
        stopTimer()
        phase = .voting

        lastVoteWasSuccess = (result == .success)

        withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
            showVoteOverlay = true
        }

        try? await Task.sleep(nanoseconds: 1_200_000_000)

        withAnimation {
            showVoteOverlay = false
        }

        // Score + Leben updaten
        if result == .success {
            players[currentPlayerIndex].gainPoint()
        } else {
            if !isEndless {
                players[currentPlayerIndex].loseLife()

                // Prüfe ob Spieler ausgeschieden
                if players[currentPlayerIndex].isEliminated {
                    let name = players[currentPlayerIndex].name
                    phase = .eliminated(playerName: name)
                    try? await Task.sleep(nanoseconds: 1_500_000_000)

                    // Nur 1 Spieler übrig → Spiel vorbei
                    if activePlayers.count <= 1 {
                        endGame()
                        return
                    }
                }
            }
        }

        advanceToNextPlayer()
    }

    // MARK: - Spieler-Wechsel
    private func advanceToNextPlayer() {
        cardIndex += 1
        if cardIndex >= cardDeck.count {
            cardDeck = SoundCardDatabase.cards(for: settings.selectedPacks)
            cardIndex = 0
        }
        currentCard = cardDeck[cardIndex]

        var next = (currentPlayerIndex + 1) % players.count
        var loops = 0
        while players[next].isEliminated && loops < players.count {
            next = (next + 1) % players.count
            loops += 1
        }
        currentPlayerIndex = next

        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            cardFlipped = false
        }
        isTimerRunning = false
        pulseTimer = false
        timeRemaining = settings.timerMode.rawValue
        timerProgress = 1.0
        phase = .playing
    }

    // MARK: - Spiel beenden
    func endGame() {
        stopTimer()
        GlobalStatsManager.shared.markGameAsPlayed("SoundCinema")
        if let w = winner ?? activePlayers.max(by: { $0.score < $1.score }) {
            GlobalStatsManager.shared.recordWin(for: w.name)
        }
        for player in players where !player.isEliminated || player.score > 0 {
            GlobalStatsManager.shared.recordParticipation(for: player.name)
        }
        withAnimation { phase = .gameOver }
    }

    // MARK: - Neustart
    func restart() {
        stopTimer()
        configure(with: settings)
    }
}
