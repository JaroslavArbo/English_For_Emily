EnglishForEmily complete project v20

Opravy:
- WordStore už není označený @MainActor, takže Xcode/Swift už nemá důvod hlásit:
  Call to main actor-isolated static method 'cleanEnglish'
- PDFWordExtractor má navíc vlastní lokální cleanEnglish(), takže není závislý na WordStore.cleanEnglish().
- Nepoužitá ikona icon-1024.png je odstraněná z AppIcon.appiconset.

Zůstává potřeba nastavit signing:
TARGETS → EnglishForEmily → Signing & Capabilities → Team → tvoje Apple ID / Personal Team.
