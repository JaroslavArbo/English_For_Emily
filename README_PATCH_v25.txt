EnglishForEmily complete project v25

Nové:
- Přidaná sekce „Přehled“ na titulní stranu.
- V Přehledu je graf za posledních 14 dní:
  - kolik slovíček bylo každý den testovaných,
  - kolik hvězdiček bylo každý den získáno.
- Aplikace eviduje denní statistiky při každém vyhodnocení odpovědi.
- Každý den v 18:00 se naplánuje připomínka:
  „Co takhle testovat slovíčka?“
- Pokud ten den už proběhlo testování, připomínka pro daný den se zruší.
- Připomínky používají lokální notifikace iOS. Při prvním spuštění je potřeba povolit oznámení.

Poznámka k iOS:
iOS neumí spustit podmíněnou notifikaci „jen pokud dnes nebylo testováno“ bez toho, aby aplikace průběžně aktualizovala naplánované připomínky. Proto aplikace plánuje jednorázové připomínky dopředu a při testování zruší připomínku pro aktuální den.
