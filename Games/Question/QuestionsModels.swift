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
    public var liarQuestion: String

    public init(id: UUID = UUID(), topic: String? = nil, citizenQuestion: String, liarQuestion: String) {
        self.id = id
        self.topic = topic
        self.citizenQuestion = citizenQuestion
        self.liarQuestion = liarQuestion
    }
}

public enum QuestionsRole: String, Codable, Hashable {
    case citizen
    case liar
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

public struct QuestionsConfig: Hashable, Codable {
    public var numberOfLiars: Int
    public var selectedCategory: QuestionsCategory?
    public var discussionTime: TimeInterval // 0 = Unlimited
    var players: [QuestionPlayer]

    init(numberOfLiars: Int = 1, selectedCategory: QuestionsCategory? = nil, discussionTime: TimeInterval = 180, players: [QuestionPlayer] = []) {
        self.numberOfLiars = numberOfLiars
        self.selectedCategory = selectedCategory
        self.discussionTime = discussionTime
        self.players = players
    }
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

// MARK: - MPC Payloads

struct QuestionsRolePayload: Codable {
    let role: QuestionsRole
    let prompt: String
}

struct QuestionsRoleAckPayload: Codable {
    let playerName: String
}

struct QuestionsVoteCastPayload: Codable {
    let voterName: String
    let targetId: UUID
    let delta: Int
}

struct QuestionsVotingStatusPayload: Codable {
    let votesReceived: Int
    let totalVotes: Int
    let tally: [String: Int]?
}

struct QuestionsTimerSyncPayload: Codable {
    let timeRemaining: TimeInterval
    let isActive: Bool
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

struct QuestionsRejoinRequestPayload: Codable {
    let playerName: String
    let playerId: UUID
}

struct QuestionsRejoinStatePayload: Codable {
    let playerName: String
    let roundState: QuestionsRoundState?
    let votingEvaluation: QuestionsVoteEvaluation?
    let timeRemaining: TimeInterval
    let isTimerActive: Bool
    let config: QuestionsConfig
}

struct QuestionsHostActivityPayload: Codable {
    let message: String
}

public enum QuestionsDefaults {
    
