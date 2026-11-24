#!/bin/bash
# install.sh — Claude Code dotfiles setup
#
# Usage:
#   bash install.sh                        # Install Tier 1 universal agents only
#   bash install.sh --type=wordpress       # + wp-researcher, css-builder
#   bash install.sh --type=nextjs          # + nextjs-helper
#   bash install.sh --type=python          # + python-helper
#   bash install.sh --type=rust            # + crate-explorer, parity-tracker
#   bash install.sh --auto-detect          # Auto-detect project type from cwd
#   bash install.sh --init-project         # Copy project-template/ to current dir
#   bash install.sh --list                 # List installed agents with versions
#   bash install.sh --update               # Reinstall/overwrite all (no skip)
#   bash install.sh --validate             # Validate all agent frontmatter
#   bash install.sh --diff                 # Compare installed vs repo versions
#   bash install.sh --health               # System health check
#   bash install.sh --check                # Repo vs ~/.claude: MISSING/DIFFERENT/EXTRA, exit 1 gdy sa roznice
#   bash install.sh --update --type=python # Reinstall Tier 1 + python

set -e

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
MANIFEST_FILE="$CLAUDE_DIR/.dotfiles-manifest.json"
PROJECT_TYPE=""
INIT_PROJECT=false
LIST_ONLY=false
UPDATE_MODE=false
VALIDATE_ONLY=false
DIFF_ONLY=false
HEALTH_CHECK=false
CHECK_ONLY=false
AUTO_DETECT=false

# Tier 1: jedna lista dla instalacji i --check
TIER1_AGENTS=(
  "code-reviewer.md"
  "doc-maintainer.md"
  "git-workflow.md"
  "security-auditor.md"
  "debug-assistant.md"
  "test-runner.md"
  "dependency-auditor.md"
  "team-recipes.md"
  "project-detector.md"
  "health-checker.md"
  "board-sceptyk.md"
  "board-realista.md"
  "board-analityk.md"
  "board-strateg.md"
  "scout.md"
  "implementer.md"
)

# Parse arguments
for arg in "$@"; do
  case "$arg" in
    --type=*)
      PROJECT_TYPE="${arg#--type=}"
      ;;
    --init-project)
      INIT_PROJECT=true
      ;;
    --list)
      LIST_ONLY=true
      ;;
    --update)
      UPDATE_MODE=true
      ;;
    --validate)
      VALIDATE_ONLY=true
      ;;
    --diff)
      DIFF_ONLY=true
      ;;
    --health)
      HEALTH_CHECK=true
      ;;
    --check)
      CHECK_ONLY=true
      ;;
    --auto-detect)
      AUTO_DETECT=true
      ;;
    --help|-h)
      echo "Usage: bash install.sh [OPTIONS]"
      echo ""
      echo "  --type=TYPE        Install Tier 2 agents (wordpress|nextjs|python|rust)"
      echo "  --auto-detect      Auto-detect project type from current directory"
      echo "  --init-project     Copy project template to current directory"
      echo "  --list             Show installed agents with versions"
      echo "  --update           Overwrite existing files (default: skip if exists)"
      echo "  --validate         Check all agent files for valid frontmatter"
      echo "  --diff             Compare installed vs repo agent versions"
      echo "  --health           Run system health check"
      echo "  --check            Diff repo vs ~/.claude (MISSING/DIFFERENT/EXTRA), exit 1 on any difference"
      exit 0
      ;;
  esac
done

# Helper: extract frontmatter field from agent file
get_field() {
  local file="$1"
  local field="$2"
  grep "^${field}:" "$file" 2>/dev/null | head -1 | sed "s/^${field}: *//"
}

# Helper: copy file, skip if exists (warn user) — or overwrite in --update mode
copy_file() {
  local src="$1"
  local dst="$2"
  if [ -f "$dst" ] && [ "$UPDATE_MODE" = false ]; then
    echo "SKIP (exists) $dst"
  else
    cp "$src" "$dst"
    if [ "$UPDATE_MODE" = true ]; then
      echo "UPDATE $dst"
    else
      echo "OK     $dst"
    fi
  fi
}

# Helper: native path for python (MSYS/Git Bash gives /c/... which Windows python cannot open)
to_native() {
  if command -v cygpath &>/dev/null; then cygpath -w "$1"; else echo "$1"; fi
}

