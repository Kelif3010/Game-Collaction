import Foundation

// MARK: - Questions Mode Models

public struct QuestionsCategory: Identifiable, Hashable, Codable {
    public let id: UUID
    public var name: String
    public var promptPairs: [QuestionsPromptPair]

    public init(id: UUID = UUID(), name: String, promptPairs: [QuestionsPromptPair]) {
        self.id = id
        self.name = name
        self.promptPairs = promptPairs
    }
}

public struct QuestionsPromptPair: Identifiable, Hashable, Codable {
    public let id: UUID
    public var topic: String?
    public var citizenQuestion: String
    public var spyQuestion: String

    public init(id: UUID = UUID(), topic: String? = nil, citizenQuestion: String, spyQuestion: String) {
        self.id = id
        self.topic = topic
        self.citizenQuestion = citizenQuestion
        self.spyQuestion = spyQuestion
    }
}

public enum QuestionsRole: String, Codable, Hashable {
    case citizen
    case spy
}

public struct QuestionsAnswer: Identifiable, Hashable, Codable {
    public let id: UUID
    public let playerID: UUID
    public let role: QuestionsRole
    public var text: String
    public var timestamp: Date
    public var timeTaken: TimeInterval

    public init(id: UUID = UUID(), playerID: UUID, role: QuestionsRole, text: String, timestamp: Date = Date(), timeTaken: TimeInterval = 0) {
        self.id = id
        self.playerID = playerID
        self.role = role
        self.text = text
        self.timestamp = timestamp
        self.timeTaken = timeTaken
    }
}

public enum QuestionsPhase: String, Codable, Hashable {
    case setup
    case collecting // players answering their prompts
    case revealed   // citizen question revealed
    case overview   // list all answers
    case voting     // voting phase
    case finished
}

struct QuestionsConfig: Codable {
    var numberOfSpies: Int
    var selectedCategory: QuestionsCategory?
    var discussionTime: TimeInterval // 0 = Unlimited
    var players: [Player]

    init(numberOfSpies: Int = 1, selectedCategory: QuestionsCategory? = nil, discussionTime: TimeInterval = 180, players: [Player] = []) {
        self.numberOfSpies = numberOfSpies
        self.selectedCategory = selectedCategory
        self.discussionTime = discussionTime
        self.players = players
    }
}

struct QuestionsVoteCastPayload: Codable {
    let voterID: UUID
    let votes: [UUID: Int]
}

struct QuestionsVotingStatusPayload: Codable {
    let isActive: Bool
    let resetVotes: Bool
    let voteCounts: [UUID: Int]
}

struct QuestionsTimerSyncPayload: Codable {
    let timeRemaining: TimeInterval
    let isTimerPaused: Bool
    let hostUptime: TimeInterval
}

struct QuestionsTimeSyncPingPayload: Codable {
    let clientName: String
    let pingId: UUID
    let clientSendUptime: TimeInterval
}

struct QuestionsTimeSyncPongPayload: Codable {
    let clientName: String
    let pingId: UUID
    let clientSendUptime: TimeInterval
    let hostReceiveUptime: TimeInterval
    let hostSendUptime: TimeInterval
}

struct QuestionsRoleAckPayload: Codable {
    let playerName: String
}

struct QuestionsRejoinRequestPayload: Codable {
    let playerName: String
    let playerID: UUID
}

struct QuestionsRejoinStatePayload: Codable {
    let config: QuestionsConfig
    let roundState: QuestionsRoundState?
    let role: QuestionsRolePayload?
    let votingStatus: QuestionsVotingStatusPayload?
    let evaluation: QuestionsVoteEvaluation?
    let timerSync: QuestionsTimerSyncPayload?
}

struct QuestionsHostActivityPayload: Codable {
    let message: String
}

public struct QuestionsRoundState: Hashable, Codable {
    public var roundIndex: Int
    public var promptPair: QuestionsPromptPair
    public var phase: QuestionsPhase
    public var currentPlayerIndex: Int
    public var answers: [UUID: QuestionsAnswer] // playerID -> answer
    public var votes: [UUID: UUID] // voterID -> targetPlayerID

    public init(roundIndex: Int, promptPair: QuestionsPromptPair, phase: QuestionsPhase = .collecting, currentPlayerIndex: Int = 0, answers: [UUID: QuestionsAnswer] = [:], votes: [UUID: UUID] = [:]) {
        self.roundIndex = roundIndex
        self.promptPair = promptPair
        self.phase = phase
        self.currentPlayerIndex = currentPlayerIndex
        self.answers = answers
        self.votes = votes
    }
}

public enum QuestionsDefaults {
    
