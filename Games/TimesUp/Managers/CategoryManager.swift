import Foundation
import Combine

@MainActor
class CategoryManager: ObservableObject {
    // Verwendung von TimesUpCategory statt Category
    @Published var categories: [TimesUpCategory] = []
    @Published var isGeneratingAI = false
    @Published var aiErrorMessage: String?
    @Published var isAIAvailable = false
    
    // DEBUG logging
    private let loggerPrefix = "🧩 CategoryManager"
    private var isDebugLoggingEnabled: Bool = true
    private var cancellables = Set<AnyCancellable>()
    private var currentLanguage: AppLanguage = .fallback
    private let defaultCustomCategoryNames: Set<String> = ["FSK 18", "18+"]
    
    private func log(_ message: String) {
        guard isDebugLoggingEnabled else { return }
        print("\(loggerPrefix) | \(message)")
    }
    
    private let aiGenerator = AICategoryGenerator()
    
    private let saveURL: URL = {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first ?? FileManager.default.temporaryDirectory
        return directory.appendingPathComponent("categories.json")
    }()
    
    init() {
        let language = Self.resolveLanguagePreference()
        currentLanguage = language
        loadSavedCategories()
        applyDefaultLanguage(language)
        setupAIObserver()
        log("Initialized. Categories loaded: \(categories.count). AI available: \(isAIAvailable)")
    }
    
    private func setupAIObserver() {
        aiGenerator.$isAIAvailable
            .receive(on: DispatchQueue.main)
            .sink { [weak self] available in
                self?.isAIAvailable = available
                self?.log("AI availability changed -> \(available)")
            }
            .store(in: &cancellables)
    }
    
    // MARK: - DEFAULT CATEGORIES
    
    /// Loads default categories for the specified language.
    /// Uses the external CategoryDefaultData struct to keep this file clean.
    private func loadDefaultCategories(for language: AppLanguage = .german) {
        log("Loading default categories for language: \(language.displayName)")
        categories = CategoryDefaultData.getData(for: language)
        
        log("Default categories loaded: \(categories.count)")
        categories.forEach { log("Kategorie '\($0.name)' hat \($0.terms.count) Begriffe") }
    }
    
    /// Public method to force reload defaults (e.g. when language changes).
    /// WARNING: Overwrites existing categories!
    func reloadDefaults(for language: AppLanguage) {
        log("Force reloading defaults for: \(language.displayName)")
        currentLanguage = language
        loadDefaultCategories(for: language)
        saveCategories()
        objectWillChange.send()
    }

    /// Updates default categories when the app language changes, without touching user-created ones.
    func updateLanguage(_ language: AppLanguage) {
        guard language != currentLanguage else { return }
        currentLanguage = language
        applyDefaultLanguage(language)
    }
    
    private func loadSavedCategories() {
        do {
            let data = try Data(contentsOf: saveURL)
            let decoded = try JSONDecoder().decode([TimesUpCategory].self, from: data)
            categories = decoded
            log("Saved categories loaded: \(decoded.count)")
        } catch {
            categories = []
            if (error as NSError).code != NSFileReadNoSuchFileError {
                log("Failed to load saved categories: \(error.localizedDescription)")
            } else {
                log("No saved categories found, will use defaults")
            }
        }
    }
    
    private func saveCategories() {
        do {
            let data = try JSONEncoder().encode(categories)
            try data.write(to: saveURL, options: .atomic)
            log("Categories saved (\(categories.count))")
        } catch {
            log("Failed to save categories: \(error.localizedDescription)")
        }
    }

