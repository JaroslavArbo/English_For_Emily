EnglishForEmily complete project v19 patch

Opravy:
- WordStore.cleanEnglish je nově nonisolated static func, takže PDFWordExtractor.swift už nespadne na chybě:
  Call to main actor-isolated static method 'cleanEnglish' in a synchronous nonisolated context.
- Z AppIcon.appiconset byl odstraněn nepoužitý icon-1024.png, aby Xcode nehlásil:
  The app icon set "AppIcon" has an unassigned child.

Poznámka:
- Warning ve SpeechHelper.swift o AVSpeechSynthesizer / Sendable je jen warning v novém Swiftu, build neblokuje.
