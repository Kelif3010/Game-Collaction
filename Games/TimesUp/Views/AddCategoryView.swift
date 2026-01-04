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
    
    // AI Vars
    @State private var showAIGenerator = false
    @State private var aiTheme = ""
    @State private var selectedDifficulty: CategoryDifficulty = .medium
    
    @StateObject private var translationManager = WordTranslationManager()
    @State private var isTranslatingTerms = false
    @State private var translatingTermId: DraftTerm.ID?

    // Theme
    private let backgroundGradient = LinearGradient(
        colors: [
            Color.black,
            Color(.systemGray6).opacity(0.3),
            Color.blue.opacity(0.15),
            Color.purple.opacity(0.1)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    var canSave: Bool {
        !categoryName.isEmpty && terms.count >= 5
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundGradient.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Button { presentationMode.wrappedValue.dismiss() } label: {
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
                        // Save Button
                        Button(action: saveCategory) {
                            Text("Speichern")
                                .font(.headline.bold())
                                .foregroundColor(canSave ? .green : .gray)
                        }
                        .disabled(!canSave)
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    .padding(.bottom, 20)
                    
                    ScrollView {
                        VStack(spacing: 24) {
                            
                            // 1. Name Input
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Name der Kategorie")
                                    .font(.headline)
                                    .foregroundColor(.white.opacity(0.8))
                                
                                TextField("", text: $categoryName, prompt: Text("z.B. 90er Hits").foregroundColor(.gray))
                                    .padding()
                                    .background(Color.white.opacity(0.08))
                                    .cornerRadius(12)
                                    .foregroundColor(.white)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                    )
                            }
                            .padding(.horizontal)
                            
                            // 2. AI Generator Toggle Section
                            VStack(alignment: .leading, spacing: 0) {
                                Button {
                                    withAnimation { showAIGenerator.toggle() }
                                } label: {
                                    HStack {
                                        Image(systemName: "sparkles")
                                            .foregroundColor(.purple)
                                        Text("KI-Unterstützung")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .rotationEffect(.degrees(showAIGenerator ? 90 : 0))
                                            .foregroundColor(.gray)
                                    }
                                    .padding()
                                    .background(Color.white.opacity(0.05))
                                }
                                
                                if showAIGenerator {
                                    VStack(spacing: 16) {
                                        TextField("", text: $aiTheme, prompt: Text("Thema für KI (z.B. Weltraum)").foregroundColor(.gray))
                                            .padding()
                                            .background(Color.black.opacity(0.3))
                                            .cornerRadius(10)
                                            .foregroundColor(.white)
                                        
                                        Picker("Schwierigkeit", selection: $selectedDifficulty) {
                                            ForEach(CategoryDifficulty.allCases, id: \.self) { diff in
                                                Text(diff.rawValue).tag(diff)
                                            }
                                        }
                                        .pickerStyle(.segmented)
                                        .onAppear {
                                             UISegmentedControl.appearance().selectedSegmentTintColor = UIColor.darkGray
                                             UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
                                             UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor.lightGray], for: .normal)
                                        }

                                        Button(action: generateAICategory) {
                                            HStack {
                                                if categoryManager.isGeneratingAI {
                                                    ProgressView().tint(.white)
                                                } else {
                                                    Image(systemName: "wand.and.stars")
                                                }
                                                Text(categoryManager.isGeneratingAI ? "Generiere..." : "Vorschläge generieren")
                                            }
                                            .font(.headline)
                                            .foregroundColor(.white)
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(aiTheme.isEmpty ? Color.gray.opacity(0.3) : Color.purple)
                                            .cornerRadius(12)
                                        }
                                        .disabled(aiTheme.isEmpty || categoryManager.isGeneratingAI)
                                    }
                                    .padding()
                                    .background(Color.white.opacity(0.02))
                                }
                            }
                            .cornerRadius(16)
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.1), lineWidth: 1))
                            .padding(.horizontal)

                            // 3. Add Words
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("Begriffe")
                                        .font(.headline)
                                        .foregroundColor(.white.opacity(0.8))
                                    Spacer()
                                    Text("\(terms.count) / 5 min.")
                                        .font(.caption)
                                        .foregroundColor(terms.count >= 5 ? .green : .orange)
                                }
                                
                                HStack(spacing: 12) {
                                    TextField("", text: $newTermText, prompt: Text("Neues Wort...").foregroundColor(.gray))
                                        .padding()
                                        .background(Color.white.opacity(0.08))
                                        .cornerRadius(12)
                                        .foregroundColor(.white)
                                        .onSubmit { addTerm() }
                                    
                                    Button(action: addTerm) {
                                        Image(systemName: "plus")
                                            .font(.title2.bold())
                                            .foregroundColor(.white)
                                            .frame(width: 50, height: 50)
                                            .background(newTermText.trimmingCharacters(in: .whitespaces).isEmpty ? Color.gray.opacity(0.3) : Color.blue)
                                            .clipShape(Circle())
                                    }
                                    .disabled(newTermText.trimmingCharacters(in: .whitespaces).isEmpty)
                                }
                                
                                // Translation All
                                if !terms.isEmpty {
                                    Button(action: translateAllTerms) {
                                        HStack {
                                            if isTranslatingTerms {
                                                ProgressView().tint(.blue)
                                            } else {
                                                Image(systemName: "globe")
                                            }
                                            Text("Alle fehlenden Englisch-Übersetzungen ergänzen")
                                                .font(.subheadline)
                                        }
                                        .foregroundColor(.blue)
                                        .padding(.vertical, 4)
                                    }
                                    .disabled(isTranslatingTerms)
                                }
                                
                                // List
                                LazyVStack(spacing: 10) {
                                    ForEach($terms) { $term in
                                        HStack {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(term.text)
                                                    .font(.body.bold())
                                                    .foregroundColor(.white)
                                                
                                                TextField("Englisch (optional)", text: Binding(
                                                    get: { term.englishTranslation ?? "" },
                                                    set: { term.englishTranslation = $0.isEmpty ? nil : $0 }
                                                ))
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                            }
                                            
                                            Spacer()
                                            
                                            // Single Translate
                                            Button {
                                                translateTerm(term.id)
                                            } label: {
                                                if translatingTermId == term.id {
                                                    ProgressView().tint(.blue).scaleEffect(0.7)
                                                } else {
                                                    Image(systemName: "globe")
                                                        .foregroundColor(.blue.opacity(0.7))
                                                }
                                            }
                                            .padding(.trailing, 8)

                                            // Delete
                                            Button {
                                                if let idx = terms.firstIndex(where: { $0.id == term.id }) {
                                                    terms.remove(at: idx)
                                                }
                                            } label: {
                                                Image(systemName: "xmark.circle.fill")
                                                    .foregroundColor(.red.opacity(0.6))
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
    }
    
    // Logic
    private func saveCategory() {
        categoryManager.addCategory(name: categoryName, terms: terms.map { Term(text: $0.text, englishTranslation: $0.englishTranslation) })
        presentationMode.wrappedValue.dismiss()
    }
    
    private func addTerm() {
        guard !newTermText.isEmpty else { return }
        terms.append(DraftTerm(text: newTermText))
        newTermText = ""
    }
    
    private func generateAICategory() {
        Task {
            await categoryManager.generateAICategory(
                theme: aiTheme,
                difficulty: selectedDifficulty
            )
            // Note: Since categoryManager adds it directly, we might want to intercept it or just populate fields?
            // The original implementation seemed to add it to the manager directly.
            // If we want to populate THIS form, we'd need different logic in Manager.
            // Assuming default behavior is fine (adds to list), user can then see it in list.
            // OR: If the user wants to EDIT the generated one before saving, that's complex.
            // Let's stick to standard behavior: It generates and adds it.
            presentationMode.wrappedValue.dismiss()
        }
    }

    private func translateAllTerms() {
        guard !isTranslatingTerms else { return }
        isTranslatingTerms = true
        Task {
            for index in terms.indices {
                let text = terms[index].text.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !text.isEmpty else { continue }
                if let english = terms[index].englishTranslation, !english.isEmpty { continue }
                
                let translation = await translationManager.translateToEnglish(text)
                await MainActor.run {
                    terms[index].englishTranslation = translation
                }
            }
            await MainActor.run { isTranslatingTerms = false }
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

struct DraftTerm: Identifiable {
    let id = UUID()
    var text: String
    var englishTranslation: String?
}