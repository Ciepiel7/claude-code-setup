#!/usr/bin/env bash
# Sprzata sesje po MARTWYCH worktree, zeby `claude --resume` w glownym repo je widzial.
#
# Stan od Claude Code 2.1.312 (sprawdzone w binarce, 2026-10-28):
#  - EnterWorktree przenosi transkrypt do ~/.claude/projects/<repo>--claude-worktrees-<nazwa>/,
#    ExitWorktree przenosi go z powrotem (relocateSessionTranscript). Zastany plik o tej samej
#    nazwie odklada jako <id>.jsonl.superseded-<ts>.
#  - Picker /resume czyta katalog repo + katalogi ZYWYCH worktree (git worktree list).
#    Domyslnie pokazuje tylko sesje biezacego worktree; Ctrl+W = wszystkie worktree repo.
#    Nie ma ustawienia, ktore by to utrwalilo.
#
# Dziura, ktora lata ten skrypt: worktree skasowany bez ExitWorktree (recznie, `git worktree
# remove`, porzucona sesja). Transkrypt zostaje w katalogu worktree, ktorego picker juz nie czyta.
# Skrypt przenosi go (i katalog <id>/ z subagentami) do katalogu repo i kasuje pusty katalog.
#
# Zywych worktree NIE dotyka: wczesniejsza wersja robila hardlinki do katalogu repo, co
# kolidowalo z natywnym przenoszeniem i mnozylo pliki .superseded-* (ten sam inode).
# Takie kopie (ten sam inode co zywy plik) skrypt kasuje - zero utraty danych.
#
# Uzycie: hook SessionStart + Stop (czyta JSON ze stdin) albo recznie z terminala.
# Zawsze exit 0 - nigdy nie blokuje sesji.
set -u
shopt -s nullglob

projects="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/projects"
[ -d "$projects" ] || exit 0

# Transkrypt biezacej sesji - jej katalogu nie ruszamy (worktree mogl zniknac w trakcie).
# Hook daje jedna linie JSON i EOF; `read -t` zamiast `cat`, zeby reczne uruchomienie
# z otwartym, pustym stdin (np. z narzedzia Bash) nie wisialo w nieskonczonosc.
keep=""
if [ ! -t 0 ]; then
  line=""
  IFS= read -r -t 3 line 2>/dev/null || true
  keep=$(printf '%s' "$line" | grep -o '"transcript_path":"[^"]*"' | head -1 | cut -d'"' -f4)
fi

for dir in "$projects"/*--claude-worktrees-*; do
  [ -d "$dir" ] || continue
  main="${dir%%--claude-worktrees-*}"
  case "$keep" in "$dir"/*) continue ;; esac

  # Sciezki worktree bierzemy z cwd w transkryptach - slug katalogu nie da sie jednoznacznie
  # odkodowac ("-" to raz "/", raz ".", raz "-"). Gdy Claude juz przeniosl transkrypt do repo,
  # a zostal sam katalog <id>/, czytamy <repo>/<id>.jsonl.
  src=("$dir"/*.jsonl)
  if [ ${#src[@]} -eq 0 ]; then
    for d in "$dir"/*-*-*-*-*/; do
      f="$main/$(basename "$d").jsonl"
      [ -f "$f" ] && src+=("$f")
    done
  fi
  if [ ${#src[@]} -eq 0 ]; then
    # Katalog bez transkryptu i bez podkatalogow = pusta skorupa po natywnym przeniesieniu.
    rmdir "$dir" 2>/dev/null
    continue
  fi

  alive=0
  while IFS= read -r cwd; do
    [ -n "$cwd" ] || continue
    if [ -d "$cwd" ]; then alive=1; break; fi
  done < <(grep -h -o '"cwd":"[^"]*/\.claude/worktrees/[^"]*"' "${src[@]}" 2>/dev/null |
    cut -d'"' -f4 | sort -u)
  # Brak sciezek = nie wiemy, zostaw. Zywy worktree = Claude sam go obsluguje.
  grep -q -h -o '/\.claude/worktrees/' "${src[@]}" 2>/dev/null || continue
  [ "$alive" = 0 ] || continue

  mkdir -p "$main"
  for f in "$dir"/*.jsonl; do
    t="$main/$(basename "$f")"
    if [ -e "$t" ] && [ "$f" -ef "$t" ]; then
      rm -f "$f"
    elif [ -e "$t" ] && [ ! "$f" -nt "$t" ]; then
      mv -f "$f" "$t.superseded-$(date +%s)000"
    else
      [ -e "$t" ] && mv -f "$t" "$t.superseded-$(date +%s)000"
      mv -f "$f" "$t"
    fi
  done
  for d in "$dir"/*-*-*-*-*/; do
    d="${d%/}"
    t="$main/$(basename "$d")"
    [ -L "$t" ] && [ "$(readlink "$t")" = "$d" ] && rm -f "$t"
    [ -e "$t" ] || mv "$d" "$t"
  done
  left=("$dir"/*.jsonl)
  [ ${#left[@]} -eq 0 ] || continue
  rm -rf "$dir"
  echo "prune-worktree-sessions: $(basename "$dir") -> sesje przeniesione do $(basename "$main")" >&2
done

# Sprzatanie po starej wersji: kopie .superseded-* bedace tym samym plikiem (inode) co zywy
# transkrypt oraz martwe symlinki <id> -> skasowany katalog worktree.
for s in "$projects"/*/*.jsonl.superseded-*; do
  base="${s%%.superseded-*}"
  [ -f "$base" ] && [ "$s" -ef "$base" ] && rm -f "$s"
done
for l in "$projects"/*/*-*-*-*-*; do
  [ -L "$l" ] && [ ! -e "$l" ] && rm -f "$l"
done

exit 0
