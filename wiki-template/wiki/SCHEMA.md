---
type: schema
updated: {{DATE}}
---
# SCHEMA — regulamin wiki ({{PROJECT}})

Wiki = pamiec agenta miedzy sesjami. Claude pisze, czlowiek czyta w Obsidianie (vault = root repo).
Zrodlo prawdy = kod / dane / outputy / docs/ w repo. Wiki LINKUJE do nich (`[[../src/plik.py]]`, sciezki), nigdy nie kopiuje tresci jako prawdy.

## Pliki hub (zawsze istnieja)
| Plik | Rola | Kto edytuje |
|---|---|---|
| index.md | katalog, 1 linia/strona, czytany PIERWSZY | Claude, przy kazdej zmianie stron |
| SCHEMA.md | ten regulamin | Claude + czlowiek, rzadko |
| log.md | dziennik append-only | Claude, tylko dopisuje |
| hot.md | stan biezacy, AUTO z log.md | `update_hot.py` (hook Stop). Reka TYLKO blok Next Actions |
| lessons.md | synteza przekrojowa | Claude po kazdej istotnej lekcji |
| Failed Ideas/ledger.md | porzucone pomysly + POWOD | Claude przy kazdym porzuceniu |

## Foldery tresci
| Folder | Co | `type:` |
|---|---|---|
| {{UNIT}}/ | jednostka pracy projektu, 1 strona/sztuka | {{UNIT_TYPE}} |
| concepts/ | slownik: 1 pojecie = 1 strona, zebysmy rozumieli to samo | concept |
| research/ | zingestowane zrodla zewnetrzne (assets/ na obrazki) | research |
| reference/ | routery: TYLKO linki do strony autorytatywnej, zero tresci | reference |

## Nazewnictwo
- Plik = tytul strony, Title Case ze spacjami (`Model Routing.md`), link `[[Model Routing]]`
- Jezyk: polski, terminy techniczne w oryginale, styl notatkowy
- Kazda strona: frontmatter `type`, `updated` (YYYY-MM-DD) + pole statusu wg typu

## Szablony stron

### Wpis w index.md
`- [[Nazwa]] — max 10 slow co to (status)`

### {{UNIT}}/ ({{UNIT_TYPE}})
```
---
type: {{UNIT_TYPE}}
updated: YYYY-MM-DD
status: planned | active | done | abandoned
---
# Nazwa
**Cel:** 1 zdanie.
**Wynik:** 1-2 zdania, liczby jesli sa.
## Pliki
- `sciezka/plik` — rola
## Decyzje
- co i dlaczego
## Powiazania
- [[Pojecie]], [[Inna jednostka]], [[Zrodlo]]
```

### concepts/ (concept)
```
---
type: concept
updated: YYYY-MM-DD
---
# Pojecie
**Definicja:** 1-2 zdania, jak MY to rozumiemy w tym projekcie.
## W projekcie
- gdzie wystepuje: [[{{UNIT_TYPE}}]], `sciezka/w/kodzie`
## Zobacz
- [[...]]
```

### research/ (research)
```
---
type: research
updated: YYYY-MM-DD
source: URL lub sciezka do surowego zrodla
verdict: useful | partial | rejected
---
# Tytul zrodla
**TL;DR:** 3-5 punktow.
## Co bierzemy
- teza -> gdzie zastosowana [[...]]
## Co odrzucamy i dlaczego
## Sprzecznosci z wiki
> [!warning] zrodlo przeczy [[Strona]]: ... (ten sam callout na tamtej stronie)
```

### reference/ (reference)
```
---
type: reference
updated: YYYY-MM-DD
---
# Temat
Router. Zero tresci, tylko linki:
- Autorytatywna strona: [[...]]
- Kod: `sciezka`
- Zrodla: [[...]]
```

### Failed Ideas/ledger.md — wiersz
`| YYYY-MM-DD | Pomysl | Kontekst [[link]] | Dlaczego nie (konkret, liczby) | nie / tak jesli X |`

