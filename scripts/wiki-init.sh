#!/usr/bin/env bash
# wiki-init.sh <unit-folder> [unit-type] — LLM Wiki (Karpathy) w biezacym repo:
#   wiki/ (hub + foldery) + CLAUDE.md "## Wiki" + hooki .claude/settings.json + .obsidian/ + hot.md
# Przyklad: bash ~/.claude/scripts/wiki-init.sh features feature
# Idempotentny: istniejace pliki pomija (SKIP), nic nie nadpisuje.
set -euo pipefail

UNIT="${1:?uzycie: wiki-init.sh <unit-folder> [unit-type]   np. features feature}"
UNIT_TYPE="${2:-${UNIT%s}}"
TPL="${WIKI_TEMPLATE_DIR:-$HOME/.claude/wiki-template}"
[ -d "$TPL" ] || TPL="$(cd "$(dirname "$0")/.." && pwd)/wiki-template"
[ -d "$TPL" ] || { echo "brak szablonu $TPL — uruchom install.sh"; exit 1; }
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "to nie repo git — najpierw: git init"; exit 1; }
ROOT="$(git rev-parse --show-toplevel)"; cd "$ROOT"
PROJECT="$(basename "$ROOT")"; DATE="$(date +%F)"
PY="$(command -v python3 || command -v python)"

# 1. wiki/ + .obsidian/ — kopia szablonu bez nadpisywania
mkdir -p "wiki/$UNIT" .claude
(cd "$TPL" && find wiki .obsidian -type f) | while read -r f; do
  if [ -e "$f" ]; then echo "SKIP $f"; continue; fi
  mkdir -p "$(dirname "$f")"; cp "$TPL/$f" "$f"; echo "OK   $f"
done
touch "wiki/$UNIT/.gitkeep"; chmod +x wiki/hooks/wiki-hook.sh wiki/update_hot.py
# Dwie roznice BSD (macOS) vs GNU, obie wywalaly skrypt TU przez set -e,
# czyli przed CLAUDE.md, hookami i hot.md:
#   1. BSD sed wymaga argumentu przy -i, GNU sed go nie przyjmuje.
#   2. BSD grep IGNORUJE -Z i wypisuje \n zamiast \0, wiec `xargs -0` sklejalo
#      cala liste plikow w JEDEN argument. `find -print0` zeruje poprawnie na obu.
# Nazwy plikow maja spacje ("Failed Ideas"), wiec separator NUL jest konieczny.
if sed --version >/dev/null 2>&1; then SED_I=(-i); else SED_I=(-i ''); fi
SUBST="s/{{UNIT}}/$UNIT/g; s/{{UNIT_TYPE}}/$UNIT_TYPE/g; s/{{PROJECT}}/$PROJECT/g; s/{{DATE}}/$DATE/g"
while IFS= read -r -d '' f; do
  case "$f" in *.png|*.jpg|*.jpeg|*.gif|*.ico) continue;; esac
  sed "${SED_I[@]}" "$SUBST" "$f"
done < <(find wiki .obsidian -type f -print0)

# 1b. .gitattributes — log.md sklada sie sam przy rownoleglych sesjach
# Hook Stop pushuje wiki/ z KAZDEJ sesji, wiec dwie sesje zawsze dopisuja rozne
# wpisy na koncu tego samego log.md -> konflikt pewny, nie przypadkowy.
# merge=union bierze oba zestawy. Bezpieczne: log jest append-only, wpisy unikalne.
if grep -qF 'wiki/log.md merge=union' .gitattributes 2>/dev/null; then
  echo "SKIP .gitattributes (merge=union juz jest)"
else
  { [ -s .gitattributes ] && echo; cat <<'GA'
# wiki/log.md jest append-only i pisza do niego rownolegle sesje Claude
# (hook Stop commituje wiki/ i pushuje). merge=union sklada oba zestawy wpisow
# zamiast wolac o reczne rozwiazanie. Szczegoly: wiki/SCHEMA.md.
wiki/log.md merge=union
GA
  } >> .gitattributes
  echo "OK   .gitattributes (wiki/log.md merge=union)"
fi

# 2. CLAUDE.md "## Wiki"
if grep -q '^## Wiki' CLAUDE.md 2>/dev/null; then echo "SKIP CLAUDE.md ## Wiki"; else
  [ -f CLAUDE.md ] || printf '# %s\n' "$PROJECT" > CLAUDE.md
  { echo; sed "s/{{UNIT}}/$UNIT/g" "$TPL/CLAUDE-wiki.md"; } >> CLAUDE.md; echo "OK   CLAUDE.md ## Wiki"
fi

# 3. hooki — PowerShell na Windows (cygpath = Git Bash), bash gdzie indziej; merge do istniejacego settings.json
if command -v cygpath >/dev/null 2>&1; then
  START='powershell -NoProfile -ExecutionPolicy Bypass -File wiki/hooks/wiki-hook.ps1 start'
  STOP='powershell -NoProfile -ExecutionPolicy Bypass -File wiki/hooks/wiki-hook.ps1 stop'
else
  START='bash wiki/hooks/wiki-hook.sh start'; STOP='bash wiki/hooks/wiki-hook.sh stop'
fi
"$PY" - "$START" "$STOP" <<'PY'
import json, pathlib, sys
start, stop = sys.argv[1], sys.argv[2]
p = pathlib.Path(".claude/settings.json")
d = json.loads(p.read_text(encoding="utf-8")) if p.exists() else {}
hooks = d.setdefault("hooks", {})
def add(event, cmd, timeout):
    groups = hooks.setdefault(event, [])
    if any(h.get("command") == cmd for g in groups for h in g.get("hooks", [])):
        print(f"SKIP hook {event}"); return
    groups.append({"hooks": [{"type": "command", "command": cmd, "timeout": timeout}]})
    print(f"OK   hook {event}: {cmd}")
add("SessionStart", start, 20000)
add("Stop", stop, 30000)
p.write_text(json.dumps(d, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
PY

# 4. hot.md z aktualnego stanu
"$PY" wiki/update_hot.py && echo "OK   wiki/hot.md (generated)"
echo
echo "GOTOWE: $ROOT/wiki (unit=$UNIT, type=$UNIT_TYPE)"
echo "Obsidian -> Open folder as vault -> $ROOT  (ROOT repo, nie wiki/)"
