//
//  TimesUpPerkSettingsView.swift
//  TimesUp
//

import SwiftUI

struct PerkSettingsDetailView: View {
    @ObservedObject var gameManager: GameManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            TimesUpStyle.backgroundGradient.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .font(.title2.bold())
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .modifier(GlassCircleButtonBackground())
                    }
                    Spacer()
                    Text(LocalizedStringKey("Perks"))
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                    Spacer()

                    Toggle("", isOn: $gameManager.gameState.settings.perksEnabled)
                        .labelsHidden()
                        .toggleStyle(SwitchToggleStyle(tint: .green))
                }
                .padding(.horizontal, TimesUpStyle.horizontalPadding)
                .padding(.top, 10)
                .padding(.bottom, 20)

                ScrollView {
                    VStack(spacing: 24) {
                        if !gameManager.gameState.settings.perksEnabled {
                            VStack(spacing: 20) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 60))
                                    .foregroundStyle(.gray)
                                Text(LocalizedStringKey("Perks sind deaktiviert"))
                                    .font(.headline)
                                    .foregroundStyle(.gray)
                                Text(LocalizedStringKey("Aktiviere sie oben rechts, um Power-Ups ins Spiel zu bringen."))
                                    .font(.caption)
                                    .foregroundStyle(.gray.opacity(0.7))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                            .padding(.top, 60)
                        } else {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(LocalizedStringKey("Party Modus"))
                                        .font(.headline.bold())
                                        .foregroundStyle(.white)
                                    Text(LocalizedStringKey("Häufigere Perks bei 3/6/9 Treffern"))
                                        .font(.caption)
                                        .foregroundStyle(.gray)
                                }
                                Spacer()
                                Toggle("", isOn: $gameManager.gameState.settings.perkPartyMode)
                                    .labelsHidden()
                                    .toggleStyle(SwitchToggleStyle(tint: .purple))
                            }
                            .padding()
                            .background(Color.white.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 18))

                            VStack(spacing: 16) {
                                Text(LocalizedStringKey("Verfügbare Pakete"))
                                    .font(.headline)
                                    .foregroundStyle(.white.opacity(0.8))
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                ForEach(PerkPack.allCases) { pack in
                                    PerkPackCard(
                                        pack: pack,
                                        isSelected: gameManager.gameState.settings.selectedPerkPacks.contains(pack),
                                        onTap: { toggle(pack) }
                                    )
                                }
                            }

                            if gameManager.gameState.settings.selectedPerkPacks.contains(.custom) {
                                CustomPerkSelectionView(gameManager: gameManager)
                            }
                        }
                    }
                    .padding(.horizontal, TimesUpStyle.horizontalPadding)
                    .padding(.bottom, 40)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private func toggle(_ pack: PerkPack) {
        TimesUpHaptics.impact(.light)
        if pack.isCustom {
            if gameManager.gameState.settings.selectedPerkPacks.contains(.custom) {
                gameManager.gameState.settings.clearCustomPerks()
            } else {
                gameManager.gameState.settings.selectedPerkPacks.insert(.custom)
            }
            return
        }

        if gameManager.gameState.settings.selectedPerkPacks.contains(pack) {
            gameManager.gameState.settings.selectedPerkPacks.remove(pack)
        } else {
            gameManager.gameState.settings.selectedPerkPacks.insert(pack)
        }
    }
}

// MARK: - Perk Pack Card

struct PerkPackCard: View {
    let pack: PerkPack
    let isSelected: Bool
    let onTap: () -> Void

    var packGradient: LinearGradient {
        switch pack {
        case .tempo:    return LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .score:    return LinearGradient(colors: [.green, .yellow], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .sabotage: return LinearGradient(colors: [.pink, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .custom:   return LinearGradient(colors: [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(packGradient.opacity(0.2))
                        .frame(width: 50, height: 50)

                    Image(systemName: pack.iconName)
                        .font(.title2)
                        .foregroundStyle(packGradient)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(LocalizedStringKey(pack.title))
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text(LocalizedStringKey(pack.subtitle))
                        .font(.caption)
                        .foregroundStyle(.gray)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                }

                Spacer()

                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.clear : Color.white.opacity(0.3), lineWidth: 2)
                        .frame(width: 24, height: 24)

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(packGradient)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.black.opacity(0.3))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(isSelected ? packGradient : LinearGradient(colors: [.white.opacity(0.1)], startPoint: .top, endPoint: .bottom), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isSelected)
    }
}

// MARK: - Custom Perk Selection

struct CustomPerkSelectionView: View {
    @ObservedObject var gameManager: GameManager
    @State private var expandedPacks: Set<String> = []

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(LocalizedStringKey("Individuelle Perks wählen"))
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.top, 10)

            ForEach(PerkPack.standardCases) { pack in
                VStack(spacing: 0) {
                    Button {
                        withAnimation {
                            if expandedPacks.contains(pack.id) {
                                expandedPacks.remove(pack.id)
                            } else {
                                expandedPacks.insert(pack.id)
                            }
                        }
                    } label: {
                        HStack {
                            Text(LocalizedStringKey(pack.title))
                                .font(.subheadline.bold())
                                .foregroundStyle(.white)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .rotationEffect(.degrees(expandedPacks.contains(pack.id) ? 90 : 0))
                                .foregroundStyle(.gray)
                        }
                        .padding()
                        .background(Color.white.opacity(0.05))
                    }

                    if expandedPacks.contains(pack.id) {
                        VStack(spacing: 0) {
                            ForEach(pack.associatedPerks, id: \.self) { perk in
                                Toggle(isOn: binding(for: perk)) {
                                    Text(LocalizedStringKey(perk.displayName))
                                        .font(.subheadline)
                                        .foregroundStyle(.white.opacity(0.9))
                                }
                                .toggleStyle(SwitchToggleStyle(tint: .purple))
                                .padding(.horizontal)
                                .padding(.vertical, 12)

                                Divider().background(Color.white.opacity(0.1))
                            }
                        }
                        .background(Color.black.opacity(0.2))
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
            }
        }
    }

    private func binding(for perk: PerkType) -> Binding<Bool> {
        Binding(
            get: { gameManager.gameState.settings.customPerks.contains(perk) },
            set: { enabled in
                gameManager.gameState.settings.setCustomPerk(perk, enabled: enabled)
            }
        )
    }
}