    // MARK: - Alltag
    public static let everyday = QuestionsCategory(
        name: "Alltag",
        promptPairs: [
            // Proband: Wasser / Lügner: Kaffee (Beides Mengenfragen)
            QuestionsPromptPair(topic: "Getränke", citizenQuestion: "Wie viele Gläser Wasser trinkst du am Tag?", liarQuestion: "Wie viele Tassen Kaffee trinkst du am Tag?"),
            
            // Proband: Wecker / Lügner: Aufstehen ohne Wecker (Beides Uhrzeiten)
            QuestionsPromptPair(topic: "Aufstehen", citizenQuestion: "Wann klingelt dein Wecker unter der Woche?", liarQuestion: "Wann stehst du am Wochenende normalerweise auf?"),
            
            // Proband: Arbeitsweg / Lügner: Zeit im Bad (Beides Dauer in Minuten)
            QuestionsPromptPair(topic: "Zeit", citizenQuestion: "Wie lange brauchst du morgens zur Arbeit/Uni?", liarQuestion: "Wie lange brauchst du morgens im Bad?"),
            
            // Proband: Kochen / Lügner: Bestellen (Beides Frequenz)
            QuestionsPromptPair(topic: "Essen", citizenQuestion: "Wie oft in der Woche kochst du frisch?", liarQuestion: "Wie oft in der Woche bestellst du Essen?"),
            
            // Proband: Lieblingssport / Lügner: TV-Sport (Beides Sportarten, die man mag)
            QuestionsPromptPair(topic: "Sport", citizenQuestion: "Welchen Sport machst du selbst am liebsten?", liarQuestion: "Welchen Sport schaust du am liebsten im Fernsehen?"),
            
            // Proband: Schlafengehen / Lügner: Handy weglegen (Beides Uhrzeiten abends)
            QuestionsPromptPair(topic: "Schlaf", citizenQuestion: "Um wie viel Uhr schläfst du meistens ein?", liarQuestion: "Um wie viel Uhr legst du dein Handy weg?"),
            
            // Proband: Mag ich / Lügner: Delegiere ich (Beides Hausarbeit, Fokus verschoben)
            QuestionsPromptPair(topic: "Haushalt", citizenQuestion: "Welche Hausarbeit machst du am ehesten gern?", liarQuestion: "Welche Hausarbeit würdest du sofort an eine Putzhilfe abgeben?"),
            
            QuestionsPromptPair(topic: "Social Media", citizenQuestion: "Auf welcher App verbringst du die meiste Zeit?", liarQuestion: "Welche App öffnest du morgens als erstes?"),
            
            // Proband: Viel Geld / Lügner: Zu wenig Geld (Beides Ausgaben)
            QuestionsPromptPair(topic: "Geld", citizenQuestion: "Wofür gibst du gerne viel Geld aus?", liarQuestion: "Wofür gibst du ungern Geld aus, musst aber?"),
            
            QuestionsPromptPair(topic: "Reisen", citizenQuestion: "Welches Land steht bei dir ganz oben auf der Reiseliste?", liarQuestion: "Welche Stadt steht bei dir als nächstes auf der Reiseliste?"),
            
            QuestionsPromptPair(topic: "Technik", citizenQuestion: "Welches Gadget benutzt du täglich?", liarQuestion: "Auf welches Gadget könntest du nicht verzichten?"),
            
            QuestionsPromptPair(topic: "Wochentag", citizenQuestion: "Welcher ist dein produktivster Wochentag?", liarQuestion: "Welcher ist dein entspanntester Wochentag?"),
            
            // Proband: Gäste / Lügner: Familie (Beides Gerichte)
            QuestionsPromptPair(topic: "Kochen", citizenQuestion: "Welches Gericht kochst du, wenn Gäste kommen?", liarQuestion: "Welches Gericht kochst du nur für dich alleine?"),
            
            // Proband: Anrufen / Lügner: Schreiben (Beides Personen)
            QuestionsPromptPair(topic: "Familie", citizenQuestion: "Wen aus deiner Familie rufst du am häufigsten an?", liarQuestion: "Wem aus deiner Familie schreibst du am häufigsten?"),
            
            // Proband: Wohlfühlen / Lügner: Zu heiß (Beides Temperaturen)
            QuestionsPromptPair(topic: "Wetter", citizenQuestion: "Bei wie viel Grad fühlst du dich am wohlsten?", liarQuestion: "Ab wie viel Grad ist es dir zu heiß?"),
            
            // Proband: Entspannen / Lügner: Feiern (Beides Musikgenres)
            QuestionsPromptPair(topic: "Musik", citizenQuestion: "Welches Genre hörst du zum Entspannen?", liarQuestion: "Welches Genre hörst du zum Feiern?"),
            
            QuestionsPromptPair(topic: "Serien", citizenQuestion: "Welche Serie hast du zuletzt geschaut?", liarQuestion: "Welche Serie ist deine absolute Lieblingsserie?"),
            
            QuestionsPromptPair(topic: "Snacks", citizenQuestion: "Was snackst du am liebsten zu Hause?", liarQuestion: "Was snackst du am liebsten unterwegs?"),
            
            QuestionsPromptPair(topic: "Pause", citizenQuestion: "Was machst du in deiner Mittagspause?", liarQuestion: "Was machst du direkt nach Feierabend?"),
            
            QuestionsPromptPair(topic: "Messenger", citizenQuestion: "Über welchen Messenger schreibst du am meisten?", liarQuestion: "Welche Social Media App nutzt du am wenigsten?"),
            
            QuestionsPromptPair(topic: "Wohnen", citizenQuestion: "In welchem Zimmer hältst du dich am meisten auf?", liarQuestion: "Welches Zimmer in deiner Wohnung magst du am liebsten?"),
            
            QuestionsPromptPair(topic: "Frühstück", citizenQuestion: "Was isst du typischerweise zum Frühstück?", liarQuestion: "Was isst du am liebsten zum Sonntagsbrunch?"),
            
            QuestionsPromptPair(topic: "Schuhe", citizenQuestion: "Wie viele Paar Schuhe besitzt du ungefähr?", liarQuestion: "Wie viele Paar Schuhe trägst du wirklich regelmäßig?"),
            
            QuestionsPromptPair(topic: "Nachricht", citizenQuestion: "Wem hast du zuletzt eine Nachricht geschrieben?", liarQuestion: "Von wem hast du die letzte Nachricht erhalten?"),
            QuestionsPromptPair(topic: "Screen Time", citizenQuestion: "Wie viele Stunden bist du täglich am Handy?", liarQuestion: "Wie viele Stunden verbringst du täglich vor Bildschirmen (PC/TV)?"),
            QuestionsPromptPair(topic: "Ordnung", citizenQuestion: "Wie oft räumst du deine Wohnung auf?", liarQuestion: "Wie oft putzt du deine Wohnung gründlich?"),
            QuestionsPromptPair(topic: "Aufgaben", citizenQuestion: "Was schiebst du am liebsten auf?", liarQuestion: "Was vergisst du im Alltag am häufigsten?"),
            QuestionsPromptPair(topic: "Pünktlichkeit", citizenQuestion: "Wie viele Minuten bist du typischerweise zu spät?", liarQuestion: "Wie viele Minuten bist du typischerweise zu früh?"),
            QuestionsPromptPair(topic: "Schnell essen", citizenQuestion: "Was isst du, wenn es schnell gehen muss?", liarQuestion: "Was isst du oft unterwegs?"),
            QuestionsPromptPair(topic: "Transport", citizenQuestion: "Welches Verkehrsmittel nutzt du am häufigsten?", liarQuestion: "Welches Verkehrsmittel nutzt du am liebsten?"),
            QuestionsPromptPair(topic: "Kleidung", citizenQuestion: "Was ist dein liebstes Kleidungsstück?", liarQuestion: "Was ist dein bequemstes Kleidungsstück?"),
            QuestionsPromptPair(topic: "Hygiene", citizenQuestion: "Wie oft duschst du in der Woche?", liarQuestion: "Wie oft wäschst du deine Haare in der Woche?"),
            QuestionsPromptPair(topic: "Freizeit", citizenQuestion: "Was machst du typischerweise sonntags?", liarQuestion: "Was machst du an einem freien Brückentag?"),
            QuestionsPromptPair(topic: "Dabei", citizenQuestion: "Was hast du immer in deiner Tasche dabei?", liarQuestion: "Was hast du immer in deiner Jackentasche?"),
            QuestionsPromptPair(topic: "Schlafen", citizenQuestion: "In welcher Position schläfst du ein?", liarQuestion: "In welcher Position wachst du meistens auf?"),
            QuestionsPromptPair(topic: "Termine", citizenQuestion: "Wie oft gehst du zum Friseur?", liarQuestion: "Wie oft gehst du zur Vorsorge (Zahnarzt/Arzt)?"),
            QuestionsPromptPair(topic: "Zuhause", citizenQuestion: "Was machst du als Erstes, wenn du nach Hause kommst?", liarQuestion: "Was machst du als Letztes, bevor du das Haus verlässt?")
        ]
    )
    