# Helper: append a PostToolUse hook to a project settings.json
# cmd trafia przez env, zeby uniknac piekla cudzyslowow w python -c
add_hook() {
  local settings="$1"
  local cmd="$2"
  local timeout="$3"
  HOOK_CMD="$cmd" HOOK_TIMEOUT="$timeout" python3 -c "
import json, os, sys
path = sys.argv[1]
with open(path) as f:
    data = json.load(f)
data.setdefault('hooks', {}).setdefault('PostToolUse', []).append({
    'matcher': 'Write|Edit|MultiEdit',
    'hooks': [{
        'type': 'command',
        'command': os.environ['HOOK_CMD'],
        'timeout': int(os.environ['HOOK_TIMEOUT']),
    }],
})
with open(path, 'w') as f:
    json.dump(data, f, indent=2)
" "$(to_native "$settings")"
}

# Helper: auto-detect project type from directory
auto_detect_type() {
  local dir="${1:-.}"
  [ -f "$dir/wp-config.php" ] || [ -d "$dir/wp-content" ] && echo "wordpress" && return
  [ -f "$dir/next.config.js" ] || [ -f "$dir/next.config.mjs" ] || [ -f "$dir/next.config.ts" ] && echo "nextjs" && return
  [ -f "$dir/pyproject.toml" ] || [ -f "$dir/requirements.txt" ] && echo "python" && return
  [ -f "$dir/Cargo.toml" ] && echo "rust" && return
  echo ""
}

