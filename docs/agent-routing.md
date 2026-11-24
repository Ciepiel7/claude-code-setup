# scripts/agent-routing.sh

## fn
main(stdin JSON) -> PreToolUse/Agent: bramka Explore + log spawnu + systemMessage inline
--report -> liczniki per model/agent + ostatnie 20 wpisow

## vars
const LOG:path=~/.claude/agent-routing.log -> TSV: czas, projekt, agent, model, opis, zrodlo
const PY -> python3 lub python (fallback Windows)
zrodlo modelu: explicit (tool_input.model) > frontmatter (.claude/agents, ~/.claude/agents) > default=inherit

## fx
- tool_name != Agent -> cichy exit 0, brak outputu
- brak subagent_type -> general-purpose
- `inherit` = model sesji = frontier; poprawne dla Plan/general-purpose (nie blad)
- Explore z modelem spoza {haiku, sonnet} (w tym inherit/opus/fable) -> hookSpecificOutput permissionDecision=deny, bez wpisu w logu
- bledy pythona wyciszone (2>/dev/null); poza bramka Explore hook nigdy nie blokuje spawnu
- efekt uboczny: spawn `scout`/`Explore` kasuje `~/.claude/.read-gate/<session_id>` (nowe rozpoznanie = nowe zadanie); blad kasowania ignorowany

## test
echo '{"tool_name":"Agent","tool_input":{"subagent_type":"Explore"}}' | bash scripts/agent-routing.sh -> deny
echo '{"tool_name":"Agent","tool_input":{"subagent_type":"Plan"}}' | bash scripts/agent-routing.sh -> systemMessage [inherit]

## deps
< settings.json (hooks.PreToolUse matcher Agent)
< CLAUDE.md (## Model Routing)
> ~/.claude/agents/*.md (frontmatter model); agents/scout.md zastepuje Explore
> scripts/read-gate.sh (wspoldziela plik stanu ~/.claude/.read-gate/<session_id>)
