import SwiftUI

struct PartyBridgeView: View {
    var manager: PartySessionManager
    let game: PartyGame
    let players: [PartyPlayer]

    @State private var winnerIDs: Set<UUID> = []

    private var canConfirm: Bool { !winnerIDs.isEmpty }

    var body: some View {
        VStack(spacing: 0) {

            // Handle
            Capsule()
                .fill(.white.opacity(0.2))
                .frame(width: 36, height: 4)
                .padding(.top, 14)
                .padding(.bottom, 24)

            // ── Spiel-Badge ───────────────────────────────────────────
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(game.gradient)
                        .frame(width: 40, height: 40)
                    Image(systemName: game.icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(game.displayName)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("abgeschlossen")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.5))
                }
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)

            // ── Headline ──────────────────────────────────────────────
            VStack(spacing: 4) {
                Text("Wer hat gewonnen?")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("Mehrere Gewinner möglich")
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.4))
            }
            .padding(.bottom, 20)

            // ── Spieler-Liste ─────────────────────────────────────────
            VStack(spacing: 8) {
                ForEach(players) { player in
                    let isWinner = winnerIDs.contains(player.id)
                    Button {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                            if isWinner {
                                winnerIDs.remove(player.id)
                            } else {
                                winnerIDs.insert(player.id)
                            }
                        }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        HStack(spacing: 14) {
                            // Avatar
                            ZStack {
                                Circle()
                                    .fill(player.avatarGradient)
                                    .frame(width: 42, height: 42)
                                Text(player.initial)
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)
                            }

                            // Name + Punkte-Vorschau
                            VStack(alignment: .leading, spacing: 2) {
                                Text(player.name)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(.white)
                                Text(isWinner ? "+3 Punkte" : "+1 Punkt")
                                    .font(.system(size: 12))
                                    .foregroundStyle(
                                        isWinner
                                        ? Color(red: 1.0, green: 0.83, blue: 0.15)
                                        : .white.opacity(0.35)
                                    )
                            }

                            Spacer()

                            // Winner Badge
                            ZStack {
                                Circle()
                                    .fill(
                                        isWinner
                                        ? Color(red: 1.0, green: 0.83, blue: 0.15)
                                        : Color.white.opacity(0.08)
                                    )
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Circle()
                                            .strokeBorder(
                                                isWinner ? Color.clear : Color.white.opacity(0.15),
                                                lineWidth: 1.5
                                            )
                                    )

                                Image(systemName: isWinner ? "crown.fill" : "crown")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(isWinner ? .black : .white.opacity(0.3))
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(isWinner ? .white.opacity(0.1) : .white.opacity(0.04))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .strokeBorder(
                                            isWinner
                                            ? Color(red: 1.0, green: 0.83, blue: 0.15).opacity(0.4)
                                            : Color.white.opacity(0.06),
                                            lineWidth: 1
                                        )
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)

            Spacer(minLength: 20)

            // ── Weiter Button ─────────────────────────────────────────
            Button {
                manager.recordResult(winnerIDs: Array(winnerIDs))
            } label: {
                Text(manager.session?.isLastGame == true ? "Zum Ergebnis" : "Nächstes Spiel")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(canConfirm ? .black : .white.opacity(0.3))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        canConfirm
                        ? LinearGradient(
                            colors: [
                                Color(red: 1.0, green: 0.83, blue: 0.15),
                                Color(red: 1.0, green: 0.65, blue: 0.05)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        : LinearGradient(
                            colors: [Color.white.opacity(0.06), Color.white.opacity(0.06)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        in: RoundedRectangle(cornerRadius: 16)
                    )
            }
            .disabled(!canConfirm)
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
    }
}
