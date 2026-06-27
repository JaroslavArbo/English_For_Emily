EnglishForEmily complete project – v32 mode hit-test fix

Oprava:
- Režimy ve Start Game jsou znovu skutečné SwiftUI Button prvky, ale s borderless stylem.
- Celá dlaždice má explicitní contentShape s RoundedRectangle.
- To řeší problém, kdy tapnutí na ikonové dlaždice na iPadu nereagovalo.
- Přepnutí režimu také zastaví rozpoznávání řeči, zavře klávesnici, obnoví balíček slov a připraví otázku.
- Marketing Version: 2.0
- Build Number: 32