    // MARK: - Liebe & Beziehungen
    public static let loveRelationships = QuestionsCategory(
        name: "Liebe & Beziehungen",
        promptPairs: [
            // Proband: Erstes Date / Lügner: Jahrestag (Beides Orte für Dates)
            QuestionsPromptPair(topic: "Dating-Ort", citizenQuestion: "Was ist ein guter Ort für das erste Date?", liarQuestion: "Was ist ein guter Ort, um einen Jahrestag zu feiern?"),
            
            // Proband: Partner / Lügner: Bester Freund (Beides Eigenschaften von geliebten Menschen)
            QuestionsPromptPair(topic: "Eigenschaften", citizenQuestion: "Welche Eigenschaft ist dir bei einem Partner am wichtigsten?", liarQuestion: "Welche Eigenschaft schätzt du an deinem besten Freund am meisten?"),
            
            // Proband: Bekommen / Lügner: Verschenkt (Beides Geschenke)
            QuestionsPromptPair(topic: "Geschenke", citizenQuestion: "Was war das schönste Geschenk, das du je bekommen hast?", liarQuestion: "Was war das schönste Geschenk, das du je verschenkt hast?"),
            
            // Proband: Partner / Lügner: Freunde (Beides Gesprächsthemen)
            QuestionsPromptPair(topic: "Kommunikation", citizenQuestion: "Worüber redest du mit deinem Partner am liebsten?", liarQuestion: "Worüber redest du mit engen Freunden am liebsten?"),
            
            // Proband: Beziehung / Lügner: Persönlich (Beides Zukunftsvisionen)
            QuestionsPromptPair(topic: "Zukunft", citizenQuestion: "Wo siehst du dich beziehungstechnisch in 5 Jahren?", liarQuestion: "Wo siehst du dich persönlich/wohnlich in 5 Jahren?"),
            
            QuestionsPromptPair(topic: "Konflikt", citizenQuestion: "Wie reagierst du, wenn du sauer auf deinen Partner bist?", liarQuestion: "Wie reagierst du, wenn du enttäuscht von deinem Partner bist?"),
            
            // Proband: Pärchenurlaub / Lügner: Urlaub mit Freunden (Beides Urlaubs-Prioritäten)
            QuestionsPromptPair(topic: "Urlaub", citizenQuestion: "Was ist dir im Pärchenurlaub am wichtigsten?", liarQuestion: "Was ist dir im Urlaub mit Freunden am wichtigsten?"),
            
            // Proband: Letzte Beziehung / Lügner: Letztes Date (Beides Learnings)
            QuestionsPromptPair(topic: "Erfahrung", citizenQuestion: "Was hast du aus deiner letzten Beziehung gelernt?", liarQuestion: "Was hast du aus deinem letzten Date gelernt?"),
            
            // Proband: Zeigen / Lügner: Erwarten (Beides Zuneigung)
            QuestionsPromptPair(topic: "Liebessprache", citizenQuestion: "Wie zeigst du Zuneigung am ehesten?", liarQuestion: "Woran merkst du, dass dich jemand mag?"),
            
            // Proband: Eifersucht / Lügner: Unsicherheit (Beides negative Gefühle)
            QuestionsPromptPair(topic: "Gefühle", citizenQuestion: "In welcher Situation wirst du eifersüchtig?", liarQuestion: "In welcher Situation wirst du unsicher?"),
            
            QuestionsPromptPair(topic: "Rollen", citizenQuestion: "Wer kocht in einer Beziehung meistens?", liarQuestion: "Wer plant in einer Beziehung meistens den Alltag?"),
            
            // Proband: Partner / Lügner: Allgemein (Beides Optik)
            QuestionsPromptPair(topic: "Aussehen", citizenQuestion: "Worauf achtest du beim anderen Geschlecht optisch zuerst?", liarQuestion: "Worauf achtest du bei Menschen generell zuerst?"),
            
            // Proband: Längste Bez. / Lügner: Single-Zeit (Beides Zeiträume)
            QuestionsPromptPair(topic: "Dauer", citizenQuestion: "Wie lange ging deine längste Beziehung?", liarQuestion: "Wie lange ging deine längste Phase als Single?"),
            
            // Proband: Kennenlernen / Lügner: Nochmal treffen (Beides Orte)
            QuestionsPromptPair(topic: "Treffen", citizenQuestion: "Wo hast du deinen letzten Partner kennengelernt?", liarQuestion: "Wo würdest du gerne jemanden kennenlernen?"),
            
            // Proband: Eltern vorstellen / Lügner: Schlüssel geben (Beides Meilensteine)
            QuestionsPromptPair(topic: "Meilenstein", citizenQuestion: "Wann stellst du einen Partner deinen Eltern vor?", liarQuestion: "Wann gibst du einem Partner deinen Wohnungsschlüssel?"),
            
            // Proband: Trennungsgrund / Lügner: Verzeihbar (Beides Beziehungsgrenzen)
            QuestionsPromptPair(topic: "Grenzen", citizenQuestion: "Was ist ein sofortiger Trennungsgrund für dich?", liarQuestion: "Was ist für dich in einer Beziehung unverzeihlich?"),
            
            // Proband: Hochzeit / Lügner: Party (Beides Feiern)
            QuestionsPromptPair(topic: "Feiern", citizenQuestion: "Wie groß würdest du gerne heiraten?", liarQuestion: "Wie groß feierst du deine runden Geburtstage?")
        ]
    )

