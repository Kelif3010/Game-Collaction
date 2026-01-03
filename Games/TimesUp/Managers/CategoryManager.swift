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
        loadSavedCategories()
        if categories.isEmpty {
            loadDefaultCategories()
            saveCategories()
        }
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
    private func loadDefaultCategories() {
        
        // 1. SEHR LEICHT (Grün)
        let greenTerms = [
            "Katze", "Hund", "Maus", "Fisch", "Vogel", "Hase", "Kuh", "Pferd", "Schaf", "Schwein",
            "Ente", "Huhn", "Bär", "Löwe", "Tiger", "Elefant", "Giraffe", "Affe", "Pinguin", "Frosch",
            "Schmetterling", "Biene", "Spinne", "Schlange", "Krokodil", "Nashorn", "Zebra", "Esel", "Hamster", "Papagei",
            "Marienkäfer", "Eichhörnchen", "Fuchs", "Wolf", "Igel", "Schildkröte", "Wal", "Delfin", "Hai", "Robbe",
            "Apfel", "Banane", "Traube", "Erdbeere", "Wassermelone", "Brot", "Käse", "Pizza", "Eis", "Kuchen",
            "Milch", "Wasser", "Saft", "Ei", "Wurst", "Pommes", "Nudel", "Tomate", "Gurke", "Karotte",
            "Schokolade", "Keks", "Bonbon", "Suppe", "Salat", "Marmelade", "Honig", "Butter", "Joghurt", "Birne",
            "Auto", "Bus", "Zug", "Flugzeug", "Schiff", "Fahrrad", "Roller", "Ball", "Ballon", "Puppe",
            "Teddy", "Rucksack", "Schuh", "Mütze", "Jacke", "Hose", "Kleid", "Brille", "Uhr", "Schlüssel",
            "Lampe", "Tisch", "Stuhl", "Bett", "Sofa", "Tür", "Fenster", "Haus", "Dach", "Treppe",
            "Zahnbürste", "Seife", "Handtuch", "Kamm", "Buch", "Stift", "Teller", "Gabel", "Löffel", "Glas",
            "Sonne", "Mond", "Stern", "Regen", "Schnee", "Regenbogen", "Wolke", "Baum", "Blume", "Blatt",
            "Stein", "Sand", "Meer", "Strand", "See", "Berg", "Wald", "Wiese", "Feuer", "Wind"
        ].map { Term(text: $0) }

        // 2. LEICHT (Gelb)
        let yellowTerms = [
            "Feuerwehr", "Polizei", "Arzt", "Bäcker", "Lehrer", "Gärtner", "Koch", "Pilot", "Verkäufer", "Postbote",
            "Astronaut", "Clown", "Zauberer", "Pirat", "Ritter", "König", "Prinzessin", "Hexe", "Fee", "Vampir",
            "Detektiv", "Tierarzt", "Bauarbeiter", "Friseur", "Kellner", "Maler", "Sänger", "Tänzer", "Bauer", "Kapitän",
            "Harry Potter", "Mickey Maus", "Spongebob", "Spiderman", "Batman", "Superman", "Elsa", "Pikachu", "Super Mario", "Darth Vader",
            "Simba", "Nemo", "Shrek", "Barbie", "James Bond", "Tarzan", "Pippi Langstrumpf", "Pinocchio", "Schneewittchen", "Aschenputtel",
            "Minions", "Yoda", "Hulk", "Iron Man", "Rotkäppchen", "Froschkönig", "Hänsel und Gretel", "Biene Maja", "Wickie", "Garfield",
            "Fußball", "Tennis", "Basketball", "Schwimmen", "Tanzen", "Reiten", "Malen", "Singen", "Kochen", "Lesen",
            "Angeln", "Wandern", "Skifahren", "Zelten", "Bowling", "Karate", "Schach", "Yoga", "Joggen", "Boxen",
            "Kino", "Zoo", "Schule", "Kirche", "Burg", "Schloss", "Insel", "Bauernhof", "Supermarkt", "Krankenhaus",
            "Fernseher", "Computer", "Handy", "Tablet", "Kamera", "Gitarre", "Klavier", "Trommel", "Geige", "Flöte",
            "Roboter", "Rakete", "Ufo", "Geist", "Mumie", "Monster", "Alien", "Drache", "Einhorn", "Meerjungfrau"
        ].map { Term(text: $0) }

        // 3. MITTEL (Rot)
        let redTerms = [
            "Deutschland", "Italien", "Spanien", "Frankreich", "USA", "China", "Japan", "Russland", "Brasilien", "Australien",
            "Berlin", "Paris", "London", "Rom", "New York", "Tokio", "Mallorca", "Hawaii", "Las Vegas", "Hollywood",
            "Ägypten", "Türkei", "Griechenland", "Schweden", "Schweiz", "Österreich", "Kanada", "Indien", "Mexiko", "Polen",
            "Eiffelturm", "Freiheitsstatue", "Kolosseum", "Chinesische Mauer", "Pyramiden", "Big Ben", "Brandenburger Tor", "Schiefer Turm von Pisa", "Taj Mahal", "Mount Everest",
            "Niagarafälle", "Grand Canyon", "Amazonas", "Nordpol", "Südpol", "Sahara", "Atlantik", "Pazifik", "Venedig", "Alpen",
            "Angela Merkel", "Donald Trump", "Barack Obama", "Albert Einstein", "Mozart", "Beethoven", "Michael Jackson", "Elvis Presley", "Madonna", "Beyoncé",
            "Cristiano Ronaldo", "Lionel Messi", "Arnold Schwarzenegger", "Brad Pitt", "Angelina Jolie", "Leonardo DiCaprio", "Bill Gates", "Mark Zuckerberg", "Steve Jobs", "Elon Musk",
            "Papst", "Queen Elizabeth", "Kleopatra", "Caesar", "Napoleon", "Hitler", "Jesus", "Buddha", "Ghandi", "Martin Luther King",
            "Coca Cola", "McDonalds", "Burger King", "Apple", "Samsung", "Google", "Facebook", "Amazon", "Nike", "Adidas",
            "Ikea", "Lego", "Disney", "Netflix", "YouTube", "Mercedes", "BMW", "Audi", "Porsche", "Ferrari",
            "Volkswagen", "Tesla", "Red Bull", "Nutealla", "Haribo", "PlayStation", "Nintendo", "Xbox", "Starbucks", "Rolex"
        ].map { Term(text: $0) }

        // 4. SCHWER (Blau)
        let blueTerms = [
            "Atom", "Molekül", "DNA", "Genetik", "Evolution", "Schwerkraft", "Relativitätstheorie", "Photosynthese", "Sauerstoff", "Kohlendioxid",
            "Mikroskop", "Teleskop", "Satellit", "Algorithmus", "Künstliche Intelligenz", "Blockchain", "Kryptowährung", "Quantenphysik", "Schwarzes Loch", "Supernova",
            "Meteorit", "Asteroid", "Komet", "Galaxie", "Universum", "Vakuum", "Radioaktivität", "Kernfusion", "Ozonloch", "Klimawandel",
            "Demokratie", "Diktatur", "Monarchie", "Kommunismus", "Kapitalismus", "Revolution", "Inflation", "Globalisierung", "Mauerfall", "Weltkrieg",
            "Mittelalter", "Renaissance", "Antike", "Steinzeit", "Industrialisierung", "Kolonialismus", "Sklaverei", "Holocaust", "Apartheid", "Bürgerkrieg",
            "Verfassung", "Parlament", "Senat", "Minister", "Präsident", "Kanzler", "Botschafter", "Spion", "Diplomat", "Veto",
            "Goethe", "Schiller", "Shakespeare", "Da Vinci", "Picasso", "Van Gogh", "Dali", "Rembrandt", "Michelangelo", "Monet",
            "Mona Lisa", "Der Schrei", "Bibel", "Koran", "Tora", "Philosophie", "Psychologie", "Soziologie", "Archäologie", "Astronomie",
            "Oper", "Ballett", "Theater", "Orchester", "Sinfonie", "Literatur", "Poesie", "Roman", "Drama", "Komödie",
            "Kaleidoskop", "Labyrinth", "Oase", "Fata Morgana", "Echo", "Schatten", "Silhouette", "Horizont", "Vulkanasche", "Stalaktit",
            "Hieroglyphen", "Mumifizierung", "Sarkophag", "Obelisk", "Kathedrale", "Moschee", "Synagoge", "Tempel", "Pagode", "Wolkenkratzer"
        ].map { Term(text: $0) }

        // 5. FSK 18 (Custom)
        let fsk18Terms = [
            "Koks", "Hure", "Stripper", "Stripclub", "Dildo", "Penis", "Brüste", "Arsch", "Blowjob", "Orgasmus",
            "Puff", "Kondom", "Anal", "Lecken", "Reiten", "Stöhnen", "Erotik", "Sextoy", "Fesselspiel", "Peitsche",
            "Swingerclub", "Escort", "Camgirl", "Nippel", "Kiffen", "Ecstasy", "Dealer", "Bordell",
            "Handschellen", "Vibrator", "Pornostar", "One Night Stand", "Affäre", "Kamasutra", "Fetisch", "Domina",
            "Lack und Leder", "Sperma", "Schlucken", "Doggy Style", "69", "Dreier", "Gangbang", "Milf",
            "Sugar Daddy", "Callboy", "Gleitgel", "Viagra", "Pille", "Schwangerschaftstest", "Frauenarzt", "Urologe",
            "Rotlichtbezirk", "Darkroom", "Glory Hole", "Exhibitionist", "Voyeur", "Nacktstrand", "FKK", "Saunaclub",
            "Tinder Date", "Walk of Shame", "Kater", "Filmriss", "Saufspiel", "Bierpong", "Schnapsleiche", "Kotzen"
        ].map { Term(text: $0) }

        // Zuweisung mit TimesUpCategory
        categories = [
            TimesUpCategory(name: "Sehr leicht", type: .green, terms: greenTerms),
            TimesUpCategory(name: "Leicht", type: .yellow, terms: yellowTerms),
            TimesUpCategory(name: "Mittel", type: .red, terms: redTerms),
            TimesUpCategory(name: "Schwere Kategorie", type: .blue, terms: blueTerms),
            TimesUpCategory(name: "FSK 18", type: .custom, terms: fsk18Terms)
        ]
        
        log("Default categories loaded: \(categories.count)")
        categories.forEach { log("Kategorie '\($0.name)' hat \($0.terms.count) Begriffe") }
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
