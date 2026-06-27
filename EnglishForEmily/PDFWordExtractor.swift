import Foundation
import PDFKit

struct PDFWordExtractor {
    static func extractWords(from url: URL) -> [String] {
        // iOS 15 can be fussy with security-scoped URLs from Files/iCloud.
        // First try the URL directly; if that fails, read/copy the data and create the PDF from Data.
        if let document = PDFDocument(url: url) {
            let text = extractText(from: document)
            let words = extractLikelyVocabulary(from: text)
            if !words.isEmpty { return words }
        }

        if let data = try? Data(contentsOf: url),
           let document = PDFDocument(data: data) {
            let text = extractText(from: document)
            return extractLikelyVocabulary(from: text)
        }

        return []
    }

    private static func extractText(from document: PDFDocument) -> String {
        var raw = ""

        for index in 0..<document.pageCount {
            if let page = document.page(at: index), let text = page.string {
                raw += "\n" + text
            }
        }

        return raw
    }

    static func extractLikelyVocabulary(from text: String) -> [String] {
        let blocked = blockedWords()

        let normalizedText = text
            .replacingOccurrences(of: "’", with: "'")
            .replacingOccurrences(of: "‘", with: "'")
            .replacingOccurrences(of: "“", with: "\"")
            .replacingOccurrences(of: "”", with: "\"")
            .replacingOccurrences(of: "\u{00a0}", with: " ")

        let lines = normalizedText
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        var candidates: [String] = []

        // Words that already appear as part of a detected multi-word term.
        // This prevents "dining room" from also being imported as "DINING" and "ROOM".
        var tokensInsidePhrases = Set<String>()

        // 1) Line-aware pass: good for vocabulary PDFs where each word/phrase is listed on a line.
        for line in lines {
            let cleanedLine = stripLineNoise(line)
            if cleanedLine.isEmpty { continue }

            let parts = splitVocabularyLine(cleanedLine)

            for part in parts {
                if let candidate = cleanCandidate(part, blocked: blocked) {
                    candidates.append(candidate)

                    let pieces = candidate.split(separator: " ").map(String.init)
                    if pieces.count > 1 {
                        for piece in pieces {
                            tokensInsidePhrases.insert(piece)
                        }
                    }
                }
            }
        }

        // 2) Token pass: catches table-like PDFs where PDFKit merges many cells into a single line.
        // Do not add single tokens that were already part of a multi-word phrase.
        let tokenSeparators = CharacterSet(charactersIn: " \n\t\r,;:|/\\()[]{}<>\"„“”!?+=*_•●◆◇■□")
        let tokens = normalizedText
            .components(separatedBy: tokenSeparators)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        for token in tokens {
            if let candidate = cleanCandidate(token, blocked: blocked, allowShortSingleWord: true) {
                if tokensInsidePhrases.contains(candidate) {
                    continue
                }
                candidates.append(candidate)
            }
        }

        var unique: [String] = []
        var seen = Set<String>()

        for item in candidates {
            let key = item
                .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "en_US"))
                .lowercased()