    // MARK: - Paare (safe)
    public static let couplesSafe = QuestionsCategory(
        name: "Paare (safe)",
        promptPairs: [
            QuestionsPromptPair(topic: "Reise", citizenQuestion: "In welches Land würdest du spontan reisen?", liarQuestion: "In welche Stadt würdest du spontan reisen?"),
            QuestionsPromptPair(topic: "Essen", citizenQuestion: "Welches Gericht würdest du heute kochen, wenn du Zeit hättest?", liarQuestion: "Welches Gericht würdest du heute bestellen?"),
            QuestionsPromptPair(topic: "Freizeit", citizenQuestion: "Wie sieht dein perfekter Sonntag aus?", liarQuestion: "Wie sieht dein perfekter Abend aus?"),
            QuestionsPromptPair(topic: "Medien", citizenQuestion: "Welchen Film würdest du jederzeit nochmal schauen?", liarQuestion: "Welche Serie würdest du jederzeit nochmal starten?"),
            QuestionsPromptPair(topic: "Musik", citizenQuestion: "Welche Musik passt für dich zu einem Roadtrip?", liarQuestion: "Welche Musik passt für dich zu einem ruhigen Abend?"),
            QuestionsPromptPair(topic: "Geld", citizenQuestion: "Wofür würdest du dir gern etwas gönnen?", liarQuestion: "Wofür würdest du lieber sparen?"),
            QuestionsPromptPair(topic: "Stimmung", citizenQuestion: "Was hebt deine Laune sofort?", liarQuestion: "Was entspannt dich sofort?"),
            QuestionsPromptPair(topic: "Leute", citizenQuestion: "Was machst du gern mit Freunden?", liarQuestion: "Was machst du gern allein?"),
            QuestionsPromptPair(topic: "Urlaub", citizenQuestion: "Was ist dir im Urlaub am wichtigsten?", liarQuestion: "Was brauchst du im Urlaub unbedingt, damit er gut wird?"),
            QuestionsPromptPair(topic: "Fähigkeiten", citizenQuestion: "Welche Fähigkeit würdest du gern sofort können?", liarQuestion: "Welche Fähigkeit würdest du gern verbessern?"),
            QuestionsPromptPair(topic: "Wohnen", citizenQuestion: "Was macht eine Wohnung für dich gemütlich?", liarQuestion: "Was macht eine Wohnung für dich praktisch?"),
            QuestionsPromptPair(topic: "Werte", citizenQuestion: "Was ist dir bei Freundschaften am wichtigsten?", liarQuestion: "Was ist dir bei Teamarbeit am wichtigsten?"),
            QuestionsPromptPair(topic: "Tagesstart", citizenQuestion: "Was gehört für dich zu einem perfekten Start in den Tag?", liarQuestion: "Was gehört für dich zu einem perfekten Abschluss des Tages?"),
            QuestionsPromptPair(topic: "Spontanität", citizenQuestion: "Was planst du gern im Voraus?", liarQuestion: "Was machst du lieber spontan?"),
            QuestionsPromptPair(topic: "Sport", citizenQuestion: "Welchen Sport würdest du gern ausprobieren?", liarQuestion: "Welchen Sport würdest du gern regelmäßig machen?"),
            QuestionsPromptPair(topic: "Essenzeiten", citizenQuestion: "Was könntest du jeden Tag zum Frühstück essen?", liarQuestion: "Was könntest du jeden Tag zum Abendessen essen?"),
            QuestionsPromptPair(topic: "Kleidung", citizenQuestion: "Worauf achtest du bei bequemer Kleidung am meisten?", liarQuestion: "Worauf achtest du bei schicker Kleidung am meisten?"),
            QuestionsPromptPair(topic: "Medienformat", citizenQuestion: "Welchen Podcast würdest du sofort hören?", liarQuestion: "Welches Hörbuch würdest du sofort hören?"),
            QuestionsPromptPair(topic: "Pause", citizenQuestion: "Was machst du gern in einer kurzen Pause?", liarQuestion: "Was machst du gern in einer langen Pause?"),
            QuestionsPromptPair(topic: "Zeit", citizenQuestion: "Wofür nimmst du dir immer Zeit?", liarQuestion: "Wofür hättest du gern mehr Zeit?"),
            QuestionsPromptPair(topic: "Ordnung", citizenQuestion: "Was räumst du sofort weg?", liarQuestion: "Was lässt du eher liegen?"),
            QuestionsPromptPair(topic: "Kochen", citizenQuestion: "Welches Gewürz darf bei dir nie fehlen?", liarQuestion: "Welche Zutat lässt du eher weg?"),
            QuestionsPromptPair(topic: "Unterkunft", citizenQuestion: "Worauf achtest du bei einer Unterkunft als erstes?", liarQuestion: "Was muss eine Unterkunft haben, damit du dich wohlfühlst?"),
            QuestionsPromptPair(topic: "Hobby", citizenQuestion: "Welches Hobby würdest du gern neu anfangen?", liarQuestion: "Welches Hobby würdest du gern wieder aufnehmen?"),
            QuestionsPromptPair(topic: "Energie", citizenQuestion: "Wann fühlst du dich am energiegeladensten?", liarQuestion: "Wann bist du am kreativsten?"),
            QuestionsPromptPair(topic: "Einkaufen", citizenQuestion: "Was kaufst du lieber online?", liarQuestion: "Was kaufst du lieber im Laden?"),
            QuestionsPromptPair(topic: "Alltag", citizenQuestion: "Was erledigst du am liebsten morgens?", liarQuestion: "Was erledigst du am liebsten abends?"),
            QuestionsPromptPair(topic: "Getränke", citizenQuestion: "Welches Getränk passt für dich eher zum Morgen?", liarQuestion: "Welches Getränk passt für dich eher zum Abend?"),
            QuestionsPromptPair(topic: "Natur", citizenQuestion: "Wo kannst du in der Natur am besten abschalten?", liarQuestion: "Was in der Natur beruhigt dich am meisten?"),
            QuestionsPromptPair(topic: "Kultur", citizenQuestion: "Welche kulturelle Aktivität macht dir am meisten Spaß?", liarQuestion: "Welche kulturelle Aktivität würdest du gern öfter machen?"),
            QuestionsPromptPair(topic: "Spiele", citizenQuestion: "Welches Spiel spielst du lieber mit anderen?", liarQuestion: "Welches Spiel spielst du lieber allein?"),
            QuestionsPromptPair(topic: "Kommunikation", citizenQuestion: "Wann schreibst du lieber eine Nachricht statt zu telefonieren?", liarQuestion: "Wann telefonierst du lieber statt zu schreiben?"),
            QuestionsPromptPair(topic: "Lernen", citizenQuestion: "Was würdest du gern neu lernen?", liarQuestion: "Was würdest du gern besser können?"),
            QuestionsPromptPair(topic: "Gesundheit", citizenQuestion: "Welche Bewegung macht dir am meisten Spaß?", liarQuestion: "Welche Bewegung tut dir am meisten gut?"),
            QuestionsPromptPair(topic: "Zuhause", citizenQuestion: "Welcher Raum ist für dich zum Entspannen am wichtigsten?", liarQuestion: "Welcher Raum ist für dich zum Arbeiten am wichtigsten?"),
            QuestionsPromptPair(topic: "Tempo", citizenQuestion: "Was machst du lieber langsam und bewusst?", liarQuestion: "Was erledigst du lieber schnell und direkt?"),
            QuestionsPromptPair(topic: "Regenwetter", citizenQuestion: "Was machst du gern, wenn es draußen regnet?", liarQuestion: "Was machst du gern, wenn es draußen richtig warm ist?"),
            QuestionsPromptPair(topic: "Energiequelle", citizenQuestion: "Was gibt dir im Alltag am meisten Energie?", liarQuestion: "Was zieht dir im Alltag am meisten Energie?"),
            QuestionsPromptPair(topic: "Aussortieren", citizenQuestion: "Welche Sache würdest du sofort aussortieren?", liarQuestion: "Welche Sache würdest du nie aussortieren?"),
            QuestionsPromptPair(topic: "Kuechenkunst", citizenQuestion: "Welches Gericht gelingt dir immer?", liarQuestion: "Welches Gericht wuerdest du gern besser koennen?"),
            QuestionsPromptPair(topic: "Ueberraschung", citizenQuestion: "Worueber wuerdest du dich heute spontan freuen?", liarQuestion: "Womit wuerdest du heute jemand anderen spontan ueberraschen?"),
            QuestionsPromptPair(topic: "Routine", citizenQuestion: "Welche kleine Routine tut dir gut?", liarQuestion: "Welche kleine Routine wuerdest du gern aufbauen?"),
            QuestionsPromptPair(topic: "Lesen", citizenQuestion: "Welche Art von Buch wuerdest du sofort anfangen?", liarQuestion: "Welche Art von Artikel liest du am liebsten?"),
            QuestionsPromptPair(topic: "Geraeusch", citizenQuestion: "Welches Geraeusch findest du beruhigend?", liarQuestion: "Welches Geraeusch nervt dich schnell?"),
            QuestionsPromptPair(topic: "Geruch", citizenQuestion: "Welcher Geruch macht dir sofort gute Laune?", liarQuestion: "Welcher Geruch ist dir unangenehm?"),
            QuestionsPromptPair(topic: "Einkaufsliste", citizenQuestion: "Was steht fast immer auf deiner Einkaufsliste?", liarQuestion: "Was kaufst du nur selten, aber immer gern?"),
            QuestionsPromptPair(topic: "Tageszeit", citizenQuestion: "Was macht fuer dich einen guten Abend aus?", liarQuestion: "Was macht fuer dich einen guten Morgen aus?"),
            QuestionsPromptPair(topic: "Ziele", citizenQuestion: "Welches kleine Ziel hast du fuer die naechste Woche?", liarQuestion: "Welches kleine Ziel hast du fuer den naechsten Monat?"),
            QuestionsPromptPair(topic: "Handy", citizenQuestion: "Wann legst du dein Handy bewusst weg?", liarQuestion: "Wann greifst du fast automatisch zum Handy?"),
            QuestionsPromptPair(topic: "Musikmoment", citizenQuestion: "Bei welcher Gelegenheit hoerst du Musik am liebsten?", liarQuestion: "Bei welcher Gelegenheit hoerst du lieber keine Musik?"),
            QuestionsPromptPair(topic: "Teamwork", citizenQuestion: "Wobei arbeitest du gern im Team?", liarQuestion: "Wobei arbeitest du lieber allein?"),
            QuestionsPromptPair(topic: "Spaziergang", citizenQuestion: "Wo gehst du gern spazieren?", liarQuestion: "Wann gehst du gern spazieren?"),
            QuestionsPromptPair(topic: "Lernenstil", citizenQuestion: "Wie lernst du neue Dinge am liebsten?", liarQuestion: "Wie erklaerst du anderen am liebsten etwas?"),
            QuestionsPromptPair(topic: "Wohngefuehl", citizenQuestion: "Was darf in deinem Zuhause nicht fehlen?", liarQuestion: "Was wuerdest du in einem neuen Zuhause als Erstes aendern?"),
            QuestionsPromptPair(topic: "Feierabend", citizenQuestion: "Wie schaltest du nach der Arbeit ab?", liarQuestion: "Wie kommst du morgens am besten in Gang?"),
            QuestionsPromptPair(topic: "Kleinigkeiten", citizenQuestion: "Welche Kleinigkeit macht dir den Tag schoener?", liarQuestion: "Welche Kleinigkeit nervt dich im Alltag?"),
            QuestionsPromptPair(topic: "Reisegepaeck", citizenQuestion: "Was nimmst du auf Reisen immer mit?", liarQuestion: "Was laesst du auf Reisen bewusst zu Hause?"),
            QuestionsPromptPair(topic: "Entspannung", citizenQuestion: "Welche Aktivitaet beruhigt dich schnell?", liarQuestion: "Welche Aktivitaet bringt dich schnell in Bewegung?"),
            QuestionsPromptPair(topic: "Kreativ", citizenQuestion: "Womit wirst du kreativ?", liarQuestion: "Womit entspannst du dich kreativ?"),
            QuestionsPromptPair(topic: "Sprache", citizenQuestion: "Welches Wort benutzt du zu oft?", liarQuestion: "Welches Wort benutzt du kaum, wuerdest es aber gern?")
        ]
    )
    
