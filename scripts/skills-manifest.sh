#!/bin/bash
# skills-manifest.sh — zapisuje skills.txt (root repo): <nazwa>\t<zrodlo> dla kazdego wpisu w ~/.claude/skills.
# Zrodlo: .skill-lock.json (npx skills) | plugin:<sciezka> (symlink do ~/.claude/plugins) | repo (jest w skills/) | local.
# Po co: nowa maszyna widzi, ktore skille brakuja i skad je wziac (install.sh drukuje `npx skills add <zrodlo>`).

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SKILLS_DIR="$HOME/.claude/skills"
LOCK="$HOME/.agents/.skill-lock.json"
PY=python3; command -v python3 >/dev/null 2>&1 || PY=python

[ -d "$SKILLS_DIR" ] || { echo "skills-manifest: brak $SKILLS_DIR" >&2; exit 1; }

LOCK="$LOCK" SKILLS_DIR="$SKILLS_DIR" REPO_SKILLS="$REPO_DIR/skills" $PY - > "$REPO_DIR/skills.txt" <<'PY'
import json, os

lock = {}
try:
    with open(os.environ["LOCK"], encoding="utf-8") as f:
        lock = json.load(f).get("skills", {})
except Exception:
    pass

# skille spoza lock-file npx skills, ze znanym zrodlem
KNOWN = {"browser-harness": "browser-use/browser-harness"}

root, repo = os.environ["SKILLS_DIR"], os.environ["REPO_SKILLS"]
rows = []
for name in os.listdir(root):
    if name.startswith("."):
        continue
    p = os.path.join(root, name)
    src = (lock.get(name) or {}).get("source") or KNOWN.get(name)
    if not src:
        target = os.path.realpath(p) if os.path.islink(p) else ""
        if "/.claude/plugins/" in target.replace("\\", "/"):
            src = "plugin:" + target
        elif os.path.isdir(os.path.join(repo, name)):
            src = "repo"
        else:
            src = "local"
    rows.append((name, src))
for name, src in sorted(rows):
    print(f"{name}\t{src}")
PY
echo "skills-manifest: $(wc -l < "$REPO_DIR/skills.txt" | tr -d ' ') skilli -> $REPO_DIR/skills.txt"
