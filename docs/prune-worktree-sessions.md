# scripts/prune-worktree-sessions.sh

Podpina sesje z worktree (`~/.claude/projects/*--claude-worktrees-*`) pod katalog sesji głównego repo,
żeby `claude resume` w repo widział je od razu. Po zniknięciu worktree przenosi resztę i kasuje pusty katalog.
Hook `SessionStart` + `Stop` (nowa sesja w worktree jest w pickerze po pierwszej turze), działa też ręcznie.

## Dlaczego
Od 2.1.302 `EnterWorktree` przenosi transkrypt sesji do `<repo>--claude-worktrees-<nazwa>/`
(sprawdzone na sesji, której pierwsze wpisy mają `cwd` repo, a plik leży w katalogu worktree).
Picker w głównym katalogu repo jej nie pokazuje. Wcześniejsza wersja skryptu robiła `rm -rf`
takiego katalogu po zniknięciu worktree; od 2.1.302 kasowało to całą rozmowę.

## fn
```
krok 1 -> <id>.jsonl hardlink do <repo>/, <id>/ symlink do <repo>/
krok 2 -> martwe worktree: mv <id>/ do <repo>/, rm -rf katalogu gdy kazdy jsonl -ef w <repo>/
keep <- stdin JSON hooka (transcript_path) -> katalog biezacej sesji nie jest sprzatany
```

## Reguly
- Hardlink, nie symlink: ten sam inode, dopisy Claude widać w obu miejscach, `rm -rf` worktree nic nie gubi
- Plik w worktree nowszy i inny inode -> `ln -f` (gdyby Claude przepisał transkrypt przez rename)
- Repo z nazwy katalogu: `${dir%%--claude-worktrees-*}` (prefiks slugu, bez dekodowania)
- Ścieżka worktree z `"cwd"` w transkryptach, NIE z nazwy katalogu — slug jest nieodwracalny
- Sesja może odwiedzić kilka worktree -> sprzątaj dopiero gdy ŻADNE z nich nie istnieje
- Żaden `"cwd"` z `.claude/worktrees/` w transkryptach -> nie sprzątaj (zachowawczo)
- `rm -rf` tylko gdy każdy `<id>.jsonl` jest `-ef` z kopią w repo
- `[ -t 0 ]` chroni przed zwisem przy ręcznym odpaleniu
- Zawsze `exit 0` — hook nigdy nie blokuje sesji

## vars
```
projects:path=${CLAUDE_CONFIG_DIR:-$HOME/.claude}/projects -> zrodlo katalogow sesji
main:path -> katalog sesji glownego repo
keep:path -> transcript_path biezacej sesji
found/alive:0|1 -> czy znaleziono cwd worktree / czy ktores zyje
safe:0|1 -> wszystkie jsonl sa w repo, mozna kasowac
```

## Powiazania
> settings.json (SessionStart, Stop), install.sh (--health), CLAUDE.md (Izolacja sesji)
< docs/worktree-init.md, docs/settings.md