    // MARK: - Alltag
    public static let everyday = QuestionsCategory(
        name: "Alltag",
        promptPairs: [
            // Bürger: Wasser / Spion: Kaffee (Beides Mengenfragen)
            QuestionsPromptPair(topic: "Getränke", citizenQuestion: "Wie viele Gläser Wasser trinkst du am Tag?", spyQuestion: "Wie viele Tassen Kaffee trinkst du am Tag?"),
            
            // Bürger: Wecker / Spion: Aufstehen ohne Wecker (Beides Uhrzeiten)
            QuestionsPromptPair(topic: "Aufstehen", citizenQuestion: "Wann klingelt dein Wecker unter der Woche?", spyQuestion: "Wann stehst du am Wochenende normalerweise auf?"),
            
            // Bürger: Arbeitsweg / Spion: Zeit im Bad (Beides Dauer in Minuten)
            QuestionsPromptPair(topic: "Zeit", citizenQuestion: "Wie lange brauchst du morgens zur Arbeit/Uni?", spyQuestion: "Wie lange brauchst du morgens im Bad?"),
            
            // Bürger: Kochen / Spion: Bestellen (Beides Frequenz)
            QuestionsPromptPair(topic: "Essen", citizenQuestion: "Wie oft in der Woche kochst du frisch?", spyQuestion: "Wie oft in der Woche bestellst du Essen?"),
            
            // Bürger: Lieblingssport / Spion: TV-Sport (Beides Sportarten, die man mag)
            QuestionsPromptPair(topic: "Sport", citizenQuestion: "Welchen Sport machst du selbst am liebsten?", spyQuestion: "Welchen Sport schaust du am liebsten im Fernsehen?"),
            
            // Bürger: Schlafengehen / Spion: Handy weglegen (Beides Uhrzeiten abends)
            QuestionsPromptPair(topic: "Schlaf", citizenQuestion: "Um wie viel Uhr schläfst du meistens ein?", spyQuestion: "Um wie viel Uhr legst du dein Handy weg?"),
            
            // Bürger: Mag ich / Spion: Delegiere ich (Beides Hausarbeit, Fokus verschoben)
            QuestionsPromptPair(topic: "Haushalt", citizenQuestion: "Welche Hausarbeit machst du am ehesten gern?", spyQuestion: "Welche Hausarbeit würdest du sofort an eine Putzhilfe abgeben?"),
            
            QuestionsPromptPair(topic: "Social Media", citizenQuestion: "Auf welcher App verbringst du die meiste Zeit?", spyQuestion: "Welche App öffnest du morgens als erstes?"),
            
            // Bürger: Viel Geld / Spion: Zu wenig Geld (Beides Ausgaben)
            QuestionsPromptPair(topic: "Geld", citizenQuestion: "Wofür gibst du gerne viel Geld aus?", spyQuestion: "Wofür gibst du ungern Geld aus, musst aber?"),
            
            QuestionsPromptPair(topic: "Reisen", citizenQuestion: "Welches Land steht bei dir ganz oben auf der Reiseliste?", spyQuestion: "Welche Stadt steht bei dir als nächstes auf der Reiseliste?"),
            
            QuestionsPromptPair(topic: "Technik", citizenQuestion: "Welches Gadget benutzt du täglich?", spyQuestion: "Auf welches Gadget könntest du nicht verzichten?"),
            
            QuestionsPromptPair(topic: "Wochentag", citizenQuestion: "Welcher ist dein produktivster Wochentag?", spyQuestion: "Welcher ist dein entspanntester Wochentag?"),
            
            // Bürger: Gäste / Spion: Familie (Beides Gerichte)
            QuestionsPromptPair(topic: "Kochen", citizenQuestion: "Welches Gericht kochst du, wenn Gäste kommen?", spyQuestion: "Welches Gericht kochst du nur für dich alleine?"),
            
            // Bürger: Anrufen / Spion: Schreiben (Beides Personen)
            QuestionsPromptPair(topic: "Familie", citizenQuestion: "Wen aus deiner Familie rufst du am häufigsten an?", spyQuestion: "Wem aus deiner Familie schreibst du am häufigsten?"),
            
            // Bürger: Wohlfühlen / Spion: Zu heiß (Beides Temperaturen)
            QuestionsPromptPair(topic: "Wetter", citizenQuestion: "Bei wie viel Grad fühlst du dich am wohlsten?", spyQuestion: "Ab wie viel Grad ist es dir zu heiß?"),
            
            // Bürger: Entspannen / Spion: Feiern (Beides Musikgenres)
            QuestionsPromptPair(topic: "Musik", citizenQuestion: "Welches Genre hörst du zum Entspannen?", spyQuestion: "Welches Genre hörst du zum Feiern?"),
            
            QuestionsPromptPair(topic: "Serien", citizenQuestion: "Welche Serie hast du zuletzt geschaut?", spyQuestion: "Welche Serie ist deine absolute Lieblingsserie?"),
            
            QuestionsPromptPair(topic: "Snacks", citizenQuestion: "Was snackst du am liebsten zu Hause?", spyQuestion: "Was snackst du am liebsten unterwegs?"),
            
            QuestionsPromptPair(topic: "Pause", citizenQuestion: "Was machst du in deiner Mittagspause?", spyQuestion: "Was machst du direkt nach Feierabend?"),
            
            QuestionsPromptPair(topic: "Messenger", citizenQuestion: "Über welchen Messenger schreibst du am meisten?", spyQuestion: "Welche Social Media App nutzt du am wenigsten?"),
            
            QuestionsPromptPair(topic: "Wohnen", citizenQuestion: "In welchem Zimmer hältst du dich am meisten auf?", spyQuestion: "Welches Zimmer in deiner Wohnung magst du am liebsten?"),
            
            QuestionsPromptPair(topic: "Frühstück", citizenQuestion: "Was isst du typischerweise zum Frühstück?", spyQuestion: "Was isst du am liebsten zum Sonntagsbrunch?"),
            
            QuestionsPromptPair(topic: "Schuhe", citizenQuestion: "Wie viele Paar Schuhe besitzt du ungefähr?", spyQuestion: "Wie viele Paar Schuhe trägst du wirklich regelmäßig?"),
            
            QuestionsPromptPair(topic: "Nachricht", citizenQuestion: "Wem hast du zuletzt eine Nachricht geschrieben?", spyQuestion: "Von wem hast du die letzte Nachricht erhalten?"),
            QuestionsPromptPair(topic: "Screen Time", citizenQuestion: "Wie viele Stunden bist du täglich am Handy?", spyQuestion: "Wie viele Stunden verbringst du täglich vor Bildschirmen (PC/TV)?"),
            QuestionsPromptPair(topic: "Ordnung", citizenQuestion: "Wie oft räumst du deine Wohnung auf?", spyQuestion: "Wie oft putzt du deine Wohnung gründlich?"),
            QuestionsPromptPair(topic: "Aufgaben", citizenQuestion: "Was schiebst du am liebsten auf?", spyQuestion: "Was vergisst du im Alltag am häufigsten?"),
            QuestionsPromptPair(topic: "Pünktlichkeit", citizenQuestion: "Wie viele Minuten bist du typischerweise zu spät?", spyQuestion: "Wie viele Minuten bist du typischerweise zu früh?"),
            QuestionsPromptPair(topic: "Schnell essen", citizenQuestion: "Was isst du, wenn es schnell gehen muss?", spyQuestion: "Was isst du oft unterwegs?"),
            QuestionsPromptPair(topic: "Transport", citizenQuestion: "Welches Verkehrsmittel nutzt du am häufigsten?", spyQuestion: "Welches Verkehrsmittel nutzt du am liebsten?"),
            QuestionsPromptPair(topic: "Kleidung", citizenQuestion: "Was ist dein liebstes Kleidungsstück?", spyQuestion: "Was ist dein bequemstes Kleidungsstück?"),
            QuestionsPromptPair(topic: "Hygiene", citizenQuestion: "Wie oft duschst du in der Woche?", spyQuestion: "Wie oft wäschst du deine Haare in der Woche?"),
            QuestionsPromptPair(topic: "Freizeit", citizenQuestion: "Was machst du typischerweise sonntags?", spyQuestion: "Was machst du an einem freien Brückentag?"),
            QuestionsPromptPair(topic: "Dabei", citizenQuestion: "Was hast du immer in deiner Tasche dabei?", spyQuestion: "Was hast du immer in deiner Jackentasche?"),
            QuestionsPromptPair(topic: "Schlafen", citizenQuestion: "In welcher Position schläfst du ein?", spyQuestion: "In welcher Position wachst du meistens auf?"),
            QuestionsPromptPair(topic: "Termine", citizenQuestion: "Wie oft gehst du zum Friseur?", spyQuestion: "Wie oft gehst du zur Vorsorge (Zahnarzt/Arzt)?"),
            QuestionsPromptPair(topic: "Zuhause", citizenQuestion: "Was machst du als Erstes, wenn du nach Hause kommst?", spyQuestion: "Was machst du als Letztes, bevor du das Haus verlässt?")
        ]
    )
    
