import Foundation

/// Zentrale Datenquelle für Standard-Kategorien in allen Sprachen.
/// Um eine neue Sprache hinzuzufügen:
/// 1. Neue private Variable anlegen (z.B. `spanishCategories`)
/// 2. Im `switch` Statement in `getData(for:)` den neuen Case hinzufügen.
struct CategoryDefaultData {
    
    static func getData(for language: AppLanguage) -> [TimesUpCategory] {
        switch language {
        case .german:
            return germanCategories
        case .english:
            return englishCategories
        // HIER SPÄTER WEITERE SPRACHEN EINFÜGEN:
        // case .spanish: return spanishCategories
        // case .french: return frenchCategories
        @unknown default:
            return germanCategories
        }
    }
    
    // MARK: - DEUTSCH (German)
    private static var germanCategories: [TimesUpCategory] {
        let green = [
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

        let yellow = [
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

        let red = [
            "Deutschland", "Italien", "Spanien", "Frankreich", "USA", "China", "Japan", "Russland", "Brasilien", "Australien",
            "Berlin", "Paris", "London", "Rom", "New York", "Tokio", "Mallorca", "Hawaii", "Las Vegas", "Hollywood",
            "Ägypten", "Türkei", "Griechenland", "Schweden", "Schweiz", "Österreich", "Kanada", "Indien", "Mexiko", "Polen",
            "Eiffelturm", "Freiheitsstatue", "Kolosseum", "Chinesische Mauer", "Pyramiden", "Big Ben", "Brandenburger Tor", "Schiefer Turm von Pisa", "Taj Mahal", "Mount Everest",
            "Niagarafälle", "Grand Canyon", "Amazonas", "Nordpol", "Südpol", "Sahara", "Atlantik", "Pazifik", "Venedig", "Alps",
            "Angela Merkel", "Donald Trump", "Barack Obama", "Albert Einstein", "Mozart", "Beethoven", "Michael Jackson", "Elvis Presley", "Madonna", "Beyoncé",
            "Cristiano Ronaldo", "Lionel Messi", "Arnold Schwarzenegger", "Brad Pitt", "Angelina Jolie", "Leonardo DiCaprio", "Bill Gates", "Mark Zuckerberg", "Steve Jobs", "Elon Musk",
            "Papst", "Queen Elizabeth", "Kleopatra", "Caesar", "Napoleon", "Hitler", "Jesus", "Buddha", "Ghandi", "Martin Luther King",
            "Coca Cola", "McDonalds", "Burger King", "Apple", "Samsung", "Google", "Facebook", "Amazon", "Nike", "Adidas",
            "Ikea", "Lego", "Disney", "Netflix", "YouTube", "Mercedes", "BMW", "Audi", "Porsche", "Ferrari",
            "Volkswagen", "Tesla", "Red Bull", "Nutealla", "Haribo", "PlayStation", "Nintendo", "Xbox", "Starbucks", "Rolex"
        ].map { Term(text: $0) }

        let blue = [
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
        
        let kids = [
            "Schokolade", "Ferien", "Spielplatz", "Taschengeld", "Weihnachtsmarkt", "Ostern", "Zahnfee", "Geburtstag", "Schwimmbad", "Zoo",
            "Zirkus", "Clown", "Zauberer", "Hexe", "Gespenst", "Pirat", "Ritter", "Burg", "Prinzessin", "Drache",
            "Einhorn", "Dinosaurier", "Lego", "Playmobil", "Nintendo", "Minecraft", "Pokémon", "Harry Potter", "Die Eiskönigin", "Minions",
            "Paw Patrol", "Micky Maus", "Tom & Jerry", "Löwenzahn", "Sendung mit der Maus", "Sandmännchen", "Bibi & Tina", "Die drei ???", "TKKG", "Fußball",
            "Reiten", "Tanzen", "Verstecken", "Fangen", "Blinde Kuh", "Gummitwist", "Seilspringen", "Skateboard", "Inliner", "Fahrrad",
            "Roller", "Kettcar", "Bobbycar", "Schaukel", "Rutsche", "Wippe", "Sandkasten", "Klettergerüst", "Baumhaus", "Murmeln",
            "Flummi", "Jo-Jo", "Drachen steigen lassen", "Schneemann", "Schneeballschlacht", "Schlitten fahren", "Schlittschuh laufen", "Schwimmflügel", "Luftmatratze", "Wasserpistole",
            "Taucherbrille", "Schnorchel", "Flossen", "Badehose", "Badeanzug", "Bikini", "Sonnencreme", "Sonnenbrille", "Sonnenhut", "Kappe",
            "Mütze", "Schal", "Handschuhe", "Gummistiefel", "Regenjacke", "Regenschirm", "Schulranzen", "Mäppchen", "Füller", "Buntstifte",
            "Radiergummi", "Spitzer", "Lineal", "Schere", "Kleber", "Pinsel", "Malkasten", "Block", "Heft", "Buch", "Comic"
        ].map { Term(text: $0) }
        
        let teens = [
            "Smartphone", "WLAN", "Akku leer", "Ladekabel", "Kopfhörer", "Bluetooth", "Streaming", "Netflix", "Spotify", "YouTube",
            "TikTok", "Instagram", "Snapchat", "WhatsApp", "Emoji", "Selfie", "Filter", "Story", "Status", "Post",
            "Like", "Follower", "Influencer", "Youtuber", "Prank", "Challenge", "Trend", "Meme", "GIF", "Sticker",
            "Hashtag", "Verlinkung", "Markierung", "Kommentar", "Nachricht", "Sprachnachricht", "Gruppenchat", "Admin", "Blockieren", "Stummschalten",
            "Screenshot", "Bildschirmaufnahme", "Update", "App", "Download", "Upload", "Online", "Offline", "Gaming", "Zocken",
            "Konsole", "Controller", "Headset", "Tastatur", "Maus", "Monitor", "Laptop", "Tablet", "Fernseher", "Serie",
            "Film", "Kino", "Popcorn", "Nachos", "Cola", "Energy Drink", "Pizza", "Döner", "Burger", "Pommes",
            "Sushi", "Bubble Tea", "Starbucks", "Mäces", "Schule", "Hausaufgaben", "Klausur", "Note", "Zeugnis", "Ferien",
            "Abschluss", "Ausbildung", "Studium", "Nebenjob", "Taschengeld", "Führerschein", "Auto", "Roller", "Moped", "Bus",
            "Bahn", "Ticket", "Schwarzfahren", "Party", "Feiern", "Tanzen", "Musik", "Konzert", "Festival", "Freunde",
            "Clique", "Beziehung", "Kuss", "Liebe", "Liebeskummer", "Trennung", "Ex", "Schwarm", "Date", "Kompliment"
        ].map { Term(text: $0) }

        let fsk18 = [
            "Koks", "Hure", "Stripper", "Stripclub", "Dildo", "Penis", "Brüste", "Arsch", "Blowjob", "Orgasmus",
            "Puff", "Kondom", "Anal", "Lecken", "Reiten", "Stöhnen", "Erotik", "Sextoy", "Fesselspiel", "Peitsche",
            "Swingerclub", "Escort", "Camgirl", "Nippel", "Kiffen", "Ecstasy", "Dealer", "Bordell",
            "Handschellen", "Vibrator", "Pornostar", "One Night Stand", "Affäre", "Kamasutra", "Fetisch", "Domina",
            "Lack und Leder", "Sperma", "Schlucken", "Doggy Style", "69", "Dreier", "Gangbang", "Milf",
            "Sugar Daddy", "Callboy", "Gleitgel", "Viagra", "Pille", "Schwangerschaftstest", "Frauenarzt", "Urologe",
            "Rotlichtbezirk", "Darkroom", "Glory Hole", "Exhibitionist", "Voyeur", "Nacktstrand", "FKK", "Saunaclub",
            "Tinder Date", "Walk of Shame", "Kater", "Filmriss", "Saufspiel", "Bierpong", "Schnapsleiche", "Kotzen"
        ].map { Term(text: $0) }

        return [
            TimesUpCategory(name: "Sehr leicht", type: .green, terms: green),
            TimesUpCategory(name: "Leicht", type: .yellow, terms: yellow),
            TimesUpCategory(name: "Mittel", type: .red, terms: red),
            TimesUpCategory(name: "Schwere Kategorie", type: .blue, terms: blue),
            TimesUpCategory(name: "Kinder (7-12)", type: .kids, terms: kids),
            TimesUpCategory(name: "Jugendliche (13-17)", type: .teens, terms: teens),
            TimesUpCategory(name: "FSK 18", type: .custom, terms: fsk18)
        ]
    }
    
    // MARK: - ENGLISH
    private static var englishCategories: [TimesUpCategory] {
        let green = [
            "Cat", "Dog", "Mouse", "Fish", "Bird", "Rabbit", "Cow", "Horse", "Sheep", "Pig",
            "Duck", "Chicken", "Bear", "Lion", "Tiger", "Elephant", "Giraffe", "Monkey", "Penguin", "Frog",
            "Butterfly", "Bee", "Spider", "Snake", "Crocodile", "Rhino", "Zebra", "Donkey", "Hamster", "Parrot",
            "Ladybug", "Squirrel", "Fox", "Wolf", "Hedgehog", "Turtle", "Whale", "Dolphin", "Shark", "Seal",
            "Apple", "Banana", "Grape", "Strawberry", "Watermelon", "Bread", "Cheese", "Pizza", "Ice cream", "Cake",
            "Milk", "Water", "Juice", "Egg", "Sausage", "Fries", "Noodle", "Tomato", "Cucumber", "Carrot",
            "Chocolate", "Cookie", "Candy", "Soup", "Salad", "Jam", "Honey", "Butter", "Yogurt", "Pear",
            "Car", "Bus", "Train", "Airplane", "Ship", "Bicycle", "Scooter", "Ball", "Balloon", "Doll",
            "Teddy", "Backpack", "Shoe", "Hat", "Jacket", "Pants", "Dress", "Glasses", "Watch", "Key",
            "Lamp", "Table", "Chair", "Bed", "Sofa", "Door", "Window", "House", "Roof", "Stairs",
            "Toothbrush", "Soap", "Towel", "Comb", "Book", "Pen", "Plate", "Fork", "Spoon", "Glass",
            "Sun", "Moon", "Star", "Rain", "Snow", "Rainbow", "Cloud", "Tree", "Flower", "Leaf",
            "Stone", "Sand", "Sea", "Beach", "Lake", "Mountain", "Forest", "Meadow", "Fire", "Wind"
        ].map { Term(text: $0) }

        let yellow = [
            "Firefighter", "Police", "Doctor", "Baker", "Teacher", "Gardener", "Chef", "Pilot", "Seller", "Mailman",
            "Astronaut", "Clown", "Magician", "Pirate", "Knight", "King", "Princess", "Witch", "Fairy", "Vampire",
            "Detective", "Vet", "Builder", "Hairdresser", "Waiter", "Painter", "Singer", "Dancer", "Farmer", "Captain",
            "Harry Potter", "Mickey Mouse", "Spongebob", "Spiderman", "Batman", "Superman", "Elsa", "Pikachu", "Super Mario", "Darth Vader",
            "Simba", "Nemo", "Shrek", "Barbie", "James Bond", "Tarzan", "Pippi Longstocking", "Pinocchio", "Snow White", "Cinderella",
            "Minions", "Yoda", "Hulk", "Iron Man", "Little Red Riding Hood", "Frog King", "Hansel and Gretel", "Maya the Bee", "Vicky the Viking", "Garfield",
            "Soccer", "Tennis", "Basketball", "Swimming", "Dancing", "Riding", "Painting", "Singing", "Cooking", "Reading",
            "Fishing", "Hiking", "Skiing", "Camping", "Bowling", "Karate", "Chess", "Yoga", "Jogging", "Boxing",
            "Cinema", "Zoo", "School", "Church", "Castle", "Palace", "Island", "Farm", "Supermarket", "Hospital",
            "Television", "Computer", "Mobile phone", "Tablet", "Camera", "Guitar", "Piano", "Drum", "Violin", "Flute",
            "Robot", "Rocket", "UFO", "Ghost", "Mummy", "Monster", "Alien", "Dragon", "Unicorn", "Mermaid"
        ].map { Term(text: $0) }

        let red = [
            "Germany", "Italy", "Spain", "France", "USA", "China", "Japan", "Russia", "Brazil", "Australia",
            "Berlin", "Paris", "London", "Rome", "New York", "Tokyo", "Mallorca", "Hawaii", "Las Vegas", "Hollywood",
            "Egypt", "Turkey", "Greece", "Sweden", "Switzerland", "Austria", "Canada", "India", "Mexico", "Poland",
            "Eiffel Tower", "Statue of Liberty", "Colosseum", "Great Wall of China", "Pyramids", "Big Ben", "Brandenburg Gate", "Leaning Tower of Pisa", "Taj Mahal", "Mount Everest",
            "Niagara Falls", "Grand Canyon", "Amazon", "North Pole", "South Pole", "Sahara", "Atlantic", "Pacific", "Venice", "Alps",
            "Angela Merkel", "Donald Trump", "Barack Obama", "Albert Einstein", "Mozart", "Beethoven", "Michael Jackson", "Elvis Presley", "Madonna", "Beyoncé",
            "Cristiano Ronaldo", "Lionel Messi", "Arnold Schwarzenegger", "Brad Pitt", "Angelina Jolie", "Leonardo DiCaprio", "Bill Gates", "Mark Zuckerberg", "Steve Jobs", "Elon Musk",
            "Pope", "Queen Elizabeth", "Cleopatra", "Caesar", "Napoleon", "Hitler", "Jesus", "Buddha", "Ghandi", "Martin Luther King",
            "Coca Cola", "McDonalds", "Burger King", "Apple", "Samsung", "Google", "Facebook", "Amazon", "Nike", "Adidas",
            "Ikea", "Lego", "Disney", "Netflix", "YouTube", "Mercedes", "BMW", "Audi", "Porsche", "Ferrari",
            "Volkswagen", "Tesla", "Red Bull", "Nutella", "Haribo", "PlayStation", "Nintendo", "Xbox", "Starbucks", "Rolex"
        ].map { Term(text: $0) }

        let blue = [
            "Atom", "Molecule", "DNA", "Genetics", "Evolution", "Gravity", "Theory of Relativity", "Photosynthesis", "Oxygen", "Carbon Dioxide",
            "Microscope", "Telescope", "Satellite", "Algorithm", "Artificial Intelligence", "Blockchain", "Cryptocurrency", "Quantum Physics", "Black Hole", "Supernova",
            "Meteorite", "Asteroid", "Comet", "Galaxy", "Universe", "Vacuum", "Radioactivity", "Nuclear Fusion", "Ozone Hole", "Climate Change",
            "Democracy", "Dictatorship", "Monarchy", "Communism", "Capitalism", "Revolution", "Inflation", "Globalization", "Fall of the Wall", "World War",
            "Middle Ages", "Renaissance", "Antiquity", "Stone Age", "Industrialization", "Colonialism", "Slavery", "Holocaust", "Apartheid", "Civil War",
            "Constitution", "Parliament", "Senate", "Minister", "President", "Chancellor", "Ambassador", "Spy", "Diplomat", "Veto",
            "Goethe", "Schiller", "Shakespeare", "Da Vinci", "Picasso", "Van Gogh", "Dali", "Rembrandt", "Michelangelo", "Monet",
            "Mona Lisa", "The Scream", "Bible", "Koran", "Torah", "Philosophy", "Psychology", "Sociology", "Archaeology", "Astronomy",
            "Opera", "Ballet", "Theater", "Orchestra", "Symphony", "Literature", "Poetry", "Novel", "Drama", "Comedy",
            "Kaleidoscope", "Labyrinth", "Oasis", "Mirage", "Echo", "Shadow", "Silhouette", "Horizon", "Volcanic Ash", "Stalactite",
            "Hieroglyphics", "Mummification", "Sarcophagus", "Obelisk", "Cathedral", "Mosque", "Synagogue", "Temple", "Pagoda", "Skyscraper"
        ].map { Term(text: $0) }
        
        let kids = [
            "Chocolate", "Vacation", "Playground", "Pocket money", "Christmas market", "Easter", "Tooth fairy", "Birthday", "Swimming pool", "Zoo",
            "Circus", "Clown", "Magician", "Witch", "Ghost", "Pirate", "Knight", "Castle", "Princess", "Dragon",
            "Unicorn", "Dinosaur", "Lego", "Playmobil", "Nintendo", "Minecraft", "Pokémon", "Harry Potter", "Frozen", "Minions",
            "Paw Patrol", "Mickey Mouse", "Tom & Jerry", "Sesame Street", "SpongeBob", "Sandman", "Peppa Pig", "Scooby Doo", "Looney Tunes", "Soccer",
            "Horse riding", "Dancing", "Hide and seek", "Tag", "Blind man's buff", "Hopscotch", "Jump rope", "Skateboard", "Rollerblades", "Bicycle",
            "Scooter", "Go-kart", "Bobby car", "Swing", "Slide", "Seesaw", "Sandbox", "Climbing frame", "Tree house", "Marbles",
            "Bouncy ball", "Yo-yo", "Flying a kite", "Snowman", "Snowball fight", "Sledding", "Ice skating", "Water wings", "Air mattress", "Water pistol",
            "Goggles", "Snorkel", "Fins", "Swimming trunks", "Swimsuit", "Bikini", "Sunscreen", "Sunglasses", "Sun hat", "Cap",
            "Beanie", "Scarf", "Gloves", "Rubber boots", "Rain jacket", "Umbrella", "School bag", "Pencil case", "Fountain pen", "Colored pencils",
            "Eraser", "Sharpener", "Ruler", "Scissors", "Glue", "Brush", "Paint box", "Pad", "Notebook", "Book", "Comic"
        ].map { Term(text: $0) }
        
        let teens = [
            "Smartphone", "WiFi", "Battery empty", "Charging cable", "Headphones", "Bluetooth", "Streaming", "Netflix", "Spotify", "YouTube",
            "TikTok", "Instagram", "Snapchat", "WhatsApp", "Emoji", "Selfie", "Filter", "Story", "Status", "Post",
            "Like", "Follower", "Influencer", "Youtuber", "Prank", "Challenge", "Trend", "Meme", "GIF", "Sticker",
            "Hashtag", "Tag", "Mention", "Comment", "Message", "Voice message", "Group chat", "Admin", "Block", "Mute",
            "Screenshot", "Screen recording", "Update", "App", "Download", "Upload", "Online", "Offline", "Gaming", "Gambling",
            "Console", "Controller", "Headset", "Keyboard", "Mouse", "Monitor", "Laptop", "Tablet", "TV", "Series",
            "Movie", "Cinema", "Popcorn", "Nachos", "Coke", "Energy Drink", "Pizza", "Kebab", "Burger", "Fries",
            "Sushi", "Bubble Tea", "Starbucks", "McDonalds", "School", "Homework", "Exam", "Grade", "Report card", "Holidays",
            "Graduation", "Apprenticeship", "University", "Part-time job", "Allowance", "Driver's license", "Car", "Scooter", "Moped", "Bus",
            "Train", "Ticket", "Fare dodging", "Party", "Celebrating", "Dancing", "Music", "Concert", "Festival", "Friends",
            "Squad", "Relationship", "Kiss", "Love", "Heartbreak", "Breakup", "Ex", "Crush", "Date", "Compliment"
        ].map { Term(text: $0) }

        let fsk18 = [
            "Cocaine", "Whore", "Stripper", "Strip club", "Dildo", "Penis", "Breasts", "Ass", "Blowjob", "Orgasm",
            "Brothel", "Condom", "Anal", "Licking", "Riding", "Groaning", "Erotica", "Sex toy", "Bondage", "Whip",
            "Swinger club", "Escort", "Camgirl", "Nipple", "Smoking weed", "Ecstasy", "Dealer", "Bordello",
            "Handcuffs", "Vibrator", "Porn star", "One night stand", "Affair", "Kamasutra", "Fetish", "Domina",
            "Latex and leather", "Sperm", "Swallowing", "Doggy style", "69", "Threesome", "Gangbang", "Milf",
            "Sugar daddy", "Callboy", "Lube", "Viagra", "The pill", "Pregnancy test", "Gynecologist", "Urologist",
            "Red light district", "Darkroom", "Glory hole", "Exhibitionist", "Voyeur", "Nude beach", "Nudism", "Sauna club",
            "Tinder date", "Walk of shame", "Hangover", "Blackout", "Drinking game", "Beer pong", "Dead drunk", "Vomiting"
        ].map { Term(text: $0) }

        return [
            TimesUpCategory(name: "Very easy", type: .green, terms: green),
            TimesUpCategory(name: "Easy", type: .yellow, terms: yellow),
            TimesUpCategory(name: "Medium", type: .red, terms: red),
            TimesUpCategory(name: "Hard category", type: .blue, terms: blue),
            TimesUpCategory(name: "Kids (7-12)", type: .kids, terms: kids),
            TimesUpCategory(name: "Teens (13-17)", type: .teens, terms: teens),
            TimesUpCategory(name: "18+", type: .custom, terms: fsk18)
        ]
    }
}