import Foundation

struct AlphabetChallenges {
    static let data: [Challenge] = [
        // Geografie
        Challenge(text: "Bis zu welchem Buchstaben kommst du bei Ländern?", category: .alphabet, inputType: .alphabet),
        Challenge(text: "Bis zu welchem Buchstaben kommst du bei europäischen Städten?", category: .alphabet, inputType: .alphabet),
        Challenge(text: "Bis zu welchem Buchstaben kommst du bei deutschen Städten?", category: .alphabet, inputType: .alphabet),
        Challenge(text: "Bis zu welchem Buchstaben kommst du bei Flüssen weltweit?", category: .alphabet, inputType: .alphabet),
        
        // Alltag & Marken
        Challenge(text: "Bis zu welchem Buchstaben kommst du bei Automarken?", category: .alphabet, inputType: .alphabet),
        Challenge(text: "Bis zu welchem Buchstaben kommst du bei Kleidungsmarken?", category: .alphabet, inputType: .alphabet),
        Challenge(text: "Bis zu welchem Buchstaben kommst du bei Dingen, die man im Supermarkt kauft?", category: .alphabet, inputType: .alphabet),
        Challenge(text: "Bis zu welchem Buchstaben kommst du bei Obst- oder Gemüsesorten?", category: .alphabet, inputType: .alphabet),
        Challenge(text: "Bis zu welchem Buchstaben kommst du bei Süßigkeiten?", category: .alphabet, inputType: .alphabet),
        
        // Natur & Tiere
        Challenge(text: "Bis zu welchem Buchstaben kommst du bei Tieren?", category: .alphabet, inputType: .alphabet),
        Challenge(text: "Bis zu welchem Buchstaben kommst du bei Hunderassen?", category: .alphabet, inputType: .alphabet),
        
        // Wissen & Kultur
        Challenge(text: "Bis zu welchem Buchstaben kommst du bei Berufen?", category: .alphabet, inputType: .alphabet),
        Challenge(text: "Bis zu welchem Buchstaben kommst du bei weiblichen Vornamen?", category: .alphabet, inputType: .alphabet),
        Challenge(text: "Bis zu welchem Buchstaben kommst du bei männlichen Vornamen?", category: .alphabet, inputType: .alphabet),
        Challenge(text: "Bis zu welchem Buchstaben kommst du bei Sportarten?", category: .alphabet, inputType: .alphabet),
        Challenge(text: "Bis zu welchem Buchstaben kommst du bei Körperteilen?", category: .alphabet, inputType: .alphabet),
        
        // Medien
        Challenge(text: "Bis zu welchem Buchstaben kommst du bei Disney-Charakteren?", category: .alphabet, inputType: .alphabet),
        Challenge(text: "Bis zu welchem Buchstaben kommst du bei Harry Potter Charakteren?", category: .alphabet, inputType: .alphabet),
        Challenge(text: "Bis zu welchem Buchstaben kommst du bei berühmten Prominenten (Nachname)?", category: .alphabet, inputType: .alphabet),
        
        // Essen & Trinken
        Challenge(text: "Bis zu welchem Buchstaben kommst du bei Getränken?", category: .alphabet, inputType: .alphabet),
        Challenge(text: "Bis zu welchem Buchstaben kommst du bei Cocktails?", category: .alphabet, inputType: .alphabet),
        Challenge(text: "Bis zu welchem Buchstaben kommst du bei Gerichten (weltweit)?", category: .alphabet, inputType: .alphabet),
        Challenge(text: "Bis zu welchem Buchstaben kommst du bei Fast-Food-Ketten?", category: .alphabet, inputType: .alphabet),
        Challenge(text: "Bis zu welchem Buchstaben kommst du bei Gewürzen?", category: .alphabet, inputType: .alphabet),
        Challenge(text: "Bis zu welchem Buchstaben kommst du bei Käsesorten?", category: .alphabet, inputType: .alphabet),
        Challenge(text: "Bis zu welchem Buchstaben kommst du bei Brotsorten?", category: .alphabet, inputType: .alphabet),
        Challenge(text: "Bis zu welchem Buchstaben kommst du bei Frühstücks-Sachen?", category: .alphabet, inputType: .alphabet),

        // Orte & Reisen
        Challenge(text: "Bis zu welchem Buchstaben kommst du bei Urlaubsländern?", category: .alphabet, inputType: .alphabet),
        Challenge(text: "Bis zu welchem Buchstaben kommst du bei Inseln?", category: .alphabet, inputType: .alphabet),
        Challenge(text: "Bis zu welchem Buchstaben kommst du bei Sehenswürdigkeiten?", category: .alphabet, inputType: .alphabet),
        Challenge(text: "Bis zu welchem Buchstaben kommst du bei Bergen?", category: .alphabet, inputType: .alphabet),
        Challenge(text: "Bis zu welchem Buchstaben kommst du bei Meeren oder Ozeanen?", category: .alphabet, inputType: .alphabet),
        Challenge(text: "Bis zu welchem Buchstaben kommst du bei Flughäfen (Stadt/Name)?", category: .alphabet, inputType: .alphabet),

        // Unterhaltung & Medien
        Challenge(text: "Bis zu welchem Buchstaben kommst du bei Filmtiteln?", category: .alphabet, inputType: .alphabet),
        Challenge(text: "Bis zu welchem Buchstaben kommst du bei Serien?", category: .alphabet, inputType: .alphabet),
        Challenge(text: "Bis zu welchem Buchstaben kommst du bei Videospielen?", category: .alphabet, inputType: .alphabet),
        Challenge(text: "Bis zu welchem Buchstaben kommst du bei Superhelden?", category: .alphabet, inputType: .alphabet),
        Challenge(text: "Bis zu welchem Buchstaben kommst du bei Bösewichten (Film/Serie)?", category: .alphabet, inputType: .alphabet),
        Challenge(text: "Bis zu welchem Buchstaben kommst du bei Rappern (Vorname)?", category: .alphabet, inputType: .alphabet),
        Challenge(text: "Bis zu welchem Buchstaben kommst du bei Bands?", category: .alphabet, inputType: .alphabet),
        Challenge(text: "Bis zu welchem Buchstaben kommst du bei Songs (Titel)?", category: .alphabet, inputType: .alphabet),

        // Alltag & Zuhause
        Challenge(text: "Bis zu welchem Buchstaben kommst du bei Dingen im Badezimmer?", category: .alphabet, inputType: .alphabet),
        Challenge(text: "Bis zu welchem Buchstaben kommst du bei Dingen in der Küche?", category: .alphabet, inputType: .alphabet),
        Challenge(text: "Bis zu welchem Buchstaben kommst du bei Haushaltsgeräten?", category: .alphabet, inputType: .alphabet),
        Challenge(text: "Bis zu welchem Buchstaben kommst du bei Möbeln?", category: .alphabet, inputType: .alphabet),
        Challenge(text: "Bis zu welchem Buchstaben kommst du bei Putzmitteln?", category: .alphabet, inputType: .alphabet),
        Challenge(text: "Bis zu welchem Buchstaben kommst du bei Dingen, die man in der Schule findet?", category: .alphabet, inputType: .alphabet),

        // Technik & Online
        Challenge(text: "Bis zu welchem Buchstaben kommst du bei Apps?", category: .alphabet, inputType: .alphabet),
        Challenge(text: "Bis zu welchem Buchstaben kommst du bei Social-Media-Plattformen?", category: .alphabet, inputType: .alphabet),
        Challenge(text: "Bis zu welchem Buchstaben kommst du bei Handy-Herstellern?", category: .alphabet, inputType: .alphabet),
        Challenge(text: "Bis zu welchem Buchstaben kommst du bei Gaming-Konsolen?", category: .alphabet, inputType: .alphabet),
        Challenge(text: "Bis zu welchem Buchstaben kommst du bei Streaming-Diensten?", category: .alphabet, inputType: .alphabet),

        // Sport & Fitness
        Challenge(text: "Bis zu welchem Buchstaben kommst du bei Fußballvereinen?", category: .alphabet, inputType: .alphabet),
        Challenge(text: "Bis zu welchem Buchstaben kommst du bei Sportlern (Nachname)?", category: .alphabet, inputType: .alphabet),
        Challenge(text: "Bis zu welchem Buchstaben kommst du bei Fitnessübungen?", category: .alphabet, inputType: .alphabet),
        Challenge(text: "Bis zu welchem Buchstaben kommst du bei Muskeln (z.B. Bizeps)?", category: .alphabet, inputType: .alphabet),

        // Sprache & Wissen
        Challenge(text: "Bis zu welchem Buchstaben kommst du bei Adjektiven (z.B. schön, schnell)?", category: .alphabet, inputType: .alphabet),
        Challenge(text: "Bis zu welchem Buchstaben kommst du bei Verben (z.B. laufen, essen)?", category: .alphabet, inputType: .alphabet),
        Challenge(text: "Bis zu welchem Buchstaben kommst du bei Dingen, die man im Büro hat?", category: .alphabet, inputType: .alphabet),
        Challenge(text: "Bis zu welchem Buchstaben kommst du bei Schulfächern?", category: .alphabet, inputType: .alphabet),
        Challenge(text: "Bis zu welchem Buchstaben kommst du bei Sprachen?", category: .alphabet, inputType: .alphabet),
        Challenge(text: "Bis zu welchem Buchstaben kommst du bei Planeten & Himmelskörpern?", category: .alphabet, inputType: .alphabet),

        // Fun & Random
        Challenge(text: "Bis zu welchem Buchstaben kommst du bei Emojis (beschreiben statt zeigen)?", category: .alphabet, inputType: .alphabet),
        Challenge(text: "Bis zu welchem Buchstaben kommst du bei Schimpfwörtern (light)?", category: .alphabet, inputType: .alphabet),
        Challenge(text: "Bis zu welchem Buchstaben kommst du bei Kosenamen?", category: .alphabet, inputType: .alphabet),
        Challenge(text: "Bis zu welchem Buchstaben kommst du bei Dingen, die man im Urlaub braucht?", category: .alphabet, inputType: .alphabet),
        Challenge(text: "Bis zu welchem Buchstaben kommst du bei Dingen, die man im Auto findet?", category: .alphabet, inputType: .alphabet),
        Challenge(text: "Bis zu welchem Buchstaben kommst du bei Dingen, die man am Strand sieht?", category: .alphabet, inputType: .alphabet)
    ]
}
