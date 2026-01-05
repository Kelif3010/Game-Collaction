//
//  Category.swift
//  Imposter
//
//  Created by Ken on 22.09.25.
//

import Foundation

struct Category: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var words: [String]
    var isCustom: Bool
    var emoji: String
    var contentRating: ContentRating

    enum ContentRating: String, Codable, Hashable {
        case general
        case mature18
    }

    init(name: String, words: [String], emoji: String = "📁", isCustom: Bool = false, contentRating: ContentRating = .general) {
        self.id = UUID()
        self.name = name
        self.words = words
        self.emoji = emoji
        self.isCustom = isCustom
        self.contentRating = contentRating
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, words, isCustom, emoji, contentRating
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.name = try container.decode(String.self, forKey: .name)
        self.words = try container.decode([String].self, forKey: .words)
        self.isCustom = try container.decodeIfPresent(Bool.self, forKey: .isCustom) ?? false
        self.emoji = try container.decodeIfPresent(String.self, forKey: .emoji) ?? "📁"
        self.contentRating = try container.decodeIfPresent(ContentRating.self, forKey: .contentRating) ?? .general
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(words, forKey: .words)
        try container.encode(isCustom, forKey: .isCustom)
        try container.encode(emoji, forKey: .emoji)
        try container.encode(contentRating, forKey: .contentRating)
    }

    // Vordefinierte Kategorien (Optimiert für Release)
    static let defaultCategories: [Category] = [
        Category(
            name: "Tiere",
            words: [
                "Hund","Katze","Elefant","Löwe","Giraffe","Pinguin","Delfin","Adler","Zebra","Nashorn",
                "Nilpferd","Krokodil","Fuchs","Wolf","Bär","Eule","Papagei","Känguru","Koala","Faultier",
                "Panda","Gorilla","Schimpanse","Otter","Robbe","Wal","Hai","Tintenfisch","Krake","Seepferdchen",
                "Igel","Kaninchen","Meerschweinchen","Hamster","Pferd","Esel","Schaf","Ziege","Kuh","Huhn",
                "Truthahn","Ente","Gans","Pfau","Flamingo","Storch","Dachs","Fledermaus","Luchs","Elch"
            ],
            emoji: "🐾"
        ),
        Category(
            name: "Länder",
            words: [
                "Deutschland","Frankreich","Italien","Spanien","Portugal","Niederlande","Belgien","Österreich","Schweiz","Polen",
                "Tschechien","Kroatien","Ungarn","Griechenland","Türkei","Dänemark","Schweden","Norwegen","Finnland","Irland",
                "Großbritannien","Island","Ukraine","Russland","USA","Kanada","Mexiko","Brasilien","Argentinien","Chile",
                "Peru","Kolumbien","Australien","Neuseeland","China","Japan","Südkorea","Thailand","Vietnam","Indien",
                "Indonesien","Südafrika","Ägypten","Marokko","Kenia","Israel","Saudi-Arabien","Vereinigte Arabische Emirate","Singapur","Philippinen"
            ],
            emoji: "🌍"
        ),
        Category(
            name: "Berufe",
            words: [
                // Zusammengeführt aus "Berufe" und "Jobs" - Mix aus Klassikern und Moderne
                "Arzt","Lehrer","Polizist","Feuerwehrmann","Pilot","Anwalt","Richter","Ingenieur","Architekt","Künstler",
                "Schauspieler","Musiker","Astronaut","Detektiv","Bäcker","Metzger","Koch","Kellner","Friseur","Gärtner",
                "Landwirt","Tierarzt","Mechaniker","Elektriker","Schreiner","Maler","Soldat","Journalist","Fotograf","Bibliothekar",
                "Programmierer","Hacker","Influencer","YouTuber","Model","Designer","DJ","Barkeeper","Stewardess","Busfahrer",
                "Taxifahrer","Immobilienmakler","Banker","Wissenschaftler","Forscher","Psychologe","Zahnarzt","Chirurg","Bestatter","Spion"
            ],
            emoji: "👔"
        ),
        Category(
            name: "Früchte",
            words: [
                // Bereinigt um Verwechslungen (z.B. Clementine vs Mandarine entfernt)
                "Apfel","Banane","Orange","Zitrone","Limette","Grapefruit","Mandarine","Erdbeere","Himbeere","Brombeere",
                "Heidelbeere","Johannisbeere","Kirsche","Pfirsich","Aprikose","Pflaume","Birne","Ananas","Mango","Papaya",
                "Wassermelone","Honigmelone","Kiwi","Weintraube","Feige","Dattel","Litschi","Drachenfrucht","Kokosnuss","Avocado",
                "Granatapfel","Maracuja","Stachelbeere","Physalis","Quitte","Kaki","Pomelo","Olive","Limone","Cranberry",
                "Hagebutte","Sanddorn","Holunder","Maulbeere","Sternfrucht","Rhabarber","Guave","Jackfrucht","Durian","Kumquat"
            ],
            emoji: "🍎"
        ),
        Category(
            name: "Gemüse",
            words: [
                "Tomate","Gurke","Paprika","Karotte","Zwiebel","Knoblauch","Kartoffel","Süßkartoffel","Kürbis","Zucchini",
                "Aubergine","Brokkoli","Blumenkohl","Rosenkohl","Spinat","Grünkohl","Salat","Rucola","Sellerie","Lauch",
                "Petersilie","Basilikum","Schnittlauch","Erbse","Bohne","Linse","Mais","Rote Bete","Radieschen","Spargel",
                "Artischocke","Ingwer","Chili","Pilze","Champignon","Fenchel","Kohlrabi","Rotkohl","Weißkohl","Wirsing",
                "Mangold","Rettich","Pastinake","Okra","Bambussprossen","Sojabohne","Kichererbse","Edamame","Meerrettich","Wasabi"
            ],
            emoji: "🥦"
        ),
        Category(
            name: "Städte",
            words: [
                "Berlin","Hamburg","München","Köln","Frankfurt","Stuttgart","Düsseldorf","Leipzig","Dresden","Wien",
                "Zürich","Genf","Paris","London","Madrid","Barcelona","Rom","Mailand","Venedig","Amsterdam",
                "Brüssel","Kopenhagen","Stockholm","Oslo","Helsinki","Prag","Budapest","Warschau","Istanbul","Moskau",
                "New York","Los Angeles","San Francisco","Las Vegas","Miami","Chicago","Toronto","Rio de Janeiro","Buenos Aires","Tokio",
                "Peking","Shanghai","Hongkong","Singapur","Bangkok","Dubai","Kairo","Kapstadt","Sydney","Melbourne"
            ],
            emoji: "🏙️"
        ),
        Category(
            name: "Sportarten",
            words: [
                "Fußball","Basketball","Handball","Volleyball","Tennis","Tischtennis","Badminton","Golf","American Football","Baseball",
                "Eishockey","Formel 1","Schwimmen","Tauchen","Surfen","Segeln","Kanu","Rudern","Skifahren","Snowboarden",
                "Biathlon","Eiskunstlauf","Boxen","Judo","Karate","Ringen","MMA","Fechten","Turnen","Tanzen",
                "Ballett","Leichtathletik","Marathon","Triathlon","Radfahren","Mountainbiking","Skateboarden","Klettern","Bouldern","Wandern",
                "Reiten","Schach","E-Sports","Dart","Billard","Bowling","Yoga","Pilates","Crossfit","Bodybuilding"
            ],
            emoji: "🏅"
        ),
        Category(
            name: "Fahrzeuge",
            words: [
                "Auto","Sportwagen","Cabrio","Limousine","SUV","Geländewagen","Pick-up","LKW","Bus","Schulbus",
                "Motorrad","Roller","Moped","Fahrrad","E-Bike","Mountainbike","Einrad","Skateboard","Tretroller","Segway",
                "Traktor","Bagger","Kran","Gabelstapler","Feuerwehrauto","Polizeiauto","Krankenwagen","Müllwagen","Panzer","Zug",
                "Straßenbahn","U-Bahn","ICE","Dampflok","Flugzeug","Hubschrauber","Privatjet","Segelflugzeug","Heißluftballon","Drohne",
                "Schiff","Kreuzfahrtschiff","Segelboot","Yacht","Schnellboot","U-Boot","Jetski","Fähre","Rakete","UFO"
            ],
            emoji: "🚗"
        ),

        Category(
            name: "Berühmtheiten",
            words: [
                // Aktualisiert auf 2025 relevante Personen + All-Time Legends
                "Michael Jackson","Elvis Presley","Marilyn Monroe","Albert Einstein","Beyoncé","Rihanna","Taylor Swift","Ariana Grande","Billie Eilish","Eminem",
                "Justin Bieber","Harry Styles","Dua Lipa","Lady Gaga","Ed Sheeran","The Weeknd","Drake","Kanye West","Jay-Z","Dr. Dre",
                "Leonardo DiCaprio","Brad Pitt","Johnny Depp","Tom Cruise","Will Smith","Dwayne Johnson","Kevin Hart","Zendaya","Tom Holland","Margot Robbie",
                "Angelina Jolie","Kim Kardashian","Kylie Jenner","Elon Musk","Jeff Bezos","Mark Zuckerberg","Bill Gates","Steve Jobs",
                "Cristiano Ronaldo","Lionel Messi","Michael Jordan","LeBron James","Serena Williams","Tiger Woods","Barack Obama","Donald Trump","Angela Merkel","Queen Elizabeth II"
            ],
            emoji: "🌟"
        ),

        Category(
            name: "Marken",
            words: [
                "Apple","Samsung","Sony","Microsoft","Google","Amazon","Tesla","Mercedes","BMW","Audi",
                "Porsche","Ferrari","Lamborghini","Volkswagen","Toyota","Nike","Adidas","Puma","Gucci","Louis Vuitton",
                "Prada","Chanel","Rolex","Tiffany","Zara","H&M","IKEA","LEGO","PlayStation","Nintendo",
                "Xbox","Coca-Cola","Pepsi","Red Bull","McDonald's","Burger King","KFC","Starbucks","Subway","Domino's",
                "Netflix","Disney","Spotify","YouTube","TikTok","Instagram","Facebook","WhatsApp","Snapchat","Twitter/X"
            ],
            emoji: "🏷️"
        ),

        Category(
            name: "FSK 18",
            words: [
                // Themen: Party, Nightlife, Dating, Crime - keine langweiligen Begriffe
                "Tequila","Whiskey","Wodka","Champagner","Cocktail","Bier","Kater","Zigarette","Joint","Shisha",
                "Casino","Poker","Stripclub","Bordell","Nachtclub","Türsteher","Handschellen","Peitsche","Maske","Fesseln",
                "One-Night-Stand","Affäre","Seitensprung","Ex-Freund","Ex-Freundin","Tinder","Date","Kuss","Zungenkuss","Knutschfleck",
                "Liebe","Eifersucht","Fremdgehen","Scheidung","Beziehung","Kondom","Pille","Schwangerschaftstest","Porno","Erotik",
                "Nacktbilder","Sexting","Drogen","Dealer","Gefängnis","Mord","Waffe","Blut","Leiche","Sünde"
            ],
            emoji: "🔞",
            contentRating: .mature18
        ),

        Category(
            name: "Essen",
            words: [
                // Universelle Gerichte statt Nische
                "Pizza","Burger","Pommes","Döner","Sushi","Pasta","Lasagne","Spaghetti","Ramen","Curry",
                "Tacos","Burrito","Hotdog","Sandwich","Toast","Pfannkuchen","Waffel","Crepes","Rührei","Spiegelei",
                "Omelett","Schnitzel","Steak","Bratwurst","Currywurst","Hähnchen","Fischstäbchen","Lachs","Forelle","Garnele",
                "Hummer","Kaviar","Salat","Suppe","Eintopf","Brot","Brötchen","Croissant","Donut","Muffin",
                "Kuchen","Torte","Keks","Schokolade","Chips","Popcorn","Eis","Joghurt","Käse","Wurst"
            ],
            emoji: "🍽️"
        ),

        Category(
            name: "Superkräfte",
            words: [
                // Bildlich und verständlich für jeden
                "Fliegen","Unsichtbarkeit","Teleportation","Gedankenlesen","Zeitreise","Unsterblichkeit","Telekinese","Superstärke","Superschnelligkeit","Heilung",
                "Wetterkontrolle","Feuer spucken","Einfrieren","Blitze schleudern","Verwandlung","Tarnung","Gedankenkontrolle","Zukunft sehen","Mit Tieren sprechen","Schweben",
                "Riesig werden","Winzig werden","Nachtsicht","Röntgenblick","Hitzeblick","Schutzschild","Wände klettern","Gummi-Körper","Kräfte klauen","Schallschrei",
                "Unterwasser atmen","Magie","Gedächtnis löschen","Durch Wände gehen","Super-Glück","Illusionen","Licht erschaffen","Schatten steuern","Zeit anhalten","Klonen",
                "Gift spucken","Säurehaut","Hypnose","Super-Gehör","Steinhaut","Laseraugen","Pflanzen steuern","Portale öffnen","Geister sehen","Magnetismus"
            ],
            emoji: "⚡️"
        ),

        Category(
            name: "Körper & Gesundheit",
            words: [
                "Herz","Gehirn","Lunge","Magen","Darm","Leber","Niere","Knochen","Muskel","Blut",
                "Haut","Zahn","Zunge","Auge","Ohr","Nase","Mund","Haare","Hand","Fuß",
                "Finger","Zeh","Knie","Ellbogen","Schulter","Rücken","Bauch","Po","Hals","Stirn",
                "Skelett","Schädel","Rippe","Wirbelsäule","Nerv","Ader","Pickel","Narbe","Tattoo","Muttermal",
                "Fieber","Husten","Schnupfen","Kopfschmerzen","Bauchschmerzen","Grippe","Virus","Bakterie","Medizin","Pflaster"
            ],
            emoji: "🧠"
        ),
        Category(
            name: "Orte",
            words: [
                "Zuhause","Schule","Universität","Büro","Krankenhaus","Polizeiwache","Gefängnis","Kirche","Friedhof","Supermarkt",
                "Einkaufszentrum","Kino","Theater","Museum","Bibliothek","Fitnessstudio","Schwimmbad","Stadion","Zoo","Freizeitpark",
                "Zirkus","Spielplatz","Park","Wald","Strand","Wüste","Berg","Insel","Höhle","Bauernhof",
                "Bahnhof","Flughafen","Hafen","Tankstelle","Werkstatt","Restaurant","Café","Bar","Disko","Hotel",
                "Campingplatz","Bank","Post","Friseur","Apotheke","Bäckerei","Metzgerei","Kiosk","Toilette","Balkon"
            ],
            emoji: "📍"
        )
    ]

    // Helper für das Hinzufügen und Löschen von Wörtern
    mutating func addWord(_ word: String) {
        let trimmedWord = word.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedWord.isEmpty && !words.contains(trimmedWord) {
            words.append(trimmedWord)
        }
    }

    mutating func removeWord(_ word: String) {
        words.removeAll { $0 == word }
    }

    mutating func removeWord(at index: Int) {
        if index < words.count && index >= 0 {
            words.remove(at: index)
        }
    }
}