    // MARK: - Liebe & Beziehungen
    public static let loveRelationships = QuestionsCategory(
        name: "Liebe & Beziehungen",
        promptPairs: [
            // Bürger: Erstes Date / Spion: Jahrestag (Beides Orte für Dates)
            QuestionsPromptPair(topic: "Dating-Ort", citizenQuestion: "Was ist ein guter Ort für das erste Date?", spyQuestion: "Was ist ein guter Ort, um einen Jahrestag zu feiern?"),
            
            // Bürger: Partner / Spion: Bester Freund (Beides Eigenschaften von geliebten Menschen)
            QuestionsPromptPair(topic: "Eigenschaften", citizenQuestion: "Welche Eigenschaft ist dir bei einem Partner am wichtigsten?", spyQuestion: "Welche Eigenschaft schätzt du an deinem besten Freund am meisten?"),
            
            // Bürger: Bekommen / Spion: Verschenkt (Beides Geschenke)
            QuestionsPromptPair(topic: "Geschenke", citizenQuestion: "Was war das schönste Geschenk, das du je bekommen hast?", spyQuestion: "Was war das schönste Geschenk, das du je verschenkt hast?"),
            
            // Bürger: Partner / Spion: Freunde (Beides Gesprächsthemen)
            QuestionsPromptPair(topic: "Kommunikation", citizenQuestion: "Worüber redest du mit deinem Partner am liebsten?", spyQuestion: "Worüber redest du mit engen Freunden am liebsten?"),
            
            // Bürger: Beziehung / Spion: Persönlich (Beides Zukunftsvisionen)
            QuestionsPromptPair(topic: "Zukunft", citizenQuestion: "Wo siehst du dich beziehungstechnisch in 5 Jahren?", spyQuestion: "Wo siehst du dich persönlich/wohnlich in 5 Jahren?"),
            
            QuestionsPromptPair(topic: "Konflikt", citizenQuestion: "Wie reagierst du, wenn du sauer auf deinen Partner bist?", spyQuestion: "Wie reagierst du, wenn du enttäuscht von deinem Partner bist?"),
            
            // Bürger: Pärchenurlaub / Spion: Urlaub mit Freunden (Beides Urlaubs-Prioritäten)
            QuestionsPromptPair(topic: "Urlaub", citizenQuestion: "Was ist dir im Pärchenurlaub am wichtigsten?", spyQuestion: "Was ist dir im Urlaub mit Freunden am wichtigsten?"),
            
            // Bürger: Letzte Beziehung / Spion: Letztes Date (Beides Learnings)
            QuestionsPromptPair(topic: "Erfahrung", citizenQuestion: "Was hast du aus deiner letzten Beziehung gelernt?", spyQuestion: "Was hast du aus deinem letzten Date gelernt?"),
            
            // Bürger: Zeigen / Spion: Erwarten (Beides Zuneigung)
            QuestionsPromptPair(topic: "Liebessprache", citizenQuestion: "Wie zeigst du Zuneigung am ehesten?", spyQuestion: "Woran merkst du, dass dich jemand mag?"),
            
            // Bürger: Eifersucht / Spion: Unsicherheit (Beides negative Gefühle)
            QuestionsPromptPair(topic: "Gefühle", citizenQuestion: "In welcher Situation wirst du eifersüchtig?", spyQuestion: "In welcher Situation wirst du unsicher?"),
            
            QuestionsPromptPair(topic: "Rollen", citizenQuestion: "Wer kocht in einer Beziehung meistens?", spyQuestion: "Wer plant in einer Beziehung meistens den Alltag?"),
            
            // Bürger: Partner / Spion: Allgemein (Beides Optik)
            QuestionsPromptPair(topic: "Aussehen", citizenQuestion: "Worauf achtest du beim anderen Geschlecht optisch zuerst?", spyQuestion: "Worauf achtest du bei Menschen generell zuerst?"),
            
            // Bürger: Längste Bez. / Spion: Single-Zeit (Beides Zeiträume)
            QuestionsPromptPair(topic: "Dauer", citizenQuestion: "Wie lange ging deine längste Beziehung?", spyQuestion: "Wie lange ging deine längste Phase als Single?"),
            
            // Bürger: Kennenlernen / Spion: Nochmal treffen (Beides Orte)
            QuestionsPromptPair(topic: "Treffen", citizenQuestion: "Wo hast du deinen letzten Partner kennengelernt?", spyQuestion: "Wo würdest du gerne jemanden kennenlernen?"),
            
            // Bürger: Eltern vorstellen / Spion: Schlüssel geben (Beides Meilensteine)
            QuestionsPromptPair(topic: "Meilenstein", citizenQuestion: "Wann stellst du einen Partner deinen Eltern vor?", spyQuestion: "Wann gibst du einem Partner deinen Wohnungsschlüssel?"),
            
            // Bürger: Trennungsgrund / Spion: Verzeihbar (Beides Beziehungsgrenzen)
            QuestionsPromptPair(topic: "Grenzen", citizenQuestion: "Was ist ein sofortiger Trennungsgrund für dich?", spyQuestion: "Was ist für dich in einer Beziehung unverzeihlich?"),
            
            // Bürger: Hochzeit / Spion: Party (Beides Feiern)
            QuestionsPromptPair(topic: "Feiern", citizenQuestion: "Wie groß würdest du gerne heiraten?", spyQuestion: "Wie groß feierst du deine runden Geburtstage?")
        ]
    )

