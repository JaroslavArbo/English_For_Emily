import Foundation

struct WordItem: Identifiable, Codable, Equatable {
    let id: UUID
    var english: String
    var czech: String
    var sourceTitle: String
    var languageCode: String
    var importedAt: Date
    var correctCount: Int
    var wrongCount: Int
    var mastery: Int
    var lastPracticedAt: Date?

    init(
        id: UUID = UUID(),
        english: String,
        czech: String = "",
        sourceTitle: String,
        languageCode: String = LearningLanguage.english.rawValue,
        importedAt: Date = Date(),
        correctCount: Int = 0,
        wrongCount: Int = 0,
        mastery: Int = 0,
        lastPracticedAt: Date? = nil
    ) {
        self.id = id
        self.english = english
        self.czech = czech
        self.sourceTitle = sourceTitle
        self.languageCode = languageCode
        self.importedAt = importedAt
        self.correctCount = correctCount
        self.wrongCount = wrongCount
        self.mastery = mastery
        self.lastPracticedAt = lastPracticedAt
    }

    enum CodingKeys: String, CodingKey {
        case id
        case english
        case czech
        case sourceTitle
        case languageCode
        case importedAt
        case correctCount
        case wrongCount
        case mastery
        case lastPracticedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.english = try container.decode(String.self, forKey: .english)
        self.czech = try container.decodeIfPresent(String.self, forKey: .czech) ?? ""
        self.sourceTitle = try container.decodeIfPresent(String.self, forKey: .sourceTitle) ?? "Import slovíček"
        self.languageCode = try container.decodeIfPresent(String.self, forKey: .languageCode) ?? LearningLanguage.english.rawValue
        self.importedAt = try container.decodeIfPresent(Date.self, forKey: .importedAt) ?? Date()
        self.correctCount = try container.decodeIfPresent(Int.self, forKey: .correctCount) ?? 0
        self.wrongCount = try container.decodeIfPresent(Int.self, forKey: .wrongCount) ?? 0
        self.mastery = try container.decodeIfPresent(Int.self, forKey: .mastery) ?? 0
        self.lastPracticedAt = try container.decodeIfPresent(Date.self, forKey: .lastPracticedAt)
    }

    var displayEnglish: String {
        english.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    }

    var displayCzech: String {
        czech.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var needsTranslation: Bool {
        displayCzech.isEmpty
    }

    var language: LearningLanguage {
        LearningLanguage(rawValue: languageCode) ?? .english
    }
}
