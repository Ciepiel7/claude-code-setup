## vars
const hooks.PostToolUse -> tablica hookow post-tool
const matcher -> "Write|Edit|MultiEdit|Bash" — pliki do sprawdzenia (Bash: sed -i, >, tee)
const command -> "bash ~/.claude/scripts/doc-check.sh"
const timeout -> 10000ms
const autoUpdatesChannel -> "latest"
const statusLine -> bash scripts/statusline.sh (wrapper: node statusline.js, fallback jq)
const env.BU_CDP_URL -> CDP dedykowanego profilu Chrome (port 9333), obie maszyny
const enabledPlugins -> frontend-design, figma, playground, humanizer, watch (stripe=false)
const autoMode -> NIE synchronizowany z repo: uczy sie lokalnie, install.sh --update go zachowuje

## fx
- rejestruje doc-check.sh jako PostToolUse hook w Claude Code
- hook odpala po kazdym Write/Edit/MultiEdit i Bash (cele zapisu)
- PreToolUse/Bash: guard-destructive.sh + guard-untrusted-repo.sh
- PreToolUse/Agent: agent-routing.sh — log spawnow subagentow + inline model
- PreToolUse/Read|Bash: read-gate.sh — bramka czytania (Read + cat/head/sed -n), przypomina o scoucie przy 3 i 8 roznych plikach, nigdy nie blokuje
- PreToolUse/Edit|Write|MultiEdit: write-gate.sh — przypomina o petli scout -> implementer przy drugim pliku, nigdy nie blokuje
- PreToolUse/mcp__claude-in-chrome__.*|mcp__chrome-devtools__.*|.*Claude_Browser.*: browser-gate.sh — blokuje MCP przegladarki (ALLOW_BROWSER_MCP=1 omija)
- UserPromptSubmit: answer-gate.sh — przypomina regule "odpowiedz z kodu" przy pytaniach "jak dziala X", nigdy nie blokuje
- install.sh NIE kopiuje tego pliku na slepo: `hooks` bierze z repo w calosci, `autoMode` i `model` zostaja lokalne (merge, backup .bak)

## deps
> scripts/doc-check.sh
> scripts/guard-destructive.sh
> scripts/agent-routing.sh
> scripts/read-gate.sh
> scripts/write-gate.sh
> scripts/browser-gate.sh
> scripts/answer-gate.sh
< install.sh (merowany do ~/.claude/settings.json)
