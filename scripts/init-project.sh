#!/bin/bash
# init-project.sh — Initialize a new project with Claude Code template
# Usage: bash ~/.claude/scripts/init-project.sh <type>
# Types: rust, wordpress, python

set -euo pipefail

TYPE="${1:-}"
TEMPLATES_DIR="$HOME/.claude/templates"

if [ -z "$TYPE" ]; then
    echo "Usage: init-project.sh <rust|wordpress|python>"
    echo ""
    echo "Available templates:"
    ls "$TEMPLATES_DIR" 2>/dev/null || echo "  (none)"
    exit 1
fi

TEMPLATE_DIR="$TEMPLATES_DIR/$TYPE"

if [ ! -d "$TEMPLATE_DIR" ]; then
    echo "Error: Template '$TYPE' not found in $TEMPLATES_DIR"
    exit 1
fi

if [ -d ".claude" ]; then
    echo "Warning: .claude/ already exists. Skipping settings.json copy."
else
    echo "Creating .claude/ from template..."
    cp -r "$TEMPLATE_DIR/.claude" .
    echo "  Created .claude/settings.json"
fi

if [ ! -f "CLAUDE.md" ]; then
    cp "$TEMPLATE_DIR/CLAUDE.md" .
    echo "  Created CLAUDE.md (edit project name and details)"
else
    echo "Warning: CLAUDE.md already exists. Skipping."
fi

echo ""
echo "Done! Edit CLAUDE.md to set project name and conventions."
