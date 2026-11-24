# wiki-template/wiki/update_hot.py

Regeneruje `wiki/hot.md` ("stan biezacy") z log.md, ledger i frontmatter stron. Stdlib only. Odpalany przez hook Stop.

## fn
fn read(p) -> tekst pliku lub "" (brak pliku = pusto, nie blad)
fn main() -> buduje hot.md: Stan, ostatnie N_LOG wpisow, blok Next Actions

## vars
const WIKI:Path=dirname(__file__) -> katalog wiki/
const N_LOG:int=8 -> ile ostatnich wpisow log.md pokazac
const NA_START/NA_END:str -> markery HTML bloku Next Actions (zachowywany miedzy regeneracjami)
const DEFAULT_NA:str="- (uzupelnij)" -> gdy blok pusty

## fx
- Stan: data ostatniego wpisu, liczba wpisow, strony `status: active` (regex na 500 znakach frontmatter), liczba wierszy ledger - 2, liczba .md per folder
- Next Actions: regex miedzy markerami ze starego hot.md -> wklejany bez zmian
- kazdy wyjatek -> stderr + exit 0 (hook nigdy nie blokuje sesji)

## deps
< wiki/log.md, wiki/Failed Ideas/ledger.md, wiki/**/*.md
> wiki/hot.md
