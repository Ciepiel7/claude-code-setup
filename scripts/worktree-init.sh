#!/bin/bash
# Generyczny init worktree Claude: podpina gitignorowane zależności z głównego
# katalogu repo (.env*, vendor/, node_modules/), bez których świeży worktree
# nie działa (typowe objawy: "Database not configured", brak autoloadera, 404 modułów).
#
# Użycie (z katalogu worktree, zaraz po EnterWorktree):
#   bash ~/.claude/scripts/worktree-init.sh
# Jeśli projekt ma własny scripts/worktree-init.sh — użyj projektowego (wygrywa).
set -euo pipefail

MAIN="$(cd "$(git rev-parse --git-common-dir)/.." && pwd)"
HERE="$(pwd)"

if [ "$MAIN" = "$HERE" ]; then
    echo "To główny katalog repo — nic do roboty."
    exit 0
fi

link_dir() { # $1 = katalog do podpięcia (junction na Windows, symlink gdzie indziej)
    local d="$1"
    [ -d "$MAIN/$d" ] || return 0     # w projekcie nie występuje
    if [ -e "$d" ]; then
        echo "SKIP $d (istnieje — częściowo trackowany? podepnij podkatalogi ręcznie)"
        return 0
    fi
    case "$(uname -s)" in
        MINGW*|MSYS*) cmd //c mklink //J "$(echo "$d" | tr '/' '\\')" "$(cygpath -w "$MAIN/$d")" >/dev/null ;;
        *) ln -s "$MAIN/$d" "$d" ;;
    esac
    echo "LINK $d -> $MAIN/$d"
}

# Sekrety/konfiguracja lokalna: kopia (nie link — worktree może chcieć własne nadpisania)
for f in .env .env.local; do
    if [ ! -f "$f" ] && [ -f "$MAIN/$f" ]; then
        cp "$MAIN/$f" "$f"
        echo "COPY $f"
    fi
done

link_dir vendor
link_dir node_modules

echo "Worktree gotowy."
