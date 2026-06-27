EnglishForEmily complete project – v31 practice mode switch fix

Oprava:
- Na stránce Start Game šlo špatně přepínat mezi ikonami/režimy.
- Ikonové režimy už nejsou řešené jako Button uvnitř vlastního labelu.
- Nově jsou to celé tapnutelné dlaždice přes contentShape + onTapGesture.
- Přepnutí režimu explicitně zavře klávesnici, nastaví nový režim, obnoví balíček slov a připraví otázku.
- Režimy zůstávají:
  - 👂 Slyším a píšu
  - 🧩 Česky → anglicky / Česky - Španělsky
  - 🎤 Řekni anglicky / Řekni to španělsky
- Marketing Version: 2.0
- Build Number: 31
