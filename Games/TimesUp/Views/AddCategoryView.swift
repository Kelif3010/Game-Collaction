//
//  AddCategoryView.swift
//  TimesUp
//
//  Created by Ken  on 23.09.25.
//

import SwiftUI

struct AddCategoryView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var categoryManager: CategoryManager

    @State private var categoryName = ""
    @State private var newTermText = ""
    @State private var terms: [DraftTerm] = []
    @State private var showAIGenerator = false
    @State private var aiTheme = ""
    @State private var selectedDifficulty: CategoryDifficulty = .medium
    @StateObject private var translationManager = WordTranslationManager()
    @State private var isTranslatingTerms = false
    @State private var translatingTermId: DraftTerm.ID?

    var canSave: Bool {
        !categoryName.isEmpty && terms.count >= 5
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Hintergrund
                LinearGradient(
                    colors: [
                        Color.purple.opacity(0.15), 
                        Color.pink.opacity(0.15),
                        Color(.systemBackground).opacity(0.8)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 25) {
                        // Header
                        VStack(spacing: 15) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 50))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.purple, .pink],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            
                            Text("Neue Kategorie")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.purple, .pink],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        }
                        .padding(.top, 20)
                        
                        // Kategorienname
                        CategoryNameSection(categoryName: $categoryName)
                        
                        // KI-Generator
                        AIGeneratorSection(
                            showAIGenerator: $showAIGenerator,
                            aiTheme: $aiTheme,
                            selectedDifficulty: $selectedDifficulty,
                            categoryManager: categoryManager
                        )
                        
                        // Wörter hinzufügen
                        TermsSection(
                            newTermText: $newTermText,
                            terms: $terms,
                            onTranslateAll: translateAllTerms,
                            onTranslateTerm: translateTerm,
                            isTranslatingAll: isTranslatingTerms,
                            translatingTermId: translatingTermId
                        )
                        
                        // Speichern Button
                        Button(action: saveCategory) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title2)
                                Text("Kategorie speichern")
                                    .font(.title2)
                                    .fontWeight(.bold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 60)
                            .background(canSave ? 
                                LinearGradient(colors: [.purple, .pink, .blue], startPoint: .leading, endPoint: .trailing) :
                                LinearGradient(colors: [.gray, .gray.opacity(0.8)], startPoint: .leading, endPoint: .trailing)
                            )
                            .cornerRadius(20)
                            .shadow(color: canSave ? .purple.opacity(0.4) : .clear, radius: 10, x: 0, y: 5)
                        }
                        .disabled(!canSave)
                        .padding(.horizontal)
                        .padding(.bottom, 30)
                    }
                }
            }
            .navigationBarHidden(true)
            .overlay(alignment: .topLeading) {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title)
                        .foregroundColor(.secondary)
                        .background(Color(.systemBackground))
                        .clipShape(Circle())
                        .shadow(color: .primary.opacity(0.2), radius: 2)
                }
                .padding(.top, 50)
                .padding(.leading, 20)
            }
        }
    }
    
    private func saveCategory() {
        categoryManager.addCategory(name: categoryName, terms: terms.map { Term(text: $0.text, englishTranslation: $0.englishTranslation) })
        presentationMode.wrappedValue.dismiss()
    }

    private func translateAllTerms() {
        guard !isTranslatingTerms else { return }
        isTranslatingTerms = true
        Task {
            for index in terms.indices {
                let text = terms[index].text.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !text.isEmpty else { continue }
                if let english = terms[index].englishTranslation, !english.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    continue
                }
                let translation = await translationManager.translateToEnglish(text)
                await MainActor.run {
                    terms[index].englishTranslation = translation
                }
            }
            await MainActor.run {
                isTranslatingTerms = false
            }
        }
    }

    private func translateTerm(_ id: DraftTerm.ID) {
        guard translatingTermId == nil else { return }
        guard let index = terms.firstIndex(where: { $0.id == id }) else { return }
        translatingTermId = id
        Task {
            let translation = await translationManager.translateToEnglish(terms[index].text)
            await MainActor.run {
                terms[index].englishTranslation = translation
                translatingTermId = nil
            }
        }
    }
}

