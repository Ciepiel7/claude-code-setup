# scripts/worktree-init.sh

Init świeżego worktree Claude: podpina gitignorowane zależności z głównego katalogu repo.
Odpalany zaraz po EnterWorktree; projektowy `scripts/worktree-init.sh` wygrywa z tym generycznym.

## fn
```
link_dir(d) -> junction (Windows mklink /J) lub symlink katalogu z MAIN; SKIP gdy istnieje (czesciowo trackowany)
main body -> MAIN z git rev-parse --git-common-dir; kopiuje .env/.env.local; linkuje vendor, node_modules
```

## Reguly
- .env KOPIA nie link (worktree moze chciec wlasne nadpisania, np. inny port)
- katalog istniejacy (np. vendor z trackowanym podkatalogiem) -> SKIP z komunikatem, podpiecie reczne
- w glownym katalogu repo: no-op (exit 0)

## Powiazania
> CLAUDE.md (Izolacja sesji), docs/produkcja.md
