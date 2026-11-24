# scripts/read-gate.sh

## fn
main(stdin JSON) -> PreToolUse/Read|Bash: liczy ROZNE pliki w sesji, przy progu systemMessage o scoucie
--reset -> kasuje caly katalog licznikow

## vars
const STATE_DIR:path=~/.claude/.read-gate -> plik na sesje, jedna sciezka na linie
const WARN_AT:tuple=(3, 8) -> prog pierwszy (przypomnienie) i drugi (sesja zignorowala pierwszy)
const PY -> python3 lub python (fallback Windows)
klucz stanu: session_id z hooka, oczyszczony do [A-Za-z0-9_-], fallback "default"

## fx
- tool_name inny niz Read/Bash -> cichy exit 0; brak file_path (Read) lub plikow (Bash) -> cichy exit 0
- Bash: liczy tez cat/head/tail/less/bat/sed -n/awk PLIK (istniejace pliki; wzgledne wzgl. cwd, ~ rozwijane)
- ten sam plik czytany ponownie NIE liczy sie drugi raz (liczone sa rozne sciezki)
- komunikat pada dokladnie raz na prog (gdy licznik OSIAGA 3, potem 8), nie przy kazdym Read
- NIGDY nie blokuje: zawsze exit 0, nigdy permissionDecision=deny — review i debug musza czytac
- blad zapisu stanu (OSError) -> cichy exit 0; licznik to wygoda, nie ma prawa przerwac pracy
- reset licznika robi agent-routing.sh przy spawnie scout/Explore (nowe rozpoznanie = nowe zadanie)

## test
printf '{"session_id":"T","tool_name":"Read","tool_input":{"file_path":"/x/a"}}' | bash scripts/read-gate.sh -> cicho
(powtorz dla /x/b, /x/c) -> przy trzecim systemMessage o scoucie
printf '{"session_id":"T","tool_name":"Bash","tool_input":{"command":"ls"}}' | bash scripts/read-gate.sh -> cicho
bash scripts/read-gate.sh --reset -> czysci licznik

## deps
< settings.json (hooks.PreToolUse matcher Read|Bash)
< CLAUDE.md (## Model Routing — bramka CZYTANIA)
> scripts/agent-routing.sh (zeruje licznik przy scout/Explore)
> docs/koszt-kontekstu.md (dlaczego prog stoi tak nisko)
