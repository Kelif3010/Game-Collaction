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
    @State private var showPresetThemes = true // Default open for better UX
    
    private let presetThemes = [
        "Tiere", "Filme", "Musik", "Sport", "Essen", "Reisen",
        "Wissenschaft", "Geschichte", "Technologie", "Kunst",
        "Literatur", "Natur", "Weltraum", "Märchen", "Berufe"
    ]
    
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
                        Text(LocalizedStringKey("KI Generator"))
                            .font(.title2.bold())
                            .foregroundColor(.white)
                        Spacer()
                        Color.clear.frame(width: 44)
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    .padding(.bottom, 20)
                    
                    ScrollView {
                        VStack(spacing: 24) {
                            
                            // 1. Difficulty
                            VStack(alignment: .leading, spacing: 12) {
                                Label(LocalizedStringKey("Schwierigkeit"), systemImage: "gauge.medium")
                                    .font(.headline)
                                    .foregroundColor(.white.opacity(0.8))
                                
                                Picker(LocalizedStringKey("Schwierigkeit"), selection: $selectedDifficulty) {
                                    ForEach(CategoryDifficulty.allCases, id: \.self) { diff in
                                        Text(LocalizedStringKey(diff.rawValue)).tag(diff)
                                    }
                                }
                                .pickerStyle(.segmented)
                                .onAppear {
                                     UISegmentedControl.appearance().selectedSegmentTintColor = UIColor.darkGray
                                     UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
                                     UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor.lightGray], for: .normal)
                                }
                            }
                            .padding(.horizontal)
                            
                            // 2. Custom Theme Input
                            VStack(alignment: .leading, spacing: 12) {
                                Label(LocalizedStringKey("Themen wählen"), systemImage: "sparkles")
                                    .font(.headline)
                                    .foregroundColor(.white.opacity(0.8))
                                
                                HStack(spacing: 12) {
                                    TextField("", text: $newTheme, prompt: Text(LocalizedStringKey("Eigenes Thema (z.B. 80er)...")).foregroundColor(.gray))
                                        .padding()
                                        .background(Color.white.opacity(0.08))
                                        .cornerRadius(12)
                                        .foregroundColor(.white)
                                        .onSubmit { addCustomTheme() }
                                    
                                    Button(action: addCustomTheme) {
                                        Image(systemName: "plus")
                                            .font(.title2.bold())
                                            .foregroundColor(.white)
                                            .frame(width: 50, height: 50)
                                            .background(newTheme.trimmingCharacters(in: .whitespaces).isEmpty ? Color.gray.opacity(0.3) : Color.purple)
                                            .clipShape(Circle())
                                    }
                                    .disabled(newTheme.trimmingCharacters(in: .whitespaces).isEmpty)
                                }
                            }
                            .padding(.horizontal)
                            
                            // 3. Selected Themes Chips
                            if !selectedThemes.isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 10) {
                                        ForEach(selectedThemes, id: \.self) { theme in
                                            HStack(spacing: 6) {
                                                Text(LocalizedStringKey(theme))
                                                    .font(.subheadline.bold())
                                                    .foregroundColor(.white)
                                                Button {
                                                    toggleTheme(theme)
                                                } label: {
                                                    Image(systemName: "xmark")
                                                        .font(.caption)
                                                        .foregroundColor(.white.opacity(0.7))
                                                }
                                            }
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(
                                                LinearGradient(colors: [.purple, .blue], startPoint: .leading, endPoint: .trailing)
                                            )
                                            .cornerRadius(20)
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                            
                            // 4. Presets
                            VStack(alignment: .leading, spacing: 12) {
                                Button {
                                    withAnimation { showPresetThemes.toggle() }
                                } label: {
                                    HStack {
                                        Text(LocalizedStringKey("Vorschläge"))
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                        Image(systemName: "chevron.right")
                                            .rotationEffect(.degrees(showPresetThemes ? 90 : 0))
                                            .foregroundColor(.gray)
                                        Spacer()
                                    }
                                }
                                
                                if showPresetThemes {
                                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 10) {
                                        ForEach(presetThemes, id: \.self) { theme in
                                            Button {
                                                toggleTheme(theme)
                                            } label: {
                                                Text(LocalizedStringKey(theme))
                                                    .font(.caption)
                                                    .fontWeight(.medium)
                                                    .foregroundColor(selectedThemes.contains(theme) ? .white : .gray)
                                                    .frame(maxWidth: .infinity)
                                                    .padding(.vertical, 8)
                                                    .background(
                                                        selectedThemes.contains(theme) ?
                                                        Color.purple.opacity(0.6) :
                                                        Color.white.opacity(0.05)
                                                    )
                                                    .cornerRadius(10)
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 10)
                                                            .stroke(selectedThemes.contains(theme) ? Color.purple : Color.white.opacity(0.1), lineWidth: 1)
                                                    )
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                            
                            // 5. Generate Action
                            Button(action: generateCategories) {
                                HStack {
                                    if categoryManager.isGeneratingAI {
                                        ProgressView().tint(.white)
                                            .padding(.trailing, 8)
                                    } else {
                                        Image(systemName: "wand.and.stars")
                                            .font(.title2)
                                            .padding(.trailing, 4)
                                    }
                                    
                                    Text(categoryManager.isGeneratingAI ? String(localized: "Generiere...") : String(localized: "Generieren"))
                                        .font(.title3.bold())
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 60)
                                .background(
                                    canGenerate ?
                                    LinearGradient(colors: [.orange, .purple], startPoint: .leading, endPoint: .trailing) :
                                        LinearGradient(colors: [.gray.opacity(0.5), .gray.opacity(0.3)], startPoint: .leading, endPoint: .trailing)
                                )
                                .cornerRadius(20)
                                .shadow(color: canGenerate ? .purple.opacity(0.4) : .clear, radius: 10, x: 0, y: 5)
                            }
                            .disabled(!canGenerate)
                            .padding(.horizontal)
                            .padding(.top, 10)
                            
                            // Status / Error
                            if let error = categoryManager.aiErrorMessage {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.red)
                                    Text(error)
                                        .font(.caption)
                                        .foregroundColor(.red.opacity(0.9))
                                }
                                .padding()
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(12)
                                .padding(.horizontal)
                            }
                            
                            Spacer()
                        }
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    // Logic
    private var canGenerate: Bool {
        !selectedThemes.isEmpty && !categoryManager.isGeneratingAI
    }
    
    private func toggleTheme(_ theme: String) {
        withAnimation(.spring()) {
            if selectedThemes.contains(theme) {
                selectedThemes.removeAll { $0 == theme }
            } else {
                selectedThemes.append(theme)
            }
        }
    }
    
    private func addCustomTheme() {
        let trimmed = newTheme.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty && !selectedThemes.contains(trimmed) else { return }
        withAnimation {
            selectedThemes.append(trimmed)
            newTheme = ""
        }
    }
    
    private func generateCategories() {
        Task {
            await categoryManager.generateMultipleAICategories(
                themes: selectedThemes,
                difficulty: selectedDifficulty
            )
            presentationMode.wrappedValue.dismiss()
        }
    }
}

#Preview {
    AICategoryGeneratorView(categoryManager: CategoryManager())
}