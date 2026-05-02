import SwiftUI

struct HoldToConfirmButton: View {
    var title: String = "Halten zum Bestätigen"
    var duration: Double = 1.0
    var action: () -> Void
    var disabled: Bool = false

    @State private var isPressing = false
    @State private var progress: CGFloat = 0
    @State private var timer: Timer?
    @State private var glowPulse = false

    var body: some View {
        ZStack(alignment: .leading) {
            // Casino-Hintergrund
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.08, green: 0.10, blue: 0.08),
                            Color(red: 0.05, green: 0.06, blue: 0.05)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            // Fortschritts-Füllung (Smaragd-Gold)
            Capsule()
                .fill(
                    LinearGradient(
                        colors: disabled
                            ? [Color.gray.opacity(0.3), Color.gray.opacity(0.2)]
                            : [BetBuddyTheme.accentEmerald, BetBuddyTheme.accentGold.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(maxWidth: .infinity, alignment: .leading)
                .scaleEffect(x: progress, y: 1, anchor: .leading)
                .shadow(color: disabled ? .clear : BetBuddyTheme.accentEmerald.opacity(0.5), radius: 8)

            // Inhalt
            HStack {
                // Chip-Icon
                ZStack {
                    Circle()
                        .fill(disabled ? Color.gray.opacity(0.3) : BetBuddyTheme.accentGold.opacity(0.2))
                        .frame(width: 32, height: 32)
                    Circle()
                        .stroke(disabled ? Color.gray.opacity(0.3) : BetBuddyTheme.accentGold.opacity(0.5), lineWidth: 1.5)
                        .frame(width: 32, height: 32)
                    Image(systemName: "hand.point.up.left.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(disabled ? Color.gray : BetBuddyTheme.accentGold)
                }

                Text(LocalizedStringKey(title))
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(disabled ? BetBuddyTheme.textSilver.opacity(0.5) : BetBuddyTheme.textChampagne)

                Spacer()

                if !disabled {
                    Text("ALL IN")
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundStyle(BetBuddyTheme.accentGold)
                        .tracking(1)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(BetBuddyTheme.accentGold.opacity(0.15))
                                .overlay(
                                    Capsule()
                                        .stroke(BetBuddyTheme.accentGold.opacity(0.4), lineWidth: 1)
                                )
                        )
                        .scaleEffect(glowPulse ? 1.05 : 1.0)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
        .frame(height: 56)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(
                    LinearGradient(
                        colors: disabled
                            ? [Color.gray.opacity(0.2), Color.gray.opacity(0.1)]
                            : [BetBuddyTheme.accentGold.opacity(0.4), BetBuddyTheme.accentGold.opacity(0.15)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        .shadow(color: disabled ? .clear : BetBuddyTheme.accentGold.opacity(0.15), radius: 10, y: 4)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    guard !disabled else { return }
                    if !isPressing {
                        startProgress()
                    }
                }
                .onEnded { _ in
                    guard !disabled else { return }
                    stopProgress()
                }
        )
        .onAppear {
            if !disabled {
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    glowPulse = true
                }
            }
        }
        .onDisappear {
            stopProgress()
        }
        .animation(.easeInOut, value: disabled)
    }

    private func startProgress() {
        isPressing = true
        progress = 0
        timer?.invalidate()

        timer = Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { _ in
            Task { @MainActor in
                withAnimation(.linear(duration: 0.02)) {
                    progress += 0.02 / duration
                }
                if progress >= 1.0 {
                    completeAction()
                }
            }
        }
    }

    private func stopProgress() {
        isPressing = false
        timer?.invalidate()
        timer = nil

        withAnimation(.easeOut(duration: 0.2)) {
            progress = 0
        }
    }

    private func completeAction() {
        isPressing = false
        timer?.invalidate()
        timer = nil
        progress = 1.0
        HapticsService.success()
        action()
    }
}
