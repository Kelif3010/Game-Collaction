//
//  CategoriesView.swift
//  Imposter
//
//  Created by Ken on 22.09.25.
//

import SwiftUI

struct CategoriesView: View {
    @EnvironmentObject var gameSettings: GameSettings
    @Environment(\.dismiss) private var dismiss
    @State private var showingAddCategory = false
    
    var body: some View {
        ZStack {
            // Hintergrund-Gradient wie im Hauptmenü
            LinearGradient(
                colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 30) {
                    // Header
                    VStack(spacing: 10) {
                        Image(systemName: "folder.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        Text("KATEGORIEN")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                    }
                    .padding(.top, 20)
                    
                    // Kategorien Grid
                    VStack(spacing: 20) {
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 15),
                            GridItem(.flexible(), spacing: 15)
                        ], spacing: 15) {
                            ForEach(gameSettings.categories) { category in
                                NavigationLink(destination: ImposterCategoryDetailView(category: category).environmentObject(gameSettings)) {
                                    ImposterCategoryCard(category: category) { }
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    
                    // Action Buttons
                    VStack(spacing: 15) {
                        Button(action: { showingAddCategory = true }) {
                            GameActionButton(
                                title: "Neue Kategorie erstellen",
                                icon: "plus.circle.fill",
                                isEnabled: true
                            )
                        }
                        
                        Button("Zurück zum Hauptmenü") {
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
        .sheet(isPresented: $showingAddCategory) {
            ImposterAddCategoryView()
                .environmentObject(gameSettings)
        }
    }
}

// MARK: - Add Category View
struct ImposterAddCategoryView: View {
    @EnvironmentObject var gameSettings: GameSettings
    @Environment(\.dismiss) private var dismiss
    
    @State private var categoryName: String = ""
    @State private var categoryEmoji: String = ""
    @State private var newWord: String = ""
    @State private var words: [String] = []
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
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
                            Image(systemName: "folder.badge.plus")
                                .font(.system(size: 50))
                                .foregroundColor(.purple)
                            
                            Text("NEUE KATEGORIE")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                        }
                        .padding(.top, 20)
                        
                        // Kategorie Name
                        VStack(alignment: .leading, spacing: 15) {
                            SectionHeader(title: "Kategorie-Name", icon: "textformat")
                            
                            TextField("z.B. Superhelden", text: $categoryName)
                                .textFieldStyle(ModernTextFieldStyle())
                        }
                        
                        // Kategorie Emoji
                        VStack(alignment: .leading, spacing: 15) {
                            SectionHeader(title: "Emoji", icon: "face.smiling")
                            
                            TextField("z.B. 🦸‍♂️", text: $categoryEmoji)
                                .textFieldStyle(ModernTextFieldStyle())
                        }
                        
                        // Begriffe hinzufügen
                        VStack(alignment: .leading, spacing: 15) {
                            SectionHeader(title: "Begriffe", icon: "list.bullet")
                            
                            HStack(spacing: 12) {
                                TextField("Begriff eingeben", text: $newWord)
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
                                            [Color.gray, Color.gray] : [Color.purple, Color.blue],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(22)
                                .disabled(newWord.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                                .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 2)
                            }
                            
                            // Wortliste
                            if !words.isEmpty {
                                LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], spacing: 10) {
                                    ForEach(Array(words.enumerated()), id: \.offset) { index, word in
                                        HStack {
                                            Text(word)
                                                .font(.subheadline)
                                                .lineLimit(1)
                                            
                                            Spacer()
                                            
                                            Button(action: { removeWord(at: index) }) {
                                                Image(systemName: "xmark.circle.fill")
                                                    .foregroundColor(.red)
                                                    .font(.caption)
                                            }
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(Color.purple.opacity(0.1))
                                        .cornerRadius(8)
                                    }
                                }
                            } else {
                                InfoCard(text: "Mindestens 4 Begriffe erforderlich", icon: "info.circle")
                            }
                        }
                        
                        // Action Buttons
                        VStack(spacing: 15) {
                            Button(action: saveCategory) {
                                GameActionButton(
                                    title: "Kategorie speichern",
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
    
    private func addWord() {
        let word = newWord.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if word.isEmpty {
            return
        }
        
        if words.contains(word) {
            alertMessage = "Dieser Begriff existiert bereits."
            showingAlert = true
            return
        }
        
        words.append(word)
        newWord = ""
    }
    
    private func removeWord(at index: Int) {
        if index < words.count {
            words.remove(at: index)
        }
    }
    
    private var canSave: Bool {
        return !categoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               !categoryEmoji.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               words.count >= 4
    }
    
    private func saveCategory() {
        guard canSave else {
            alertMessage = "Bitte geben Sie einen Kategorie-Namen, ein Emoji ein und fügen Sie mindestens 4 Begriffe hinzu."
            showingAlert = true
            return
        }
        
        let name = categoryName.trimmingCharacters(in: .whitespacesAndNewlines)
        let emoji = categoryEmoji.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if gameSettings.categories.contains(where: { $0.name == name }) {
            alertMessage = "Eine Kategorie mit diesem Namen existiert bereits."
            showingAlert = true
            return
        }
        
        let newCategory = Category(name: name, words: words, emoji: emoji, isCustom: true)
        gameSettings.addCustomCategory(newCategory)
        dismiss()
    }
}

#Preview {
    CategoriesView()
        .environmentObject(GameSettings())
}
