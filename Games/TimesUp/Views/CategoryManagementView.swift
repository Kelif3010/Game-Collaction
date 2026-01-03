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
    
    // HIER GEÄNDERT: TimesUpCategory
    @State private var selectedCategory: TimesUpCategory?
    
    var body: some View {
        NavigationView {
            ZStack {
                // Spielerischer Hintergrund - Dark Mode kompatibel
                LinearGradient(
                    colors: [
                        Color.orange.opacity(0.15),
                        Color.red.opacity(0.15),
                        Color(.systemBackground).opacity(0.8)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 25) {
                        // Header mit Icon
                        VStack(spacing: 15) {
                            Image(systemName: "folder.badge.gearshape")
                                .font(.system(size: 50))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.orange, .red],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            
                            Text("Kategorien verwalten")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.orange, .red],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        }
                        .padding(.top, 20)
                        
                        // Kategorien Liste
                        CategoriesListSection(categoryManager: categoryManager, selectedCategory: $selectedCategory)
                        
                        // Action Buttons
                        VStack(spacing: 15) {
                            // KI Generator Button
                            Button(action: {
                                showingAIGenerator = true
                            }) {
                                HStack {
                                    Image(systemName: "sparkles.rectangle.stack.fill")
                                        .font(.title2)
                                    Text("Mit KI generieren")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 60)
                                .background(
                                    LinearGradient(
                                        colors: [.purple, .pink, .orange],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(20)
                                .shadow(color: .purple.opacity(0.4), radius: 10, x: 0, y: 5)
                            }
                            
                            // Neue Kategorie hinzufügen Button
                            Button(action: {
                                showingAddCategory = true
                            }) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title2)
                                    Text("Manuell erstellen")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 60)
                                .background(
                                    LinearGradient(
                                        colors: [.orange, .red, .pink],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(20)
                                .shadow(color: .orange.opacity(0.4), radius: 10, x: 0, y: 5)
                            }
                        }
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
            .sheet(isPresented: $showingAddCategory) {
                AddCategoryView(categoryManager: categoryManager)
            }
            .sheet(isPresented: $showingAIGenerator) {
                AICategoryGeneratorView(categoryManager: categoryManager)
            }
            .sheet(item: $selectedCategory) { category in
                CategoryDetailView(category: category, categoryManager: categoryManager)
            }
        }
    }
}

// MARK: - Categories List Section
struct CategoriesListSection: View {
    @ObservedObject var categoryManager: CategoryManager
    // HIER GEÄNDERT: TimesUpCategory
    @Binding var selectedCategory: TimesUpCategory?
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Image(systemName: "list.bullet.rectangle.fill")
                    .font(.title2)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.orange, .red],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                Text("Alle Kategorien")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.orange, .red],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                Spacer()
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 15) {
                ForEach(categoryManager.categories) { category in
                    CategoryManagementCard(
                        category: category,
                        onTap: {
                            selectedCategory = category
                        },
                        onDelete: {
                            categoryManager.deleteCategory(category)
                        }
                    )
                }
            }
            
            if categoryManager.categories.isEmpty {
                VStack(spacing: 15) {
                    Image(systemName: "folder.badge.questionmark")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text("Keine Kategorien vorhanden")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("Füge deine erste Kategorie hinzu!")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .frame(minHeight: 120)
            }
        }
        .padding(20)
        .background(Color(.systemBackground).opacity(0.9))
        .cornerRadius(20)
        .shadow(color: .primary.opacity(0.12), radius: 8, x: 0, y: 4)
        .padding(.horizontal)
    }
}

// MARK: - Category Management Card
struct CategoryManagementCard: View {
    // HIER GEÄNDERT: TimesUpCategory
    let category: TimesUpCategory
    let onTap: () -> Void
    let onDelete: () -> Void
    @State private var showingDeleteAlert = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                HStack {
                    Spacer()
                    if category.type != .custom {
                        // Nur eigene Kategorien können gelöscht werden
                        Image(systemName: "lock.circle.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Button(action: {
                            showingDeleteAlert = true
                        }) {
                            Image(systemName: "trash.circle.fill")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                Image(systemName: category.type.systemImage)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [category.type.color, category.type.color.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                VStack(spacing: 4) {
                    Text(category.name)
                        .font(.caption)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .foregroundColor(category.type.color)
                    
                    Text("\(category.terms.count) Wörter")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .frame(height: 110)
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    colors: [category.type.color.opacity(0.2), category.type.color.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(15)
            .shadow(color: category.type.color.opacity(0.2), radius: 5, x: 0, y: 3)
        }
        .buttonStyle(PlainButtonStyle())
        .alert("Kategorie löschen?", isPresented: $showingDeleteAlert) {
            Button("Abbrechen", role: .cancel) { }
            Button("Löschen", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("Möchtest du die Kategorie '\(category.name)' und alle ihre Wörter wirklich löschen?")
        }
    }
}

#Preview {
    CategoryManagementView(categoryManager: CategoryManager())
}
