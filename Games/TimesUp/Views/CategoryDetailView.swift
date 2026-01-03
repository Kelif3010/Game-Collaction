//
//  CategoryDetailView.swift
//  TimesUp
//
//  Created by Ken  on 23.09.25.
//

import SwiftUI

struct CategoryDetailView: View {
    @Environment(\.presentationMode) var presentationMode
    
    // HIER GEÄNDERT: TimesUpCategory
    let category: TimesUpCategory
    @ObservedObject var categoryManager: CategoryManager
    
    @State private var newTermText = ""
    
    // HIER GEÄNDERT: TimesUpCategory
    @State private var editingCategory: TimesUpCategory
    
    // HIER GEÄNDERT: TimesUpCategory
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
                // Hintergrund mit Kategorie-Farbe
                LinearGradient(
                    colors: [
                        category.type.color.opacity(0.15),
                        category.type.color.opacity(0.25),
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
                            Image(systemName: category.type.systemImage)
                                .font(.system(size: 50))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [category.type.color, category.type.color.opacity(0.7)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            
                            VStack(spacing: 8) {
                                if canEdit {
                                    TextField("Kategoriename", text: $editingCategory.name)
                                        .font(.largeTitle)
                                        .fontWeight(.bold)
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [category.type.color, category.type.color.opacity(0.8)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .multilineTextAlignment(.center)
                                        .onSubmit {
                                            saveChanges()
                                        }
                                } else {
                                    Text(category.name)
                                        .font(.largeTitle)
                                        .fontWeight(.bold)
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [category.type.color, category.type.color.opacity(0.8)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                }
                                
                                HStack(spacing: 15) {
                                    Label("\(editingCategory.terms.count) Wörter", systemImage: "textformat.123")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    
                                    if !canEdit {
                                        Label("Systemkategorie", systemImage: "lock.fill")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                        .padding(.top, 20)
                        
                        // Wörter hinzufügen (nur bei eigenen Kategorien)
                        if canEdit {
                            AddTermSection(newTermText: $newTermText, onAdd: addTerm)
                        }
                        
                        // Wörter Liste
                        TermsListSection(
                            terms: editingCategory.terms,
                            categoryColor: category.type.color,
                            canEdit: canEdit,
                            onDelete: deleteTerm
                        )
                        
                        if canEdit && hasChanges {
                            // Änderungen speichern Button
                            Button(action: saveChanges) {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.title2)
                                    Text("Änderungen speichern")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 60)
                                .background(
                                    LinearGradient(
                                        colors: [category.type.color, category.type.color.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(20)
                                .shadow(color: category.type.color.opacity(0.4), radius: 10, x: 0, y: 5)
                            }
                            .padding(.horizontal)
                        }
                        
                        Spacer(minLength: 30)
                    }
                }
            }
            .navigationBarHidden(true)
            .overlay(alignment: .topLeading) {
                Button(action: {
                    if hasChanges && canEdit {
                        saveChanges()
                    }
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: hasChanges && canEdit ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.title)
                        .foregroundColor(hasChanges && canEdit ? .green : .secondary)
                        .background(Color(.systemBackground))
                        .clipShape(Circle())
                        .shadow(color: .primary.opacity(0.2), radius: 2)
                }
                .padding(.top, 50)
                .padding(.leading, 20)
            }
        }
    }
    
    // MARK: - Helper Properties
    private var hasChanges: Bool {
        editingCategory.name != category.name ||
        editingCategory.terms.count != category.terms.count ||
        !editingCategory.terms.elementsEqual(category.terms, by: { $0.text == $1.text })
    }
    
    // MARK: - Actions
    private func addTerm() {
        guard !newTermText.isEmpty else { return }
        let newTerm = Term(text: newTermText)
        editingCategory.terms.append(newTerm)
        newTermText = ""
    }
    
    private func deleteTerm(at indexSet: IndexSet) {
        editingCategory.terms.remove(atOffsets: indexSet)
    }
    
    private func saveChanges() {
        categoryManager.updateCategory(editingCategory)
    }
}

// MARK: - Add Term Section
struct AddTermSection: View {
    @Binding var newTermText: String
    let onAdd: () -> Void
    
    var body: some View {
        VStack(spacing: 15) {
            HStack {
                Image(systemName: "plus.circle")
                    .font(.title2)
                    .foregroundColor(.blue)
                Text("Wort hinzufügen")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                Spacer()
            }
            
            HStack(spacing: 12) {
                TextField("Neues Wort", text: $newTermText)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(.systemBackground))
                    .cornerRadius(15)
                    .shadow(color: .primary.opacity(0.1), radius: 3, x: 0, y: 1)
                    .onSubmit {
                        onAdd()
                    }
                
                Button(action: onAdd) {
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
        }
        .padding(20)
        .background(Color(.systemBackground).opacity(0.9))
        .cornerRadius(20)
        .shadow(color: .primary.opacity(0.12), radius: 8, x: 0, y: 4)
        .padding(.horizontal)
    }
}

// MARK: - Terms List Section
struct TermsListSection: View {
    let terms: [Term]
    let categoryColor: Color
    let canEdit: Bool
    let onDelete: (IndexSet) -> Void
    
    var body: some View {
        VStack(spacing: 15) {
            HStack {
                Image(systemName: "list.bullet.rectangle")
                    .font(.title2)
                    .foregroundColor(categoryColor)
                Text("Alle Wörter")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(categoryColor)
                Spacer()
            }
            
            if terms.isEmpty {
                VStack(spacing: 15) {
                    Image(systemName: "text.badge.xmark")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text("Keine Wörter vorhanden")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    if canEdit {
                        Text("Füge dein erstes Wort hinzu!")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(minHeight: 100)
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(Array(terms.enumerated()), id: \.element.id) { index, term in
                        HStack {
                            Text(term.text)
                                .font(.body)
                                .fontWeight(.medium)
                            Spacer()
                            
                            if canEdit {
                                Button(action: {
                                    onDelete(IndexSet(integer: index))
                                }) {
                                    Image(systemName: "trash.circle.fill")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                            }
                        }
                        .padding(.horizontal, 15)
                        .padding(.vertical, 12)
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(color: .primary.opacity(0.08), radius: 3, x: 0, y: 2)
                    }
                }
            }
        }
        .padding(20)
        .background(Color(.systemBackground).opacity(0.9))
        .cornerRadius(20)
        .shadow(color: .primary.opacity(0.12), radius: 8, x: 0, y: 4)
        .padding(.horizontal)
    }
}

#Preview {
    // HIER GEÄNDERT: TimesUpCategory
    CategoryDetailView(category: TimesUpCategory(name: "Test", type: .custom, terms: [Term(text: "Test1"), Term(text: "Test2")]), categoryManager: CategoryManager())
}
