#!/usr/bin/env bash
# Sprawdza merge settings.json z install.sh: stan maszyny przezywa --update,
# a repo dalej wnosi hooki, pluginy i nowe klucze.
# ponytail: wycina heredoc z install.sh zamiast duplikowac logike
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

awk '/^python3 - "\$\(to_native "\$DOTFILES_DIR\/settings.json"\)"/{f=1;next} f&&/^PY$/{exit} f' \
  "$ROOT/install.sh" > "$TMP/merge.py"
[ -s "$TMP/merge.py" ] || { echo "FAIL: nie znaleziono bloku merge w install.sh"; exit 1; }

cat > "$TMP/repo.json" <<'JSON'
{
  "model": "opus",
  "env": {"BU_CDP_URL": "http://127.0.0.1:9333"},
  "statusLine": {"type": "command", "command": "bash ~/.claude/scripts/statusline.sh"},
  "enabledPlugins": {"humanizer@market": true},
  "hooks": {"PreToolUse": [{"hooks": [
    {"type": "command", "command": "powershell -File guard.ps1"},
    {"type": "command", "command": "bash guard.sh"}
  ]}]},
  "permissions": {"allow": ["Bash(git status:*)"]},
  "nowyKluczZRepo": true
}
JSON

cat > "$TMP/local.json" <<'JSON'
{
  "model": "fable",
  "env": {"BU_CDP_URL": "http://127.0.0.1:1111", "TYLKO_TUTAJ": "1"},
  "statusLine": {"type": "command", "command": "bash stary-statusline.sh"},
  "enabledPlugins": {"stripe@market": true},
  "autoMode": {"soft_deny": ["Bash(taskkill *chrome*:*)"]},
  "hooks": {"PreToolUse": [{"hooks": [{"type": "command", "command": "bash stary-guard.sh"}]}]},
  "permissions": {"allow": ["Bash(gh pr merge:*)"]},
  "kluczTylkoLokalny": 7
}
JSON

IS_WINDOWS=0 python3 "$TMP/merge.py" "$TMP/repo.json" "$TMP/local.json"

python3 - "$TMP/local.json" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))

# lokalne wygrywa
assert d['model'] == 'fable', 'model maszyny nadpisany przez repo'
assert d['autoMode']['soft_deny'] == ['Bash(taskkill *chrome*:*)'], 'autoMode zgubione'
assert d['kluczTylkoLokalny'] == 7, 'klucz spoza repo skasowany'

# repo wygrywa
assert 'statusline.sh' in d['statusLine']['command'], 'statusLine ma byc z repo'
assert d['nowyKluczZRepo'] is True, 'nowy klucz z repo nie doszedl'
cmds = [h['command'] for g in d['hooks']['PreToolUse'] for h in g['hooks']]
assert cmds == ['bash guard.sh'], 'hooki: repo + strip powershell, jest %r' % cmds

# slowniki sumowane, repo wygrywa kolizje
assert d['env'] == {'BU_CDP_URL': 'http://127.0.0.1:9333', 'TYLKO_TUTAJ': '1'}, 'env: %r' % d['env']
assert set(d['enabledPlugins']) == {'humanizer@market', 'stripe@market'}, 'pluginy: %r' % d['enabledPlugins']
assert set(d['permissions']['allow']) == {'Bash(git status:*)', 'Bash(gh pr merge:*)'}, \
    'permissions nie zsumowane: %r' % d['permissions']['allow']

print('OK: merge zachowuje stan maszyny, repo wnosi hooki, pluginy i nowe klucze')
PY