    // MARK: - Paare (safe)
    public static let couplesSafe = QuestionsCategory(
        name: "Paare (safe)",
        promptPairs: [
            QuestionsPromptPair(topic: "Reise", citizenQuestion: "In welches Land würdest du spontan reisen?", spyQuestion: "In welche Stadt würdest du spontan reisen?"),
            QuestionsPromptPair(topic: "Essen", citizenQuestion: "Welches Gericht würdest du heute kochen, wenn du Zeit hättest?", spyQuestion: "Welches Gericht würdest du heute bestellen?"),
            QuestionsPromptPair(topic: "Freizeit", citizenQuestion: "Wie sieht dein perfekter Sonntag aus?", spyQuestion: "Wie sieht dein perfekter Abend aus?"),
            QuestionsPromptPair(topic: "Medien", citizenQuestion: "Welchen Film würdest du jederzeit nochmal schauen?", spyQuestion: "Welche Serie würdest du jederzeit nochmal starten?"),
            QuestionsPromptPair(topic: "Musik", citizenQuestion: "Welche Musik passt für dich zu einem Roadtrip?", spyQuestion: "Welche Musik passt für dich zu einem ruhigen Abend?"),
            QuestionsPromptPair(topic: "Geld", citizenQuestion: "Wofür würdest du dir gern etwas gönnen?", spyQuestion: "Wofür würdest du lieber sparen?"),
            QuestionsPromptPair(topic: "Stimmung", citizenQuestion: "Was hebt deine Laune sofort?", spyQuestion: "Was entspannt dich sofort?"),
            QuestionsPromptPair(topic: "Leute", citizenQuestion: "Was machst du gern mit Freunden?", spyQuestion: "Was machst du gern allein?"),
            QuestionsPromptPair(topic: "Urlaub", citizenQuestion: "Was ist dir im Urlaub am wichtigsten?", spyQuestion: "Was brauchst du im Urlaub unbedingt, damit er gut wird?"),
            QuestionsPromptPair(topic: "Fähigkeiten", citizenQuestion: "Welche Fähigkeit würdest du gern sofort können?", spyQuestion: "Welche Fähigkeit würdest du gern verbessern?"),
            QuestionsPromptPair(topic: "Wohnen", citizenQuestion: "Was macht eine Wohnung für dich gemütlich?", spyQuestion: "Was macht eine Wohnung für dich praktisch?"),
            QuestionsPromptPair(topic: "Werte", citizenQuestion: "Was ist dir bei Freundschaften am wichtigsten?", spyQuestion: "Was ist dir bei Teamarbeit am wichtigsten?"),
            QuestionsPromptPair(topic: "Tagesstart", citizenQuestion: "Was gehört für dich zu einem perfekten Start in den Tag?", spyQuestion: "Was gehört für dich zu einem perfekten Abschluss des Tages?"),
            QuestionsPromptPair(topic: "Spontanität", citizenQuestion: "Was planst du gern im Voraus?", spyQuestion: "Was machst du lieber spontan?"),
            QuestionsPromptPair(topic: "Sport", citizenQuestion: "Welchen Sport würdest du gern ausprobieren?", spyQuestion: "Welchen Sport würdest du gern regelmäßig machen?"),
            QuestionsPromptPair(topic: "Essenzeiten", citizenQuestion: "Was könntest du jeden Tag zum Frühstück essen?", spyQuestion: "Was könntest du jeden Tag zum Abendessen essen?"),
            QuestionsPromptPair(topic: "Kleidung", citizenQuestion: "Worauf achtest du bei bequemer Kleidung am meisten?", spyQuestion: "Worauf achtest du bei schicker Kleidung am meisten?"),
            QuestionsPromptPair(topic: "Medienformat", citizenQuestion: "Welchen Podcast würdest du sofort hören?", spyQuestion: "Welches Hörbuch würdest du sofort hören?"),
            QuestionsPromptPair(topic: "Pause", citizenQuestion: "Was machst du gern in einer kurzen Pause?", spyQuestion: "Was machst du gern in einer langen Pause?"),
            QuestionsPromptPair(topic: "Zeit", citizenQuestion: "Wofür nimmst du dir immer Zeit?", spyQuestion: "Wofür hättest du gern mehr Zeit?"),
            QuestionsPromptPair(topic: "Ordnung", citizenQuestion: "Was räumst du sofort weg?", spyQuestion: "Was lässt du eher liegen?"),
            QuestionsPromptPair(topic: "Kochen", citizenQuestion: "Welches Gewürz darf bei dir nie fehlen?", spyQuestion: "Welche Zutat lässt du eher weg?"),
            QuestionsPromptPair(topic: "Unterkunft", citizenQuestion: "Worauf achtest du bei einer Unterkunft als erstes?", spyQuestion: "Was muss eine Unterkunft haben, damit du dich wohlfühlst?"),
            QuestionsPromptPair(topic: "Hobby", citizenQuestion: "Welches Hobby würdest du gern neu anfangen?", spyQuestion: "Welches Hobby würdest du gern wieder aufnehmen?"),
            QuestionsPromptPair(topic: "Energie", citizenQuestion: "Wann fühlst du dich am energiegeladensten?", spyQuestion: "Wann bist du am kreativsten?"),
            QuestionsPromptPair(topic: "Einkaufen", citizenQuestion: "Was kaufst du lieber online?", spyQuestion: "Was kaufst du lieber im Laden?"),
            QuestionsPromptPair(topic: "Alltag", citizenQuestion: "Was erledigst du am liebsten morgens?", spyQuestion: "Was erledigst du am liebsten abends?"),
            QuestionsPromptPair(topic: "Getränke", citizenQuestion: "Welches Getränk passt für dich eher zum Morgen?", spyQuestion: "Welches Getränk passt für dich eher zum Abend?"),
            QuestionsPromptPair(topic: "Natur", citizenQuestion: "Wo kannst du in der Natur am besten abschalten?", spyQuestion: "Was in der Natur beruhigt dich am meisten?"),
            QuestionsPromptPair(topic: "Kultur", citizenQuestion: "Welche kulturelle Aktivität macht dir am meisten Spaß?", spyQuestion: "Welche kulturelle Aktivität würdest du gern öfter machen?"),
            QuestionsPromptPair(topic: "Spiele", citizenQuestion: "Welches Spiel spielst du lieber mit anderen?", spyQuestion: "Welches Spiel spielst du lieber allein?"),
            QuestionsPromptPair(topic: "Kommunikation", citizenQuestion: "Wann schreibst du lieber eine Nachricht statt zu telefonieren?", spyQuestion: "Wann telefonierst du lieber statt zu schreiben?"),
            QuestionsPromptPair(topic: "Lernen", citizenQuestion: "Was würdest du gern neu lernen?", spyQuestion: "Was würdest du gern besser können?"),
            QuestionsPromptPair(topic: "Gesundheit", citizenQuestion: "Welche Bewegung macht dir am meisten Spaß?", spyQuestion: "Welche Bewegung tut dir am meisten gut?"),
            QuestionsPromptPair(topic: "Zuhause", citizenQuestion: "Welcher Raum ist für dich zum Entspannen am wichtigsten?", spyQuestion: "Welcher Raum ist für dich zum Arbeiten am wichtigsten?"),
            QuestionsPromptPair(topic: "Tempo", citizenQuestion: "Was machst du lieber langsam und bewusst?", spyQuestion: "Was erledigst du lieber schnell und direkt?"),
            QuestionsPromptPair(topic: "Regenwetter", citizenQuestion: "Was machst du gern, wenn es draußen regnet?", spyQuestion: "Was machst du gern, wenn es draußen richtig warm ist?"),
            QuestionsPromptPair(topic: "Energiequelle", citizenQuestion: "Was gibt dir im Alltag am meisten Energie?", spyQuestion: "Was zieht dir im Alltag am meisten Energie?"),
            QuestionsPromptPair(topic: "Aussortieren", citizenQuestion: "Welche Sache würdest du sofort aussortieren?", spyQuestion: "Welche Sache würdest du nie aussortieren?"),
            QuestionsPromptPair(topic: "Kuechenkunst", citizenQuestion: "Welches Gericht gelingt dir immer?", spyQuestion: "Welches Gericht wuerdest du gern besser koennen?"),
            QuestionsPromptPair(topic: "Ueberraschung", citizenQuestion: "Worueber wuerdest du dich heute spontan freuen?", spyQuestion: "Womit wuerdest du heute jemand anderen spontan ueberraschen?"),
            QuestionsPromptPair(topic: "Routine", citizenQuestion: "Welche kleine Routine tut dir gut?", spyQuestion: "Welche kleine Routine wuerdest du gern aufbauen?"),
            QuestionsPromptPair(topic: "Lesen", citizenQuestion: "Welche Art von Buch wuerdest du sofort anfangen?", spyQuestion: "Welche Art von Artikel liest du am liebsten?"),
            QuestionsPromptPair(topic: "Geraeusch", citizenQuestion: "Welches Geraeusch findest du beruhigend?", spyQuestion: "Welches Geraeusch nervt dich schnell?"),
            QuestionsPromptPair(topic: "Geruch", citizenQuestion: "Welcher Geruch macht dir sofort gute Laune?", spyQuestion: "Welcher Geruch ist dir unangenehm?"),
            QuestionsPromptPair(topic: "Einkaufsliste", citizenQuestion: "Was steht fast immer auf deiner Einkaufsliste?", spyQuestion: "Was kaufst du nur selten, aber immer gern?"),
            QuestionsPromptPair(topic: "Tageszeit", citizenQuestion: "Was macht fuer dich einen guten Abend aus?", spyQuestion: "Was macht fuer dich einen guten Morgen aus?"),
            QuestionsPromptPair(topic: "Ziele", citizenQuestion: "Welches kleine Ziel hast du fuer die naechste Woche?", spyQuestion: "Welches kleine Ziel hast du fuer den naechsten Monat?"),
            QuestionsPromptPair(topic: "Handy", citizenQuestion: "Wann legst du dein Handy bewusst weg?", spyQuestion: "Wann greifst du fast automatisch zum Handy?"),
            QuestionsPromptPair(topic: "Musikmoment", citizenQuestion: "Bei welcher Gelegenheit hoerst du Musik am liebsten?", spyQuestion: "Bei welcher Gelegenheit hoerst du lieber keine Musik?"),
            QuestionsPromptPair(topic: "Teamwork", citizenQuestion: "Wobei arbeitest du gern im Team?", spyQuestion: "Wobei arbeitest du lieber allein?"),
            QuestionsPromptPair(topic: "Spaziergang", citizenQuestion: "Wo gehst du gern spazieren?", spyQuestion: "Wann gehst du gern spazieren?"),
            QuestionsPromptPair(topic: "Lernenstil", citizenQuestion: "Wie lernst du neue Dinge am liebsten?", spyQuestion: "Wie erklaerst du anderen am liebsten etwas?"),
            QuestionsPromptPair(topic: "Wohngefuehl", citizenQuestion: "Was darf in deinem Zuhause nicht fehlen?", spyQuestion: "Was wuerdest du in einem neuen Zuhause als Erstes aendern?"),
            QuestionsPromptPair(topic: "Feierabend", citizenQuestion: "Wie schaltest du nach der Arbeit ab?", spyQuestion: "Wie kommst du morgens am besten in Gang?"),
            QuestionsPromptPair(topic: "Kleinigkeiten", citizenQuestion: "Welche Kleinigkeit macht dir den Tag schoener?", spyQuestion: "Welche Kleinigkeit nervt dich im Alltag?"),
            QuestionsPromptPair(topic: "Reisegepaeck", citizenQuestion: "Was nimmst du auf Reisen immer mit?", spyQuestion: "Was laesst du auf Reisen bewusst zu Hause?"),
            QuestionsPromptPair(topic: "Entspannung", citizenQuestion: "Welche Aktivitaet beruhigt dich schnell?", spyQuestion: "Welche Aktivitaet bringt dich schnell in Bewegung?"),
            QuestionsPromptPair(topic: "Kreativ", citizenQuestion: "Womit wirst du kreativ?", spyQuestion: "Womit entspannst du dich kreativ?"),
            QuestionsPromptPair(topic: "Sprache", citizenQuestion: "Welches Wort benutzt du zu oft?", spyQuestion: "Welches Wort benutzt du kaum, wuerdest es aber gern?")
        ]
    )
    
