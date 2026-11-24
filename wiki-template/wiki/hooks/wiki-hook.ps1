# Hook Claude Code (Windows). Uzycie: wiki-hook.ps1 start|stop. Best-effort, zawsze exit 0.
# start: git pull --ff-only (sync wiki miedzy maszynami)
# stop : update_hot.py -> git add wiki .obsidian -> commit z timestampem -> push
param([string]$Phase = "stop")
$ErrorActionPreference = "SilentlyContinue"
try {
  if ($Phase -eq "start") {
    git pull --ff-only 2>&1 | Out-Null
  } else {
    $py = if (Get-Command python -ErrorAction SilentlyContinue) { "python" } else { "python3" }
    & $py wiki/update_hot.py 2>&1 | Out-Null
    git add wiki .obsidian 2>&1 | Out-Null
    git diff --cached --quiet
    if ($LASTEXITCODE -ne 0) {
      git commit -qm ("wiki: auto " + (Get-Date -Format s)) 2>&1 | Out-Null
      git push -q 2>&1 | Out-Null
    }
  }
} catch {}
exit 0
