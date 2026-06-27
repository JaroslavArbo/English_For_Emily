EnglishForEmily complete project – version 2.0

Připraveno pro publikaci:
- Marketing Version: 2.0
- Build Number: 27
- Minimum Deployment Target: iOS 15.0
- Bundle Identifier ponechán: cz.jarek.englishforemily
- Základních 30 anglických a 30 španělských slovíček je součástí instalace.

Postup v Xcode:
1. Otevři EnglishForEmily.xcodeproj.
2. Zkontroluj:
   TARGETS → EnglishForEmily → Signing & Capabilities
   Team: tvoje Apple ID / vývojářský tým
   Bundle Identifier: cz.jarek.englishforemily
3. V horní liště vyber: Any iOS Device (arm64).
4. Product → Clean Build Folder.
5. Product → Archive.
6. V Organizeru zvol Distribute App.
7. App Store Connect → Upload.
8. Po uploadu čekej na zpracování v App Store Connect / TestFlight.

Poznámka:
Build number musí být při každém dalším uploadu vyšší. Pokud budeš upload opakovat,
zvedni Build například na 28.
