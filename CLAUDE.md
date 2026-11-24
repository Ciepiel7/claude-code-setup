# claude-code-setup — projekt

## Stack
- Shell: Bash
- Target: Claude Code CLI (`~/.claude/`)
- Agent format: Markdown + YAML frontmatter
- Hooks: PostToolUse w settings.json

## Struktura
```
CLAUDE.global.md           — global ~/.claude/CLAUDE.md po install (kazdy projekt)
CLAUDE.md                  — instrukcje tego repo (ladowane tylko tutaj)
settings.json              — hooks config + permissions (PostToolUse doc-check)
install.sh                 — tier-aware: --type=, --auto-detect, --init-project, --list, --update, --diff, --check, --health
agents/
  code-reviewer.md         — Tier 1: review dowolnego jezyka
  doc-maintainer.md        — Tier 1: utrzymanie docs/*.md
  git-workflow.md          — Tier 1: commity, PRy, changelog, tagi
  security-auditor.md      — Tier 1: OWASP Top 10 audit
  debug-assistant.md       — Tier 1: systematyczne debugowanie
  test-runner.md           — Tier 1: wykrywanie i uruchamianie testow
  dependency-auditor.md    — Tier 1: audyt zaleznosci (CVE, outdated)
  project-detector.md      — Tier 1: auto-detect stack i konwencji
  health-checker.md        — Tier 1: diagnostyka systemu agentow
  team-recipes.md          — gotowe kompozycje Agent Teams (full-review, pre-deploy, debug)
  board-{sceptyk,realista,analityk,strateg}.md — Tier 1: Board, ocena pomyslu z 4 stron (Recipe 8 w team-recipes.md)
  scout.md                 — Tier 1: rozpoznanie repo (haiku), zamiast wbudowanego Explore
  implementer.md           — Tier 1: implementacja z planu sesji (sonnet), sesja czyta diff
  project-types/
    wp-researcher.md       — Tier 2: WordPress/WooCommerce hooks (dowolna wersja)
    css-builder.md         — Tier 2: CSS uniwersalny (design system z CLAUDE.md)
    nextjs-helper.md       — Tier 2: Next.js App Router
    python-helper.md       — Tier 2: Python venv, async, data, scheduler, logging
project-template/
  CLAUDE.md                — szablon dla nowego projektu
  settings.json            — placeholder domeny projektu
skills/
  llm-wiki/SKILL.md        — LLM Wiki: init + operacje (ingest/query/lint) -> ~/.claude/skills/
  polszczyzna/             — poprawna polszczyzna w tekstach PL: SKILL.md, eval.md, references/ (kalki, interpunkcja, fleksja, maile)
  explain-diff/SKILL.md    — /explain-diff: twoje zmiany prostym jezykiem + diagram przeplywu (czat albo Artifact)
  video-claude/SKILL.md    — filmy z Claude: Remotion, assety marki, spring + audio, petla samokrytyki /watch
wiki-template/             — szablon wiki/ per projekt -> ~/.claude/wiki-template/
  wiki/                    — index, SCHEMA, log, hot, lessons, Failed Ideas/ledger, update_hot.py, hooks/
  .obsidian/               — graph.json (kolory per folder), app.json (ignore, attachments)
  CLAUDE-wiki.md           — sekcja "## Wiki" doklejana do CLAUDE.md projektu
scripts/
  doc-check.sh             — PostToolUse hook: sprawdza pokrycie docs
  worktree-init.sh         — init worktree: .env + vendor/node_modules z glownego katalogu
  prune-worktree-sessions.sh — SessionStart+Stop hook: sesje z worktree widoczne w `claude resume` repo, sprzata po martwych worktree
  init-project.sh          — szablon nowego projektu (rust|wordpress|python)
  wiki-init.sh             — LLM Wiki w repo: wiki/ + CLAUDE.md + hooki + .obsidian
  guard-destructive.sh — PreToolUse hook: blokada destrukcyjnych komend
  guard-untrusted-repo.sh  — PreToolUse/Bash hook: skan SkillSpector przed klonem/instalacja repo z GitHuba
  session-banner.sh        — SessionStart: liczy agentow/skille/skrypty/recipes na zywo (zastapil zahardkodowany echo)
  agent-routing.sh         — PreToolUse/Agent hook: log + inline info o modelu subagenta; --report; zeruje licznik read-gate
  read-gate.sh             — PreToolUse/Read hook: bramka czytania, przypomina o scoucie przy 3 i 8 plikach (nigdy nie blokuje)
  write-gate.sh            — PreToolUse/Edit|Write hook: bramka zapisu, przypomina o petli przy 2. pliku (nigdy nie blokuje)
  browser-gate.sh          — PreToolUse hook: blokuje MCP przegladarki, wszystko przez browser-harness (ALLOW_BROWSER_MCP=1 omija)
  chrome-claude.sh         — uruchamia dedykowany Chrome (CDP 9333, ~/.chrome-claude), idempotentny
  skills-manifest.sh       — zapisuje skills.txt (skille + zrodlo), install.sh podpowiada brakujace
  answer-gate.sh           — UserPromptSubmit hook: przypomina regule "odpowiedz z kodu" przy pytaniach "jak dziala X" (nigdy nie blokuje)
  statusline.sh            — statusLine wrapper: node statusline.js (Mac+Win), fallback jq
  statusline.js            — statusLine: model, % kontekstu, koszt, projekt (staly w worktree), czas sesji
docs/                      — dokumentacja repo (Doc-Index v4) + docs/produkcja.md (playbook prod)
```

