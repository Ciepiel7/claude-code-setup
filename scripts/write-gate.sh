#!/bin/bash
# write-gate.sh — PreToolUse hook (matcher: Edit|Write|MultiEdit): bramka ZAPISU.
# Liczy ROZNE pliki edytowane w sesji; przy drugim przypomina raz o petli scout -> implementer.
# NIGDY nie blokuje (zawsze exit 0). Nie rozpoznaje subagentow (hook ich nie oznacza) — raz na sesje.
#
# Stan: ~/.claude/.read-gate/<session_id>.w (obok licznika read-gate, ten sam katalog).
# Reset przy `read-gate.sh --reset` (kasuje caly katalog). Mozna skasowac w kazdej chwili.

STATE_DIR="$HOME/.claude/.read-gate"
PY=python3; command -v python3 >/dev/null 2>&1 || PY=python

HOOK_INPUT="$(cat || true)" STATE_DIR="$STATE_DIR" $PY - <<'PY' 2>/dev/null
import sys, json, os, re

try:
    d = json.loads(os.environ.get("HOOK_INPUT", ""))
except Exception:
    sys.exit(0)
p = (d.get("tool_input") or {}).get("file_path")
if d.get("tool_name") not in ("Edit", "Write", "MultiEdit") or not p:
    sys.exit(0)
p = os.path.normpath(p)

state_dir = os.environ["STATE_DIR"]
sid = re.sub(r"[^A-Za-z0-9_-]", "", str(d.get("session_id") or "default")) or "default"
state = os.path.join(state_dir, sid + ".w")

try:
    os.makedirs(state_dir, exist_ok=True)
    seen = []
    if os.path.isfile(state):
        with open(state, encoding="utf-8") as f:
            seen = [l.strip() for l in f if l.strip()]
    if p in seen:
        sys.exit(0)
    seen.append(p)
    with open(state, "w", encoding="utf-8") as f:
        f.write("\n".join(seen) + "\n")
except OSError:
    sys.exit(0)

if len(seen) == 2:   # dokladnie raz: drugi rozny plik
    print(json.dumps({"systemMessage":
        "bramka ZAPISU: >1 plik w zadaniu — petla scout -> implementer (CLAUDE.md Model Routing)"}))
PY
exit 0
