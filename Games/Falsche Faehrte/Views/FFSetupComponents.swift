import SwiftUI

// MARK: - Action Row (tappable)
struct FFSetupActionRow: View {
    let icon: String
    let title: String
    let detail: String
    let subtitle: String?
    let accent: Color

    var body: some View {
        HStack(spacing: 12) {
            FFSetupIconBadge(icon: icon, accent: accent)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.white)

                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(FFStyle.textMuted)
                        .lineLimit(2)
                }
            }

            Spacer()

            HStack(spacing: 6) {
                Text(detail)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(FFStyle.textMuted)
                    .lineLimit(1)
                Image(systemName: "chevron.right")
                    .font(.subheadline)
                    .foregroundStyle(FFStyle.textMuted.opacity(0.7))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.black.opacity(0.35))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(accent.opacity(0.12), lineWidth: 1)
        )
        .contentShape(Rectangle())
    }
}

// MARK: - Toggle Row
struct FFSetupToggleRow: View {
    let icon: String
    let title: String
    let detail: String
    let accent: Color
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 12) {
            FFSetupIconBadge(icon: icon, accent: accent)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.white)
                Text("Zeigt die Themenrichtung direkt unter der Frage")
                    .font(.subheadline)
                    .foregroundStyle(FFStyle.textMuted)
                    .lineLimit(2)
            }

            Spacer()

            Text(detail)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(FFStyle.textMuted)

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(accent)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.black.opacity(0.35))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(accent.opacity(0.12), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityValue(detail)
    }
}

// MARK: - Icon Badge
struct FFSetupIconBadge: View {
    let icon: String
    let accent: Color

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [accent.opacity(0.22), accent.opacity(0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 44, height: 44)
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(accent.opacity(0.3), lineWidth: 1)
                )

            Image(systemName: icon)
                .font(.headline)
                .foregroundStyle(accent)
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Info Sheet (Spielregeln)
struct FFInfoSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                FFBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        ruleBlock(
                            icon: "1.circle.fill", color: FFStyle.accentViolet,
                            title: "Frage erscheint",
                            text: "Eine seltsame, aber wahre Frage wird angezeigt — z.B. \"Womit putzten sich Römer die Zähne?\""
                        )
                        ruleBlock(
                            icon: "2.circle.fill", color: FFStyle.accentIndigo,
                            title: "Alle lügen",
                            text: "Jeder Spieler tippt eine glaubwürdige Lüge ein — am besten eine, die die anderen als Wahrheit wählen!"
                        )
                        ruleBlock(
                            icon: "3.circle.fill", color: FFStyle.accentViolet,
                            title: "Abstimmung",
                            text: "Alle Antworten (Lügen + echte Antwort) erscheinen gemischt. Jeder tippt, was er für die Wahrheit hält."
                        )
                        ruleBlock(
                            icon: "4.circle.fill", color: FFStyle.accentIndigo,
                            title: "Auflösung",
                            text: "Die echte Antwort wird enthüllt. Wer sie gefunden hat, bekommt 2 Punkte. Wer andere mit seiner Lüge täuschte: 1 Punkt pro getäuschtem Spieler."
                        )
                        ruleBlock(
                            icon: "trophy.fill", color: FFStyle.accentGold,
                            title: "Gewinner",
                            text: "Nach allen Runden gewinnt, wer die meisten Punkte gesammelt hat. Kein Ausscheiden — alle spielen bis zum Ende!"
                        )
                        ruleBlock(
                            icon: "lightbulb.fill", color: FFStyle.accentViolet,
                            title: "Profi-Tipp",
                            text: "Die beste Lüge klingt plausibel, aber nicht zu offensichtlich. Verwende Fachbegriffe oder spezifische Details — das überzeugt!"
                        )
                    }
                    .padding()
                }
            }
            .navigationTitle("Spielregeln")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Verstanden!") { dismiss() }
                        .font(.headline)
                        .foregroundStyle(FFStyle.accentViolet)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(28)
    }

    private func ruleBlock(icon: String, color: Color, title: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundStyle(color)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                Text(text)
                    .font(.system(size: 14))
                    .foregroundStyle(FFStyle.textMuted)
                    .lineSpacing(3)
            }
        }
        .padding(14)
        .ffCard()
    }
}

#Preview("Info Sheet") {
    FFInfoSheet()
}