# Helper: write manifest
write_manifest() {
  local installed_type="${1:-}"
  local agents_json="["
  local first=true
  for f in "$CLAUDE_DIR"/agents/*.md; do
    [ -f "$f" ] || continue
    local name
    name=$(basename "$f")
    local ver
    ver=$(get_field "$f" "version")
    if [ "$first" = true ]; then
      first=false
    else
      agents_json="$agents_json,"
    fi
    agents_json="$agents_json\"$name(v${ver:-?})\""
  done
  agents_json="$agents_json]"

  cat > "$MANIFEST_FILE" << MANIFEST_EOF
{
  "installed_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "dotfiles_dir": "$DOTFILES_DIR",
  "project_type": "$installed_type",
  "agents": $agents_json
}
MANIFEST_EOF
}

# ─── --health: system health check ──────────────────────────────────────────

if [ "$HEALTH_CHECK" = true ]; then
  echo "=== System Health Check ==="
  echo ""
  errors=0
  warnings=0

  # Check settings.json
  echo "--- Settings ---"
  if [ -f "$CLAUDE_DIR/settings.json" ]; then
    if python3 -c "import json; json.load(open(r'$(to_native "$CLAUDE_DIR/settings.json")'))" 2>/dev/null; then
      echo "OK   settings.json (valid JSON)"
    else
      echo "FAIL settings.json (invalid JSON)"
      errors=$((errors + 1))
    fi
  else
    echo "FAIL settings.json missing"
    errors=$((errors + 1))
  fi

  # Check CLAUDE.md
  if [ -f "$CLAUDE_DIR/CLAUDE.md" ]; then
    echo "OK   CLAUDE.md"
  else
    echo "FAIL CLAUDE.md missing"
    errors=$((errors + 1))
  fi

  # Check agents
  echo ""
  echo "--- Agents ---"
  agent_count=0
  agent_names=()
  for f in "$CLAUDE_DIR"/agents/*.md; do
    [ -f "$f" ] || continue
    agent_count=$((agent_count + 1))
    basename_f=$(basename "$f")
    name=$(get_field "$f" "name")
    ver=$(get_field "$f" "version")
    model=$(get_field "$f" "model")

    # Check for duplicate names
    for existing in "${agent_names[@]+"${agent_names[@]}"}"; do
      if [ "$existing" = "$name" ]; then
        echo "WARN duplicate agent name: $name"
        warnings=$((warnings + 1))
      fi
    done
    agent_names+=("$name")

    # Validate fields
    if [ -z "$name" ] || [ -z "$ver" ] || [ -z "$model" ]; then
      echo "WARN $basename_f — missing frontmatter fields"
      warnings=$((warnings + 1))
    else
      echo "OK   $basename_f (v$ver, $model)"
    fi
  done
  echo "     $agent_count agents installed"

  # Check hooks
  echo ""
  echo "--- Hooks ---"
  for hook in agent-routing.sh guard-destructive.sh guard-untrusted-repo.sh statusline.sh prune-worktree-sessions.sh read-gate.sh write-gate.sh browser-gate.sh answer-gate.sh; do
    if [ -x "$CLAUDE_DIR/scripts/$hook" ]; then echo "OK   $hook"; else echo "FAIL $hook missing/not executable"; errors=$((errors + 1)); fi
  done
  if command -v skillspector >/dev/null 2>&1; then
    echo "OK   skillspector (guard-untrusted-repo aktywny)"
  else
    echo "WARN skillspector brak — guard-untrusted-repo.sh przepuszcza wszystko. Instalacja: uv tool install git+https://github.com/NVIDIA/skillspector.git"
    warnings=$((warnings + 1))
  fi
  if [ -f "$CLAUDE_DIR/scripts/doc-check.sh" ]; then
    if [ -x "$CLAUDE_DIR/scripts/doc-check.sh" ]; then
      echo "OK   doc-check.sh (executable)"
    else
      echo "WARN doc-check.sh not executable — run: chmod +x ~/.claude/scripts/doc-check.sh"
      warnings=$((warnings + 1))
    fi
  else
    echo "FAIL doc-check.sh missing"
    errors=$((errors + 1))
  fi

  # Check dependencies
  echo ""
  echo "--- Dependencies ---"
  if command -v python3 &>/dev/null; then
    echo "OK   python3 ($(python3 --version 2>&1))"
  else
    echo "FAIL python3 not found — PreToolUse hook will not work"
    errors=$((errors + 1))
  fi

  # Check manifest
  echo ""
  echo "--- Manifest ---"
  if [ -f "$MANIFEST_FILE" ]; then
    if python3 -c "import json; json.load(open(r'$(to_native "$MANIFEST_FILE")'))" 2>/dev/null; then
      installed_at=$(python3 -c "import json; print(json.load(open(r'$(to_native "$MANIFEST_FILE")')).get('installed_at','?'))" 2>/dev/null)
      echo "OK   manifest (installed: $installed_at)"
    else
      echo "WARN manifest invalid JSON"
      warnings=$((warnings + 1))
    fi
  else
    echo "WARN no manifest — run install.sh to create one"
    warnings=$((warnings + 1))
  fi

  # Summary
  echo ""
  if [ "$errors" -eq 0 ] && [ "$warnings" -eq 0 ]; then
    echo "Overall: HEALTHY"
  elif [ "$errors" -eq 0 ]; then
    echo "Overall: DEGRADED ($warnings warnings)"
  else
    echo "Overall: BROKEN ($errors errors, $warnings warnings)"
  fi
  exit 0
fi

# ─── --diff: compare installed vs repo ───────────────────────────────────────

if [ "$DIFF_ONLY" = true ]; then
  echo "=== Agent Diff: repo vs installed ==="
  echo ""

  for f in "$DOTFILES_DIR"/agents/*.md; do
    [ -f "$f" ] || continue
    basename_f=$(basename "$f")
    dst="$CLAUDE_DIR/agents/$basename_f"

    repo_ver=$(get_field "$f" "version")

    if [ -f "$dst" ]; then
      installed_ver=$(get_field "$dst" "version")
      if diff -q --strip-trailing-cr "$f" "$dst" &>/dev/null; then
        printf "CURRENT  %-28s v%s\n" "$basename_f" "${installed_ver:-?}"
      else
        printf "CHANGED  %-28s repo:v%-8s installed:v%s\n" "$basename_f" "${repo_ver:-?}" "${installed_ver:-?}"
      fi
    else
      printf "MISSING  %-28s v%s\n" "$basename_f" "${repo_ver:-?}"
    fi
  done

  # Check for agents installed but not in repo (orphans)
  echo ""
  for f in "$CLAUDE_DIR"/agents/*.md; do
    [ -f "$f" ] || continue
    basename_f=$(basename "$f")
    if [ ! -f "$DOTFILES_DIR/agents/$basename_f" ]; then
      # Check project-types
      found=false
      for pt in "$DOTFILES_DIR"/agents/project-types/*.md; do
        [ -f "$pt" ] || continue
        if [ "$(basename "$pt")" = "$basename_f" ]; then
          found=true
          break
        fi
      done
      if [ "$found" = false ]; then
        printf "ORPHAN   %-28s (not in repo)\n" "$basename_f"
      fi
    fi
  done

  echo ""
  echo "Run 'bash install.sh --update' to sync CHANGED/MISSING agents."
  exit 0
fi

# ─── --check: repo vs ~/.claude (nic nie zmienia) ───────────────────────────

if [ "$CHECK_ONLY" = true ]; then
  echo "=== Check: repo vs $CLAUDE_DIR ==="
  echo ""
  diffs=0

  # check_file <repo> <installed>: te same pary co kopiuje instalator
  check_file() {
    if [ ! -e "$2" ]; then
      echo "MISSING   $2"; diffs=$((diffs + 1))
    elif ! diff -q --strip-trailing-cr "$1" "$2" &>/dev/null; then
      echo "DIFFERENT $2"; diffs=$((diffs + 1))
    fi
  }

  check_file "$DOTFILES_DIR/CLAUDE.global.md" "$CLAUDE_DIR/CLAUDE.md"

  for s in "$DOTFILES_DIR"/scripts/*.sh "$DOTFILES_DIR"/scripts/*.ps1 "$DOTFILES_DIR"/scripts/*.js "$DOTFILES_DIR"/scripts/*.py; do
    [ -f "$s" ] || continue
    check_file "$s" "$CLAUDE_DIR/scripts/$(basename "$s")"
  done
  # EXTRA: w ~/.claude/scripts, ale nie w repo
  for f in "$CLAUDE_DIR"/scripts/*; do
    [ -f "$f" ] || continue
    if [ ! -f "$DOTFILES_DIR/scripts/$(basename "$f")" ]; then
      echo "EXTRA     $f"; diffs=$((diffs + 1))
    fi
  done

  for agent in "${TIER1_AGENTS[@]}"; do
    [ -f "$DOTFILES_DIR/agents/$agent" ] && check_file "$DOTFILES_DIR/agents/$agent" "$CLAUDE_DIR/agents/$agent"
  done

  for s in "$DOTFILES_DIR"/skills/*/; do
    [ -f "$s/SKILL.md" ] || continue
    name="$(basename "$s")"
    while read -r f; do
      check_file "$s/$f" "$CLAUDE_DIR/skills/$name/$f"
    done < <(cd "$s" && find . -type f)
  done
  while read -r f; do
    check_file "$DOTFILES_DIR/wiki-template/$f" "$CLAUDE_DIR/wiki-template/$f"
  done < <(cd "$DOTFILES_DIR/wiki-template" && find . -type f)

  # hooki: kazda komenda z repo settings.json ma byc w zainstalowanym (merge wycina powershell poza Windows)
  hook_diff=$(IS_WINDOWS=$(command -v cygpath &>/dev/null && echo 1 || echo 0) python3 - "$(to_native "$DOTFILES_DIR/settings.json")" "$(to_native "$CLAUDE_DIR/settings.json")" <<'PY'
import json, os, sys
def cmds(path):
    with open(path, encoding='utf-8') as f:
        d = json.load(f)
    return {h['command'] for ev in d.get('hooks', {}).values() for g in ev for h in g.get('hooks', [])}
try:
    repo, local = cmds(sys.argv[1]), cmds(sys.argv[2])
except Exception:
    print('MISSING   settings.json (brak lub nieczytelny)'); sys.exit(0)
for c in sorted(repo - local):
    if os.environ.get('IS_WINDOWS') != '1' and c.startswith('powershell'):
        continue
    print('MISSING   hook: ' + c)
PY
)
  if [ -n "$hook_diff" ]; then
    echo "$hook_diff"
    diffs=$((diffs + $(echo "$hook_diff" | wc -l)))
  fi

  echo ""
  if [ "$diffs" -eq 0 ]; then
    echo "Check: OK (repo = $CLAUDE_DIR)"
    exit 0
  fi
  echo "Check: $diffs roznic. Napraw: bash install.sh --update"
  exit 1
fi

# ─── --validate: check agent frontmatter ───────────────────────────────────

if [ "$VALIDATE_ONLY" = true ]; then
  echo "=== Agent Validation ==="
  echo ""
  errors=0
  checked=0

  for f in "$DOTFILES_DIR"/agents/*.md "$DOTFILES_DIR"/agents/project-types/*.md; do
    [ -f "$f" ] || continue
    checked=$((checked + 1))
    basename=$(basename "$f")
    ok=true

    # Check required fields
    for field in name version description tools model; do
      val=$(get_field "$f" "$field")
      if [ -z "$val" ]; then
        echo "FAIL $basename — missing '$field'"
        ok=false
        errors=$((errors + 1))
      fi
    done

    # Check model is valid
    model=$(get_field "$f" "model")
    if [ -n "$model" ]; then
      case "$model" in
        haiku|sonnet|opus) ;;
        *)
          echo "FAIL $basename — invalid model '$model' (must be haiku|sonnet|opus)"
          ok=false
          errors=$((errors + 1))
          ;;
      esac
    fi

    # Check tools are known
    tools=$(get_field "$f" "tools")
    if [ -n "$tools" ]; then
      for tool in $(echo "$tools" | tr ',' '\n' | sed 's/^ *//;s/ *$//'); do
        case "$tool" in
          Read|Write|Edit|Grep|Glob|Bash|WebSearch|WebFetch|MultiEdit) ;;
          *)
            echo "WARN $basename — unknown tool '$tool' (may be valid, verify)"
            ;;
        esac
      done
    fi

    # Check frontmatter delimiters
    first_line=$(head -1 "$f")
    if [ "$first_line" != "---" ]; then
      echo "FAIL $basename — missing opening '---' delimiter"
      ok=false
      errors=$((errors + 1))
    fi

    if [ "$ok" = true ]; then
      ver=$(get_field "$f" "version")
      echo "OK   $basename (v$ver)"
    fi
  done

  echo ""
  echo "Checked: $checked agents, Errors: $errors"
  [ "$errors" -eq 0 ] && echo "All agents valid." || exit 1
  exit 0
