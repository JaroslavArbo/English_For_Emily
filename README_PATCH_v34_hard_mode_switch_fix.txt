EnglishForEmily complete project – v34 hard mode switch fix

Oprava přepínání režimů ve Start Game:
- Dlaždice režimů už nejsou Button, ale čisté tapnutelné plochy.
- Přidán highPriorityGesture + onTapGesture.
- Celý přepínač má vyšší zIndex, aby jej nepřekrývala jiná UI vrstva.
- Přidán text „Aktivní režim“, aby bylo okamžitě vidět, že se režim přepnul.
- Při změně režimu se zastaví rozpoznávání řeči, zavře se klávesnice, vyčistí odpověď a načte nová otázka.
- Marketing Version: 2.0
- Build Number: 34