## Kluczowe pliki
- `install.sh` — jedyne narzedzie deploy: nowa maszyna `bash install.sh`, istniejaca `bash install.sh --update` (zachowuje lokalny `autoMode`), potem `--health`
- Maszyny: macOS (M3) + Windows 11 (Git Bash). Wszystko w repo musi dzialac na obu
- `scripts/doc-check.sh` — PostToolUse hook; analizuje PHP/JS/CSS/Py/Bash
- `settings.json` — rejestruje hook + permissions w Claude Code
- `agents/*.md` — Tier 1 agenty (globalne)
- `agents/project-types/*.md` — Tier 2 agenty (technologia-specyficzne)

## Konwencje agentow
- Kazdy agent: YAML frontmatter (`name`, `description`, `tools`, `model`)
- `model:` wg tabeli w `## Model Routing` — frontmatter musi sie z nia zgadzac
- `tools:` lista — tylko te co agent realnie uzywa
- Opis w frontmatter: jedno zdanie, kiedy Claude ma odpalic agenta

## Docs

| Plik źródłowy | Dokumentacja |
|---|---|
| install.sh | docs/install.md |
| scripts/doc-check.sh | docs/doc-check.md |
| scripts/agent-routing.sh | docs/agent-routing.md |
| settings.json | docs/settings.md |
| scripts/wiki-init.sh | docs/wiki-init.md |
| scripts/prune-worktree-sessions.sh | docs/prune-worktree-sessions.md |
| scripts/read-gate.sh | docs/read-gate.md |
| scripts/guard-untrusted-repo.sh | docs/guard-untrusted-repo.md |
| scripts/browser-gate.sh | docs/browser-gate.md |
| scripts/write-gate.sh | docs/write-gate.md |
| scripts/chrome-claude.sh | docs/chrome-claude.md |
| scripts/skills-manifest.sh | docs/skills-manifest.md |
| scripts/answer-gate.sh | docs/answer-gate.md |
| wiki-template/wiki/update_hot.py | docs/update_hot.md |
| (workflow git/deploy/monitoring) | docs/produkcja.md |
| (dowody liczbowe pod Model Routing) | docs/koszt-kontekstu.md |
