import SwiftUI

struct QuestionsSetupView: View {
    @ObservedObject var appModel: AppModel
    @Binding var selectedCategory: QuestionsCategory?
    @Binding var numberOfSpies: Int
    @Binding var discussionTime: TimeInterval
    var onStartGame: () -> Void
    
    // Navigation State
    @Environment(\.dismiss) private var dismiss
    @State private var showPlayerSheet = false
    @State private var showCategorySheet = false
    @State private var showSettingsSheet = false
    @State private var showLeaderboardSheet = false
    @State private var showInfoSheet = false
    
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
                QuestionsStyle.backgroundGradient.ignoresSafeArea()
                
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
                        VStack(spacing: 16) {
                            
                            QuestionsGroupedCard {
                                // Spieler Row
                                Button {
                                    showPlayerSheet = true
                                } label: {
                                    QuestionsRowCell(
                                        icon: "person.3.fill",
                                        title: "Spieler",
                                        value: "\(playerCount)",
                                        tint: .blue
                                    )
                                }
                                
                                // Spione Row with Stepper
                                HStack(spacing: 12) {
                                    QuestionsIconBadge(systemName: "eye.slash.fill", tint: .red)
                                    Text("Spione")
                                        .font(.body)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                    Spacer()
                                    
                                    HStack(spacing: 8) {
                                        Button {
                                            if numberOfSpies > 1 { numberOfSpies -= 1 }
                                        } label: {
                                            Image(systemName: "minus")
                                                .font(.system(size: 16, weight: .semibold))
                                                .frame(width: 30, height: 30)
                                                .background(Color.white.opacity(0.12))
                                                .foregroundColor(.white)
                                                .clipShape(Circle())
                                        }
                                        
                                        Text("\(numberOfSpies)")
                                            .font(.callout)
                                            .foregroundColor(.white)
                                            .frame(minWidth: 24)
                                            
                                        Button {
                                            if numberOfSpies < maxSpies { numberOfSpies += 1 }
                                        } label: {
                                            Image(systemName: "plus")
                                                .font(.system(size: 16, weight: .semibold))
                                                .frame(width: 30, height: 30)
                                                .background(Color.white.opacity(0.12))
                                                .foregroundColor(.white)
                                                .clipShape(Circle())
                                        }
                                    }
                                }
                                .questionsRowStyle()
                                
                                // Timer Row
                                Button {
                                    toggleTime()
                                } label: {
                                    QuestionsRowCell(
                                        icon: "timer",
                                        title: "Diskussion",
                                        value: timeString,
                                        tint: .green
                                    )
                                }
                                
                                // Kategorie Row
                                Button {
                                    showCategorySheet = true
                                } label: {
                                    QuestionsRowCell(
                                        icon: "folder.fill",
                                        title: "Kategorie",
                                        value: selectedCategory?.name ?? "Wählen",
                                        tint: .orange
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, QuestionsStyle.padding)
                        .padding(.top, 16)
                        .padding(.bottom, 120)
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 10) {
                    QuestionsPrimaryButton(title: "Spiel starten") {
                        onStartGame()
                    }
                    .disabled(!canStart)
                    
                    if !canStart {
                        Text(validationMessage)
                            .font(.footnote)
                            .foregroundStyle(QuestionsStyle.mutedText)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
            }
            .sheet(isPresented: $showPlayerSheet) {
                QuestionsPlayerManagementSheet(appModel: appModel)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(28)
                    .presentationBackground(.clear)
            }
            .sheet(isPresented: $showCategorySheet) {
                QuestionsCategorySheet(selectedCategory: $selectedCategory)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(28)
                    .presentationBackground(.clear)
            }
            .sheet(isPresented: $showSettingsSheet) {
                QuestionsSettingsSheet()
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(28)
                    .presentationBackground(.clear)
            }
            .sheet(isPresented: $showLeaderboardSheet) {
                QuestionsPlaceholderSheet(title: "Bestenliste", icon: "trophy.fill")
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(28)
                    .presentationBackground(.clear)
            }
            .sheet(isPresented: $showInfoSheet) {
                QuestionsPlaceholderSheet(title: "Anleitung", icon: "book.fill")
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(28)
                    .presentationBackground(.clear)
            }
        }
    }
    
    private func toggleTime() {
        let options: [TimeInterval] = [120, 180, 300, 0]
        if let currentIndex = options.firstIndex(of: discussionTime) {
            let nextIndex = (currentIndex + 1) % options.count
            discussionTime = options[nextIndex]
        } else {
            discussionTime = 180
        }
    }
    
    private var timeString: String {
        if discussionTime == 0 {
            return NSLocalizedString("Unbegrenzt", comment: "")
        } else {
            let minutes = Int(discussionTime / 60)
            return "\(minutes) Min"
        }
    }
    
    private var validationMessage: LocalizedStringKey {
        if playerCount < 3 { return "Mindestens 3 Spieler benötigt." }
        if selectedCategory == nil { return "Bitte eine Kategorie wählen." }
        return ""
    }
}

// MARK: - Helper Sheets

struct QuestionsPlayerManagementSheet: View {
    @ObservedObject var appModel: AppModel
    @Environment(\.dismiss) var dismiss
    @State private var newPlayerName = ""
    @FocusState private var isInputFocused: Bool