fi

# ─── --list: show installed agents ─────────────────────────────────────────

if [ "$LIST_ONLY" = true ]; then
  echo "=== Claude Code — Installed Agents ==="
  echo ""
  echo "~/.claude/agents/ (Tier 1):"
  TIER1_AGENTS=(
    "code-reviewer.md"
    "doc-maintainer.md"
    "git-workflow.md"
    "security-auditor.md"
    "debug-assistant.md"
    "test-runner.md"
    "dependency-auditor.md"
    "team-recipes.md"
    "project-detector.md"
    "health-checker.md"
    "scout.md"
    "implementer.md"
  )
  for agent in "${TIER1_AGENTS[@]}"; do
    dst="$CLAUDE_DIR/agents/$agent"
    if [ -f "$dst" ]; then
      ver=$(get_field "$dst" "version")
      model=$(get_field "$dst" "model")
      printf "  %-28s v%-8s %s\n" "$agent" "${ver:-?}" "${model:-?}"
    else
      printf "  %-28s %s\n" "$agent" "[missing]"
    fi
  done

  echo ""
  echo "Tier 2 (technology-specific):"
  TIER2_TYPES=("wordpress" "nextjs" "python" "rust")
  TIER2_AGENTS=("wp-researcher.md css-builder.md" "nextjs-helper.md" "python-helper.md" "crate-explorer.md parity-tracker.md")
  for i in "${!TIER2_TYPES[@]}"; do
    type="${TIER2_TYPES[$i]}"
    agents="${TIER2_AGENTS[$i]}"
    installed=true
    versions=""
    for agent in $agents; do
      dst="$CLAUDE_DIR/agents/$agent"
      if [ -f "$dst" ]; then
        ver=$(get_field "$dst" "version")
        versions="$versions $agent(v${ver:-?})"
      else
        installed=false
      fi
    done
    if [ "$installed" = true ]; then
      echo "  [installed] --type=$type $versions"
    else
      echo "  [missing]   --type=$type  → bash install.sh --type=$type"
    fi
  done
  echo ""
  exit 0
