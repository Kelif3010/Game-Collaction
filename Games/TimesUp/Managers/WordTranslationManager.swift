//
//  WordTranslationManager.swift
//  TimesUp
//
//  Created by Codex on new feature task.
//

import Combine
import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

@MainActor
class WordTranslationManager: ObservableObject {
    @Published private(set) var isAIAvailable = false

    private var session: Any?
    private let fallbackTranslations: [String: String]

    init() {
        fallbackTranslations = Self.defaultFallbackTranslations()
        checkAIAvailability()
    }

    private func checkAIAvailability() {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            let model = SystemLanguageModel.default
            switch model.availability {
            case .available:
                isAIAvailable = true
                session = LanguageModelSession(instructions: createTranslationInstructionsText())
                print("🤖 WordTranslationManager: Apple Intelligence verfügbar")
            case .unavailable:
                isAIAvailable = false
                print("⚠️ WordTranslationManager: Apple Intelligence nicht verfügbar – Verwende Fallback-Wörterbuch")
            }
            return
        }
        #endif
        isAIAvailable = false
        print("⚠️ WordTranslationManager: Apple Intelligence nicht verfügbar – iOS-Version zu alt")
    }

    private func createTranslationInstructionsText() -> String {
        """
        Du übersetzt einzelne Begriffe ins Englische.
        Antwort nur im JSON-Format {"english":"<Wort>"} ohne zusätzliche Erklärungen.
        """
    }

    func translateToEnglish(_ term: String) async -> String {
        let cleaned = term.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return term }

        #if canImport(FoundationModels)
        if #available(iOS 26.0, *), isAIAvailable, let session = session as? LanguageModelSession {
            let prompt = """
            Übersetze das Wort '\(cleaned)' ins Englische.
            Antworte ausschließlich im JSON-Format {"english":"<Übersetzung>"}.
            """
            do {
                let response = try await session.respond(to: prompt)
                if let translation = parseTranslation(from: response.content) {
                    return translation
                }
            } catch {
                print("⚠️ WordTranslationManager: Übersetzung fehlgeschlagen -> \(error.localizedDescription)")
            }
        }
        #endif

        let key = cleaned.lowercased()
        return fallbackTranslations[key] ?? cleaned
    }

    private static func defaultFallbackTranslations() -> [String: String] {
        let entries: [(String, String)] = [
            ("katze", "Cat"), ("hund", "Dog"), ("maus", "Mouse"), ("fisch", "Fish"), ("vogel", "Bird"),
            ("hase", "Rabbit"), ("kuh", "Cow"), ("pferd", "Horse"), ("schaf", "Sheep"), ("schwein", "Pig"),
            ("ente", "Duck"), ("huhn", "Chicken"), ("bär", "Bear"), ("löwe", "Lion"), ("tiger", "Tiger"),
            ("elefant", "Elephant"), ("giraffe", "Giraffe"), ("affe", "Monkey"), ("pinguin", "Penguin"),
            ("frosch", "Frog"), ("auto", "Car"), ("bus", "Bus"), ("zug", "Train"), ("flugzeug", "Airplane"),
            ("schiff", "Ship"), ("fahrrad", "Bicycle"), ("roller", "Scooter"), ("ball", "Ball"),
            ("ballon", "Balloon"), ("puppe", "Doll"), ("teddy", "Teddy bear"), ("rucksack", "Backpack"),
            ("schuh", "Shoe"), ("mütze", "Hat"), ("jacke", "Jacket"), ("handschuh", "Glove"), ("brille", "Glasses"),
            ("uhr", "Watch"), ("schlüssel", "Key"), ("lampe", "Lamp"), ("tisch", "Table"), ("stuhl", "Chair"),
            ("bett", "Bed"), ("sofa", "Sofa"), ("tür", "Door"), ("fenster", "Window"), ("haus", "House"),
            ("schule", "School"), ("park", "Park"), ("spielplatz", "Playground"), ("garten", "Garden"),
            ("apfel", "Apple"), ("banane", "Banana"), ("traube", "Grape"), ("erdbeere", "Strawberry"),
            ("wassermelone", "Watermelon"), ("brot", "Bread"), ("käse", "Cheese"), ("pizza", "Pizza"),
            ("eis", "Ice cream"), ("kuchen", "Cake"), ("milch", "Milk"), ("wasser", "Water"), ("saft", "Juice"),
            ("sonne", "Sun"), ("mond", "Moon"), ("stern", "Star"), ("regen", "Rain"), ("schnee", "Snow"),
            ("regenbogen", "Rainbow"), ("wolke", "Cloud"), ("baum", "Tree"), ("blume", "Flower"), ("blatt", "Leaf"),
            ("stein", "Stone"), ("sand", "Sand"), ("meer", "Sea"), ("strand", "Beach"), ("see", "Lake"),
            ("berg", "Mountain"), ("zahnbürste", "Toothbrush"), ("zahnpasta", "Toothpaste"), ("seife", "Soap"),
            ("handtuch", "Towel"), ("spiegel", "Mirror"), ("kamm", "Comb"), ("schere", "Scissors"), ("buch", "Book"),
            ("heft", "Notebook"), ("stift", "Pen"), ("radiergummi", "Eraser"), ("lineal", "Ruler"),
            ("computer", "Computer"), ("tablet", "Tablet"), ("handy", "Phone"), ("fernseher", "TV"),
            ("fernbedienung", "Remote control"), ("kamera", "Camera"), ("kopfhörer", "Headphones"),
            ("mikrofon", "Microphone"), ("feuerwehr", "Firefighter"), ("polizei", "Police"), ("arzt", "Doctor"),
            ("bäcker", "Baker"), ("lehrer", "Teacher"), ("gärtner", "Gardener"), ("koch", "Chef"),
            ("pilot", "Pilot"), ("verkäufer", "Salesperson"), ("postbote", "Mail carrier"),
            ("gitarre", "Guitar"), ("trommel", "Drum"), ("klavier", "Piano"), ("geige", "Violin"), ("flöte", "Flute"),
            ("trompete", "Trumpet"), ("fußball", "Soccer"), ("basketball", "Basketball"), ("tennis", "Tennis"),
            ("schwimmen", "Swimming"), ("springseil", "Jump rope"), ("laufen", "Running"), ("zebra", "Zebra"),
            ("delfin", "Dolphin"), ("wal", "Whale"), ("eule", "Owl"), ("fuchs", "Fox"), ("igel", "Hedgehog"),
            ("spaghetti", "Spaghetti"), ("pfannkuchen", "Pancake"), ("suppe", "Soup"), ("salat", "Salad"),
            ("schokolade", "Chocolate"), ("marmelade", "Jam"), ("honig", "Honey"), ("stadt", "City"),
            ("dorf", "Village"), ("bahnhof", "Train station"), ("flughafen", "Airport"), ("brücke", "Bridge"),
            ("tunnel", "Tunnel")
        ]
        return Dictionary(uniqueKeysWithValues: entries.map { ($0.0.lowercased(), $0.1) })
    }

    private struct TranslationResponse: Decodable {
        let english: String
    }

    private func parseTranslation(from text: String) -> String? {
        guard let data = extractJSON(from: text),
              let decoded = try? JSONDecoder().decode(TranslationResponse.self, from: data) else {
            return nil
        }
        let trimmed = decoded.english.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private func extractJSON(from text: String) -> Data? {
        guard let start = text.firstIndex(of: "{"),
              let end = text.lastIndex(of: "}") else { return nil }
        let jsonStr = String(text[start...end])
        return jsonStr.data(using: .utf8)
    }
}