## Workflow

### Start sesji (przed KAZDA istotna praca)
1. `index.md` -> 2. `Failed Ideas/ledger.md` -> 3. `hot.md` (stan + Next Actions) -> 4. strony istotne dla zadania

### Po ukonczeniu jednostki pracy ({{UNIT_TYPE}})
1. strona w {{UNIT}}/ z szablonu (istnieje -> update `status`, `updated`, Wynik)
2. linia w index.md
3. log.md: `## [DATE] {{UNIT_TYPE}} | nazwa | wynik`
4. nowe pojecie -> concepts/; nowa lekcja -> lessons.md
5. porzucone -> wiersz w Failed Ideas + `status: abandoned`

### Ingest zrodla (artykul, paper, transkrypt, notatka, wynik researchu)
1. przeczytaj calosc; surowe zrodlo zostaje gdzie jest (URL / research/assets/) — nie kopiuj
2. research/<Tytul>.md z szablonu + verdict
3. zaktualizuj strony, ktorych dotyczy (concepts, {{UNIT}}, lessons) — 1 zrodlo tyka 5-15 stron, to normalne
4. sprzecznosc ze stara wiedza -> callout `> [!warning]` na OBU stronach, starej nie kasuj
5. index.md + log.md: `ingest | tytul | verdict`

### Query ("co wiemy o X")
1. index.md -> strony -> odpowiedz z linkami [[...]]
2. odpowiedz wartosciowa (porownanie, analiza, decyzja) -> strona (reference/ lub {{UNIT}}/) + index + log: `query | pytanie | strona`

### Koniec sesji (przed zakonczeniem)
1. strony dotkniete w sesji maja swieze `updated`
2. log.md dopisany (`session | co robiono | stan`)
3. Next Actions w hot.md zaktualizowane (jedyny blok hot.md edytowany reka)
4. hook Stop: regeneruje hot.md, commituje `wiki/` + `.obsidian/`, push (best-effort)

### Konflikt na wiki przy merge'u (rownolegle sesje)
Hook Stop pushuje `wiki/` z kazdej sesji, wiec przy kilku sesjach naraz kolizja na `log.md` i `hot.md` jest **pewna, nie przypadkowa**. Rozwiazanie jest mechaniczne:

| Plik | Jak rozwiazac | Dlaczego tak |
|---|---|---|
| `wiki/log.md` | **samo sie sklada** — `.gitattributes` ma `merge=union` (wstawia `wiki-init.sh`) | append-only, wpisy unikalne, starych nie edytujemy |
| `wiki/hot.md` | `git checkout --theirs wiki/hot.md && python3 wiki/update_hot.py` | plik generowany; blok Next Actions i tak przezywa regeneracje |
| strony tresci | recznie, normalnie | to prawdziwa tresc, nie ma skrotu |

Nigdy nie rozwiazuj `log.md` wybierajac jedna strone — to kasuje wpis drugiej sesji bez sladu.

## Lint (co ~10 wpisow w log lub na "lint wiki")
- **Sieroty:** strona bez linku przychodzacego -> podlinkuj z index/reference lub usun
  `grep -rhoE "\[\[[^]|#]+" wiki | sed 's/\[\[//' | sort -u` vs `find wiki -name '*.md'`
- **Stale:** `updated` starsze niz nowsze zrodlo/{{UNIT_TYPE}} na ten sam temat -> odswiez lub oznacz `superseded_by: [[...]]`
- **Sprzecznosci:** dwie strony twierdza co innego -> callout na obu + rozstrzygniecie w lessons.md
- **Brak pojecia:** termin na >=3 stronach bez strony w concepts/ -> stworz
- **Failed Ideas:** kazdy `status: abandoned` ma wiersz w ledger; kazdy wiersz ma powod
- **Luki:** czego nie wiemy, a powinnismy -> lista pytan + proponowane zrodla (web)
- Wynik -> log.md: `lint | N sierot, M stale, K sprzecznosci | co naprawiono`
