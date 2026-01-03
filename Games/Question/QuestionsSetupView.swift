import SwiftUI

struct QuestionsSetupView: View {
    @ObservedObject var appModel: AppModel
    @Binding var selectedCategory: QuestionsCategory?
    @Binding var numberOfSpies: Int
    var onStartGame: () -> Void

    // Berechnete Eigenschaften für Validierung
    private var playerCount: Int { appModel.players.count }
    private var maxSpies: Int { max(0, playerCount > 1 ? playerCount - 1 : 0) }
    private var canStart: Bool {
        guard let cat = selectedCategory else { return false }
        return playerCount >= 3 && numberOfSpies >= 1 && numberOfSpies <= maxSpies && !cat.promptPairs.isEmpty
    }

    var body: some View {
        ZStack {
            // Hintergrund im Spiel-Stil
            QuestionsTheme.gradient
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header Karte
                    phaseHeader(icon: "gearshape.fill", title: "Spielvorbereitung", subtitle: "Konfiguriere deine Runde.")

                    // 1. SPIELER EDITOR (Jetzt im Glas-Look)
                    glassCard {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Label("Spieler", systemImage: "person.3.fill")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Spacer()
                                Text("\(playerCount)")
                                    .monospacedDigit()
                                    .foregroundStyle(.white.opacity(0.7))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(.white.opacity(0.2))
                                    .clipShape(Capsule())
                                
                                // Button: Spieler hinzufügen
                                Button(action: addPlayer) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title2)
                                        .foregroundStyle(Color.green)
                                        .background(Circle().fill(.white)) // Weißer Hintergrund für besseren Kontrast
                                }
                            }
                            
                            Divider().overlay(.white.opacity(0.3))
                            
                            if appModel.players.isEmpty {
                                Text("Bitte füge Spieler hinzu (min. 3)")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.6))
                                    .padding(.vertical, 8)
                            } else {
                                // Spieler Liste
                                ForEach(Array(appModel.players.enumerated()), id: \.element.id) { index, player in
                                    HStack(spacing: 12) {
                                        Text("\(index + 1).")
                                            .font(.subheadline.bold())
                                            .foregroundStyle(.white.opacity(0.5))
                                            .frame(width: 25, alignment: .leading)
                                        
                                        // Custom Text Field
                                        TextField("Name", text: $appModel.players[index].name)
                                            .font(.body.weight(.medium))
                                            .padding(10)
                                            .background(Color.black.opacity(0.3))
                                            .cornerRadius(8)
                                            .foregroundColor(.white)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                            )
                                        
                                        // Button: Spieler löschen
                                        Button(action: { removePlayer(at: index) }) {
                                            Image(systemName: "trash.fill")
                                                .foregroundStyle(.red.opacity(0.9))
                                                .padding(8)
                                                .background(Color.black.opacity(0.3))
                                                .clipShape(Circle())
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // 2. KATEGORIE & SPIONE (Nebeneinander oder untereinander)
                    VStack(spacing: 16) {
                        // Kategorie
                        glassCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Kategorie")
                                    .font(.headline)
                                    .foregroundColor(.white.opacity(0.9))
                                
                                Menu {
                                    ForEach(QuestionsDefaults.all) { cat in
                                        Button(action: {
                                            selectedCategory = QuestionsDefaults.all.first(where: { $0.id == cat.id })
                                        }) {
                                            if selectedCategory?.id == cat.id {
                                                Label(cat.name, systemImage: "checkmark")
                                            } else {
                                                Text(cat.name)
                                            }
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Text(selectedCategory?.name ?? "Wählen...")
                                            .font(.body.bold())
                                            .foregroundColor(.white)
                                        Spacer()
                                        Image(systemName: "chevron.up.chevron.down")
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.7))
                                    }
                                    .padding()
                                    .background(Color.black.opacity(0.3))
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                                    )
                                }
                            }
                        }

                        // Spione
                        glassCard {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Anzahl Spione")
                                            .font(.headline)
                                            .foregroundColor(.white.opacity(0.9))
                                    }
                                    Spacer()
                                    // Custom Stepper Anzeige
                                    HStack(spacing: 0) {
                                        Button(action: { if numberOfSpies > 1 { numberOfSpies -= 1 } }) {
                                            Image(systemName: "minus")
                                                .frame(width: 40, height: 40)
                                                .background(Color.white.opacity(0.1))
                                                .foregroundColor(.white)
                                        }
                                        
                                        Text("\(numberOfSpies)")
                                            .font(.title3.bold())
                                            .frame(width: 40)
                                            .foregroundColor(.white)
                                        
                                        Button(action: { if numberOfSpies < maxSpies { numberOfSpies += 1 } }) {
                                            Image(systemName: "plus")
                                                .frame(width: 40, height: 40)
                                                .background(Color.white.opacity(0.1))
                                                .foregroundColor(.white)
                                        }
                                    }
                                    .background(Color.black.opacity(0.3))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                                    )
                                }
                                
                                if maxSpies < 1 {
                                    Label("Zu wenige Spieler für Spione.", systemImage: "exclamationmark.triangle")
                                        .font(.caption)
                                        .foregroundStyle(.orange)
                                } else {
                                    Text("max. \(maxSpies)")
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.5))
                                }
                            }
                        }
                    }

                    // 4. START BUTTON
                    VStack(spacing: 12) {
                        Button(action: onStartGame) {
                            HStack {
                                Image(systemName: "play.fill")
                                Text("Runde starten")
                                    .fontWeight(.bold)
                                    .font(.title3)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                Group {
                                    if canStart {
                                        LinearGradient(
                                            colors: [Color.white, Color.white.opacity(0.8)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    } else {
                                        Color.white.opacity(0.1)
                                    }
                                }
                            )
                            .foregroundStyle(canStart ? QuestionsTheme.textAccent : Color.white.opacity(0.3))
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                            .shadow(color: canStart ? Color.white.opacity(0.2) : .clear, radius: 10, x: 0, y: 5)
                        }
                        .disabled(!canStart)

                        if !canStart {
                            HStack {
                                Image(systemName: "info.circle")
                                if playerCount < 3 {
                                    Text("Min. 3 Spieler benötigt")
                                } else if selectedCategory == nil {
                                    Text("Kategorie wählen")
                                }
                            }
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                        }
                    }
                    .padding(.top, 10)
                }
                .padding(.vertical, 24)
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func addPlayer() {
        let newNumber = appModel.players.count + 1
        appModel.players.append(Player(name: "Spieler \(newNumber)"))
        if numberOfSpies > maxSpies { numberOfSpies = max(1, maxSpies) }
    }
    
    private func removePlayer(at index: Int) {
        guard appModel.players.indices.contains(index) else { return }
        appModel.players.remove(at: index)
        if numberOfSpies > maxSpies { numberOfSpies = max(1, maxSpies) }
    }
    
    private func phaseHeader(icon: String, title: String, subtitle: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.white)
                .padding(12)
                .background(Color.white.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.title3.weight(.bold))
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
            }
            Spacer()
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
    
    private func glassCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.ultraThinMaterial) // Der Glas-Effekt
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1) // Feiner Rand
            )
            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}
