//
//  CategoryManagementView.swift
//  TimesUp
//
//  Created by Ken  on 23.09.25.
//

import SwiftUI

struct CategoryManagementView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var categoryManager: CategoryManager
    
    @State private var showingAddCategory = false
    @State private var showingAIGenerator = false
    @State private var selectedCategory: TimesUpCategory?
    @State private var showingDeleteAlert = false
    @State private var categoryToDelete: TimesUpCategory?
    
    // Theme Reference (copied locally to ensure preview works easily)
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
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundGradient.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Custom Header
                    HStack {
                        Button {
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
                        
                        Text(LocalizedStringKey("Kategorien verwalten"))
                            .font(.title2.bold())
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        // Placeholder for symmetry
                        Color.clear.frame(width: 44, height: 44)
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    .padding(.bottom, 20)
                    
                    ScrollView {
                        VStack(spacing: 20) {
                            
                            // MARK: - Actions Section
                            VStack(spacing: 12) {
                                // AI Generator Button
                                Button {
                                    showingAIGenerator = true
                                } label: {
                                    HStack(spacing: 14) {
                                        ZStack {
                                            Circle()
                                                .fill(LinearGradient(colors: [.purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing))
                                                .frame(width: 48, height: 48)
                                            Image(systemName: "sparkles")
                                                .font(.title3.bold())
                                                .foregroundColor(.white)
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(LocalizedStringKey("Mit KI generieren"))
                                                .font(.headline)
                                                .foregroundColor(.white)
                                            Text(LocalizedStringKey("Lass dir Begriffe vorschlagen"))
                                                .font(.caption)
                                                .foregroundColor(.white.opacity(0.7))
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.white.opacity(0.5))
                                    }
                                    .padding()
                                    .background(Color.white.opacity(0.08))
                                    .cornerRadius(18)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 18)
                                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                    )
                                }
                                
                                // Manual Add Button
                                Button {
                                    showingAddCategory = true
                                } label: {
                                    HStack(spacing: 14) {
                                        ZStack {
                                            Circle()
                                                .fill(LinearGradient(colors: [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing))
                                                .frame(width: 48, height: 48)
                                            Image(systemName: "plus")
                                                .font(.title3.bold())
                                                .foregroundColor(.white)
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(LocalizedStringKey("Manuell erstellen"))
                                                .font(.headline)
                                                .foregroundColor(.white)
                                            Text(LocalizedStringKey("Erstelle eine leere Kategorie"))
                                                .font(.caption)
                                                .foregroundColor(.white.opacity(0.7))
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.white.opacity(0.5))
                                    }
                                    .padding()
                                    .background(Color.white.opacity(0.08))
                                    .cornerRadius(18)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 18)
                                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                    )
                                }
                            }
                            .padding(.horizontal)
                            
                            // MARK: - List Section
                            VStack(alignment: .leading, spacing: 12) {
                                Text(LocalizedStringKey("Deine Kategorien"))
                                    .font(.headline)
                                    .foregroundColor(.white.opacity(0.8))
                                    .padding(.horizontal)
                                    .padding(.top, 10)
                                
                                LazyVStack(spacing: 12) {
                                    ForEach(categoryManager.categories) { category in
                                        ManagementRow(
                                            category: category,
                                            onTap: {
                                                selectedCategory = category
                                            },
                                            onDelete: {
                                                categoryToDelete = category
                                                showingDeleteAlert = true
                                            }
                                        )
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingAddCategory) {
                AddCategoryView(categoryManager: categoryManager)
            }
            .sheet(isPresented: $showingAIGenerator) {
                AICategoryGeneratorView(categoryManager: categoryManager)
            }
            .sheet(item: $selectedCategory) { category in
                CategoryDetailView(category: category, categoryManager: categoryManager)
            }
            .alert(LocalizedStringKey("Kategorie löschen?"), isPresented: $showingDeleteAlert) {
                Button(LocalizedStringKey("Abbrechen"), role: .cancel) {
                    categoryToDelete = nil
                }
                Button(LocalizedStringKey("Löschen"), role: .destructive) {
                    if let cat = categoryToDelete {
                        categoryManager.deleteCategory(cat)
                    }
                    categoryToDelete = nil
                }
            } message: {
                if let cat = categoryToDelete {
                    Text("Möchtest du '\(cat.name)' wirklich löschen?")
                } else {
                    Text(LocalizedStringKey("Möchtest du diese Kategorie löschen?"))
                }
            }
        }
    }
}

// Helper Row Component (Matches Settings Design)
private struct ManagementRow: View {
    let category: TimesUpCategory
    let onTap: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 14) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        LinearGradient(
                            colors: [category.type.color.opacity(0.3), category.type.color.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)
                
                Image(systemName: category.type.systemImage)
                    .font(.title3.bold())
                    .foregroundStyle(category.type.color)
            }
            
            // Text
            VStack(alignment: .leading, spacing: 4) {
                Text(LocalizedStringKey(category.name))
                    .font(.headline)
                    .foregroundColor(.white)
                
                (Text("\(category.terms.count) ") + Text("Begriffe"))
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
            
            // Actions
            HStack(spacing: 12) {
                Button(action: onTap) {
                    Image(systemName: "pencil.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                        .background(Color.white.clipShape(Circle()).padding(2))
                }
                
                if category.type == .custom {
                    Button(action: onDelete) {
                        Image(systemName: "trash.circle.fill")
                            .font(.title2)
                            .foregroundColor(.red)
                            .background(Color.white.clipShape(Circle()).padding(2))
                    }
                } else {
                    Image(systemName: "lock.circle.fill")
                        .font(.title2)
                        .foregroundColor(.gray.opacity(0.5))
                }
            }
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

#Preview {
    CategoryManagementView(categoryManager: CategoryManager())
}