// MARK: - Category Name Section
struct CategoryNameSection: View {
    @Binding var categoryName: String
    
    var body: some View {
        VStack(spacing: 15) {
            HStack {
                Image(systemName: "textformat")
                    .font(.title2)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .pink],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                Text("Kategoriename")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .pink],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                Spacer()
            }
            
            TextField("Name der Kategorie", text: $categoryName)
                .padding(.horizontal, 20)
                .padding(.vertical, 15)
                .background(Color(.systemBackground))
                .cornerRadius(15)
                .shadow(color: .primary.opacity(0.1), radius: 5, x: 0, y: 2)
                .onSubmit {
                    // Focus auf nächstes Eingabefeld könnte hier implementiert werden
                }
        }
        .padding(20)
        .background(Color(.systemBackground).opacity(0.9))
        .cornerRadius(20)
        .shadow(color: .primary.opacity(0.12), radius: 8, x: 0, y: 4)
        .padding(.horizontal)
    }
}

// MARK: - Terms Section
    struct TermsSection: View {
    @Binding var newTermText: String
    @Binding var terms: [DraftTerm]
    let onTranslateAll: () -> Void
    let onTranslateTerm: (DraftTerm.ID) -> Void
    let isTranslatingAll: Bool
    let translatingTermId: DraftTerm.ID?

    var body: some View {
        VStack(spacing: 15) {
            HStack {
                Image(systemName: "list.bullet.circle")
                    .font(.title2)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                Text("Wörter")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                Spacer()
                Text("\(terms.count) Wörter")
                    .font(.subheadline)
                    .foregroundColor(terms.count < 5 ? .red : .secondary)
                    .fontWeight(.medium)
            }

            HStack {
                Button(action: onTranslateAll) {
                    HStack(spacing: 6) {
                        if isTranslatingAll {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .scaleEffect(0.7)
                        } else {
                            Image(systemName: "globe")
                        }
                        Text(isTranslatingAll ? "Übersetze…" : "Alle übersetzen")
                            .font(.subheadline.bold())
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(isTranslatingAll || terms.isEmpty ? Color.gray.opacity(0.2) : Color.blue.opacity(0.2))
                    .foregroundColor(.primary)
                    .cornerRadius(12)
                }
                .disabled(isTranslatingAll || terms.isEmpty)

                Spacer()
            }

            // Wort hinzufügen
            HStack(spacing: 12) {
                TextField("Neues Wort", text: $newTermText)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(.systemBackground))
                    .cornerRadius(15)
                    .shadow(color: .primary.opacity(0.1), radius: 3, x: 0, y: 1)
                    .onSubmit {
                        addTerm()
                    }

                Button(action: addTerm) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(20)
                        .shadow(color: .blue.opacity(0.3), radius: 5, x: 0, y: 2)
                }
                .disabled(newTermText.isEmpty)
                .scaleEffect(newTermText.isEmpty ? 0.9 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: newTermText.isEmpty)
            }

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 10) {
                ForEach($terms) { $term in
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text(term.text)
                                .font(.body)
                                .fontWeight(.medium)
                            Spacer()
                            Button(action: {
                                onTranslateTerm(term.id)
                            }) {
                                if translatingTermId == term.id {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "globe")
                                        .foregroundColor(.blue)
                                }
                            }
                            .disabled(isTranslatingAll)
                        }

                        TextField("Englische Übersetzung", text: Binding(
                            get: { term.englishTranslation ?? "" },
                            set: {
                                term.englishTranslation = $0.isEmpty ? nil : $0
                            }
                        ))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(color: .primary.opacity(0.05), radius: 2, x: 0, y: 1)
                    }
                    .padding(.horizontal, 15)
                    .padding(.vertical, 10)
                    .background(Color(.systemBackground))
                    .cornerRadius(10)
                    .shadow(color: .primary.opacity(0.05), radius: 2, x: 0, y: 1)
                }
            }

            if terms.count < 5 {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("Mindestens 5 Wörter erforderlich")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(10)
            }
        }
        .padding(20)
        .background(Color(.systemBackground).opacity(0.9))
        .cornerRadius(20)
        .shadow(color: .primary.opacity(0.12), radius: 8, x: 0, y: 4)
        .padding(.horizontal)
    }

    private func addTerm() {
        guard !newTermText.isEmpty else { return }
        terms.append(DraftTerm(text: newTermText))
        newTermText = ""
    }
}

