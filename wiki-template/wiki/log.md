---
type: log
---
# Log — {{PROJECT}}

Append-only. Format: `## [YYYY-MM-DD] typ | co | wynik`. Typy: init, {{UNIT_TYPE}}, ingest, query, lint, decision, session.
Nigdy nie edytuj starych wpisow. Ostatnie 5: `grep "^## \[" wiki/log.md | tail -5`.

## [{{DATE}}] init | szkielet wiki (wiki-init.sh, unit={{UNIT}}) | hub + foldery + CLAUDE.md ## Wiki + hooki + graph.json