fi

# ─── Auto-detect project type ────────────────────────────────────────────────

if [ "$AUTO_DETECT" = true ] && [ -z "$PROJECT_TYPE" ]; then
  detected=$(auto_detect_type "$(pwd)")
  if [ -n "$detected" ]; then
    echo "Auto-detected project type: $detected"
    PROJECT_TYPE="$detected"
  else
    echo "Could not auto-detect project type. Use --type=TYPE to specify."
  fi
fi

echo "=== Claude Code dotfiles install ==="
echo ""

# Create directories
mkdir -p "$CLAUDE_DIR/scripts"
mkdir -p "$CLAUDE_DIR/agents"

# ─── Tier 1: Universal (always installed) ───────────────────────────────────

echo "--- Tier 1: Universal ---"

copy_file "$DOTFILES_DIR/CLAUDE.global.md" "$CLAUDE_DIR/CLAUDE.md"
# settings.json NIE jest kopiowany na slepo: repo wnosi hooki/permissions/pluginy,
# ale czesc stanu zyje tylko na maszynie. --update robil blind cp i kasowal go bez sladu.
if [ -f "$CLAUDE_DIR/settings.json" ]; then
  cp "$CLAUDE_DIR/settings.json" "$CLAUDE_DIR/settings.json.bak"
  echo "BACKUP $CLAUDE_DIR/settings.json.bak"
