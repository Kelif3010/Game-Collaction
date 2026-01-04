import SwiftUI

struct QuestionsSetupView: View {
    @ObservedObject var appModel: AppModel
    @Binding var selectedCategory: QuestionsCategory?
    @Binding var numberOfSpies: Int
    var onStartGame: () -> Void
    
    // Navigation State
    @Environment(\.dismiss) private var dismiss
    @State private var showCategorySheet = false
    @State private var showSettingsSheet = false
    @State private var showLeaderboardSheet = false
    @State private var showInfoSheet = false
    
    // Text inputs
    @State private var newPlayerName = ""

    // Validierung
    private var playerCount: Int { appModel.players.count }
    private var maxSpies: Int { max(0, playerCount > 1 ? playerCount - 1 : 0) }
    private var canStart: Bool {
        guard let cat = selectedCategory else { return false }
        return playerCount >= 3 && numberOfSpies >= 1 && numberOfSpies <= maxSpies && !cat.promptPairs.isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Hintergrund
                QuestionsTheme.gradient.ignoresSafeArea()
                
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
                                Image(systemName: "folder.fill")
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
                            Button { showInfoSheet = true } label: {
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
                        VStack(spacing: 20) {
                            
                            // 1. Kategorie Anzeige (Read-only, da Auswahl über Ordner)
                            glassCard {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Kategorie")
                                            .font(.headline)
                                            .foregroundColor(.white.opacity(0.7))
                                        Text(selectedCategory?.name ?? "Bitte wählen")
                                            .font(.title3.bold())
                                            .foregroundColor(.white)
                                    }
                                    Spacer()
                                    Button {
                                        showCategorySheet = true
                                    } label: {
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.white.opacity(0.5))
                                    }
                                }
                            }
                            .onTapGesture {
                                showCategorySheet = true
                            }
                            
                            // 2. Spieler & Spione
                            glassCard {
                                VStack(spacing: 20) {
                                    // Spione Stepper
                                    HStack {
                                        Label("Anzahl Spione", systemImage: "eye.slash.fill")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                        Spacer()
                                        
                                        HStack(spacing: 12) {
                                            Button(action: { if numberOfSpies > 1 { numberOfSpies -= 1 } }) {
                                                Image(systemName: "minus")
                                                    .frame(width: 32, height: 32)
                                                    .background(Color.white.opacity(0.1))
                                                    .clipShape(Circle())
                                                    .foregroundColor(.white)
                                            }
                                            
                                            Text("\(numberOfSpies)")
                                                .font(.title3.bold())
                                                .frame(minWidth: 20)
                                                .foregroundColor(.white)
                                            
                                            Button(action: { if numberOfSpies < maxSpies { numberOfSpies += 1 } }) {
                                                Image(systemName: "plus")
                                                    .frame(width: 32, height: 32)
                                                    .background(Color.white.opacity(0.1))
                                                    .clipShape(Circle())
                                                    .foregroundColor(.white)
                                            }
                                        }
                                    }
                                    
                                    Divider().overlay(.white.opacity(0.2))
                                    
                                    // Spieler Header & Add
                                    HStack {
                                        Label("Spieler (\(playerCount))", systemImage: "person.3.fill")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                        Spacer()
                                        Button(action: addPlayer) {
                                            HStack {
                                                Image(systemName: "plus")
                                                Text("Hinzufügen")
                                            }
                                            .font(.subheadline.bold())
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(Color.green.opacity(0.2))
                                            .foregroundColor(.green)
                                            .clipShape(Capsule())
                                        }
                                    }
                                    
                                    // Spieler Liste
                                    VStack(spacing: 12) {
                                        if appModel.players.isEmpty {
                                            Text("Keine Spieler. Füge mindestens 3 hinzu.")
                                                .font(.caption)
                                                .foregroundColor(.white.opacity(0.5))
                                                .padding()
                                        } else {
                                            ForEach(Array(appModel.players.enumerated()), id: \.element.id) { index, player in
                                                HStack {
                                                    Text("\(index + 1).")
                                                        .font(.subheadline.bold())
                                                        .foregroundColor(.white.opacity(0.5))
                                                        .frame(width: 24)
                                                    
                                                    TextField("Name", text: $appModel.players[index].name)
                                                        .font(.body.weight(.medium))
                                                        .foregroundColor(.white)
                                                    
                                                    Spacer()
                                                    
                                                    Button {
                                                        withAnimation { removePlayer(at: index) }
                                                    } label: {
                                                        Image(systemName: "trash")
                                                            .foregroundColor(.red.opacity(0.7))
                                                    }
                                                }
                                                .padding(12)
                                                .background(Color.black.opacity(0.2))
                                                .cornerRadius(12)
                                            }
                                        }
                                    }
                                }
                            }
                            
