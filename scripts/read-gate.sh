#!/bin/bash
# read-gate.sh — PreToolUse hook (matcher: Read|Bash): bramka czytania.
# Liczy ROZNE pliki otwarte przez sesje (Read oraz Bash cat/head/tail/less/bat/sed -n/awk) i po progu przypomina o agencie scout.
# NIGDY nie blokuje (zawsze exit 0) — review i debug z natury wymagaja czytania.
#
# Po co: 89% rachunku to cache, nie pisanie. Kazdy token wciagniety do kontekstu
# glownej sesji jest oplacany srednio ~52 razy (odczyt cache co ture), wiec plik
# przeczytany przez sesje kosztuje wielokrotnie wiecej niz ten sam plik
# przeczytany raz przez scouta na haiku. Szczegoly: docs/koszt-kontekstu.md
#
# Stan: ~/.claude/.read-gate/<session_id> — jedna sciezka na linie.
# Reset robi agent-routing.sh, gdy wystartuje scout albo Explore (nowe rozpoznanie
# = nowe zadanie). Katalog mozna skasowac w kazdej chwili, to tylko licznik.

STATE_DIR="$HOME/.claude/.read-gate"
PY=python3; command -v python3 >/dev/null 2>&1 || PY=python

if [ "$1" = "--reset" ]; then
    rm -rf "$STATE_DIR"
    echo "read-gate: licznik wyczyszczony"
    exit 0
fi

HOOK_INPUT="$(cat || true)" STATE_DIR="$STATE_DIR" $PY - <<'PY' 2>/dev/null
import sys, json, os, re

# Progi: pierwszy przypomina, drugi lapie sesje, ktora go zignorowala.
WARN_AT = (3, 8)

try:
    d = json.loads(os.environ.get("HOOK_INPUT", ""))
except Exception:
    sys.exit(0)
tool = d.get("tool_name")
ti = d.get("tool_input") or {}
paths = []
if tool == "Read":
    if ti.get("file_path"):
        paths = [ti["file_path"]]
elif tool == "Bash":
    # flagi i sciezka nie moga zawierac ; | & — inaczej `head -3; head -20 x` gubi drugi plik
    rx = re.compile(r"\b(?:cat|head|tail|less|bat|sed\s+-n\s+[^\s;|&]+|awk\s+'[^']*')\s+((?:-[^\s;|&]+\s+)*)([^\s;|&]+)")
    for m in rx.finditer(ti.get("command") or ""):
        p = m.group(2).strip("'\")")
        if not p or p[0] in "-<$":
            continue
        p = os.path.expanduser(p)
        if not os.path.isabs(p) and d.get("cwd"):
            p = os.path.join(d["cwd"], p)
        p = os.path.normpath(p)   # ta sama postac co file_path z Read, zeby dedupe dzialal
        if os.path.isfile(p) and p not in paths:
            paths.append(p)
if not paths:
    sys.exit(0)

state_dir = os.environ["STATE_DIR"]
sid = re.sub(r"[^A-Za-z0-9_-]", "", str(d.get("session_id") or "default")) or "default"
state = os.path.join(state_dir, sid)

try:
    os.makedirs(state_dir, exist_ok=True)
    seen = []
    if os.path.isfile(state):
        with open(state, encoding="utf-8") as f:
            seen = [l.strip() for l in f if l.strip()]
    new = [p for p in paths if p not in seen]   # ten sam plik czytany ponownie nie liczy sie drugi raz
    if not new:
        sys.exit(0)
    prev = len(seen)
    seen.extend(new)
    with open(state, "w", encoding="utf-8") as f:
        f.write("\n".join(seen) + "\n")
except OSError:
    sys.exit(0)              # licznik to wygoda, nie ma prawa przerwac pracy

n = len(seen)
if prev < WARN_AT[0] <= n:
    print(json.dumps({"systemMessage":
        f"read-gate: {n} rozne pliki w tym zadaniu. Reszte rozpoznania oddaj agentowi "
        "scout (haiku) — kazdy plik w kontekscie sesji placisz ~52 razy. "
        "Czytaj sam tylko to, co musisz OCENIC."}))
elif prev < WARN_AT[1] <= n:
    print(json.dumps({"systemMessage":
        f"read-gate: juz {n} roznych plikow bez scouta. Jesli to nie jest review "
        "ani debug wymagajacy tresci, to zadanie mialo isc przez petle."}))
PY
exit 0
