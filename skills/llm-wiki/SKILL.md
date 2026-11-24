---
name: llm-wiki
description: LLM Wiki (wzorzec Karpathy'ego) w Obsidianie dla kazdego projektu — pamiec agenta miedzy sesjami w wiki/. Uzyj gdy w projekcie brak wiki/ a zaczyna sie istotna praca, albo na hasla "wiki", "ingest", "wrzuc do wiki", "co wiemy o X", "lint wiki", "zainicjuj wiki".
---
# LLM Wiki

Wiki = trwala, kompilowana wiedza w `wiki/` repo. Claude pisze i utrzymuje, wlasciciel czyta w Obsidianie (vault = ROOT repo).
`docs/` = KOD (Doc-Index, co robi plik). `wiki/` = WIEDZA (domena, decyzje, zrodla, lekcje, slepe uliczki). Nie duplikuj — wiki linkuje do docs/ i kodu.

## Brak wiki/ -> init
1. **Zbadaj repo**: jezyk, cel, domena, istniejace docs, `git status`. Nie repo -> powiedz i zaproponuj `git init` (nie rob sam).
2. **Wybierz jednostke pracy** i nazwe folderu: research -> `experiments`, apka -> `features`, pisanie -> `drafts`, trading -> `strategies`, sklep -> `changes`. Nie zadawaj pytan — wybierz i POWIEDZ, co wybrales.
3. `bash ~/.claude/scripts/wiki-init.sh <folder> [typ]` — tworzy: hub (index, SCHEMA, log, hot, lessons, Failed Ideas/ledger), foldery (`<folder>/`, concepts, research, reference), `## Wiki` w CLAUDE.md, hooki w `.claude/settings.json` (PowerShell na Windows / bash), `.obsidian/graph.json` + `app.json`, generuje hot.md.
4. **Projekt ma juz wiedze** (CLAUDE.md, docs/, stary vault, README)? Pierwszy ingest od razu: strony w concepts/ i `<folder>/`, reference/ z linkami do starych miejsc, wpis w log.
5. **Powiedz uzytkownikowi**: zainstaluj Obsidian, "Open folder as vault" -> ROOT repo (nie `wiki/`), bo wikilinki do plikow projektu musza sie rozwiazywac, a `.obsidian/` ma byc w repo. graph.json edytowac tylko przy zamknietym Obsidianie.
6. Podsumowanie 5 linii + "nawyk: zaden, pracuj normalnie, ja utrzymuje wiki".

## Jest wiki/ -> stosuj `wiki/SCHEMA.md`
- **Start** (przed istotna praca): `index.md` -> `Failed Ideas/ledger.md` -> `hot.md` -> strony do zadania.
- **Koniec**: dotkniete strony `updated`, `log.md` dopisany, Next Actions w hot.md. Hook Stop robi hot.md + commit + push.
- **ingest / query / lint / po jednostce pracy**: procedury krok po kroku w SCHEMA.md. Zrodlo tyka 5-15 stron — normalne.
- Sprzecznosc = callout na OBU stronach, starej nie kasuj. Porzucenie = wiersz w ledger Z POWODEM.
- Wartosciowa odpowiedz (porownanie, analiza, decyzja) -> strona w wiki, nie tylko chat.

## Uwagi
- Hook Stop commituje TYLKO `wiki/` i `.obsidian/` (nie `git add -A` — inne sesje moga miec brudne pliki). Na `main` z branch protection push odpada cicho; wiki wchodzi wtedy przez PR.
- Stare vaulty (np. `projekt-a/vault`): nie przenos hurtem. wiki-init + reference/ z linkami do starych stron; migracja strona po stronie przy okazji.
