import SwiftUI

/// Entry-Point für die gesamte Party-Session.
/// Wird als `fullScreenCover` aus ContentView präsentiert.
struct PartyWrapper: View {
    @Environment(\.dismiss) var dismiss
    @State private var manager = PartySessionManager()

    var body: some View {
        Group {
            if manager.session == nil {
                // ── Setup: Spieler + Spiele wählen ──────────────────
                PartySetupView(manager: manager)

            } else if manager.session?.state == .complete {
                // ── Recap: Gesamtwertung ─────────────────────────────
                PartyRecapView(manager: manager, onDismiss: { dismiss() })
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal:   .opacity
                    ))

            } else {
                // ── Hub: Session läuft ───────────────────────────────
                PartyHubView(manager: manager, onDismiss: { dismiss() })
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal:   .opacity
                    ))
            }
        }
        .animation(.easeInOut(duration: 0.35), value: manager.session?.state)
        .animation(.easeInOut(duration: 0.35), value: manager.session == nil)
    }
}