struct DraftTerm: Identifiable {
    let id = UUID()
    var text: String
    var englishTranslation: String?
}

// MARK: - AI Generator Section
struct AIGeneratorSection: View {
    @Binding var showAIGenerator: Bool
    @Binding var aiTheme: String
    @Binding var selectedDifficulty: CategoryDifficulty
    @ObservedObject var categoryManager: CategoryManager
    
    var body: some View {
        VStack(spacing: 15) {
            HStack {
                Image(systemName: "sparkles")
                    .font(.title2)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.orange, .pink],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                Text("KI-Generator")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.orange, .pink],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                Spacer()
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showAIGenerator.toggle()
                    }
                }) {
                    Image(systemName: showAIGenerator ? "chevron.up" : "chevron.down")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
            }
            
            if showAIGenerator {
                VStack(spacing: 15) {
                    // Theme Eingabe
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Thema der Kategorie")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        TextField("z.B. Tiere, Filme, Sport...", text: $aiTheme)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .shadow(color: .primary.opacity(0.1), radius: 3, x: 0, y: 1)
                    }
                    
                    // Schwierigkeit Auswahl
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Schwierigkeit")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Picker("Schwierigkeit", selection: $selectedDifficulty) {
                            ForEach(CategoryDifficulty.allCases, id: \.self) { difficulty in
                                Text(difficulty.rawValue).tag(difficulty)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    
                    // KI Generieren Button
                    Button(action: generateAICategory) {
                        HStack {
                            if categoryManager.isGeneratingAI {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "sparkles")
                                    .font(.title3)
                            }
                            
                            Text(categoryManager.isGeneratingAI ? "Generiere..." : "Mit KI generieren")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            LinearGradient(
                                colors: categoryManager.isGeneratingAI ? 
                                    [.gray, .gray.opacity(0.8)] : 
                                    [.orange, .pink, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(15)
                        .shadow(
                            color: categoryManager.isGeneratingAI ? .clear : .orange.opacity(0.3),
                            radius: 8,
                            x: 0,
                            y: 4
                        )
                    }
                    .disabled(categoryManager.isGeneratingAI || aiTheme.isEmpty)
                    
                    // KI-Status anzeigen
                    HStack {
                        Image(systemName: categoryManager.isAIAvailable ? "brain.head.profile" : "brain.head.profile.slash")
                            .foregroundColor(categoryManager.isAIAvailable ? .green : .orange)
                        Text(categoryManager.isAIAvailable ? "Apple KI verfügbar" : "Apple KI nicht verfügbar - Mock-Daten")
                            .font(.caption)
                            .foregroundColor(categoryManager.isAIAvailable ? .green : .orange)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background((categoryManager.isAIAvailable ? Color.green : Color.orange).opacity(0.1))
                    .cornerRadius(8)
                    
                    // Fehlermeldung anzeigen
                    if let errorMessage = categoryManager.aiErrorMessage {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text(errorMessage)
                                .font(.subheadline)
                                .foregroundColor(.red)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(10)
                    }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .padding(20)
        .background(Color(.systemBackground).opacity(0.9))
        .cornerRadius(20)
        .shadow(color: .primary.opacity(0.12), radius: 8, x: 0, y: 4)
        .padding(.horizontal)
    }
    
    private func generateAICategory() {
        Task {
            await categoryManager.generateAICategory(
                theme: aiTheme,
                difficulty: selectedDifficulty
            )
        }
    }
}

#Preview {
    AddCategoryView(categoryManager: CategoryManager())
}
