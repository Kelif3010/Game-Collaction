//
//  CategoriesViewSimplified.swift
//  Imposter - Vereinfachte Version für Testing
//
//  Created by Ken on 22.09.25.
//

import SwiftUI

struct CategoriesViewSimplified: View {
    @EnvironmentObject var gameSettings: GameSettings
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    @State private var showingAddCategory = false
    @State private var selectedCategory: Category?
    
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
                        
                        Text("Tippen Sie auf eine Kategorie zum Bearbeiten")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                    
                    // Kategorien Grid
                    VStack(spacing: 20) {
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 15),
                            GridItem(.flexible(), spacing: 15)
                        ], spacing: 15) {
                            ForEach(gameSettings.categories) { category in
                                Button(action: {
                                    selectedCategory = category
                                }) {
                                    VStack(alignment: .leading, spacing: 12) {
                                        HStack {
                                            Text(category.emoji)
                                                .font(.title)
                                            
                                            Spacer()
                                            
                                            if category.isCustom {
                                                Text("Eigene")
                                                    .font(.caption)
                                                    .padding(.horizontal, 8)
                                                    .padding(.vertical, 4)
                                                    .background(Color.purple.opacity(0.2))
                                                    .cornerRadius(8)
                                                    .foregroundColor(.purple)
                                            }
                                        }
                                        
                                        Text(category.name)
                                            .font(.headline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.primary)
                                            .multilineTextAlignment(.leading)
                                        
                                        Text("\(category.words.count) Begriffe")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                        
                                        Text("✏️ Bearbeiten")
                                            .font(.caption)
                                            .foregroundColor(.blue)
                                            .italic()
                                        
                                        Spacer()
                                    }
                                    .padding(.horizontal, 18)
                                    .padding(.vertical, 16)
                                    .frame(minHeight: 140)
                                    .background(
                                        RoundedRectangle(cornerRadius: 15)
                                            .fill(colorScheme == .dark ? Color(.systemGray6) : Color.white)
                                            .shadow(color: .black.opacity(colorScheme == .dark ? 0.3 : 0.1), radius: 5, x: 0, y: 3)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 15)
                                            .stroke(Color.blue.opacity(0.3), lineWidth: colorScheme == .dark ? 1 : 2)
                                    )
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
        .sheet(item: $selectedCategory) { category in
            CategoryDetailViewSheet(category: category)
                .environmentObject(gameSettings)
        }
    }
}

// MARK: - Category Detail as Sheet
struct CategoryDetailViewSheet: View {
    @EnvironmentObject var gameSettings: GameSettings
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    @State var category: Category
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @State private var newWord: String = ""
    @State private var showingWordAlert = false
    @State private var wordToDelete: String?
    
    var body: some View {
        NavigationView {
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
                        
                        // Wort hinzufügen
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
                        
                        // Begriffe-Liste mit deutlichem Lösch-Button
                        VStack(alignment: .leading, spacing: 15) {
                            SectionHeader(title: "Begriffe", icon: "list.bullet")
                            
                            LazyVGrid(columns: [
                                GridItem(.adaptive(minimum: 140), spacing: 12)
                            ], spacing: 12) {
                                ForEach(category.words, id: \.self) { word in
                                    HStack {
                                        Text(word)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.primary)
                                            .lineLimit(2)
                                        
                                        Spacer()
                                        
                                        Button(action: {
                                            wordToDelete = word
                                            showingWordAlert = true
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.title3)
                                                .foregroundColor(.red)
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
                                            .stroke(Color.blue.opacity(colorScheme == .dark ? 0.5 : 0.3), lineWidth: 1)
                                    )
                                }
                            }
                        }
                        
                        // Action Buttons
                        VStack(spacing: 15) {
                            Button(action: { showingEditSheet = true }) {
                                GameActionButton(
                                    title: "Kategorie bearbeiten",
                                    icon: "pencil.circle.fill",
                                    isEnabled: true
                                )
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
                            } else {
                                InfoCard(text: "Standard-Kategorien können nicht gelöscht werden, aber Sie können Begriffe hinzufügen und entfernen", icon: "info.circle")
                            }
                        }
                        .padding(.bottom, 30)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationTitle("Kategorie bearbeiten")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fertig") {
                        dismiss()
                    }
                }
            }
        }
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
            Text("Sind Sie sicher, dass Sie die Kategorie '\(category.name)' löschen möchten? Diese Aktion kann nicht rückgängig gemacht werden.")
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
        
        if !word.isEmpty && !category.words.contains(word) {
            category.addWord(word)
            gameSettings.updateCategory(category)
            newWord = ""
        }
    }
    
    private func removeWord(_ word: String) {
        category.removeWord(word)
        gameSettings.updateCategory(category)
    }
}

#Preview {
    CategoriesViewSimplified()
        .environmentObject(GameSettings())
}
