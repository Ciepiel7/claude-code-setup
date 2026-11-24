#!/bin/bash
# browser-gate.sh — PreToolUse hook (matcher: narzedzia MCP przegladarki): blokuje je.
# Cala przegladarka idzie przez `browser-harness` (Bash) na dedykowanym profilu Chrome (BU_CDP_URL).
# Wyjscie awaryjne: ALLOW_BROWSER_MCP=1 w env sesji (ustawia user, gdy sam o to prosi).
# Blad parsowania = przepusc (exit 0). Blokuje tylko jawne dopasowanie (exit 2).

[ "$ALLOW_BROWSER_MCP" = "1" ] && exit 0

PY=python3; command -v python3 >/dev/null 2>&1 || PY=python
INPUT="$(cat || true)"
TOOL="$(printf '%s' "$INPUT" | $PY -c "import sys,json
try:
 print(json.load(sys.stdin).get('tool_name',''))
except Exception:
 pass" 2>/dev/null || true)"

case "$TOOL" in
    mcp__claude-in-chrome__*|mcp__chrome-devtools__*|*Claude_Browser*)
        echo "browser-gate: zablokowano $TOOL. Przegladarka = zawsze skill browser-harness: w Bash uruchom 'browser-harness <<'PY' ... PY' (profil Chrome przez BU_CDP_URL, port 9333). Problemy z polaczeniem: browser-harness --doctor, potem bash ~/.claude/scripts/chrome-claude.sh. Jesli user jawnie chce MCP: uruchamia sesje z ALLOW_BROWSER_MCP=1." >&2
        exit 2
        ;;
esac
exit 0