    // MARK: - Mindset & Zukunft
    public static let mindsetFuture = QuestionsCategory(
        name: "Mindset & Zukunft",
        promptPairs: [
            // Proband: Wichtigster Wert / Lügner: Vernachlässigter Wert
            QuestionsPromptPair(topic: "Werte", citizenQuestion: "Welcher Wert steht für dich an erster Stelle?", liarQuestion: "Welchen Wert vernachlässigen viele Menschen heutzutage?"),
            
            // Proband: Job / Lügner: Privat (Beides Risikobereitschaft)
            QuestionsPromptPair(topic: "Risiko", citizenQuestion: "In welchem Lebensbereich bist du risikofreudig?", liarQuestion: "In welchem Lebensbereich gehst du immer auf Nummer sicher?"),
            
            // Proband: Aufstehen / Lügner: Durchhalten (Beides Motivation)
            QuestionsPromptPair(topic: "Motivation", citizenQuestion: "Was motiviert dich morgens aufzustehen?", liarQuestion: "Was motiviert dich, bei schwierigen Aufgaben dranzubleiben?"),
            
            // Proband: Erfolg / Lügner: Glück (Beides Definitionen)
            QuestionsPromptPair(topic: "Definition", citizenQuestion: "Was bedeutet Erfolg für dich in einem Wort?", liarQuestion: "Was bedeutet Glück für dich in einem Wort?"),
            
            // Proband: Inspiriert / Lügner: Respektiert (Beides Personen)
            QuestionsPromptPair(topic: "Vorbild", citizenQuestion: "Welche Person inspiriert dich?", liarQuestion: "Vor welcher Person hast du am meisten Respekt?"),
            
            // Proband: Freude / Lügner: Neugier (Beides Zukunft)
            QuestionsPromptPair(topic: "Zukunft", citizenQuestion: "Worauf freust du dich in der Zukunft am meisten?", liarQuestion: "Worauf bist du in der Zukunft am meisten gespannt?"),
            
            QuestionsPromptPair(topic: "Entscheidung", citizenQuestion: "Triffst du Entscheidungen eher spontan oder geplant?", liarQuestion: "Vertraust du bei Entscheidungen eher auf Kopf oder Bauch?"),
            
            // Proband: Superkraft / Lügner: Talent (Beides Fähigkeiten)
            QuestionsPromptPair(topic: "Fähigkeit", citizenQuestion: "Welche Superkraft hättest du gerne?", liarQuestion: "Welches Talent hättest du gerne?"),
            
            // Proband: Welt ändern / Lügner: Selbst ändern (Beides Veränderung)
            QuestionsPromptPair(topic: "Veränderung", citizenQuestion: "Was würdest du an der Welt ändern?", liarQuestion: "Was würdest du an deinem Leben ändern?"),
            
            // Proband: Luxus / Lügner: Gönnen (Beides Materielles)
            QuestionsPromptPair(topic: "Luxus", citizenQuestion: "Was ist für dich der größte Luxus?", liarQuestion: "Womit verwöhnst du dich selbst am liebsten?"),
            
            QuestionsPromptPair(topic: "Rat", citizenQuestion: "Welchen Rat würdest du deinem jüngeren Ich geben?", liarQuestion: "Welchen Rat würdest du deinem zukünftigen Ich geben?"),
            
            QuestionsPromptPair(topic: "Tier", citizenQuestion: "Welches Tier wärst du gerne?", liarQuestion: "Welches Tier fasziniert dich am meisten?"),
            
            QuestionsPromptPair(topic: "Jahreszeit", citizenQuestion: "Welche ist deine absolute Lieblingsjahreszeit?", liarQuestion: "In welcher Jahreszeit bist du am produktivsten?"),
            
            QuestionsPromptPair(topic: "Element", citizenQuestion: "Mit welchem Element (Feuer, Wasser, Erde, Luft) identifizierst du dich?", liarQuestion: "Welches Element findest du am mächtigsten?"),
            
            // Proband: Verzichten / Lügner: Schärfen (Beides Sinne)
            QuestionsPromptPair(topic: "Sinn", citizenQuestion: "Auf welchen deiner 5 Sinne könntest du am wenigsten verzichten?", liarQuestion: "Welchen deiner 5 Sinne würdest du gerne verstärken?"),
            
            // Proband: Reisen / Lügner: Leben (Beides Epochen)
            QuestionsPromptPair(topic: "Zeit", citizenQuestion: "In welche Epoche würdest du gerne reisen?", liarQuestion: "In welcher Epoche hättest du gerne gelebt?"),
            
            QuestionsPromptPair(topic: "Genre", citizenQuestion: "Welches Filmgenre beschreibt dein Leben am besten?", liarQuestion: "Welches Filmgenre schaust du am liebsten?"),
            QuestionsPromptPair(topic: "Wohnen", citizenQuestion: "In welcher Stadt würdest du gerne leben?", liarQuestion: "In welcher Stadt könntest du dir vorstellen, ein Jahr zu bleiben?"),
            QuestionsPromptPair(topic: "Job", citizenQuestion: "Was wäre dein Traumjob?", liarQuestion: "Welches Hobby würdest du gerne zum Beruf machen?"),
            QuestionsPromptPair(topic: "Lotto", citizenQuestion: "Was würdest du als Erstes kaufen, wenn du im Lotto gewinnst?", liarQuestion: "In was würdest du investieren, wenn du reich wärst?"),
            QuestionsPromptPair(topic: "Reise", citizenQuestion: "Wohin geht deine nächste große Reise?", liarQuestion: "Was ist dein absolutes Traumreiseziel?"),
            QuestionsPromptPair(topic: "Haus", citizenQuestion: "Was darf in deinem Traumhaus nicht fehlen?", liarQuestion: "Was wäre das Highlight in deinem Traumhaus?"),
            QuestionsPromptPair(topic: "Alter", citizenQuestion: "Wie alt möchtest du werden?", liarQuestion: "Welches Alter findest du am besten?"),
            QuestionsPromptPair(topic: "Sprache", citizenQuestion: "Welche Sprache würdest du gerne fließend sprechen?", liarQuestion: "Welche Sprache würdest du gerne verstehen können?"),
            QuestionsPromptPair(topic: "Musik", citizenQuestion: "Welches Instrument würdest du gerne spielen?", liarQuestion: "Welches Instrument findest du am schönsten?"),
            QuestionsPromptPair(topic: "Abenteuer", citizenQuestion: "Welches Abenteuer willst du unbedingt noch erleben?", liarQuestion: "Welches besondere Erlebnis steht ganz oben auf deiner Liste?"),
            QuestionsPromptPair(topic: "Ort", citizenQuestion: "Wo möchtest du deinen Lebensabend verbringen?", liarQuestion: "Wo hättest du gerne ein Ferienhaus?"),
            QuestionsPromptPair(topic: "Erfindung", citizenQuestion: "Welche Erfindung würdest du gerne machen?", liarQuestion: "Welche Erfindung würdest du gerne besitzen, wenn es sie gäbe?"),
            QuestionsPromptPair(topic: "Promi", citizenQuestion: "Welchen Star würdest du gerne treffen?", liarQuestion: "Mit welchem Promi würdest du gerne essen gehen?"),
            QuestionsPromptPair(topic: "Buch", citizenQuestion: "Über welches Thema würdest du ein Buch schreiben?", liarQuestion: "Über welches Thema liest du am liebsten?"),
            QuestionsPromptPair(topic: "Auto", citizenQuestion: "Was wäre dein absolutes Traumauto?", liarQuestion: "Welches Auto würdest du dir als Erstes kaufen, wenn Geld egal wäre?"),
            QuestionsPromptPair(topic: "Angst", citizenQuestion: "Welche Angst würdest du gerne besiegen?", liarQuestion: "Auf welche Sorge würdest du gerne verzichten?")
        ]
    )
    