    // MARK: - Mindset & Zukunft
    public static let mindsetFuture = QuestionsCategory(
        name: "Mindset & Zukunft",
        promptPairs: [
            // Bürger: Wichtigster Wert / Spion: Vernachlässigter Wert
            QuestionsPromptPair(topic: "Werte", citizenQuestion: "Welcher Wert steht für dich an erster Stelle?", spyQuestion: "Welchen Wert vernachlässigen viele Menschen heutzutage?"),
            
            // Bürger: Job / Spion: Privat (Beides Risikobereitschaft)
            QuestionsPromptPair(topic: "Risiko", citizenQuestion: "In welchem Lebensbereich bist du risikofreudig?", spyQuestion: "In welchem Lebensbereich gehst du immer auf Nummer sicher?"),
            
            // Bürger: Aufstehen / Spion: Durchhalten (Beides Motivation)
            QuestionsPromptPair(topic: "Motivation", citizenQuestion: "Was motiviert dich morgens aufzustehen?", spyQuestion: "Was motiviert dich, bei schwierigen Aufgaben dranzubleiben?"),
            
            // Bürger: Erfolg / Spion: Glück (Beides Definitionen)
            QuestionsPromptPair(topic: "Definition", citizenQuestion: "Was bedeutet Erfolg für dich in einem Wort?", spyQuestion: "Was bedeutet Glück für dich in einem Wort?"),
            
            // Bürger: Inspiriert / Spion: Respektiert (Beides Personen)
            QuestionsPromptPair(topic: "Vorbild", citizenQuestion: "Welche Person inspiriert dich?", spyQuestion: "Vor welcher Person hast du am meisten Respekt?"),
            
            // Bürger: Freude / Spion: Neugier (Beides Zukunft)
            QuestionsPromptPair(topic: "Zukunft", citizenQuestion: "Worauf freust du dich in der Zukunft am meisten?", spyQuestion: "Worauf bist du in der Zukunft am meisten gespannt?"),
            
            QuestionsPromptPair(topic: "Entscheidung", citizenQuestion: "Triffst du Entscheidungen eher spontan oder geplant?", spyQuestion: "Vertraust du bei Entscheidungen eher auf Kopf oder Bauch?"),
            
            // Bürger: Superkraft / Spion: Talent (Beides Fähigkeiten)
            QuestionsPromptPair(topic: "Fähigkeit", citizenQuestion: "Welche Superkraft hättest du gerne?", spyQuestion: "Welches Talent hättest du gerne?"),
            
            // Bürger: Welt ändern / Spion: Selbst ändern (Beides Veränderung)
            QuestionsPromptPair(topic: "Veränderung", citizenQuestion: "Was würdest du an der Welt ändern?", spyQuestion: "Was würdest du an deinem Leben ändern?"),
            
            // Bürger: Luxus / Spion: Gönnen (Beides Materielles)
            QuestionsPromptPair(topic: "Luxus", citizenQuestion: "Was ist für dich der größte Luxus?", spyQuestion: "Womit verwöhnst du dich selbst am liebsten?"),
            
            QuestionsPromptPair(topic: "Rat", citizenQuestion: "Welchen Rat würdest du deinem jüngeren Ich geben?", spyQuestion: "Welchen Rat würdest du deinem zukünftigen Ich geben?"),
            
            QuestionsPromptPair(topic: "Tier", citizenQuestion: "Welches Tier wärst du gerne?", spyQuestion: "Welches Tier fasziniert dich am meisten?"),
            
            QuestionsPromptPair(topic: "Jahreszeit", citizenQuestion: "Welche ist deine absolute Lieblingsjahreszeit?", spyQuestion: "In welcher Jahreszeit bist du am produktivsten?"),
            
            QuestionsPromptPair(topic: "Element", citizenQuestion: "Mit welchem Element (Feuer, Wasser, Erde, Luft) identifizierst du dich?", spyQuestion: "Welches Element findest du am mächtigsten?"),
            
            // Bürger: Verzichten / Spion: Schärfen (Beides Sinne)
            QuestionsPromptPair(topic: "Sinn", citizenQuestion: "Auf welchen deiner 5 Sinne könntest du am wenigsten verzichten?", spyQuestion: "Welchen deiner 5 Sinne würdest du gerne verstärken?"),
            
            // Bürger: Reisen / Spion: Leben (Beides Epochen)
            QuestionsPromptPair(topic: "Zeit", citizenQuestion: "In welche Epoche würdest du gerne reisen?", spyQuestion: "In welcher Epoche hättest du gerne gelebt?"),
            
            QuestionsPromptPair(topic: "Genre", citizenQuestion: "Welches Filmgenre beschreibt dein Leben am besten?", spyQuestion: "Welches Filmgenre schaust du am liebsten?"),
            QuestionsPromptPair(topic: "Wohnen", citizenQuestion: "In welcher Stadt würdest du gerne leben?", spyQuestion: "In welcher Stadt könntest du dir vorstellen, ein Jahr zu bleiben?"),
            QuestionsPromptPair(topic: "Job", citizenQuestion: "Was wäre dein Traumjob?", spyQuestion: "Welches Hobby würdest du gerne zum Beruf machen?"),
            QuestionsPromptPair(topic: "Lotto", citizenQuestion: "Was würdest du als Erstes kaufen, wenn du im Lotto gewinnst?", spyQuestion: "In was würdest du investieren, wenn du reich wärst?"),
            QuestionsPromptPair(topic: "Reise", citizenQuestion: "Wohin geht deine nächste große Reise?", spyQuestion: "Was ist dein absolutes Traumreiseziel?"),
            QuestionsPromptPair(topic: "Haus", citizenQuestion: "Was darf in deinem Traumhaus nicht fehlen?", spyQuestion: "Was wäre das Highlight in deinem Traumhaus?"),
            QuestionsPromptPair(topic: "Alter", citizenQuestion: "Wie alt möchtest du werden?", spyQuestion: "Welches Alter findest du am besten?"),
            QuestionsPromptPair(topic: "Sprache", citizenQuestion: "Welche Sprache würdest du gerne fließend sprechen?", spyQuestion: "Welche Sprache würdest du gerne verstehen können?"),
            QuestionsPromptPair(topic: "Musik", citizenQuestion: "Welches Instrument würdest du gerne spielen?", spyQuestion: "Welches Instrument findest du am schönsten?"),
            QuestionsPromptPair(topic: "Abenteuer", citizenQuestion: "Welches Abenteuer willst du unbedingt noch erleben?", spyQuestion: "Welches besondere Erlebnis steht ganz oben auf deiner Liste?"),
            QuestionsPromptPair(topic: "Ort", citizenQuestion: "Wo möchtest du deinen Lebensabend verbringen?", spyQuestion: "Wo hättest du gerne ein Ferienhaus?"),
            QuestionsPromptPair(topic: "Erfindung", citizenQuestion: "Welche Erfindung würdest du gerne machen?", spyQuestion: "Welche Erfindung würdest du gerne besitzen, wenn es sie gäbe?"),
            QuestionsPromptPair(topic: "Promi", citizenQuestion: "Welchen Star würdest du gerne treffen?", spyQuestion: "Mit welchem Promi würdest du gerne essen gehen?"),
            QuestionsPromptPair(topic: "Buch", citizenQuestion: "Über welches Thema würdest du ein Buch schreiben?", spyQuestion: "Über welches Thema liest du am liebsten?"),
            QuestionsPromptPair(topic: "Auto", citizenQuestion: "Was wäre dein absolutes Traumauto?", spyQuestion: "Welches Auto würdest du dir als Erstes kaufen, wenn Geld egal wäre?"),
            QuestionsPromptPair(topic: "Angst", citizenQuestion: "Welche Angst würdest du gerne besiegen?", spyQuestion: "Auf welche Sorge würdest du gerne verzichten?")
        ]
    )
    