    private func applyDefaultLanguage(_ language: AppLanguage) {
        let defaults = CategoryDefaultData.getData(for: language)
        guard !categories.isEmpty else {
            categories = defaults
            saveCategories()
            return
        }

        var updated = categories
        var didChange = false

        for defaultCategory in defaults {
            if defaultCategory.type != .custom {
                if let index = updated.firstIndex(where: { $0.type == defaultCategory.type }) {
                    if updated[index].name != defaultCategory.name ||
                        !termsMatch(updated[index].terms, defaultCategory.terms) {
                        updated[index].name = defaultCategory.name
                        updated[index].terms = defaultCategory.terms
                        didChange = true
                    }
                } else {
                    updated.append(defaultCategory)
                    didChange = true
                }
            } else if defaultCustomCategoryNames.contains(defaultCategory.name) {
                if let index = updated.firstIndex(where: { defaultCustomCategoryNames.contains($0.name) }) {
                    if updated[index].name != defaultCategory.name ||
                        !termsMatch(updated[index].terms, defaultCategory.terms) {
                        updated[index].name = defaultCategory.name
                        updated[index].terms = defaultCategory.terms
                        didChange = true
                    }
                }
            }
        }

        if didChange {
            categories = updated
            saveCategories()
        }
    }

    private func termsMatch(_ lhs: [Term], _ rhs: [Term]) -> Bool {
        guard lhs.count == rhs.count else { return false }
        return zip(lhs, rhs).allSatisfy { $0.text == $1.text && $0.englishTranslation == $1.englishTranslation }
    }

    private static func resolveLanguagePreference() -> AppLanguage {
        let defaults = UserDefaults.standard
        let useSystem: Bool
        if defaults.object(forKey: "useSystemLanguage") == nil {
            useSystem = true
        } else {
            useSystem = defaults.bool(forKey: "useSystemLanguage")
        }
        if useSystem {
            return AppLanguage.fromSystemPreferred()
        }
        let code = defaults.string(forKey: "selectedLanguageCode")
        return AppLanguage.from(code: code)
    }
    
    // MARK: - Category Management
    func addCategory(name: String, terms: [Term] = []) {
        log("addCategory requested -> name: \(name), terms: \(terms.count)")
        let newCategory = TimesUpCategory(name: name, type: .custom, terms: terms)
        categories.append(newCategory)
        saveCategories()
        log("addCategory completed. Total categories: \(categories.count)")
    }
    
    func deleteCategory(_ category: TimesUpCategory) {
        log("deleteCategory requested -> id: \(category.id), name: \(category.name), type: \(category.type)")
        // Nur eigene Kategorien können gelöscht werden
        guard category.type == .custom else { return }
        let beforeCount = categories.count
        categories.removeAll { $0.id == category.id }
        saveCategories()
        log("deleteCategory completed. Removed: \(beforeCount - categories.count). Total now: \(categories.count)")
    }
    
    func updateCategory(_ category: TimesUpCategory) {
        log("updateCategory requested -> id: \(category.id), name: \(category.name), terms: \(category.terms.count)")
        if let index = categories.firstIndex(where: { $0.id == category.id }) {
            categories[index] = category
            saveCategories()
            log("updateCategory completed for id: \(category.id)")
        }
    }
    
    // MARK: - Term Management
    func addTerm(to categoryId: UUID, term: String) {
        log("addTerm requested -> categoryId: \(categoryId), term: \(term)")
        guard let index = categories.firstIndex(where: { $0.id == categoryId }) else { return }
        let newTerm = Term(text: term)
        categories[index].terms.append(newTerm)
        saveCategories()
        log("addTerm completed. Category terms count: \(categories[index].terms.count)")
    }
    
    func deleteTerm(from categoryId: UUID, termId: UUID) {
        log("deleteTerm requested -> categoryId: \(categoryId), termId: \(termId)")
        guard let categoryIndex = categories.firstIndex(where: { $0.id == categoryId }) else { return }
        let before = categories[categoryIndex].terms.count
        categories[categoryIndex].terms.removeAll { $0.id == termId }
        saveCategories()
        log("deleteTerm completed. Removed: \(before - categories[categoryIndex].terms.count). Terms now: \(categories[categoryIndex].terms.count)")
    }
    