    // MARK: - Party & Spicy
    public static let partySpicy = QuestionsCategory(
        name: "Party & Spicy",
        promptPairs: [
            // Proband: Tanzen / Lügner: Mitsingen (Beides Songs)
            QuestionsPromptPair(topic: "Musik", citizenQuestion: "Bei welchem Song stürmst du die Tanzfläche?", liarQuestion: "Bei welchem Song singst du am lautesten mit?"),
            
            // Proband: Liebster / Lügner: Standard (Beides Drinks)
            QuestionsPromptPair(topic: "Drink", citizenQuestion: "Was trinkst du auf Partys am liebsten?", liarQuestion: "Was ist dein Standard-Bestellgetränk in einer Bar?"),
            
            // Proband: Nach Hause / Lügner: Müde werden (Beides Uhrzeiten)
            QuestionsPromptPair(topic: "Ende", citizenQuestion: "Wann gehst du auf einer guten Party nach Hause?", liarQuestion: "Wann wirst du beim Feiern meistens müde?"),
            
            // Proband: Feiern / Lügner: Ausgehen (Beides Outfits)
            QuestionsPromptPair(topic: "Outfit", citizenQuestion: "Was ziehst du zum Feiern am liebsten an?", liarQuestion: "Was ziehst du für ein schickes Dinner an?"),
            
            // Proband: Mittel / Lügner: Essen (Beides Kater-Hilfe)
            QuestionsPromptPair(topic: "Kater", citizenQuestion: "Was ist dein bestes Mittel gegen Kater?", liarQuestion: "Welches Essen brauchst du nach einer durchzechten Nacht?"),
            
            // Proband: Peinlich / Lügner: Lustig (Beides Ereignisse)
            QuestionsPromptPair(topic: "Story", citizenQuestion: "Was ist dir auf einer Party schon mal Peinliches passiert?", liarQuestion: "Was war der lustigste Moment auf einer Party?"),
            
            // Proband: Ansprechen / Lügner: Kennenlernen (Beides Flirt)
            QuestionsPromptPair(topic: "Flirt", citizenQuestion: "Wie sprichst du jemanden an, der dir gefällt?", liarQuestion: "Wie zeigst du Interesse, wenn dir jemand gefällt?"),
            
            // Proband: Favorit / Lügner: Live sehen (Beides Künstler)
            QuestionsPromptPair(topic: "Act", citizenQuestion: "Welcher DJ oder welche Band ist dein Favorit?", liarQuestion: "Welchen Künstler würdest du gerne live sehen?"),
            
            // Proband: Vorglühen / Lügner: Cornern (Beides Start-Orte)
            QuestionsPromptPair(topic: "Start", citizenQuestion: "Wo glühst du am liebsten vor?", liarQuestion: "Wo triffst du dich meistens vor dem Feiern?"),
            
            // Proband: Karaoke / Lügner: Dusche (Beides Singen)
            QuestionsPromptPair(topic: "Singen", citizenQuestion: "Welchen Song singst du beim Karaoke?", liarQuestion: "Welchen Song singst du unter der Dusche?"),
            
            // Proband: Tresen / Lügner: Tisch (Beides Bar-Orte)
            QuestionsPromptPair(topic: "Bar", citizenQuestion: "Was bestellst du am liebsten an der Bar?", liarQuestion: "Was bestellst du, wenn du die Runde zahlst?"),
            
            // Proband: Gehen / Lügner: Absagen (Beides Ausreden)
            QuestionsPromptPair(topic: "Ausrede", citizenQuestion: "Welche Ausrede nutzt du, um früher zu gehen?", liarQuestion: "Welche Ausrede nutzt du, um ein Treffen abzusagen?"),
            
            // Proband: Können / Lügner: Lernen (Beides Tanzstile)
            QuestionsPromptPair(topic: "Tanzen", citizenQuestion: "Welchen Tanzstil würdest du gerne können?", liarQuestion: "Welchen Tanz findest du beeindruckend?"),
            
            // Proband: Abend / Lügner: Wochenende (Beides Geldsummen)
            QuestionsPromptPair(topic: "Geld", citizenQuestion: "Wie viel gibst du an einem guten Abend aus?", liarQuestion: "Wie viel Geld nimmst du bar zum Feiern mit?"),
            
            // Proband: Aufgewacht / Lügner: Eingeschlafen (Beides Orte)
            QuestionsPromptPair(topic: "Schlaf", citizenQuestion: "Wo bist du nach einer Party mal aufgewacht?", liarQuestion: "Wo bist du schon mal versehentlich eingeschlafen?"),
            QuestionsPromptPair(topic: "Attraktivität", citizenQuestion: "Was findest du an anderen körperlich am attraktivsten?", liarQuestion: "Was findest du an der Ausstrahlung anderer am wichtigsten?"),
            QuestionsPromptPair(topic: "Bett", citizenQuestion: "Was ist dir im Bett besonders wichtig?", liarQuestion: "Was macht für dich guten Sex aus?"),
            QuestionsPromptPair(topic: "Ort", citizenQuestion: "An welchem ungewöhnlichen Ort hattest du schon Sex?", liarQuestion: "An welchem Ort hättest du gerne mal Sex?"),
            QuestionsPromptPair(topic: "Kleidung", citizenQuestion: "Was findest du beim anderen Geschlecht sexy?", liarQuestion: "Welches Kleidungsstück findest du besonders anziehend?"),
            QuestionsPromptPair(topic: "App", citizenQuestion: "Welche Dating-App hast du schon mal benutzt?", liarQuestion: "Auf welcher Plattform hast du schon mal geflirtet?"),
            QuestionsPromptPair(topic: "Ex", citizenQuestion: "Mit wie vielen Ex-Partnern hast du noch Kontakt?", liarQuestion: "Mit wie vielen Ex-Partnern bist du noch befreundet?"),
            QuestionsPromptPair(topic: "Initiative", citizenQuestion: "Machst du eher den ersten Schritt oder wartest du?", liarQuestion: "Sprichst du jemanden an oder lässt du dich ansprechen?"),
            QuestionsPromptPair(topic: "Crush", citizenQuestion: "Wer ist dein Celebrity Crush?", liarQuestion: "Welchen Promi findest du heiß?"),
            QuestionsPromptPair(topic: "Erfahrung", citizenQuestion: "Hattest du schon mal einen One Night Stand?", liarQuestion: "Hattest du schon mal ein Date, das im Bett endete?"),
            QuestionsPromptPair(topic: "Erstes Mal", citizenQuestion: "Wann hast du deinen ersten Kuss bekommen?", liarQuestion: "In welchem Alter hattest du deinen ersten Kuss?"),
            QuestionsPromptPair(topic: "Farbe", citizenQuestion: "Welche Farbe findest du bei Unterwäsche attraktiv?", liarQuestion: "Welche Farbe trägst du bei Kleidung am liebsten?"),
            QuestionsPromptPair(topic: "Gedanken", citizenQuestion: "Hast du eine geheime Fantasie?", liarQuestion: "Wovon träumst du manchmal tagüber?"),
            QuestionsPromptPair(topic: "Alter", citizenQuestion: "Welcher Altersunterschied ist für dich okay?", liarQuestion: "Welchen Altersunterschied findest du ideal?"),
            QuestionsPromptPair(topic: "Vorliebe", citizenQuestion: "Welche Stellung magst du am liebsten?", liarQuestion: "Welche Position bevorzugst du meistens?")
        ]
    )
    