    // MARK: - Party & Spicy
    public static let partySpicy = QuestionsCategory(
        name: "Party & Spicy",
        promptPairs: [
            // Bürger: Tanzen / Spion: Mitsingen (Beides Songs)
            QuestionsPromptPair(topic: "Musik", citizenQuestion: "Bei welchem Song stürmst du die Tanzfläche?", spyQuestion: "Bei welchem Song singst du am lautesten mit?"),
            
            // Bürger: Liebster / Spion: Standard (Beides Drinks)
            QuestionsPromptPair(topic: "Drink", citizenQuestion: "Was trinkst du auf Partys am liebsten?", spyQuestion: "Was ist dein Standard-Bestellgetränk in einer Bar?"),
            
            // Bürger: Nach Hause / Spion: Müde werden (Beides Uhrzeiten)
            QuestionsPromptPair(topic: "Ende", citizenQuestion: "Wann gehst du auf einer guten Party nach Hause?", spyQuestion: "Wann wirst du beim Feiern meistens müde?"),
            
            // Bürger: Feiern / Spion: Ausgehen (Beides Outfits)
            QuestionsPromptPair(topic: "Outfit", citizenQuestion: "Was ziehst du zum Feiern am liebsten an?", spyQuestion: "Was ziehst du für ein schickes Dinner an?"),
            
            // Bürger: Mittel / Spion: Essen (Beides Kater-Hilfe)
            QuestionsPromptPair(topic: "Kater", citizenQuestion: "Was ist dein bestes Mittel gegen Kater?", spyQuestion: "Welches Essen brauchst du nach einer durchzechten Nacht?"),
            
            // Bürger: Peinlich / Spion: Lustig (Beides Ereignisse)
            QuestionsPromptPair(topic: "Story", citizenQuestion: "Was ist dir auf einer Party schon mal Peinliches passiert?", spyQuestion: "Was war der lustigste Moment auf einer Party?"),
            
            // Bürger: Ansprechen / Spion: Kennenlernen (Beides Flirt)
            QuestionsPromptPair(topic: "Flirt", citizenQuestion: "Wie sprichst du jemanden an, der dir gefällt?", spyQuestion: "Wie zeigst du Interesse, wenn dir jemand gefällt?"),
            
            // Bürger: Favorit / Spion: Live sehen (Beides Künstler)
            QuestionsPromptPair(topic: "Act", citizenQuestion: "Welcher DJ oder welche Band ist dein Favorit?", spyQuestion: "Welchen Künstler würdest du gerne live sehen?"),
            
            // Bürger: Vorglühen / Spion: Cornern (Beides Start-Orte)
            QuestionsPromptPair(topic: "Start", citizenQuestion: "Wo glühst du am liebsten vor?", spyQuestion: "Wo triffst du dich meistens vor dem Feiern?"),
            
            // Bürger: Karaoke / Spion: Dusche (Beides Singen)
            QuestionsPromptPair(topic: "Singen", citizenQuestion: "Welchen Song singst du beim Karaoke?", spyQuestion: "Welchen Song singst du unter der Dusche?"),
            
            // Bürger: Tresen / Spion: Tisch (Beides Bar-Orte)
            QuestionsPromptPair(topic: "Bar", citizenQuestion: "Was bestellst du am liebsten an der Bar?", spyQuestion: "Was bestellst du, wenn du die Runde zahlst?"),
            
            // Bürger: Gehen / Spion: Absagen (Beides Ausreden)
            QuestionsPromptPair(topic: "Ausrede", citizenQuestion: "Welche Ausrede nutzt du, um früher zu gehen?", spyQuestion: "Welche Ausrede nutzt du, um ein Treffen abzusagen?"),
            
            // Bürger: Können / Spion: Lernen (Beides Tanzstile)
            QuestionsPromptPair(topic: "Tanzen", citizenQuestion: "Welchen Tanzstil würdest du gerne können?", spyQuestion: "Welchen Tanz findest du beeindruckend?"),
            
            // Bürger: Abend / Spion: Wochenende (Beides Geldsummen)
            QuestionsPromptPair(topic: "Geld", citizenQuestion: "Wie viel gibst du an einem guten Abend aus?", spyQuestion: "Wie viel Geld nimmst du bar zum Feiern mit?"),
            
            // Bürger: Aufgewacht / Spion: Eingeschlafen (Beides Orte)
            QuestionsPromptPair(topic: "Schlaf", citizenQuestion: "Wo bist du nach einer Party mal aufgewacht?", spyQuestion: "Wo bist du schon mal versehentlich eingeschlafen?"),
            QuestionsPromptPair(topic: "Attraktivität", citizenQuestion: "Was findest du an anderen körperlich am attraktivsten?", spyQuestion: "Was findest du an der Ausstrahlung anderer am wichtigsten?"),
            QuestionsPromptPair(topic: "Bett", citizenQuestion: "Was ist dir im Bett besonders wichtig?", spyQuestion: "Was macht für dich guten Sex aus?"),
            QuestionsPromptPair(topic: "Ort", citizenQuestion: "An welchem ungewöhnlichen Ort hattest du schon Sex?", spyQuestion: "An welchem Ort hättest du gerne mal Sex?"),
            QuestionsPromptPair(topic: "Kleidung", citizenQuestion: "Was findest du beim anderen Geschlecht sexy?", spyQuestion: "Welches Kleidungsstück findest du besonders anziehend?"),
            QuestionsPromptPair(topic: "App", citizenQuestion: "Welche Dating-App hast du schon mal benutzt?", spyQuestion: "Auf welcher Plattform hast du schon mal geflirtet?"),
            QuestionsPromptPair(topic: "Ex", citizenQuestion: "Mit wie vielen Ex-Partnern hast du noch Kontakt?", spyQuestion: "Mit wie vielen Ex-Partnern bist du noch befreundet?"),
            QuestionsPromptPair(topic: "Initiative", citizenQuestion: "Machst du eher den ersten Schritt oder wartest du?", spyQuestion: "Sprichst du jemanden an oder lässt du dich ansprechen?"),
            QuestionsPromptPair(topic: "Crush", citizenQuestion: "Wer ist dein Celebrity Crush?", spyQuestion: "Welchen Promi findest du heiß?"),
            QuestionsPromptPair(topic: "Erfahrung", citizenQuestion: "Hattest du schon mal einen One Night Stand?", spyQuestion: "Hattest du schon mal ein Date, das im Bett endete?"),
            QuestionsPromptPair(topic: "Erstes Mal", citizenQuestion: "Wann hast du deinen ersten Kuss bekommen?", spyQuestion: "In welchem Alter hattest du deinen ersten Kuss?"),
            QuestionsPromptPair(topic: "Farbe", citizenQuestion: "Welche Farbe findest du bei Unterwäsche attraktiv?", spyQuestion: "Welche Farbe trägst du bei Kleidung am liebsten?"),
            QuestionsPromptPair(topic: "Gedanken", citizenQuestion: "Hast du eine geheime Fantasie?", spyQuestion: "Wovon träumst du manchmal tagüber?"),
            QuestionsPromptPair(topic: "Alter", citizenQuestion: "Welcher Altersunterschied ist für dich okay?", spyQuestion: "Welchen Altersunterschied findest du ideal?"),
            QuestionsPromptPair(topic: "Vorliebe", citizenQuestion: "Welche Stellung magst du am liebsten?", spyQuestion: "Welche Position bevorzugst du meistens?")
        ]
    )
    
