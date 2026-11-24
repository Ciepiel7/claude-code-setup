# scripts/write-gate.sh

## fn
main(stdin JSON) -> PreToolUse/Edit|Write|MultiEdit: liczy ROZNE pliki w sesji, przy drugim systemMessage o petli scout -> implementer

## vars
const STATE_DIR:path=~/.claude/.read-gate -> wspolny z read-gate, plik <session_id>.w
klucz stanu: session_id oczyszczony do [A-Za-z0-9_-], fallback "default"

## fx
- tool inny niz Edit/Write/MultiEdit lub brak file_path -> cichy exit 0
- ten sam plik edytowany ponownie NIE liczy sie drugi raz
- komunikat dokladnie raz na sesje (gdy licznik osiaga 2)
- NIGDY nie blokuje: zawsze exit 0
- nie rozpoznaje subagentow (hook nie niesie takiej flagi) — raz na sesje
- blad zapisu stanu -> cichy exit 0
- `read-gate.sh --reset` kasuje tez te liczniki (ten sam katalog)

## test
printf '{"session_id":"T","tool_name":"Edit","tool_input":{"file_path":"/x/a"}}' | bash scripts/write-gate.sh -> cicho
(to samo dla /x/b) -> systemMessage "bramka ZAPISU"

## deps
< settings.json (hooks.PreToolUse matcher Edit|Write|MultiEdit)
< CLAUDE.md (## Model Routing — bramka ZAPISU)
< scripts/read-gate.sh (wzorzec stanu)
