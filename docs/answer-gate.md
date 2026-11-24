# scripts/answer-gate.sh

## fn
main(stdin JSON) -> UserPromptSubmit: regex na prompt, przy trafieniu wypisuje przypomnienie o zrodle w kodzie

## vars
const STRONG -> regex: "jak dziala", "co robi", "skad wie", "where is .* handled" itd (PL + EN)
const WEAK -> "dlaczego|czemu|why|how does|what does"; liczy sie tylko razem z CODE
const CODE -> slowa o kodzie (funkcj, plik, klas, hook, script, query...)
fn trigger -> STRONG or (WEAK and CODE)

## fx
- brak/pusty prompt -> cichy exit 0
- brak trafienia regex -> cichy exit 0
- trafienie -> 3-liniowy [answer-gate] output na stdout (trafia do kontekstu sesji)
- NIGDY nie blokuje: zawsze exit 0, nigdy nie przerywa promptu
- blad JSON/brak python3 -> cichy exit 0

## test
echo '{"prompt":"jak dziala bramka czytania?"}' | bash scripts/answer-gate.sh -> 3 linie [answer-gate]
echo '{"prompt":"dodaj przycisk do headera"}' | bash scripts/answer-gate.sh -> cicho
echo 'nie-json' | bash scripts/answer-gate.sh; echo $? -> cicho, rc=0

## deps
< settings.json (hooks.UserPromptSubmit)
< CLAUDE.md (## Odpowiedzi o dzialaniu kodu)