fi
IS_WINDOWS=$(command -v cygpath &>/dev/null && echo 1 || echo 0) \
python3 - "$(to_native "$DOTFILES_DIR/settings.json")" "$(to_native "$CLAUDE_DIR/settings.json")" <<'PY'
import json, os, sys

# uczy sie per maszyna / wybor na tej maszynie — repo tego nie nadpisuje
LOCAL_WINS = ('autoMode', 'model')
# slowniki: baza z repo + lokalne dopiski zostaja (np. env albo plugin tylko tutaj)
MERGE_DICTS = ('env', 'enabledPlugins', 'extraKnownMarketplaces')

repo_path, local_path = sys.argv[1], sys.argv[2]
with open(repo_path, encoding='utf-8') as f:
    data = json.load(f)

if os.path.exists(local_path):
    with open(local_path, encoding='utf-8') as f:
        local = json.load(f)
    for k, v in local.items():
        if k in LOCAL_WINS or k not in data:
            data[k] = v
        elif k in MERGE_DICTS and isinstance(v, dict) and isinstance(data.get(k), dict):
            data[k] = dict(v, **data[k])
    # permissions: suma repo + lokalne wpisy, bez duplikatow
    for section, entries in local.get('permissions', {}).items():
        merged = data.setdefault('permissions', {}).setdefault(section, [])
        if isinstance(entries, list) and isinstance(merged, list):
            merged.extend(e for e in entries if e not in merged)
        else:
            data['permissions'][section] = entries

# Szablon ma guard hook w dwoch wariantach (powershell + bash); na nie-Windows
# powershell nie istnieje i kazdy Bash call loguje "command not found" — wytnij
if os.environ.get('IS_WINDOWS') != '1':
    for group in data.get('hooks', {}).get('PreToolUse', []):
        group['hooks'] = [h for h in group['hooks'] if not h.get('command', '').startswith('powershell')]

with open(local_path, 'w', encoding='utf-8') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
    f.write('\n')
PY
echo "MERGE  $CLAUDE_DIR/settings.json (lokalne: autoMode, model)"


# Wszystkie skrypty (doc-check, worktree-init, init-project, guard-destructive)
for s in "$DOTFILES_DIR"/scripts/*.sh "$DOTFILES_DIR"/scripts/*.ps1 "$DOTFILES_DIR"/scripts/*.js "$DOTFILES_DIR"/scripts/*.py; do
  [ -f "$s" ] || continue
  copy_file "$s" "$CLAUDE_DIR/scripts/$(basename "$s")"
  case "$s" in *.sh) chmod +x "$CLAUDE_DIR/scripts/$(basename "$s")" ;; esac
done

# Skills (skills/<name>/**) + szablon LLM Wiki (wiki-template/ -> ~/.claude/wiki-template/)
# Pelne drzewo (eval.md, references/, agents/) — nie tylko SKILL.md
mkdir -p "$CLAUDE_DIR/skills" "$CLAUDE_DIR/wiki-template"
for s in "$DOTFILES_DIR"/skills/*/; do
  [ -f "$s/SKILL.md" ] || continue
  name="$(basename "$s")"
  dst="$CLAUDE_DIR/skills/$name"
  # Zastap symlink katalogiem (np. no-ai-slop -> ~/.agents/skills/...)
  if [ -L "$dst" ]; then
    rm "$dst"
  fi
  mkdir -p "$dst"
  (cd "$s" && find . -type f) | while read -r f; do
    mkdir -p "$dst/$(dirname "$f")"
    copy_file "$s/$f" "$dst/$f"
  done
