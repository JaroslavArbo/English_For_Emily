import Foundation
import Combine

struct DailyPracticeStat: Identifiable, Codable, Equatable {
    var dayKey: String
    var testedCount: Int
    var starsEarned: Int

    var id: String { dayKey }
}

struct WordBackup: Codable {
    var appName: String
    var version: Int
    var exportedAt: Date
    var latestSourceTitle: String
    var selectedLanguageCode: String
    var words: [WordItem]
}

final class WordStore: ObservableObject {
    @Published var words: [WordItem] = [] {
        didSet { save() }
    }

    @Published var latestSourceTitle: String = "" {
        didSet { saveLatestSource() }
    }

    @Published var selectedLanguage: LearningLanguage = .english {
        didSet {
            UserDefaults.standard.set(selectedLanguage.rawValue, forKey: "selectedLanguageCode")
        }
    }

    @Published var dailyStats: [DailyPracticeStat] = [] {
        didSet { saveDailyStats() }
    }

    private let wordsURL: URL
    private let latestURL: URL
    private let dailyStatsURL: URL

    init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.wordsURL = docs.appendingPathComponent("words.json")
        self.latestURL = docs.appendingPathComponent("latestSource.txt")
        self.dailyStatsURL = docs.appendingPathComponent("dailyStats.json")

        if let raw = UserDefaults.standard.string(forKey: "selectedLanguageCode"),
           let language = LearningLanguage(rawValue: raw) {
            self.selectedLanguage = language
        }

