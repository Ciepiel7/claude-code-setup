#!/bin/bash
# doc-check.sh — PostToolUse hook for doc-index system v4
# Checks docs/<basename>.md first, then CLAUDE.md fallback.
# Silent when all indexed. Shows only missing symbols when undocumented.

trap 'exit 0' ERR
set -uo pipefail

# ─── Parse tool input from stdin ────────────────────────────────────────────
INPUT=$(cat)

PATHS=$(echo "$INPUT" | python3 -c "
import sys, json, os, re
try:
    data = json.load(sys.stdin)
except Exception:
    sys.exit(0)
ti = data.get('tool_input') or {}
tool = data.get('tool_name')
out = []
if tool == 'Bash':
    cmd = ti.get('command') or ''
    cands = []
    for seg in re.split(r'&&|\|\||;|\||\n', cmd):
        toks = seg.split()
        if toks and toks[0] == 'sed' and any(t.startswith('-i') for t in toks[1:]):
            args = [t for t in toks[1:] if not t.startswith('-')]
            if len(args) > 1:
                cands.append(args[-1])
    cands += re.findall(r'(?<![<=&\d])\d?>>?\s*([^\s;&|<>]+)', cmd)
    cands += re.findall(r'\btee\s+(?:-a\s+)?(\S+)', cmd)
    for p in cands:
        p = p.strip('\'\"')
        if not p or p == '/dev/null' or p[0] in '-\$&':
            continue
        p = os.path.expanduser(p)
        if not os.path.isabs(p) and data.get('cwd'):
            p = os.path.join(data['cwd'], p)
        if os.path.isfile(p) and p not in out:
            out.append(p)
else:
    p = ti.get('file_path', ti.get('path', ''))
    if p:
        out.append(p)
print('\n'.join(out))
" 2>/dev/null || echo "")

check_file() {
    local FILE_PATH="$1"
# ─── Skip conditions ─────────────────────────────────────────────────────────
[ -z "$FILE_PATH" ] && return 0
[[ "$(basename "$FILE_PATH")" == "CLAUDE.md" ]] && return 0
[[ "$(basename "$FILE_PATH")" == *.md ]] && [[ "$FILE_PATH" == */docs/* ]] && return 0

# Skip vendor/generated paths
case "$FILE_PATH" in
  */node_modules/*|*/vendor/*|*/.next/*|*/dist/*|*/build/*|*/__pycache__/*) return 0 ;;
esac

EXT="${FILE_PATH##*.}"
BASENAME="$(basename "$FILE_PATH")"

case "$BASENAME" in
    package-lock.json|yarn.lock|pnpm-lock.yaml|*.min.*) return 0 ;;
esac
case "$EXT" in
    lock|log|map) return 0 ;;
esac

# Skip files >5000 lines (likely generated)
if [ -f "$FILE_PATH" ]; then
    LINE_COUNT_CHECK=$(wc -l < "$FILE_PATH" 2>/dev/null || echo 0)
    [ "$LINE_COUNT_CHECK" -gt 5000 ] && return 0
fi

# ─── Project root ────────────────────────────────────────────────────────────
FILE_DIR="$(dirname "$FILE_PATH")"
PROJECT_ROOT=$(git -C "$FILE_DIR" rev-parse --show-toplevel 2>/dev/null || echo "$FILE_DIR")

# ─── Extract functions/exports from modified file ─────────────────────────────
FUNCTIONS=""
if [ -f "$FILE_PATH" ]; then
    FUNCTIONS=$(python3 -c "
import re, sys

path = sys.argv[1]
ext = path.rsplit('.', 1)[-1] if '.' in path else ''

try:
    with open(path, 'r', encoding='utf-8', errors='ignore') as f:
        content = f.read()
except:
    sys.exit(0)

funcs = []

if ext in ('ts', 'tsx', 'js', 'jsx', 'mjs'):
    patterns = [
        r'export\s+(?:default\s+)?(?:async\s+)?function\s+(\w+)\s*\(([^)]*)\)',
        r'export\s+(?:const|let|var)\s+(\w+)\s*[:=]',
        r'(?:async\s+)?function\s+(\w+)\s*\(([^)]*)\)',
        r'(?:const|let|var)\s+(\w+)\s*=\s*(?:async\s*)?\([^)]*\)\s*(?:=>|:)',
        r'(?:const|let|var)\s+(\w+)\s*=\s*(?:async\s*)?\w+\s*(?:=>)',
        r'class\s+(\w+)',
        r'interface\s+(\w+)',
        r'type\s+(\w+)\s*=',
    ]
    for p in patterns:
        for m in re.finditer(p, content):
            name = m.group(1)
            if name and name not in [f.split('(')[0].strip() for f in funcs]:
                funcs.append(m.group(0)[:80])

elif ext in ('php',):
    seen_names = set()
    for m in re.finditer(r'function\s+(\w+)\s*\(([^)]*)\)', content):
        name = m.group(1)
        if name not in seen_names:
            seen_names.add(name)
            funcs.append(f'function {name}({m.group(2)[:40]})')
    for m in re.finditer(r'class\s+(\w+)', content):
        name = m.group(1)
        if name not in seen_names:
            seen_names.add(name)
            funcs.append(f'class {name}')
    for m in re.finditer(r'add_(action|filter)\s*\(\s*[\x27\"]([\w_/-]+)[\x27\"]\s*,\s*[\x27\"]([\w_]+)[\x27\"]', content):
        hook_type = m.group(1)
        hook_name = m.group(2)
        callback = m.group(3)
        key = f'{hook_type}:{hook_name}'
        if key not in seen_names:
            seen_names.add(key)
            funcs.append(f'add_{hook_type}({hook_name}, {callback})')
    for m in re.finditer(r'add_(action|filter)\s*\(\s*[\x27\"]([\w_/-]+)[\x27\"]\s*,\s*function', content):
        hook_type = m.group(1)
        hook_name = m.group(2)
        key = f'{hook_type}:{hook_name}:anon'
        if key not in seen_names:
            seen_names.add(key)
            funcs.append(f'add_{hook_type}({hook_name}, fn())')
    for m in re.finditer(r'wp_enqueue_(style|script)\s*\(\s*[\x27\"]([\w-]+)[\x27\"]', content):
        asset_type = m.group(1)
        handle = m.group(2)
        key = f'enqueue:{handle}'
        if key not in seen_names:
            seen_names.add(key)
            funcs.append(f'wp_enqueue_{asset_type}({handle})')

elif ext in ('py',):
    patterns = [
        r'def\s+(\w+)\s*\(([^)]*)\)',
        r'class\s+(\w+)',
        r'(\w+)\s*=\s*(?:lambda|partial)',
    ]
    for p in patterns:
        for m in re.finditer(p, content):
            name = m.group(1)
            if name and not name.startswith('_') or len(content.split(chr(10))) > 15:
                funcs.append(m.group(0)[:80])

elif ext in ('css', 'scss', 'less'):
    patterns = [
        r'(\.[a-zA-Z][\w-]*)\s*\{',
        r'(--[\w-]+)\s*:',
        r'@media\s*([^{]+)',
        r'@keyframes\s+([\w-]+)',
    ]
    for p in patterns:
        for m in re.finditer(p, content):
            funcs.append(m.group(0)[:80].strip().rstrip('{').strip())

elif ext in ('vue', 'svelte'):
    patterns = [
        r'(?:export\s+)?(?:async\s+)?function\s+(\w+)',
        r'(?:const|let)\s+(\w+)\s*=',
        r'defineProps<([^>]+)>',
        r'defineEmits\(\[([^\]]+)\]',
    ]
    for p in patterns:
        for m in re.finditer(p, content):
            funcs.append(m.group(0)[:80])

# Deduplicate and limit
seen = set()
unique = []
for f in funcs:
    key = f.strip()
    if key not in seen:
        seen.add(key)
        unique.append(key)
    if len(unique) >= 40:
        break

for f in unique:
    print(f'  - {f}')
" "$FILE_PATH" 2>/dev/null || echo "")
fi

# ─── Find doc file: docs/<basename>.md first, then nearest CLAUDE.md ────────
NEAREST_DOC=""
DOC_BASENAME="${BASENAME%.*}"

# Strategy 1: docs/<basename>.md in project root
if [ -f "$PROJECT_ROOT/docs/$DOC_BASENAME.md" ]; then
    NEAREST_DOC="$PROJECT_ROOT/docs/$DOC_BASENAME.md"
fi

# Strategy 2: fallback to nearest CLAUDE.md
if [ -z "$NEAREST_DOC" ]; then
    CHECK_DIR="$FILE_DIR"
    for _ in 1 2 3 4; do
        if [ -f "$CHECK_DIR/CLAUDE.md" ]; then
            NEAREST_DOC="$CHECK_DIR/CLAUDE.md"
            break
        fi
        PARENT="$(dirname "$CHECK_DIR")"
        [ "$PARENT" = "$CHECK_DIR" ] && break
        CHECK_DIR="$PARENT"
    done
fi

# ─── Check which functions are already documented ─────────────────────────────
UNDOCUMENTED=""
if [ -n "$NEAREST_DOC" ] && [ -n "$FUNCTIONS" ]; then
    UNDOCUMENTED=$(python3 -c "
import sys

doc_path = sys.argv[1]
try:
    with open(doc_path, 'r', encoding='utf-8', errors='ignore') as f:
        doc = f.read().lower()
except:
    sys.exit(0)

import re
for line in sys.stdin:
    line = line.strip().lstrip('- ').strip()
    match = re.search(r'(?:function|const|let|var|class|interface|type|def)\s+(\w+)', line)
    if not match:
        match = re.search(r'\.(\w[\w-]*)', line)
    if not match:
        match = re.search(r'--(\w[\w-]*)', line)
    if match:
        name = match.group(1).lower()
        if name not in doc:
            print(f'  X {line}')
" "$NEAREST_DOC" <<< "$FUNCTIONS" 2>/dev/null || echo "")
fi

# ─── File metrics ─────────────────────────────────────────────────────────────
LINE_COUNT=0
[ -f "$FILE_PATH" ] && LINE_COUNT=$(wc -l < "$FILE_PATH" 2>/dev/null || echo 0)

SIGNIFICANCE="minor"
if [ "$LINE_COUNT" -gt 50 ]; then SIGNIFICANCE="significant"
elif [ "$LINE_COUNT" -gt 20 ]; then SIGNIFICANCE="moderate"; fi

case "$EXT" in
    tsx|jsx|vue|svelte) SIGNIFICANCE="significant" ;;
    ts|js) [ "$LINE_COUNT" -gt 30 ] && SIGNIFICANCE="significant" ;;
    css|scss|less) [ "$LINE_COUNT" -gt 30 ] && SIGNIFICANCE="significant" ;;
    py) [ "$LINE_COUNT" -gt 30 ] && SIGNIFICANCE="significant" ;;
esac

# ─── Output (silent when all indexed) ─────────────────────────────────────────

# Case 1: doc exists, all symbols indexed -> silent exit
if [ -n "$NEAREST_DOC" ] && [ -z "$UNDOCUMENTED" ]; then
    return 0
fi

# Case 2: doc exists, undocumented symbols -> show only missing
if [ -n "$NEAREST_DOC" ] && [ -n "$UNDOCUMENTED" ]; then
    REL_DOC="${NEAREST_DOC#$PROJECT_ROOT/}"
    echo ""
    echo "DOC-ADD: $REL_DOC"
    echo "$UNDOCUMENTED"
    echo ""
    return 0
fi

# Case 3: No doc, significant file -> suggest docs/<basename>.md
if [ -z "$NEAREST_DOC" ] && [ "$SIGNIFICANCE" != "minor" ]; then
    echo ""
    echo "DOC-NEW: docs/$DOC_BASENAME.md"
    if [ -n "$FUNCTIONS" ]; then
        echo "$FUNCTIONS"
    fi
    echo ""
fi
}

while IFS= read -r p; do [ -n "$p" ] && check_file "$p"; done <<< "$PATHS"
exit 0
