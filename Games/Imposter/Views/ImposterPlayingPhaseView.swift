//
//  ImposterPlayingPhaseView.swift
//  Games Collection
//

import SwiftUI

// MARK: - Playing Phase (lokales Spiel & Multiplayer)
struct ImposterPlayingPhaseView: View {
    @Environment(GameSettings.self) var gameSettings

    let showStartingPlayerAnnouncement: Bool
    let startingPlayerName: String?
    let isMultiplayerCountdown: Bool
    let hintService: HintService
    let onAnnouncementDone: () -> Void

    var body: some View {
        if isMultiplayerCountdown {
            TimelineView(.periodic(from: .now, by: 0.1)) { _ in
                StartingPlayerAnnouncementView(
                    playerName: startingPlayerName,
                    countdownSeconds: countdownSeconds,
                    showButton: false,
                    onContinue: {}
                )
            }
        } else if showStartingPlayerAnnouncement {
            StartingPlayerAnnouncementView(playerName: startingPlayerName) {
                onAnnouncementDone()
            }
        } else {
            ZStack {
                GameTimerView()

                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        HintOverlay(hintService: hintService)
                    }
                }
                .padding(.bottom, 20)
            }
        }
    }

    private var countdownSeconds: Int {
        guard let startAtHostUptime = gameSettings.multiplayerStartAtHostUptime else { return 0 }
        let now = ProcessInfo.processInfo.systemUptime
        let startAtClientUptime = startAtHostUptime - gameSettings.hostClockOffset
        let remaining = startAtClientUptime - now
        guard remaining > 0 else { return 0 }
        return Int(ceil(remaining))
    }
}