            if !seen.contains(key) {
                unique.append(item)
                seen.insert(key)
            }
        }

        return unique
    }

    private static func splitVocabularyLine(_ line: String) -> [String] {
        // Split on separators that usually separate vocabulary items, but do not split normal phrases like "ice cream".
        let separators = CharacterSet(charactersIn: ",;|/\\•●◆◇■□")
        var parts = line.components(separatedBy: separators)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        if parts.count == 1 {
            let words = line
                .split(separator: " ")
                .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }

            // Keep two- and three-word terms together, e.g. "dining room".
            if words.count <= 3 {
                return [line]
            }

            // If a PDF table exported as one long line, try to preserve known classroom compounds.
            parts = splitKnownCompoundsAndSingles(words)
        }

        return parts
    }

    private static func splitKnownCompoundsAndSingles(_ words: [String]) -> [String] {
        let compounds = knownMultiWordTerms()
        var result: [String] = []
        var index = 0

        while index < words.count {
            let word = words[index]

            if index + 2 < words.count {
                let three = cleanEnglish("\(word) \(words[index + 1]) \(words[index + 2])")
                if compounds.contains(three) {
                    result.append("\(word) \(words[index + 1]) \(words[index + 2])")
                    index += 3
                    continue
                }
            }

            if index + 1 < words.count {
                let two = cleanEnglish("\(word) \(words[index + 1])")
                if compounds.contains(two) {
                    result.append("\(word) \(words[index + 1])")
                    index += 2
                    continue
                }
            }

            result.append(word)
            index += 1
        }

        return result
    }

    private static func stripLineNoise(_ line: String) -> String {
        var result = line.trimmingCharacters(in: .whitespacesAndNewlines)

        // Remove numbering and bullets: "1. apple", "12) banana", "- orange".
        let patterns = [
            #"^\s*[0-9]+[\.\)]\s*"#,
            #"^\s*[A-Za-z][\.\)]\s*"#,
            #"^\s*[-–—]\s*"#
        ]

        for pattern in patterns {
            result = result.replacingOccurrences(
                of: pattern,
                with: "",
                options: .regularExpression
            )
        }

        // Remove common worksheet blanks.
        result = result.replacingOccurrences(of: "_", with: " ")
        result = result.replacingOccurrences(of: #" {2,}"#, with: " ", options: .regularExpression)

        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func cleanCandidate(_ raw: String, blocked: Set<String>, allowShortSingleWord: Bool = false) -> String? {
        var value = stripLineNoise(raw)
        value = value.trimmingCharacters(in: CharacterSet(charactersIn: " .,:;!?\"'()[]{}<>"))

        guard !value.isEmpty else { return nil }
        guard value.count >= 2 && value.count <= 32 else { return nil }
        if value.rangeOfCharacter(from: .decimalDigits) != nil { return nil }

        let allowed = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz '’.-")
        if value.rangeOfCharacter(from: allowed.inverted) != nil { return nil }

        // Avoid sentences/instructions.
        let pieces = value.split(separator: " ").map(String.init)
        guard pieces.count <= 3 else { return nil }

        let upper = cleanEnglish(value)

        if blocked.contains(upper) { return nil }
        if upper.contains("TWINKL") { return nil }
        if upper.contains("WWW") { return nil }
        if upper.contains("@") { return nil }

        // Single-letter tokens and very short worksheet leftovers are usually noise.
        if pieces.count == 1 {
            if upper.count == 1 { return nil }
            if !allowShortSingleWord && upper.count < 3 { return nil }
        }

        // Reject if every part is a blocked word.
        let wordParts = upper.split(separator: " ").map(String.init)
        if !wordParts.isEmpty && wordParts.allSatisfy({ blocked.contains($0) }) {
            return nil
        }

        return upper
    }

    private static func knownMultiWordTerms() -> Set<String> {
        return [
            // home / rooms
            "DINING ROOM", "LIVING ROOM", "BEDROOM", "BATHROOM", "KITCHEN SINK",
            "FRONT DOOR", "BACK DOOR", "BUNK BED", "COFFEE TABLE", "TV ROOM",

            // school / classroom
            "PENCIL CASE", "SCHOOL BAG", "WHITE BOARD", "BLACK BOARD", "CLASS ROOM",
            "DINING HALL", "SPORTS HALL", "PLAY GROUND",

            // common food / phrases
            "ICE CREAM", "HOT DOG", "FISH AND CHIPS", "ORANGE JUICE", "APPLE JUICE",
            "MINERAL WATER", "CHOCOLATE CAKE", "BIRTHDAY CAKE",

            // places / everyday
            "BUS STOP", "TRAIN STATION", "POLICE STATION", "POST OFFICE",
            "SHOPPING CENTRE", "SWIMMING POOL", "PET SHOP", "TOY SHOP",

            // animals / objects
            "GUINEA PIG", "TEDDY BEAR", "BOARD GAME", "COMPUTER GAME",

            // time / weather
            "GOOD MORNING", "GOOD AFTERNOON", "GOOD EVENING", "GOOD NIGHT"
        ]
    }


    private static func cleanEnglish(_ text: String) -> String {
        text
            .replacingOccurrences(of: "’", with: "'")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: #" {2,}"#, with: " ", options: .regularExpression)
            .uppercased()
    }

    private static func blockedWords() -> Set<String> {
        return [
            "A", "AN", "AND", "ARE", "AS", "AT", "BE", "BY", "CAN", "DO", "DOES", "FOR", "FROM", "HAS", "HAVE",
            "HE", "HER", "HIS", "I", "IN", "IS", "IT", "ITS", "ME", "MY", "OF", "ON", "OR", "OUR", "SHE",
            "THE", "THEIR", "THEM", "THERE", "THESE", "THIS", "TO", "WE", "WHAT", "WHEN", "WHERE", "WHO",
            "WITH", "YOU", "YOUR",

            "NAME", "DATE", "CLASS", "SCHOOL", "TEACHER", "PAGE", "UNIT", "LESSON", "HOMEWORK",
            "WORDS", "WORD", "VOCABULARY", "SPELLING", "ENGLISH", "CZECH",

            "MONDAY", "TUESDAY", "WEDNESDAY", "THURSDAY", "FRIDAY", "SATURDAY", "SUNDAY",

            "LOOK", "SAY", "COVER", "WRITE", "CHECK", "READ", "LISTEN", "MATCH", "DRAW", "CIRCLE",
            "COMPLETE", "FILL", "CHOOSE", "ANSWER", "ASK", "TICK", "CROSS", "COPY", "REPEAT",
            "PRACTISE", "PRACTICE", "EXERCISE", "EXERCISES", "ACTIVITY", "ACTIVITIES",

            "KID", "KIDS", "KID'S", "BOX", "PUPIL", "PUPILS", "STUDENT", "STUDENTS",
            "TEST", "QUIZ", "WORKSHEET", "WORKBOOK"
        ]
    }
}
