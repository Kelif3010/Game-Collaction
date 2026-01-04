//
//  CategoryDetailView.swift
//  TimesUp
//
//  Created by Ken  on 23.09.25.
//

import SwiftUI

struct CategoryDetailView: View {
    @Environment(\.presentationMode) var presentationMode
    
    let category: TimesUpCategory
    @ObservedObject var categoryManager: CategoryManager
    
    @State private var newTermText = ""
    @State private var editingCategory: TimesUpCategory
    
    // Theme Reference
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
    
    init(category: TimesUpCategory, categoryManager: CategoryManager) {
        self.category = category
        self.categoryManager = categoryManager
        self._editingCategory = State(initialValue: category)
    }
    
    var canEdit: Bool {
        category.type == .custom
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                backgroundGradient.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Button {
                            if hasChanges && canEdit {
                                saveChanges()
                            }
                            presentationMode.wrappedValue.dismiss()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.title2.bold())
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(Color.white.opacity(0.1))
                                .clipShape(Circle())
                        }
                        
                        Spacer()
                        
                        Text(canEdit ? "Bearbeiten" : "Details")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        // Save Button (only if changes)
                        if canEdit && hasChanges {
                            Button(action: saveChanges) {
                                Image(systemName: "checkmark")
                                    .font(.title2.bold())
                                    .foregroundColor(.green)
                                    .frame(width: 44, height: 44)
                                    .background(Color.white.opacity(0.1))
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
                            // Category Icon & Name Header
                            VStack(spacing: 16) {
                                ZStack {
                                    Circle()
                                        .fill(category.type.color.opacity(0.2))
                                        .frame(width: 100, height: 100)
                                    Image(systemName: category.type.systemImage)
                                        .font(.system(size: 40))
                                        .foregroundStyle(category.type.color)
                                }
                                .shadow(color: category.type.color.opacity(0.5), radius: 20)
                                
                                VStack(spacing: 8) {
                                    if canEdit {
                                        TextField("Name", text: $editingCategory.name)
                                            .font(.title.bold())
                                            .multilineTextAlignment(.center)
                                            .foregroundColor(.white)
                                            .padding(.horizontal)
                                            .padding(.vertical, 8)
                                            .background(Color.white.opacity(0.1))
                                            .cornerRadius(12)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                            )
                                            .padding(.horizontal, 40)
                                    } else {
                                        Text(category.name)
                                            .font(.title.bold())
                                            .foregroundColor(.white)
                                    }
                                    
                                    HStack(spacing: 12) {
                                        Label("\(editingCategory.terms.count) Wörter", systemImage: "textformat.123")
                                        if !canEdit {
                                            Label("Systemkategorie", systemImage: "lock.fill")
                                        }
                                    }
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.6))
                                }
                            }
                            .padding(.bottom, 10)
                            
                            // Add Word Section
                            if canEdit {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Neues Wort")
                                        .font(.headline)
                                        .foregroundColor(.white.opacity(0.8))
                                        .padding(.leading, 4)
                                    
                                    HStack(spacing: 12) {
                                        TextField("", text: $newTermText, prompt: Text("Wort eingeben...").foregroundColor(.gray))
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
                                                .background(newTermText.trimmingCharacters(in: .whitespaces).isEmpty ? Color.gray.opacity(0.3) : category.type.color)
                                                .clipShape(Circle())
                                        }
                                        .disabled(newTermText.trimmingCharacters(in: .whitespaces).isEmpty)
                                    }
                                }
                                .padding(.horizontal)
                            }
                            
                            // Terms List
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Begriffe")
                                    .font(.headline)
                                    .foregroundColor(.white.opacity(0.8))
                                    .padding(.leading, 20)
                                
                                if editingCategory.terms.isEmpty {
                                    Text("Keine Wörter vorhanden.")
                                        .foregroundColor(.gray)
                                        .italic()
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                } else {
                                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
                                        ForEach(Array(editingCategory.terms.enumerated()), id: \.element.id) { index, term in
                                            HStack {
                                                Text(term.text)
                                                    .font(.subheadline.bold())
                                                    .foregroundColor(.white)
                                                    .lineLimit(1)
                                                
                                                Spacer()
                                                
                                                if canEdit {
                                                    Button {
                                                        deleteTerm(at: IndexSet(integer: index))
                                                    } label: {
                                                        Image(systemName: "xmark.circle.fill")
                                                            .foregroundColor(.red.opacity(0.8))
                                                    }
                                                }
                                            }
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 10)
                                            .background(Color.white.opacity(0.08))
                                            .cornerRadius(12)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color.white.opacity(0.05), lineWidth: 1)
                                            )
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    // MARK: - Logic
    
    private var hasChanges: Bool {
        editingCategory.name != category.name ||
        editingCategory.terms.count != category.terms.count ||
        !editingCategory.terms.elementsEqual(category.terms, by: { $0.text == $1.text })
    }
    
    private func addTerm() {
        guard !newTermText.isEmpty else { return }
        let newTerm = Term(text: newTermText)
        withAnimation {
            editingCategory.terms.append(newTerm)
        }
        newTermText = ""
    }
    
    private func deleteTerm(at indexSet: IndexSet) {
        withAnimation {
            editingCategory.terms.remove(atOffsets: indexSet)
        }
    }
    
    private func saveChanges() {
        categoryManager.updateCategory(editingCategory)
    }
}