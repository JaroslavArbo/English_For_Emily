EnglishForEmily – kompletní Xcode projekt

Co je uvnitř:
- EnglishForEmily.xcodeproj – otevři v Xcode
- EnglishForEmily/ – všechny Swift soubory, Info.plist a Assets.xcassets
- SpanishImport/ – JSON se španělskými slovíčky z JAREK español.pdf + CSV pro kontrolu

Doporučené použití:
1. Rozbal ZIP do /Users/kolarik/Englsh nebo kamkoli chceš.
2. Otevři EnglishForEmily.xcodeproj.
3. V Xcode nastav:
   TARGETS → EnglishForEmily → Signing & Capabilities → Team: tvoje Apple ID / Personal Team
4. Minimum deployment je nastavené na iOS 15.0.
5. Vyber iPad/iPhone a dej Cmd+B, potom Cmd+R.

Import španělských slovíček:
1. Spusť aplikaci.
2. Na titulní straně zvol Španělština.
3. Dej Import slovíček.
4. Vyber soubor:
   SpanishImport/EnglishForEmily_spanish_words_from_JAREK_espanol.json

Kdyby Xcode hlásil signing error:
- změň Bundle Identifier třeba na cz.jarek.englishforemily2
- zapni Automatically manage signing
