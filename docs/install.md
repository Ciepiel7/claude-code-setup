## fn
fn install -> kopiuje dotfiles do ~/.claude/, tworzy katalogi

## fx
- tworzy ~/.claude/scripts/, ~/.claude/agents/
- nadpisuje ~/.claude/CLAUDE.md z CLAUDE.global.md (CLAUDE.md repo zostaje tylko lokalnie)
- merge ~/.claude/settings.json z settings.json: repo wnosi hooks/permissions/pluginy,
  lokalne wygrywaja `autoMode` i `model`, slowniki env/enabledPlugins/extraKnownMarketplaces sumowane
- backup ~/.claude/settings.json.bak przed kazdym merge
- kopiuje scripts/*.sh, *.ps1, *.js -> ~/.claude/scripts/ (chmod +x dla .sh)
- --health: sprawdza agent-routing.sh, guard-destructive.sh, statusline.sh, read-gate.sh, write-gate.sh, browser-gate.sh, answer-gate.sh (executable)
- --check: repo vs ~/.claude bez zmian: MISSING / DIFFERENT / EXTRA (plik w ~/.claude/scripts bez odpowiednika w scripts/), brakujace hooki z settings.json; exit 1 gdy cokolwiek sie rozni
- --check uzywa tych samych list co instalator (TIER1_AGENTS na gorze pliku, globy scripts/skills/wiki-template)
- po instalacji drukuje skille z skills.txt brakujace w ~/.claude/skills (`npx skills add <zrodlo>`), nic nie instaluje
- kopiuje scripts/doc-check.sh → ~/.claude/scripts/doc-check.sh (chmod +x)
- kopiuje agents/*.md → ~/.claude/agents/
- kopiuje skills/<name>/** → ~/.claude/skills/<name>/ (skille z repo; zastępuje symlinki katalogiem)
- kopiuje wiki-template/** → ~/.claude/wiki-template/ (szablon dla scripts/wiki-init.sh)

## vars
const DOTFILES_DIR -> bezwzgledna sciezka katalogu repo
const CLAUDE_DIR -> ~/.claude
const TIER1_AGENTS:array -> jedna lista agentow Tier 1 (instalacja + --check)

## fn
fn test-settings-merge -> scripts/test-settings-merge.sh weryfikuje merge na fixtures

## deps
> scripts/doc-check.sh, scripts/skills-manifest.sh (skills.txt), settings.json, CLAUDE.global.md, agents/*.md
