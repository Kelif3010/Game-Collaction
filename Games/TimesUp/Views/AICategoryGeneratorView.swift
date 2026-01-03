//
//  AICategoryGeneratorView.swift
//  TimesUp
//
//  Created by Ken on 23.09.25.
//

import SwiftUI

struct AICategoryGeneratorView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var categoryManager: CategoryManager
    
    @State private var selectedThemes: [String] = []
    @State private var newTheme = ""
    @State private var selectedDifficulty: CategoryDifficulty = .medium
    @State private var showPresetThemes = false
    
    private let presetThemes = [
        "Tiere", "Filme", "Musik", "Sport", "Essen", "Reisen",
        "Wissenschaft", "Geschichte", "Technologie", "Kunst",
        "Literatur", "Natur", "Weltraum", "Märchen", "Berufe"
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                // Hintergrund
                LinearGradient(
                    colors: [
                        Color.orange.opacity(0.15),
                        Color.pink.opacity(0.15),
                        Color.purple.opacity(0.15),
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
                            Image(systemName: "sparkles.rectangle.stack")
                                .font(.system(size: 50))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.orange, .pink, .purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            
                            Text("KI-Kategorie Generator")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.orange, .pink, .purple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                            
                            Text("Lassen Sie die KI automatisch Kategorien mit Begriffen erstellen")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .padding(.top, 20)
                        
                        // Schwierigkeit Auswahl
                        DifficultySection(selectedDifficulty: $selectedDifficulty)
                        
                        // Theme Auswahl
                        ThemeSelectionSection(
                            selectedThemes: $selectedThemes,
                            newTheme: $newTheme,
                            showPresetThemes: $showPresetThemes,
                            presetThemes: presetThemes
                        )
                        
                        // Generieren Button
                        GenerateButton(
                            categoryManager: categoryManager,
                            selectedThemes: selectedThemes,
                            selectedDifficulty: selectedDifficulty
                        )
                        
                        // Status und Fehler
                        StatusSection(categoryManager: categoryManager)
                        
                        Spacer(minLength: 30)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Abbrechen") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Difficulty Section
struct DifficultySection: View {
    @Binding var selectedDifficulty: CategoryDifficulty
    
    var body: some View {
        VStack(spacing: 15) {
            HStack {
                Image(systemName: "slider.horizontal.3")
                    .font(.title2)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                Text("Schwierigkeit")
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
            }
            
            Picker("Schwierigkeit", selection: $selectedDifficulty) {
                ForEach(CategoryDifficulty.allCases, id: \.self) { difficulty in
                    VStack(alignment: .leading) {
                        Text(difficulty.rawValue)
                            .font(.headline)
                        Text(difficulty.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .tag(difficulty)
                }
            }
            .pickerStyle(WheelPickerStyle())
            .frame(height: 120)
        }
        .padding(20)
        .background(Color(.systemBackground).opacity(0.9))
        .cornerRadius(20)
        .shadow(color: .primary.opacity(0.12), radius: 8, x: 0, y: 4)
        .padding(.horizontal)
    }
}

// MARK: - Theme Selection Section
struct ThemeSelectionSection: View {
    @Binding var selectedThemes: [String]
    @Binding var newTheme: String
    @Binding var showPresetThemes: Bool
    let presetThemes: [String]
    
    var body: some View {
        VStack(spacing: 15) {
            HStack {
                Image(systemName: "list.bullet.rectangle")
                    .font(.title2)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.green, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                Text("Themen auswählen")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.green, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                Spacer()
            }
            
            // Preset Themes Toggle
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showPresetThemes.toggle()
                }
            }) {
                HStack {
                    Text("Vordefinierte Themen")
                        .font(.headline)
                    Spacer()
                    Image(systemName: showPresetThemes ? "chevron.up" : "chevron.down")
                        .font(.title3)
                }
                .foregroundColor(.primary)
                .padding(.vertical, 8)
            }
            
            if showPresetThemes {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 10) {
                    ForEach(presetThemes, id: \.self) { theme in
                        ThemeChip(
                            theme: theme,
                            isSelected: selectedThemes.contains(theme),
                            onTap: {
                                toggleTheme(theme)
                            }
                        )
                    }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
            
            // Custom Theme Input
            VStack(alignment: .leading, spacing: 8) {
                Text("Eigenes Thema hinzufügen")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                HStack {
                    TextField("z.B. Fantasy, Kochen, Autos...", text: $newTheme)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(color: .primary.opacity(0.1), radius: 3, x: 0, y: 1)
                    
                    Button(action: addCustomTheme) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(
                                LinearGradient(
                                    colors: [.green, .blue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(20)
                            .shadow(color: .green.opacity(0.3), radius: 5, x: 0, y: 2)
                    }
                    .disabled(newTheme.isEmpty)
                }
            }
            
            // Selected Themes
            if !selectedThemes.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Ausgewählte Themen (\(selectedThemes.count))")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 8) {
                        ForEach(selectedThemes, id: \.self) { theme in
                            ThemeChip(
                                theme: theme,
                                isSelected: true,
                                onTap: {
                                    toggleTheme(theme)
                                }
                            )
                        }
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
    
    private func toggleTheme(_ theme: String) {
        if selectedThemes.contains(theme) {
            selectedThemes.removeAll { $0 == theme }
        } else {
            selectedThemes.append(theme)
        }
    }
    
    private func addCustomTheme() {
        guard !newTheme.isEmpty && !selectedThemes.contains(newTheme) else { return }
        selectedThemes.append(newTheme)
        newTheme = ""
    }
}

// MARK: - Theme Chip
struct ThemeChip: View {
    let theme: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(theme)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    isSelected ?
                    LinearGradient(colors: [.green, .blue], startPoint: .leading, endPoint: .trailing) :
                    LinearGradient(colors: [Color(.systemGray6)], startPoint: .leading, endPoint: .trailing)
                )
                .cornerRadius(15)
                .shadow(
                    color: isSelected ? .green.opacity(0.3) : .clear,
                    radius: 3,
                    x: 0,
                    y: 1
                )
        }
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - Generate Button
struct GenerateButton: View {
    @ObservedObject var categoryManager: CategoryManager
    let selectedThemes: [String]
    let selectedDifficulty: CategoryDifficulty
    
    var canGenerate: Bool {
        !selectedThemes.isEmpty && !categoryManager.isGeneratingAI
    }
    
    var body: some View {
        Button(action: generateCategories) {
            HStack {
                if categoryManager.isGeneratingAI {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "sparkles.rectangle.stack.fill")
                        .font(.title2)
                }
                
                Text(categoryManager.isGeneratingAI ? 
                     "Generiere 1 Kategorie aus \(selectedThemes.count) Themen..." : 
                     "1 Kategorie aus \(selectedThemes.count) Themen generieren")
                    .font(.title2)
                    .fontWeight(.bold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(
                LinearGradient(
                    colors: canGenerate ? 
                        [.orange, .pink, .purple] : 
                        [.gray, .gray.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(20)
            .shadow(
                color: canGenerate ? .orange.opacity(0.4) : .clear,
                radius: 10,
                x: 0,
                y: 5
            )
        }
        .disabled(!canGenerate)
        .padding(.horizontal)
    }
    
    private func generateCategories() {
        Task {
            await categoryManager.generateMultipleAICategories(
                themes: selectedThemes,
                difficulty: selectedDifficulty
            )
        }
    }
}

// MARK: - Status Section
struct StatusSection: View {
    @ObservedObject var categoryManager: CategoryManager
    
    var body: some View {
        VStack(spacing: 10) {
            if categoryManager.isGeneratingAI {
                HStack {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                    Text("KI generiert Kategorien...")
                        .font(.headline)
                        .foregroundColor(.primary)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(15)
            }
            
            if let errorMessage = categoryManager.aiErrorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text(errorMessage)
                        .font(.subheadline)
                        .foregroundColor(.red)
                }
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(15)
            }
        }
        .padding(.horizontal)
    }
}

#Preview {
    AICategoryGeneratorView(categoryManager: CategoryManager())
}