    // MARK: - Hard & Tabu (optional)
    public static let darkTaboo = QuestionsCategory(
        name: "Hard & Tabu",
        promptPairs: [
            // Bürger: Gesetz / Spion: Regel (Beides Verstöße)
            QuestionsPromptPair(topic: "Regelbruch", citizenQuestion: "Welches Gesetz würdest du brechen, wenn es keine Strafe gäbe?", spyQuestion: "Welche gesellschaftliche Regel würdest du gerne ignorieren?"),
            
            // Bürger: Gelogen / Spion: Geschummelt (Beides Unehrlichkeit)
            QuestionsPromptPair(topic: "Lüge", citizenQuestion: "Wann hast du zuletzt gelogen?", spyQuestion: "Wann hast du zuletzt die Wahrheit verdreht?"),
            
            // Bürger: Hasst / Spion: Verachtest (Beides Abneigung Personen)
            QuestionsPromptPair(topic: "Feind", citizenQuestion: "Gibt es jemanden, den du wirklich hasst?", spyQuestion: "Gibt es jemanden, den du absolut nicht ausstehen kannst?"),
            
            QuestionsPromptPair(topic: "Ende", citizenQuestion: "Wie würdest du am liebsten sterben?", spyQuestion: "Wovor hättest du beim Thema Tod am meisten Angst?"),

            QuestionsPromptPair(topic: "Scham", citizenQuestion: "Wofür schämst du dich heute noch ein bisschen?", spyQuestion: "Wofür würdest du dich wahrscheinlich schämen, wenn es rauskommt?"),
            
            QuestionsPromptPair(topic: "Notlüge", citizenQuestion: "Welche Notlüge benutzt du am häufigsten?", spyQuestion: "Welche Wahrheit würdest du am ehesten verschweigen?"),
            
            QuestionsPromptPair(topic: "Grenze", citizenQuestion: "Wo ziehst du eine klare moralische Grenze?", spyQuestion: "Wo wärst du am ehesten bereit, eine Grenze zu überschreiten?"),
            
            QuestionsPromptPair(topic: "Neugier", citizenQuestion: "Was würdest du gerne heimlich wissen?", spyQuestion: "Was würdest du lieber niemals erfahren?"),
            
            QuestionsPromptPair(topic: "Manipulation", citizenQuestion: "Hast du schon mal jemanden manipuliert?", spyQuestion: "Hast du dich schon mal manipuliert gefühlt?"),
            
            // Bürger: Geheimnisse / Spion: Wahres Ich (Beides Wissen über dich)
            QuestionsPromptPair(topic: "Wissen", citizenQuestion: "Wer kennt deine dunkelsten Geheimnisse?", spyQuestion: "Wer weiß alles über dich?"),
            
            // Bürger: Angst / Spion: Sorge (Beides Furcht)
            QuestionsPromptPair(topic: "Furcht", citizenQuestion: "Wovor hast du am meisten Angst?", spyQuestion: "Was ist deine größte Sorge im Leben?"),
            
            // Bürger: Verbrechen / Spion: Tat (Beides Kriminelles)
            QuestionsPromptPair(topic: "Kriminalität", citizenQuestion: "Welches Verbrechen könntest du dir theoretisch vorstellen zu begehen?", spyQuestion: "Für welche Tat hättest du theoretisch ein Motiv?"),
            
            // Bürger: Rachsüchtig / Spion: Nachtragend (Beides Eigenschaften)
            QuestionsPromptPair(topic: "Charakter", citizenQuestion: "Bist du ein rachsüchtiger Mensch?", spyQuestion: "Bist du ein nachtragender Mensch?"),
            
            // Bürger: Schadenfreude / Spion: Genugtuung (Beides Gefühle)
            QuestionsPromptPair(topic: "Gefühl", citizenQuestion: "Wann hast du zuletzt Schadenfreude empfunden?", spyQuestion: "Wann hast du zuletzt Genugtuung empfunden?"),
            
            // Bürger: Geklaut / Spion: Mitgehen lassen (Beides Diebstahl)
            QuestionsPromptPair(topic: "Diebstahl", citizenQuestion: "Was hast du schon mal geklaut?", spyQuestion: "Was hast du schon mal versehentlich eingesteckt?"),
            
            // Bürger: Betrogen / Spion: Hintergangen (Beides Vertrauensbruch)
            QuestionsPromptPair(topic: "Verrat", citizenQuestion: "Hast du schon mal jemanden betrogen?", spyQuestion: "Hast du schon mal das Vertrauen von jemandem missbraucht?"),
            
            // Bürger: Neidisch / Spion: Eifersüchtig (Beides Missgunst)
            QuestionsPromptPair(topic: "Neid", citizenQuestion: "Auf wen bist du heimlich neidisch?", spyQuestion: "Auf wessen Erfolg bist du manchmal eifersüchtig?"),
            
            // Bürger: Sünde / Spion: Laster (Beides Schwächen)
            QuestionsPromptPair(topic: "Schwäche", citizenQuestion: "Welche der 7 Todsünden ist deine größte?", spyQuestion: "Was ist dein größtes Laster?"),
            
            // Bürger: Dunkelster Gedanke / Spion: Geheimster Wunsch (Beides Kopfkino)
            QuestionsPromptPair(topic: "Gedanke", citizenQuestion: "Was war dein dunkelster Gedanke?", spyQuestion: "Was ist ein Gedanke, den du niemandem erzählst?"),
            
            // Bürger: Drogen / Spion: Rauschmittel (Beides Konsum)
            QuestionsPromptPair(topic: "Illegal", citizenQuestion: "Hast du schon mal illegale Substanzen probiert?", spyQuestion: "Hast du schon mal etwas Verbotenes konsumiert?"),
            
            QuestionsPromptPair(topic: "Geheimnis", citizenQuestion: "Welches Geheimnis würdest du nie laut sagen?", spyQuestion: "Welches Geheimnis würdest du nur einer Person anvertrauen?"),
            
            QuestionsPromptPair(topic: "Reue", citizenQuestion: "Was bereust du am meisten?", spyQuestion: "Was würdest du sofort anders machen, wenn du könntest?")
        ]
    )
    
    public static let all: [QuestionsCategory] = [
        everyday,
        loveRelationships,
        couplesSafe,
        mindsetFuture,
        partySpicy,
        darkTaboo
    ]
}
