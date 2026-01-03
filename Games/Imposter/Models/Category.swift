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

    // Vordefinierte Kategorien (8x ~50 Wörter)
    static let defaultCategories: [Category] = [
        Category(
            name: "Tiere",
            words: [
                "Hund","Katze","Elefant","Löwe","Giraffe","Pinguin","Delfin","Adler","Zebra","Nashorn",
                "Nilpferd","Krokodil","Fuchs","Wolf","Bär","Eule","Papagei","Känguru","Koala","Faultier",
                "Panda","Gorilla","Schimpanse","Otter","Robbe","Wal","Hai","Tintenfisch","Krake","Seepferdchen",
                "Igel","Kaninchen","Meerschweinchen","Hamster","Pferd","Esel","Schaf","Ziege","Kuh","Huhn",
                "Truthahn","Ente","Gans","Pfau","Flamingo","Storch","Dachs","Marder","Luchs","Elch"
            ],
            emoji: "🐾"
        ),
        Category(
            name: "Länder",
            words: [
                "Deutschland","Frankreich","Italien","Spanien","Portugal","Niederlande","Belgien","Luxemburg","Österreich","Schweiz",
                "Polen","Tschechien","Slowakei","Ungarn","Rumänien","Bulgarien","Griechenland","Türkei","Zypern","Dänemark",
                "Schweden","Norwegen","Finnland","Estland","Lettland","Litauen","Irland","Vereinigtes Königreich","Island","Ukraine",
                "Moldau","Georgien","Armenien","Aserbaidschan","USA","Kanada","Mexiko","Brasilien","Argentinien","Chile",
                "Peru","Kolumbien","Australien","Neuseeland","China","Japan","Südkorea","Indien","Indonesien","Südafrika"
            ],
            emoji: "🌍"
        ),
        Category(
            name: "Berufe",
            words: [
                "Arzt","Lehrkraft","Polizist","Koch","Pilot","Anwalt","Ingenieur","Künstler","Musiker","Schauspieler",
                "Tänzer","Fotograf","Designer","Architekt","Programmierer","Datenanalyst","Produktmanager","Projektmanager","Verkäufer","Kassierer",
                "Mechaniker","Elektriker","Installateur","Schreiner","Bäcker","Metzger","Friseur","Kellner","Barkeeper","Krankenpfleger",
                "Physiotherapeut","Apotheker","Wissenschaftler","Forscher","Biologe","Chemiker","Physiker","Mathematiker","Journalist","Redakteur",
                "Autor","Übersetzer","Dolmetscher","Landwirt","Gärtner","Fahrer","Lokführer","Zugbegleiter","Flugbegleiter","Buchhalter"
            ],
            emoji: "👔"
        ),
        Category(
            name: "Früchte",
            words: [
                "Apfel","Banane","Orange","Zitrone","Limette","Grapefruit","Mandarine","Clementine","Erdbeere","Himbeere",
                "Brombeere","Heidelbeere","Johannisbeere","Stachelbeere","Kirsche","Pfirsich","Nektarine","Aprikose","Pflaume","Zwetschge",
                "Birne","Ananas","Mango","Papaya","Guave","Maracuja","Granatapfel","Kiwi","Traube","Wassermelone",
                "Honigmelone","Cantaloupe","Feige","Dattel","Litschi","Rambutan","Drachenfrucht","Sternfrucht","Kokosnuss","Avocado",
                "Physalis","Quitte","Kakifrucht","Persimone","Cranberry","Kumquat","Pomelo","Boysenbeere","Mirabelle","Mispel"
            ],
            emoji: "🍎"
        ),
        Category(
            name: "Gemüse",
            words: [
                "Tomate","Gurke","Paprika","Karotte","Zwiebel","Knoblauch","Kartoffel","Süßkartoffel","Kürbis","Zucchini",
                "Aubergine","Brokkoli","Blumenkohl","Rosenkohl","Spinat","Mangold","Grünkohl","Eisbergsalat","Rucola","Feldsalat",
                "Kopfsalat","Sellerie","Staudensellerie","Lauch","Porree","Schnittlauch","Petersilie","Dill","Koriander","Basilikum",
                "Oregano","Thymian","Rosmarin","Erbse","Bohne","Linsen","Kichererbse","Mais","Rote Bete","Rettich",
                "Radieschen","Pastinake","Schwarzwurzel","Topinambur","Ingwer","Kurkuma","Chili","Jalapeño","Artischocke","Spargel"
            ],
            emoji: "🥦"
        ),
        Category(
            name: "Städte",
            words: [
                "Berlin","Hamburg","München","Köln","Frankfurt","Stuttgart","Düsseldorf","Leipzig","Dresden","Hannover",
                "Bremen","Nürnberg","Essen","Dortmund","Bonn","Mannheim","Karlsruhe","Wiesbaden","Mainz","Augsburg",
                "Wien","Zürich","Basel","Genf","Paris","Lyon","Marseille","London","Manchester","Birmingham",
                "Dublin","Edinburgh","Rom","Mailand","Neapel","Barcelona","Madrid","Valencia","Lissabon","Porto",
                "Amsterdam","Rotterdam","Brüssel","Kopenhagen","Stockholm","Oslo","Helsinki","Prag","Budapest","Warschau"
            ],
            emoji: "🏙️"
        ),
        Category(
            name: "Sportarten",
            words: [
                "Fußball","Basketball","Handball","Volleyball","Tennis","Tischtennis","Badminton","Squash","Rugby","American Football",
                "Baseball","Eishockey","Feldhockey","Leichtathletik","Schwimmen","Wasserspringen","Synchronschwimmen","Wasserball","Ringen","Judo",
                "Karate","Taekwondo","Boxen","Kickboxen","Fechten","Gewichtheben","Turnen","Rhythmische Sportgymnastik","Radfahren","Mountainbike",
                "BMX","Triathlon","Marathon","Halbmarathon","Skifahren","Snowboarden","Langlauf","Biathlon","Eiskunstlauf","Eisschnelllauf",
                "Surfen","Windsurfen","Kitesurfen","Segeln","Rudern","Kanu","Kajak","Reiten","Golf","Schach"
            ],
            emoji: "🏅"
        ),
        Category(
            name: "Fahrzeuge",
            words: [
                "Auto","Motorrad","Roller","Moped","Fahrrad","E-Bike","Mountainbike","Rennrad","Skateboard","Longboard",
                "Tretroller","Bus","Reisebus","LKW","Sattelzug","Traktor","Bagger","Radlader","Gabelstapler","Kran",
                "Feuerwehrauto","Polizeiauto","Krankenwagen","Taxi","Limousine","Cabrio","Kombi","Coupé","SUV","Van",
                "Minivan","Pickup","Geländewagen","Wohnmobil","Wohnwagen","Zug","Straßenbahn","U-Bahn","S-Bahn","Hochgeschwindigkeitszug",
                "Schiff","Fähre","Segelboot","Motorboot","Yacht","U-Boot","Flugzeug","Hubschrauber","Heißluftballon","Seilbahn"
            ],
            emoji: "🚗"
        ),
    

        Category(
            name: "Berühmtheiten",
            words: [
                "Michael Jackson","Elvis Presley","Madonna","Beyoncé","Rihanna","Taylor Swift","Ariana Grande","Billie Eilish","Drake","Eminem",
                "Justin Bieber","Selena Gomez","Miley Cyrus","Shakira","Lady Gaga","Britney Spears","Ed Sheeran","The Weeknd","Kanye West","Jay-Z",
                "Leonardo DiCaprio","Brad Pitt","Johnny Depp","Tom Cruise","Robert Downey Jr.","Chris Hemsworth","Dwayne Johnson","Will Smith","Ryan Reynolds","Keanu Reeves",
                "Angelina Jolie","Scarlett Johansson","Zendaya","Jennifer Lawrence","Emma Watson","Kim Kardashian","Kylie Jenner","Cristiano Ronaldo","Lionel Messi","Neymar",
                "Michael Jordan","LeBron James","Serena Williams","Usain Bolt","Oprah Winfrey","Elon Musk","Jeff Bezos","Donald Trump","Barack Obama","Taylor Lautner"
            ],
            emoji: "🌟"
        ),

        Category(
            name: "Jobs",
            words: [
                "Softwareentwickler","Produktdesigner","UX-Designer","Data Scientist","Marketing Manager","Social Media Manager","Videograf","Content Creator","Influencer","Eventmanager",
                "Immobilienmakler","Bauleiter","Lagerist","Verwaltungsangestellter","Sekretär","Bankkaufmann","Versicherungskaufmann","Zollbeamter","Soldat","Polizist",
                "Feuerwehrmann","Sanitäter","Pflegekraft","Hebamme","Tierarzt","Tierpfleger","Fahrlehrer","Busfahrer","Taxifahrer","Postbote",
                "Hausmeister","Gärtner","Florist","Friseur","Kosmetikerin","Nageldesignerin","Barkeeper","Koch","Kellner","Reinigungskraft",
                "Hauswirtschafter","Fotograf","Videograf","Journalist","Autor","Redakteur","Synchronsprecher","Schauspieler","Musiker","Tänzer"
            ],
            emoji: "💼"
        ),

        Category(
            name: "Marken",
            words: [
                "Apple","Samsung","Sony","LG","Microsoft","Google","Amazon","Nike","Adidas","Puma",
                "Under Armour","New Balance","Reebok","Vans","Converse","Balenciaga","Gucci","Prada","Louis Vuitton","Chanel",
                "Dior","Hermès","Rolex","Cartier","Versace","Zara","H&M","Uniqlo","Shein","Bershka",
                "Tesla","Ferrari","Lamborghini","Porsche","BMW","Mercedes","Audi","Volkswagen","IKEA","LEGO",
                "Coca-Cola","Pepsi","Red Bull","Nescafé","McDonald's","Burger King","KFC","Subway","Netflix","Spotify"
            ],
            emoji: "🏷️"
        ),

        Category(
            name: "FSK 18",
            words: [
                "Tequila","Whiskey","Wodka","Rum","Gin","Sekt","Champagner","Cocktail","Bier","Wein",
                "Zigarette","Zigarre","Casino","Poker","Roulette","Stripclub","One-Night-Stand","Hangover","Tattoo","Piercing",
                "Verführung","Eifersucht","Affäre","Nachtclub","Party","Betrunken","Lügen","Verlangen","BDSM","Flirten",
                "Kuss","Lippenstift","High Heels","Dessous","Verlobung","Beziehung","Herzschmerz","Eifersucht","Drama","Dating-App",
                "Luxus","Verführung","Massage","Cocktailbar","Afterparty","Geheimnis","Verboten","Sünde","Wette","Alkohol"
            ],
            emoji: "🔞",
            contentRating: .mature18
        ),

        Category(
            name: "Essen",
            words: [
                "Pizza","Burger","Pasta","Lasagne","Hotdog","Sandwich","Wrap","Tacos","Burrito","Sushi",
                "Ramen","Pad Thai","Curry","Kebab","Falafel","Kisir","Cigköfte","Pommes","Salat","Risotto",
                "Gnocchi","Döner","Hähnchen","Steak","Fisch","Schnitzel","Spätzle","Maultaschen","Kartoffelsalat","Suppen",
                "Eintopf","Tofu","Tempeh","Vegetarisch","Vegan","Omelett","Pfannkuchen","Waffel","Crêpe","Torte",
                "Kuchen","Donut","Muffin","Brownie","Eis","Pudding","Joghurt","Smoothie","Shake","Müsli"
            ],
            emoji: "🍽️"
        ),

        Category(
            name: "Superkräfte",
            words: [
                "Fliegen","Unsichtbarkeit","Teleportation","Gedankenlesen","Zeitreise","Unsterblichkeit","Telekinese","Superstärke","Superschnelligkeit","Heilung",
                "Wetterkontrolle","Feuerkontrolle","Eiskontrolle","Elektrizität","Formwandlung","Tarnung","Gedankensteuerung","Vorahnung","Tierkommunikation","Schwebefähigkeit",
                "Größenveränderung","Superhörvermögen","Nachtsicht","Röntgenblick","Telepathie","Energieblitze","Laserblick","Schattenmanipulation","Klonen","Levitation",
                "Traumwandeln","Magie","Gedächtnis löschen","Wände durchdringen","Karma-Kontrolle","Illusion","Lichtmanipulation","Gedankenübertragung","Realitätsveränderung","Zeit anhalten",
                "Gedankenprojektion","Aura sehen","Hypnose","Schnellheilung","Supersinn","Mimikry","Seele trennen","Natur kontrollieren","Dimensionen wechseln","Telepathischer Ruf"
            ],
            emoji: "⚡️"
        ),

        Category(
            name: "Körper & Gesundheit",
            words: [
                "Herz","Lunge","Leber","Niere","Magen","Darm","Gehirn","Augen","Ohren","Zähne",
                "Knochen","Muskeln","Blut","Haut","Haare","Nägel","Zunge","Lippen","Hände","Füße",
                "Rücken","Wirbelsäule","Gelenke","Knie","Schultern","Bizeps","Trizeps","Bauch","Po","Brust",
                "Atmung","Puls","Schlaf","Stress","Ernährung","Bewegung","Meditation","Yoga","Fitness","Krafttraining",
                "Cardio","Erkältung","Grippe","Fieber","Kopfschmerz","Migräne","Allergie","Immunität","Heilung","Entspannung"
            ],
            emoji: "🧠"
        ),
        Category(
            name: "Orte",
            words: [
                "Kino","Schwimmbad","Garage","Bibliothek","Supermarkt","Bäckerei","Metzgerei","Apotheke","Krankenhaus","Arztpraxis",
                "Zahnarzt","Schule","Universität","Kindergarten","Büro","Park","Spielplatz","Museum","Theater","Stadion",
                "Bahnhof","Flughafen","Bushaltestelle","U-Bahn-Station","Tankstelle","Werkstatt","Post","Bank","Rathaus","Polizeistation",
                "Feuerwache","Kirche","Moschee","Tempel","Synagoge","Friedhof","Hotel","Hostel","Restaurant","Café",
                "Bar","Club","Zoo","Aquarium","Campingplatz","Strand","Hafen","Leuchtturm","Brücke","Tunnel"
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
