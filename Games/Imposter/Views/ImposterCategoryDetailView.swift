//
//  CategoryDetailView.swift
//  Imposter
//
//  Created by Ken on 22.09.25.
//

import SwiftUI

struct ImposterCategoryDetailView: View {
    @EnvironmentObject var gameSettings: GameSettings
    @Environment(\.dismiss) private var dismiss
    
    @State var category: Category
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @State private var newWord: String = ""
    @State private var showingWordAlert = false
    @State private var wordToDelete: String?
    
    var body: some View {
        ZStack {
            // Hintergrund-Gradient
            LinearGradient(
                colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 25) {
                    // Header
                    VStack(spacing: 15) {
                        Text(category.emoji)
                            .font(.system(size: 80))
                        
                        Text(category.name)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("\(category.words.count) Begriffe")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)
                    
                    if category.isCustom {
                        VStack(alignment: .leading, spacing: 15) {
                            SectionHeader(title: "Begriff hinzufügen", icon: "plus.circle")
                            
                            HStack(spacing: 12) {
                                TextField("Neuen Begriff eingeben", text: $newWord)
                                    .textFieldStyle(ModernTextFieldStyle())
                                
                                Button(action: addWord) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                }
                                .frame(width: 44, height: 44)
                                .background(
                                    LinearGradient(
                                        colors: newWord.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?
                                            [Color.gray, Color.gray] : [Color.green, Color.blue],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(22)
                                .disabled(newWord.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                                .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 2)
                            }
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            SectionHeader(title: "Begriffe", icon: "plus.circle")
                            Text("Standardkategorien können nicht bearbeitet werden.")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Begriffe-Liste
                    VStack(alignment: .leading, spacing: 15) {
                        SectionHeader(title: "Begriffe", icon: "list.bullet")
                        
                        LazyVGrid(columns: [
                            GridItem(.adaptive(minimum: 140), spacing: 12)
                        ], spacing: 12) {
                            ForEach(category.words, id: \.self) { word in
                                WordCard(word: word, onDelete: category.isCustom ? {
                                    wordToDelete = word
                                    showingWordAlert = true
                                } : nil)
                            }
                        }
                    }

                    // Action Buttons
                    VStack(spacing: 15) {
                        Button(action: { showingEditSheet = true }) {
                            GameActionButton(
                                title: "Kategorie bearbeiten",
                                icon: "pencil.circle.fill",
                                isEnabled: category.isCustom
                            )
                        }
                        .disabled(!category.isCustom)
                        if !category.isCustom {
                            Text("Standardkategorien können nicht bearbeitet werden.")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }

                        if category.isCustom {
                            Button(action: { showingDeleteAlert = true }) {
                                HStack {
                                    Image(systemName: "trash.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                    
                                    Text("Kategorie löschen")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                }
                                .padding(.horizontal, 25)
                                .padding(.vertical, 18)
                                .background(
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(LinearGradient(
                                            colors: [Color.red, Color.red.opacity(0.8)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        ))
                                        .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 3)
                                )
                            }
                        }
                        
                        Button("Zurück") {
                            dismiss()
                        }
                        .foregroundColor(.secondary)
                        .font(.headline)
                    }
                    .padding(.bottom, 30)
                }
                .padding(.horizontal, 20)
            }
        }
        .navigationTitle(category.name)
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showingEditSheet) {
            EditCategoryView(category: $category)
                .environmentObject(gameSettings)
        }
        .alert("Kategorie löschen", isPresented: $showingDeleteAlert) {
            Button("Abbrechen", role: .cancel) { }
            Button("Löschen", role: .destructive) {
                gameSettings.removeCategory(category)
                dismiss()
            }
        } message: {
            Text("Sind Sie sicher, dass Sie diese Kategorie löschen möchten? Diese Aktion kann nicht rückgängig gemacht werden.")
        }
        .alert("Begriff löschen", isPresented: $showingWordAlert) {
            Button("Abbrechen", role: .cancel) { 
                wordToDelete = nil
            }
            Button("Löschen", role: .destructive) {
                if let word = wordToDelete {
                    removeWord(word)
                }
                wordToDelete = nil
            }
        } message: {
            if let word = wordToDelete {
                Text("Möchten Sie den Begriff '\(word)' löschen?")
            }
        }
    }
    
    private func addWord() {
        let word = newWord.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if category.isCustom, !word.isEmpty, !category.words.contains(word) {
            category.addWord(word)
            gameSettings.updateCategory(category)
            newWord = ""
        }
    }
    
    private func removeWord(_ word: String) {
        guard category.isCustom else { return }
        category.removeWord(word)
        gameSettings.updateCategory(category)
    }
}

// MARK: - Word Card
struct WordCard: View {
    let word: String
    let onDelete: (() -> Void)?
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack {
            Text(word)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .lineLimit(2)
            
            Spacer()
            
            if let onDelete {
                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(colorScheme == .dark ? Color(.systemGray5) : Color.white)
                .shadow(color: .black.opacity(colorScheme == .dark ? 0.2 : 0.1), radius: 2, x: 0, y: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Edit Category View
struct EditCategoryView: View {
    @EnvironmentObject var gameSettings: GameSettings
    @Environment(\.dismiss) private var dismiss
    
    @Binding var category: Category
    @State private var categoryName: String
    @State private var categoryEmoji: String
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    init(category: Binding<Category>) {
        self._category = category
        self._categoryName = State(initialValue: category.wrappedValue.name)
        self._categoryEmoji = State(initialValue: category.wrappedValue.emoji)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 25) {
                        // Header
                        VStack(spacing: 10) {
                            Text(categoryEmoji)
                                .font(.system(size: 60))
                            
                            Text("KATEGORIE BEARBEITEN")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                        }
                        .padding(.top, 20)
                        
                        // Name
                        VStack(alignment: .leading, spacing: 15) {
                            SectionHeader(title: "Name", icon: "textformat")
                            
                            TextField("Kategorie-Name", text: $categoryName)
                                .textFieldStyle(ModernTextFieldStyle())
                        }
                        
                        // Emoji
                        VStack(alignment: .leading, spacing: 15) {
                            SectionHeader(title: "Emoji", icon: "face.smiling")
                            
                            TextField("Emoji (z.B. 🎮)", text: $categoryEmoji)
                                .textFieldStyle(ModernTextFieldStyle())
                        }
                        
                        // Action Buttons
                        VStack(spacing: 15) {
                            Button(action: saveChanges) {
                                GameActionButton(
                                    title: "Änderungen speichern",
                                    icon: "checkmark.circle.fill",
                                    isEnabled: canSave
                                )
                            }
                            .disabled(!canSave)
                            
                            Button("Abbrechen") {
                                dismiss()
                            }
                            .foregroundColor(.secondary)
                            .font(.headline)
                        }
                        .padding(.bottom, 30)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationBarHidden(true)
        }
        .alert("Fehler", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private var canSave: Bool {
        !categoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !categoryEmoji.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func saveChanges() {
        let name = categoryName.trimmingCharacters(in: .whitespacesAndNewlines)
        let emoji = categoryEmoji.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard canSave else {
            alertMessage = "Bitte füllen Sie alle Felder aus."
            showingAlert = true
            return
        }
        
        // Prüfen, ob Name bereits existiert (außer bei der aktuellen Kategorie)
        if gameSettings.categories.contains(where: { $0.name == name && $0.id != category.id }) {
            alertMessage = "Eine Kategorie mit diesem Namen existiert bereits."
            showingAlert = true
            return
        }
        
        category.name = name
        category.emoji = emoji
        gameSettings.updateCategory(category)
        dismiss()
    }
}

#Preview {
    ImposterCategoryDetailView(category: Category.defaultCategories[0])
        .environmentObject(GameSettings())
}
