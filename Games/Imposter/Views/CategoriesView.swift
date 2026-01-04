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
    
    // Theme
    private let backgroundGradient = LinearGradient(
        colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Custom Header
                    HStack {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.title2.bold())
                                .foregroundColor(.white)
                                .frame(width: 36, height: 36)
                                .background(Color.white.opacity(0.1))
                                .clipShape(Circle())
                        }
                        
                        Spacer()
                        
                        Text("Kategorien")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Button {
                            showingAddCategory = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.title2.bold())
                                .foregroundColor(.white)
                                .frame(width: 36, height: 36)
                                .background(Color.blue)
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                    .padding(.bottom, 20)
                    
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(gameSettings.categories) { category in
                                NavigationLink(destination: ImposterCategoryDetailView(category: category).environmentObject(gameSettings)) {
                                    CategoryRow(category: category)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 40)
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showingAddCategory) {
                ImposterAddCategoryView()
                    .environmentObject(gameSettings)
            }
        }
    }
}

// MARK: - Category Row Component
private struct CategoryRow: View {
    let category: Category
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon / Emoji
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        LinearGradient(
                            colors: [Color.orange.opacity(0.2), Color.red.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                
                Text(category.emoji)
                    .font(.title)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(category.name)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("\(category.words.count) Begriffe")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.white.opacity(0.3))
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - Add Category View (Refactored)
struct ImposterAddCategoryView: View {
    @EnvironmentObject var gameSettings: GameSettings
    @Environment(\.dismiss) private var dismiss
    
    @State private var categoryName: String = ""
    @State private var categoryEmoji: String = ""
    @State private var newWord: String = ""
    @State private var words: [String] = []
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    // Theme
    private let backgroundGradient = LinearGradient(
        colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    var body: some View {
        NavigationView {
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
                        Text("Neue Kategorie")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                        Spacer()
                        Button("Speichern") {
                            saveCategory()
                        }
                        .font(.headline.bold())
                        .foregroundColor(canSave ? .green : .gray)
                        .disabled(!canSave)
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    .padding(.bottom, 20)
                    
                    ScrollView {
                        VStack(spacing: 24) {
                            
                            // 1. Details
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Details")
                                    .font(.headline)
                                    .foregroundColor(.white.opacity(0.8))
                                
                                TextField("", text: $categoryName, prompt: Text("Name (z.B. Superhelden)").foregroundColor(.gray))
                                    .padding()
                                    .background(Color.white.opacity(0.08))
                                    .cornerRadius(12)
                                    .foregroundColor(.white)
                                
                                TextField("", text: $categoryEmoji, prompt: Text("Emoji (z.B. 🦸‍♂️)").foregroundColor(.gray))
                                    .padding()
                                    .background(Color.white.opacity(0.08))
                                    .cornerRadius(12)
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal)
                            
                            // 2. Words
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("Begriffe")
                                        .font(.headline)
                                        .foregroundColor(.white.opacity(0.8))
                                    Spacer()
                                    Text("\(words.count) / 4 min.")
                                        .font(.caption)
                                        .foregroundColor(words.count >= 4 ? .green : .orange)
                                }
                                
                                HStack(spacing: 12) {
                                    TextField("", text: $newWord, prompt: Text("Neues Wort...").foregroundColor(.gray))
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
                                            .background(newWord.trimmingCharacters(in: .whitespaces).isEmpty ? Color.gray.opacity(0.3) : Color.blue)
                                            .clipShape(Circle())
                                    }
                                    .disabled(newWord.trimmingCharacters(in: .whitespaces).isEmpty)
                                }
                                
                                // Word List
                                LazyVStack(spacing: 10) {
                                    ForEach(Array(words.enumerated()), id: \.offset) { index, word in
                                        HStack {
                                            Text(word)
                                                .font(.body.bold())
                                                .foregroundColor(.white)
                                            
                                            Spacer()
                                            
                                            Button {
                                                removeWord(at: index)
                                            } label: {
                                                Image(systemName: "xmark.circle.fill")
                                                    .foregroundColor(.red.opacity(0.7))
                                            }
                                        }
                                        .padding()
                                        .background(Color.white.opacity(0.05))
                                        .cornerRadius(12)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding(.bottom, 40)
                    }
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
    
    // Logic
    private func addWord() {
        let word = newWord.trimmingCharacters(in: .whitespacesAndNewlines)
        if word.isEmpty { return }
        if words.contains(word) {
            alertMessage = "Dieser Begriff existiert bereits."
            showingAlert = true
            return
        }
        withAnimation {
            words.append(word)
        }
        newWord = ""
    }
    
    private func removeWord(at index: Int) {
        if index < words.count {
            withAnimation {
                words.remove(at: index)
            }
        }
    }
    
    private var canSave: Bool {
        return !categoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               !categoryEmoji.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               words.count >= 4
    }
    
    private func saveCategory() {
        guard canSave else { return }
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
