#!/bin/bash
# guard-untrusted-repo.sh — PreToolUse/Bash: skanuje zdalne repo (SkillSpector)
# zanim Claude je sklonuje lub zainstaluje.
#
# Progi ustawione na pomiarze 39 zainstalowanych skilli (2026-09-22), nie na oko:
#   BLOKADA  — YARA [malware] albo Prompt Injection/Instruction Override.
#              To dwa ksztalty, ktore w tej probce nie dawaly falszywek.
#   OSTRZEZENIE — reszta HIGH/CRITICAL (m.in. Supply Chain / CVE w lockfile).
#              Komenda idzie dalej normalnym flow uprawnien, wpis laduje w logu.
# Czemu nie blokujemy calej kategorii Prompt Injection: regula "Hidden Instructions"
# zapala sie na KAZDYM komentarzu HTML w przykladzie kodu (6 z 39 skilli, 100%
# falszywek). Blokowanie po kategorii uziemiloby normalne skille.
#
# ponytail: fail-open — blad skanera nie blokuje pracy, tylko wypisuje ostrzezenie.

INPUT="$(cat || true)"
CACHE="${HOME}/.claude/cache/skillspector"
LOG="${HOME}/.claude/skillspector.log"
ALLOWLIST="${HOME}/.claude/skillspector-allow"

# Jeden obiekt dla obu hostow: Cursor czyta `permission`, Claude Code
# `hookSpecificOutput.permissionDecision` — top-level `permission` ignoruje.
# Sciezka allow celowo bez hookSpecificOutput: "allow" w Claude Code omija
# pytanie o zgode dla KAZDEJ komendy. Tu ma tylko przepuscic do normalnego flow.
allow() { echo '{"permission":"allow"}'; exit 0; }
deny() {
    local r="${1//\\/\\\\}"; r="${r//\"/\\\"}"
    echo "{\"permission\":\"deny\",\"user_message\":\"$r\",\"agent_message\":\"$r\",\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\",\"permissionDecision\":\"deny\",\"permissionDecisionReason\":\"$r\"}}"
    echo "$r" >&2
    exit 2
}

command -v skillspector >/dev/null 2>&1 || allow

TOOL="$(printf '%s' "$INPUT" | python3 -c "
import sys,json
try: print(json.load(sys.stdin).get('tool_name',''))
except Exception: pass" 2>/dev/null)"
[ "$TOOL" = "Bash" ] || allow

COMMAND="$(printf '%s' "$INPUT" | python3 -c "
import sys,json
try: print(json.load(sys.stdin).get('tool_input',{}).get('command','').replace(chr(10),' '))
except Exception: pass" 2>/dev/null)"
[ -n "$COMMAND" ] || allow

case "$COMMAND" in
    *"git clone"*|*"pip install git+"*|*"uv tool install"*|*"npx shadcn"*|*"plugin install"*|*"marketplace add"*) ;;
    *) allow ;;
esac

URL="$(printf '%s' "$COMMAND" | grep -oE 'https://(github|gitlab)\.com/[A-Za-z0-9._-]+/[A-Za-z0-9._-]+' | head -1)"
[ -n "$URL" ] || allow

# Swiadomie zaufane repo (jedno URL na linie) — np. skille bezpieczenstwa,
# ktore z definicji zawieraja przyklady atakow.
[ -f "$ALLOWLIST" ] && grep -qxF "$URL" "$ALLOWLIST" && allow

mkdir -p "$CACHE"
KEY="$CACHE/$(printf '%s' "$URL" | tr -c 'A-Za-z0-9' '_').json"
if [ ! -s "$KEY" ]; then
    skillspector scan "$URL" --no-llm --format json --output "$KEY" >/dev/null 2>&1
    [ -s "$KEY" ] || { echo "skillspector: skan $URL nie powiodl sie, przepuszczam" >&2; allow; }
fi

# Zwraca dwie linie: "BLOCK <opis>" i/lub "WARN <opis>". Pusto = czysto.
VERDICT="$(python3 - "$KEY" <<'PY' 2>/dev/null
import sys, json

WARN_CATS = {"Prompt Injection", "Supply Chain", "YARA Match",
             "Privilege Escalation", "Data Exfiltration", "Rogue Agent"}

def blocking(i):
    cat, pat = i.get("category"), str(i.get("pattern") or "")
    if cat == "YARA Match" and "[malware]" in pat:
        return True
    return cat == "Prompt Injection" and pat == "Instruction Override"

try:
    d = json.load(open(sys.argv[1]))
except Exception:
    sys.exit(0)

high = [i for i in d.get("issues") or []
        if str(i.get("severity", "")).upper() in ("HIGH", "CRITICAL")]
score = (d.get("risk_assessment") or {}).get("score", 0)

def render(items):
    return "; ".join(sorted({
        f'{i["category"]}/{(i.get("pattern") or i.get("id"))[:60]}'
        f' @ {(i.get("location") or {}).get("file", "?")}'
        for i in items
    })[:3])

hard = [i for i in high if blocking(i)]
soft = [i for i in high if not blocking(i) and i.get("category") in WARN_CATS]
if hard:
    print(f'BLOCK risk {score}/100 — {len(hard)} trafien — {render(hard)}')
elif soft:
    print(f'WARN risk {score}/100 — {len(soft)} trafien HIGH — {render(soft)}')
PY
)"

printf '%s\t%s\t%s\n' "$(date +%FT%T)" "$URL" "${VERDICT:-ok}" >> "$LOG"

case "$VERDICT" in
    BLOCK*) deny "SkillSpector zablokowal $URL: ${VERDICT#BLOCK }. Raport: $KEY. Przejrzyj recznie; swiadome zaufanie: echo '$URL' >> $ALLOWLIST" ;;
    WARN*)  printf '{"systemMessage":"skillspector %s: %s — raport %s"}\n' \
                "$URL" "$(printf '%s' "${VERDICT#WARN }" | tr -d '"\\')" "$KEY"
            exit 0 ;;
esac
allow
