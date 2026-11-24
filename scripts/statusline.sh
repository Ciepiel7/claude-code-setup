#!/usr/bin/env bash
# ponytail: okno kontekstu zaszyte jako 200k (dzielnik 2000 = 200000/100) - zmien przy 1M
# ponytail: jeden jq na transcript, reszta w bashu; bez cache, bez stanu
# ponytail: node = jedna wersja na Mac i Windows; jq ponizej to fallback bez node
command -v node >/dev/null 2>&1 && exec node "$HOME/.claude/scripts/statusline.js"
j=$(cat)
{ read -r model; read -r tr; read -r cost; read -r dir; } < <(jq -r '.model.display_name // "?", .transcript_path // "", (.cost.total_cost_usd // 0), .workspace.current_dir // ""' <<<"$j")

ctx="?"
[ -f "$tr" ] && ctx=$(jq -rs '[.[] | select(.message.usage)] | last | .message.usage
  | if . then ((.input_tokens + .cache_read_input_tokens + .cache_creation_input_tokens) / 2000) else empty end
  | "\(. * 10 | round / 10)%"' 2>/dev/null)
[ -z "$ctx" ] && ctx="?"

dir=${dir:-$PWD}
# ponytail: --git-common-dir wskazuje .git glownego repo, wiec worktree nie zmienia nazwy
gc=$(git -C "$dir" rev-parse --path-format=absolute --git-common-dir 2>/dev/null)
[ -n "$gc" ] && proj=$(basename "$(dirname "$gc")") || proj=$(basename "$dir")

D=$'\033[90m'; R=$'\033[0m'
printf '%sModel:%s %s%s%s %s|%s %sCtx Used: %s%s %s|%s %sCost:%s %s$%.2f%s %s|%s %sProjekt:%s %s%s%s' \
  $'\033[36m' "$R" $'\033[96m' "$model" "$R" "$D" "$R" \
  "$D" "$ctx" "$R" "$D" "$R" \
  $'\033[35m' "$R" $'\033[95m' "$cost" "$R" "$D" "$R" \
  $'\033[33m' "$R" $'\033[93m' "$proj" "$R"

pt=$(ls -d ~/.claude/plugins/cache/ponytail/ponytail/*/hooks/ponytail-statusline.sh 2>/dev/null | sort -V | tail -n1)
[ -n "$pt" ] && { printf ' %s|%s ' "$D" "$R"; bash "$pt"; }