done
(cd "$DOTFILES_DIR/wiki-template" && find . -type f) | while read -r f; do
  mkdir -p "$CLAUDE_DIR/wiki-template/$(dirname "$f")"
  copy_file "$DOTFILES_DIR/wiki-template/$f" "$CLAUDE_DIR/wiki-template/$f"
done

for agent in "${TIER1_AGENTS[@]}"; do
  src="$DOTFILES_DIR/agents/$agent"
  if [ -f "$src" ]; then
    copy_file "$src" "$CLAUDE_DIR/agents/$agent"
  else
    echo "WARN missing $src"
  fi
done

# ─── Tier 2: Technology-specific ────────────────────────────────────────────

if [ -n "$PROJECT_TYPE" ]; then
  echo ""
  echo "--- Tier 2: $PROJECT_TYPE ---"

  case "$PROJECT_TYPE" in
    wordpress|wp)
      for agent in "wp-researcher.md" "css-builder.md"; do
        src="$DOTFILES_DIR/agents/project-types/$agent"
        if [ -f "$src" ]; then
          copy_file "$src" "$CLAUDE_DIR/agents/$agent"
        else
          echo "WARN missing $src"
        fi
      done
      ;;
    nextjs|next)
      src="$DOTFILES_DIR/agents/project-types/nextjs-helper.md"
      if [ -f "$src" ]; then
        copy_file "$src" "$CLAUDE_DIR/agents/nextjs-helper.md"
      else
        echo "WARN missing $src"
      fi
      ;;
    python)
      src="$DOTFILES_DIR/agents/project-types/python-helper.md"
      if [ -f "$src" ]; then
        copy_file "$src" "$CLAUDE_DIR/agents/python-helper.md"
      else
        echo "WARN missing $src"
      fi
      ;;
    rust)
      for agent in "crate-explorer.md" "parity-tracker.md"; do
        src="$DOTFILES_DIR/agents/project-types/$agent"
        if [ -f "$src" ]; then
          copy_file "$src" "$CLAUDE_DIR/agents/$agent"
        else
          echo "WARN missing $src"
        fi
      done
      ;;
    *)
      echo "WARN unknown type: $PROJECT_TYPE (valid: wordpress, nextjs, python, rust)"
      ;;
  esac
fi

# ─── --init-project: copy template to current directory ─────────────────────