    // MARK: - Hard & Tabu (optional)
    public static let darkTaboo = QuestionsCategory(
        name: "Hard & Tabu",
        promptPairs: [
            // Proband: Gesetz / Lügner: Regel (Beides Verstöße)
            QuestionsPromptPair(topic: "Regelbruch", citizenQuestion: "Welches Gesetz würdest du brechen, wenn es keine Strafe gäbe?", liarQuestion: "Welche gesellschaftliche Regel würdest du gerne ignorieren?"),
            
            // Proband: Gelogen / Lügner: Geschummelt (Beides Unehrlichkeit)
            QuestionsPromptPair(topic: "Lüge", citizenQuestion: "Wann hast du zuletzt gelogen?", liarQuestion: "Wann hast du zuletzt die Wahrheit verdreht?"),
            
            // Proband: Hasst / Lügner: Verachtest (Beides Abneigung Personen)
            QuestionsPromptPair(topic: "Feind", citizenQuestion: "Gibt es jemanden, den du wirklich hasst?", liarQuestion: "Gibt es jemanden, den du absolut nicht ausstehen kannst?"),
            
            QuestionsPromptPair(topic: "Ende", citizenQuestion: "Wie würdest du am liebsten sterben?", liarQuestion: "Wovor hättest du beim Thema Tod am meisten Angst?"),

            QuestionsPromptPair(topic: "Scham", citizenQuestion: "Wofür schämst du dich heute noch ein bisschen?", liarQuestion: "Wofür würdest du dich wahrscheinlich schämen, wenn es rauskommt?"),
            
            QuestionsPromptPair(topic: "Notlüge", citizenQuestion: "Welche Notlüge benutzt du am häufigsten?", liarQuestion: "Welche Wahrheit würdest du am ehesten verschweigen?"),
            
            QuestionsPromptPair(topic: "Grenze", citizenQuestion: "Wo ziehst du eine klare moralische Grenze?", liarQuestion: "Wo wärst du am ehesten bereit, eine Grenze zu überschreiten?"),
            
            QuestionsPromptPair(topic: "Neugier", citizenQuestion: "Was würdest du gerne heimlich wissen?", liarQuestion: "Was würdest du lieber niemals erfahren?"),
            
            QuestionsPromptPair(topic: "Manipulation", citizenQuestion: "Hast du schon mal jemanden manipuliert?", liarQuestion: "Hast du dich schon mal manipuliert gefühlt?"),
            
            // Proband: Geheimnisse / Lügner: Wahres Ich (Beides Wissen über dich)
            QuestionsPromptPair(topic: "Wissen", citizenQuestion: "Wer kennt deine dunkelsten Geheimnisse?", liarQuestion: "Wer weiß alles über dich?"),
            
            // Proband: Angst / Lügner: Sorge (Beides Furcht)
            QuestionsPromptPair(topic: "Furcht", citizenQuestion: "Wovor hast du am meisten Angst?", liarQuestion: "Was ist deine größte Sorge im Leben?"),
            
            // Proband: Verbrechen / Lügner: Tat (Beides Kriminelles)
            QuestionsPromptPair(topic: "Kriminalität", citizenQuestion: "Welches Verbrechen könntest du dir theoretisch vorstellen zu begehen?", liarQuestion: "Für welche Tat hättest du theoretisch ein Motiv?"),
            
            // Proband: Rachsüchtig / Lügner: Nachtragend (Beides Eigenschaften)
            QuestionsPromptPair(topic: "Charakter", citizenQuestion: "Bist du ein rachsüchtiger Mensch?", liarQuestion: "Bist du ein nachtragender Mensch?"),
            
            // Proband: Schadenfreude / Lügner: Genugtuung (Beides Gefühle)
            QuestionsPromptPair(topic: "Gefühl", citizenQuestion: "Wann hast du zuletzt Schadenfreude empfunden?", liarQuestion: "Wann hast du zuletzt Genugtuung empfunden?"),
            
            // Proband: Geklaut / Lügner: Mitgehen lassen (Beides Diebstahl)
            QuestionsPromptPair(topic: "Diebstahl", citizenQuestion: "Was hast du schon mal geklaut?", liarQuestion: "Was hast du schon mal versehentlich eingesteckt?"),
            
            // Proband: Betrogen / Lügner: Hintergangen (Beides Vertrauensbruch)
            QuestionsPromptPair(topic: "Verrat", citizenQuestion: "Hast du schon mal jemanden betrogen?", liarQuestion: "Hast du schon mal das Vertrauen von jemandem missbraucht?"),
            
            // Proband: Neidisch / Lügner: Eifersüchtig (Beides Missgunst)
            QuestionsPromptPair(topic: "Neid", citizenQuestion: "Auf wen bist du heimlich neidisch?", liarQuestion: "Auf wessen Erfolg bist du manchmal eifersüchtig?"),
            
            // Proband: Sünde / Lügner: Laster (Beides Schwächen)
            QuestionsPromptPair(topic: "Schwäche", citizenQuestion: "Welche der 7 Todsünden ist deine größte?", liarQuestion: "Was ist dein größtes Laster?"),
            
            // Proband: Dunkelster Gedanke / Lügner: Geheimster Wunsch (Beides Kopfkino)
            QuestionsPromptPair(topic: "Gedanke", citizenQuestion: "Was war dein dunkelster Gedanke?", liarQuestion: "Was ist ein Gedanke, den du niemandem erzählst?"),
            
            // Proband: Drogen / Lügner: Rauschmittel (Beides Konsum)
            QuestionsPromptPair(topic: "Illegal", citizenQuestion: "Hast du schon mal illegale Substanzen probiert?", liarQuestion: "Hast du schon mal etwas Verbotenes konsumiert?"),
            
            QuestionsPromptPair(topic: "Geheimnis", citizenQuestion: "Welches Geheimnis würdest du nie laut sagen?", liarQuestion: "Welches Geheimnis würdest du nur einer Person anvertrauen?"),
            
            QuestionsPromptPair(topic: "Reue", citizenQuestion: "Was bereust du am meisten?", liarQuestion: "Was würdest du sofort anders machen, wenn du könntest?")
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
