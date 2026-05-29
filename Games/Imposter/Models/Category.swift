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
    var sourceName: String?
    var isCustom: Bool
    var emoji: String
    var contentRating: ContentRating

    enum ContentRating: String, Codable, Hashable {
        case general
        case mature18
    }

    init(name: String, words: [String], emoji: String = "📁", isCustom: Bool = false, contentRating: ContentRating = .general, sourceName: String? = nil) {
        self.id = UUID()
        self.name = name
        self.words = words
        if isCustom {
            self.sourceName = sourceName
        } else {
            self.sourceName = sourceName ?? name
        }
        self.emoji = emoji
        self.isCustom = isCustom
        self.contentRating = contentRating
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, words, sourceName, isCustom, emoji, contentRating
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.name = try container.decode(String.self, forKey: .name)
        self.words = try container.decode([String].self, forKey: .words)
        self.sourceName = try container.decodeIfPresent(String.self, forKey: .sourceName)
        self.isCustom = try container.decodeIfPresent(Bool.self, forKey: .isCustom) ?? false
        self.emoji = try container.decodeIfPresent(String.self, forKey: .emoji) ?? "📁"
        self.contentRating = try container.decodeIfPresent(ContentRating.self, forKey: .contentRating) ?? .general
        if !self.isCustom && self.sourceName == nil {
            self.sourceName = self.name
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(words, forKey: .words)
        try container.encode(sourceName, forKey: .sourceName)
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
                "Truthahn","Ente","Gans","Pfau","Flamingo","Storch","Dachs","Fledermaus","Luchs","Elch",
                "Waschbär","Biber","Marder","Wiesel","Rentier","Büffel","Antilope","Erdmännchen","Chamäleon","Leguan",
                "Salamander","Frosch","Schildkröte","Qualle","Seestern","Hummer","Skorpion","Spinne","Marienkäfer","Libelle"
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
                "Indonesien","Südafrika","Ägypten","Marokko","Kenia","Israel","Saudi-Arabien","Vereinigte Arabische Emirate","Singapur","Philippinen",
                "Kuba","Jamaika","Dominikanische Republik","Costa Rica","Uruguay","Bolivien","Ecuador","Panama","Katar","Jordanien",
                "Libanon","Tunesien","Nigeria","Ghana","Äthiopien","Madagaskar","Malaysia","Taiwan","Mongolei","Nepal"
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
                "Taxifahrer","Immobilienmakler","Banker","Wissenschaftler","Forscher","Psychologe","Zahnarzt","Chirurg","Bestatter","Spion",
                "Sanitäter","Apotheker","Optiker","Hebamme","Erzieher","Professor","Richterassistent","Notar","Übersetzer","Reiseleiter",
                "Fitnesstrainer","Personal Trainer","Streamer","Game Designer","Data Analyst","Produktmanager","Eventmanager","Kameramann","Maskenbildner","Tattoo-Künstler"
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
                "Hagebutte","Sanddorn","Holunder","Maulbeere","Sternfrucht","Rhabarber","Guave","Jackfrucht","Durian","Kumquat",
                "Nektarine","Cantaloupe","Mirabelle","Reneklode","Preiselbeere","Acerola","Açaí","Tamarinde","Cherimoya","Mangostan",
                "Buddhas Hand","Blutorange","Satsuma","Yuzu","Longan","Rambutan","Boysenbeere","Jostabeere","Kaktusfeige","Bergamotte"
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
                "Mangold","Rettich","Pastinake","Okra","Bambussprossen","Sojabohne","Kichererbse","Edamame","Meerrettich","Wasabi",
                "Pak Choi","Chinakohl","Topinambur","Schwarzwurzel","Steckrübe","Mairübe","Butternut-Kürbis","Hokkaido","Portobello","Austernpilz",
                "Shiitake","Zuckerschote","Romanesco","Brunnenkresse","Endivie","Radicchio","Frühlingszwiebel","Kresse","Kürbisblüte","Alge"
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
                "Peking","Shanghai","Hongkong","Singapur","Bangkok","Dubai","Kairo","Kapstadt","Sydney","Melbourne",
                "Lissabon","Porto","Sevilla","Valencia","Florenz","Neapel","Athen","Edinburgh","Dublin","Reykjavik",
                "Vancouver","Seattle","Boston","Washington","Havanna","Lima","Bogotá","Seoul","Kyoto","Mumbai"
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
                "Reiten","Schach","E-Sports","Dart","Billard","Bowling","Yoga","Pilates","Crossfit","Bodybuilding",
                "Rugby","Cricket","Lacrosse","Ultimate Frisbee","Parkour","Slackline","Kickboxen","Taekwondo","Capoeira","Gewichtheben",
                "Curling","Eisschnelllauf","Skeleton","Bobfahren","Synchronschwimmen","Wasserball","Beachvolleyball","Padel","Squash","Disc Golf"
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
                "Schiff","Kreuzfahrtschiff","Segelboot","Yacht","Schnellboot","U-Boot","Jetski","Fähre","Rakete","UFO",
                "Wohnmobil","Wohnwagen","Monstertruck","Rennwagen","Kart","Quad","Schneemobil","Pistenraupe","Krankenhubschrauber","Zeppelin",
                "Seilbahn","Gondel","Monorail","Schwebebahn","Containerschiff","Frachter","Katamaran","Rettungsboot","Surfbrett","Hovercraft"
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
                "Cristiano Ronaldo","Lionel Messi","Michael Jordan","LeBron James","Serena Williams","Tiger Woods","Barack Obama","Donald Trump","Angela Merkel","Queen Elizabeth II",
                "Snoop Dogg","Kendrick Lamar","Post Malone","Olivia Rodrigo","Miley Cyrus","Selena Gomez","Shakira","Bad Bunny","Adele","Bruno Mars",
                "Ryan Reynolds","Ryan Gosling","Emma Stone","Jennifer Lawrence","Robert Downey Jr.","Chris Hemsworth","Keanu Reeves","MrBeast","Greta Thunberg","Usain Bolt"
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
                "Netflix","Disney","Spotify","YouTube","TikTok","Instagram","Facebook","WhatsApp","Snapchat","Twitter/X",
                "Airbnb","Uber","PayPal","Visa","Mastercard","Nvidia","Intel","AMD","Canon","Nikon",
                "GoPro","Dyson","Nespresso","Lidl","Aldi","Rewe","Edeka","dm","Müller","Decathlon"
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
                "Nacktbilder","Sexting","Drogen","Dealer","Gefängnis","Mord","Waffe","Blut","Leiche","Sünde",
                "Afterparty","Katerfrühstück","Walk of Shame","Blind Date","Red Flag","Toxic Beziehung","Sugar Daddy","Fetisch","Lust","Verführung",
                "Ehekrise","Affären-App","Bodyshot","Junggesellenabschied","Roulette","Blackjack","Lügenbaron","Alibi","Tatort","Beichte"
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
                "Kuchen","Torte","Keks","Schokolade","Chips","Popcorn","Eis","Joghurt","Käse","Wurst",
                "Falafel","Hummus","Paella","Risotto","Gnocchi","Maultaschen","Käsespätzle","Gyros","Pekingente","Dim Sum",
                "Pho","Bibimbap","Kimchi","Nachos","Quesadilla","Fish and Chips","Mac and Cheese","Brownie","Tiramisu","Pudding"
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
                "Gift spucken","Säurehaut","Hypnose","Super-Gehör","Steinhaut","Laseraugen","Pflanzen steuern","Portale öffnen","Geister sehen","Magnetismus",
                "Formwandlung","Wasser kontrollieren","Erdbeben auslösen","Metall verbiegen","Albträume erzeugen","Träume betreten","Auren sehen","Schmerz ausschalten","Körper tauschen","Gedanken übertragen",
                "Unendliches Wissen","Tiere verwandeln","Schwerkraft ändern","Energie absorbieren","Unsichtbare Waffen","Kraftfelder bauen","Schattenreise","Selbstheilung","Technik kontrollieren","Wahrheit erzwingen"
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
                "Fieber","Husten","Schnupfen","Kopfschmerzen","Bauchschmerzen","Grippe","Virus","Bakterie","Medizin","Pflaster",
                "Allergie","Impfung","Röntgenbild","Ultraschall","Spritze","Verband","Krücke","Rollstuhl","Blutdruck","Puls",
                "Migräne","Muskelkater","Sonnenbrand","Schlafmangel","Narkose","Operation","Rezept","Therapie","Brille","Kontaktlinse"
            ],
            emoji: "🧠"
        ),

        Category(
            name: "Filme & Serien",
            words: [
                "Harry Potter","Star Wars","Herr der Ringe","Hobbit","Titanic","Avatar","Jurassic Park","König der Löwen","Frozen","Shrek",
                "Toy Story","Findet Nemo","Minions","Spider-Man","Batman","Superman","Iron Man","Avengers","Black Panther","Guardians of the Galaxy",
                "Fluch der Karibik","James Bond","Mission Impossible","Fast & Furious","Matrix","Inception","Interstellar","Forrest Gump","Zurück in die Zukunft","Ghostbusters",
                "Breaking Bad","Better Call Saul","Stranger Things","Game of Thrones","House of the Dragon","The Walking Dead","Squid Game","The Last of Us","Wednesday","Dark",
                "Haus des Geldes","Friends","How I Met Your Mother","The Big Bang Theory","The Office","Modern Family","Simpsons","South Park","SpongeBob","Naruto",
                "One Piece","Dragon Ball","Pokémon","The Mandalorian","Loki","Sherlock","Peaky Blinders","The Crown","Bridgerton","Black Mirror"
            ],
            emoji: "🎬"
        ),

        Category(
            name: "Alltagsgegenstände",
            words: [
                "Schlüssel","Handy","Geldbeutel","Kopfhörer","Ladegerät","Fernbedienung","Taschenlampe","Regenschirm","Rucksack","Koffer",
                "Brille","Sonnenbrille","Uhr","Wecker","Spiegel","Kamm","Zahnbürste","Zahnpasta","Seife","Handtuch",
                "Kissen","Decke","Bettlaken","Kleiderbügel","Schere","Kleber","Klebeband","Stift","Bleistift","Radiergummi",
                "Notizbuch","Kalender","Briefumschlag","Kerze","Feuerzeug","Streichholz","Flasche","Tasse","Glas","Teller",
                "Gabel","Messer","Löffel","Pfanne","Topf","Schneidebrett","Müllbeutel","Staubsauger","Besen","Wäschekorb",
                "Batterie","Mehrfachsteckdose","Laptop","Tablet","Maus","Tastatur","Router","Kühlschrankmagnet","Pflaster","Taschentuch"
            ],
            emoji: "🔑"
        ),

        Category(
            name: "Events & Anlässe",
            words: [
                "Geburtstag","Hochzeit","Beerdigung","Taufe","Einschulung","Abschlussfeier","Abi-Ball","Junggesellenabschied","Babyparty","Familientreffen",
                "Weihnachten","Silvester","Ostern","Halloween","Karneval","Valentinstag","Muttertag","Vatertag","Erntedank","Oktoberfest",
                "Festival","Konzert","Theaterpremiere","Kinopremiere","Sportfinale","Public Viewing","Grillparty","Hausparty","Pyjamaparty","Dinnerparty",
                "Erstes Date","Vorstellungsgespräch","Prüfung","Führerscheinprüfung","Umzug","Wohnungsbesichtigung","Urlaubsreise","Campingtrip","Klassenfahrt","Betriebsausflug",
                "Konferenz","Messe","Workshop","Teammeeting","Gerichtstermin","Arzttermin","Impftermin","Fotoshooting","Livestream","Spieleabend",
                "Karaokeabend","Escape Room","Weinprobe","Kochkurs","Tanzkurs","Spendenlauf","Flohmarkt","Eröffnung","Abschiedsparty","Überraschungsparty"
            ],
            emoji: "🎉"
        ),

        Category(
            name: "Schule & Uni",
            words: [
                "Klassenzimmer","Hörsaal","Mensa","Bibliothek","Schulhof","Sekretariat","Lehrerzimmer","Spind","Tafel","Whiteboard",
                "Kreide","Marker","Schulranzen","Federmappe","Lineal","Geodreieck","Taschenrechner","Heft","Arbeitsblatt","Lehrbuch",
                "Hausaufgaben","Referat","Gruppenarbeit","Klausur","Prüfung","Mündliche Prüfung","Vokabeltest","Spickzettel","Sitznachbar","Pausenklingel",
                "Stundenplan","Vertretungsstunde","Freistunde","Nachhilfe","AG","Projektwoche","Klassenfahrt","Exkursion","Elternabend","Zeugnis",
                "Abitur","Bachelorarbeit","Masterarbeit","Vorlesung","Seminar","Tutorium","Praktikum","Labor","Campus","Studentenausweis",
                "BAföG","Semesterferien","Erstiwoche","Lerngruppe","PowerPoint","Notendruck","Kopierer","Rucksack","Schließfach","Schulbus"
            ],
            emoji: "🎓"
        ),
        Category(
            name: "Orte",
            words: [
                "Zuhause","Schule","Universität","Büro","Krankenhaus","Polizeiwache","Gefängnis","Kirche","Friedhof","Supermarkt",
                "Einkaufszentrum","Kino","Theater","Museum","Bibliothek","Fitnessstudio","Schwimmbad","Stadion","Zoo","Freizeitpark",
                "Zirkus","Spielplatz","Park","Wald","Strand","Wüste","Berg","Insel","Höhle","Bauernhof",
                "Bahnhof","Flughafen","Hafen","Tankstelle","Werkstatt","Restaurant","Café","Bar","Disko","Hotel",
                "Campingplatz","Bank","Post","Friseur","Apotheke","Bäckerei","Metzgerei","Kiosk","Toilette","Balkon",
                "Dachboden","Keller","Garage","Garten","Küche","Wohnzimmer","Schlafzimmer","Bad","Waschküche","Aufzug",
                "Bushaltestelle","Parkhaus","Gericht","Rathaus","Botschaft","Labor","Studio","Backstage","Spielhalle","Escape Room"
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
