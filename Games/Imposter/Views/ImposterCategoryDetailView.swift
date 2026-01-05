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
    
    // Theme
    private let backgroundGradient = ImposterStyle.backgroundGradient
    
    var body: some View {
        ZStack {
            backgroundGradient.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                    Spacer()
                    Text("Details")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    Spacer()
                    
                    if category.isCustom {
                        Button { showingEditSheet = true } label: {
                            Image(systemName: "pencil")
                                .font(.title2.bold())
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(Color.blue)
                                .clipShape(Circle())
                        }
                    } else {
                        Color.clear.frame(width: 44, height: 44)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 10)
                .padding(.bottom, 20)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Info Card
                        VStack(spacing: 10) {
                            Text(category.emoji)
                                .font(.system(size: 80))
                                .shadow(color: .purple.opacity(0.5), radius: 20)
                            
                            Text(category.name)
                                .font(.largeTitle.bold())
                                .foregroundColor(.white)
                            
                            if !category.isCustom {
                                HStack {
                                    Image(systemName: "lock.fill")
                                    Text("Standard-Kategorie")
                                }
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                            }
                        }
                        .padding(.bottom, 10)
                        
                        // Add Word (if custom)
                        if category.isCustom {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Neuer Begriff")
                                    .font(.headline)
                                    .foregroundColor(.white.opacity(0.8))
                                    .padding(.leading, 4)
                                
                                HStack(spacing: 12) {
                                    TextField("", text: $newWord, prompt: Text("Wort eingeben...").foregroundColor(.gray))
                                        .padding()
                                        .background(Color.white.opacity(0.08))
                                        .cornerRadius(12)
                                        .foregroundColor(.white)
                                        .onSubmit { addWord() }
                                    
                                    Button(action: addWord) {
                                        Image(systemName: "plus")
                                            .font(.title2.bold())
                                            .foregroundColor(.white)
                                            .frame(width: 50, height: 50)
                                            .background(newWord.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray.opacity(0.3) : Color.green)
                                            .clipShape(Circle())
                                    }
                                    .disabled(newWord.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // Word List
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Alle Begriffe")
                                    .font(.headline)
                                    .foregroundColor(.white.opacity(0.8))
                                Spacer()
                                Text("\(category.words.count)")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            .padding(.horizontal)
                            
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 12)], spacing: 12) {
                                ForEach(category.words, id: \.self) { word in
                                    HStack {
                                        Text(word)
                                            .font(.subheadline.bold())
                                            .foregroundColor(.white)
                                            .lineLimit(1)
                                        
                                        Spacer()
                                        
                                        if category.isCustom {
                                            Button {
                                                wordToDelete = word
                                                showingWordAlert = true
                                            } label: {
                                                Image(systemName: "xmark.circle.fill")
                                                    .foregroundColor(.red.opacity(0.7))
                                            }
                                        }
                                    }
                                    .imposterRowStyle()
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // Delete Category Button
                        if category.isCustom {
                            Button(action: { showingDeleteAlert = true }) {
                                HStack {
                                    Image(systemName: "trash")
                                    Text("Kategorie löschen")
                                }
                                .font(.headline)
                                .foregroundColor(.red)
                                .padding()
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(12)
                            }
                            .padding(.top, 20)
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
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
            Text("Willst du diese Kategorie wirklich unwiderruflich löschen?")
        }
        .alert("Begriff löschen", isPresented: $showingWordAlert) {
            Button("Abbrechen", role: .cancel) { wordToDelete = nil }
            Button("Löschen", role: .destructive) {
                if let word = wordToDelete {
                    removeWord(word)
                }
                wordToDelete = nil
            }
        } message: {
            if let word = wordToDelete {
                Text("Soll der Begriff '\(word)' gelöscht werden?")
            }
        }
    }
    
    // Logic
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

// MARK: - Edit Category View (Refactored)
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
    
    private let backgroundGradient = ImposterStyle.backgroundGradient
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundGradient.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    HStack {
                        Button { dismiss() } label: {
                            Image(systemName: "chevron.left")
                                .font(.title2.bold())
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(Color.white.opacity(0.1))
                                .clipShape(Circle())
                        }
                        Spacer()
                        Text("Bearbeiten")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                        Spacer()
                        Button("Fertig") { saveChanges() }
                            .font(.headline.bold())
                            .foregroundColor(.green)
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    .padding(.bottom, 20)
                    
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Name")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.8))
                            TextField("", text: $categoryName)
                                .padding()
                                .background(Color.white.opacity(0.08))
                                .cornerRadius(12)
                                .foregroundColor(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Emoji")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.8))
                            TextField("", text: $categoryEmoji)
                                .padding()
                                .background(Color.white.opacity(0.08))
                                .cornerRadius(12)
                                .foregroundColor(.white)
                        }
                        Spacer()
                    }
                    .padding(.horizontal)
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
    
    private func saveChanges() {
        let name = categoryName.trimmingCharacters(in: .whitespacesAndNewlines)
        let emoji = categoryEmoji.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !name.isEmpty, !emoji.isEmpty else {
            alertMessage = "Bitte füllen Sie alle Felder aus."
            showingAlert = true
            return
        }
        
        if gameSettings.categories.contains(where: { $0.name == name && $0.id != category.id }) {
            alertMessage = "Name existiert bereits."
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
    NavigationStack {
        ImposterCategoryDetailView(category: Category.defaultCategories[0])
            .environmentObject(GameSettings())
    }
}
