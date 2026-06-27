EnglishForEmily complete project – v35 practice layout and mode switch fix

Opravy:
- Start Game je nově ve ScrollView, takže se nedeformuje v portrait režimu.
- Obsah už není vertikálně centrovaný přes celou obrazovku; začíná nahoře a dá se scrollovat.
- Přepínače režimů jsou standardní SwiftUI Button dlaždice.
- Při přepnutí režimu se natvrdo zavře klávesnice/focus přes UIApplication resignFirstResponder.
- Zůstává text „Aktivní režim“, aby bylo okamžitě vidět, že se přepnutí povedlo.
- Režimy:
  - 👂 Slyším a píšu
  - 🧩 Česky → anglicky / Česky - Španělsky
  - 🎤 Řekni anglicky / Řekni to španělsky
- Marketing Version: 2.0
- Build Number: 35
