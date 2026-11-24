#!/bin/bash
# guard-destructive.sh — PreToolUse / beforeShellExecution guard
# Jeden obiekt JSON dla obu hostow: Cursor czyta `permission`, Claude Code
# `hookSpecificOutput.permissionDecision` — top-level `permission` ignoruje,
# wiec bez tego bloku blokada dziala, ale powod nie dociera do modelu.

INPUT="$(cat || true)"

# Sciezka allow celowo NIE zwraca hookSpecificOutput: "allow" w Claude Code
# omija pytanie o zgode dla KAZDEJ komendy. Cursor czyta `permission`,
# Claude Code ma po prostu przepuscic dalej do normalnego flow uprawnien.
json_allow() {
    echo '{"permission":"allow"}'
    exit 0
}

json_deny() {
    local reason="$1"
    local escaped="${reason//\\/\\\\}"
    escaped="${escaped//\"/\\\"}"
    echo "{\"permission\":\"deny\",\"user_message\":\"$escaped\",\"agent_message\":\"$escaped\",\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\",\"permissionDecision\":\"deny\",\"permissionDecisionReason\":\"$escaped\"}}"
    echo "$escaped" >&2
    exit 2
}

TOOL_NAME=""
COMMAND=""

if command -v python3 >/dev/null 2>&1; then
    TOOL_NAME="$(printf '%s' "$INPUT" | python3 -c "import sys,json
try:
 d=json.load(sys.stdin); print(d.get('tool_name',''))
except: pass" 2>/dev/null || true)"
    COMMAND="$(printf '%s' "$INPUT" | python3 -c "import sys,json
try:
 d=json.load(sys.stdin); print(d.get('tool_input',{}).get('command',''))
except: pass" 2>/dev/null || true)"
elif command -v python >/dev/null 2>&1; then
    TOOL_NAME="$(printf '%s' "$INPUT" | python -c "import sys,json
try:
 d=json.load(sys.stdin); print(d.get('tool_name',''))
except: pass" 2>/dev/null || true)"
    COMMAND="$(printf '%s' "$INPUT" | python -c "import sys,json
try:
 d=json.load(sys.stdin); print(d.get('tool_input',{}).get('command',''))
except: pass" 2>/dev/null || true)"
fi

case "$TOOL_NAME" in
    Bash|Shell) ;;
    *) json_allow ;;
esac

[ -z "$COMMAND" ] && json_allow

CMD_LOWER="$(printf '%s' "$COMMAND" | tr '[:upper:]' '[:lower:]')"

# Przegladarka wlasciciela jest nietykalna (CLAUDE.md "Twarde zakazy"); dedykowany profil .chrome-claude wolno
case "$CMD_LOWER" in
    *".chrome-claude"*) ;;
    *killall*chrome*|*pkill*chrome*|*taskkill*chrome.exe*|*osascript*quit*chrome*|*osascript*chrome*quit*)
        json_deny "BLOCKED: zamykanie przegladarki uzytkownika (CLAUDE.md, Twarde zakazy). Automatyzacja tylko na profilu .chrome-claude: bash ~/.claude/scripts/chrome-claude.sh" ;;
esac

case "$CMD_LOWER" in
    *"git push --force"*|*"git push -f "*) json_deny "BLOCKED: git force push" ;;
    *"git reset --hard"*) json_deny "BLOCKED: git reset --hard" ;;
    *"git clean -fd"*|*"git clean -f"*) json_deny "BLOCKED: git clean" ;;
    *"git checkout -- ."*) json_deny "BLOCKED: git checkout -- ." ;;
    *"drop table"*|*"drop database"*) json_deny "BLOCKED: SQL drop" ;;
    *"truncate "*) json_deny "BLOCKED: SQL truncate" ;;
    *"rm -rf /"*|*"rm -rf ~"*|*"rm -rf \$home"*) json_deny "BLOCKED: rm -rf" ;;
    *"mkfs"*|*"dd if="*) json_deny "BLOCKED: disk wipe command" ;;
    *"chmod -r 777"*|*"chmod 777 /"*) json_deny "BLOCKED: chmod" ;;
esac

json_allow
