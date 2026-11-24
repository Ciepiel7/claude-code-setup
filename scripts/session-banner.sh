#!/bin/bash
# session-banner.sh — SessionStart: co realnie jest w systemie.
# Zastapil zahardkodowany echo, ktory podawal 20 agentow (bylo 17) i wymienial
# dwa skille, ktorych nie ma. Banner laduje w kontekscie KAZDEJ sesji jako fakt
# o systemie, wiec kazda nieprawda w nim kosztuje przy kazdej decyzji.
# ponytail: liczenie na zywo zamiast listy do recznego utrzymania.

C="$HOME/.claude"
count() { ls -1 $1 2>/dev/null | wc -l | tr -d ' '; }

AGENTS="$(ls -1 "$C"/agents/*.md 2>/dev/null | wc -l | tr -d ' ')"
# tylko katalogi z SKILL.md — w skills/ siedzi tez `synced` i inne smieci
SKILLS="$(find -L "$C/skills" -maxdepth 2 -name SKILL.md 2>/dev/null | wc -l | tr -d ' ')"
RECIPES="$(grep -c '^## Recipe' "$C/agents/team-recipes.md" 2>/dev/null || echo 0)"
SCRIPTS="$(count "$C/scripts/*.sh")"

printf 'AVAILABLE: %s agentow (~/.claude/agents/) | %s skilli | %s skryptow | Team recipes: %s | Szablon projektu: bash ~/.claude/scripts/init-project.sh <rust|wordpress|python>\n' \
    "$AGENTS" "$SKILLS" "$SCRIPTS" "$RECIPES"