if [ "$INIT_PROJECT" = true ]; then
  echo ""
  echo "--- Init project ---"
  TARGET_DIR="$(pwd)"

  if [ "$TARGET_DIR" = "$DOTFILES_DIR" ]; then
    echo "WARN --init-project: cannot init in dotfiles directory itself"
  else
    if [ -f "$TARGET_DIR/CLAUDE.md" ]; then
      echo "SKIP (exists) $TARGET_DIR/CLAUDE.md"
    else
      cp "$DOTFILES_DIR/project-template/CLAUDE.md" "$TARGET_DIR/CLAUDE.md"
      echo "OK     $TARGET_DIR/CLAUDE.md"
    fi

    mkdir -p "$TARGET_DIR/.claude"
    if [ -f "$TARGET_DIR/.claude/settings.json" ]; then
      echo "SKIP (exists) $TARGET_DIR/.claude/settings.json"
    else
      # Build project-level settings with type-specific hooks
      cp "$DOTFILES_DIR/project-template/settings.json" "$TARGET_DIR/.claude/settings.json"

      # Add project-type-specific hooks
      if [ -n "$PROJECT_TYPE" ]; then
        SETTINGS="$TARGET_DIR/.claude/settings.json"
        case "$PROJECT_TYPE" in
          wordpress|wp)
            add_hook "$SETTINGS" 'FILE_PATH=$(echo "$CLAUDE_TOOL_INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get(\"tool_input\",{}).get(\"file_path\",\"\"))" 2>/dev/null); [[ "$FILE_PATH" == *.php ]] && php -l "$FILE_PATH" 2>&1 || true' 10000 \
              && echo "OK     Added PHP lint hook" \
              || echo "WARN   Could not add PHP lint hook"
            ;;
          nextjs|next)
            if [ -f "$TARGET_DIR/tsconfig.json" ]; then
              add_hook "$SETTINGS" 'FILE_PATH=$(echo "$CLAUDE_TOOL_INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get(\"tool_input\",{}).get(\"file_path\",\"\"))" 2>/dev/null); [[ "$FILE_PATH" == *.ts || "$FILE_PATH" == *.tsx ]] && npx tsc --noEmit 2>&1 | head -20 || true' 30000 \
                && echo "OK     Added TypeScript check hook" \
                || echo "WARN   Could not add TypeScript check hook"
            else
              echo "SKIP   TypeScript check hook (no tsconfig.json)"
            fi
            ;;
          python)
            if command -v ruff &>/dev/null; then
              add_hook "$SETTINGS" 'FILE_PATH=$(echo "$CLAUDE_TOOL_INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get(\"tool_input\",{}).get(\"file_path\",\"\"))" 2>/dev/null); [[ "$FILE_PATH" == *.py ]] && ruff check "$FILE_PATH" 2>&1 | head -20 || true' 10000 \
                && echo "OK     Added Ruff lint hook" \
                || echo "WARN   Could not add Ruff lint hook"
            else
              echo "SKIP   Ruff lint hook (ruff not installed)"
            fi
            ;;
        esac
      fi

      echo "OK     $TARGET_DIR/.claude/settings.json"
    fi

    echo ""
    echo "Edit CLAUDE.md to fill in your project details."
    echo "Edit .claude/settings.json to set your project domain."
  fi
fi

# ─── Write manifest ─────────────────────────────────────────────────────────

write_manifest "$PROJECT_TYPE"

# ─── Summary ────────────────────────────────────────────────────────────────

echo ""
echo "=== Done ==="
echo ""
echo "Installed Tier 1 agents:"
for agent in "${TIER1_AGENTS[@]}"; do
  ver=$(get_field "$CLAUDE_DIR/agents/$agent" "version")
  echo "  ~/.claude/agents/$agent (v${ver:-?})"
done

if [ -n "$PROJECT_TYPE" ]; then
  echo ""
  echo "Installed Tier 2 agents ($PROJECT_TYPE):"
  case "$PROJECT_TYPE" in
    wordpress|wp)
      echo "  ~/.claude/agents/wp-researcher.md"
      echo "  ~/.claude/agents/css-builder.md"
      ;;
    nextjs|next)
      echo "  ~/.claude/agents/nextjs-helper.md"
      ;;
    python)
      echo "  ~/.claude/agents/python-helper.md"
      ;;
    rust)
      echo "  ~/.claude/agents/crate-explorer.md"
      echo "  ~/.claude/agents/parity-tracker.md"
      ;;
  esac
fi

# Skille z skills.txt, ktorych brakuje na tej maszynie — tylko podpowiedz, nic nie instaluje
if [ -f "$DOTFILES_DIR/skills.txt" ]; then
  missing_skills=""
  while IFS=$'\t' read -r sname ssrc; do
    [ -n "$sname" ] || continue
    [ -e "$CLAUDE_DIR/skills/$sname" ] && continue
    case "$ssrc" in
      repo) ;;
      local|plugin:*) missing_skills="$missing_skills  $sname ($ssrc, recznie)\n" ;;
      *) missing_skills="$missing_skills  $sname -> npx skills add $ssrc\n" ;;
    esac
  done < "$DOTFILES_DIR/skills.txt"
  if [ -n "$missing_skills" ]; then
    echo ""
    echo "Brakujace skille (skills.txt):"
    printf '%b' "$missing_skills"
  fi
fi

if [ "$UPDATE_MODE" = true ]; then
  echo ""
  echo "Verify: bash install.sh --list"
fi

echo ""
echo "Validate: bash install.sh --validate"
echo "Health:   bash install.sh --health"
echo "Run:      claude"