    func updateTerm(in categoryId: UUID, termId: UUID, newText: String) {
        log("updateTerm requested -> categoryId: \(categoryId), termId: \(termId), newText: \(newText)")
        guard let categoryIndex = categories.firstIndex(where: { $0.id == categoryId }),
              let termIndex = categories[categoryIndex].terms.firstIndex(where: { $0.id == termId }) else { return }
        categories[categoryIndex].terms[termIndex].text = newText
        saveCategories()
        log("updateTerm completed for termId: \(termId)")
    }
    
    // MARK: - AI Category Generation
    
    func generateAICategory(theme: String, difficulty: CategoryDifficulty = .medium) async {
        log("AI generateCategory start -> theme: \(theme), difficulty: \(difficulty.rawValue)")
        isGeneratingAI = true
        aiErrorMessage = nil
        
        do {
            let generatedCategory = try await aiGenerator.generateCategory(for: theme, difficulty: difficulty)
            log("AI generateCategory received -> name: \(generatedCategory.name), terms: \(generatedCategory.terms.count)")
            
            // Erstelle neue Kategorie aus AI-Generierung
            let newCategory = TimesUpCategory(
                name: generatedCategory.name,
                type: .custom,
                terms: generatedCategory.terms
            )
            
            await MainActor.run {
                categories.append(newCategory)
                self.log("AI generateCategory success. Categories total: \(self.categories.count)")
                self.saveCategories()
                isGeneratingAI = false
            }
        } catch {
            await MainActor.run {
                self.log("AI generateCategory error: \(error.localizedDescription)")
                aiErrorMessage = error.localizedDescription
                isGeneratingAI = false
            }
        }
    }
    
    func generateMultipleAICategories(themes: [String], difficulty: CategoryDifficulty = .medium) async {
        log("AI generateMultiple start -> themes: \(themes), difficulty: \(difficulty.rawValue)")
        isGeneratingAI = true
        aiErrorMessage = nil
        
        do {
            let generatedCategories = try await aiGenerator.generateMultipleCategories(themes: themes, difficulty: difficulty)
            log("AI generateMultiple received -> count: \(generatedCategories.count), termsPerCategory: \(generatedCategories.first?.terms.count ?? -1)")
            
            // Konvertiere zu TimesUpCategory-Objekten
            let newCategories = generatedCategories.map { generated in
                TimesUpCategory(name: generated.name, type: .custom, terms: generated.terms)
            }
            
            await MainActor.run {
                categories.append(contentsOf: newCategories)
                self.log("AI generateMultiple success. Categories total: \(self.categories.count)")
                self.saveCategories()
                isGeneratingAI = false
            }
        } catch {
            await MainActor.run {
                self.log("AI generateMultiple error: \(error.localizedDescription)")
                aiErrorMessage = error.localizedDescription
                isGeneratingAI = false
            }
        }
    }
    
    func generateAICategoryVariation(basedOn category: TimesUpCategory, difficulty: CategoryDifficulty = .medium) async {
        log("AI generateVariation start -> base: \(category.name) [\(category.id)], difficulty: \(difficulty.rawValue)")
        isGeneratingAI = true
        aiErrorMessage = nil
        
        do {
            let generatedCategory = try await aiGenerator.generateCategory(for: category.name, difficulty: difficulty)
            log("AI generateVariation received -> name: \(generatedCategory.name), terms: \(generatedCategory.terms.count)")
            
            let newCategory = TimesUpCategory(
                name: "\(generatedCategory.name) - Variation",
                type: .custom,
                terms: generatedCategory.terms
            )
            
            await MainActor.run {
                categories.append(newCategory)
                self.log("AI generateVariation success. Categories total: \(self.categories.count)")
                self.saveCategories()
                isGeneratingAI = false
            }
        } catch {
            await MainActor.run {
                self.log("AI generateVariation error: \(error.localizedDescription)")
                aiErrorMessage = error.localizedDescription
                isGeneratingAI = false
            }
        }
    }
    
    func clearAIError() {
        log("AI error cleared (was: \(aiErrorMessage ?? "nil"))")
        aiErrorMessage = nil
    }
}
