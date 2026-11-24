## Wiki (pamiec agenta — `wiki/`, vault Obsidian = ROOT repo)
Dwie zasady stale (caly system):
- **Przed kazda istotna praca:** przeczytaj `wiki/index.md` ORAZ `wiki/Failed Ideas/ledger.md` (potem `wiki/hot.md`).
- **Przed zakonczeniem:** zaktualizuj dotkniete strony wiki, dopisz `## [YYYY-MM-DD] typ | co | wynik` do `wiki/log.md`, porzucony pomysl -> wiersz w Failed Ideas.

Reguly:
- Wiki LINKUJE do zrodel prawdy (kod, dane, outputy, docs/) — nigdy nie kopiuje ich tresci jako prawdy.
- `wiki/hot.md` generuje `wiki/update_hot.py` (hook Stop) — nie edytuj reka poza blokiem Next Actions.
- Szablony stron, workflow, lint: `wiki/SCHEMA.md`. Jednostka pracy: `wiki/{{UNIT}}/`.
- `.obsidian/graph.json` Obsidian nadpisuje w locie — edytuj tylko przy ZAMKNIETYM Obsidianie.
- Hooki `.claude/settings.json` (`wiki/hooks/wiki-hook.*`): SessionStart `git pull --ff-only`; Stop `update_hot.py` + commit `wiki/ .obsidian/` + push. Wszystkie best-effort, nigdy nie blokuja sesji.