    var body: some View {
        ZStack {
            QuestionsStyle.backgroundGradient.ignoresSafeArea()
            
            VStack(spacing: 0) {
                QuestionsSheetHeader(title: "Spieler verwalten") {
                    dismiss()
                }
                .padding(.horizontal, QuestionsStyle.padding)
                
                VStack(spacing: 16) {
                    // Input
                    HStack(spacing: 10) {
                        TextField("Neuer Spieler...", text: $newPlayerName)
                            .textFieldStyle(.plain)
                            .font(.body)
                            .padding(12)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.1)))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.2), lineWidth: 1))
                            .foregroundStyle(.white)
                            .submitLabel(.done)
                            .focused($isInputFocused)
                            .onSubmit { addPlayer() }
                            .autocorrectionDisabled()
                        
                        Button(action: addPlayer) {
                            Image(systemName: "plus")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 48, height: 48)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(!newPlayerName.isEmpty ? Color.green : Color.gray.opacity(0.3))
                                )
                        }
                        .disabled(newPlayerName.isEmpty)
                    }
                    .padding(.top, 20)
                    
                    // List
                    List {
                        Section {
                            ForEach(appModel.players, id: \.id) { player in
                                Text(player.name)
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                    .listRowBackground(Color.white.opacity(0.08))
                                    .listRowSeparatorTint(Color.white.opacity(0.1))
                            }
                            .onDelete(perform: deletePlayer)
                            .onMove(perform: movePlayer)
                        } header: {
                            Text("\(appModel.players.count) Spieler")
                                .foregroundStyle(QuestionsStyle.mutedText)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .environment(\.editMode, .constant(.active))
                }
                .padding(.horizontal, QuestionsStyle.padding)
            }
        }
    }
    
    private func addPlayer() {
        let name = newPlayerName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        withAnimation {
            appModel.players.append(Player(name: name))
        }
        newPlayerName = ""
        isInputFocused = true
    }
    
    private func deletePlayer(at offsets: IndexSet) {
        appModel.players.remove(atOffsets: offsets)
    }
    
    private func movePlayer(from source: IndexSet, to destination: Int) {
        appModel.players.move(fromOffsets: source, toOffset: destination)
    }
}

struct QuestionsCategorySheet: View {
    @Binding var selectedCategory: QuestionsCategory?
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            QuestionsStyle.backgroundGradient.ignoresSafeArea()
            
            VStack(spacing: 0) {
                QuestionsSheetHeader(title: "Kategorie wählen") {
                    dismiss()
                }
                .padding(.horizontal, QuestionsStyle.padding)
                
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(QuestionsDefaults.all) { category in
                            Button {
                                selectedCategory = category
                                dismiss()
                            } label: {
                                HStack(spacing: 12) {
                                    QuestionsIconBadge(systemName: "folder.fill", tint: .orange)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(LocalizedStringKey(category.name))
                                            .font(.headline)
                                            .foregroundStyle(.white)
                                        Text("\(category.promptPairs.count) Fragen")
                                            .font(.caption)
                                            .foregroundStyle(QuestionsStyle.mutedText)
                                    }
                                    
                                    Spacer()
                                    
                                    if selectedCategory?.id == category.id {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.green)
                                            .font(.headline)
                                    } else {
                                        Image(systemName: "circle")
                                            .foregroundStyle(.white.opacity(0.3))
                                            .font(.headline)
                                    }
                                }
                                .questionsRowStyle()
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(QuestionsStyle.padding)
                }
            }
        }
    }
}

struct QuestionsSettingsSheet: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            QuestionsStyle.backgroundGradient.ignoresSafeArea()
            VStack {
                QuestionsSheetHeader(title: "Einstellungen") {
                    dismiss()
                }
                .padding(.horizontal, QuestionsStyle.padding)
                
                Spacer()
                Text(LocalizedStringKey("Hier könnten Spieleinstellungen sein."))
                    .foregroundColor(QuestionsStyle.mutedText)
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
            QuestionsStyle.backgroundGradient.ignoresSafeArea()
            VStack(spacing: 20) {
                QuestionsSheetHeader(title: title) {
                    dismiss()
                }
                .padding(.horizontal, QuestionsStyle.padding)
                
                Spacer()
                
                Image(systemName: icon)
                    .font(.system(size: 60))
                    .foregroundColor(.white.opacity(0.2))
                
                Text(LocalizedStringKey(title))
                    .font(.title2.bold())
                    .foregroundColor(.white)
                
                Spacer()
            }
        }
    }
}