                            // 3. Start Button (Floating Bottom Style)
                            Button(action: onStartGame) {
                                Text("Spiel starten")
                                    .font(.title3.bold())
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 18)
                                    .background(
                                        canStart
                                        ? LinearGradient(colors: [Color.green, Color.blue], startPoint: .leading, endPoint: .trailing)
                                        : LinearGradient(colors: [Color.gray.opacity(0.3)], startPoint: .leading, endPoint: .trailing)
                                    )
                                    .clipShape(Capsule())
                                    .shadow(color: canStart ? Color.green.opacity(0.4) : .clear, radius: 10, x: 0, y: 5)
                            }
                            .disabled(!canStart)
                            .padding(.top, 10)
                            
                            if !canStart {
                                Text(validationMessage)
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showCategorySheet) {
                QuestionsCategorySheet(selectedCategory: $selectedCategory)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showSettingsSheet) {
                QuestionsSettingsSheet()
            }
            .sheet(isPresented: $showLeaderboardSheet) {
                QuestionsPlaceholderSheet(title: "Bestenliste", icon: "trophy.fill")
            }
            .sheet(isPresented: $showInfoSheet) {
                QuestionsPlaceholderSheet(title: "Anleitung", icon: "book.fill")
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func addPlayer() {
        let newNumber = appModel.players.count + 1
        withAnimation {
            appModel.players.append(Player(name: "Spieler \(newNumber)"))
            if numberOfSpies > maxSpies { numberOfSpies = max(1, maxSpies) }
        }
    }
    
    private func removePlayer(at index: Int) {
        guard appModel.players.indices.contains(index) else { return }
        appModel.players.remove(at: index)
        if numberOfSpies > maxSpies { numberOfSpies = max(1, maxSpies) }
    }
    
    private var validationMessage: String {
        if playerCount < 3 { return "Mindestens 3 Spieler benötigt." }
        if selectedCategory == nil { return "Bitte eine Kategorie wählen." }
        return ""
    }
    
    private func glassCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(20)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
    }
}

// MARK: - Sheets

struct QuestionsCategorySheet: View {
    @Binding var selectedCategory: QuestionsCategory?
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            QuestionsTheme.gradient.ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("Kategorie wählen")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                    .padding(.top, 20)
                
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(QuestionsDefaults.all) { category in
                            Button {
                                selectedCategory = category
                                dismiss()
                            } label: {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(category.name)
                                            .font(.headline)
                                            .foregroundColor(.white)
                                        Text("\(category.promptPairs.count) Fragenpaare")
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.6))
                                    }
                                    Spacer()
                                    if selectedCategory?.id == category.id {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                            .font(.title2)
                                    }
                                }
                                .padding()
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(selectedCategory?.id == category.id ? Color.green.opacity(0.5) : Color.white.opacity(0.05), lineWidth: 1)
                                )
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
}

struct QuestionsSettingsSheet: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            QuestionsTheme.gradient.ignoresSafeArea()
            VStack {
                Text("Einstellungen")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                    .padding(.top, 20)
                
                Spacer()
                Text("Hier könnten Spieleinstellungen sein.")
                    .foregroundColor(.gray)
                Spacer()
            }
        }
    }
}

struct QuestionsPlaceholderSheet: View {
    let title: String
    let icon: String
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            QuestionsTheme.gradient.ignoresSafeArea()
            VStack(spacing: 20) {
                Image(systemName: icon)
                    .font(.system(size: 60))
                    .foregroundColor(.white.opacity(0.2))
                    .padding(.top, 40)
                
                Text(title)
                    .font(.largeTitle.bold())
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("Schließen") { dismiss() }
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.bottom, 20)
            }
        }
    }
}
