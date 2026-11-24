# scripts/browser-gate.sh

## fn
main(stdin JSON) -> PreToolUse: blokuje MCP przegladarki, exit 2 + komunikat PL na stderr

## vars
env ALLOW_BROWSER_MCP=1 -> wyjscie awaryjne, exit 0 (ustawia user, nie sesja)
const PY -> python3 lub python (fallback Windows)

## fx
- blokuje tool_name: mcp__claude-in-chrome__*, mcp__chrome-devtools__*, *Claude_Browser*
- komunikat kieruje do: browser-harness w Bash, skill browser-harness, BU_CDP_URL
- blad parsowania JSON / inny tool -> exit 0 (blokuje tylko jawne dopasowanie)
- matcher w settings.json zaweza wywolanie, case w skrypcie jest drugim zabezpieczeniem

## test
printf '{"tool_name":"mcp__chrome-devtools__click"}' | bash scripts/browser-gate.sh -> exit 2
printf '{"tool_name":"Bash"}' | bash scripts/browser-gate.sh -> exit 0
printf '{"tool_name":"mcp__chrome-devtools__click"}' | ALLOW_BROWSER_MCP=1 bash scripts/browser-gate.sh -> exit 0

## deps
< settings.json (hooks.PreToolUse matcher mcp__claude-in-chrome__.*|mcp__chrome-devtools__.*|.*Claude_Browser.*)
< CLAUDE.global.md (# Przegladarka: zawsze browser-harness)
> scripts/chrome-claude.sh (wskazany w komunikacie)
