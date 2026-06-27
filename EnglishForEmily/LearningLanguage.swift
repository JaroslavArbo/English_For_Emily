import Foundation

enum LearningLanguage: String, CaseIterable, Identifiable, Codable {
    case english = "en"
    case spanish = "es"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .english: return "Angličtina"
        case .spanish: return "Španělština"
        }
    }

    var homeSelectionIconAssetName: String {
        switch self {
        case .english: return "LanguageEnglishIcon"
        case .spanish: return "LanguageSpanishIcon"
        }
    }


    var hearAndTypePrompt: String {
        switch self {
        case .english: return "Poslechni si slovo a napiš ho anglicky"
        case .spanish: return "Poslechni si slovo a napiš ho španělsky"
        }
    }

    var targetLabel: String {
        switch self {
        case .english: return "Anglicky"
        case .spanish: return "Španělsky"
        }
    }

    var targetPrompt: String {
        switch self {
        case .english: return "Jak se anglicky řekne:"
        case .spanish: return "Česky - Španělsky"
        }
    }

    var speakPrompt: String {
        switch self {
        case .english: return "Řekni anglicky:"
        case .spanish: return "Řekni to španělsky"
        }
    }


    var goodJobText: String {
        switch self {
        case .english: return "Good job! 🌟"
        case .spanish: return "¡Muy bien! 🌟"
        }
    }

    var greatJobText: String {
        switch self {
        case .english: return "Good job! Jednorožec odemkl kytičku! 🌸🦄"
        case .spanish: return "¡Excelente! El unicornio desbloqueó una flor. 🌸🦄"
        }
    }

    var goodJobSpeech: String {
        switch self {
        case .english: return "Good job"
        case .spanish: return "Muy bien"
        }
    }

    var greatJobSpeech: String {
        switch self {
        case .english: return "Great job"
        case .spanish: return "Excelente"
        }
    }

    var almostTextPrefix: String {
        switch self {
        case .english: return "Skoro! Správně je:"
        case .spanish: return "¡Casi! Correcto:"
        }
    }

    var speechLocaleIdentifier: String {
        switch self {
        case .english: return "en-US"
        case .spanish: return "es-ES"
        }
    }

    var voiceLanguage: String {
        switch self {
        case .english: return "en-GB"
        case .spanish: return "es-ES"
        }
    }

    var fallbackVoiceLanguage: String {
        switch self {
        case .english: return "en-US"
        case .spanish: return "es-MX"
        }
    }

    var exampleWord: String {
        switch self {
        case .english: return "BUTTERFLY"
        case .spanish: return "MARIPOSA"
        }
    }
}
