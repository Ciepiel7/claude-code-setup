# scripts/wiki-init.sh

Inicjalizuje LLM Wiki (Karpathy) w biezacym repo git. Idempotentny — istniejace pliki SKIP.
Uzycie: `bash ~/.claude/scripts/wiki-init.sh <unit-folder> [unit-type]` np. `features feature`.

## fn
(skrypt liniowy, bez funkcji)
1. kopia `wiki-template/{wiki,.obsidian}` -> repo, bez nadpisywania; `wiki/<UNIT>/.gitkeep`
1b. `.gitattributes`: dokleja `wiki/log.md merge=union` jesli brak (grep -qF, idempotentnie)
2. sed placeholders `{{UNIT}} {{UNIT_TYPE}} {{PROJECT}} {{DATE}}` (xargs -0, bo "Failed Ideas" ma spacje)
3. CLAUDE.md: dokleja `wiki-template/CLAUDE-wiki.md` jesli brak `## Wiki`
4. `.claude/settings.json`: merge hookow SessionStart/Stop przez python (nie duplikuje)
5. `python wiki/update_hot.py` -> hot.md

## vars
const UNIT:str=$1 -> nazwa folderu jednostki pracy (features/experiments/...)
const UNIT_TYPE:str=$2|${UNIT%s} -> wartosc `type:` w frontmatter
const TPL:path=$WIKI_TEMPLATE_DIR|~/.claude/wiki-template|<repo>/wiki-template -> zrodlo szablonu
const PY:path=python3|python -> interpreter do merge JSON i hot.md

## fx
- Windows (cygpath istnieje) -> hooki `powershell -File wiki/hooks/wiki-hook.ps1 start|stop`
- inne OS -> `bash wiki/hooks/wiki-hook.sh start|stop`
- hooki: SessionStart = `git pull --ff-only`; Stop = update_hot + `git add wiki .obsidian` + commit + push; zawsze exit 0
- `merge=union` na log.md -> rownolegle sesje dopisuja wpisy bez konfliktu (log jest append-only)
- nie repo git -> exit 1 z komunikatem (nie robi git init)

## deps
> wiki-template/, skills/llm-wiki/SKILL.md, install.sh (kopiuje do ~/.claude)
