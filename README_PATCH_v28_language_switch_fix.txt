EnglishForEmily complete project – v28 language switch fix

Úprava:
- Na titulní stránce je původní iOS segmented Picker nahrazen dvěma velkými tlačítky:
  - Angličtina 🇬🇧
  - Španělština 🇪🇸
- Přepnutí jazyka se provádí přímo nastavením store.selectedLanguage.
- U každého jazyka se zobrazuje počet dostupných slovíček.
- Vybraný jazyk je graficky zvýrazněný.
- Build Number: 28
- Marketing Version: 2.0

Poznámka:
Tahle změna obchází problém, kdy segmented Picker na titulní straně na některých iOS verzích
nepůsobil spolehlivě nebo nebylo zřejmé, že se jazyk opravdu přepnul.
