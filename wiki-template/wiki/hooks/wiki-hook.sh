#!/usr/bin/env bash
# Hook Claude Code (mac/linux). Uzycie: wiki-hook.sh start|stop. Best-effort, zawsze exit 0.
# start: git pull --ff-only (sync wiki miedzy maszynami)
# stop : update_hot.py -> git add wiki .obsidian -> commit z timestampem -> push
{
  if [ "${1:-stop}" = start ]; then
    git pull --ff-only
  else
    python3 wiki/update_hot.py || python wiki/update_hot.py
    git add wiki .obsidian
    git diff --cached --quiet || { git commit -qm "wiki: auto $(date +%FT%T)"; git push -q; }
  fi
} >/dev/null 2>&1
exit 0
