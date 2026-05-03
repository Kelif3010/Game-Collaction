//
//  CategoryDetailView.swift
//  Imposter
//
//  Created by Ken on 22.09.25.
//

import SwiftUI

struct ImposterCategoryDetailView: View {
    @Environment(GameSettings.self) var gameSettings
    @Environment(\.dismiss) private var dismiss
    
    @State var category: Category
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @State private var newWord: String = ""
    @State private var showingWordAlert = false
    @State private var wordToDelete: String?
    @State private var showingShareSheet = false // NEU
    
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
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .modifier(GlassCircleButtonBackground())
                    }
                    Spacer()
                    Text("Details")
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                    Spacer()
                    
                    Button { showingEditSheet = true } label: {
                        Image(systemName: "pencil")
                            .font(.title2.bold())
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.blue)
                            .clipShape(Circle())
                    }
                    
                    // Share Button (QR Code)
                    Button { showingShareSheet = true } label: {
                        Image(systemName: "qrcode")
                            .font(.title2.bold())
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.purple)
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal)
                .padding(.top, 10)
                .padding(.bottom, 20)
                
                ScrollView {
                    // ... (Content unchanged)
                    VStack(spacing: 24) {
                        // Info Card
                        VStack(spacing: 10) {
                            Text(category.emoji)
                                .font(.system(size: 80))
                                .shadow(color: .purple.opacity(0.5), radius: 20)
                            
                            Text(category.name)
                                .font(.largeTitle.bold())
                                .foregroundStyle(.white)
                            
                            if !category.isCustom {
                                Text("Standard-Kategorie")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.6))
                            }
                        }
                        .padding(.bottom, 10)
                        
                        // Add Word
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Neuer Begriff")
                                .font(.headline)
                                .foregroundStyle(.white.opacity(0.8))
                                .padding(.leading, 4)
                            
                            HStack(spacing: 12) {
                                TextField("", text: $newWord, prompt: Text("Wort eingeben...").foregroundStyle(.gray))
                                    .padding()
                                    .background(Color.white.opacity(0.08))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .foregroundStyle(.white)
                                    .onSubmit { addWord() }
                                
                                Button(action: addWord) {
                                    Image(systemName: "plus")
                                        .font(.title2.bold())
                                        .foregroundStyle(.white)
                                        .frame(width: 50, height: 50)
                                        .background(newWord.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray.opacity(0.3) : Color.green)
                                        .clipShape(Circle())
                                }
                                .disabled(newWord.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Word List
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Alle Begriffe")
                                    .font(.headline)
                                    .foregroundStyle(.white.opacity(0.8))
                                Spacer()
                                Text("\(category.words.count)")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.6))
                            }
                            .padding(.horizontal)
                            
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 12)], spacing: 12) {
                                ForEach(category.words, id: \.self) { word in
                                    HStack {
                                        Text(word)
                                            .font(.subheadline.bold())
                                            .foregroundStyle(.white)
                                            .lineLimit(1)
                                        
                                        Spacer()
                                        
                                        Button {
                                            wordToDelete = word
                                            showingWordAlert = true
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundStyle(.red.opacity(0.7))
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
                                    Image(systemName: "arrow.counterclockwise")
                                    Text("Kategorie zurücksetzen")
                                }
                                .font(.headline)
                                .foregroundStyle(.red)
                                .padding()
                                .background(Color.red.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
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
                .environment(gameSettings)
        }
        .sheet(isPresented: $showingShareSheet) { // NEU: Share Sheet
            QRCodeSheetView(category: category)
                .presentationDetents([.medium])
        }
        .alert("Kategorie zurücksetzen", isPresented: $showingDeleteAlert) {
            Button("Abbrechen", role: .cancel) { }
            Button("Zurücksetzen", role: .destructive) {
                gameSettings.removeCategory(category)
                dismiss()
            }
        } message: {
            Text("Willst du diese Kategorie wirklich zurücksetzen?")
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
    
    // Logic (unchanged)
    private func addWord() {
        let word = newWord.trimmingCharacters(in: .whitespacesAndNewlines)
        if !word.isEmpty, !category.words.contains(word) {
            promoteToCustomIfNeeded()
            category.addWord(word)
            gameSettings.updateCategory(category)
            newWord = ""
        }
    }
    
    private func removeWord(_ word: String) {
        promoteToCustomIfNeeded()
        category.removeWord(word)
        gameSettings.updateCategory(category)
    }

    private func promoteToCustomIfNeeded() {
        guard !category.isCustom else { return }
        category.isCustom = true
        if category.sourceName == nil {
            category.sourceName = category.name
        }
    }
}

// MARK: - QR Code Sheet View (NEU)
struct QRCodeSheetView: View {
    let category: Category
    @Environment(\.dismiss) var dismiss
    
    private var qrCodeImage: UIImage? {
        // Wir kodieren nur die essenziellen Daten, um den QR-Code klein zu halten
        struct ShareableCategory: Codable {
            let n: String // Name
            let e: String // Emoji
            let w: [String] // Words
        }
        let shareable = ShareableCategory(n: category.name, e: category.emoji, w: category.words)
        guard let jsonString = QRCodeService.shared.encodeForSharing(shareable) else { return nil }
        // Prefix hinzufügen, damit der Scanner weiß, was es ist
        let payload = "impcat:" + jsonString
        return QRCodeService.shared.generateQRCode(from: payload)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Teile diese Kategorie")
                .font(.headline)
                .padding(.top, 20)
            
            if let image = qrCodeImage {
                Image(uiImage: image)
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                    .padding()
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            } else {
                Text("Fehler beim Erstellen des QR-Codes")
                    .foregroundStyle(.red)
            }
            
            Text("Lasse einen Freund diesen Code in der App scannen.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Fertig") {
                dismiss()
            }
            .font(.headline)
            .padding()
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Edit Category View (Refactored)
struct EditCategoryView: View {
    @Environment(GameSettings.self) var gameSettings
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
        NavigationStack {
            ZStack {
                backgroundGradient.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    HStack {
                        Button { dismiss() } label: {
                            Image(systemName: "chevron.left")
                                .font(.title2.bold())
                                .foregroundStyle(.white)
                                .frame(width: 44, height: 44)
                                .modifier(GlassCircleButtonBackground())
                        }
                        Spacer()
                        Text("Bearbeiten")
                            .font(.title2.bold())
                            .foregroundStyle(.white)
                        Spacer()
                        Button("Fertig") { saveChanges() }
                            .font(.headline.bold())
                            .foregroundStyle(.green)
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    .padding(.bottom, 20)
                    
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Name")
                                .font(.headline)
                                .foregroundStyle(.white.opacity(0.8))
                            TextField("", text: $categoryName)
                                .padding()
                                .background(Color.white.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .foregroundStyle(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Emoji")
                                .font(.headline)
                                .foregroundStyle(.white.opacity(0.8))
                            TextField("", text: $categoryEmoji)
                                .padding()
                                .background(Color.white.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .foregroundStyle(.white)
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
        
        let wasCustom = category.isCustom
        let originalSourceName = category.sourceName ?? category.name
        category.name = name
        category.emoji = emoji
        if !wasCustom {
            category.isCustom = true
            category.sourceName = originalSourceName
        }
        gameSettings.updateCategory(category)
        dismiss()
    }
}

#Preview {
    NavigationStack {
        ImposterCategoryDetailView(category: Category.defaultCategories[0])
            .environment(GameSettings())
    }
}