        load()
        seedDefaultWordsIfNeeded()
    }

    var selectedLanguageWords: [WordItem] {
        words.filter { $0.languageCode == selectedLanguage.rawValue }
    }


    private static let defaultEnglishWords: [(String, String)] = [
        ("UNICORN", "jednorožec"),
        ("STAR", "hvězda"),
        ("FLOWER", "květina"),
        ("TREE", "strom"),
        ("HOUSE", "dům"),
        ("DOG", "pes"),
        ("CAT", "kočka"),
        ("BIRD", "pták"),
        ("FISH", "ryba"),
        ("APPLE", "jablko"),
        ("WATER", "voda"),
        ("SUN", "slunce"),
        ("MOON", "měsíc"),
        ("BOOK", "kniha"),
        ("BALL", "míč"),
        ("PLAY", "hrát si"),
        ("RUN", "běžet"),
        ("JUMP", "skákat"),
        ("SING", "zpívat"),
        ("DANCE", "tančit"),
        ("EAT", "jíst"),
        ("DRINK", "pít"),
        ("SLEEP", "spát"),
        ("READ", "číst"),
        ("WRITE", "psát"),
        ("DRAW", "kreslit"),
        ("LISTEN", "poslouchat"),
        ("SAY", "říct"),
        ("LOOK", "dívat se"),
        ("HELP", "pomáhat"),
        ("CLASSROOM", "třída"),
        ("TEACHER", "učitel/učitelka"),
        ("PUPIL", "žák/žákyně"),
        ("SCHOOL", "škola"),
        ("BAG", "taška"),
        ("PENCIL", "tužka"),
        ("PEN", "pero"),
        ("RUBBER", "guma"),
        ("ERASER", "guma"),
        ("RULER", "pravítko"),
        ("DESK", "lavice"),
        ("CHAIR", "židle"),
        ("TABLE", "stůl"),
        ("BOARD", "tabule"),
        ("DOOR", "dveře"),
        ("WINDOW", "okno"),
        ("BOOKCASE", "knihovna"),
        ("COMPUTER", "počítač"),
        ("NOTEBOOK", "sešit"),
        ("CRAYON", "pastelka"),
        ("PICTURE", "obrázek"),
        ("PAGE", "stránka"),
        ("STORY", "příběh"),
        ("SONG", "písnička"),
        ("RED", "červená"),
        ("BLUE", "modrá"),
        ("GREEN", "zelená"),
        ("YELLOW", "žlutá"),
        ("ORANGE", "oranžová/pomeranč"),
        ("PINK", "růžová"),
        ("PURPLE", "fialová"),
        ("BLACK", "černá"),
        ("WHITE", "bílá"),
        ("BROWN", "hnědá"),
        ("GREY", "šedá"),
        ("ONE", "jedna"),
        ("TWO", "dvě"),
        ("THREE", "tři"),
        ("FOUR", "čtyři"),
        ("FIVE", "pět"),
        ("SIX", "šest"),
        ("SEVEN", "sedm"),
        ("EIGHT", "osm"),
        ("NINE", "devět"),
        ("TEN", "deset"),
        ("ELEVEN", "jedenáct"),
        ("TWELVE", "dvanáct"),
        ("THIRTEEN", "třináct"),
        ("FOURTEEN", "čtrnáct"),
        ("FIFTEEN", "patnáct"),
        ("SIXTEEN", "šestnáct"),
        ("SEVENTEEN", "sedmnáct"),
        ("EIGHTEEN", "osmnáct"),
        ("NINETEEN", "devatenáct"),
        ("TWENTY", "dvacet"),
        ("FAMILY", "rodina"),
        ("MUM", "maminka"),
        ("DAD", "tatínek"),
        ("MOTHER", "matka"),
        ("FATHER", "otec"),
        ("SISTER", "sestra"),
        ("BROTHER", "bratr"),
        ("GRANDMA", "babička"),
        ("GRANDPA", "dědeček"),
        ("BABY", "miminko"),
        ("BOY", "chlapec"),
        ("GIRL", "dívka"),
        ("FRIEND", "kamarád/kamarádka"),
        ("MAN", "muž"),
        ("WOMAN", "žena"),
        ("CHILD", "dítě"),
        ("CHILDREN", "děti"),
        ("HEAD", "hlava"),
        ("HAIR", "vlasy"),
        ("FACE", "obličej"),
        ("EYE", "oko"),
        ("EYES", "oči"),
        ("EAR", "ucho"),
        ("EARS", "uši"),
        ("NOSE", "nos"),
        ("MOUTH", "ústa"),
        ("TOOTH", "zub"),
        ("TEETH", "zuby"),
        ("HAND", "ruka"),
        ("HANDS", "ruce"),
        ("ARM", "paže"),
        ("LEG", "noha"),
        ("FOOT", "chodidlo/noha"),
        ("FEET", "chodidla/nohy"),
        ("BODY", "tělo"),
        ("TOY", "hračka"),
        ("DOLL", "panenka"),
        ("CAR", "auto"),
        ("TRAIN", "vlak"),
        ("PLANE", "letadlo"),
        ("BIKE", "kolo"),
        ("KITE", "drak"),
        ("ROBOT", "robot"),
        ("MONSTER", "příšera"),
        ("TEDDY", "plyšový medvídek"),
        ("GAME", "hra"),
        ("PUZZLE", "skládačka"),
        ("BALLOON", "balónek"),
        ("BOAT", "loď"),
        ("ANIMAL", "zvíře"),
        ("HORSE", "kůň"),
        ("COW", "kráva"),
        ("SHEEP", "ovce"),
        ("GOAT", "koza"),
        ("PIG", "prase"),
        ("DUCK", "kachna"),
        ("CHICKEN", "kuře/slepice"),
        ("FROG", "žába"),
        ("MOUSE", "myš"),
        ("RABBIT", "králík"),
        ("TURTLE", "želva"),
        ("LIZARD", "ještěrka"),
        ("SNAKE", "had"),
        ("MONKEY", "opice"),
        ("ELEPHANT", "slon"),
        ("GIRAFFE", "žirafa"),
        ("CROCODILE", "krokodýl"),
        ("TIGER", "tygr"),
        ("LION", "lev"),
        ("HIPPO", "hroch"),
        ("PARROT", "papoušek"),
        ("SPIDER", "pavouk"),
        ("BANANA", "banán"),
        ("PEAR", "hruška"),
        ("CAKE", "dort"),
        ("BREAD", "chléb"),
        ("MILK", "mléko"),
        ("JUICE", "džus"),
        ("ICE CREAM", "zmrzlina"),
        ("CHEESE", "sýr"),
        ("EGG", "vejce"),
        ("RICE", "rýže"),
        ("MEAT", "maso"),
        ("CARROT", "mrkev"),
        ("POTATO", "brambora"),
        ("TOMATO", "rajče"),
        ("PIZZA", "pizza"),
        ("BURGER", "hamburger"),
        ("ROOM", "pokoj"),
        ("BEDROOM", "ložnice"),
        ("BATHROOM", "koupelna"),
        ("KITCHEN", "kuchyně"),
        ("LIVING ROOM", "obývací pokoj"),
        ("GARDEN", "zahrada"),
        ("BED", "postel"),
        ("SOFA", "pohovka"),
        ("LAMP", "lampa"),
        ("TV", "televize"),
        ("BATH", "vana"),
        ("TOILET", "toaleta"),
        ("FLOOR", "podlaha"),
        ("WALL", "zeď"),
        ("CLOTHES", "oblečení"),
        ("T-SHIRT", "tričko"),
        ("SHIRT", "košile"),
        ("TROUSERS", "kalhoty"),
        ("SHORTS", "kraťasy"),
        ("SKIRT", "sukně"),
        ("DRESS", "šaty"),
        ("SHOES", "boty"),
        ("SOCKS", "ponožky"),
        ("HAT", "čepice/klobouk"),
        ("JACKET", "bunda"),
        ("COAT", "kabát"),
        ("BIG", "velký"),
        ("SMALL", "malý"),
        ("LONG", "dlouhý"),
        ("SHORT", "krátký"),
        ("HAPPY", "šťastný"),
        ("SAD", "smutný"),
        ("HOT", "horký"),
        ("COLD", "studený"),
        ("OLD", "starý"),
        ("NEW", "nový"),
        ("GOOD", "dobrý"),
        ("BAD", "špatný"),
        ("BEAUTIFUL", "krásný"),
        ("UGLY", "ošklivý"),
        ("FUNNY", "legrační"),
        ("FAVOURITE", "oblíbený"),
        ("OPEN", "otevřít"),
        ("CLOSE", "zavřít"),
        ("STAND UP", "postavit se"),
        ("SIT DOWN", "sednout si"),
        ("POINT", "ukázat"),
        ("TOUCH", "dotknout se"),
        ("COUNT", "počítat"),
        ("COLOUR", "vybarvit/barva"),
        ("MATCH", "přiřadit"),
        ("CIRCLE", "zakroužkovat/kruh"),
        ("ASK", "zeptat se"),
        ("ANSWER", "odpovědět/odpověď"),
        ("SPEAK", "mluvit"),
        ("SPELL", "hláskovat"),
        ("SHOW", "ukázat"),
        ("CLAP", "tleskat"),
        ("STOP", "zastavit"),
        ("START", "začít"),
        ("HAVE", "mít"),
        ("LIKE", "mít rád"),
        ("LOVE", "milovat"),
        ("WANT", "chtít"),
        ("CAN", "umět/moci"),
        ("GO", "jít"),
        ("COME", "přijít"),
        ("SEE", "vidět"),
        ("HEAR", "slyšet"),
        ("MAKE", "dělat/vyrábět"),
        ("TAKE", "vzít"),
        ("GIVE", "dát"),
        ("PUT", "položit/dát"),
        ("WASH", "mýt"),
        ("FLY", "létat"),
        ("SWIM", "plavat"),
        ("RIDE", "jezdit"),
        ("CLIMB", "lézt"),
        ("KICK", "kopnout"),
        ("CATCH", "chytit"),
        ("THROW", "hodit"),
        ("SMILE", "usmívat se"),
        ("I", "já"),
        ("YOU", "ty/vy"),
        ("HE", "on"),
        ("SHE", "ona"),
        ("WE", "my"),
        ("THEY", "oni"),
        ("MY", "můj/moje"),
        ("YOUR", "tvůj/váš"),
        ("THIS", "tento/tato"),
        ("THAT", "tamten/tamta"),
        ("YES", "ano"),
        ("NO", "ne"),
        ("PLEASE", "prosím"),
        ("THANK YOU", "děkuji"),
        ("HELLO", "ahoj"),
        ("GOODBYE", "nashledanou"),
        ("GOOD MORNING", "dobré ráno"),
        ("GOOD NIGHT", "dobrou noc"),
        ("PARK", "park"),
        ("SHOP", "obchod"),
        ("ZOO", "zoo"),
        ("STREET", "ulice"),
        ("PLAYGROUND", "hřiště"),
        ("BUS", "autobus"),
        ("SUNNY", "slunečno"),
        ("RAIN", "déšť"),
        ("CLOUD", "mrak"),
        ("WIND", "vítr"),
    ]

    private static let defaultSpanishWords: [(String, String)] = [
        ("UNICORNIO", "jednorožec"),
        ("ESTRELLA", "hvězda"),
        ("FLOR", "květina"),
        ("ÁRBOL", "strom"),
        ("CASA", "dům"),
        ("PERRO", "pes"),
        ("GATO", "kočka"),
        ("PÁJARO", "pták"),
        ("PEZ", "ryba"),
        ("MANZANA", "jablko"),
        ("AGUA", "voda"),
        ("SOL", "slunce"),
        ("LUNA", "měsíc"),
        ("LIBRO", "kniha"),
        ("PELOTA", "míč"),
        ("JUGAR", "hrát si"),
        ("CORRER", "běžet"),
        ("SALTAR", "skákat"),
        ("CANTAR", "zpívat"),
        ("BAILAR", "tančit"),
        ("COMER", "jíst"),
        ("BEBER", "pít"),
        ("DORMIR", "spát"),
        ("LEER", "číst"),
        ("ESCRIBIR", "psát"),
        ("DIBUJAR", "kreslit"),
        ("ESCUCHAR", "poslouchat"),
        ("DECIR", "říct"),
        ("MIRAR", "dívat se"),
        ("AYUDAR", "pomáhat"),
        ("HOLA", "ahoj"),
        ("ADIOS", "nashledanou"),
        ("GRACIAS", "děkuji"),
        ("POR FAVOR", "prosím"),
        ("SÍ", "ano"),
        ("NO", "ne"),
    ]

    private func seedDefaultWordsIfNeeded() {
        var changed = false

        changed = addDefaultWordsIfMissing(
            Self.defaultEnglishWords,
            languageCode: LearningLanguage.english.rawValue,
            sourceTitle: "Kid's Box 1 – odhad základní slovní zásoby"
        ) || changed

        changed = addDefaultWordsIfMissing(
            Self.defaultSpanishWords,
            languageCode: LearningLanguage.spanish.rawValue,
            sourceTitle: "Základní španělština pro děti"
        ) || changed

        if changed {
            save()
        }
    }

    private func addDefaultWordsIfMissing(
        _ defaultWords: [(String, String)],
        languageCode: String,
        sourceTitle: String
    ) -> Bool {
        var changed = false
        var existingKeys = Set(words.map { importKey(english: $0.english, sourceTitle: $0.sourceTitle, languageCode: $0.languageCode) })

        for item in defaultWords {
            let target = Self.cleanEnglish(item.0)
            let czech = item.1
            let key = importKey(english: target, sourceTitle: sourceTitle, languageCode: languageCode)

            if !existingKeys.contains(key) {
                words.append(
                    WordItem(
                        english: target,
                        czech: czech,
                        sourceTitle: sourceTitle,
                        languageCode: languageCode
                    )
                )
                existingKeys.insert(key)
                changed = true
            }
        }

        return changed
    }


    func addImportedWords(_ imported: [String], sourceTitle: String) {
        let cleaned = imported
            .map { WordStore.cleanEnglish($0) }
            .filter { !$0.isEmpty }

        var seen = Set(words.map { importKey(english: $0.english, sourceTitle: $0.sourceTitle, languageCode: $0.languageCode) })
        var newItems: [WordItem] = []

        for word in cleaned {
            let key = importKey(english: word, sourceTitle: sourceTitle, languageCode: selectedLanguage.rawValue)
            if !seen.contains(key) {
                newItems.append(WordItem(english: word, sourceTitle: sourceTitle, languageCode: selectedLanguage.rawValue))
                seen.insert(key)
            }
        }

        words.insert(contentsOf: newItems, at: 0)
        latestSourceTitle = sourceTitle
    }

    func addManualWord(english: String, czech: String = "") {
        let cleanedEnglish = WordStore.cleanEnglish(english)
        let cleanedCzech = czech.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanedEnglish.isEmpty else { return }

        let sourceTitle = "Ručně přidané"
        let key = importKey(english: cleanedEnglish, sourceTitle: sourceTitle, languageCode: selectedLanguage.rawValue)
        let existingKeys = Set(words.map { importKey(english: $0.english, sourceTitle: $0.sourceTitle, languageCode: $0.languageCode) })

        if !existingKeys.contains(key) {
            let item = WordItem(english: cleanedEnglish, czech: cleanedCzech, sourceTitle: sourceTitle, languageCode: selectedLanguage.rawValue)
            words.insert(item, at: 0)
        }
    }

    func updateTranslation(for id: UUID, czech: String) {
        guard let index = words.firstIndex(where: { $0.id == id }) else { return }
        words[index].czech = czech
    }

    func deleteWord(id: UUID) {
        words.removeAll { $0.id == id }
    }

    func deleteWords(at offsets: IndexSet) {
        let visibleIDs = selectedLanguageWords.map { $0.id }

        for offset in offsets {
            guard visibleIDs.indices.contains(offset) else { continue }
            deleteWord(id: visibleIDs[offset])
        }
    }

    func recordAnswer(for id: UUID, correct: Bool) {
        guard let index = words.firstIndex(where: { $0.id == id }) else { return }
        words[index].lastPracticedAt = Date()
        if correct {
            words[index].correctCount += 1
            words[index].mastery = min(5, words[index].mastery + 1)
        } else {
            words[index].wrongCount += 1
            words[index].mastery = max(0, words[index].mastery - 1)
        }

        recordDailyPractice(correct: correct)
        ReminderManager.shared.cancelReminder(for: Date())
    }

    func recordDailyPractice(correct: Bool) {
        let key = Self.dayKey(for: Date())

        if let index = dailyStats.firstIndex(where: { $0.dayKey == key }) {
            dailyStats[index].testedCount += 1
            if correct {
                dailyStats[index].starsEarned += 1
            }
        } else {
            dailyStats.append(
                DailyPracticeStat(
                    dayKey: key,
                    testedCount: 1,
                    starsEarned: correct ? 1 : 0
                )
            )
        }

        dailyStats.sort { $0.dayKey < $1.dayKey }
    }

    var todayStat: DailyPracticeStat {
        let key = Self.dayKey(for: Date())
        return dailyStats.first(where: { $0.dayKey == key }) ?? DailyPracticeStat(dayKey: key, testedCount: 0, starsEarned: 0)
    }

    func hasTesting(onDayKey dayKey: String) -> Bool {
        dailyStats.first(where: { $0.dayKey == dayKey })?.testedCount ?? 0 > 0
    }

    func recentDailyStats(days: Int) -> [DailyPracticeStat] {
        let calendar = Calendar.current
        let today = Date()
        let existing = Dictionary(uniqueKeysWithValues: dailyStats.map { ($0.dayKey, $0) })

        var result: [DailyPracticeStat] = []

        for offset in stride(from: days - 1, through: 0, by: -1) {
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { continue }
            let key = Self.dayKey(for: date)
            result.append(existing[key] ?? DailyPracticeStat(dayKey: key, testedCount: 0, starsEarned: 0))
        }

        return result
    }

    static func dayKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    func practiceDeck(limit: Int = 12, includeUntranslated: Bool = false) -> [WordItem] {
        let languageWords = words.filter { $0.languageCode == selectedLanguage.rawValue }
        let available = includeUntranslated ? languageWords : languageWords.filter { !$0.needsTranslation }
        guard !available.isEmpty else { return [] }

        // Priority:
        // 1) words that have never been tested,
        // 2) words with the weakest score,
        // 3) words with better/good score.
        let neverTested = available
            .filter { $0.correctCount == 0 && $0.wrongCount == 0 && $0.lastPracticedAt == nil }
            .shuffled()

        let alreadyTested = available
            .filter { !($0.correctCount == 0 && $0.wrongCount == 0 && $0.lastPracticedAt == nil) }
            .sorted { first, second in
                let firstScore = practicePriorityScore(first)
                let secondScore = practicePriorityScore(second)

                if firstScore != secondScore {
                    return firstScore < secondScore
                }

                let firstDate = first.lastPracticedAt ?? .distantPast
                let secondDate = second.lastPracticedAt ?? .distantPast
                return firstDate < secondDate
            }

        var deck: [WordItem] = []
        deck.append(contentsOf: neverTested)
        deck.append(contentsOf: alreadyTested)

        return Array(deck.prefix(limit))
    }

    private func practicePriorityScore(_ word: WordItem) -> Int {
        // Lower number = higher priority.
        // Wrong answers make the score worse; mastery and correct answers improve it.
        let answerBalance = word.correctCount - word.wrongCount
        return (word.mastery * 10) + answerBalance
    }

    func exportBackupData() throws -> Data {
        let backup = WordBackup(
            appName: "EnglishForEmily",
            version: 2,
            exportedAt: Date(),
            latestSourceTitle: latestSourceTitle,
            selectedLanguageCode: selectedLanguage.rawValue,
            words: words
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(backup)
    }

    func importBackupData(_ data: Data) throws -> Int {
        let importedWords: [WordItem]
        let importedLatestSourceTitle: String?
        let importedSelectedLanguageCode: String?

        let isoDecoder = JSONDecoder()
        isoDecoder.dateDecodingStrategy = .iso8601

        if let backup = try? isoDecoder.decode(WordBackup.self, from: data) {
            importedWords = backup.words
            importedLatestSourceTitle = backup.latestSourceTitle
            importedSelectedLanguageCode = backup.selectedLanguageCode
        } else if let plainWords = try? isoDecoder.decode([WordItem].self, from: data) {
            importedWords = plainWords
            importedLatestSourceTitle = nil
            importedSelectedLanguageCode = nil
        } else {
            let defaultDecoder = JSONDecoder()
            if let backup = try? defaultDecoder.decode(WordBackup.self, from: data) {
                importedWords = backup.words
                importedLatestSourceTitle = backup.latestSourceTitle
                importedSelectedLanguageCode = backup.selectedLanguageCode
            } else {
                importedWords = try defaultDecoder.decode([WordItem].self, from: data)
                importedLatestSourceTitle = nil
                importedSelectedLanguageCode = nil
            }
        }

        guard !importedWords.isEmpty else { return 0 }

        var changedCount = 0
        var existingIndexByKey: [String: Int] = [:]
        rebuildIndexMap(&existingIndexByKey)

        for imported in importedWords {
            let cleanedTarget = WordStore.cleanEnglish(imported.english)
            guard !cleanedTarget.isEmpty else { continue }

            var cleanImported = imported
            cleanImported.english = cleanedTarget
            cleanImported.czech = imported.czech.trimmingCharacters(in: .whitespacesAndNewlines)
            cleanImported.sourceTitle = imported.sourceTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Import slovíček" : imported.sourceTitle
            if LearningLanguage(rawValue: cleanImported.languageCode) == nil {
                cleanImported.languageCode = LearningLanguage.english.rawValue
            }

            let key = importKey(english: cleanImported.english, sourceTitle: cleanImported.sourceTitle, languageCode: cleanImported.languageCode)

            if let index = existingIndexByKey[key] {
                if words[index].czech.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !cleanImported.czech.isEmpty {
                    words[index].czech = cleanImported.czech
                    changedCount += 1
                }

                words[index].correctCount = max(words[index].correctCount, cleanImported.correctCount)
                words[index].wrongCount = max(words[index].wrongCount, cleanImported.wrongCount)
                words[index].mastery = max(words[index].mastery, cleanImported.mastery)

                if let importedDate = cleanImported.lastPracticedAt {
                    if let currentDate = words[index].lastPracticedAt {
                        words[index].lastPracticedAt = max(currentDate, importedDate)
                    } else {
                        words[index].lastPracticedAt = importedDate
                    }
                }
            } else {
                words.insert(cleanImported, at: 0)
                rebuildIndexMap(&existingIndexByKey)
                changedCount += 1
            }
        }

        if let importedLatestSourceTitle, !importedLatestSourceTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            latestSourceTitle = importedLatestSourceTitle
        }

        if let code = importedSelectedLanguageCode,
           let language = LearningLanguage(rawValue: code) {
            selectedLanguage = language
        }

        return changedCount
    }

    static func cleanEnglish(_ text: String) -> String {
        text
            .replacingOccurrences(of: "’", with: "'")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: #" {2,}"#, with: " ", options: .regularExpression)
            .uppercased()
    }

    private func rebuildIndexMap(_ map: inout [String: Int]) {
        map = [:]
        for (index, word) in words.enumerated() {
            map[importKey(english: word.english, sourceTitle: word.sourceTitle, languageCode: word.languageCode)] = index
        }
    }

    private func importKey(english: String, sourceTitle: String, languageCode: String) -> String {
        let normalizedTarget = WordStore.cleanEnglish(english)
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "en_US"))
            .lowercased()
        let normalizedSource = sourceTitle
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "en_US"))
            .lowercased()
        return normalizedTarget + "|" + normalizedSource + "|" + languageCode
    }

    private func load() {
        if let data = try? Data(contentsOf: wordsURL) {
            let decoder = JSONDecoder()
            if let decoded = try? decoder.decode([WordItem].self, from: data) {
                words = decoded
            }
        }
        if let latest = try? String(contentsOf: latestURL) {
            latestSourceTitle = latest
        }

        if let data = try? Data(contentsOf: dailyStatsURL),
           let decoded = try? JSONDecoder().decode([DailyPracticeStat].self, from: data) {
            dailyStats = decoded
        }
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(words) else { return }
        try? data.write(to: wordsURL, options: [.atomic])
    }

    private func saveLatestSource() {
        try? latestSourceTitle.write(to: latestURL, atomically: true, encoding: .utf8)
    }

    private func saveDailyStats() {
        guard let data = try? JSONEncoder().encode(dailyStats) else { return }
        try? data.write(to: dailyStatsURL, options: [.atomic])
    }
}
